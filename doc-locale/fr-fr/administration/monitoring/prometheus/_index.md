---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Surveillance de GitLab avec Prometheus
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

[Prometheus](https://prometheus.io) est un puissant service de surveillance de séries temporelles, offrant une plateforme flexible pour surveiller GitLab et d'autres produits logiciels.

GitLab fournit une surveillance prête à l'emploi avec Prometheus, donnant accès à une surveillance de haute qualité des séries temporelles des services GitLab.

Prometheus et les différents exportateurs répertoriés sur cette page sont intégrés dans les packages Linux. Consultez la documentation de chaque exportateur pour connaître la date à laquelle ils ont été ajoutés. Pour les installations auto-compilées, vous devez les installer vous-même. Au fil des releases successives, des métriques GitLab supplémentaires sont capturées.

Les services Prometheus sont activés par défaut.

Prometheus et ses exportateurs n'authentifient pas les utilisateurs et sont accessibles à toute personne pouvant y accéder.

## Fonctionnement de Prometheus {#how-prometheus-works}

Prometheus fonctionne en se connectant périodiquement à des sources de données et en collectant leurs métriques de performance via les [différents exportateurs](#bundled-software-metrics). Pour afficher et utiliser les données de surveillance, vous pouvez soit [vous connecter directement à Prometheus](#viewing-performance-metrics), soit utiliser un outil de tableau de bord comme [Grafana](https://grafana.com).

## Configurer Prometheus {#configuring-prometheus}

Pour les installations auto-compilées, vous devez l'installer et le configurer vous-même.

Prometheus et ses exportateurs sont activés par défaut. Prometheus s'exécute en tant qu'utilisateur `gitlab-prometheus` et écoute sur `http://localhost:9090`. Par défaut, Prometheus n'est accessible que depuis le serveur GitLab lui-même. Chaque exportateur est automatiquement configuré comme cible de surveillance pour Prometheus, sauf s'il est désactivé individuellement.

Pour désactiver Prometheus et l'ensemble de ses exportateurs, ainsi que tout exportateur ajouté à l'avenir :

1. Modifiez `/etc/gitlab/gitlab.rb`
1. Ajoutez ou trouvez et décommentez les lignes suivantes, en vous assurant qu'elles sont définies sur `false` :

   ```ruby
   prometheus_monitoring['enable'] = false
   sidekiq['metrics_enabled'] = false

   # Already set to `false` by default, but you can explicitly disable it to be sure
   puma['exporter_enabled'] = false
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

### Modifier le port et l'adresse d'écoute de Prometheus {#changing-the-port-and-address-prometheus-listens-on}

> [!warning]
> Vous pouvez modifier le port d'écoute de Prometheus, mais vous ne devriez pas le faire. Cette modification pourrait affecter ou entrer en conflit avec d'autres services s'exécutant sur le serveur GitLab. Procédez à vos risques et périls.

Pour accéder à Prometheus depuis l'extérieur du serveur GitLab, modifiez l'adresse/le port d'écoute de Prometheus :

1. Modifiez `/etc/gitlab/gitlab.rb`
1. Ajoutez ou trouvez et décommentez la ligne suivante :

   ```ruby
   prometheus['listen_address'] = 'localhost:9090'
   ```

   Remplacez `localhost:9090` par l'adresse ou le port sur lequel vous souhaitez que Prometheus écoute. Si vous souhaitez autoriser l'accès à Prometheus depuis des hôtes autres que `localhost`, omettez l'hôte ou utilisez `0.0.0.0` pour autoriser l'accès public :

   ```ruby
   prometheus['listen_address'] = ':9090'
   # or
   prometheus['listen_address'] = '0.0.0.0:9090'
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet

### Ajouter des configurations de scrape personnalisées {#adding-custom-scrape-configurations}

Vous pouvez configurer des cibles de scrape supplémentaires pour Prometheus intégré au package Linux en modifiant `prometheus['scrape_configs']` dans `/etc/gitlab/gitlab.rb` à l'aide de la syntaxe de [configuration des cibles de scrape Prometheus](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cscrape_config%3E).

Voici un exemple de configuration pour scraper `http://1.1.1.1:8060/probe?param_a=test&param_b=additional_test` :

```ruby
prometheus['scrape_configs'] = [
  {
    'job_name': 'custom-scrape',
    'metrics_path': '/probe',
    'params' => {
      'param_a' => ['test'],
      'param_b' => ['additional_test'],
    },
    'static_configs' => [
      'targets' => ['1.1.1.1:8060'],
    ],
  },
]
```

### Prometheus autonome avec le package Linux {#standalone-prometheus-using-the-linux-package}

Vous pouvez utiliser le package Linux pour configurer un nœud de surveillance autonome exécutant Prometheus. Un [Grafana](../performance/grafana_configuration.md) externe peut être configuré sur ce nœud de surveillance pour afficher des tableaux de bord.

Un nœud de surveillance autonome est recommandé pour les [déploiements GitLab avec plusieurs nœuds](../../reference_architectures/_index.md).

Les étapes ci-dessous sont le minimum nécessaire pour configurer un nœud de surveillance exécutant Prometheus avec le package Linux :

1. Connectez-vous en SSH au nœud de surveillance.
1. [Installez](https://about.gitlab.com/install/) le package Linux souhaité en suivant **steps 1 and 2** de la page de téléchargements GitLab, mais ne suivez pas les étapes restantes.
1. Assurez-vous de collecter les adresses IP ou les enregistrements DNS des nœuds du serveur Consul, pour l'étape suivante.
1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez le contenu suivant :

   ```ruby
   roles ['monitoring_role']

   external_url 'http://gitlab.example.com'

   # Prometheus
   prometheus['listen_address'] = '0.0.0.0:9090'
   prometheus['monitor_kubernetes'] = false

   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] = true
   consul['configuration'] = {
      retry_join: %w(10.0.0.1 10.0.0.2 10.0.0.3), # The addresses can be IPs or FQDNs
   }

   # Nginx - For Grafana access
   nginx['enable'] = true
   ```

1. Exécutez `sudo gitlab-ctl reconfigure` pour compiler la configuration.

L'étape suivante consiste à indiquer à tous les autres nœuds où se trouve le nœud de surveillance :

1. Modifiez `/etc/gitlab/gitlab.rb`, puis ajoutez, ou trouvez et décommentez la ligne suivante :

   ```ruby
   # can be FQDN or IP
   gitlab_rails['prometheus_address'] = '10.0.0.1:9090'
   ```

   Où `10.0.0.1:9090` est l'adresse IP et le port du nœud Prometheus.

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Une fois la surveillance par Service Discovery activée avec `consul['monitoring_service_discovery'] = true`, assurez-vous que `prometheus['scrape_configs']` n'est pas défini dans `/etc/gitlab/gitlab.rb`. La définition simultanée de `consul['monitoring_service_discovery'] = true` et `prometheus['scrape_configs']` dans `/etc/gitlab/gitlab.rb` entraîne des erreurs.

### Utiliser un serveur Prometheus externe {#using-an-external-prometheus-server}

> [!warning]
> Prometheus et la plupart des exportateurs ne prennent pas en charge l'authentification. Nous ne recommandons pas de les exposer en dehors du réseau local.

Quelques modifications de configuration sont nécessaires pour permettre à GitLab d'être surveillé par un serveur Prometheus externe.

Pour utiliser un serveur Prometheus externe :

1. Modifiez `/etc/gitlab/gitlab.rb`.
1. Désactivez Prometheus intégré :

   ```ruby
   prometheus['enable'] = false
   ```

1. Configurez l'[exportateur](#bundled-software-metrics) de chaque service intégré pour écouter sur une adresse réseau, par exemple :

   ```ruby
   node_exporter['listen_address'] = '0.0.0.0:9100'
   gitlab_workhorse['prometheus_listen_addr'] = "0.0.0.0:9229"

   # Rails nodes
   gitlab_exporter['listen_address'] = '0.0.0.0'
   gitlab_exporter['listen_port'] = '9168'
   registry['debug_addr'] = '0.0.0.0:5001'

   # Sidekiq nodes
   sidekiq['listen_address'] = '0.0.0.0'

   # Redis nodes
   redis_exporter['listen_address'] = '0.0.0.0:9121'

   # PostgreSQL nodes
   postgres_exporter['listen_address'] = '0.0.0.0:9187'

   # Gitaly nodes
   gitaly['configuration'] = {
      # ...
      prometheus_listen_addr: '0.0.0.0:9236',
   }

   # Pgbouncer nodes
   pgbouncer_exporter['listen_address'] = '0.0.0.0:9188'
   ```

1. Installez et configurez une instance Prometheus dédiée, si nécessaire, en utilisant les [instructions d'installation officielles](https://prometheus.io/docs/prometheus/latest/installation/).
1. Sur **l'ensemble** des serveurs GitLab Rails (Puma, Sidekiq), définissez l'adresse IP et le port d'écoute du serveur Prometheus. Par exemple :

   ```ruby
   gitlab_rails['prometheus_address'] = '192.168.0.1:9090'
   ```

1. Pour scraper les métriques NGINX, vous devez également configurer NGINX pour autoriser l'adresse IP du serveur Prometheus. Par exemple :

   ```ruby
   nginx['status']['options'] = {
         "server_tokens" => "off",
         "access_log" => "off",
         "allow" => "192.168.0.1",
         "deny" => "all",
   }
   ```

   Vous pouvez également spécifier plusieurs adresses IP si vous avez plusieurs serveurs Prometheus :

   ```ruby
   nginx['status']['options'] = {
         "server_tokens" => "off",
         "access_log" => "off",
         "allow" => ["192.168.0.1", "192.168.0.2"],
         "deny" => "all",
   }
   ```

1. Pour autoriser le serveur Prometheus à récupérer des données depuis le point de terminaison des [métriques GitLab](#gitlab-metrics), ajoutez l'adresse IP du serveur Prometheus à la [liste d'autorisation IP de surveillance](../ip_allowlist.md) :

   ```ruby
   gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '192.168.0.1']
   ```

1. Puisque nous configurons l'[exportateur](#bundled-software-metrics) de chaque service intégré pour écouter sur une adresse réseau, mettez à jour le pare-feu de l'instance pour n'autoriser que le trafic provenant de votre IP Prometheus pour les exportateurs activés. Une liste de référence complète des services d'exportateur et de [leurs ports respectifs](../../package_information/defaults.md#ports) est disponible.
1. [Reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour appliquer les modifications.
1. Modifiez le fichier de configuration du serveur Prometheus.
1. Ajoutez les exportateurs de chaque nœud à la [configuration des cibles de scrape](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cscrape_config%3E) du serveur Prometheus. Par exemple, un exemple d'extrait utilisant `static_configs` :

   ```yaml
   scrape_configs:
     - job_name: nginx
       static_configs:
         - targets:
           - 1.1.1.1:8060
     - job_name: redis
       static_configs:
         - targets:
           - 1.1.1.1:9121
     - job_name: postgres
       static_configs:
         - targets:
           - 1.1.1.1:9187
     - job_name: node
       static_configs:
         - targets:
           - 1.1.1.1:9100
     - job_name: gitlab-workhorse
       static_configs:
         - targets:
           - 1.1.1.1:9229
     - job_name: gitlab-rails
       metrics_path: "/-/metrics"
       scheme: https
       static_configs:
         - targets:
           - 1.1.1.1
     - job_name: gitlab-sidekiq
       static_configs:
         - targets:
           - 1.1.1.1:8082
     - job_name: gitlab_exporter_database
       metrics_path: "/database"
       static_configs:
         - targets:
           - 1.1.1.1:9168
     - job_name: gitlab_exporter_sidekiq
       metrics_path: "/sidekiq"
       static_configs:
         - targets:
           - 1.1.1.1:9168
     - job_name: gitaly
       static_configs:
         - targets:
           - 1.1.1.1:9236
     - job_name: registry
       static_configs:
         - targets:
           - 1.1.1.1:5001
   ```

   > [!warning]
   > Le job `gitlab-rails` dans l'extrait suppose que GitLab est accessible via HTTPS. Si votre déploiement n'utilise pas HTTPS, la configuration du job est adaptée pour utiliser le schéma `http` et le port 80.

1. Rechargez le serveur Prometheus.

### Configurer la taille de rétention du stockage {#configure-the-storage-retention-size}

Prometheus dispose de plusieurs indicateurs personnalisés pour configurer le stockage local :

- `storage.tsdb.retention.time` : date de suppression des anciennes données. Par défaut, `15d`. Remplace `storage.tsdb.retention` si cet indicateur est défini sur une valeur autre que la valeur par défaut.
- `storage.tsdb.retention.size` : (expérimental) nombre maximal d'octets de blocs de stockage à conserver. Les données les plus anciennes sont supprimées en premier. La valeur par défaut est `0` (désactivé). Cet indicateur est expérimental et peut changer dans les futures releases. Unités prises en charge : `B`, `KB`, `MB`, `GB`, `TB`, `PB`, `EB`. Par exemple, `512MB`.

Pour configurer la taille de rétention du stockage :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   prometheus['flags'] = {
     'storage.tsdb.path' => "/var/opt/gitlab/prometheus/data",
     'storage.tsdb.retention.time' => "7d",
     'storage.tsdb.retention.size' => "2GB",
     'config.file' => "/var/opt/gitlab/prometheus/prometheus.yml"
   }
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Afficher les métriques de performance {#viewing-performance-metrics}

Vous pouvez accéder à `http://localhost:9090` pour le tableau de bord que Prometheus propose par défaut.

Si SSL a été activé sur votre instance GitLab, vous ne pourrez peut-être pas accéder à Prometheus sur le même navigateur que GitLab si vous utilisez le même FQDN en raison de [HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security). [Un projet de test GitLab existe](https://gitlab.com/gitlab-org/multi-user-prometheus) pour fournir un accès, mais dans l'intervalle, il existe quelques solutions de contournement : utiliser un FQDN séparé, utiliser l'IP du serveur, utiliser un navigateur séparé pour Prometheus, réinitialiser HSTS ou utiliser [un proxy NGINX](https://docs.gitlab.com/omnibus/settings/nginx/#inserting-custom-nginx-settings-into-the-gitlab-server-block).

Les données de performance collectées par Prometheus peuvent être consultées directement dans la console Prometheus ou via un outil de tableau de bord compatible. L'interface Prometheus fournit un [langage de requête flexible](https://prometheus.io/docs/prometheus/latest/querying/basics/) pour travailler avec les données collectées et vous permet de visualiser les résultats. Pour un tableau de bord plus complet, Grafana peut être utilisé et dispose d'un [support officiel pour Prometheus](https://prometheus.io/docs/visualization/grafana/).

## Exemples de requêtes Prometheus {#sample-prometheus-queries}

Vous trouverez ci-dessous quelques exemples de requêtes Prometheus pouvant être utilisées.

> [!note]
> Ces exemples peuvent ne pas fonctionner sur toutes les configurations. Des ajustements supplémentaires peuvent être nécessaires.

- **% CPU utilization** : `1 - avg without (mode,cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m]))`
- **% Memory available** : `((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) or ((node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes) / node_memory_MemTotal_bytes)) * 100`
- **Data transmitted** : `rate(node_network_transmit_bytes_total{device!="lo"}[5m])`
- **Data received** : `rate(node_network_receive_bytes_total{device!="lo"}[5m])`
- **Disk read IOPS** : `sum by (instance) (rate(node_disk_reads_completed_total[1m]))`
- **Disk write IOPS** : `sum by (instance) (rate(node_disk_writes_completed_total[1m]))`
- **RPS via GitLab transaction count** : `sum(irate(gitlab_transaction_duration_seconds_count{controller!~'HealthController|MetricsController'}[1m])) by (controller, action)`

## Prometheus comme source de données Grafana {#prometheus-as-a-grafana-data-source}

Grafana vous permet d'importer des métriques de performance Prometheus comme source de données et de les afficher sous forme de graphiques et de tableaux de bord, ce qui est utile pour la visualisation.

Pour ajouter un tableau de bord Prometheus pour une installation GitLab sur un seul serveur :

1. Créez une nouvelle source de données dans Grafana.
1. Pour **Type**, sélectionnez `Prometheus`.
1. Nommez votre source de données (par exemple GitLab).
1. Dans **URL du serveur Prometheus**, ajoutez votre adresse d'écoute Prometheus.
1. Définissez la **Méthode HTTP** sur `GET`.
1. Enregistrez et testez votre configuration pour vérifier qu'elle fonctionne.

## Métriques GitLab {#gitlab-metrics}

GitLab surveille ses propres métriques de service interne et les rend disponibles au point d'arrivée `/-/metrics`. Contrairement aux autres exportateurs, ce point de terminaison nécessite une authentification car il est disponible sur la même URL et le même port que le trafic utilisateur.

En savoir plus sur les [métriques GitLab](gitlab_metrics.md).

## Métriques des logiciels intégrés {#bundled-software-metrics}

De nombreuses dépendances GitLab intégrées dans le package Linux sont préconfigurées pour exporter des métriques Prometheus.

### Exportateur de nœud {#node-exporter}

L'exportateur de nœud vous permet de mesurer diverses ressources de la machine, telles que la mémoire, le disque et l'utilisation du CPU.

[En savoir plus sur l'exportateur de nœud](node_exporter.md).

### Exportateur web {#web-exporter}

L'exportateur web est un serveur de métriques dédié qui permet de séparer le trafic des utilisateurs finaux et le trafic Prometheus en deux applications distinctes pour améliorer les performances et la disponibilité.

[En savoir plus sur l'exportateur web](web_exporter.md).

### Exportateur Redis {#redis-exporter}

L'exportateur Redis vous permet de mesurer diverses métriques Redis.

[En savoir plus sur l'exportateur Redis](redis_exporter.md).

### Exportateur PostgreSQL {#postgresql-exporter}

L'exportateur PostgreSQL vous permet de mesurer diverses métriques PostgreSQL.

[En savoir plus sur l'exportateur PostgreSQL](postgres_exporter.md).

### Exportateur PgBouncer {#pgbouncer-exporter}

L'exportateur PgBouncer vous permet de mesurer diverses métriques PgBouncer.

[En savoir plus sur l'exportateur PgBouncer](pgbouncer_exporter.md).

### Exportateur Registry {#registry-exporter}

L'exportateur de Registry vous permet de mesurer diverses métriques de Registry.

[En savoir plus sur l'exportateur Registry](registry_exporter.md).

### Exportateur GitLab {#gitlab-exporter}

L'exportateur GitLab vous permet de mesurer diverses métriques GitLab, extraites de Redis et de la base de données.

[En savoir plus sur l'exportateur GitLab](gitlab_exporter.md).

## Dépannage {#troubleshooting}

### `/var/opt/gitlab/prometheus` consomme trop d'espace disque {#varoptgitlabprometheus-consumes-too-much-disk-space}

Si vous n'utilisez **pas** la surveillance Prometheus :

1. [Désactivez Prometheus](_index.md#configuring-prometheus).
1. Supprimez les données sous `/var/opt/gitlab/prometheus`.

Si vous utilisez la surveillance Prometheus :

1. Arrêtez Prometheus (la suppression de données pendant son exécution peut entraîner une corruption des données) :

   ```shell
   gitlab-ctl stop prometheus
   ```

1. Supprimez les données sous `/var/opt/gitlab/prometheus/data`.
1. Redémarrez le service :

   ```shell
   gitlab-ctl start prometheus
   ```

1. Vérifiez que le service est opérationnel :

   ```shell
   gitlab-ctl status prometheus
   ```

1. Facultatif. [Configurez la taille de rétention du stockage](_index.md#configure-the-storage-retention-size).

### Le nœud de surveillance ne reçoit pas de données {#monitoring-node-not-receiving-data}

Si le nœud de surveillance ne reçoit aucune donnée, vérifiez que les exportateurs capturent bien des données :

```shell
curl "http[s]://localhost:<EXPORTER LISTENING PORT>/metrics"
```

ou

```shell
curl "http[s]://localhost:<EXPORTER LISTENING PORT>/-/metrics"
```

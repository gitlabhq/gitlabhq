---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Configurer l'instance Puma intégrée du package GitLab"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Puma est un serveur HTTP 1.1 rapide, multi-thread et hautement concurrent pour les applications Ruby. Il exécute l'application Rails principale qui fournit les fonctionnalités destinées aux utilisateurs de GitLab.

## Optimisation de l'utilisation de la mémoire {#tuning-memory-use}

Pour réduire l'utilisation de la mémoire, Puma duplique des processus de worker. Chaque fois qu'un worker est créé, il partage la mémoire avec le processus principal. Le worker n'utilise de la mémoire supplémentaire que lorsqu'il modifie ses pages mémoire ou en ajoute de nouvelles. Cela peut entraîner une augmentation de la mémoire physique utilisée par les workers Puma au fil du temps, à mesure qu'ils traitent des requêtes web supplémentaires. La quantité de mémoire utilisée au fil du temps dépend de l'utilisation de GitLab. Plus les utilisateurs de GitLab utilisent de fonctionnalités, plus l'utilisation de la mémoire attendue sera élevée au fil du temps.

Pour arrêter la croissance incontrôlée de la mémoire, l'application GitLab Rails exécute un fil de discussion de supervision qui redémarre automatiquement les workers s'ils dépassent un seuil de taille de jeu résident (RSS) donné pendant un certain temps.

GitLab définit une valeur par défaut de `1500Mb` pour la limite de mémoire. Pour remplacer la valeur par défaut, définissez `per_worker_max_memory_mb` sur la nouvelle limite RSS en mégaoctets :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   puma['per_worker_max_memory_mb'] = 1200 # 1.2 GB
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Lorsque les workers sont redémarrés, la capacité à exécuter GitLab est réduite pendant une courte période. Définissez `per_worker_max_memory_mb` sur une valeur plus élevée si les workers sont remplacés trop souvent.

Le nombre de workers est calculé en fonction des cœurs de processeur. Un petit déploiement GitLab avec 4 à 8 workers peut rencontrer des problèmes de performances si les workers sont redémarrés trop souvent (une fois ou plus par minute).

Une valeur `per_worker_max_memory_mb` plus élevée peut être bénéfique si le serveur dispose de mémoire libre.

## Planifier les connexions à la base de données {#plan-the-database-connections}

Avant d'augmenter le nombre de workers ou de threads Puma, tenez compte de l'impact des connexions à la base de données sur votre paramètre PostgreSQL `max_connections`.

Pour une planification détaillée des connexions et des calculs, consultez la page [Optimiser PostgreSQL](../postgresql/tune.md).

### Surveiller les redémarrages de workers {#monitor-worker-restarts}

GitLab émet des événements de journal si des workers sont redémarrés en raison d'une utilisation élevée de la mémoire.

Voici un exemple de l'un de ces événements de journal dans `/var/log/gitlab/gitlab-rails/application_json.log` :

```json
{
  "severity": "WARN",
  "time": "2023-01-04T09:45:16.173Z",
  "correlation_id": null,
  "pid": 2725,
  "worker_id": "puma_0",
  "memwd_handler_class": "Gitlab::Memory::Watchdog::PumaHandler",
  "memwd_sleep_time_s": 5,
  "memwd_rss_bytes": 1077682176,
  "memwd_max_rss_bytes": 629145600,
  "memwd_max_strikes": 5,
  "memwd_cur_strikes": 6,
  "message": "rss memory limit exceeded"
}
```

`memwd_rss_bytes` est la quantité réelle de mémoire consommée, et `memwd_max_rss_bytes` est la limite RSS définie via `per_worker_max_memory_mb` ou par [`DEFAULT_PUMA_WORKER_RSS_LIMIT_MB`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/memory/watchdog/configurator.rb).

## Modifier le délai d'expiration du worker {#change-the-worker-timeout}

Le [délai d'expiration par défaut de Puma est de 60 secondes](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/rack_timeout.rb).

> [!note]
> Le paramètre `puma['worker_timeout']` ne définit pas la durée maximale des requêtes.

Pour modifier le délai d'expiration du worker à 600 secondes :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['env'] = {
      'GITLAB_RAILS_RACK_TIMEOUT' => 600
    }
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Désactiver le mode cluster de Puma dans les environnements à mémoire limitée {#disable-puma-clustered-mode-in-memory-constrained-environments}

> [!warning]
> Cette fonctionnalité est une [expérimentation](../../policy/development_stages_support.md#experiment) et peut être modifiée sans préavis. Cette fonctionnalité n'est pas prête pour une utilisation en production. Si vous souhaitez utiliser cette fonctionnalité, vous devez d'abord la tester en dehors de la production. Consultez les [problèmes connus](#puma-single-mode-known-issues) pour plus de détails.

Dans un environnement à mémoire limitée avec moins de 4 Go de RAM disponible, envisagez de désactiver le [mode cluster](https://github.com/puma/puma#clustered-mode) de Puma.

Définissez le nombre de `workers` sur `0` pour réduire l'utilisation de la mémoire de plusieurs centaines de Mo :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   puma['worker_processes'] = 0
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Contrairement au mode cluster, qui est configuré par défaut, un seul processus Puma servirait l'application. Pour plus de détails sur les paramètres de workers et de threads Puma, consultez les [exigences Puma](../../install/requirements.md#puma).

L'inconvénient d'exécuter Puma dans cette configuration est la réduction du débit, ce qui peut être considéré comme un compromis acceptable dans un environnement à mémoire limitée.

N'oubliez pas de disposer d'un espace d'échange suffisant pour éviter les conditions de mémoire insuffisante (OOM). Consultez les [exigences en matière de mémoire](../../install/requirements.md#memory) pour plus de détails.

### Problèmes connus du mode unique Puma {#puma-single-mode-known-issues}

Lors de l'exécution de Puma en mode unique, certaines fonctionnalités ne sont pas prises en charge :

- [Redémarrage par phases](https://gitlab.com/gitlab-org/gitlab/-/issues/300665)
- [Limiteurs de mémoire](#tuning-memory-use)

Pour plus d'informations, consultez l'epic [5303](https://gitlab.com/groups/gitlab-org/-/epics/5303).

## Configurer Puma pour écouter via SSL {#configuring-puma-to-listen-over-ssl}

Puma, lorsqu'il est déployé avec une installation de package Linux, écoute par défaut sur un socket Unix. Pour configurer Puma afin qu'il écoute sur un port HTTPS à la place, suivez les étapes ci-dessous :

1. Générez une paire de clés de certificat SSL pour l'adresse sur laquelle Puma écoutera. Pour l'exemple ci-dessous, il s'agit de `127.0.0.1`.

   > [!note]
   > Si vous utilisez un certificat auto-signé d'une autorité de certification (CA) personnalisée, suivez [la documentation](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates) pour les faire approuver par les autres composants GitLab.

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   puma['ssl_listen'] = '127.0.0.1'
   puma['ssl_port'] = 9111
   puma['ssl_certificate'] = '<path_to_certificate>'
   puma['ssl_certificate_key'] = '<path_to_key>'

   # Disable UNIX socket
   puma['socket'] = ""
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> En plus du socket Unix, Puma écoute également via HTTP sur le port 8080 pour fournir des métriques à récupérer par Prometheus. Il n'est pas possible de faire récupérer ces métriques par Prometheus via HTTPS, et la prise en charge de cette fonctionnalité est en cours de discussion [dans ce ticket](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6811). Par conséquent, il n'est techniquement pas possible de désactiver cet écouteur HTTP sans perdre les métriques Prometheus.

### Utilisation d'une clé SSL chiffrée {#using-an-encrypted-ssl-key}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7799) dans GitLab 16.1.

{{< /history >}}

Puma prend en charge l'utilisation d'une clé SSL privée chiffrée, qui peut être déchiffrée à l'exécution. Les instructions suivantes illustrent comment configurer cela :

1. Chiffrez la clé avec un mot de passe si ce n'est pas déjà fait :

   ```shell
   openssl rsa -aes256 -in /path/to/ssl-key.pem -out /path/to/encrypted-ssl-key.pem
   ```

   Saisissez un mot de passe deux fois pour écrire le fichier chiffré. Dans cet exemple, nous utilisons `some-password-here`.

1. Créez un script ou un exécutable qui affiche le mot de passe. Par exemple, créez un script de base dans `/var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password` qui affiche le mot de passe :

   ```shell
   #!/bin/sh
   echo some-password-here
   ```

   Évitez de stocker le mot de passe sur disque et utilisez un mécanisme sécurisé pour récupérer un mot de passe, tel que Vault. Par exemple, le script pourrait ressembler à :

   ```shell
   #!/bin/sh
   export VAULT_ADDR=http://vault-password-distribution-point:8200
   export VAULT_TOKEN=<some token>

   echo "$(vault kv get -mount=secret puma-ssl-password)"
   ```

1. Assurez-vous que le processus Puma dispose des autorisations suffisantes pour exécuter le script et lire la clé chiffrée :

   ```shell
   chown git:git /var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password
   chmod 770 /var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password
   chmod 660 /path/to/encrypted-ssl-key.pem
   ```

1. Modifiez `/etc/gitlab/gitlab.rb`, et remplacez `puma['ssl_certificate_key']` par la clé chiffrée et spécifiez `puma['ssl_key_password_command]` :

   ```ruby
   puma['ssl_certificate_key'] = '/path/to/encrypted-ssl-key.pem'
   puma['ssl_key_password_command'] = '/var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password'
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Si GitLab démarre correctement, vous devriez pouvoir supprimer la clé SSL non chiffrée qui était stockée sur l'instance GitLab.

## Passer d'Unicorn à Puma {#switch-from-unicorn-to-puma}

> [!note]
> Pour les déploiements basés sur Helm, consultez la [documentation du chart `webservice`](https://docs.gitlab.com/charts/charts/gitlab/webservice/).

Puma est le serveur web par défaut et Unicorn n'est plus pris en charge.

Puma possède une architecture multi-thread qui utilise moins de mémoire qu'un serveur d'application multi-processus comme Unicorn. Sur GitLab.com, nous avons constaté une réduction de 40 % de la consommation de mémoire. La plupart des requêtes d'applications Rails incluent généralement une proportion de temps d'attente d'E/S.

Pendant le temps d'attente d'E/S, MRI Ruby libère le GVL pour les autres threads. Puma multi-thread peut donc continuer à traiter plus de requêtes qu'un seul processus.

Lors du passage à Puma, toute configuration du serveur Unicorn ne sera pas transférée automatiquement, en raison des différences entre les deux serveurs d'application.

Pour passer d'Unicorn à Puma :

1. Déterminez les [paramètres de workers et de threads](../../install/requirements.md#puma) Puma appropriés.
1. Convertissez tous les paramètres Unicorn personnalisés en paramètres Puma dans `/etc/gitlab/gitlab.rb`.

   Le tableau ci-dessous résume les clés de configuration Unicorn qui correspondent à celles de Puma lors de l'utilisation du package Linux, et celles qui n'ont pas de correspondance.

   | Unicorn                              | Puma                               |
   | ------------------------------------ | ---------------------------------- |
   | `unicorn['enable']`                  | `puma['enable']`                   |
   | `unicorn['worker_timeout']`          | `puma['worker_timeout']`           |
   | `unicorn['worker_processes']`        | `puma['worker_processes']`         |
   | Non applicable                       | `puma['ha']`                       |
   | Non applicable                       | `puma['min_threads']`              |
   | Non applicable                       | `puma['max_threads']`              |
   | `unicorn['listen']`                  | `puma['listen']`                   |
   | `unicorn['port']`                    | `puma['port']`                     |
   | `unicorn['socket']`                  | `puma['socket']`                   |
   | `unicorn['pidfile']`                 | `puma['pidfile']`                  |
   | `unicorn['tcp_nopush']`              | Non applicable                     |
   | `unicorn['backlog_socket']`          | Non applicable                     |
   | `unicorn['somaxconn']`               | `puma['somaxconn']`                |
   | Non applicable                       | `puma['state_path']`               |
   | `unicorn['log_directory']`           | `puma['log_directory']`            |
   | `unicorn['worker_memory_limit_min']` | Non applicable                     |
   | `unicorn['worker_memory_limit_max']` | `puma['per_worker_max_memory_mb']` |
   | `unicorn['exporter_enabled']`        | `puma['exporter_enabled']`         |
   | `unicorn['exporter_address']`        | `puma['exporter_address']`         |
   | `unicorn['exporter_port']`           | `puma['exporter_port']`            |

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Facultatif. Pour les déploiements multi-nœuds, configurez l'équilibreur de charge pour utiliser la [vérification de disponibilité](../load_balancer.md#readiness-check).

## Dépannage de Puma {#troubleshooting-puma}

### Délai d'expiration de la passerelle 502 après que Puma tourne à 100 % du CPU {#502-gateway-timeout-after-puma-spins-at-100-cpu}

Cette erreur se produit lorsque le serveur web expire (par défaut :  60 s) sans avoir reçu de réponse du worker Puma. Si le CPU atteint 100 % pendant ce temps, il se peut que quelque chose prenne plus de temps que prévu.

Pour résoudre ce problème, nous devons d'abord comprendre ce qui se passe. Les conseils suivants ne sont recommandés que si vous n'avez pas d'objection à ce que les utilisateurs soient affectés par une interruption de service. Sinon, passez à la section suivante.

1. Chargez l'URL problématique
1. Exécutez `sudo gdb -p <PID>` pour vous attacher au processus Puma.
1. Dans la fenêtre GDB, saisissez :

   ```plaintext
   call (void) rb_backtrace()
   ```

1. Cela force le processus à générer une trace de pile Ruby. Consultez `/var/log/gitlab/puma/puma_stderr.log` pour la trace de pile. Par exemple, vous pourriez voir :

   ```plaintext
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:33:in `block in start'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:33:in `loop'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:36:in `block (2 levels) in start'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:44:in `sample'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:68:in `sample_objects'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:68:in `each_with_object'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:68:in `each'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:69:in `block in sample_objects'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:69:in `name'
   ```

1. Pour afficher les threads actuels, exécutez :

   ```plaintext
   thread apply all bt
   ```

1. Une fois le débogage avec `gdb` terminé, assurez-vous de vous détacher du processus et de quitter :

   ```plaintext
   detach
   exit
   ```

GDB signale une erreur si le processus Puma se termine avant que vous puissiez exécuter ces commandes. Pour gagner du temps, vous pouvez toujours augmenter le délai d'expiration du worker Puma. Pour les utilisateurs d'installations de packages Linux, vous pouvez modifier `/etc/gitlab/gitlab.rb` et l'augmenter de 60 secondes à 600 :

```ruby
gitlab_rails['env'] = {
        'GITLAB_RAILS_RACK_TIMEOUT' => 600
}
```

Pour les installations compilées manuellement, définissez la variable d'environnement. Reportez-vous à [Délai d'expiration du worker Puma](puma.md#change-the-worker-timeout).

[Reconfigurez](../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab pour que les modifications prennent effet.

#### Dépannage sans affecter les autres utilisateurs {#troubleshooting-without-affecting-other-users}

La section précédente s'attachait à un processus Puma en cours d'exécution, ce qui peut avoir des effets indésirables sur les utilisateurs tentant d'accéder à GitLab pendant ce temps. Si vous craignez d'affecter d'autres utilisateurs sur un système en production, vous pouvez exécuter un processus Rails distinct pour déboguer le problème :

1. Connectez-vous à votre compte GitLab.
1. Copiez l'URL qui pose problème (par exemple, `https://gitlab.com/ABC`).
1. Créez un jeton d'accès personnel pour votre utilisateur (Paramètres utilisateur -> Jetons d'accès).
1. Ouvrez la [console Rails GitLab.](rails_console.md#starting-a-rails-console-session)
1. Dans la console Rails, exécutez :

   ```ruby
   app.get '<URL FROM STEP 2>/?private_token=<TOKEN FROM STEP 3>'
   ```

   Par exemple :

   ```ruby
   app.get 'https://gitlab.com/gitlab-org/gitlab-foss/-/issues/1?private_token=123456'
   ```

1. Dans une nouvelle fenêtre, exécutez `top`. Il devrait afficher ce processus Ruby utilisant 100 % du CPU. Notez le PID.
1. Suivez l'étape 2 de la section précédente sur l'utilisation de GDB.

### GitLab :  L'API n'est pas accessible {#gitlab-api-is-not-accessible}

Cela se produit souvent lorsque GitLab Shell tente de demander une autorisation via l'API interne (par exemple, `http://localhost:8080/api/v4/internal/allowed`), et que quelque chose dans la vérification échoue. Ce problème peut se produire pour les raisons suivantes :

1. Délai d'expiration lors de la connexion à une base de données (par exemple, PostgreSQL ou Redis)
1. Erreur dans les hooks Git ou les règles de push
1. Erreur lors de l'accès au dépôt (par exemple, handles NFS obsolètes)

Pour diagnostiquer ce problème, essayez de reproduire le problème, puis vérifiez s'il existe un worker Puma qui tourne via `top`. Essayez d'utiliser les techniques `gdb` documentées précédemment. De plus, l'utilisation de `strace` peut aider à isoler les problèmes :

```shell
strace -ttTfyyy -s 1024 -p <PID of puma worker> -o /tmp/puma.txt
```

Si vous ne pouvez pas isoler quel worker Puma pose problème, essayez d'exécuter `strace` sur tous les workers Puma pour voir où le point de terminaison `/internal/allowed` est bloqué :

```shell
ps auwx | grep puma | awk '{ print " -p " $2}' | xargs  strace -ttTfyyy -s 1024 -o /tmp/puma.txt
```

Le résultat dans `/tmp/puma.txt` peut aider à diagnostiquer la cause racine.

## Sujets connexes {#related-topics}

- [Utiliser un serveur de métriques dédié pour exporter les métriques web](../monitoring/prometheus/web_exporter.md)

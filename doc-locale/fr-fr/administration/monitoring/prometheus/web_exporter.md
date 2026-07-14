---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Exportateur web (serveur de métriques dédié)
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Améliorez la fiabilité et les performances de votre surveillance GitLab en collectant les métriques séparément de votre serveur d'application principal. Un serveur de métriques dédié isole le trafic de surveillance des requêtes des utilisateurs, empêchant la collecte de métriques d'impacter les performances de l'application.

Pour les installations de taille moyenne à grande, cette séparation peut fournir une collecte de données plus cohérente pendant les périodes de pointe et peut réduire le risque de manquer des métriques critiques pendant les périodes de forte charge.

## Fonctionnement de la collecte de métriques GitLab {#how-gitlab-metrics-collection-works}

Lors de la surveillance de GitLab avec Prometheus, GitLab exécute divers collecteurs qui échantillonnent l'application pour des données relatives à l'utilisation, la charge et les performances. GitLab peut ensuite mettre ces données à disposition d'un scraper Prometheus en exécutant un ou plusieurs exportateurs Prometheus. Un exportateur Prometheus est un serveur HTTP qui sérialise les données de métriques dans un format compréhensible par le scraper Prometheus.

> [!note]
> Cette page concerne les métriques des applications web. Pour exporter les métriques des jobs en arrière-plan, apprenez comment [configurer le serveur de métriques Sidekiq](../../sidekiq/_index.md#configure-the-sidekiq-metrics-server).

Nous fournissons deux mécanismes par lesquels les métriques des applications web peuvent être exportées :

- Via l'application Rails principale. Cela signifie que le serveur d'application que nous utilisons, Puma, rend les données de métriques disponibles via son propre point de terminaison `/-/metrics`. Il s'agit de la configuration par défaut, décrite dans GitLab Metrics. Vous devriez utiliser cette configuration par défaut pour les petites installations GitLab où la quantité de métriques collectées est faible.
- Via un serveur de métriques dédié. L'activation de ce serveur amène Puma à lancer un processus supplémentaire dont la seule responsabilité est de servir les métriques. Cette approche conduit à une meilleure isolation des pannes et de meilleures performances pour les très grandes installations GitLab, mais implique une utilisation de mémoire supplémentaire. Nous recommandons cette approche pour les installations GitLab de taille moyenne à grande qui recherchent des performances et une disponibilité élevées.

Le serveur dédié et le point de terminaison Rails `/-/metrics` servent les mêmes données ; ils sont donc fonctionnellement équivalents et ne diffèrent que par leurs caractéristiques de performance.

Pour activer le serveur dédié :

1. [Activer Prometheus](_index.md#configuring-prometheus).
1. Modifiez `/etc/gitlab/gitlab.rb` pour ajouter (ou trouver et décommenter) les lignes suivantes. Assurez-vous que `puma['exporter_enabled']` est défini sur `true` :

   ```ruby
   puma['exporter_enabled'] = true
   puma['exporter_address'] = "127.0.0.1"
   puma['exporter_port'] = 8083
   ```

1. Configurez le scraper Prometheus :
   - Si vous utilisez le Prometheus fourni avec GitLab, assurez-vous que son [`scrape_config` pointe vers `localhost:8083/metrics`](_index.md#adding-custom-scrape-configurations).
   - Si vous utilisez un serveur Prometheus externe, configurez ce [serveur externe pour scraper le nouveau point de terminaison](_index.md#using-an-external-prometheus-server).
1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Les métriques peuvent désormais être servies et scrapées depuis `localhost:8083/metrics`.

## Activer HTTPS {#enable-https}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/364771) dans GitLab 15.2.

{{< /history >}}

Pour servir les métriques via HTTPS au lieu de HTTP, activez TLS dans les paramètres de l'exportateur :

1. Modifiez `/etc/gitlab/gitlab.rb` pour ajouter (ou trouver et décommenter) les lignes suivantes :

   ```ruby
   puma['exporter_tls_enabled'] = true
   puma['exporter_tls_cert_path'] = "/path/to/certificate.pem"
   puma['exporter_tls_key_path'] = "/path/to/private-key.pem"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Lorsque TLS est activé, le même `port` et la même `address` sont utilisés comme décrit précédemment. Le serveur de métriques ne peut pas servir à la fois HTTP et HTTPS en même temps.

## Sujets connexes {#related-topics}

- [Installation Docker de GitLab](../../../install/docker/_index.md)
- [Surveillance de GitLab avec Prometheus](_index.md)
- [Métriques GitLab](_index.md#gitlab-metrics)
- [Opérations Puma](../../operations/puma.md)

## Dépannage {#troubleshooting}

### Le conteneur Docker manque d'espace {#docker-container-runs-out-of-space}

Lors de l'exécution de GitLab dans Docker, votre conteneur peut manquer d'espace. Cela peut se produire si vous activez certaines fonctionnalités qui augmentent votre consommation d'espace, par exemple Web Exporter.

Pour contourner ce problème, [mettez à jour votre `shm-size`](../../../install/docker/troubleshooting.md#devshm-mount-not-having-enough-space-in-docker-container).

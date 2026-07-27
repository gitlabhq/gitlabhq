---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Données d'événement"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Bascule [activée](https://gitlab.com/gitlab-org/gitlab/-/issues/510333) dans GitLab 17.11.
- Remplacement par variable d'environnement [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/567724) dans GitLab 18.9.

{{< /history >}}

## Suivi des données d'utilisation du produit au niveau des événements {#data-tracking-for-product-usage-at-event-level}

**Important** :  À partir de GitLab 18.0, les instances Self-Managed et Dedicated collectent des données au niveau des événements, offrant des informations plus détaillées sur l'utilisation du produit. Auparavant, seules des métriques agrégées étaient collectées auprès des instances Self-Managed.

Pour en savoir plus sur les modifications apportées à la collecte des données d'utilisation du produit, lisez le billet de blog [More granular product usage insights for GitLab Self-Managed and Dedicated](https://about.gitlab.com/blog/more-granular-product-usage-insights-for-gitlab-self-managed-and-dedicated/).

### Données d'événement {#event-data}

Les données d'événement suivent les interactions (ou actions) au sein de la plateforme GitLab. Ces interactions ou actions peuvent être initiées par l'utilisateur, comme le lancement de pipelines CI/CD, la fusion d'un merge request, le déclenchement d'un webhook ou la création d'un ticket. Les actions peuvent également résulter d'un traitement système en arrière-plan, comme la réussite d'un pipeline planifié. La collecte des données d'événement est axée sur les actions des utilisateurs et les métadonnées associées à ces actions.

Les identifiants utilisateur sont pseudonymisés pour protéger la vie privée, et GitLab n'entreprend aucun processus pour réidentifier ou associer les métriques à des utilisateurs individuels. Les données d'événement ne comprennent pas le code source ni d'autres contenus créés par les clients et stockés dans GitLab.

Pour en savoir plus, consultez également :

- [Dictionnaire des métriques](https://metrics.gitlab.com/?status=active) pour une liste des événements et des métriques
- [Informations sur l'utilisation des produits par les clients](https://handbook.gitlab.com/handbook/legal/privacy/customer-product-usage-information/)

### Avantages des données d'événement {#benefits-of-event-data}

Les données au niveau des événements améliorent plusieurs avantages de Service Ping en offrant des informations plus granulaires sans identifier les utilisateurs.

- Assistance proactive :  Les données granulaires permettent à nos Customer Success Managers (CSMs) et à nos équipes d'assistance d'accéder à des informations plus détaillées, leur permettant d'approfondir l'analyse et de créer des métriques personnalisées adaptées aux besoins spécifiques de votre organisation, plutôt que de se fier à des métriques plus génériques et agrégées.
- Conseils ciblés :  Les données au niveau des événements offrent une compréhension plus approfondie de la façon dont les fonctionnalités sont utilisées, nous aidant à identifier des opportunités d'optimisation et d'amélioration. La profondeur des données nous permet de formuler des recommandations plus précises et exploitables pour vous aider à maximiser la valeur de GitLab et à améliorer vos workflows.
- Rapports de benchmarking anonymisés :  Les données d'événement granulaires permettent des comparaisons de performances plus précises et pertinentes avec des organisations similaires en se concentrant sur des modèles d'utilisation détaillés, plutôt que sur des données agrégées de haut niveau.

### Activer ou désactiver la collecte de données au niveau des événements {#enable-or-disable-event-level-data-collection}

> [!note]
> Si le suivi Snowplow est activé, il sera automatiquement désactivé lorsque vous activerez le suivi de l'utilisation du produit. Une seule méthode de collecte de données peut être active à la fois.

Pour activer ou désactiver la collecte de données au niveau des événements :

1. Connectez-vous en tant qu'utilisateur avec un accès administrateur.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Metrics and Profiling**.
1. Développez **Suivi des événements**.
1. Pour activer le paramètre, cochez la case **Activer le suivi d'événement**. Pour désactiver le paramètre, décochez la case.
1. Sélectionnez **Sauvegarder les modifications**.

### Configurer la collecte de données au niveau des événements par programmation {#programmatically-configure-event-level-data-collection}

Vous pouvez configurer la collecte de données au niveau des événements par programmation en utilisant :

- **Initial defaults** :  S'applique uniquement lors de la première installation
- **Environment variable override** :  S'applique au moment de l'exécution et a la priorité sur les paramètres de la base de données

#### Valeurs par défaut initiales (installation uniquement) {#initial-defaults-installation-only}

Ces paramètres s'appliquent uniquement lors de l'installation initiale de GitLab. La modification de ces paramètres après l'installation n'a aucun effet.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Définissez `gitlab_rails['initial_gitlab_product_usage_data']` sur `false` dans `/etc/gitlab/gitlab.rb` :

```ruby
gitlab_rails['initial_gitlab_product_usage_data'] = false
```

Reconfigurez ensuite GitLab :

```shell
sudo gitlab-ctl reconfigure
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Définissez `global.appConfig.initialDefaults.gitlabProductUsageData` sur `false` dans votre fichier de valeurs :

```yaml
global:
  appConfig:
    initialDefaults:
      gitlabProductUsageData: false
```

Ou via la ligne de commande :

```shell
helm install gitlab gitlab/gitlab \
  --set global.appConfig.initialDefaults.gitlabProductUsageData=false
```

{{< /tab >}}

{{< /tabs >}}

#### Remplacement par variable d'environnement (exécution) {#environment-variable-override-runtime}

> [!note]
> Introduit dans GitLab 18.9.

La variable d'environnement `GITLAB_PRODUCT_USAGE_DATA_ENABLED` vous permet de contrôler la collecte de données au niveau des événements au moment de l'exécution. Lorsqu'elle est définie, cette variable d'environnement :

- A la priorité sur le paramètre de la base de données
- Ne peut pas être modifiée via l'interface utilisateur Admin (la bascule est désactivée)
- S'applique immédiatement sans nécessiter de migration de base de données

Cela est utile pour :

- Les environnements air-gapped nécessitant une configuration automatisée
- Les déploiements nécessitant des paramètres cohérents entre les mises à niveau
- Les workflows de déploiement automatisés où l'accès à l'interface utilisateur n'est pas pratique

Les valeurs valides sont `true` ou `false`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Définissez la variable d'environnement dans `/etc/gitlab/gitlab.rb` :

```ruby
gitlab_rails['env']['GITLAB_PRODUCT_USAGE_DATA_ENABLED'] = 'false'
```

Reconfigurez ensuite GitLab :

```shell
sudo gitlab-ctl reconfigure
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Définissez la variable d'environnement en utilisant `extraEnv` dans votre fichier de valeurs :

```yaml
gitlab:
  sidekiq:
    extraEnv:
      GITLAB_PRODUCT_USAGE_DATA_ENABLED: 'false'
  webservice:
    extraEnv:
      GITLAB_PRODUCT_USAGE_DATA_ENABLED: 'false'
```

Ou via la ligne de commande :

```shell
helm upgrade gitlab gitlab/gitlab \
  --set gitlab.sidekiq.extraEnv.GITLAB_PRODUCT_USAGE_DATA_ENABLED='false' \
  --set gitlab.webservice.extraEnv.GITLAB_PRODUCT_USAGE_DATA_ENABLED='false'
```

{{< /tab >}}

{{< tab title="Docker" >}}

Transmettez la variable d'environnement lors du démarrage du conteneur :

```shell
docker run --env GITLAB_PRODUCT_USAGE_DATA_ENABLED=false gitlab/gitlab-ee:latest
```

Ou dans un fichier Docker Compose :

```yaml
services:
  gitlab:
    image: gitlab/gitlab-ee:latest
    environment:
      GITLAB_PRODUCT_USAGE_DATA_ENABLED: 'false'
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Définissez la variable d'environnement avant de démarrer GitLab :

```shell
export GITLAB_PRODUCT_USAGE_DATA_ENABLED=false
```

Ou ajoutez-la à votre fichier de service systemd ou à votre script d'initialisation.

{{< /tab >}}

{{< /tabs >}}

#### Vérifier la source du paramètre actuel {#check-the-current-setting-source}

Lorsque le remplacement par variable d'environnement est actif, l'interface utilisateur Admin affiche une bannière d'avertissement indiquant que le paramètre est contrôlé par une variable d'environnement et ne peut pas être modifié via l'interface utilisateur.

Vous pouvez également vérifier la source du paramètre via l'API :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/application/settings" | jq '.gitlab_product_usage_data_enabled, .gitlab_product_usage_data_source'
```

Le champ `gitlab_product_usage_data_source` retourne soit :

- `environment` :  Le paramètre est contrôlé par la variable d'environnement `GITLAB_PRODUCT_USAGE_DATA_ENABLED`
- `database` :  Le paramètre est contrôlé par la base de données (peut être modifié via l'interface utilisateur Admin)

### Délai de livraison des événements {#event-delivery-timing}

Les événements sont transmis à GitLab presque immédiatement après leur survenance. Le système collecte les événements en petits lots, en envoyant les données une fois que 10 événements ont été rassemblés. Cette approche offre une livraison quasi en temps réel tout en maintenant une utilisation efficace du réseau.

### Taille du payload et compression {#payload-size-and-compression}

Chaque événement représente environ 10 Ko au format JSON. Des lots de 10 événements donnent une taille de payload non compressée d'environ 100 Ko. Avant la transmission, le payload est compressé pour minimiser la taille du transfert de données et optimiser les performances.

### Journaux des données d'événement {#event-data-logs}

Les données de suivi au niveau des événements sont enregistrées dans le fichier `product_usage_data.log`. Ce journal contient des entrées au format JSON des événements d'utilisation du produit suivis, notamment les informations sur le payload et les données de contexte. Chaque ligne représente un événement de suivi distinct et toutes les données qui ont été envoyées.

Le fichier journal est situé à :

- `/var/log/gitlab/gitlab-rails/product_usage_data.log` sur les installations du package Linux
- `/home/git/gitlab/log/product_usage_data.log` sur les installations auto-compilées

Bien que ces journaux offrent une visibilité approfondie sur la transmission des données, ils sont conçus spécifiquement pour l'inspection par les équipes de sécurité plutôt que pour l'analyse de l'utilisation des fonctionnalités. Pour des informations plus détaillées sur le système de journalisation, consultez la [documentation du système de journaux](../logs/_index.md#product-usage-data-log).

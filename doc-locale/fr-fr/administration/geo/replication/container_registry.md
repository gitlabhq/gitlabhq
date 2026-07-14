---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Registre de conteneurs pour un site secondaire
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez configurer un registre de conteneurs sur votre site Geo **secondaire** qui réplique les images de conteneurs depuis celui du site Geo **principal**. Cette réplication d'images de conteneurs est utilisée uniquement à des fins de reprise après sinistre.

Ne poussez pas vers le registre de conteneurs sur le site Geo **secondaire**, car les données ne sont pas propagées vers le site **principal**.

Nous ne recommandons pas d'extraire des données du registre de conteneurs depuis le site **secondaire**, car elles peuvent être obsolètes. La demande de fonctionnalité [ticket 365864](https://gitlab.com/gitlab-org/gitlab/-/issues/365864) permettrait de résoudre ce problème. Vous êtes encouragé à voter pour ce ticket afin d'enregistrer votre intérêt.

> [!warning]
> **Important :** La base de données de métadonnées du registre de conteneurs est distincte de la réplication des images de conteneurs. Bien que les images de conteneurs se répliquent des sites principaux vers les sites secondaires, la base de données de métadonnées ne le fait pas. Lors de l'utilisation de GitLab Geo avec la base de données de métadonnées du registre de conteneurs activée, vous devez configurer des instances PostgreSQL externes séparées pour le registre de conteneurs sur chaque site Geo (principal et secondaire). La base de données de métadonnées du registre de conteneurs ne peut pas utiliser la base de données PostgreSQL gérée par GitLab par défaut. La base de données de métadonnées de chaque site fonctionne de manière indépendante, sans réplication entre elles. Pour les instructions de configuration, consultez [Utilisation d'une base de données externe](../../packages/container_registry_metadata_database.md#using-an-external-database).

## Registres de conteneurs pris en charge {#supported-container-registries}

Geo prend en charge les types de registres de conteneurs suivants :

- [Docker](https://distribution.github.io/distribution/)
- [OCI](https://github.com/opencontainers/distribution-spec/blob/main/spec.md)

## Formats d'images pris en charge {#supported-image-formats}

Les formats d'images de conteneurs suivants sont pris en charge par Geo :

- [Docker V2, schéma 1](https://distribution.github.io/distribution/spec/deprecated-schema-v1/)
- [Docker V2, schéma 2](https://distribution.github.io/distribution/spec/manifest-v2-2/)
- [OCI (Open Container Initiative)](https://github.com/opencontainers/image-spec)

De plus, Geo prend également en charge les [images de cache BuildKit](https://github.com/moby/buildkit).

## Stockage pris en charge {#supported-storage}

### Docker {#docker}

Pour plus d'informations sur les pilotes de stockage de registre pris en charge, consultez [les pilotes de stockage du registre Docker](https://distribution.github.io/distribution/storage-drivers/)

Lisez les [considérations relatives à l'équilibrage de charge](https://distribution.github.io/distribution/about/deploying/#load-balancing-considerations) lors du déploiement du registre, et comment configurer le pilote de stockage pour le [registre de conteneurs](../../packages/container_registry.md#use-object-storage) intégré à GitLab.

### Registres prenant en charge les artefacts OCI {#registries-that-support-oci-artifacts}

Les registres suivants prennent en charge les artefacts OCI :

- CNCF Distribution - vérification locale/hors ligne
- Azure Container Registry (ACR)
- Amazon Elastic Container Registry (ECR)
- Google Artifact Registry (GAR)
- GitHub Packages container registry (GHCR)
- Bundle Bar

Pour plus d'informations, consultez la [spécification de distribution OCI](https://github.com/opencontainers/distribution-spec).

## Configurer la réplication du registre de conteneurs {#configure-container-registry-replication}

Vous pouvez activer une réplication indépendante du stockage afin qu'elle puisse être utilisée pour un stockage cloud ou local. Chaque fois qu'une nouvelle image est poussée vers le site **principal**, chaque site **secondaire** la récupère dans son propre dépôt de conteneurs.

Pour configurer la réplication du registre de conteneurs :

1. Configurez le [site **principal**](#configure-primary-site).
1. Configurez le [site **secondaire**](#configure-secondary-site).
1. Vérifiez la [réplication](#verify-replication) du registre de conteneurs.

### Configurer le site principal {#configure-primary-site}

Assurez-vous que le registre de conteneurs est configuré et fonctionnel sur le site **principal** avant de suivre les étapes suivantes.

Pour pouvoir répliquer de nouvelles images de conteneurs, le registre de conteneurs doit envoyer des événements de notification au site **principal** à chaque push. Le jeton partagé entre le registre de conteneurs et les nœuds web du site **principal** est utilisé pour sécuriser les communications.

1. Connectez-vous en SSH à votre serveur GitLab **principal** et connectez-vous en tant que root (pour GitLab HA, vous n'avez besoin que d'un nœud Registry) :

   ```shell
   sudo -i
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Configure the registry to listen on the public/internal interface
   # Replace with the appropriate interface (for example, '0.0.0.0' for all interfaces)
   registry['registry_http_addr'] = '0.0.0.0:5000'
   registry['notifications'] = [
     {
       'name' => 'geo_event',
       'url' => 'https://<example.com>/api/v4/container_registry_event/events',
       'timeout' => '500ms',
       'threshold' => 5,
       'backoff' => '1s',
       'headers' => {
         'Authorization' => ['<replace_with_a_secret_token>']
       }
     }
   ]
   ```

   Remplacez `<example.com>` par l'`external_url` défini dans le fichier `/etc/gitlab/gitlab.rb` de votre site principal, et remplacez `<replace_with_a_secret_token>` par une chaîne alphanumérique sensible à la casse qui commence par une lettre. Vous pouvez en générer une avec `/dev/urandom tr -dc _A-Z-a-z-0-9 | head -c 32 | sed "s/^[0-9]*//"; echo`

   > [!note]
   > Si vous utilisez un registre externe (pas celui intégré à GitLab), vous n'avez besoin de spécifier que le secret de notification (`registry['notification_secret']`) dans le fichier `/etc/gitlab/gitlab.rb`.

1. Pour GitLab HA uniquement. Modifiez `/etc/gitlab/gitlab.rb` sur chaque nœud web :

   ```ruby
   registry['notification_secret'] = '<replace_with_a_secret_token_generated_above>'
   ```

1. Reconfigurez chaque nœud que vous venez de mettre à jour :

   ```shell
   gitlab-ctl reconfigure
   ```

### Configurer le site secondaire {#configure-secondary-site}

Assurez-vous que le registre de conteneurs est configuré et fonctionnel sur le site **secondaire** avant de suivre les étapes suivantes.

Les étapes suivantes doivent être effectuées sur chaque site **secondaire** sur lequel vous attendez de voir les images de conteneurs répliquées.

Étant donné que nous devons permettre au site **secondaire** de communiquer de manière sécurisée avec le registre de conteneurs du site **principal**, nous devons disposer d'une seule paire de clés pour tous les sites. Le site **secondaire** utilise cette clé pour générer un JWT à courte durée de vie avec accès en lecture seule permettant d'accéder au registre de conteneurs du site **principal**.

Pour chaque nœud d'application et Sidekiq sur le site **secondaire** :

1. Connectez-vous en SSH au nœud et connectez-vous en tant qu'utilisateur `root` :

   ```shell
   sudo -i
   ```

1. Copiez `/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key` depuis le site **principal** vers le nœud.
1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez :

   ```ruby
   gitlab_rails['geo_registry_replication_enabled'] = true

   # Primary registry's hostname and port, it will be used by
   # the secondary node to directly communicate to primary registry
   gitlab_rails['geo_registry_replication_primary_api_url'] = 'https://primary.example.com:5050/'
   ```

1. Reconfigurez le nœud pour que la modification prenne effet :

   ```shell
   gitlab-ctl reconfigure
   ```

### Vérifier la réplication {#verify-replication}

Pour vérifier que la réplication du registre de conteneurs fonctionne, sur le site **secondaire** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Nœuds**. La réplication initiale, ou « remplissage », est probablement encore en cours.

Vous pouvez surveiller le processus de synchronisation sur chaque site Geo depuis le tableau de bord **Geo Nodes** du site **principal** dans votre navigateur.

## Dépannage {#troubleshooting}

### Confirmer que la réplication du registre de conteneurs est activée {#confirm-that-container-registry-replication-is-enabled}

Cela peut être effectué avec une vérification à l'aide de la [console Rails](../../operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Geo::ContainerRepositoryRegistry.replication_enabled?
```

### Événement de notification du registre de conteneurs manquant {#missing-container-registry-notification-event}

1. Lorsqu'une image est poussée vers le registre de conteneurs du site principal, cela devrait déclencher une [notification du registre de conteneurs](../../packages/container_registry.md#configure-container-registry-notifications)
1. Le registre de conteneurs du site principal appelle l'API du site principal sur `https://<example.com>/api/v4/container_registry_event/events`
1. Le site principal insère un enregistrement dans la table `geo_events` avec `replicable_name: 'container_repository', model_record_id: <ID of the container repository>`.
1. L'enregistrement est répliqué par PostgreSQL vers la base de données du site secondaire.
1. Le service Geo Log Cursor traite le nouvel événement et met en file d'attente un job Sidekiq `Geo::EventWorker`

Pour vérifier que cela fonctionne correctement, poussez une image vers le registre sur le site principal, et exécutez la commande suivante sur la console Rails pour vérifier que la notification a été reçue et traitée sous forme d'événement :

```ruby
Geo::Event.where(replicable_name: 'container_repository')
```

Vous pouvez vérifier cela davantage en consultant `geo.log` pour les entrées provenant de `Geo::ContainerRepositorySyncService`.

### Les journaux d'événements du registre indiquent le statut de réponse 401 Unauthorized non accepté {#registry-events-logs-response-status-401-unauthorized-unaccepted}

Les erreurs `401 Unauthorized` indiquent que la notification du registre de conteneurs du site principal n'est pas acceptée par l'application Rails, l'empêchant d'informer GitLab qu'un push a été effectué.

Pour résoudre ce problème, assurez-vous que les en-têtes d'autorisation envoyés avec la notification du registre correspondent à ce qui est configuré sur le site principal, comme cela devrait être fait lors de l'étape [Configurer le site principal](#configure-primary-site).

#### Erreur de registre : `token from untrusted issuer: "<token>"` {#registry-error-token-from-untrusted-issuer-token}

Lors de la réplication d'images de conteneurs dans Geo, vous pourriez voir l'erreur `token from untrusted issuer: "<token>"`.

Ce problème survient lorsque la configuration du registre de conteneurs est incorrecte, entraînant l'échec de l'authentification JWT de Sidekiq.

Pour résoudre ce problème :

1. Assurez-vous que les deux sites partagent une seule paire de clés de signature, comme décrit dans [configurer le site secondaire](#configure-secondary-site).
1. Vérifiez que les deux registres de conteneurs ainsi que les sites principal et secondaire sont configurés pour utiliser le même émetteur de jeton. Pour plus d'informations, consultez [configurer GitLab et le registre sur des nœuds séparés](../../packages/container_registry.md#configure-gitlab-and-registry-on-separate-nodes-linux-package-installations).
1. Pour les déploiements multi-nœuds, confirmez que l'émetteur configuré sur le nœud Sidekiq correspond à la valeur configurée sur les registres.

### Déclencher manuellement un événement de synchronisation du registre de conteneurs {#manually-trigger-a-container-registry-sync-event}

Pour faciliter le dépannage, vous pouvez déclencher manuellement le processus de réplication du registre de conteneurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Dans **Détails de Réplication** pour un **Secondary Site**, sélectionnez **Dépôts de conteneurs**.
1. Sélectionnez **Resynchroniser** pour une ligne, ou **Tout resynchroniser**.

Vous pouvez également déclencher manuellement une resynchronisation en exécutant les commandes suivantes sur la console Rails du site secondaire :

```ruby
registry = Geo::ContainerRepositoryRegistry.first # Choose a Geo registry entry
registry.replicator.sync # Resync the container repository
pp registry.reload # Look at replication state fields

#<Geo::ContainerRepositoryRegistry:0x00007f54c2a36060
 id: 1,
 container_repository_id: 1,
 state: "2",
 retry_count: 0,
 last_sync_failure: nil,
 retry_at: nil,
 last_synced_at: Thu, 28 Sep 2023 19:38:05.823680000 UTC +00:00,
 created_at: Mon, 11 Sep 2023 15:38:06.262490000 UTC +00:00>
```

Le champ `state` représente l'état de synchronisation :

- `"0"` : synchronisation en attente (signifie généralement qu'elle n'a jamais été synchronisée)
- `"1"` : synchronisation démarrée (un job de synchronisation est en cours d'exécution)
- `"2"` : synchronisé avec succès
- `"3"` : échec de la synchronisation

### Le dépôt n'est pas resynchronisé après une interruption {#repository-not-resynced-after-downtime}

Si la réplication du registre de conteneurs a été désactivée pendant une période, que ce soit via le feature flag `geo_container_repository_replication` ou une mauvaise configuration, les images poussées durant cette période pourraient ne pas se synchroniser automatiquement vers le site **secondaire**.

Les nouveaux dépôts de conteneurs créés pendant l'interruption sont automatiquement pris en charge par le worker de remplissage après la réactivation de la réplication. Cependant, les mises à jour des dépôts de conteneurs existants (par exemple, de nouveaux tags poussés vers un dépôt existant) ne sont pas automatiquement resynchronisées. L'interface d'administration Geo peut toujours indiquer 100 % de réplication car l'état de synchronisation est basé sur l'état de l'entrée du registre, et non sur la vérification du contenu.

Les dépôts de conteneurs mis à jour se resynchronisent éventuellement après que le cycle de revérification du site **principal** détecte une discordance de somme de contrôle. Pour plus d'informations sur l'intervalle de revérification, consultez [la re-vérification du dépôt](../disaster_recovery/background_verification.md#repository-re-verification).

Pour forcer une resynchronisation immédiate au lieu d'attendre la revérification, consultez [réessayer manuellement la réplication ou la vérification](troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification).

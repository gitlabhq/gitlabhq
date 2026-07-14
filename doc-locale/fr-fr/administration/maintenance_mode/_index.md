---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mode de maintenance GitLab
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le Mode de maintenance permet aux administrateurs de réduire les opérations d'écriture au minimum pendant l'exécution des tâches de maintenance. L'objectif principal est de bloquer toutes les actions externes qui modifient l'état interne. L'état interne inclut la base de données PostgreSQL, mais surtout les fichiers, les dépôts Git et les dépôts de conteneurs.

Lorsque le Mode de maintenance est activé, les actions en cours se terminent relativement rapidement car aucune nouvelle action n'arrive et les modifications de l'état interne sont minimales. Dans cet état, diverses tâches de maintenance sont plus faciles à effectuer. Les services peuvent être complètement arrêtés ou davantage dégradés pendant une période plus courte que ce qui serait autrement nécessaire. Par exemple, l'arrêt des cron jobs et le vidage des files d'attente devraient être assez rapides.

Le Mode de maintenance autorise la plupart des actions externes qui ne modifient pas l'état interne. À un niveau général, les requêtes HTTP `POST`, `PUT`, `PATCH` et `DELETE` sont bloquées et un aperçu détaillé de [la façon dont les cas spéciaux sont gérés](#rest-api) est disponible.

## Activer le Mode de maintenance {#enable-maintenance-mode}

Activez le Mode de maintenance en tant qu'administrateur de l'une des façons suivantes :

- **Interface Web** :
  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
  1. Développez **Mode de maintenance** et activez/désactivez **Activer le Mode de maintenance**. Vous pouvez éventuellement ajouter un message pour la bannière.
  1. Sélectionnez **Sauvegarder les modifications**.

- **API** :

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?maintenance_mode=true"
  ```

## Désactiver le Mode de maintenance {#disable-maintenance-mode}

Désactivez le Mode de maintenance de l'une de ces trois façons :

- **Interface Web** :
  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
  1. Développez **Mode de maintenance** et activez/désactivez **Activer le Mode de maintenance**. Vous pouvez éventuellement ajouter un message pour la bannière.
  1. Sélectionnez **Sauvegarder les modifications**.

- **API** :

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?maintenance_mode=false"
  ```

## Comportement des fonctionnalités GitLab en Mode de maintenance {#behavior-of-gitlab-features-in-maintenance-mode}

Lorsque le Mode de maintenance est activé, une bannière s'affiche en haut de la page. La bannière peut être personnalisée avec un message spécifique.

Une erreur s'affiche lorsqu'un utilisateur tente d'effectuer une opération d'écriture non autorisée.

![Bannière du Mode de maintenance et message d'erreur](img/maintenance_mode_error_message_v17_6.png)

> [!note]
> Dans certains cas, le retour visuel d'une action peut être trompeur. Par exemple, lorsqu'on ajoute un projet aux favoris, le bouton **Ajouter aux favoris** change pour afficher l'action **Supprimer des favoris**. Cependant, cela ne met à jour que l'interface utilisateur et ne tient pas compte du statut de la requête POST.

### Fonctions d'administration {#administrator-functions}

Les administrateurs système peuvent modifier les paramètres de l'application. Cela leur permet de désactiver le Mode de maintenance après son activation.

### Authentification {#authentication}

Tous les utilisateurs peuvent se connecter et se déconnecter de l'instance GitLab, mais aucun nouvel utilisateur ne peut être créé.

Si des [synchronisations LDAP](../auth/ldap/_index.md) sont planifiées pour cette période, elles échouent car la création d'utilisateurs est désactivée. De même, les [créations d'utilisateurs basées sur SAML](../../integration/saml.md#configure-saml-support-in-gitlab) échouent.

### Actions Git {#git-actions}

Toutes les opérations Git en lecture seule continuent de fonctionner, par exemple `git clone` et `git pull`. Toutes les opérations d'écriture échouent, que ce soit via la CLI ou l'IDE Web, avec le message d'erreur : `Git push is not allowed because this GitLab instance is currently in (read-only) maintenance mode.`

Si Geo est activé, les Git pushes vers les sites primaires et secondaires échouent.

### Merge requests, tickets, epics {#merge-requests-issues-epics}

Toutes les actions d'écriture à l'exception de celles mentionnées précédemment échouent. Par exemple, un utilisateur ne peut pas mettre à jour des merge requests ou des tickets.

### E-mail entrant {#incoming-email}

La création de nouvelles réponses aux tickets, de tickets (y compris les nouveaux tickets Service Desk) et de merge requests [par e-mail](../incoming_email.md) échoue.

### E-mail sortant {#outgoing-email}

Les e-mails de notification continuent d'arriver, mais les e-mails nécessitant des écritures en base de données, comme la réinitialisation du mot de passe, n'arrivent pas.

### API REST {#rest-api}

Pour la plupart des requêtes JSON, `POST`, `PUT`, `PATCH` et `DELETE` sont bloquées, et l'API REST renvoie une réponse `503` avec le message d'erreur : `GitLab Maintenance: system is in maintenance mode`. Seules les requêtes suivantes sont autorisées :

|Requête HTTP | Routes autorisées |  Notes |
|:----:|:--------------------------------------:|:----:|
| `POST` | `/admin/application_settings/general` | Pour permettre la mise à jour des paramètres de l'application dans l'interface utilisateur d'administration |
| `PUT`  | `/api/v4/application/settings` | Pour permettre la mise à jour des paramètres de l'application via l'API REST |
| `POST` | `/users/sign_in` | Pour permettre aux utilisateurs de se connecter. |
| `POST` | `/users/sign_out`| Pour permettre aux utilisateurs de se déconnecter. |
| `POST` | `/oauth/token` | Pour permettre aux utilisateurs de se connecter pour la première fois à un site secondaire Geo. |
| `POST` | `/admin/session`, `/admin/session/destroy` | Pour autoriser le [mode Admin pour les administrateurs GitLab](https://gitlab.com/groups/gitlab-org/-/epics/2158) |
| `POST` | Chemins se terminant par `/compare`| Routes de révision Git. |
| `POST` | `.git/git-upload-pack` | Pour autoriser le Git pull/clone. |
| `POST` | `/api/v4/internal` | Routes d'API REST internes |
| `POST` | `/admin/sidekiq` | Pour permettre la gestion des jobs en arrière-plan dans la zone **Admin** |
| `POST` | `/admin/geo` | Pour permettre la mise à jour des nœuds Geo dans l'interface d'administration |
| `POST` | `/api/v4/geo_replication`| Pour permettre certaines actions de l'interface d'administration spécifiques à Geo sur les sites secondaires |

### API GraphQL {#graphql-api}

{{< history >}}

- L'ajout de la mutation `GeoRegistriesUpdate` dans la liste d'autorisation a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124259) dans GitLab 16.2.

{{< /history >}}

Les requêtes `POST /api/graphql` sont autorisées, mais les mutations sont bloquées avec le message d'erreur `You cannot perform write operations on a read-only instance`.

La seule mutation autorisée est `GeoRegistriesUpdate`, qui est utilisée pour resynchroniser et revérifier les registres.

### Intégration continue {#continuous-integration}

- Aucun nouveau job ni pipeline ne démarre, qu'ils soient planifiés ou non.
- Les jobs qui étaient déjà en cours d'exécution continuent d'afficher le statut `running` dans l'interface GitLab, même s'ils ont terminé de s'exécuter sur le GitLab Runner.
- Les jobs à l'état `running` depuis plus longtemps que la limite de temps du projet n'expirent pas.
- Les pipelines ne peuvent pas être démarrés, relancés ou annulés. Aucun nouveau job ne peut non plus être créé.
- Le statut des runners dans `/admin/runners` n'est pas mis à jour.
- `gitlab-runner verify` renvoie l'erreur `ERROR: Verifying runner... is removed`.

Une fois le Mode de maintenance désactivé, de nouveaux jobs sont de nouveau pris en charge. Les jobs qui étaient à l'état `running` avant l'activation du Mode de maintenance reprennent et leurs journaux recommencent à se mettre à jour.

> [!note]
> Vous devriez redémarrer les pipelines précédemment à l'état `running` après la désactivation du Mode de maintenance.

### Déploiements {#deployments}

Les déploiements n'aboutissent pas car les pipelines ne sont pas terminés.

Vous devriez désactiver les déploiements automatiques pendant le Mode de maintenance et les réactiver lorsqu'il est désactivé.

#### Intégration Terraform {#terraform-integration}

L'intégration Terraform dépend de l'exécution des pipelines CI, elle est donc bloquée.

### Registre de conteneurs {#container-registry}

`docker push` échoue avec cette erreur : `denied: requested access to the resource is denied`, mais `docker pull` fonctionne.

### Registre de paquets {#package-registry}

Le registre de paquets vous permet d'installer des paquets, mais pas d'en publier.

### Jobs en arrière-plan {#background-jobs}

Les jobs en arrière-plan (cron jobs, Sidekiq) continuent de fonctionner normalement, car ils ne sont pas automatiquement désactivés. Comme les jobs en arrière-plan effectuent des opérations pouvant modifier l'état interne de votre instance, vous pouvez en désactiver certains ou la totalité pendant que le mode de maintenance est activé.

[Lors d'un basculement Geo planifié](../geo/disaster_recovery/planned_failover.md#prevent-updates-to-the-primary-site), vous devriez désactiver tous les cron jobs, à l'exception de ceux liés à Geo.

Pour surveiller les files d'attente et désactiver les jobs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.
1. Dans le tableau de bord Sidekiq, sélectionnez **Cron** et désactivez les jobs individuellement ou tous à la fois en sélectionnant **Tout désactiver**.

### Gestion des incidents {#incident-management}

Les fonctions de [gestion des incidents](../../operations/incident_management/_index.md) sont limitées. La création d'[alertes](../../operations/incident_management/alerts.md) et d'[incidents](../../operations/incident_management/manage_incidents.md#create-an-incident) est entièrement suspendue. Les notifications et les alertes sur les alertes et les incidents sont donc désactivées.

### Feature flags {#feature-flags}

- Les feature flags de développement ne peuvent pas être activés ou désactivés via l'API REST, mais peuvent être basculés via la console Rails.
- [Le service de feature flags](../../operations/feature_flags.md) répond aux vérifications des feature flags, mais les feature flags ne peuvent pas être basculés

### Sites secondaires Geo {#geo-secondaries}

Lorsque le site primaire est en Mode de maintenance, les sites secondaires passent également automatiquement en Mode de maintenance.

Il est important de ne pas désactiver la réplication avant d'activer le Mode de maintenance.

La réplication, la vérification et les actions manuelles de resynchronisation et de revérification des registres via l'interface d'administration continuent de fonctionner, mais les Git pushes proxifiés vers le site primaire ne fonctionnent pas.

### Fonctionnalités de sécurité {#secure-features}

Les fonctionnalités qui dépendent de la création de tickets ou de la création ou de l'approbation de merge requests ne fonctionnent pas.

L'exportation d'une liste de vulnérabilités depuis une page de rapport de vulnérabilités ne fonctionne pas.

La modification du statut d'un résultat ou d'un objet de vulnérabilité ne fonctionne pas, même si aucune erreur n'est affichée dans l'interface utilisateur.

SAST et la détection des secrets ne peuvent pas être initiés car ils dépendent de la réussite des jobs CI/CD pour créer des artefacts.

## Exemple de cas d'utilisation : un basculement planifié {#an-example-use-case-a-planned-failover}

Dans le cas d'utilisation d'[un basculement planifié](../geo/disaster_recovery/planned_failover.md), quelques écritures dans la base de données primaire sont acceptables, car elles sont répliquées rapidement et ne sont pas significatives en nombre.

Pour la même raison, nous ne bloquons pas automatiquement les jobs en arrière-plan lorsque le Mode de maintenance est activé.

Les écritures en base de données qui en résultent sont acceptables. Ici, le compromis est entre une dégradation de service plus importante et la finalisation de la réplication.

Cependant, lors d'un basculement planifié, nous [demandons aux utilisateurs de désactiver manuellement les cron jobs non liés à Geo](../geo/disaster_recovery/planned_failover.md#prevent-updates-to-the-primary-site). En l'absence de nouvelles écritures en base de données et de cron jobs non liés à Geo, de nouveaux jobs en arrière-plan ne seraient soit pas créés du tout, soit créés en nombre minimal.

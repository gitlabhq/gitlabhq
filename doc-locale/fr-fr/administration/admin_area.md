---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
description: "Gérez votre instance GitLab et configurez les fonctionnalités dans l'interface utilisateur."
title: "Espace d'administration GitLab"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

La zone **Admin** fournit une interface web pour gérer et configurer les fonctionnalités d'une instance GitLab Self-Managed. Si vous êtes administrateur, pour accéder à la zone **Admin** :

- Dans GitLab 18.5 et versions ultérieures :
  - Dans le coin supérieur droit, sélectionnez **Admin**.
  - Dans la barre supérieure, sélectionnez **Rechercher ou aller à**, puis sélectionnez **Espace d’administration**.
- Dans GitLab 17.3 et versions ultérieures : dans la barre latérale gauche, en bas, sélectionnez **Admin**.
- Dans GitLab 16.7 et versions ultérieures : dans la barre latérale gauche, en bas, sélectionnez **Espace d’administration**.
- Dans GitLab 16.1 et versions ultérieures : dans la barre latérale gauche, sélectionnez **Rechercher ou aller à**, puis sélectionnez **Admin**.
- Dans GitLab 16.0 et versions antérieures : dans la barre supérieure, sélectionnez **Main menu** > **Admin**.

Si l'instance GitLab utilise le mode Admin, vous devez [activer le mode Admin pour votre session](settings/sign_in_restrictions.md#turn-on-admin-mode-for-your-session) avant que **Admin** soit visible.

> [!note]
> Seuls les administrateurs de GitLab Self-Managed ou GitLab Dedicated peuvent accéder à la zone **Admin**. Sur GitLab.com, la fonctionnalité de la zone **Admin** n'est pas disponible.

## Administration des projets {#administering-projects}

{{< history >}}

- Nouvelle apparence [introduite](https://gitlab.com/groups/gitlab-org/-/epics/17782) dans GitLab 18.2 [avec un flag](feature_flags/_index.md) nommé `admin_projects_vue`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/549452) dans GitLab 18.3. Indicateur de feature flag `admin_projects_vue` supprimé.

{{< /history >}}

Pour administrer tous les projets dans l'instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Projets**. La page affiche pour chaque projet :

   - Nom
   - Description
   - Niveau de visibilité
   - Rôle
   - Sujets
   - Statut
   - Taille de stockage
   - Nombre d'étoiles
   - Nombre de duplications
   - Nombre de merge requests
   - Nombre de tickets

1. Facultatif. Sélectionnez un onglet :

   - **Actif** affiche tous les projets actifs.
   - **Inactif** affiche les projets archivés ou en attente de suppression.

1. Facultatif. Combinez des filtres pour trouver les projets souhaités. Filtrer par :

   - Nom. Vous devez saisir au moins trois caractères.
   - Visibilité, soit publique, interne ou privée.
   - Langage de programmation.
   - Groupe ou espace de nommage d'utilisateur.
   - Projets pour lesquels vous avez le rôle Propriétaire.

1. Facultatif. Pour modifier l'ordre de tri, sélectionnez la liste déroulante de tri et choisissez l'ordre souhaité. Les options de tri disponibles sont :

   - Nom
   - Date de création
   - Date de mise à jour
   - Étoiles
   - Taille de stockage

### Modifier un projet {#edit-a-project}

Pour modifier le nom ou la description d'un projet depuis la page Projets de la zone **Admin** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Projets**.
1. Trouvez le projet que vous souhaitez modifier et sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Éditer**.
1. Modifiez le **Nom du projet** ou la **Description du projet**.
1. Sélectionnez **Enregistrer les modifications**.

### Supprimer un projet {#delete-a-project}

Pour supprimer un projet :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Projets**.
1. Trouvez le projet que vous souhaitez modifier et sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Supprimer**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Oui, supprimer le projet**.

## Administration des utilisateurs {#administering-users}

{{< history >}}

- Filtrage des utilisateurs [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) dans GitLab 17.0.

{{< /history >}}

La page Utilisateurs de la zone **Admin** affiche ces informations pour chaque utilisateur :

- Nom d'utilisateur
- Adresse e-mail
- Nombre d'adhésions à des projets
- Nombre d'adhésions à des groupes
- Date de création du compte
- Date de dernière activité

Pour administrer tous les utilisateurs depuis la page Utilisateurs de la zone **Admin** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Facultatif. Pour modifier l'ordre de tri, dont la valeur par défaut est le nom d'utilisateur :

   1. Sélectionnez la liste déroulante de tri.
   1. Sélectionnez l'ordre souhaité.

1. Facultatif. Utilisez la zone de recherche des utilisateurs pour rechercher et filtrer les utilisateurs par :

   - **Niveau d'accès** de l'utilisateur.
   - Si l'**authentification à deux facteurs** est activée ou désactivée.
   - **État** de l'utilisateur.
   - Si le **type** d'utilisateur est [un espace réservé](../user/import/mapping/post_migration_mapping.md#placeholder-users).

1. Facultatif. Dans le champ de recherche des utilisateurs, saisissez du texte, puis appuyez sur <kbd>Entrée</kbd>. Cette recherche textuelle non sensible à la casse applique une correspondance partielle au nom, au nom d'utilisateur et à l'adresse e-mail.

Pour modifier un utilisateur, trouvez la ligne de l'utilisateur et sélectionnez **Éditer**.

### Supprimer un utilisateur {#delete-a-user}

Pour supprimer l'utilisateur, ou supprimer l'utilisateur et ses contributions, depuis la page Utilisateurs de la zone **Admin** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Trouvez l'utilisateur que vous souhaitez supprimer. Dans la ligne, sélectionnez **Administration des utilisateurs** ({{< icon name="ellipsis_v" >}}), puis sélectionnez l'option souhaitée.

### Usurpation d'identité d'utilisateur {#user-impersonation}

Un administrateur peut incarner n'importe quel autre utilisateur, y compris d'autres administrateurs. Cela vous permet de voir ce que l'utilisateur voit dans GitLab et d'effectuer des actions en son nom.

Pour incarner un utilisateur :

- Via l'interface utilisateur :
  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
  1. Dans la liste des utilisateurs, sélectionnez un utilisateur.
  1. En haut à droite, sélectionnez **Incarner**.
  1. Pour arrêter l'usurpation, dans le coin supérieur droit, sélectionnez **Mettre fin à l'emprunt d'identité** ({{< icon name="incognito" >}}).
- Avec l'API, en utilisant des [jetons d'usurpation d'identité](../api/rest/authentication.md#impersonation-tokens).

Toutes les activités d'usurpation d'identité sont [capturées par les événements d'audit](compliance/audit_event_reports.md#user-impersonation). Par défaut, l'usurpation d'identité est activée. GitLab peut être configuré pour [désactiver l'usurpation d'identité](../api/rest/authentication.md#disable-impersonation).

### Identités de l'utilisateur {#user-identities}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate

{{< /details >}}

{{< history >}}

- Consultation de l'identité SCIM d'un utilisateur [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/294608) dans GitLab 15.3.

{{< /history >}}

Lors de l'utilisation de fournisseurs d'authentification, les administrateurs peuvent voir les identités d'un utilisateur. Cette page affiche les identités de l'utilisateur, y compris les identités SCIM. Utilisez ces informations pour résoudre les problèmes liés à SCIM et confirmer les identités utilisées pour un compte.

Pour ce faire :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Dans la liste des utilisateurs, sélectionnez un utilisateur.
1. Sélectionnez **Identités**.

### Export des permissions utilisateur {#user-permission-export}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous exportez les permissions des utilisateurs, les informations exportées indiquent les adhésions directes que les utilisateurs ont dans les groupes et les projets. Il comprend ces données, et est limité aux 100 000 premiers utilisateurs :

- Nom d'utilisateur
- Courriel
- Type
- Chemin
- Niveau d'accès ([Projet](../user/permissions.md#project-permissions) et [Groupe](../user/permissions.md#group-permissions))
- Date de dernière activité. Pour obtenir la liste des activités qui alimentent cette colonne, consultez la [documentation de l'API Utilisateurs](../api/users.md#list-a-users-activity).

Pour exporter les permissions des utilisateurs pour tous les utilisateurs actifs de votre instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. En haut à droite, sélectionnez **Exporter les autorisations au format CSV** ({{< icon name="export" >}}).

### Statistiques sur les utilisateurs {#users-statistics}

La page **Statistiques sur les utilisateurs** fournit une vue d'ensemble des comptes utilisateurs par rôle. Ces statistiques sont calculées quotidiennement. Les modifications d'utilisateurs effectuées après la dernière mise à jour ne sont pas reflétées. Ces totaux sont également inclus :

- Utilisateurs facturables
- Utilisateurs bloqués
- Total des utilisateurs

La facturation GitLab est basée sur le nombre d'[utilisateurs facturables](../subscriptions/manage_seats.md#billable-users).

### Ajouter un e-mail à un utilisateur {#add-email-to-user}

Pour ajouter manuellement des adresses e-mail aux comptes utilisateurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Localisez l'utilisateur et sélectionnez-le.
1. Sélectionnez **Éditer**.
1. Dans **Courriel**, saisissez la nouvelle adresse e-mail. Cela ajoute la nouvelle adresse e-mail à l'utilisateur et définit l'adresse e-mail précédente comme adresse secondaire.
1. Sélectionnez **Sauvegarder les modifications**.

## Cohortes d'utilisateurs {#user-cohorts}

L'onglet [Cohortes](user_cohorts.md) affiche les cohortes mensuelles de nouveaux utilisateurs et leurs activités au fil du temps.

## Empêcher un utilisateur de créer des groupes principaux {#prevent-a-user-from-creating-top-level-groups}

Les administrateurs peuvent empêcher des utilisateurs spécifiques de créer des groupes principaux. Ces utilisateurs peuvent toujours créer des sous-groupes et collaborer dans des structures organisationnelles existantes.

Pour empêcher un utilisateur de créer des groupes principaux :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Localisez l'utilisateur et sélectionnez-le.
1. Sélectionnez **Éditer**.
1. Décochez la case **Possibilité de créer un groupe de niveau supérieur**.
1. Sélectionnez **Sauvegarder les modifications**.

Après avoir désactivé ce paramètre :

- L'utilisateur ne peut pas créer de groupes principaux.
- L'utilisateur peut créer des sous-groupes dans les groupes où il a le rôle Maintainer ou Propriétaire, en fonction des [permissions de création de sous-groupes](../user/group/subgroups/_index.md#change-who-can-create-subgroups) pour le groupe.

## Administration des groupes {#administering-groups}

{{< history >}}

- Nouvelle apparence [introduite](https://gitlab.com/groups/gitlab-org/-/epics/17783) dans GitLab 18.2 [avec un flag](feature_flags/_index.md) nommé `admin_groups_vue`. Désactivé par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/553229) dans GitLab 18.5.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/574017) dans GitLab 18.6. Indicateur de feature flag `admin_groups_vue` supprimé.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Pour administrer tous les groupes dans l'instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Groupes**. La page affiche pour chaque groupe :

   - Nom
   - Description
   - Niveau de visibilité
   - Rôle
   - Statut
   - Taille de stockage
   - Nombre de sous-groupes
   - Nombre de projets
   - Nombre de membres

1. Facultatif. Sélectionnez un onglet :

   - **Actif** affiche tous les groupes actifs.
   - **Inactif** affiche les groupes en attente de suppression.

1. Facultatif. Pour modifier l'ordre de tri, sélectionnez la liste déroulante de tri et choisissez l'ordre souhaité. Les options de tri disponibles sont :

   - Nom
   - Date de création
   - Date de mise à jour
   - [Taille de stockage](../user/storage_usage_quotas.md)

1. Facultatif. Pour filtrer les groupes par nom, saisissez au moins trois caractères dans la barre de recherche.
1. Facultatif. Pour [créer un nouveau groupe](../user/group/_index.md#create-a-group), sélectionnez **Nouveau groupe**.

### Modifier un groupe {#edit-a-group}

Pour modifier le nom ou la description d'un groupe depuis la page Groupes de la zone **Admin** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Groupes**.
1. Trouvez le groupe que vous souhaitez modifier et sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Éditer**.
1. Modifiez le **Nom du groupe** ou la **Description du groupe**.
1. Sélectionnez **Enregistrer les modifications**.

### Supprimer un groupe {#delete-a-group}

Pour supprimer un groupe :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Groupes**.
1. Trouvez le groupe que vous souhaitez modifier et sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Supprimer**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Confirmer**.

## Administration des sujets {#administering-topics}

{{< details >}}

- Statut : Bêta

{{< /details >}}

Catégorisez et trouvez des projets similaires grâce aux [sujets](../user/project/project_topics.md).

### Voir tous les sujets {#view-all-topics}

Pour voir tous les sujets dans l'instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Sujets**.

Pour chaque sujet, la page affiche son nom et le nombre de projets étiquetés avec ce sujet.

### Rechercher des sujets {#search-for-topics}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Sujets**.
1. Dans la zone de recherche, saisissez vos critères de recherche. La recherche de sujets est non sensible à la casse et applique une correspondance partielle.

### Créer un sujet {#create-a-topic}

Pour créer un sujet :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Sujets**.
1. Sélectionnez **Nouveau sujet**.
1. Saisissez l'**Identifiant « slug » du sujet (nom)** et le **Titre du sujet**.
1. Facultatif. Saisissez une **Description** et ajoutez un **Avatar du sujet**.
1. Sélectionnez **Sauvegarder les modifications**.

Les sujets créés sont affichés sur la page **Explorer les sujets**.

Les sujets assignés sont visibles uniquement par toutes les personnes ayant accès au projet, mais tout le monde peut voir quels sujets existent dans l'instance GitLab. N'incluez pas d'informations sensibles dans le nom d'un sujet.

### Modifier un sujet {#edit-a-topic}

Vous pouvez modifier le nom, le titre, la description et l'avatar d'un sujet à tout moment. Pour modifier un sujet :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Sujets**.
1. Sélectionnez **Éditer** dans la ligne de ce sujet.
1. Modifiez le slug (nom), le titre, la description ou l'avatar du sujet.
1. Sélectionnez **Sauvegarder les modifications**.

### Supprimer un sujet {#remove-a-topic}

Si vous n'avez plus besoin d'un sujet, vous pouvez le supprimer définitivement. Pour supprimer un sujet :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Sujets**.
1. Pour supprimer un sujet, sélectionnez **Supprimer** dans la ligne de ce sujet.

### Fusionner les sujets {#merge-topics}

Vous pouvez déplacer tous les projets assignés à un sujet vers un autre sujet. Le sujet source est ensuite supprimé définitivement. Une fois qu'un sujet fusionné est supprimé, vous ne pouvez pas le restaurer.

Pour fusionner des sujets :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Sujets**.
1. Sélectionnez **Fusionner les sujets**.
1. Dans la liste déroulante **Sujet source**, sélectionnez le sujet que vous souhaitez fusionner et supprimer.
1. Dans la liste déroulante **Sujet cible**, sélectionnez le sujet dans lequel vous souhaitez fusionner le sujet source.
1. Sélectionnez **Fusionner**.

## Administration des serveurs Gitaly {#administering-gitaly-servers}

Vous pouvez lister tous les serveurs Gitaly dans l'instance GitLab depuis la page **Serveurs Gitaly** de la zone **Admin**. Pour plus de détails, consultez [Gitaly](gitaly/_index.md).

Pour accéder à la page **Serveurs Gitaly** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Serveurs Gitaly**.

La page comprend ces informations pour chaque serveur Gitaly :

| Champ          | Description |
|----------------|-------------|
| Stockage        | Stockage du dépôt |
| Adresse        | Adresse réseau sur laquelle le serveur Gitaly est à l'écoute |
| Version du serveur | Version de Gitaly |
| Version de Git    | Version de Git installée sur le serveur Gitaly |
| À jour     | Indique si la version du serveur Gitaly est la dernière version disponible. Un point vert indique que le serveur est à jour. |

## Administration des organisations {#administering-organizations}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/419540) dans GitLab 16.10 [avec un flag](feature_flags/_index.md) nommé `ui_for_organizations`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> Sur GitLab Self-Managed, cette fonctionnalité n'est pas disponible par défaut. Pour la rendre disponible, un administrateur peut [activer le feature flag](feature_flags/_index.md) nommé `ui_for_organizations`. Sur GitLab.com et GitLab Dedicated, cette fonctionnalité n'est pas disponible. Cette fonctionnalité n'est pas prête pour une utilisation en production.

La page Organisations dans la zone **Admin** liste tous les projets par défaut, dans l'ordre inverse de leur dernière mise à jour. Chaque projet affiche :

- Nom
- Espace de nommage
- Description
- Taille, mise à jour toutes les 15 minutes au maximum

Pour administrer toutes les organisations dans l'instance GitLab depuis cette page :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Organisations**.

## Section CI/CD {#cicd-section}

### Administration des runners {#administering-runners}

{{< history >}}

- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/340859) de **Vue d'ensemble** > **Runners** vers **CI/CD** > **Runners** dans GitLab 15.8.

{{< /history >}}

Pour administrer tous les runners dans l'instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.

Ces informations sont affichées pour chaque runner :

| Attribut    | Description |
|--------------|-------------|
| Statut       | Le statut du runner. Dans [GitLab 15.1 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/22224), pour le niveau Ultimate, le statut de mise à niveau est disponible. |
| Détails du runner | Informations sur le runner, y compris le jeton partiel et les détails sur l'ordinateur depuis lequel le runner a été enregistré. |
| Version      | Version de GitLab Runner. |
| Jobs         | Nombre total de jobs exécutés par le runner. |
| Tags         | Étiquettes associées au runner. |
| Dernier contact | Horodatage indiquant quand le runner a contacté pour la dernière fois l'instance GitLab. |

Vous pouvez également modifier, mettre en pause ou supprimer chaque runner.

Pour plus d'informations, consultez [GitLab Runner](https://docs.gitlab.com/runner/).

#### Rechercher et filtrer les runners {#search-and-filter-runners}

Pour rechercher dans les descriptions des runners :

1. Dans la zone de texte **Rechercher ou filtrer les résultats**, saisissez la description du runner que vous souhaitez trouver.
1. Appuyez sur <kbd>Entrée</kbd>.

Pour filtrer les runners par statut, type et étiquette :

1. Sélectionnez un onglet ou la zone de texte **Rechercher ou filtrer les résultats**.
1. Sélectionnez un **Type**, ou filtrez par **Statut** ou **Étiquettes**.
1. Sélectionnez ou saisissez vos critères de recherche.

![Attributs d'un runner filtré par statut.](img/index_runners_search_or_filter_v14_5.png)

#### Suppression en masse des runners {#bulk-delete-runners}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/370241) dans GitLab 15.4.
- [Feature flag supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/353981) dans GitLab 15.5.

{{< /history >}}

Pour supprimer plusieurs runners simultanément :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. À gauche du runner que vous souhaitez supprimer, cochez la case. Pour sélectionner tous les runners de la page, cochez la case au-dessus de la liste.
1. Sélectionnez **Supprimer la sélection**.

### Administration des jobs {#administering-jobs}

{{< history >}}

- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/386311) de **Vue d'ensemble** > **Jobs** vers **CI/CD** > **Jobs** dans GitLab 15.8.

{{< /history >}}

Pour administrer tous les jobs dans l'instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Jobs**. Tous les jobs sont listés, dans l'ordre décroissant des ID de job.
1. Sélectionnez l'onglet **Tous** pour lister tous les jobs. Sélectionnez l'onglet **En attente**, **En cours** ou **Terminé** pour lister uniquement les jobs ayant ce statut.

Pour chaque job, les détails suivants sont listés :

| Champ    | Description |
|----------|-------------|
| Statut   | Statut du job. L'un des états suivants : **réussi**, **ignoré** ou **en échec**.              |
| Job      | Comprend des liens vers le job, la branche et le commit qui a démarré le job. |
| Pipeline | Comprend un lien vers le pipeline spécifique.                               |
| Projet  | Nom du projet et de l'organisation auxquels appartient le job.        |
| Runner   | Nom du runner CI assigné pour exécuter le job.                      |
| Étape    | L'étape dans laquelle le job est déclaré dans un fichier `.gitlab-ci.yml`.              |
| Nom     | Nom du job spécifié dans un fichier `.gitlab-ci.yml`.                   |
| Durée   | Durée du job et temps écoulé depuis la fin du job.                |
| Couverture | Pourcentage de couverture des tests.                                           |

## Section Surveillance {#monitoring-section}

Les rubriques suivantes documentent la section **Surveillance** de la zone **Admin**.

### Informations système {#system-information}

{{< history >}}

- Prise en charge du temps relatif [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/341248) dans GitLab 15.2. La statistique « Uptime » a été renommée en « Démarrage du système ».

{{< /history >}}

La page **Informations système** fournit les statistiques suivantes :

| Champ          | Description                                       |
|:---------------|:--------------------------------------------------|
| CPU            | Nombre de cœurs CPU disponibles                     |
| Utilisation de la mémoire   | Mémoire utilisée et mémoire totale disponible         |
| Utilisation du disque     | Espace disque utilisé et espace disque total disponible |
| Démarrage du système | Quand le système hébergeant GitLab a démarré. Dans GitLab 15.1 et versions antérieures, il s'agissait d'une statistique de disponibilité. |

Ces statistiques sont mises à jour uniquement lorsque vous accédez à la page **Informations système** ou que vous actualisez la page dans votre navigateur.

### Jobs en arrière-plan {#background-jobs}

La page **Jobs en arrière-plan** affiche le tableau de bord Sidekiq. Sidekiq est utilisé par GitLab pour effectuer des processus en arrière-plan.

Le tableau de bord Sidekiq contient :

- Un onglet pour chaque [statut du cycle de vie du job](https://github.com/sidekiq/sidekiq/wiki/Job-Lifecycle).
- Un récapitulatif des statistiques des jobs en arrière-plan.
- Un graphique en temps réel des jobs au statut **Traité** et **Échec**, avec un intervalle d'interrogation sélectionnable.
- Un graphique historique des jobs au statut **Traité** et **Échec**, avec une plage de temps sélectionnable.
- Statistiques Redis, notamment :
  - Numéro de version
  - Disponibilité, mesurée en jours
  - Nombre de connexions
  - Utilisation actuelle de la mémoire, mesurée en Mo
  - Utilisation maximale de la mémoire, mesurée en Mo

### Gestion des données {#data-management}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/550952) dans GitLab 18.8.

{{< /history >}}

La page **Gestion des données** fournit une interface complète pour visualiser et gérer le statut de vérification de tous les composants sur un site Geo principal. Les composants incluent [tous les types de données](geo/replication/datatypes.md) pris en charge par Geo.

Utilisez cette page pour :

- Identifier les fichiers orphelins ou les enregistrements de base de données qui entraînent des échecs de vérification sans nécessiter d'accès à la console Rails.
- Afficher des informations d'erreur détaillées et prendre des mesures correctives directement depuis l'interface utilisateur.
- Suivre le statut de vérification de tous les composants et identifier les schémas d'échecs.
- Déclencher le calcul de la somme de contrôle pour tous les objets à la fois.

La vue liste affiche le statut de vérification pour un composant sélectionné.

1. Choisissez un composant dans la liste déroulante pour basculer entre différents modèles de vérification (Projets, Téléversements, etc.). Depuis la vue liste, vous pouvez :

   - Filtrer les objets par statut de somme de contrôle (Échec, En attente, Réussi).
   - Naviguer dans les grands ensembles de résultats.
   - Afficher la dernière heure de somme de contrôle, la dernière heure d'échec et les raisons d'échec pour chaque objet.
   - Déclencher le calcul de la somme de contrôle pour des objets individuels.

1. Sélectionnez un modèle individuel dans la vue liste pour consulter des informations complètes sur le statut de vérification d'un objet spécifique, telles que :

   - Détails sur l'objet vérifié.
   - Statut actuel de la somme de contrôle et historique.
   - Raisons d'échec détaillées si la vérification a échoué.
   - Options pour recalculer la somme de contrôle de l'objet.

### Diagnostics de base de données {#database-diagnostics}

{{< history >}}

- Vérification de l'état de la collation [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/555916) dans GitLab 18.3.
- Vérification de l'état du schéma [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199796) dans GitLab 18.3 avec les vérifications des index manquants, des tables, des clés étrangères et des séquences.
- Vérification des propriétaires de séquences incorrects [ajoutée à la vérification de l'état du schéma](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197521) dans GitLab 18.4.

{{< /history >}}

La page de diagnostics de base de données comprend un ensemble de vérifications qui tentent de signaler les problèmes courants liés à la base de données :

- Corruption d'index causée par un [changement dans les collations PostgreSQL](https://gitlab.com/groups/gitlab-org/-/epics/8573)
- [Incohérences de schéma](https://gitlab.com/groups/gitlab-org/-/epics/3928)

Pour exécuter chaque vérification, sélectionnez le bouton d'exécution correspondant. La sélection du bouton d'exécution planifie un job en arrière-plan qui rapportera les informations de la vérification à la page.

#### Vérification de l'état de la collation {#collation-health-check}

La vérification de l'état de la collation tente de détecter les problèmes PostgreSQL qui entraînent des index corrompus. Cela se produit généralement si le système d'exploitation précédent exécutant PostgreSQL utilisait une version de `glibc` antérieure à la version 2.28. Pour plus d'informations, consultez la documentation sur la [mise à niveau des systèmes d'exploitation pour PostgreSQL](postgresql/upgrading_os.md).

Tous les problèmes sont listés dans une section **Corrupted Indexes**. Si vous rencontrez des problèmes, vous pouvez [réparer les index corrompus](raketasks/maintenance.md#repair-corrupted-database-indexes).

La vérification de l'état de la collation tente également de signaler les doublons dans les tables fréquemment affectées :

- `ci_refs`
- `ci_resource_groups`
- `environments`
- `merge_request_diff_commit_users`
- `sbom_components`
- `tags`
- `topics`

Pour plus d'informations, consultez [l'issue 505982](https://gitlab.com/gitlab-org/gitlab/-/issues/505982).

Le tableau de bord liste les informations identiques à celles affichées dans la [tâche Rake `gitlab:db:collation_checker`](raketasks/maintenance.md#detect-postgresql-collation-version-mismatches).

#### Vérification de l'état du schéma {#schema-health-check}

La vérification de l'état du schéma compare l'état de la base de données avec le schéma cible et liste les incohérences détectées. Aucun outil automatisé de réparation du schéma n'est disponible.

Si vous constatez des faux positifs ou si vous avez des questions sur les résultats de la vérification, consultez l'[issue de retour d'information](https://gitlab.com/gitlab-org/gitlab/-/issues/567561).

### Journaux {#logs}

Le contenu de ces fichiers journaux peut aider à résoudre un problème. Le contenu de chaque fichier journal est listé dans l'ordre chronologique. Pour minimiser les problèmes de performance, un maximum de 2000 lignes de chaque fichier journal est affiché.

| Fichier journal                | Contenu |
|:------------------------|:---------|
| `application_json.log`  | Activité des utilisateurs GitLab |
| `git_json.log`          | Interaction GitLab échouée avec les dépôts Git |
| `production.log`        | Requêtes reçues par Puma et actions effectuées pour y répondre |
| `sidekiq.log`           | Jobs en arrière-plan |
| `repocheck.log`         | Activité du dépôt |
| `integrations_json.log` | Activité entre GitLab et les systèmes intégrés |
| `kubernetes.log`        | Activité Kubernetes |

Pour plus de détails sur ces fichiers journaux et leur contenu, consultez [Système de journalisation](logs/_index.md).

La vue **Journal** a été supprimée du tableau de bord de la zone **Admin** pour éviter toute confusion pour les administrateurs des systèmes multi-nœuds. Cette vue présente des informations partielles pour les configurations multi-nœuds. Pour les systèmes multi-nœuds, intégrez les journaux dans des services tels qu'Elasticsearch et Splunk.

### Événements d'audit {#audit-events}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

La page **Événements d'audit** liste les modifications apportées au serveur GitLab. Utilisez ces informations pour contrôler, analyser et suivre chaque modification.

### Statistiques {#statistics}

La section **Vue d'ensemble de l'instance** du tableau de bord liste les statistiques actuelles de l'instance GitLab. Récupérez ces informations avec l'[API de statistiques d'application](../api/statistics.md#retrieve-application-statistics).

Ces statistiques affichent des comptages exacts pour les valeurs inférieures à 10 000. Pour les valeurs supérieures ou égales à 10 000, ces statistiques affichent des données approximatives lorsque les stratégies [`TablesampleCountStrategy`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/count/tablesample_count_strategy.rb?ref_type=heads#L16) et [`ReltuplesCountStrategy`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/count/reltuples_count_strategy.rb?ref_type=heads) sont utilisées pour les calculs.

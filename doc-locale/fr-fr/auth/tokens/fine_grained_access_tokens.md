---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Jetons d'accès personnel affinés"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/18555) en tant que [version bêta](../../policy/development_stages_support.md#beta) dans GitLab 18.10.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/596613) dans GitLab 19.2.

{{< /history >}}

Les jetons d'accès personnel affinés ont une portée limitée à l'accès aux ressources et aux permissions spécifiques que vous définissez. Lors de la création du jeton, vous définissez les attributs suivants :

- Ressources : Un ensemble d'opérations d'API REST. Les ressources sont regroupées en périmètres plus larges (`Group and project`, `User` et `Global`).
- Permissions : Les actions spécifiques que le jeton peut effectuer sur une ressource. En général, cela correspond aux actions Créer, Lire, Mettre à jour et Supprimer.

## Créer un jeton d'accès personnel affiné {#create-a-fine-grained-personal-access-token}

Pour créer un jeton d'accès personnel affiné :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Jetons d'accès personnel**.
1. Dans la liste déroulante **Générer un jeton**, sélectionnez **Jeton affiné**.
1. Renseignez les champs **Nom** et **Description**.
1. Dans la zone de texte **Date d'expiration**, saisissez une date d'expiration pour le jeton.
   - Le jeton expire à minuit UTC à cette date.
   - Si vous ne saisissez pas de date, la date d'expiration est fixée à 365 jours à compter d'aujourd'hui.
   - Par défaut, la date d'expiration ne peut pas dépasser 365 jours à compter d'aujourd'hui. Dans GitLab 17.6 et versions ultérieures, les administrateurs peuvent [modifier la durée de vie maximale des jetons d'accès](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens).
1. Si vous ajoutez des ressources de groupe ou de projet, sous **Accès aux groupes et projets**, sélectionnez une option.
1. Sous **Ajouter des autorisations d'accès aux ressources** :
   1. Utilisez les onglets **Groupe et projet**, **Utilisateur ou utilisatrice** ou **Globales** pour filtrer les ressources par périmètre.
   1. Dans le panneau gauche, sélectionnez une ou plusieurs ressources.
   1. Dans le panneau de droite, sélectionnez une [autorisation disponible](#available-fine-grained-permissions) pour chaque ressource.
1. Sélectionnez **Générer un jeton**.

Un jeton d'accès personnel s'affiche. Enregistrez le jeton d'accès personnel dans un endroit sûr. Après avoir quitté ou actualisé la page, vous ne pourrez plus le consulter.

## Emprunter l'identité d'utilisateurs avec sudo {#impersonate-users-with-sudo}

Les administrateurs peuvent créer un jeton d'accès personnel affiné pouvant emprunter l'identité d'autres utilisateurs via le paramètre [`sudo`](../../api/rest/authentication.md#sudo) de l'API REST.

Seul un administrateur peut créer un jeton avec la fonctionnalité sudo. Un utilisateur non-administrateur qui tente d'en créer un reçoit une erreur.

Un jeton affiné continue d'appliquer ses propres autorisations lors de l'emprunt d'identité. Le jeton ne peut effectuer une action que lorsque les deux conditions suivantes sont remplies :

- L'utilisateur dont l'identité est empruntée est autorisé à effectuer l'action.
- Le jeton dispose d'une autorisation permettant l'action.

Ce comportement diffère d'un jeton d'accès personnel hérité avec la portée `sudo`, qui peut effectuer n'importe quelle action en tant qu'utilisateur dont l'identité est empruntée.

> [!warning]
> Un jeton avec la fonctionnalité sudo peut agir en tant que n'importe quel utilisateur. Limitez ses autorisations et périmètres au strict minimum requis, et stockez-le de manière sécurisée.

## Permissions à granularité fine disponibles {#available-fine-grained-permissions}

Les autorisations qu'un jeton d'accès personnel affiné peut utiliser dépendent du point de terminaison que le jeton appelle :

- [Autorisations affinées pour l'API REST](fine_grained_access_tokens_rest.md)
- [Autorisations affinées pour l'API GraphQL](fine_grained_access_tokens_graphql.md)
- [Autorisations affinées pour Git et autres opérations](fine_grained_access_tokens_other.md)

## Appliquer les jetons d'accès personnel affinés {#enforce-fine-grained-personal-access-tokens}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/20180) dans GitLab 18.11 [avec des flags](../../administration/feature_flags/_index.md) nommés `granular_personal_access_tokens_enforcement` et `granular_personal_access_tokens_enforcement_saas`. Désactivés par défaut.
- [Disponible en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/596613) sur GitLab Self-Managed dans GitLab 19.2.

{{< /history >}}

Vous pouvez exiger de vos utilisateurs qu'ils adoptent des jetons d'accès personnel affinés après une date d'application spécifiée. Après cette date, les jetons d'accès personnel hérités existants restent listés dans les profils utilisateurs, mais ne peuvent plus être utilisés pour accéder aux ressources.

L'application fonctionne différemment sur GitLab.com et GitLab Self-Managed :

- Sur GitLab.com, l'application est appliquée à un groupe principal et héritée par tous les sous-groupes et projets.
- Sur GitLab Self-Managed, l'application s'étend à l'ensemble de l'instance.

### Appliquer les jetons affinés pour un groupe principal {#enforce-fine-grained-tokens-for-a-top-level-group}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe principal.

Sur GitLab.com, l'application s'étend au groupe, à ses sous-groupes et à ses projets, et bloque les jetons d'accès personnel hérités pour l'accès à ces ressources après la date d'application. Les utilisateurs peuvent toujours créer des jetons hérités, mais ces jetons ne peuvent pas accéder aux ressources soumises à l'application pour le groupe.

Ce paramètre n'est pas disponible sur GitLab Self-Managed.

Vous pouvez appliquer les jetons affinés uniquement sur un groupe principal.

Pour appliquer les jetons d'accès personnel affinés pour un groupe principal :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez **Permissions et fonctionnalités du groupe**.
1. Sélectionnez **Exiger des jetons d'accès personnel affinés après une date spécifique**.
1. Saisissez une date d'application future. La date d'application est en temps universel coordonné (UTC).
1. Sélectionnez **Enregistrer les modifications**.

Après la date d'application, les utilisateurs reçoivent une erreur lorsqu'ils tentent d'utiliser un jeton hérité pour accéder aux ressources du groupe principal, de ses sous-groupes ou de ses projets. L'erreur liste le périmètre de ressource et les autorisations dont un jeton affiné a besoin. Par exemple :

```plaintext
Access denied: This operation requires a fine-grained personal access token with the following project permissions: [Project: Read].
```

### Appliquer les jetons affinés sur GitLab Self-Managed {#enforce-fine-grained-tokens-on-gitlab-self-managed}

Prérequis :

- Être administrateur.

Sur GitLab Self-Managed, l'application s'étend à l'ensemble de l'instance et bloque les utilisateurs dans la création ou la rotation des jetons d'accès personnel hérités après la date d'application. Les utilisateurs ne peuvent créer que des jetons affinés. Les jetons hérités existants continuent de fonctionner jusqu'à leur expiration.

Pour appliquer les jetons d'accès personnel affinés pour l'instance :

1. Dans la barre latérale gauche, en bas, sélectionnez **Admin**.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Sélectionnez **Exiger des jetons d'accès personnel affinés après une date spécifique**.
1. Dans **Date d'application des jetons d'accès personnel affinés**, saisissez une date future.
1. Sélectionnez **Enregistrer les modifications**.

Après la date d'application, les utilisateurs reçoivent une erreur lorsqu'ils tentent de créer ou de renouveler un jeton hérité.

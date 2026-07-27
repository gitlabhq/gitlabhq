---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Permissions affinées pour les jetons d'accès personnel"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : Version bêta

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/groups/gitlab-org/-/work_items/18555) en tant que [version bêta](../../policy/development_stages_support.md#beta) dans GitLab 18.10.

{{< /history >}}

Les jetons d'accès personnel affinés ont une portée limitée à l'accès aux ressources et aux permissions spécifiques que vous définissez. Lors de la création du jeton, vous définissez les attributs suivants :

- Ressources : Un ensemble d'opérations d'API REST. Les ressources sont regroupées en catégories plus larges ( `Group and project` et `User`).
- Permissions : Les actions spécifiques que le jeton peut effectuer sur une ressource. En général, cela correspond aux actions Créer, Lire, Mettre à jour et Supprimer.

## Créer un jeton d'accès personnel affiné {#create-a-fine-grained-personal-access-token}

Pour créer un jeton d'accès personnel affiné :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Jetons d'accès personnel**.
1. Dans la liste déroulante **Générer un jeton**, sélectionnez **Jeton affiné**.
1. Dans **Nom du jeton**, saisissez un nom pour le jeton.
1. Dans **Description du jeton**, saisissez une description pour le jeton.
1. Dans **Date d'expiration**, saisissez une date d'expiration pour le jeton.
   - Le jeton expire à minuit UTC à cette date.
   - Si vous ne saisissez pas de date, la date d'expiration est fixée à 365 jours à compter d'aujourd'hui.
   - Par défaut, la date d'expiration ne peut pas dépasser 365 jours à compter d'aujourd'hui. Dans GitLab 17.6 et versions ultérieures, les administrateurs peuvent [modifier la durée de vie maximale des jetons d'accès](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens).
1. Définissez la portée du jeton d'accès personnel.
   1. Dans le panneau gauche, sélectionnez une ou plusieurs ressources.
   1. Si vous incluez des ressources de groupe ou de projet, sélectionnez une option dans la section `Group and project access`.
   1. Dans le panneau droit, sélectionnez une permission disponible pour chaque ressource.
1. Sélectionnez **Générer un jeton**.

Un jeton d'accès personnel s'affiche. Enregistrez le jeton d'accès personnel dans un endroit sûr. Après avoir quitté ou actualisé la page, vous ne pourrez plus le consulter.

## Permissions à granularité fine disponibles {#available-fine-grained-permissions}

Les permissions qu'un jeton d'accès personnel affiné peut utiliser dépendent de l'API REST que le jeton appelle :

- [Points de terminaison de l'API REST prenant en charge les jetons d'accès personnel affinés](fine_grained_access_tokens_rest.md)
- [Champs GraphQL prenant en charge les jetons d'accès personnel affinés](fine_grained_access_tokens_graphql.md)

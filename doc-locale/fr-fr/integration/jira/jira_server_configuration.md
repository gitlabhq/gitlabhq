---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Créez un utilisateur, un groupe et un schéma d'autorisations Jira pour authentifier l'intégration des tickets Jira dans GitLab."
title: 'Tutoriel : créer des identifiants Jira'
---

Dans ce tutoriel, vous allez configurer un utilisateur Jira dédié et lui accorder les autorisations dont l'intégration des tickets Jira a besoin. Toutes les étapes sont effectuées dans Jira, pas dans GitLab.

Une fois ce tutoriel terminé, utilisez le nom d'utilisateur et le mot de passe Jira que vous avez créés ici pour configurer l'intégration des tickets Jira dans GitLab.

Pour créer des identifiants Jira :

1. [Créer un utilisateur Jira](#create-a-jira-user).
1. [Créer un groupe Jira pour l'utilisateur](#create-a-jira-group-for-the-user).
1. [Créer un schéma d'autorisations pour le groupe](#create-a-permission-scheme-for-the-group).
1. [Attribuer le schéma d'autorisations à vos projets](#assign-the-permission-scheme-to-your-projects).

## Avant de commencer {#before-you-begin}

- Vous devez disposer de la **Jira administrators** ou **Jira System administrators** [autorisation globale](https://confluence.atlassian.com/adminjiraserver/managing-global-permissions-938847142.html).

## Créer un utilisateur Jira {#create-a-jira-user}

Pour créer un utilisateur Jira :

1. Dans le coin supérieur droit, sélectionnez **Administration** > **User management**.
1. [Créez un nouveau compte utilisateur](https://confluence.atlassian.com/adminjiraserver/create-edit-or-remove-a-user-938847025.html#Create,edit,orremoveauser-CreateusersmanuallyinJira) avec un accès en écriture à vos projets Jira :

   - Dans **Adresse de courriel**, saisissez une adresse e-mail valide.
   - Dans **Nom d'utilisateur**, saisissez `gitlab`.
   - Dans **Mot de passe**, saisissez un mot de passe. L'intégration des tickets Jira ne prend pas en charge l'authentification unique (SSO) telle que SAML.

1. Sélectionnez **Créer un utilisateur**.

Vous pouvez également utiliser un compte utilisateur existant, à condition que l'utilisateur appartienne à un groupe disposant des autorisations requises.

Maintenant que vous avez créé un utilisateur nommé `gitlab`, il est temps de créer un groupe pour cet utilisateur.

## Créer un groupe Jira pour l'utilisateur {#create-a-jira-group-for-the-user}

Pour créer un groupe Jira pour l'utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Administration** > **User management**.
1. Dans la barre latérale gauche, sélectionnez **Groupes**.
1. Dans la section **Ajouter un groupe**, saisissez un nom pour le groupe (par exemple, `gitlab-developers`), puis sélectionnez **Ajouter un groupe**.
1. Pour ajouter l'utilisateur `gitlab` au groupe `gitlab-developers`, sélectionnez **Edit members**. Le groupe `gitlab-developers` apparaît en tant que groupe sélectionné.
   <!-- vale gitlab_base.BadPlurals = NO -->
1. Dans la section **Add members to selected group(s)**, saisissez `gitlab`.
   <!-- vale gitlab_base.BadPlurals = YES -->
1. Sélectionnez **Add selected users**. L'utilisateur `gitlab` apparaît en tant que membre du groupe.

Maintenant que vous avez ajouté l'utilisateur `gitlab` au groupe `gitlab-developers`, il est temps de créer un schéma d'autorisations pour le groupe.

## Créer un schéma d'autorisations pour le groupe {#create-a-permission-scheme-for-the-group}

L'intégration des tickets Jira a besoin d'autorisations pour parcourir les projets, créer et modifier des tickets, et ajouter des commentaires. N'accordez que les autorisations requises pour ces actions.

Pour créer un schéma d'autorisations :

1. Dans le coin supérieur droit, sélectionnez **Administration** > **Tickets**.
1. Dans la barre latérale gauche, sélectionnez **Permission schemes**.
1. Sélectionnez **Add permission scheme**.
1. Dans la boîte de dialogue **Add permission scheme**, remplissez les champs.
1. Sélectionnez **Ajouter**.
1. Sur la page **Permission schemes**, dans la colonne **Actions**, sélectionnez **Autorisations** pour le nouveau schéma.
1. Pour chacune des autorisations suivantes, sélectionnez **Éditer**, accordez l'autorisation au groupe `gitlab-developers`, puis sélectionnez **Grant** :

   - **Browse Projects**
   - **Create Issues**
   - **Edit Issues**
   - **Add Comments**

Maintenant que vous avez configuré le schéma d'autorisations, il est temps de l'assigner à vos projets Jira.

## Assigner le schéma d'autorisations à vos projets {#assign-the-permission-scheme-to-your-projects}

Un schéma d'autorisations n'a aucun effet tant qu'il n'est pas associé à au moins un projet. Répétez ces étapes pour chaque projet Jira auquel vous souhaitez que l'intégration des tickets Jira accède.

Pour assigner le schéma d'autorisations à un projet :

1. Dans le coin supérieur droit, sélectionnez **Administration** > **Projets**.
1. Sélectionnez le projet que vous souhaitez configurer.
1. Dans **Paramètres du projet**, sélectionnez **Autorisations**.
1. Sélectionnez **Actions** > **Use a different scheme**.
1. Sélectionnez le schéma que vous avez créé, puis sélectionnez **Associate**.

Vous avez réussi ! Rendez-vous maintenant dans GitLab et [configurez l'intégration des tickets Jira](configure.md) en utilisant le nom d'utilisateur et le mot de passe `gitlab` que vous avez créés ici.

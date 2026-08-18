---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez Sentry à GitLab pour le suivi des erreurs dans vos projets.
title: Suivi des erreurs Sentry
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Sentry](https://sentry.io/) est un système de suivi des erreurs open source. GitLab permet aux administrateurs de connecter Sentry à GitLab, afin que les utilisateurs puissent consulter une liste des erreurs Sentry dans GitLab.

GitLab s'intègre à la fois avec [Sentry](https://sentry.io) hébergé dans le cloud et avec Sentry déployé dans votre [instance on-premise](https://github.com/getsentry/self-hosted).

## Activer l'intégration Sentry pour un projet {#enable-sentry-integration-for-a-project}

GitLab fournit un moyen de connecter Sentry à votre projet.

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour activer l'intégration Sentry :

1. Inscrivez-vous sur Sentry.io ou déployez votre propre [instance Sentry on-premise](https://github.com/getsentry/self-hosted).
1. [Créez un nouveau projet Sentry](https://docs.sentry.io/product/sentry-basics/integrate-frontend/create-new-project/). Pour chaque projet GitLab que vous souhaitez intégrer, créez un nouveau projet Sentry.
1. Trouvez ou générez un [jeton d'authentification Sentry](https://docs.sentry.io/api/auth/#auth-tokens). Pour la version SaaS de Sentry, vous pouvez trouver ou générer le jeton d'authentification à l'adresse <https://sentry.io/api/>. Accordez au jeton au minimum les portées suivantes : `project:read`, `event:read` et `event:write` (pour la résolution des événements).
1. Dans GitLab, activez et configurez le suivi des erreurs :
   1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
   1. Sélectionnez **Paramètres** > **Supervision**, puis développez **Suivi des erreurs**.
   1. Pour **Activer le suivi d'erreur**, sélectionnez **Actif**.
   1. Pour **Backend du suivi des erreurs**, sélectionnez **Sentry**.
   1. Pour **URL de l'API Sentry**, saisissez le nom d'hôte de votre instance Sentry. Par exemple, saisissez `https://sentry.example.com`. Pour la version SaaS de Sentry, le nom d'hôte est `https://sentry.io`. Pour la version SaaS de Sentry hébergée dans l'UE, le nom d'hôte est `https://de.sentry.io`.
   1. Pour **Jeton d'authentification**, saisissez le jeton que vous avez généré précédemment.
   1. Pour tester la connexion à Sentry et remplir la liste déroulante **Projet**, sélectionnez **Connecter**.
   1. Dans la liste **Projet**, choisissez un projet Sentry à lier à votre projet GitLab.
   1. Sélectionnez **Enregistrer les modifications**.

Pour afficher la liste des erreurs Sentry, dans la barre latérale de votre projet, accédez à **Supervision** > **Suivi des erreurs**.

## Activer l'intégration GitLab de Sentry {#enable-sentrys-integration-with-gitlab}

Vous pouvez également activer l'intégration GitLab de Sentry en suivant les étapes décrites dans la [documentation Sentry](https://docs.sentry.io/organization/integrations/source-code-mgmt/gitlab/).

## Dépannage {#troubleshooting}

Lorsque vous utilisez le suivi des erreurs, vous pouvez rencontrer les problèmes suivants.

### Erreur `Connection failed. Check auth token and try again` {#error-connection-failed-check-auth-token-and-try-again}

Si la fonctionnalité **Supervision** est désactivée dans les [paramètres du projet](../user/project/settings/_index.md#configure-project-features-and-permissions), une erreur peut s'afficher lorsque vous tentez d'[activer l'intégration Sentry pour un projet](#enable-sentry-integration-for-a-project). La requête résultante vers `/project/path/-/error_tracking/projects.json?api_host=https:%2F%2Fsentry.example.com%2F&token=<token>` renvoie une erreur 404.

Pour résoudre ce problème, activez la fonctionnalité **Supervision** pour le projet.

### Erreur `Connection has failed. Re-check Auth Token and try again` {#error-connection-has-failed-re-check-auth-token-and-try-again}

Les intégrations Sentry on-premise peuvent rencontrer ce problème lors de la tentative de connexion.

Prérequis :

- Disposer d'un accès administrateur.

Pour résoudre ce problème :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Requêtes sortantes**.
1. Cochez les cases **Autoriser les requêtes vers le réseau local des crochets Web et des intégrations** et **Autoriser les requêtes vers le réseau local depuis les crochets système**.
1. Sélectionnez **Enregistrer les modifications**.

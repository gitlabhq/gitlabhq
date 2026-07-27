---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez votre dépôt GitHub à GitLab CI/CD.
title: Utilisation de GitLab CI/CD avec un dépôt GitHub
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD peut être utilisé avec **GitHub.com** et **GitHub Enterprise** en créant un [projet CI/CD](_index.md) pour connecter votre dépôt GitHub à GitLab.

<i class="fa-youtube-play" aria-hidden="true"></i> Regardez une vidéo sur [l'utilisation des pipelines GitLab CI/CD avec des dépôts GitHub](https://www.youtube.com/watch?v=qgl3F2j-1cI).

> [!note]
> En raison des [limitations de GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/9147), [GitHub OAuth](../../integration/github.md#enable-github-oauth-in-gitlab) ne peut pas être utilisé pour s'authentifier auprès de GitHub en tant que dépôt CI/CD externe.

## Connexion avec un jeton d'accès personnel {#connect-with-personal-access-token}

Les jetons d'accès personnels ne peuvent être utilisés que pour connecter des dépôts GitHub.com à GitLab, et l'utilisateur GitHub doit disposer du [rôle owner](https://docs.github.com/en/get-started/learning-about-github/access-permissions-on-github).

Pour effectuer une autorisation unique avec GitHub afin d'accorder à GitLab l'accès à vos dépôts :

1. Dans GitHub, créez un jeton :
   1. Ouvrez <https://github.com/settings/tokens/new>.
   1. Créez un jeton d'accès personnel.
   1. Saisissez une **Description du jeton** et mettez à jour la portée pour autoriser `repo` et `admin:repo_hook` afin que GitLab puisse accéder à votre projet, mettre à jour les statuts de commit et créer un webhook pour notifier GitLab des nouveaux commits.
1. Dans GitLab, créez un projet :
   1. Dans le coin supérieur droit, sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}) et **Nouveau projet/dépôt**.
   1. Sélectionnez **Exécuter CI/CD pour un dépôt externe**.
   1. Sélectionnez **GitHub**.
   1. Pour **Jeton d'accès personnel**, collez le jeton.
   1. Sélectionnez **List Repositories**.
   1. Sélectionnez **Connecter** pour sélectionner le dépôt.
1. Dans GitHub, ajoutez un `.gitlab-ci.yml` pour [configurer GitLab CI/CD](../quick_start/_index.md).

GitLab :

1. Importe le projet.
1. Active le [pull mirroring](../../user/project/repository/mirror/pull.md).
1. Active l'[intégration du projet GitHub](../../user/project/integrations/github.md).
1. Crée un webhook sur GitHub pour notifier GitLab des nouveaux commits.

## Connexion manuelle {#connect-manually}

Pour utiliser **GitHub Enterprise** avec **GitLab.com**, utilisez cette méthode.

Pour activer manuellement GitLab CI/CD pour votre dépôt :

1. Dans GitHub, créez un jeton :
   1. Ouvrez <https://github.com/settings/tokens/new>.
   1. Créez un jeton d'accès personnel.
   1. Saisissez une **Description du jeton** et mettez à jour la portée pour autoriser `repo` afin que GitLab puisse accéder à votre projet et mettre à jour les statuts de commit.
1. Dans GitLab, créez un projet :
   1. Dans le coin supérieur droit, sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}) et **Nouveau projet/dépôt**.
   1. Sélectionnez **Exécuter CI/CD pour un dépôt externe** et **Dépôt par URL**.
   1. Dans le champ **URL du dépôt Git**, saisissez l'URL HTTPS de votre dépôt GitHub. Si votre projet est privé, utilisez le jeton d'accès personnel que vous venez de créer pour l'authentification.
   1. Remplissez tous les autres champs et sélectionnez **Créer le projet**. GitLab configure automatiquement le pull mirroring basé sur l'interrogation.
1. Dans GitLab, activez l'[intégration du projet GitHub](../../user/project/integrations/github.md) :
   1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
   1. Cochez la case **Actif**.
   1. Collez votre jeton d'accès personnel et l'URL HTTPS du dépôt dans le formulaire et sélectionnez **Enregistrer**.
1. Dans GitLab, créez un jeton d'accès personnel avec la portée `API` pour authentifier le webhook GitHub notifiant GitLab des nouveaux commits.
1. Dans GitHub, depuis **Paramètres** > **Crochets web**, créez un webhook pour notifier GitLab des nouveaux commits.

   L'URL du webhook doit être définie sur l'API GitLab pour [déclencher le pull mirroring](../../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project), en utilisant le jeton d'accès personnel GitLab que vous venez de créer :

   ```plaintext
   https://gitlab.com/api/v4/projects/<NAMESPACE>%2F<PROJECT>/mirror/pull?private_token=<PERSONAL_ACCESS_TOKEN>
   ```

   Sélectionnez l'option **Let me select individual events**, puis cochez les cases **Requêtes pull** et **Poussées**. Ces paramètres sont nécessaires pour les [pipelines pour les requêtes pull externes](_index.md#pipelines-for-external-pull-requests).

1. Dans GitHub, ajoutez un `.gitlab-ci.yml` pour configurer GitLab CI/CD.

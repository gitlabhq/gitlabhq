---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Authentifiez les jobs CI/CD avec les fonctionnalités GitLab en utilisant un jeton de job à courte durée de vie.
title: Jeton de job CI/CD
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsqu'un job de pipeline CI/CD est sur le point de s'exécuter, GitLab génère un jeton unique et le met à disposition du job en tant que [`CI_JOB_TOKEN` variable prédéfinie](../variables/predefined_variables.md). Le jeton n'est valide que pendant l'exécution du job. Une fois le job terminé, l'accès au jeton est révoqué et vous ne pouvez plus utiliser le jeton.

Utilisez un jeton de job CI/CD pour vous authentifier auprès de certaines fonctionnalités GitLab à partir des jobs en cours d'exécution. Le jeton reçoit le même niveau d'accès que l'utilisateur qui a déclenché le pipeline, mais dispose d'un [accès à moins de ressources](#job-token-access) qu'un jeton d'accès personnel. Un utilisateur peut déclencher un job en poussant un commit, en exécutant un job manuel ou en étant propriétaire d'un pipeline planifié. Cet utilisateur doit avoir un [rôle disposant des privilèges requis](../../user/permissions.md#project-cicd) pour accéder aux ressources.

Vous pouvez utiliser un jeton de job pour vous authentifier auprès de GitLab afin d'accéder aux ressources d'un autre groupe ou projet (le projet cible). Par défaut, le groupe ou le projet du jeton de job doit être [ajouté à la liste des jetons de job autorisés du projet cible](#add-a-group-or-project-to-the-job-token-allowlist).

Si un projet est public ou interne, vous pouvez accéder à certaines fonctionnalités sans figurer sur la liste des autorisations. Par exemple, vous pouvez récupérer des artefacts de job à partir des pipelines publics du projet. Cet accès peut également [être restreint](#limit-job-token-scope-for-public-or-internal-projects).

## Accès au jeton de job {#job-token-access}

{{< history >}}

- La permission d'obtenir un tag unique [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216463) dans GitLab 18.8.

{{< /history >}}

Les jetons de job CI/CD peuvent accéder aux ressources suivantes :

| Ressource                                                                                              | Notes |
| ----------------------------------------------------------------------------------------------------- | ----- |
| [API Branches](../../api/branches.md)                                                                 | Peut accéder au point de terminaison `GET /projects/:id/repository/branches`. |
| [API Commits](../../api/commits.md)                                                                   | Peut accéder aux points de terminaison `GET /projects/:id/repository/commits/:sha` et `GET /projects/:id/repository/commits/:sha/merge_requests`. |
| [Registre de conteneurs](../../user/packages/container_registry/build_and_push_images.md#use-gitlab-cicd) | Utilisé comme [variable prédéfinie](../variables/predefined_variables.md) `$CI_REGISTRY_PASSWORD` pour s'authentifier auprès du registre de conteneurs associé au projet du job. |
| [Registre de paquets](../../user/packages/package_registry/_index.md#to-build-packages)                  | Utilisé pour s'authentifier auprès du registre. |
| [Registre de modules Terraform](../../user/packages/terraform_module_registry/_index.md)                  | Utilisé pour s'authentifier auprès du registre. |
| [Fichiers sécurisés](../secure_files/_index.md#use-secure-files-in-cicd-jobs)                               | Utilisé par la commande [`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile) pour utiliser des fichiers sécurisés dans les jobs. |
| [API du registre de conteneurs](../../api/container_registry.md)                                             | Peut s'authentifier uniquement auprès du registre de conteneurs associé au projet du job. |
| [API Déploiements](../../api/deployments.md)                                                           | Peut accéder à tous les points de terminaison de cette API. |
| [API Environnements](../../api/environments.md)                                                         | Peut accéder à tous les points de terminaison de cette API. |
| [API Fichiers](../../api/repository_files.md)                                                            | Peut accéder au point de terminaison `GET /projects/:id/repository/files/:file_path/raw`. |
| [API Jobs](../../api/jobs.md#retrieve-a-job-by-job-token)                                             | Peut accéder uniquement au point de terminaison `GET /job`. |
| [API Artefacts de job](../../api/job_artifacts.md)                                                       | Peut accéder uniquement aux points de terminaison de téléchargement. |
| [API Merge requests](../../api/merge_requests.md)                                                     | Peut accéder aux points de terminaison `GET /projects/:id/merge_requests` et `GET /projects/:id/merge_requests/:merge_request_iid`. |
| [API Notes](../../api/notes.md)                                                                       | Peut accéder aux points de terminaison `GET /projects/:id/merge_requests/:merge_request_iid/notes` et `GET /projects/:id/merge_requests/:merge_request_iid/notes/:note_id`. |
| [API Paquets](../../api/packages.md)                                                                 | Peut accéder à tous les points de terminaison de cette API. |
| [API Jetons de déclenchement de pipeline](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)         | Peut accéder uniquement au point de terminaison `POST /projects/:id/trigger/pipeline`. |
| [API Pipelines](../../api/pipelines.md#update-pipeline-metadata)                                      | Peut accéder uniquement au point de terminaison `PUT /projects/:id/pipelines/:pipeline_id/metadata`. |
| [API Liens de release](../../api/releases/links.md)                                                      | Peut accéder à tous les points de terminaison de cette API. |
| [API Releases](../../api/releases/_index.md)                                                          | Peut accéder à tous les points de terminaison de cette API. |
| [API Dépôts](../../api/repositories.md#generate-changelog-data)                                 | Peut accéder uniquement au point de terminaison `GET /projects/:id/repository/changelog` des dépôts publics. |
| [API Tags](../../api/tags.md)                                                                         | Peut accéder aux points de terminaison `GET /projects/:id/repository/tags` et `GET /projects/:id/repository/tags/:tag_name`. |

Une [proposition](https://gitlab.com/groups/gitlab-org/-/epics/3559) ouverte existe pour rendre les permissions plus granulaires.

## Sécurité du jeton de job GitLab CI/CD {#gitlab-cicd-job-token-security}

Si un jeton de job est compromis, il pourrait potentiellement être utilisé pour accéder aux données privées accessibles à l'utilisateur qui a exécuté le job CI/CD. Pour aider à prévenir la fuite ou l'utilisation abusive de ce jeton, GitLab :

- Masque le jeton de job dans les job logs.
- Accorde des permissions au jeton de job uniquement lorsque le job est en cours d'exécution.

Vous devez également configurer vos [runners](../runners/_index.md) pour qu'ils soient sécurisés :

- Évitez d'utiliser le mode Docker `privileged` si les machines sont réutilisées.
- Évitez d'utiliser l'[exécuteur `shell`](https://docs.gitlab.com/runner/executors/shell/) lorsque les jobs s'exécutent sur la même machine.

Une configuration GitLab Runner non sécurisée augmente le risque que quelqu'un puisse voler des jetons d'autres jobs.

## Contrôler l'accès au jeton de job à votre projet {#control-job-token-access-to-your-project}

Vous pouvez contrôler quels groupes ou projets peuvent utiliser un jeton de job pour s'authentifier et accéder à certaines ressources de votre projet.

Par défaut, l'accès au jeton de job est limité aux seuls jobs CI/CD qui s'exécutent dans les pipelines de votre projet. Pour permettre à un autre groupe ou projet de s'authentifier avec un jeton de job provenant du pipeline de l'autre projet :

- Vous devez [ajouter le groupe ou le projet à la liste des jetons de job autorisés](#add-a-group-or-project-to-the-job-token-allowlist).
- L'utilisateur qui déclenche le job doit être membre de votre projet.
- L'utilisateur doit disposer des [permissions](../../user/permissions.md) nécessaires pour effectuer l'action.

Si votre projet est public ou interne, certaines ressources accessibles publiquement peuvent être accédées avec un jeton de job depuis n'importe quel projet. Ces ressources peuvent également être [limitées aux seuls projets figurant sur la liste des autorisations](#limit-job-token-scope-for-public-or-internal-projects).

Les administrateurs de GitLab Self-Managed peuvent [remplacer et appliquer ce paramètre](../../administration/settings/continuous_integration.md#access-job-token-permission-settings). Lorsque le paramètre est appliqué, le jeton de job CI/CD est toujours limité à la liste des autorisations du projet.

### Ajouter un groupe ou un projet à la liste des jetons de job autorisés {#add-a-group-or-project-to-the-job-token-allowlist}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/346298/) dans GitLab 15.9. [Déployé derrière le feature flag `:inbound_ci_scoped_job_token`](../../administration/feature_flags/_index.md), activé par défaut.
- [Feature flag supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/346298/) dans GitLab 15.10.
- Le paramètre **Allow access to this project with a CI_JOB_TOKEN** [renommé en **Limit access to this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) dans GitLab 16.3.
- L'ajout de groupes à la liste des jetons de job autorisés [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) dans GitLab 17.0.
- La section **Token Access** renommée en **Permissions de jetons de job**, et [le paramètre **Limit access to this project** renommé en **Groupes et projets autorisés**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) dans GitLab 17.2.
- [Le paramètre **Groupes et projets autorisés** renommé en **Liste des jetons de job CI/CD autorisés**](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160078) dans GitLab 17.3.
- L'option **Ajouter un projet** [renommée en **Ajouter**](https://gitlab.com/gitlab-org/gitlab/-/issues/470880/) dans GitLab 17.6.

{{< /history >}}

Vous pouvez ajouter des groupes ou des projets à votre liste des jetons de job autorisés pour permettre l'accès aux ressources de votre projet avec un jeton de job pour l'authentification. Par défaut, la liste des autorisations de tout projet ne comprend que lui-même. N'ajoutez des groupes ou des projets à la liste des autorisations que lorsqu'un accès inter-projets est nécessaire.

L'ajout d'un projet à la liste des autorisations ne confère pas de [permissions](../../user/permissions.md) supplémentaires aux membres du projet autorisé. Ils doivent déjà disposer des permissions nécessaires pour accéder aux ressources de votre projet afin d'utiliser un jeton de job du projet autorisé pour accéder à votre projet.

Par exemple, le projet A peut ajouter le projet B à la liste des autorisations du projet A. Les jobs CI/CD du projet B (le « projet autorisé ») peuvent désormais utiliser des jetons de job CI/CD pour authentifier les appels d'API REST afin d'accéder au projet A.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet actuel. Si le projet autorisé est interne ou privé, vous devez avoir le rôle Guest, Planificateur, Reporter, Developer, Maintainer ou Owner dans ce projet.
- Vous ne devez pas avoir plus de 200 groupes et projets ajoutés à la liste des autorisations.

Pour ajouter un groupe ou un projet à la liste des autorisations :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Permissions de jetons de job**.
1. À droite de **Liste des jetons de job CI/CD autorisés**, sélectionnez **Ajouter**.
1. Sélectionnez **Groupe ou projet**
1. Saisissez le chemin du groupe ou du projet à ajouter à la liste des autorisations, puis sélectionnez **Ajouter**.

Vous pouvez également ajouter un groupe ou un projet à la liste des autorisations [via l'API](../../api/graphql/reference/_index.md#mutationcijobtokenscopeaddgrouporproject).

### Limiter la portée du jeton de job pour les projets publics ou internes {#limit-job-token-scope-for-public-or-internal-projects}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/405369) dans GitLab 16.6.
- L'accès au dépôt [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/439158) dans GitLab 17.0.

{{< /history >}}

Les projets ne figurant pas sur la liste des autorisations peuvent utiliser un jeton de job pour s'authentifier auprès de projets publics ou internes afin de :

- Récupérer des artefacts de job.
- Accéder au registre de conteneurs.
- Accéder au registre de paquets.
- Accéder aux releases, aux déploiements et aux environnements.
- Accéder au dépôt.

Vous pouvez limiter l'accès à ces actions aux seuls projets figurant sur la liste des autorisations en configurant chaque fonctionnalité pour qu'elle ne soit visible que par les membres du projet.

Prérequis :

- Vous devez avoir le rôle Maintainer pour le projet.

Pour configurer une fonctionnalité afin qu'elle ne soit visible que par les membres du projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Définissez la visibilité sur **Only project members** pour les fonctionnalités dont vous souhaitez restreindre l'accès.
   - La possibilité de récupérer des artefacts de job est contrôlée par le paramètre de visibilité CI/CD.
1. Sélectionnez **Sauvegarder les modifications**.

### Autoriser n'importe quel projet à accéder à votre projet {#allow-any-project-to-access-your-project}

{{< details >}}

- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Le paramètre **Allow access to this project with a CI_JOB_TOKEN** [renommé en **Limit access to this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) dans GitLab 16.3.
- La section **Token Access** renommée en **Permissions de jetons de job**, et [le paramètre **Limit access to this project** renommé en **Groupes et projets autorisés**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) dans GitLab 17.2.
- [Le paramètre **Groupes et projets autorisés** renommé en **Liste des jetons de job CI/CD autorisés**](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160078) dans GitLab 17.3.

{{< /history >}}

> [!warning]
> Désactiver la limite d'accès au jeton et la liste des autorisations constitue un risque de sécurité. Un utilisateur malveillant pourrait tenter de compromettre un pipeline créé dans un projet non autorisé. Si le pipeline a été créé par l'un de vos maintainers, le jeton de job pourrait être utilisé pour tenter d'accéder à votre projet.

Si vous désactivez la liste des jetons de job CI/CD autorisés, les jobs de n'importe quel projet peuvent accéder à votre projet avec un jeton de job. L'utilisateur qui déclenche le pipeline doit avoir la permission d'accéder à votre projet. Vous ne devez désactiver ce paramètre qu'à des fins de test ou pour une raison similaire, et vous devez le réactiver dès que possible.

Cette option n'est disponible que sur les instances GitLab Self-Managed ou GitLab Dedicated avec le paramètre [**Enable and enforce job token allowlist for all projects**](../../administration/settings/continuous_integration.md#enforce-job-token-allowlist) désactivé.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

Pour désactiver la liste des jetons de job autorisés :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Permissions de jetons de job**.
1. Sélectionnez **Tous les groupes et projets**.
1. Recommandé. Une fois les tests terminés, sélectionnez **This project and any groups and projects in the allowlist** pour réactiver la liste des jetons de job autorisés.

Vous pouvez également modifier ce paramètre avec l'[API GraphQL](../../api/graphql/reference/_index.md#mutationprojectcicdsettingsupdate) (`inboundJobTokenScopeEnabled`) ou l'[API REST](../../api/project_job_token_scopes.md#update-the-cicd-job-token-access-settings-for-a-project).

### Autoriser les requêtes de poussée Git vers le dépôt de votre projet {#allow-git-push-requests-to-your-project-repository}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/389060) dans GitLab 17.2. [avec un flag](../../administration/feature_flags/_index.md) nommé `allow_push_repository_for_job_token`. Désactivé par défaut.
- La section **Token Access** renommée en **Permissions de jetons de job**, et [le paramètre **Limit access to this project** renommé en **Groupes et projets autorisés**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) dans GitLab 17.2.
- [Le paramètre **Groupes et projets autorisés** renommé en **Liste des jetons de job CI/CD autorisés**](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160078) dans GitLab 17.3.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/468320) dans GitLab 18.3
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/issues/468320) dans GitLab 18.4. Feature flag `allow_push_repository_for_job_token` supprimé.

{{< /history >}}

Vous pouvez configurer votre projet pour autoriser les requêtes de poussée Git authentifiées avec un jeton de job CI/CD. Ce paramètre est désactivé par défaut.

Lorsque vous activez ce paramètre, seuls les jetons de job générés par des jobs CI/CD s'exécutant dans les pipelines du projet peuvent pousser vers le projet.

Lorsque vous utilisez un jeton de job pour pousser vers le projet, aucun pipeline CI/CD n'est déclenché. Le jeton de job dispose des mêmes permissions d'accès que l'utilisateur qui a démarré le job.

Si vous utilisez l'outil `semantic-release`, [ce paramètre pourrait empêcher la création de pipelines](#the-semantic-release-tool-and-job-tokens).

> [!warning]
> N'activez pas ce paramètre sur les projets configurés comme [miroirs de tirage](../../user/project/repository/mirror/pull.md), en particulier si [des pipelines s'exécutent pour les mises à jour du miroir](../../user/project/repository/mirror/pull.md#trigger-pipelines-for-mirror-updates). Le propriétaire du dépôt en amont pourrait tenter d'utiliser `CI_JOB_TOKEN` pour pousser des commits vers le projet mis en miroir.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

Pour accorder la permission aux jetons de job générés dans votre projet de pousser vers le dépôt du projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Permissions de jetons de job**.
1. Dans la section **Autorisations**, sélectionnez **Autoriser les requêtes de poussée Git dans le dépôt**.

Vous pouvez également contrôler ce paramètre avec le paramètre `ci_push_repository_for_job_token_allowed` dans l'[API projets](../../api/projects.md#update-a-project).

### Autoriser les requêtes de poussée Git inter-projets à partir des projets autorisés {#allow-cross-project-git-push-requests-from-allowlisted-projects}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/479907) dans GitLab 19.0 [avec un flag](../../administration/feature_flags/_index.md) nommé `allow_push_to_allowlisted_projects`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Vous pouvez autoriser les jetons de job CI/CD des projets autorisés à pousser vers le dépôt de votre projet. Ceci est utile pour les workflows GitOps, le balisage de sous-modules et les pipelines CI/CD inter-dépôts sans jetons d'accès de longue durée.

Lorsqu'une poussée par jeton de job réussit, aucun pipeline CI/CD n'est déclenché dans le projet cible.

> [!warning]
> N'activez pas ce paramètre sur les projets configurés comme [miroirs de tirage](../../user/project/repository/mirror/pull.md), en particulier si [des pipelines sont déclenchés pour les mises à jour du miroir](../../user/project/repository/mirror/pull.md#trigger-pipelines-for-mirror-updates). Un propriétaire d'un projet source autorisé pourrait pousser des commits vers votre projet mis en miroir en utilisant un jeton de job CI/CD.

Pour que la poussée inter-projets fonctionne, toutes les conditions suivantes doivent être remplies :

- Le projet cible a **Autoriser les requêtes de poussée Git dans le dépôt** activé.
- Le projet cible a **Allow cross-project Git push requests from allowlisted projects** activé.
- Le projet cible a la [liste des jetons de job autorisés](#add-a-group-or-project-to-the-job-token-allowlist) activée.
- Le projet source figure sur la liste des autorisations du projet cible avec la [permission fine-grained](fine_grained_permissions.md) `admin_repositories`, ou avec les permissions par défaut (aucune restriction fine-grained définie). Une entrée de groupe sur la liste des autorisations qui inclut le projet source satisfait également à cette exigence.
- L'utilisateur qui a démarré le pipeline dispose au moins du rôle Developer sur le projet cible.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

Pour autoriser les requêtes de poussée inter-projets :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Permissions de jetons de job**.
1. Dans la section **Autorisations**, sélectionnez **Autoriser les requêtes de poussée Git dans le dépôt**.
1. Sélectionnez **Allow cross-project Git push requests from allowlisted projects**.
1. Sélectionnez **Enregistrer les modifications**.
1. [Ajoutez le projet source ou son groupe à la liste des autorisations](#add-a-group-or-project-to-the-job-token-allowlist) avec la permission fine-grained `ADMIN_REPOSITORIES`, ou laissez les permissions par défaut activées.

## Permissions fine-grained pour les jetons de job {#fine-grained-permissions-for-job-tokens}

Vous pouvez utiliser les permissions fine-grained pour autoriser explicitement l'accès à un ensemble limité de points de terminaison de l'API REST.

Pour plus d'informations, consultez [les permissions fine-grained pour les jetons de job CI/CD](fine_grained_permissions.md).

## Clonage de dépôt Git {#git-repository-cloning}

Vous pouvez utiliser le jeton de job pour vous authentifier et cloner un dépôt depuis un projet privé dans un job CI/CD. Utilisez `gitlab-ci-token` comme utilisateur et la valeur du jeton de job comme mot de passe.

Par exemple :

```shell
git clone https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.example.com/<namespace>/<project>
```

Vous pouvez utiliser ce jeton de job pour cloner un dépôt même si le protocole HTTPS est [désactivé par les paramètres du groupe, du projet ou de l'instance](../../administration/settings/visibility_and_access_controls.md#configure-enabled-git-access-protocols).

## Authentification par API REST {#rest-api-authentication}

Vous pouvez utiliser un jeton de job pour authentifier des requêtes vers des points de terminaison spécifiques de l'API REST en utilisant ces méthodes :

- En-tête : `--header "JOB-TOKEN: $CI_JOB_TOKEN"` (recommandé)
- Formulaire : `--form "token=$CI_JOB_TOKEN"`
- Données : `--data "job_token=$CI_JOB_TOKEN"`
- Chaîne de requête dans l'URL : `?job_token=$CI_JOB_TOKEN` (non recommandé)

Par exemple, en utilisant la méthode d'en-tête recommandée :

```shell
curl --verbose --request POST --header "JOB-TOKEN: $CI_JOB_TOKEN" --form ref=master "https://gitlab.com/api/v4/projects/1234/trigger/pipeline"
```

Pour des conseils sur la sécurité des jetons, consultez les [considérations de sécurité](../../security/tokens/_index.md#security-considerations).

Vous ne pouvez pas utiliser de jetons de job pour authentifier des requêtes GraphQL.

## Journal d'authentification du jeton de job {#job-token-authentication-log}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467292/) dans GitLab 17.6.

{{< /history >}}

Vous pouvez suivre quels autres projets utilisent un jeton de job CI/CD pour s'authentifier auprès de votre projet dans un journal d'authentification. Pour consulter le journal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Permissions de jetons de job**. La section **Journal d'authentification** affiche la liste des autres projets qui ont accédé à votre projet en s'authentifiant avec un jeton de job.
1. Facultatif. Sélectionnez **Télécharger au format CSV** pour télécharger le journal d'authentification complet au format CSV.

Le journal d'authentification affiche un maximum de 100 événements d'authentification. Si le nombre d'événements est supérieur à 100, téléchargez le fichier CSV pour consulter le journal.

Les nouvelles authentifications auprès d'un projet peuvent prendre jusqu'à 5 minutes pour apparaître dans le journal d'authentification.

## Utiliser le format hérité pour les jetons CI/CD {#use-legacy-format-for-cicd-tokens}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/514860) dans GitLab 17.10.

{{< /history >}}

À partir de GitLab 19.0, les jetons de job CI/CD utilisent le standard JWT par défaut. Les projets peuvent continuer à utiliser le format hérité en configurant le groupe principal de leur projet. Ce paramètre n'est disponible que jusqu'à la release de GitLab 20.0.

Pour utiliser le format hérité pour vos jetons CI/CD :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Désactivez **Activer le format JWT pour les jetons de job CI/CD**.

Vos jetons CI/CD utilisent désormais le format hérité. Si vous souhaitez utiliser à nouveau le format JWT ultérieurement, vous pouvez réactiver ce paramètre.

## Dépannage {#troubleshooting}

Les échecs de jeton de job CI sont généralement affichés sous la forme de réponses comme `404 Not Found` ou similaires :

- Clone Git non autorisé :

  ```plaintext
  $ git clone https://gitlab-ci-token:$CI_JOB_TOKEN@gitlab.com/fabiopitino/test2.git

  Cloning into 'test2'...
  remote: The project you were looking for could not be found or you don't have permission to view it.
  fatal: repository 'https://gitlab-ci-token:[MASKED]@gitlab.com/<namespace>/<project>.git/' not found
  ```

- Téléchargement de paquet non autorisé :

  ```plaintext
  $ wget --header="JOB-TOKEN: $CI_JOB_TOKEN" ${CI_API_V4_URL}/projects/1234/packages/generic/my_package/0.0.1/file.txt

  --2021-09-23 11:00:13--  https://gitlab.com/api/v4/projects/1234/packages/generic/my_package/0.0.1/file.txt
  Resolving gitlab.com (gitlab.com)... 172.65.251.78, 2606:4700:90:0:f22e:fbec:5bed:a9b9
  Connecting to gitlab.com (gitlab.com)|172.65.251.78|:443... connected.
  HTTP request sent, awaiting response... 404 Not Found
  2021-09-23 11:00:13 ERROR 404: Not Found.
  ```

- Requête d'API non autorisée :

  ```plaintext
  $ curl --verbose --request POST --form "token=$CI_JOB_TOKEN" --form ref=master "https://gitlab.com/api/v4/projects/1234/trigger/pipeline"

  < HTTP/2 404
  < date: Thu, 23 Sep 2021 11:00:12 GMT
  {"message":"404 Not Found"}
  < content-type: application/json
  ```

Lors du dépannage des problèmes d'authentification par jeton de job CI/CD, soyez conscient que :

- Une [mutation GraphQL d'exemple](../../api/graphql/getting_started.md#update-project-settings) est disponible pour basculer les paramètres de portée par projet.
- [Ce commentaire](https://gitlab.com/gitlab-org/gitlab/-/issues/351740#note_1335673157) montre comment utiliser GraphQL avec Bash et cURL pour :
  - Activer la portée d'accès au jeton entrant.
  - Donner accès au projet B depuis le projet A, ou ajouter B à la liste des autorisations de A.
  - Supprimer l'accès au projet.
- Le jeton de job CI devient invalide si le job n'est plus en cours d'exécution, a été effacé, ou si le projet est en cours de suppression.

### L'outil `semantic-release` et les jetons de job {#the-semantic-release-tool-and-job-tokens}

Il existe un problème connu si vous utilisez l'outil `semantic-release` avec le [paramètre **Autoriser les requêtes de poussée Git dans le dépôt**](#allow-git-push-requests-to-your-project-repository). Lorsqu'il est activé :

- L'outil s'authentifie avec le jeton de job, même si l'outil est configuré pour utiliser un jeton d'accès personnel.
- Le jeton de job ne déclenche pas de nouveaux pipelines, donc les pipelines de release pourraient ne pas s'exécuter.

Pour plus d'informations, consultez le [ticket 891](https://github.com/semantic-release/gitlab/issues/891).

### Erreurs de jeton de job au format JWT {#jwt-format-job-token-errors}

Il existe des problèmes connus avec le format JWT pour les jetons de job CI/CD.

#### Erreur `Error when persisting the task ARN.` avec l'exécuteur personnalisé EC2 Fargate Runner {#error-when-persisting-the-task-arn-error-with-ec2-fargate-runner-custom-executor}

Il existe [un bug](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/fargate/-/issues/86) dans la version `0.5.0` et les versions antérieures de l'exécuteur personnalisé EC2 Fargate. Ce problème provoque cette erreur :

- `Error when persisting the task ARN. Will stop the task for cleanup`

Pour résoudre ce problème, mettez à niveau vers la version `0.5.1` ou une version ultérieure de l'exécuteur personnalisé Fargate.

#### Erreur `invalid character '\n' in string literal` avec l'encodage `base64` {#invalid-character-n-in-string-literal-error-with-base64-encoding}

Si vous utilisez `base64` pour encoder des jetons de job, vous pourriez recevoir une erreur `invalid character '\n'`.

Le comportement par défaut de la commande `base64` enveloppe les chaînes de caractères de plus de 79 caractères. Lors de l'encodage `base64` des jetons de job au format JWT pendant l'exécution du job, par exemple avec `echo $CI_JOB_TOKEN | base64`, le jeton est rendu invalide.

Pour résoudre ce problème, utilisez `base64 -w0` pour désactiver l'enveloppement automatique du jeton.

#### Erreur : `403 Forbidden` dans les jobs de longue durée {#error-403-forbidden-in-long-running-jobs}

Lors de l'utilisation de jetons de job au format JWT dans GitLab 18.8 et versions antérieures, un job pourrait échouer avec une erreur `403 Forbidden`. Cela peut se produire dans :

- Les jobs qui utilisent [`needs`](../yaml/_index.md#needs).
- Les jobs dans les [pipelines enfants](../pipelines/downstream_pipelines.md#parent-child-pipelines).
- Les jobs qui s'exécutent pendant plus d'environ 6 minutes sans produire de sortie console.

L'erreur apparaissait généralement dans les logs du runner sous la forme :

```plaintext
WARNING: Submitting job to coordinator... job failed
  code=403 job=<job_id> status=PUT https://gitlab.com/api/v4/jobs/<job_id>: 403 Forbidden
```

Mettez à niveau vers GitLab 18.9 pour éviter ce problème.

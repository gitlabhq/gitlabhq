---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Environnements
description: "Environnements, variables, tableaux de bord et environnements éphémères."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Un environnement GitLab représente une cible de déploiement spécifique pour votre application, comme le développement, la staging ou la production. Utilisez-le pour gérer différentes configurations et déployer du code lors des différentes étapes du cycle de vie de votre logiciel.

Avec les environnements, vous pouvez :

- Maintenir la cohérence et la reproductibilité de votre processus de déploiement
- Suivre quel code est déployé et où
- Revenir à des versions précédentes en cas de problème
- Protéger les environnements sensibles contre les modifications non autorisées
- Contrôler les variables de déploiement par environnement pour maintenir les limites de sécurité
- Surveiller l'état des environnements et recevoir des alertes en cas de problème

## Afficher les environnements et les déploiements {#view-environments-and-deployments}

Prérequis :

- Dans un projet privé, vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner. Consultez [Autorisations des environnements](#environment-permissions).

Il existe plusieurs façons d'afficher la liste des environnements d'un projet donné :

- Sur la page de présentation du projet, si au moins un environnement est disponible (c'est-à-dire non arrêté).

  ![Page de présentation d'un projet affichant le nombre d'environnements disponibles sous forme de compteur incrémental.](img/environments_project_home_v15_9.png)

- Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**. Les environnements s'affichent.

  ![Liste des environnements disponibles dans un projet GitLab, affichant les noms des environnements, les statuts et d'autres informations pertinentes.](img/environments_list_v14_8.png)

- Pour afficher la liste des déploiements d'un environnement, sélectionnez le nom de l'environnement, par exemple `staging`. Les déploiements n'apparaissent dans cette liste qu'après qu'un job de déploiement les a créés.

  ![Liste des déploiements pour un environnement sélectionné, affichant l'historique des déploiements et les détails associés.](img/deployments_list_v13_10.png)

- Pour afficher la liste de tous les jobs manuels dans un pipeline de déploiement, sélectionnez la liste déroulante **Exécution** ({{< icon name="play" >}}).

  ![Affichage d'un job manuel dans un pipeline de déploiement](img/view_manual_jobs_v17_10.png)

### URL d'environnement {#environment-url}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/337417) pour conserver des URL arbitraires dans GitLab 15.2 [avec un flag](../../administration/feature_flags/_index.md) nommé `soft_validation_on_external_url`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/337417) dans GitLab 15.3. [Feature flag `soft_validation_on_external_url`](https://gitlab.com/gitlab-org/gitlab/-/issues/367206) supprimé.

{{< /history >}}

L'[URL d'environnement](../yaml/_index.md#environmenturl) s'affiche à plusieurs endroits dans GitLab :

- Dans une merge request sous forme de lien :

  ![URL d'environnement dans une merge request](img/environments_mr_review_app_v11_10.png)

- Dans la vue Environnements sous forme de bouton :

  ![Ouvrir l'environnement en direct depuis la vue des environnements](img/environments_open_live_environment_v14_8.png)

- Dans la vue Déploiements sous forme de bouton :

  ![URL d'environnement dans les déploiements](img/deployments_view_v11_10.png)

Ces informations sont visibles dans une merge request si :

- La merge request est finalement fusionnée dans la branche par défaut (généralement `main`).
- Cette branche déploie également dans un environnement (par exemple, `staging` ou `production`).

Par exemple :

![URL d'environnement dans une merge request](img/environments_link_url_mr_v10_1.png)

#### Accéder aux pages publiques depuis les fichiers sources {#go-from-source-files-to-public-pages}

Avec les [Route Maps](../review_apps/_index.md#route-maps) GitLab, vous pouvez accéder directement des fichiers sources aux pages publiques dans l'environnement défini pour les environnements éphémères.

## Types d'environnements {#types-of-environments}

Un environnement est soit statique, soit dynamique.

Environnements statiques :

- Sont généralement réutilisés par des déploiements successifs.
- Ont des noms statiques. Par exemple, `staging` ou `production`.
- Sont créés manuellement ou dans le cadre d'un pipeline CI/CD.

Environnements dynamiques :

- Sont généralement créés dans un pipeline CI/CD et utilisés par un seul déploiement, puis arrêtés ou supprimés.
- Ont des noms dynamiques, généralement basés sur la valeur d'une variable CI/CD.
- Sont une fonctionnalité des [environnements éphémères](../review_apps/_index.md).

Un environnement a l'un des trois états suivants, selon que son [job d'arrêt](../yaml/_index.md#environmenton_stop) a été exécuté ou non :

- `available` :  L'environnement existe. Un déploiement est possible.
- `stopping` :  Le _job on stop_ a démarré. Cet état ne s'applique pas lorsqu'aucun job on stop n'est défini.
- `stopped` :  Soit le _job on stop_ a été exécuté, soit un utilisateur a arrêté le job manuellement.

## Créer un environnement statique {#create-a-static-environment}

Vous pouvez créer un environnement statique dans l'interface utilisateur ou dans votre fichier `.gitlab-ci.yml`.

### Dans l'interface utilisateur {#in-the-ui}

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire.

Pour créer un environnement statique dans l'interface utilisateur :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez **Créer un environnement**.
1. Remplissez les champs.
1. Sélectionnez **Enregistrer**.

### Dans votre fichier `.gitlab-ci.yml` {#in-your-gitlab-ciyml-file}

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire.

Pour créer un environnement statique, dans votre fichier `.gitlab-ci.yml` :

1. Définissez un job dans l'étape `deploy`.
1. Dans le job, définissez les paramètres `name` et `url` de l'environnement. Si un environnement portant ce nom n'existe pas au moment de l'exécution du pipeline, il est créé.

> [!note]
> Certains caractères ne peuvent pas être utilisés dans les noms d'environnement. Pour plus d'informations sur les mots-clés `environment`, consultez la [référence des mots-clés `.gitlab-ci.yml`](../yaml/_index.md#environment).

Par exemple, pour créer un environnement nommé `staging`, avec l'URL `https://staging.example.com` :

```yaml
deploy_staging:
  stage: deploy
  script:
    - echo "Deploy to staging server"
  environment:
    name: staging
    url: https://staging.example.com
```

## Créer un environnement dynamique {#create-a-dynamic-environment}

Pour créer un environnement dynamique, vous utilisez des [variables CI/CD](#cicd-variables) propres à chaque pipeline.

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire.

Pour créer un environnement dynamique, dans votre fichier `.gitlab-ci.yml` :

1. Définissez un job dans l'étape `deploy`.
1. Dans le job, définissez les attributs d'environnement suivants :
   - `name` :  Utilisez une variable CI/CD associée telle que `$CI_COMMIT_REF_SLUG`. Vous pouvez également ajouter un préfixe statique au nom de l'environnement, ce qui [regroupe dans l'interface utilisateur](#group-similar-environments) tous les environnements ayant le même préfixe.
   - `url` :  facultatif. Préfixez le nom d'hôte avec une variable CI/CD associée telle que `$CI_ENVIRONMENT_SLUG`.

> [!note]
> Certains caractères ne peuvent pas être utilisés dans les noms d'environnement. Pour plus d'informations sur les mots-clés `environment`, consultez la [référence des mots-clés `.gitlab-ci.yml`](../yaml/_index.md#environment).

Dans l'exemple suivant, à chaque exécution du job `deploy_review_app`, le nom et l'URL de l'environnement sont définis à l'aide de valeurs uniques.

```yaml
deploy_review_app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: never
    - if: $CI_COMMIT_BRANCH
```

### Définir une URL d'environnement dynamique {#set-a-dynamic-environment-url}

Certaines plateformes d'hébergement externes génèrent une URL aléatoire pour chaque déploiement, par exemple `https://94dd65b.amazonaws.com/qa-lambda-1234567`. Il est donc difficile de référencer l'URL dans le fichier `.gitlab-ci.yml`.

Vous pouvez configurer un job de déploiement pour capturer l'URL générée en tant que variable dotenv et la transmettre à `environment:url`. Spécifiez [`artifacts:reports:dotenv`](../variables/dotenv_variables.md) dans votre job. À la fin du job, GitLab analyse le rapport dotenv et développe `environment:url` avec la valeur de la variable. L'URL assignée est alors visible dans l'interface utilisateur.

Vous pouvez également combiner un préfixe statique avec la variable, par exemple `https://$DYNAMIC_ENVIRONMENT_URL`. Si `DYNAMIC_ENVIRONMENT_URL` est `example.com`, le résultat est `https://example.com`.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation générale, consultez [définir des URL dynamiques après la fin d'un job](https://youtu.be/70jDXtOf4Ig).

Dans l'exemple suivant, un environnement éphémère crée un nouvel environnement pour chaque merge request :

- Le job `review` est déclenché par chaque push et crée ou met à jour un environnement nommé `review/your-branch-name`. L'URL de l'environnement est définie sur `$DYNAMIC_ENVIRONMENT_URL`.
- À la fin du job `review`, GitLab met à jour l'URL de l'environnement `review/your-branch-name`. Il analyse le rapport `deploy.env`, extrait les variables et les utilise pour développer et définir `environment:url`.

```yaml
review:
  script:
    - DYNAMIC_ENVIRONMENT_URL=$(deploy-script)                                 # In script, get the environment URL.
    - echo "DYNAMIC_ENVIRONMENT_URL=$DYNAMIC_ENVIRONMENT_URL" >> deploy.env    # Add the value to a dotenv file.
  artifacts:
    reports:
      dotenv: deploy.env                                                       # Report back dotenv file to rails.
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: $DYNAMIC_ENVIRONMENT_URL                                              # and set the variable produced in script to `environment:url`
    on_stop: stop_review

stop_review:
  script:
    - ./teardown-environment
  when: manual
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
```

Remarques :

- `stop_review` ne génère pas d'artefact de rapport dotenv et ne reconnaît donc pas la variable CI/CD `DYNAMIC_ENVIRONMENT_URL`. Par conséquent, vous ne devez pas définir `environment:url` dans le job `stop_review`.
- Si l'URL de l'environnement n'est pas valide (par exemple, si l'URL est malformée), le système ne met pas à jour l'URL de l'environnement.
- Si le script qui s'exécute dans `stop_review` existe uniquement dans votre dépôt et ne peut donc pas utiliser `GIT_STRATEGY: none` ni `GIT_STRATEGY: empty`, configurez des [pipelines de merge request](../pipelines/merge_request_pipelines.md) pour ces jobs. Cela garantit que les runners peuvent récupérer le dépôt même après la suppression d'une branche de fonctionnalité. Pour plus d'informations, consultez [Ref Specs pour les runners](../pipelines/_index.md#ref-specs-for-runners).

> [!note]
> Pour les runners Windows, vous devez utiliser la commande PowerShell `Add-Content` pour écrire dans les fichiers `.env`.

```powershell
Add-Content -Path deploy.env -Value "DYNAMIC_ENVIRONMENT_URL=$DYNAMIC_ENVIRONMENT_URL"
```

## Niveau de déploiement des environnements {#deployment-tier-of-environments}

Les projets d'un même groupe peuvent utiliser des noms d'environnement différents pour le même niveau de déploiement. Par exemple, un projet peut utiliser production tandis qu'un autre utilise custom-portal pour le même niveau. Les environnements protégés de groupe utilisent des niveaux de déploiement pour gérer ces différences.

Les niveaux de déploiement disponibles sont les suivants :

- development
- testing
- staging
- production
- other

GitLab détermine les niveaux de déploiement à partir du [nom de l'environnement](../yaml/_index.md#environmentname) en se basant sur ces patterns :

| Pattern d'expression régulière Ruby                                         | Niveau de déploiement |
|-------------------------------------------------------------|-----------------|
| `/(dev\|review\|trunk)/i`                                   | development     |
| `/(test\|tst\|int\|ac(ce\|)pt\|qa\|qc\|control\|quality)/i` | testing         |
| `/(st(a\|)g\|mod(e\|)l\|pre\|demo\|non)/i`                  | staging         |
| `/(pr(o\|)d\|live)/i`                                       | production      |

Les noms d'environnement ne correspondant à aucun pattern sont classés comme `other`.

Pour éviter la détermination automatique, utilisez le [mot-clé `deployment_tier`](../yaml/_index.md#environmentdeployment_tier).

Vous ne pouvez pas définir les niveaux de déploiement dans l'interface utilisateur.

### Renommer un environnement {#rename-an-environment}

{{< history >}}

- Le renommage d'un environnement via l'API a été [déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/338897) dans GitLab 15.9.
- Le renommage d'un environnement avec l'API a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/338897) dans GitLab 16.0.

{{< /history >}}

Vous ne pouvez pas renommer un environnement.

Pour obtenir le même résultat qu'un renommage d'environnement :

1. [Arrêtez l'environnement existant](#stop-an-environment-by-using-the-ui).
1. [Supprimez l'environnement existant](#delete-an-environment).
1. [Créez un nouvel environnement](#create-a-static-environment) avec le nom souhaité.

## Variables CI/CD {#cicd-variables}

Pour personnaliser vos environnements et déploiements, vous pouvez utiliser l'une des [variables CI/CD prédéfinies](../variables/predefined_variables.md) et définir des variables CI/CD personnalisées.

### Limiter la portée d'environnement d'une variable CI/CD {#limit-the-environment-scope-of-a-cicd-variable}

Par défaut, toutes les [variables CI/CD](../variables/_index.md) sont disponibles pour tous les jobs d'un pipeline. Si un outil de test dans un job est compromis, il pourrait tenter de récupérer toutes les variables CI/CD disponibles pour ce job. Pour limiter ce type d'attaque de la chaîne d'approvisionnement, vous devez restreindre la portée d'environnement des variables sensibles aux seuls jobs qui en ont besoin.

Limitez la portée d'environnement d'une variable CI/CD en définissant les environnements pour lesquels elle peut être disponible. La portée d'environnement par défaut est le caractère générique `*`, de sorte que tout job peut accéder à la variable.

Vous pouvez utiliser une correspondance spécifique pour sélectionner un environnement particulier. Par exemple, définissez la portée d'environnement de la variable sur `production` pour n'autoriser que les jobs ayant un [environnement](../yaml/_index.md#environment) `production` à accéder à la variable.

Vous pouvez également utiliser la correspondance par caractère générique (`*`) pour sélectionner un groupe d'environnements particulier, comme tous les [environnements éphémères](../review_apps/_index.md) avec `review/*`.

Par exemple, avec ces quatre environnements :

- `production`
- `staging`
- `review/feature-1`
- `review/feature-2`

Ces portées d'environnement correspondent comme suit :

| ↓ Portée / Environnement → | `production` | `staging` | `review/feature-1` | `review/feature-2` |
|:------------------------|:-------------|:----------|:-------------------|:-------------------|
| `*`                     | Correspondance        | Correspondance     | Correspondance              | Correspondance              |
| `production`            | Correspondance        |           |                    |                    |
| `staging`               |              | Correspondance     |                    |                    |
| `review/*`              |              |           | Correspondance              | Correspondance              |
| `review/feature-1`      |              |           | Correspondance              |                    |

Vous ne devez pas utiliser de variables dont la portée est définie par environnement avec [`rules`](../yaml/_index.md#rules) ou [`include`](../yaml/_index.md#include). Les variables pourraient ne pas être définies lors de la validation de la configuration du pipeline à sa création.

## Rechercher des environnements {#search-environments}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/10754) dans GitLab 15.5.
- [La recherche d'environnements dans un dossier](https://gitlab.com/gitlab-org/gitlab/-/issues/373850) a été introduite dans GitLab 15.7 avec le [feature flag `enable_environments_search_within_folder`](https://gitlab.com/gitlab-org/gitlab/-/issues/382108). Activé par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/382108) dans GitLab 17.4. Feature flag `enable_environments_search_within_folder` supprimé.

{{< /history >}}

Pour rechercher des environnements par nom :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Dans la barre de recherche, saisissez votre terme de recherche.
   - La longueur de votre **search term should be 3 or more characters**.
   - La correspondance s'applique à partir du début du nom de l'environnement.
     - Par exemple, `devel` correspond au nom d'environnement `development`, mais pas `elop`.
   - Pour les environnements dont le nom est au format dossier, la correspondance s'applique après le nom du dossier de base.
     - Par exemple, lorsque le nom est `review/test-app`, le terme de recherche `test` correspond à `review/test-app`.
     - Une recherche avec le nom du dossier en préfixe, comme `review/test`, correspond également à `review/test-app`.

## Regrouper des environnements similaires {#group-similar-environments}

Vous pouvez regrouper des environnements en sections réductibles dans l'interface utilisateur.

Par exemple, si tous vos environnements commencent par le nom `review`, les environnements sont regroupés sous ce titre dans l'interface utilisateur :

![Groupes d'environnements](img/environments_dynamic_groups_v13_10.png)

L'exemple suivant montre comment faire commencer vos noms d'environnement par `review`. La variable `$CI_COMMIT_REF_SLUG` est renseignée avec le nom de la branche au moment de l'exécution :

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
```

## Arrêter un environnement {#stopping-an-environment}

Arrêter un environnement signifie que ses déploiements ne sont plus accessibles sur le serveur cible. Vous devez arrêter un environnement avant de pouvoir le supprimer.

Lors de l'utilisation de l'action `on_stop` pour arrêter un environnement, le job s'exécute s'il n'est pas [archivé](../../administration/settings/continuous_integration.md#archive-pipelines).

### Arrêter un environnement via l'interface utilisateur {#stop-an-environment-by-using-the-ui}

> [!note]
> Pour déclencher une action `on_stop` et arrêter manuellement un environnement depuis la vue Environnements, les jobs d'arrêt et de déploiement doivent appartenir au même [`resource_group`](../yaml/_index.md#resource_group).

Pour arrêter un environnement dans l'interface GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. En regard de l'environnement que vous souhaitez arrêter, sélectionnez **Arrêter**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Arrêter l'environnement**.

### Comportement d'arrêt par défaut {#default-stopping-behavior}

GitLab arrête automatiquement les environnements lorsque la branche associée est supprimée ou fusionnée. Ce comportement persiste même si aucun job CI/CD `on_stop` explicite n'est défini.

Cependant, le [ticket 428625](https://gitlab.com/gitlab-org/gitlab/-/issues/428625) propose de modifier ce comportement afin que les environnements de production et de staging ne s'arrêtent que si un job CI/CD `on_stop` explicite est défini.

Vous pouvez configurer le comportement d'arrêt d'un environnement avec le paramètre [`auto_stop_setting`](../../api/environments.md#update-an-existing-environment) dans l'API Environments.

### Arrêter un environnement lors de la suppression d'une branche {#stop-an-environment-when-a-branch-is-deleted}

Vous pouvez configurer des environnements pour qu'ils s'arrêtent lors de la suppression d'une branche.

Dans l'exemple suivant, un job `deploy_review` appelle un job `stop_review` pour nettoyer et arrêter l'environnement.

- Les deux jobs doivent avoir la même configuration [`rules`](../yaml/_index.md#rules) ou [`only/except`](../yaml/deprecated_keywords.md#only--except). Sinon, le job `stop_review` pourrait ne pas être inclus dans tous les pipelines qui incluent le job `deploy_review`, et vous ne pourrez pas déclencher `action: stop` pour arrêter automatiquement l'environnement.
- Le job avec [`action: stop` pourrait ne pas s'exécuter](#the-job-with-action-stop-doesnt-run) s'il se trouve dans une étape ultérieure à celle du job qui a démarré l'environnement.
- Si vous ne pouvez pas utiliser les [pipelines de merge request](../pipelines/merge_request_pipelines.md), définissez [`GIT_STRATEGY`](../runners/configure_runners.md#git-strategy) sur `none` ou `empty` dans le job `stop_review`. Ainsi, le [runner](https://docs.gitlab.com/runner/) ne tentera pas d'extraire le code après la suppression de la branche.

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com
    on_stop: stop_review

stop_review:
  stage: deploy
  script:
    - echo "Remove review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

### Arrêter un environnement lors de la fusion ou de la fermeture d'une merge request {#stop-an-environment-when-a-merge-request-is-merged-or-closed}

Lorsque vous utilisez la configuration des [pipelines de merge request](../pipelines/merge_request_pipelines.md), le déclencheur `stop` est automatiquement activé.

Dans l'exemple suivant, le job `deploy_review` appelle un job `stop_review` pour nettoyer et arrêter l'environnement.

- Lorsque le paramètre [**Les pipelines doivent réussir**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) est activé, vous pouvez configurer le mot-clé [`allow_failure: true`](../yaml/_index.md#allow_failure) sur le job `stop_review` pour éviter qu'il ne bloque vos pipelines et merge requests.

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    on_stop: stop_review
  rules:
    - if: $CI_MERGE_REQUEST_ID

stop_review:
  stage: deploy
  script:
    - echo "Remove review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  rules:
    - if: $CI_MERGE_REQUEST_ID
      when: manual
```

> [!note]
> Lors de l'utilisation de cette fonctionnalité avec les merge trains, le job `stop` ne s'exécute que si [les pipelines en double sont évités](../jobs/job_rules.md#avoid-duplicate-pipelines).

### Arrêter un environnement après une certaine période {#stop-an-environment-after-a-certain-time-period}

Vous pouvez configurer un environnement pour qu'il s'arrête automatiquement après une certaine période.

> [!note]
> En raison des limitations de ressources, le worker en arrière-plan chargé d'arrêter les environnements ne s'exécute qu'une fois par heure. Cela signifie que les environnements pourraient ne pas être arrêtés exactement après la période spécifiée, mais plutôt lorsque le worker en arrière-plan détecte les environnements expirés.

Dans votre fichier `.gitlab-ci.yml`, spécifiez le mot-clé [`environment:auto_stop_in`](../yaml/_index.md#environmentauto_stop_in). Spécifiez la période en langage naturel, par exemple `1 hour and 30 minutes` ou `1 day`. Une fois la période écoulée, GitLab démarre automatiquement un job pour arrêter l'environnement.

Dans l'exemple suivant :

- Chaque commit sur une merge request exécute un job `review_app` qui déploie la dernière modification dans l'environnement et réinitialise sa période d'expiration.
- Si l'environnement est inactif pendant plus d'une semaine, GitLab exécute automatiquement le job `stop_review_app` pour arrêter l'environnement.

```yaml
review_app:
  script: deploy-review-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    on_stop: stop_review_app
    auto_stop_in: 1 week
  rules:
    - if: $CI_MERGE_REQUEST_ID

stop_review_app:
  script: stop-review-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  rules:
    - if: $CI_MERGE_REQUEST_ID
      when: manual
```

Le mot-clé [`environment:action`](../yaml/_index.md#environmentaction) peut être utilisé pour réinitialiser l'heure à laquelle un environnement est programmé pour s'arrêter. Pour plus d'informations, consultez [Accéder à un environnement à des fins de préparation ou de vérification](#access-an-environment-for-preparation-or-verification-purposes).

#### Afficher la date et l'heure d'arrêt planifiées d'un environnement {#view-an-environments-scheduled-stop-date-and-time}

Lorsqu'un environnement a été [programmé pour s'arrêter après une période spécifiée](#stop-an-environment-after-a-certain-time-period), vous pouvez afficher sa date et son heure d'expiration.

Pour afficher la date et l'heure d'expiration d'un environnement :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez le nom de l'environnement.

La date et l'heure d'expiration s'affichent dans le coin supérieur gauche, à côté du nom de l'environnement.

#### Remplacer la date et l'heure d'arrêt planifiées d'un environnement {#override-an-environments-scheduled-stop-date-and-time}

Lorsqu'un environnement a été [programmé pour s'arrêter après une période spécifiée](#stop-an-environment-after-a-certain-time-period), vous pouvez remplacer son expiration.

Pour remplacer l'expiration d'un environnement dans l'interface utilisateur :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez le nom de l'environnement.
1. Dans le coin supérieur droit, sélectionnez la punaise ({{< icon name="thumbtack" >}}).

Pour remplacer l'expiration d'un environnement dans le fichier `.gitlab-ci.yml` :

1. Ouvrez le fichier `.gitlab-ci.yml` du projet.
1. Mettez à jour le paramètre `auto_stop_in` du job de déploiement correspondant sur `auto_stop_in: never`.

Le paramètre `auto_stop_in` est remplacé et l'environnement reste actif jusqu'à ce qu'il soit arrêté manuellement.

### Nettoyer les environnements obsolètes {#clean-up-stale-environments}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108616) dans GitLab 15.8 [avec un flag](../../administration/feature_flags/_index.md) nommé `stop_stale_environments`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112098) dans GitLab 15.10. Feature flag `stop_stale_environments` supprimé.

{{< /history >}}

Nettoyez les environnements obsolètes lorsque vous souhaitez arrêter les anciens environnements d'un projet.

Prérequis :

- Vous devez disposer du rôle Chargé de maintenance ou Propriétaire.

Pour nettoyer les environnements obsolètes :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez **Nettoyer les environnements**.
1. Sélectionnez la date à utiliser pour déterminer quels environnements considérer comme obsolètes.
1. Sélectionnez **Nettoyer**.

Les environnements actifs qui n'ont pas été mis à jour après la date spécifiée sont arrêtés. Les environnements protégés sont ignorés et ne sont pas arrêtés.

### Exécuter un job de pipeline lorsque l'environnement est arrêté {#run-a-pipeline-job-when-environment-is-stopped}

{{< history >}}

- Le feature flag `environment_stop_actions_include_all_finished_deployments` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/435128) dans GitLab 16.9. Désactivé par défaut.
- Le feature flag `environment_stop_actions_include_all_finished_deployments` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150932) dans GitLab 17.0.

{{< /history >}}

Vous pouvez définir un job d'arrêt pour l'environnement avec une [action `on_stop`](../yaml/_index.md#environmenton_stop) dans le job de déploiement de l'environnement.

Les jobs d'arrêt des déploiements terminés dans le dernier pipeline terminé sont exécutés lorsqu'un environnement est arrêté. Un déploiement ou un pipeline est terminé s'il a le statut réussi, annulé ou échoué.

Prérequis :

- Les jobs de déploiement et d'arrêt doivent avoir la même configuration rules ou only/except.
- Le job d'arrêt doit avoir les mots-clés suivants définis :
  - `when`, défini dans l'un ou l'autre des contextes suivants :
    - [Au niveau du job](../yaml/_index.md#when).
    - [Dans une clause rules](../yaml/_index.md#rules). Si vous utilisez `rules` et `when: manual`, vous devez également définir [`allow_failure: true`](../yaml/_index.md#allow_failure) afin que le pipeline puisse se terminer même si le job ne s'exécute pas.
  - `environment:name`
  - `environment:action`

Dans l'exemple suivant :

- Un job `review_app` appelle un job `stop_review_app` une fois le premier job terminé.
- Le job `stop_review_app` est déclenché selon ce qui est défini sous `when`. Dans ce cas, il est défini sur `manual`, il nécessite donc une [action manuelle](../jobs/job_control.md#create-a-job-that-must-be-run-manually) depuis l'interface GitLab pour s'exécuter.
- Le paramètre `GIT_STRATEGY` est défini sur `none`. Si le job `stop_review_app` est [déclenché automatiquement](#stopping-an-environment), le runner ne tente pas d'extraire le code après la suppression de la branche.

```yaml
review_app:
  stage: deploy
  script: make deploy-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com
    on_stop: stop_review_app

stop_review_app:
  stage: deploy
  variables:
    GIT_STRATEGY: none
  script: make delete-app
  when: manual
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
```

### Actions d'arrêt multiples pour un environnement {#multiple-stop-actions-for-an-environment}

{{< history >}}

- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/358911) dans GitLab 15.0. [Feature flag `environment_multiple_stop_actions`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86685) supprimé.

{{< /history >}}

Pour configurer plusieurs actions d'arrêt **parallel** sur un environnement, spécifiez le mot-clé [`on_stop`](../yaml/_index.md#environmenton_stop) dans plusieurs [jobs de déploiement](../jobs/_index.md#deployment-jobs) pour le même `environment`, tel que défini dans le fichier `.gitlab-ci.yml`.

Lorsqu'un environnement est arrêté, les actions `on_stop` correspondantes provenant uniquement des jobs de déploiement réussis sont exécutées en parallèle, sans ordre particulier.

> [!note]
> Toutes les actions `on_stop` pour un environnement doivent appartenir au même pipeline. Pour utiliser plusieurs actions `on_stop` dans des [pipelines downstream](../pipelines/downstream_pipelines.md), vous devez configurer les actions d'environnement dans le pipeline parent. Pour plus d'informations, consultez [pipelines downstream pour les déploiements](../pipelines/downstream_pipelines.md#advanced-example).

Dans l'exemple suivant, pour l'environnement `test`, il y a deux jobs de déploiement :

- `deploy-to-cloud-a`
- `deploy-to-cloud-b`

Lorsque l'environnement est arrêté, le système exécute les actions `on_stop` `teardown-cloud-a` et `teardown-cloud-b` en parallèle.

```yaml
deploy-to-cloud-a:
  script: echo "Deploy to cloud a"
  environment:
    name: test
    on_stop: teardown-cloud-a

deploy-to-cloud-b:
  script: echo "Deploy to cloud b"
  environment:
    name: test
    on_stop: teardown-cloud-b

teardown-cloud-a:
  script: echo "Delete the resources in cloud a"
  environment:
    name: test
    action: stop
  when: manual

teardown-cloud-b:
  script: echo "Delete the resources in cloud b"
  environment:
    name: test
    action: stop
  when: manual
```

### Arrêter un environnement sans exécuter l'action `on_stop` {#stop-an-environment-without-running-the-on_stop-action}

Il peut arriver que vous souhaitiez arrêter un environnement sans exécuter l'action [`on_stop`](../yaml/_index.md#environmenton_stop) définie. Par exemple, vous souhaitez supprimer de nombreux environnements sans utiliser de [quota de calcul](../pipelines/compute_minutes.md).

Pour arrêter un environnement sans exécuter l'action `on_stop` définie, exécutez l'[API d'arrêt d'un environnement](../../api/environments.md#stop-an-environment) avec le paramètre `force=true`.

### Supprimer un environnement {#delete-an-environment}

Supprimez un environnement lorsque vous souhaitez le retirer ainsi que tous ses déploiements.

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire.
- Vous devez [arrêter](#stopping-an-environment) l'environnement avant de pouvoir le supprimer.

Pour supprimer un environnement :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez l'onglet **Arrêté(e)**.
1. En regard de l'environnement que vous souhaitez supprimer, sélectionnez **Supprimer l'environnement**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Supprimer l'environnement**.

## Accéder à un environnement à des fins de préparation ou de vérification {#access-an-environment-for-preparation-or-verification-purposes}

{{< history >}}

- [Mis à jour](https://gitlab.com/gitlab-org/gitlab/-/issues/437133) pour réinitialiser `auto_stop_in` pour les actions `prepare` et `access` dans GitLab 17.7.

{{< /history >}}

Vous pouvez définir un job qui accède à un environnement à différentes fins, telles que la vérification ou la préparation. Cela permet de contourner efficacement la création de déploiement, afin d'ajuster votre workflow CD avec plus de précision.

Pour ce faire, ajoutez `action: prepare`, `action: verify` ou `action: access` à la section `environment` de votre job :

```yaml
build:
  stage: build
  script:
    - echo "Building the app"
  environment:
    name: staging
    action: prepare
    url: https://staging.example.com
```

Cela vous donne accès aux variables dont la portée est définie par environnement et peut être utilisé pour protéger les builds contre les accès non autorisés. De plus, cela permet d'éviter la fonctionnalité [empêcher les jobs de déploiement obsolètes](deployment_safety.md#prevent-outdated-deployment-jobs).

Si un environnement est configuré pour s'arrêter après une certaine période, les jobs avec l'action `access` ou `prepare` réinitialisent l'heure d'arrêt planifiée. La valeur [`environment:auto_stop_in`](../yaml/_index.md#environmentauto_stop_in) du job de déploiement réussi le plus récent vers l'environnement est utilisée lors de la réinitialisation de l'heure planifiée. Par exemple, si le déploiement le plus récent utilisait `auto_stop_in: 1 week` et est ensuite accédé par un job avec `action: access`, l'environnement sera replanifié pour s'arrêter une semaine après la fin du job d'accès.

Pour accéder à un environnement sans modifier l'heure d'arrêt planifiée, utilisez l'action `verify`.

## Gestion des incidents d'environnement {#environment-incident-management}

Les environnements de production peuvent tomber en panne de manière inattendue, y compris pour des raisons indépendantes de votre volonté. Par exemple, des problèmes liés à des dépendances externes, à l'infrastructure ou à des erreurs humaines peuvent causer des problèmes majeurs dans un environnement. Par exemple :

- Un service cloud dépendant tombe en panne.
- Une bibliothèque tierce est mise à jour et n'est pas compatible avec votre application.
- Quelqu'un effectue une attaque DDoS sur un point de terminaison vulnérable de votre serveur.
- Un opérateur configure mal l'infrastructure.
- Un bug est introduit dans le code de l'application de production.

Vous pouvez utiliser la [gestion des incidents](../../operations/incident_management/_index.md) pour recevoir des alertes en cas de problèmes critiques nécessitant une attention immédiate.

### Afficher les dernières alertes pour les environnements {#view-the-latest-alerts-for-environments}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Si vous [configurez une intégration d'alerte](../../operations/incident_management/integrations.md#configuration), les alertes pour les environnements s'affichent sur la page des environnements. L'alerte ayant la gravité la plus élevée est affichée, ce qui vous permet d'identifier les environnements nécessitant une attention immédiate.

![Alerte d'environnement](img/alert_for_environment_v13_4.png)

Lorsque le ticket qui a déclenché l'alerte est résolu, il est supprimé et n'est plus visible sur la page des environnements.

Si l'alerte nécessite un [rollback](deployments.md#retry-or-roll-back-a-deployment), vous pouvez sélectionner l'onglet de déploiement depuis la page de l'environnement et choisir vers quel déploiement effectuer le rollback.

### Auto Rollback {#auto-rollback}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Dans un workflow de déploiement continu classique, le pipeline CI teste chaque commit avant de le déployer en production. Cependant, du code problématique peut tout de même atteindre la production. Par exemple, du code inefficace mais logiquement correct peut passer les tests même s'il provoque une dégradation sévère des performances. Les opérateurs et les SRE surveillent le système afin de détecter ces problèmes le plus tôt possible. S'ils détectent un déploiement problématique, ils peuvent effectuer un rollback vers une version stable précédente.

GitLab Auto Rollback simplifie ce workflow en déclenchant automatiquement un rollback lorsqu'une [alerte critique](../../operations/incident_management/alerts.md) est détectée. Pour que GitLab sélectionne l'environnement approprié pour le rollback, l'alerte doit contenir une clé `gitlab_environment_name` avec le nom de l'environnement. GitLab sélectionne et redéploie le déploiement réussi le plus récent.

Limitations de GitLab Auto Rollback :

- Le rollback est ignoré si un déploiement est en cours au moment où l'alerte est détectée.
- Un rollback ne peut se produire qu'une fois toutes les trois minutes. Si plusieurs alertes sont détectées simultanément, un seul rollback est effectué.

GitLab Auto Rollback est désactivé par défaut. Pour l'activer :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Restaurations automatiques des déploiements**.
1. Cochez la case **Activer les restaurations automatiques**.
1. Sélectionnez **Sauvegarder les modifications**.

## Autorisations des environnements {#environment-permissions}

Selon votre rôle, vous pouvez interagir avec les environnements dans des projets publics et privés.

### Afficher les environnements {#view-environments}

- Dans les projets publics, tout le monde peut afficher la liste des environnements, y compris les non-membres.
- Dans les projets privés, vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour afficher la liste des environnements.

### Créer et mettre à jour des environnements {#create-and-update-environments}

- Vous devez disposer du rôle Developer, Maintainer ou Owner pour créer un nouvel environnement ou mettre à jour un environnement non protégé existant.
- Pour les [environnements protégés](protected_environments.md), vous devez figurer dans la liste **Autorisés à déployer**.

### Arrêter et supprimer des environnements {#stop-and-delete-environments}

- Vous devez disposer du rôle Developer, Maintainer ou Owner pour arrêter ou supprimer un environnement non protégé.
- Si un environnement est protégé et que vous n'y avez pas accès, vous ne pouvez pas l'arrêter ni le supprimer.

### Exécuter des jobs de déploiement dans des environnements protégés {#run-deployment-jobs-in-protected-environments}

Si vous pouvez effectuer un push ou une fusion vers la branche protégée :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner.

Si vous ne pouvez pas effectuer de push vers la branche protégée :

- Vous devez faire partie d'un groupe avec le rôle Reporter.

Consultez [Accès limité au déploiement vers les environnements protégés](protected_environments.md#deployment-only-access-to-protected-environments).

## Terminaux web (déprécié) {#web-terminals-deprecated}

> [!warning]
> Cette fonctionnalité a été [dépréciée](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) dans GitLab 14.5.

Si vous déployez vers vos environnements à l'aide d'un service de déploiement (par exemple, l'[intégration Kubernetes](../../user/infrastructure/clusters/_index.md)), GitLab peut ouvrir une session de terminal vers votre environnement. Vous pouvez ensuite déboguer les problèmes sans quitter votre navigateur web.

Le terminal web est un déploiement basé sur des conteneurs, qui manque souvent d'outils de base (comme un éditeur) et peut être arrêté ou redémarré à tout moment. Si cela se produit, vous perdez toutes vos modifications. Considérez le terminal web comme un outil de débogage, et non comme un IDE en ligne complet.

Terminaux web :

- Sont disponibles uniquement pour les Maintainers et Owners du projet.
- Doivent [être activés](../../administration/integration/terminal.md).

Dans l'interface utilisateur, pour afficher le terminal web, procédez de l'une des façons suivantes :

- Dans le menu **Actions**, sélectionnez **Terminal** :

  ![Bouton Terminal sur l'index des environnements](img/environments_terminal_button_on_index_v14_3.png)

- Sur la page d'un environnement spécifique, à droite, sélectionnez **Terminal** ({{< icon name="terminal" >}}).

Sélectionnez le bouton pour établir la session de terminal. Il fonctionne comme n'importe quel autre terminal. Vous êtes dans le conteneur créé par votre déploiement, ce qui vous permet de :

- Exécuter des commandes shell et obtenir des réponses en temps réel.
- Consulter les journaux.
- Tester des ajustements de configuration ou de code.

Vous pouvez ouvrir plusieurs terminaux vers le même environnement. Chacun dispose de sa propre session shell et même d'un multiplexeur tel que `screen` ou `tmux`.

## Sujets connexes {#related-topics}

- [Tableau de bord pour Kubernetes](kubernetes_dashboard.md)
- [Déploiements](deployments.md)
- [Environnements protégés](protected_environments.md)
- [Tableau de bord des environnements](environments_dashboard.md)
- [Sécurité des déploiements](deployment_safety.md#restrict-write-access-to-a-critical-environment)

## Dépannage {#troubleshooting}

### Le job avec `action: stop` ne s'exécute pas {#the-job-with-action-stop-doesnt-run}

Dans certains cas, les environnements ne s'arrêtent pas malgré la configuration d'un job `on_stop`. Cela se produit lorsque le job avec `action: stop` n'est pas dans un état exécutable en raison de sa configuration `stages:` ou `needs:`.

Par exemple :

- L'environnement peut démarrer dans une étape qui comporte également un job ayant échoué. Les jobs des étapes ultérieures ne démarrent alors pas. Si le job avec `action: stop` pour l'environnement se trouve également dans une étape ultérieure, il ne peut pas démarrer et l'environnement n'est pas supprimé.
- Le job avec `action: stop` peut avoir une dépendance envers un job qui n'est pas encore terminé.

Pour vous assurer que `action: stop` peut toujours s'exécuter quand nécessaire, vous pouvez :

- Placer les deux jobs dans la même étape :

  ```yaml
  stages:
    - build
    - test
    - deploy

  ...

  deploy_review:
    stage: deploy
    environment:
      name: review/$CI_COMMIT_REF_SLUG
      url: https://$CI_ENVIRONMENT_SLUG.example.com
      on_stop: stop_review

  stop_review:
    stage: deploy
    environment:
      name: review/$CI_COMMIT_REF_SLUG
      action: stop
    when: manual
  ```

- Ajouter une entrée [`needs`](../yaml/_index.md#needs) au job `action: stop` afin que le job puisse démarrer en dehors de l'ordre des étapes :

  ```yaml
  stages:
    - build
    - test
    - deploy
    - cleanup

  ...

  deploy_review:
    stage: deploy
    environment:
      name: review/$CI_COMMIT_REF_SLUG
      url: https://$CI_ENVIRONMENT_SLUG.example.com
      on_stop: stop_review

  stop_review:
    stage: cleanup
    needs:
      - deploy_review
    environment:
      name: review/$CI_COMMIT_REF_SLUG
      action: stop
    when: manual
  ```

### Erreur : job `would create an environment with an invalid parameter` {#error-job-would-create-an-environment-with-an-invalid-parameter}

Si votre projet est configuré pour [créer un environnement dynamique](#create-a-dynamic-environment), vous pourriez rencontrer cette erreur dans un job de déploiement, car le paramètre généré dynamiquement ne peut pas être utilisé pour créer un environnement :

```plaintext
This job could not be executed because it would create an environment with an invalid parameter.
```

Par exemple, votre projet contient le fichier `.gitlab-ci.yml` suivant :

```yaml
deploy:
  script: echo
  environment: production/$ENVIRONMENT
```

Comme la variable CI/CD `$ENVIRONMENT` n'existe pas dans le pipeline, GitLab tente de créer un environnement avec le nom `production/`, ce qui est invalide selon [la contrainte de nom d'environnement](../yaml/_index.md#environmentname).

Pour résoudre ce problème, utilisez l'une des solutions suivantes :

- Supprimez le mot-clé `environment` du job de déploiement. GitLab ignorait déjà le mot-clé invalide, vos pipelines de déploiement restent donc intacts même après la suppression du mot-clé.
- Assurez-vous que la variable existe dans le pipeline. Consultez la [limitation sur les variables prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).
- Si vous avez `environment:deployment_tier` dans votre `.gitlab-ci.yml`, assurez-vous que la valeur est l'un des niveaux pris en charge : `production`, `staging`, `testing`, `development` ou `other`.

#### Si vous obtenez cette erreur sur des environnements éphémères {#if-you-get-this-error-on-review-apps}

Par exemple, si votre fichier `.gitlab-ci.yml` contient les éléments suivants :

```yaml
review:
  script: deploy review app
  environment: review/$CI_COMMIT_REF_NAME
```

Lorsque vous créez une nouvelle merge request avec un nom de branche `bug-fix!`, le job `review` tente de créer un environnement avec `review/bug-fix!`. Cependant, le caractère `!` est invalide pour les environnements, de sorte que le job de déploiement échoue car il était sur le point de s'exécuter sans environnement.

Pour résoudre ce problème, utilisez l'une des solutions suivantes :

- Recréez votre branche de fonctionnalité sans les caractères invalides, comme `bug-fix`.
- Remplacez la [variable prédéfinie](../variables/predefined_variables.md) `CI_COMMIT_REF_NAME` par `CI_COMMIT_REF_SLUG`, qui supprime tous les caractères invalides :

  ```yaml
  review:
    script: deploy review app
    environment: review/$CI_COMMIT_REF_SLUG
  ```

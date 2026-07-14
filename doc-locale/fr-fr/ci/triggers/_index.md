---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Déclencher des pipelines avec l'API"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser un appel API vers le [point de terminaison de l'API des déclencheurs de pipeline](../../api/pipeline_triggers.md) pour déclencher un pipeline pour une branche ou un tag spécifique.

Vous pouvez également [déclencher un pipeline downstream depuis un job CI/CD](../pipelines/downstream_pipelines.md) avec le mot-clé `trigger`.

Si vous [migrez vers GitLab CI/CD](../migration/plan_a_migration.md), vous pouvez déclencher des pipelines GitLab CI/CD en appelant le point de terminaison de l'API depuis les jobs d'un autre fournisseur. Par exemple, dans le cadre d'une migration depuis [Jenkins](../migration/jenkins.md) ou [CircleCI](../migration/circleci.md).

Lors de l'authentification avec l'API, vous pouvez utiliser :

- Un [jeton de déclenchement de pipeline](#create-a-pipeline-trigger-token) pour déclencher un pipeline de branche ou de tag avec le [point de terminaison de l'API des déclencheurs de pipeline](../../api/pipeline_triggers.md).
- Un [jeton de job CI/CD](../jobs/ci_job_token.md) pour [déclencher un pipeline multi-projets](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api).
- Un autre [jeton avec accès à l'API](../../security/tokens/_index.md) pour créer un nouveau pipeline avec le [point de terminaison de l'API de pipeline de projet](../../api/pipelines.md#create-a-new-pipeline).

## Créer un jeton de déclenchement de pipeline {#create-a-pipeline-trigger-token}

Vous pouvez déclencher un pipeline pour une branche ou un tag en générant un jeton de déclenchement de pipeline et en l'utilisant pour authentifier un appel API. Le jeton emprunte l'identité des accès et des permissions d'un utilisateur au projet.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

Pour créer un jeton de déclenchement :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Jetons de déclenchement de pipeline**.
1. Sélectionnez **Ajouter un jeton**
1. Saisissez une description et sélectionnez **Créer un jeton de déclenchement de pipeline**.
   - Vous pouvez afficher et copier le jeton complet pour tous les déclencheurs que vous avez créés.
   - Vous ne pouvez voir que les 4 premiers caractères des jetons créés par d'autres membres du projet.

> [!warning]
> Il est risqué pour la sécurité d'enregistrer des jetons en texte brut dans des projets publics, ou de les stocker d'une manière qui permettrait à des utilisateurs malveillants d'y accéder. Un jeton de déclenchement compromis pourrait être utilisé pour forcer un déploiement non planifié, tenter d'accéder aux variables CI/CD, ou à d'autres fins malveillantes. Les [variables CI/CD masquées](../variables/_index.md#mask-a-cicd-variable) contribuent à améliorer la sécurité des jetons de déclenchement. Pour plus d'informations sur la sécurisation des jetons, consultez les [considérations de sécurité](../../security/tokens/_index.md#security-considerations).

## Déclencher un pipeline {#trigger-a-pipeline}

Après avoir [créé un jeton de déclenchement de pipeline](#create-a-pipeline-trigger-token), vous pouvez l'utiliser pour déclencher des pipelines avec un outil pouvant accéder à l'API, ou un webhook.

### Utiliser cURL {#use-curl}

Vous pouvez utiliser cURL pour déclencher des pipelines avec le [point de terminaison de l'API des déclencheurs de pipeline](../../api/pipeline_triggers.md). Par exemple :

- Utiliser une commande cURL multiligne :

  ```shell
  curl --request POST \
       --form token=<token> \
       --form ref=<ref_name> \
       "https://gitlab.example.com/api/v4/projects/<project_id>/trigger/pipeline"
  ```

- Utiliser cURL et passer `<token>` et `<ref_name>` dans la chaîne de requête :

  ```shell
  curl --request POST \
       "https://gitlab.example.com/api/v4/projects/<project_id>/trigger/pipeline?token=<token>&ref=<ref_name>"
  ```

Dans chaque exemple, remplacez :

- L'URL par `https://gitlab.com` ou l'URL de votre instance.
- `<token>` par votre jeton de déclenchement.
- `<ref_name>` par un nom de branche ou de tag, comme `main`.
- `<project_id>` par l'ID de votre projet, comme `123456`. L'ID du projet est affiché sur la [page d'aperçu du projet](../../user/project/working_with_projects.md#find-the-project-id).

### Utiliser un job CI/CD {#use-a-cicd-job}

Vous pouvez utiliser un job CI/CD avec un jeton de déclenchement de pipeline pour déclencher des pipelines lorsqu'un autre pipeline s'exécute.

Par exemple, pour déclencher un pipeline sur la branche `main` de `project-B` lorsqu'un tag est créé dans `project-A`, ajoutez le job suivant au fichier `.gitlab-ci.yml` du projet A :

```yaml
trigger_pipeline:
  stage: deploy
  script:
    - 'curl --fail --request POST --form token=$MY_TRIGGER_TOKEN --form ref=main "${CI_API_V4_URL}/projects/123456/trigger/pipeline"'
  rules:
    - if: $CI_COMMIT_TAG
  environment: production
```

Dans cet exemple :

- `1234` est l'ID du projet pour `project-B`. L'ID du projet est affiché sur la [page d'aperçu du projet](../../user/project/working_with_projects.md#find-the-project-id).
- Les [`rules`](../yaml/_index.md#rules) font en sorte que le job s'exécute chaque fois qu'un tag est ajouté à `project-A`.
- `MY_TRIGGER_TOKEN` est une [variable CI/CD masquée](../variables/_index.md#mask-a-cicd-variable) qui contient le jeton de déclenchement.

### Utiliser un webhook {#use-a-webhook}

Pour déclencher un pipeline depuis le webhook d'un autre projet, utilisez une URL de webhook comme la suivante pour les événements push et tag :

```plaintext
https://gitlab.example.com/api/v4/projects/<project_id>/ref/<ref_name>/trigger/pipeline?token=<token>
```

Remplacez :

- L'URL par `https://gitlab.com` ou l'URL de votre instance.
- `<project_id>` par l'ID de votre projet, comme `123456`. L'ID du projet est affiché sur la [page d'aperçu du projet](../../user/project/working_with_projects.md#find-the-project-id).
- `<ref_name>` par un nom de branche ou de tag, comme `main`. Cette valeur est prioritaire sur `ref_name` dans la charge utile du webhook. Le `ref` de la charge utile est la branche qui a déclenché le déclencheur dans le dépôt source. Vous devez encoder en URL le `ref_name` s'il contient des barres obliques.
- `<token>` par votre jeton de déclenchement de pipeline.

#### Accéder à la charge utile du webhook {#access-webhook-payload}

Si vous déclenchez un pipeline en utilisant un webhook, vous pouvez accéder à la charge utile du webhook avec la [variable CI/CD prédéfinie](../variables/predefined_variables.md) `TRIGGER_PAYLOAD`. la charge utile est exposé comme une [variable de type fichier](../variables/_index.md#use-file-type-cicd-variables), vous pouvez donc accéder aux données avec `cat $TRIGGER_PAYLOAD` ou une commande similaire.

### Passer des variables CI/CD dans l'appel API {#pass-cicd-variables-in-the-api-call}

Vous pouvez passer un nombre illimité de [variables CI/CD](../variables/_index.md) dans l'appel API de déclenchement, bien que [l'utilisation des entrées pour contrôler le comportement du pipeline](#pass-pipeline-inputs-in-the-api-call) offre une sécurité et une flexibilité améliorées par rapport aux variables CI/CD.

Ces variables ont la [priorité la plus élevée](../variables/_index.md#cicd-variable-precedence) et remplacent toutes les variables portant le même nom.

Le paramètre est de la forme `variables[key]=value`, par exemple :

```shell
curl --request POST \
     --form token=TOKEN \
     --form ref=main \
     --form "variables[UPLOAD_TO_S3]=true" \
     "https://gitlab.example.com/api/v4/projects/123456/trigger/pipeline"
```

Les variables CI/CD dans les pipelines déclenchés s'affichent sur la page de chaque job, mais seuls les utilisateurs avec le rôle Owner et Maintainer peuvent en voir les valeurs.

![Panneau de configuration d'un déclencheur CI pour le jeton 4e19 affichant UPLOAD_TO_CI défini à true](img/trigger_variables_v11_6.png)

L'utilisation des entrées pour contrôler le comportement du pipeline offre une sécurité et une flexibilité améliorées par rapport aux variables CI/CD.

### Passer des entrées de pipeline dans l'appel API {#pass-pipeline-inputs-in-the-api-call}

Vous pouvez passer des entrées de pipeline dans l'appel API de déclenchement. Les [entrées](../inputs/_index.md) fournissent un moyen structuré de paramétrer vos pipelines avec une validation et une documentation intégrées.

Le format du paramètre est `inputs[name]=value`, par exemple :

```shell
curl --request POST \
     --form token=TOKEN \
     --form ref=main \
     --form "inputs[environment]=production" \
     "https://gitlab.example.com/api/v4/projects/123456/trigger/pipeline"
```

Les valeurs d'entrée sont validées selon le type et les contraintes définis dans la section `spec:inputs` de votre pipeline :

```yaml
spec:
  inputs:
    environment:
      type: string
      description: "Deployment environment"
      options: [dev, staging, production]
      default: dev
```

## Révoquer un jeton de déclenchement de pipeline {#revoke-a-pipeline-trigger-token}

Pour révoquer un jeton de déclenchement de pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Déclencheurs de pipeline**.
1. À gauche du jeton de déclenchement que vous souhaitez révoquer, sélectionnez **Révoquer** ({{< icon name="remove" >}}).

Un jeton de déclenchement révoqué ne peut pas être réajouté.

## Configurer les jobs CI/CD pour s'exécuter dans les pipelines déclenchés {#configure-cicd-jobs-to-run-in-triggered-pipelines}

Pour [configurer le moment d'exécution des jobs](../jobs/job_control.md) dans les pipelines déclenchés, vous pouvez :

- Utiliser [`rules`](../yaml/_index.md#rules) avec la [variable CI/CD prédéfinie](../variables/predefined_variables.md) `$CI_PIPELINE_SOURCE`.
- Utiliser les mots-clés [`only`/`except`](../yaml/deprecated_keywords.md#onlyrefs--exceptrefs), bien que `rules` soit le mot-clé recommandé.

| Valeur `$CI_PIPELINE_SOURCE` | Mots-clés `only`/`except` | Méthode de déclenchement      |
|-----------------------------|--------------------------|---------------------|
| `trigger`                   | `triggers`               | Dans les pipelines déclenchés avec l'[API des déclencheurs de pipeline](../../api/pipeline_triggers.md) en utilisant un [jeton de déclenchement](#create-a-pipeline-trigger-token). |
| `pipeline`                  | `pipelines`              | Dans les [pipelines multi-projets](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api) déclenchés avec l'[API des déclencheurs de pipeline](../../api/pipeline_triggers.md) en utilisant le [`$CI_JOB_TOKEN`](../jobs/ci_job_token.md), ou en utilisant le mot-clé [`trigger`](../yaml/_index.md#trigger) dans le fichier de configuration CI/CD. |

De plus, la variable CI/CD prédéfinie `$CI_PIPELINE_TRIGGERED` est définie à `true` dans les pipelines déclenchés avec un jeton de déclenchement de pipeline.

## Identifier le jeton de déclenchement de pipeline utilisé {#see-which-pipeline-trigger-token-was-used}

Vous pouvez identifier quel jeton de déclenchement de pipeline a provoqué l'exécution d'un job en consultant la page du job individuel. Une partie du jeton de déclenchement s'affiche dans la barre latérale droite, sous **Détails du job**.

Dans les pipelines déclenchés avec un jeton de déclenchement, les jobs sont étiquetés comme `triggered` dans **Version** > **Jobs**.

## Dépannage {#troubleshooting}

### `403 Forbidden` lors du déclenchement d'un pipeline avec un webhook {#403-forbidden-when-you-trigger-a-pipeline-with-a-webhook}

Lorsque vous déclenchez un pipeline avec un webhook, l'API peut renvoyer une réponse `{"message":"403 Forbidden"}`. Pour éviter les boucles de déclenchement, n'utilisez pas les [événements de pipeline](../../user/project/integrations/webhook_events.md#pipeline-events) pour déclencher des pipelines.

### `404 Not Found` lors du déclenchement d'un pipeline {#404-not-found-when-triggering-a-pipeline}

Une réponse `{"message":"404 Not Found"}` lors du déclenchement d'un pipeline peut être causée par l'utilisation d'un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md) à la place d'un jeton de déclenchement de pipeline. [Créez un nouveau jeton de déclenchement](#create-a-pipeline-trigger-token) et utilisez-le à la place du jeton d'accès personnel.

Une réponse `{"message":"404 Not Found"}` lors du déclenchement d'un pipeline peut également être causée par l'utilisation d'une requête `GET`. Les pipelines ne peuvent être déclenchés qu'à l'aide d'une requête `POST`.

### `The requested URL returned error: 400` lors du déclenchement d'un pipeline {#the-requested-url-returned-error-400-when-triggering-a-pipeline}

Si vous tentez de déclencher un pipeline en utilisant un `ref` correspondant à un nom de branche qui n'existe pas, GitLab renvoie `The requested URL returned error: 400`.

Par exemple, vous pourriez utiliser accidentellement `main` comme nom de branche dans un projet qui utilise un nom de branche différent pour sa branche par défaut.

Une autre cause possible de cette erreur est une règle qui empêche la création de pipelines lorsque la valeur de `CI_PIPELINE_SOURCE` est `trigger`, par exemple :

```yaml
rules:
  - if: $CI_PIPELINE_SOURCE == "trigger"
    when: never
```

Vérifiez [`workflow:rules`](../yaml/_index.md#workflowrules) pour vous assurer qu'un pipeline peut être créé lorsque la valeur de `CI_PIPELINE_SOURCE` est `trigger`.

---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Déclencher et gérer des pipelines parent-enfant et multi-projets.
title: Pipelines downstream
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Un pipeline downstream est tout pipeline CI/CD GitLab déclenché par un autre pipeline. Les pipelines downstream s'exécutent indépendamment et simultanément par rapport au pipeline upstream qui les a déclenchés.

- Un [pipeline parent-enfant](downstream_pipelines.md#parent-child-pipelines) est un pipeline downstream déclenché dans le même projet que le premier pipeline.
- Un [pipeline multi-projets](#multi-project-pipelines) est un pipeline downstream déclenché dans un projet différent du premier pipeline.

Vous pouvez parfois utiliser des pipelines parent-enfant et des pipelines multi-projets à des fins similaires, mais il existe des [différences clés](pipeline_architectures.md).

Une hiérarchie de pipelines peut contenir jusqu'à 1000 pipelines downstream par défaut. Pour plus d'informations sur cette limite et comment la modifier, consultez [Limiter la taille de la hiérarchie de pipelines](../../administration/cicd/limits.md#limit-pipeline-hierarchy-size).

## Pipelines parent-enfant {#parent-child-pipelines}

Un pipeline parent est un pipeline qui déclenche un pipeline downstream dans le même projet. Le pipeline downstream est appelé pipeline enfant.

Les pipelines enfants :

- S'exécutent sous le même projet, la même référence et le même SHA de commit que le pipeline parent.
- N'affectent pas directement le statut global de la référence sur laquelle le pipeline s'exécute. Par exemple, si un pipeline échoue pour la branche main, on dit généralement que « main est cassé ». Le statut des pipelines enfants n'affecte le statut de la référence que si le pipeline enfant est déclenché avec [`trigger:strategy`](../yaml/_index.md#triggerstrategy).
- Sont automatiquement annulés si le pipeline est configuré avec [`interruptible`](../yaml/_index.md#interruptible) lorsqu'un nouveau pipeline est créé pour la même référence.
- Ne s'affichent pas dans la liste des pipelines du projet. Vous pouvez uniquement consulter les pipelines enfants sur la page de détails de leur pipeline parent.

### Pipelines enfants imbriqués {#nested-child-pipelines}

Les pipelines parent et enfants ont une profondeur maximale de deux niveaux de pipelines enfants.

Un pipeline parent peut déclencher de nombreux pipelines enfants, et ces pipelines enfants peuvent déclencher leurs propres pipelines enfants. Vous ne pouvez pas déclencher un autre niveau de pipelines enfants.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, consultez [Nested Dynamic Pipelines](https://youtu.be/C5j3ju9je2M).

## Pipelines multi-projets {#multi-project-pipelines}

Un pipeline dans un projet peut déclencher des pipelines downstream dans un autre projet, appelés pipelines multi-projets. L'utilisateur déclenchant le pipeline upstream doit être en mesure de démarrer des pipelines dans le projet downstream, sinon [le pipeline downstream ne parvient pas à démarrer](downstream_pipelines_troubleshooting.md#trigger-job-fails-and-does-not-create-multi-project-pipeline).

Les pipelines multi-projets :

- Sont déclenchés depuis le pipeline d'un autre projet, mais le pipeline upstream (déclencheur) n'a pas beaucoup de contrôle sur le pipeline downstream (déclenché). Toutefois, il peut choisir la référence du pipeline downstream et lui transmettre des variables CI/CD.
- Affectent le statut global de la référence du projet dans lequel ils s'exécutent, mais n'affectent pas le statut de la référence du pipeline déclencheur, sauf s'il a été déclenché avec [`trigger:strategy`](../yaml/_index.md#triggerstrategy).
- Ne sont pas automatiquement annulés dans le projet downstream lors de l'utilisation de [`interruptible`](../yaml/_index.md#interruptible) si un nouveau pipeline s'exécute pour la même référence dans le pipeline upstream. Ils peuvent être automatiquement annulés si un nouveau pipeline est déclenché pour la même référence dans le projet downstream.
- Sont visibles dans la liste des pipelines du projet downstream.
- Sont indépendants, il n'y a donc pas de limites d'imbrication.

Si vous utilisez un projet public pour déclencher des pipelines downstream dans un projet privé, assurez-vous qu'il n'y a pas de problèmes de confidentialité. La page des pipelines du projet upstream affiche toujours :

- Le nom du projet downstream.
- Le statut du pipeline.

## Déclencher un pipeline downstream depuis un job dans le fichier `.gitlab-ci.yml` {#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file}

Utilisez le mot-clé [`trigger`](../yaml/_index.md#trigger) dans votre fichier `.gitlab-ci.yml` pour créer un job qui déclenche un pipeline downstream. Ce job est appelé un job de déclenchement.

Par exemple :

{{< tabs >}}

{{< tab title="Pipeline parent-enfant" >}}

```yaml
trigger_job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

{{< /tab >}}

{{< tab title="Pipeline multi-projets" >}}

```yaml
trigger_job:
  trigger:
    project: project-group/my-downstream-project
```

{{< /tab >}}

{{< /tabs >}}

Après le démarrage du job de déclenchement, le statut initial du job est `pending` pendant que GitLab tente de créer le pipeline downstream. Le job de déclenchement affiche `passed` si le pipeline downstream est créé avec succès, sinon il affiche `failed`. Vous pouvez également [configurer le job de déclenchement pour afficher le statut du pipeline downstream](#mirror-the-status-of-a-downstream-pipeline-in-the-trigger-job) à la place.

### Utiliser `rules` pour contrôler les jobs des pipelines downstream {#use-rules-to-control-downstream-pipeline-jobs}

Utilisez des variables CI/CD ou le mot-clé [`rules`](../yaml/_index.md#rulesif) pour [contrôler le comportement des jobs](../jobs/job_control.md) dans les pipelines downstream.

Lorsque vous déclenchez un pipeline downstream avec le mot-clé [`trigger`](../yaml/_index.md#trigger), la valeur de la [variable prédéfinie `$CI_PIPELINE_SOURCE`](../variables/predefined_variables.md) pour tous les jobs est :

- `pipeline` pour les pipelines multi-projets.
- `parent_pipeline` pour les pipelines parent-enfant.

Par exemple, pour contrôler les jobs dans des pipelines multi-projets dans un projet qui exécute également des pipelines de merge request :

```yaml
job1:
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"
  script: echo "This job runs in multi-project pipelines only"

job2:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script: echo "This job runs in merge request pipelines only"

job3:
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script: echo "This job runs in both multi-project and merge request pipelines"
```

### Utiliser un fichier de configuration de pipeline enfant dans un projet différent {#use-a-child-pipeline-configuration-file-in-a-different-project}

Vous pouvez utiliser [`include:project`](../yaml/_index.md#includeproject) dans un job de déclenchement pour déclencher des pipelines enfants avec un fichier de configuration dans un projet différent :

```yaml
microservice_a:
  trigger:
    include:
      - project: 'my-group/my-pipeline-library'
        ref: 'main'
        file: '/path/to/child-pipeline.yml'
```

### Combiner plusieurs fichiers de configuration de pipeline enfant {#combine-multiple-child-pipeline-configuration-files}

Vous pouvez inclure jusqu'à trois fichiers de configuration lors de la définition d'un pipeline enfant. La configuration du pipeline enfant est composée de tous les fichiers de configuration fusionnés ensemble :

```yaml
microservice_a:
  trigger:
    include:
      - local: path/to/microservice_a.yml
      - template: Jobs/SAST.gitlab-ci.yml
      - project: 'my-group/my-pipeline-library'
        ref: 'main'
        file: '/path/to/child-pipeline.yml'
```

### Pipelines enfants dynamiques {#dynamic-child-pipelines}

Vous pouvez déclencher un pipeline enfant depuis un fichier YAML généré dans un job, au lieu d'un fichier statique enregistré dans votre projet. Cette technique peut être très puissante pour générer des pipelines ciblant du contenu modifié ou pour construire une matrice de cibles et d'architectures.

L'artefact contenant le fichier YAML généré doit être dans les [limites de l'instance](../../administration/cicd/limits.md#maximum-size-of-the-ci-artifacts-archive).

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, consultez [Create child pipelines using dynamically generated configurations](https://youtu.be/nMdfus2JWHM).

Pour un exemple de projet qui génère un pipeline enfant dynamique, consultez [Dynamic Child Pipelines with Jsonnet](https://gitlab.com/gitlab-org/project-templates/jsonnet). Ce projet montre comment utiliser un langage de modélisation de données pour générer votre `.gitlab-ci.yml` au moment de l'exécution. Vous pouvez utiliser un processus similaire pour d'autres langages de modélisation comme [Dhall](https://dhall-lang.org/) ou [ytt](https://get-ytt.io/).

#### Déclencher un pipeline enfant dynamique {#trigger-a-dynamic-child-pipeline}

Pour déclencher un pipeline enfant depuis un fichier de configuration généré dynamiquement :

1. Générez le fichier de configuration dans un job et enregistrez-le en tant qu'[artefact](../yaml/_index.md#artifactspaths) :

   ```yaml
   generate-config:
     stage: build
     script: generate-ci-config > generated-config.yml
     artifacts:
       paths:
         - generated-config.yml
   ```

1. Configurez le job de déclenchement pour s'exécuter après le job qui a généré le fichier de configuration. Définissez `include: artifact` sur l'artefact généré, et définissez `include: job` sur le job qui a créé l'artefact :

   ```yaml
   child-pipeline:
     stage: test
     trigger:
       include:
         - artifact: generated-config.yml
           job: generate-config
   ```

Dans cet exemple, GitLab récupère `generated-config.yml` et déclenche un pipeline enfant avec la configuration CI/CD contenue dans ce fichier.

Le chemin de l'artefact est analysé par GitLab, et non par le runner, donc le chemin doit correspondre à la syntaxe du système d'exploitation exécutant GitLab. Si GitLab s'exécute sur Linux mais utilise un runner Windows pour les tests, le séparateur de chemin pour le job de déclenchement est `/`. Les autres configurations CI/CD pour les jobs qui utilisent le runner Windows, comme les scripts, utilisent ` \ `.

Vous ne pouvez pas utiliser des variables CI/CD dans une section `include` dans la configuration d'un pipeline enfant dynamique.

### Exécuter des pipelines enfants avec des pipelines de merge request {#run-child-pipelines-with-merge-request-pipelines}

Les pipelines, y compris les pipelines enfants, s'exécutent en tant que pipelines de branche par défaut lorsqu'ils n'utilisent pas [`rules`](../yaml/_index.md#rules) ou [`workflow:rules`](../yaml/_index.md#workflowrules). Pour configurer les pipelines enfants à s'exécuter lorsqu'ils sont déclenchés depuis un [pipeline de merge request (parent)](merge_request_pipelines.md), utilisez `rules` ou `workflow:rules`. Par exemple, en utilisant `rules` :

1. Définissez le job de déclenchement du pipeline parent pour s'exécuter sur les merge requests :

   ```yaml
   trigger-child-pipeline-job:
     trigger:
       include: path/to/child-pipeline-configuration.yml
     rules:
       - if: $CI_PIPELINE_SOURCE == "merge_request_event"
   ```

1. Utilisez `rules` pour configurer les jobs du pipeline enfant à s'exécuter lorsqu'ils sont déclenchés par le pipeline parent :

   ```yaml
   job1:
     script: echo "This child pipeline job runs any time the parent pipeline triggers it."
     rules:
       - if: $CI_PIPELINE_SOURCE == "parent_pipeline"

   job2:
     script: echo "This child pipeline job runs only when the parent pipeline is a merge request pipeline"
     rules:
       - if: $CI_MERGE_REQUEST_ID
   ```

Dans les pipelines enfants, `$CI_PIPELINE_SOURCE` a toujours une valeur de `parent_pipeline`, donc :

- Vous pouvez utiliser `if: $CI_PIPELINE_SOURCE == "parent_pipeline"` pour vous assurer que les jobs du pipeline enfant s'exécutent toujours.
- Vous ne pouvez pas utiliser `if: $CI_PIPELINE_SOURCE == "merge_request_event"` pour configurer les jobs du pipeline enfant à s'exécuter pour les pipelines de merge request. Utilisez plutôt `if: $CI_MERGE_REQUEST_ID` pour configurer les jobs du pipeline enfant à s'exécuter uniquement lorsque le pipeline parent est un pipeline de merge request. Les [variables prédéfinies `CI_MERGE_REQUEST_*`](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines) du pipeline parent sont transmises aux jobs du pipeline enfant.

### Spécifier une branche pour les pipelines multi-projets {#specify-a-branch-for-multi-project-pipelines}

Vous pouvez spécifier la branche à utiliser lors du déclenchement d'un pipeline multi-projets. GitLab utilise le commit en tête de la branche pour créer le pipeline downstream. Par exemple :

```yaml
staging:
  stage: deploy
  trigger:
    project: my/deployment
    branch: stable-11-2
```

Utilisez :

- Le mot-clé `project` pour spécifier le chemin complet vers le projet downstream. Vous pouvez utiliser l'[expansion de variables](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).
- Le mot-clé `branch` pour spécifier le nom d'une branche ou d'un [tag](../../user/project/repository/tags/_index.md) dans le projet spécifié par `project`. Vous pouvez utiliser l'expansion de variables.

## Déclencher un pipeline multi-projets en utilisant l'API {#trigger-a-multi-project-pipeline-by-using-the-api}

Vous pouvez utiliser le [jeton de job CI/CD (`CI_JOB_TOKEN`)](../jobs/ci_job_token.md) avec le [point de terminaison de l'API des jetons de déclenchement de pipeline](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token) pour déclencher des pipelines multi-projets depuis l'intérieur d'un job CI/CD. GitLab définit les pipelines déclenchés avec un jeton de job en tant que pipelines downstream du pipeline qui contient le job ayant effectué l'appel API.

Par exemple :

```yaml
trigger_pipeline:
  stage: deploy
  script:
    - |
      curl --request POST \
        --form "token=$CI_JOB_TOKEN" \
        --form ref=main \
        --url "https://gitlab.example.com/api/v4/projects/9/trigger/pipeline"
  rules:
    - if: $CI_COMMIT_TAG
  environment: production
```

## Consulter un pipeline downstream {#view-a-downstream-pipeline}

Sur la [page de détails du pipeline](_index.md#pipeline-details), les pipelines downstream s'affichent sous forme de liste de cartes à droite du graphe. Depuis cette vue, vous pouvez :

- Sélectionner un job de déclenchement pour voir les jobs du pipeline downstream déclenché.
- Sélectionner **Étendre les jobs** {{< icon name="chevron-lg-right" >}} sur une carte de pipeline pour développer la vue avec les jobs du pipeline downstream. Vous pouvez consulter un pipeline downstream à la fois.
- Survolez une carte de pipeline pour mettre en évidence le job qui a déclenché le pipeline downstream.

### Réessayer les jobs échoués et annulés dans un pipeline downstream {#retry-failed-and-canceled-jobs-in-a-downstream-pipeline}

Pour réessayer les jobs échoués et annulés, sélectionnez **Réessayer** ({{< icon name="retry" >}}) :

- Depuis la page de détails du pipeline downstream.
- Sur la carte du pipeline dans la vue du graphe de pipeline.

### Recréer un pipeline downstream {#recreate-a-downstream-pipeline}

Vous pouvez recréer un pipeline downstream en réessayant son job de déclenchement correspondant. Le pipeline downstream nouvellement créé remplace le pipeline downstream actuel dans le graphe de pipeline.

Pour recréer un pipeline downstream :

- Sélectionnez **Réexécuter** ({{< icon name="retry" >}}) sur la carte du job de déclenchement dans la vue du graphe de pipeline.

### Annuler un pipeline downstream {#cancel-a-downstream-pipeline}

Pour annuler un pipeline downstream encore en cours d'exécution, sélectionnez **Annuler** ({{< icon name="cancel" >}}) :

- Depuis la page de détails du pipeline downstream.
- Sur la carte du pipeline dans la vue du graphe de pipeline.

### Annuler automatiquement le pipeline parent depuis un pipeline downstream {#auto-cancel-the-parent-pipeline-from-a-downstream-pipeline}

Vous pouvez configurer un pipeline enfant pour [s'annuler automatiquement](../yaml/_index.md#workflowauto_cancelon_job_failure) dès qu'un de ses jobs échoue.

Le pipeline parent ne s'annule automatiquement que lorsqu'un job du pipeline enfant échoue si :

- Le pipeline parent est également configuré pour s'annuler automatiquement en cas d'échec de job.
- Le job de déclenchement est configuré avec [`strategy: mirror`](../yaml/_index.md#triggerstrategy).

Par exemple :

- Contenu de `.gitlab-ci.yml` :

  ```yaml
  workflow:
    auto_cancel:
      on_job_failure: all

  trigger_job:
    trigger:
      include: child-pipeline.yml
      strategy: mirror

  job3:
    script:
      - sleep 120
  ```

- Contenu de `child-pipeline.yml`

  ```yaml
  # Contents of child-pipeline.yml
  workflow:
    auto_cancel:
      on_job_failure: all

  job1:
    script: sleep 60

  job2:
    script:
      - sleep 30
      - exit 1
  ```

Dans cet exemple :

1. Le pipeline parent déclenche le pipeline enfant et `job3` en même temps
1. `job2` du pipeline enfant échoue et le pipeline enfant est annulé, arrêtant également `job1`
1. Le pipeline enfant a été annulé, donc le pipeline parent est annulé automatiquement

### Refléter le statut d'un pipeline downstream dans le job de déclenchement {#mirror-the-status-of-a-downstream-pipeline-in-the-trigger-job}

Vous pouvez refléter le statut du pipeline downstream dans le job de déclenchement en utilisant [`trigger: strategy`](../yaml/_index.md#triggerstrategy) :

Avec `strategy: mirror`, le job de déclenchement a toujours le même statut que le pipeline downstream.

{{< tabs >}}

{{< tab title="Pipeline parent-enfant" >}}

```yaml
trigger_job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
    strategy: mirror
```

{{< /tab >}}

{{< tab title="Pipeline multi-projets" >}}

```yaml
trigger_job:
  trigger:
    project: my/project
    strategy: mirror
```

{{< /tab >}}

{{< /tabs >}}

`strategy: depend` n'est pas recommandé, car le statut du job de déclenchement ne correspond pas toujours au statut du pipeline downstream. Consultez les [informations complémentaires dans la référence `trigger:strategy`](../yaml/_index.md#triggerstrategy).

### Consulter les pipelines multi-projets dans les graphes de pipeline {#view-multi-project-pipelines-in-pipeline-graphs}

{{< history >}}

- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/422282) de GitLab Premium vers GitLab Free dans la version 16.8.

{{< /history >}}

Après avoir déclenché un pipeline multi-projets, le pipeline downstream s'affiche à droite du [graphe de pipeline](_index.md#view-pipelines).

Dans les [mini-graphes de pipeline](_index.md#pipeline-mini-graphs), le pipeline downstream s'affiche à droite du mini-graphe.

## Consulter les rapports de pipelines enfants dans les merge requests {#view-child-pipeline-reports-in-merge-requests}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/18311) dans GitLab 18.6.
- Les rapports de sécurité des pipelines enfants [introduits](https://gitlab.com/groups/gitlab-org/-/work_items/18377) dans GitLab 18.9.

{{< /history >}}

Vous pouvez consulter et télécharger des rapports de pipelines enfants dans les widgets de merge request. Cela fournit une vue unifiée des résultats de tests et des contrôles de qualité dans toute votre hiérarchie de pipelines, sans avoir à naviguer manuellement à travers plusieurs pipelines pour identifier les échecs et les vulnérabilités.

Les types de rapports suivants des pipelines enfants sont pris en charge :

- Rapports de tests unitaires (JUnit)
- Rapports de qualité du code
- Rapports Terraform
- Rapports de métriques
- Rapports de sécurité (SAST, détection des secrets, analyse des dépendances, analyse des conteneurs, DAST, fuzzing d'API)

Les rapports de sécurité fonctionnent avec les pipelines enfants du même projet, les pipelines enfants générés dynamiquement et les pipelines créés par des politiques d'exécution de pipeline. Les rapports provenant des [politiques d'exécution d'analyse](../../user/application_security/policies/scan_execution_policies.md) ne sont pas pris en charge.

Les résultats de tests et les [résultats de sécurité](../../user/application_security/detect/security_scanning_results.md) des pipelines enfants apparaissent également dans les onglets **Tests** et **Sécurité** du pipeline parent.

Les résultats de sécurité des pipelines enfants peuvent déclencher des [politiques d'approbation de merge request](../../user/application_security/policies/merge_request_approval_policies.md). Si un pipeline enfant détecte des vulnérabilités, vous pourriez avoir besoin d'approbations supplémentaires avant de pouvoir fusionner.

Pour vous assurer que les rapports des pipelines enfants apparaissent dans les widgets de merge request, utilisez [`strategy: depend`](../yaml/_index.md#triggerstrategy) ou [`strategy: mirror`](../yaml/_index.md#triggerstrategy) pour les pipelines enfants qui génèrent des rapports d'artefacts. Par exemple :

```yaml
test-backend:
  trigger:
    include: backend-tests.yml
    strategy: depend

test-frontend:
  trigger:
    include: frontend-tests.yml
    strategy: depend
```

Sans ces stratégies, le pipeline parent se termine avant que les pipelines enfants ne soient terminés, et leurs rapports n'apparaissent pas dans la merge request.

## Récupérer des artefacts depuis un pipeline upstream {#fetch-artifacts-from-an-upstream-pipeline}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< tabs >}}

{{< tab title="Pipeline parent-enfant" >}}

Utilisez [`needs:pipeline:job`](../yaml/_index.md#needspipelinejob) pour récupérer des artefacts depuis un pipeline upstream :

1. Dans le pipeline upstream, enregistrez les artefacts dans un job avec le mot-clé [`artifacts`](../yaml/_index.md#artifacts), puis déclenchez le pipeline downstream avec un job de déclenchement :

   ```yaml
   build_artifacts:
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   deploy:
     stage: deploy
     trigger:
       include:
         - local: path/to/child-pipeline.yml
     variables:
       PARENT_PIPELINE_ID: $CI_PIPELINE_ID
   ```

1. Utilisez `needs:pipeline:job` dans un job du pipeline downstream pour récupérer les artefacts d'un job réussi.

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - pipeline: $PARENT_PIPELINE_ID
         job: build_artifacts
   ```

   Définissez `job` sur le job dans le pipeline upstream qui a créé les artefacts.

{{< /tab >}}

{{< tab title="Pipeline multi-projets" >}}

Utilisez [`needs:project`](../yaml/_index.md#needsproject) pour récupérer des artefacts depuis un pipeline upstream :

1. [Ajoutez le projet downstream à la liste d'autorisation de la portée du jeton de job](../jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) du projet upstream.
1. Dans le pipeline upstream, enregistrez les artefacts dans un job avec le mot-clé [`artifacts`](../yaml/_index.md#artifacts), puis déclenchez le pipeline downstream avec un job de déclenchement :

   ```yaml
   build_artifacts:
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   deploy:
     stage: deploy
     trigger: my/downstream_project   # Path to the project to trigger a pipeline in
   ```

1. Utilisez `needs:project` dans un job du pipeline downstream pour récupérer les artefacts d'un job réussi.

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - project: my/upstream_project
         job: build_artifacts
         ref: main
         artifacts: true
   ```

   Définissez :

   - `job` sur le job dans le pipeline upstream qui a créé les artefacts.
   - `ref` sur la branche.
   - `artifacts` sur `true`.

{{< /tab >}}

{{< /tabs >}}

> [!warning]
> Assurez-vous que le job upstream se termine avant que le job downstream ne commence, sinon vous ne pourrez pas récupérer les artefacts. Utilisez [`needs`](../yaml/_index.md#needs) pour que le job downstream attende le job upstream.
>
> Pour plus d'informations, consultez le [ticket 356016](https://gitlab.com/gitlab-org/gitlab/-/issues/356016).

### Récupérer des artefacts depuis un pipeline de merge request upstream {#fetch-artifacts-from-an-upstream-merge-request-pipeline}

Lorsque vous utilisez `needs:project` pour [transmettre des artefacts à un pipeline downstream](#fetch-artifacts-from-an-upstream-pipeline), la valeur de `ref` est généralement un nom de branche, comme `main` ou `development`.

Pour les [pipelines de merge request](merge_request_pipelines.md), la valeur de `ref` est de la forme `refs/merge-requests/<id>/head`, où `id` est l'ID de la merge request. Vous pouvez récupérer cette référence avec la variable CI/CD [`CI_MERGE_REQUEST_REF_PATH`](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines). N'utilisez pas un nom de branche comme `ref` avec des pipelines de merge request, car le pipeline downstream tente de récupérer les artefacts depuis le dernier pipeline de branche.

Pour récupérer les artefacts depuis le pipeline `merge request` upstream au lieu du pipeline `branch`, transmettez `CI_MERGE_REQUEST_REF_PATH` au pipeline downstream en utilisant l'[héritage de variables](#pass-yaml-defined-cicd-variables) :

1. [Ajoutez le projet downstream à la liste d'autorisation de la portée du jeton de job](../jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) du projet upstream.
1. Dans un job du pipeline upstream, enregistrez les artefacts en utilisant le mot-clé [`artifacts`](../yaml/_index.md#artifacts).
1. Dans le job qui déclenche le pipeline downstream, transmettez la variable `$CI_MERGE_REQUEST_REF_PATH` :

   ```yaml
   build_artifacts:
     rules:
       - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   upstream_job:
     rules:
       - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
     variables:
       UPSTREAM_REF: $CI_MERGE_REQUEST_REF_PATH
     trigger:
       project: my/downstream_project
       branch: my-branch
   ```

1. Dans un job du pipeline downstream, récupérez les artefacts depuis le pipeline upstream en utilisant `needs:project` et la variable transmise comme valeur de `ref` :

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - project: my/upstream_project
         job: build_artifacts
         ref: $UPSTREAM_REF
         artifacts: true
   ```

Vous pouvez utiliser cette méthode pour récupérer des artefacts depuis des pipelines de merge request upstream, mais pas depuis des [pipelines de résultats fusionnés](merged_results_pipelines.md).

## Transmettre des inputs à un pipeline downstream {#pass-inputs-to-a-downstream-pipeline}

Vous pouvez utiliser le mot-clé [`inputs`](../inputs/_index.md) pour transmettre des valeurs d'input à des pipelines downstream. Les inputs offrent des avantages par rapport aux variables, notamment la vérification de type, la validation via des options, des descriptions et des valeurs par défaut.

Commencez par définir les paramètres d'input dans le fichier de configuration cible en utilisant `spec:inputs` :

```yaml
# Target pipeline configuration
spec:
  inputs:
    environment:
      description: "Deployment environment"
      options: [staging, production]
    version:
      type: string
      description: "Application version"
```

Fournissez ensuite les valeurs lors du déclenchement du pipeline :

{{< tabs >}}

{{< tab title="Pipeline parent-enfant" >}}

```yaml
staging:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
        inputs:
          environment: staging
          version: "1.0.0"
```

{{< /tab >}}

{{< tab title="Pipeline multi-projets" >}}

```yaml
staging:
  trigger:
    project: my-group/my-deployment-project
    inputs:
      environment: staging
      version: "1.0.0"
```

{{< /tab >}}

{{< /tabs >}}

## Transmettre des variables CI/CD à un pipeline downstream {#pass-cicd-variables-to-a-downstream-pipeline}

Vous pouvez transmettre des [variables CI/CD](../variables/_index.md) à un pipeline downstream avec quelques méthodes différentes, selon l'endroit où la variable est créée ou définie.

### Transmettre des variables CI/CD définies en YAML {#pass-yaml-defined-cicd-variables}

> [!note]
> Les inputs sont recommandés pour la configuration de pipeline à la place des variables car ils offrent une sécurité et une flexibilité améliorées.

Vous pouvez utiliser le mot-clé `variables` pour transmettre des variables CI/CD à un pipeline downstream. Ces variables sont des variables de pipeline pour la [précédence des variables](../variables/_index.md#cicd-variable-precedence).

Par exemple :

{{< tabs >}}

{{< tab title="Pipeline parent-enfant" >}}

```yaml
variables:
  VERSION: "1.0.0"

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

{{< /tab >}}

{{< tab title="Pipeline multi-projets" >}}

```yaml
variables:
  VERSION: "1.0.0"

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger: my-group/my-deployment-project
```

{{< /tab >}}

{{< /tabs >}}

La variable `ENVIRONMENT` est disponible dans chaque job défini dans le pipeline downstream.

La variable par défaut `VERSION` est également disponible dans le pipeline downstream, car tous les jobs d'un pipeline, y compris les jobs de déclenchement, héritent des [`variables` par défaut](../yaml/_index.md#default-variables).

#### Empêcher la transmission des variables par défaut {#prevent-default-variables-from-being-passed}

Vous pouvez empêcher les variables CI/CD par défaut d'atteindre le pipeline downstream avec [`inherit:variables`](../yaml/_index.md#inheritvariables). Vous pouvez lister des variables spécifiques à hériter ou bloquer toutes les variables par défaut.

Par exemple :

{{< tabs >}}

{{< tab title="Pipeline parent-enfant" >}}

```yaml
variables:
  DEFAULT_VAR: value

trigger-job:
  inherit:
    variables: false
  variables:
    JOB_VAR: value
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

{{< /tab >}}

{{< tab title="Pipeline multi-projets" >}}

```yaml
variables:
  DEFAULT_VAR: value

trigger-job:
  inherit:
    variables: false
  variables:
    JOB_VAR: value
  trigger: my-group/my-project
```

{{< /tab >}}

{{< /tabs >}}

La variable `DEFAULT_VAR` n'est pas disponible dans le pipeline déclenché, mais `JOB_VAR` est disponible.

### Transmettre une variable prédéfinie {#pass-a-predefined-variable}

Pour transmettre des informations sur le pipeline upstream en utilisant des [variables CI/CD prédéfinies](../variables/predefined_variables.md), utilisez l'interpolation. Enregistrez la variable prédéfinie en tant que nouvelle variable de job dans le job de déclenchement, qui est transmise au pipeline downstream. Par exemple :

{{< tabs >}}

{{< tab title="Pipeline parent-enfant" >}}

```yaml
trigger-job:
  variables:
    PARENT_BRANCH: $CI_COMMIT_REF_NAME
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

{{< /tab >}}

{{< tab title="Pipeline multi-projets" >}}

```yaml
trigger-job:
  variables:
    UPSTREAM_BRANCH: $CI_COMMIT_REF_NAME
  trigger: my-group/my-project
```

{{< /tab >}}

{{< /tabs >}}

La variable `UPSTREAM_BRANCH`, qui contient la valeur de la variable CI/CD prédéfinie `$CI_COMMIT_REF_NAME` du pipeline upstream, est disponible dans le pipeline downstream.

N'utilisez pas cette méthode pour transmettre des [variables masquées](../variables/_index.md#mask-a-cicd-variable) à un pipeline multi-projets. La configuration de masquage CI/CD n'est pas transmise au pipeline downstream et la variable pourrait être démasquée dans les job logs du projet downstream.

Vous ne pouvez pas utiliser cette méthode pour transférer des [variables réservées aux jobs](../variables/predefined_variables.md#variable-availability) vers un pipeline downstream, car elles ne sont pas disponibles dans les jobs de déclenchement.

Les pipelines upstream ont la priorité sur les pipelines downstream. S'il existe deux variables portant le même nom définies dans les projets upstream et downstream, celles définies dans le projet upstream ont la priorité.

### Transmettre des variables dotenv créées dans un job {#pass-dotenv-variables-created-in-a-job}

Vous pouvez transmettre des variables à un pipeline downstream avec l'héritage de variables dotenv.

Pour plus d'informations, consultez [transmettre des variables aux pipelines downstream](../variables/dotenv_variables.md#pass-variables-to-downstream-pipelines).

### Contrôler le type de variables à transférer aux pipelines downstream {#control-what-type-of-variables-to-forward-to-downstream-pipelines}

Utilisez le [mot-clé `trigger:forward`](../yaml/_index.md#triggerforward) pour spécifier le type de variables à transférer vers le pipeline downstream. Les variables transférées sont considérées comme des variables de déclenchement, qui ont la [priorité la plus élevée](../variables/_index.md#cicd-variable-precedence).

## Pipelines downstream pour les déploiements {#downstream-pipelines-for-deployments}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/369061) dans GitLab 16.4.

{{< /history >}}

Vous pouvez utiliser le mot-clé [`environment`](../yaml/_index.md#environment) avec [`trigger`](../yaml/_index.md#trigger). Vous pourriez vouloir utiliser `environment` depuis un job de déclenchement si vos projets de déploiement et d'application sont gérés séparément.

```yaml
deploy:
  trigger:
    project: project-group/my-downstream-project
  environment: production
```

Un pipeline downstream peut provisionner de l'infrastructure, déployer vers un environnement désigné et renvoyer le statut de déploiement au projet upstream.

Vous pouvez [consulter l'environnement et le déploiement](../environments/_index.md#view-environments-and-deployments) depuis le projet upstream.

### Exemple avancé {#advanced-example}

Cet exemple de configuration présente les comportements suivants :

- Le projet upstream compose dynamiquement un nom d'environnement basé sur un nom de branche.
- Le projet upstream transmet le contexte du déploiement au projet downstream avec les variables `UPSTREAM_*`.

Le `.gitlab-ci.yml` dans un projet upstream :

```yaml
stages:
  - deploy
  - cleanup

.downstream-deployment-pipeline:
  variables:
    UPSTREAM_PROJECT_ID: $CI_PROJECT_ID
    UPSTREAM_ENVIRONMENT_NAME: $CI_ENVIRONMENT_NAME
    UPSTREAM_ENVIRONMENT_ACTION: $CI_ENVIRONMENT_ACTION
  trigger:
    project: project-group/deployment-project
    branch: main
    strategy: mirror

deploy-review:
  stage: deploy
  extends: .downstream-deployment-pipeline
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    on_stop: stop-review

stop-review:
  stage: cleanup
  extends: .downstream-deployment-pipeline
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

Le `.gitlab-ci.yml` dans un projet downstream :

```yaml
deploy:
  script: echo "Deploy to ${UPSTREAM_ENVIRONMENT_NAME} for ${UPSTREAM_PROJECT_ID}"
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline" && $UPSTREAM_ENVIRONMENT_ACTION == "start"

stop:
  script: echo "Stop ${UPSTREAM_ENVIRONMENT_NAME} for ${UPSTREAM_PROJECT_ID}"
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline" && $UPSTREAM_ENVIRONMENT_ACTION == "stop"
```

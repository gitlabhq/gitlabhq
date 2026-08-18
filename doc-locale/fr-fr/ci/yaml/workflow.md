---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisation du mot-clé `workflow` de GitLab CI/CD pour le contrôle des pipelines, la gestion des règles et la prévention des pipelines en double."
title: 'Mot-clé `workflow`'
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez le mot-clé [`workflow`](_index.md#workflow) dans votre fichier `.gitlab-ci.yml` pour contrôler quand les pipelines sont créés.

Le mot-clé `workflow` est évalué avant les jobs. Par exemple, si un job est configuré pour s'exécuter pour des tags, mais que le workflow empêche les pipelines de tags, le job ne s'exécute jamais.

## Clauses `if` courantes pour `workflow:rules` {#common-if-clauses-for-workflowrules}

Exemples de clauses `if` pour `workflow: rules` :

| Exemples de règles                                        | Détails |
|------------------------------------------------------|---------|
| `if: '$CI_PIPELINE_SOURCE == "merge_request_event"'` | Contrôler quand les pipelines de merge request s'exécutent. |
| `if: '$CI_PIPELINE_SOURCE == "push"'`                | Contrôler quand les pipelines de branche et les pipelines de tags s'exécutent. |
| `if: $CI_COMMIT_TAG`                                 | Contrôler quand les pipelines de tags s'exécutent. |
| `if: $CI_COMMIT_BRANCH`                              | Contrôler quand les pipelines de branche s'exécutent. |

Consultez les [clauses `if` courantes pour `rules`](../jobs/job_rules.md#common-if-clauses-with-predefined-variables) pour plus d'exemples.

## Exemples `workflow: rules` {#workflow-rules-examples}

Dans l'exemple suivant :

- Les pipelines s'exécutent pour tous les événements `push` (modifications apportées aux branches et nouveaux tags).
- Les pipelines pour les événements push dont les messages de commit se terminent par `-draft` ne s'exécutent pas, car ils sont définis sur `when: never`.
- Les pipelines pour les planifications ou les merge requests ne s'exécutent pas non plus, car aucune règle n'est évaluée à vrai pour eux.

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_MESSAGE =~ /-draft$/
      when: never
    - if: $CI_PIPELINE_SOURCE == "push"
```

Cet exemple comporte des règles strictes, et les pipelines ne s'exécutent dans aucun autre cas.

Il est également possible que toutes les règles soient définies sur `when: never`, avec une règle finale `when: always`. Les pipelines correspondant aux règles `when: never` ne s'exécutent pas. Tous les autres types de pipeline s'exécutent. Par exemple :

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always
```

Cet exemple empêche les pipelines pour les planifications ou les pipelines `push` (branches et tags). La règle finale `when: always` exécute tous les autres types de pipeline, **including** les pipelines de merge request.

### Basculer entre les pipelines de branche et les pipelines de merge request {#switch-between-branch-pipelines-and-merge-request-pipelines}

Pour faire basculer le pipeline des pipelines de branche vers les [pipelines de merge request](../pipelines/merge_request_pipelines.md) après la création d'une merge request, ajoutez une section `workflow: rules` à votre fichier `.gitlab-ci.yml`.

Si vous utilisez les deux types de pipeline en même temps, des [pipelines en double](../jobs/job_rules.md#avoid-duplicate-pipelines) risquent de s'exécuter simultanément. Pour éviter les pipelines en double, utilisez la [variable `CI_OPEN_MERGE_REQUESTS`](../variables/predefined_variables.md).

L'exemple suivant concerne un projet qui exécute uniquement des pipelines de branche et des pipelines de merge request, mais n'exécute pas de pipelines dans d'autres cas. Il exécute :

- Les pipelines de branche lorsqu'aucune merge request n'est ouverte pour la branche.
- Les pipelines de merge request lorsqu'une merge request est ouverte pour la branche.

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS
      when: never
    - if: $CI_COMMIT_BRANCH
```

Si GitLab tente de déclencher :

- Un pipeline de merge request : démarrer le pipeline. Par exemple, un pipeline de merge request peut être déclenché par un push vers une branche associée à une merge request ouverte.
- Un pipeline de branche, mais une merge request est ouverte pour cette branche : ne pas exécuter le pipeline de branche. Par exemple, un pipeline de branche peut être déclenché par une modification apportée à une branche, un appel d'API, un pipeline planifié, etc.
- Un pipeline de branche, mais aucune merge request n'est ouverte pour la branche : exécuter le pipeline de branche.

Vous pouvez également ajouter une règle à une section `workflow` existante pour basculer des pipelines de branche vers les pipelines de merge request lors de la création d'une merge request.

Ajoutez cette règle en haut de la section `workflow`, suivie des autres règles déjà présentes :

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - # Previously defined workflow rules here
```

Les [pipelines déclenchés](../triggers/_index.md) qui s'exécutent sur une branche ont une variable `$CI_COMMIT_BRANCH` définie et peuvent être bloqués par une règle similaire. Les pipelines déclenchés ont une source de pipeline `trigger` ou `pipeline`, donc `&& $CI_PIPELINE_SOURCE == "push"` garantit que la règle ne bloque pas les pipelines déclenchés.

### Git Flow avec les pipelines de merge request {#git-flow-with-merge-request-pipelines}

Vous pouvez utiliser `workflow: rules` avec les pipelines de merge request. Grâce à ces règles, vous pouvez utiliser les [fonctionnalités des pipelines de merge request](../pipelines/merge_request_pipelines.md) avec des branches de fonctionnalité, tout en conservant des branches à longue durée de vie pour prendre en charge plusieurs versions de votre logiciel.

Par exemple, pour n'exécuter des pipelines que pour vos merge requests, vos tags et vos branches protégées :

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_TAG
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_REF_PROTECTED == "true"
```

Cet exemple suppose que votre branche par défaut ou d'autres branches à longue durée de vie sont [protégées](../../user/project/repository/branches/protected.md).

### Ignorer les pipelines pour les merge requests en brouillon {#skip-pipelines-for-draft-merge-requests}

Vous pouvez utiliser `workflow: rules` pour ignorer les pipelines des merge requests en brouillon. Cette approche permet d'économiser des ressources de calcul jusqu'à ce que le développement soit terminé.

Utilisez la variable `CI_MERGE_REQUEST_DRAFT` pour vérifier si une merge request est à l'état de brouillon. Cette variable détecte automatiquement tous les formats de brouillon pris en charge par GitLab.

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event" && $CI_MERGE_REQUEST_DRAFT == "true"
      when: never
    - when: always

stages:
  - build

build-job:
  stage: build
  script:
    - echo "Testing"
```

> [!note]
> La variable `CI_MERGE_REQUEST_DRAFT` a été introduite dans GitLab 17.10. Pour les versions antérieures, utilisez `CI_MERGE_REQUEST_TITLE` avec une expression régulière à la place.

## Dépannage {#troubleshooting}

### Merge request bloquée avec le message `Checking pipeline status.` {#merge-request-stuck-with-checking-pipeline-status-message}

Si une merge request affiche `Checking pipeline status.`, mais que le message ne disparaît jamais (le « spinner » ne s'arrête jamais de tourner), cela peut être dû à `workflow:rules`. Ce problème peut survenir si un projet a l'option [**Les pipelines doivent réussir**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) activée, mais que les `workflow:rules` empêchent l'exécution d'un pipeline pour la merge request.

Par exemple, avec ce workflow, les merge requests ne peuvent pas être fusionnées, car aucun pipeline ne peut s'exécuter :

```yaml
workflow:
  rules:
    - changes:
        - .gitlab/**/**.md
      when: never
```

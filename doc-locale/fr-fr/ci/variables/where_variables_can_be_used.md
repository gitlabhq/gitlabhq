---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Utilisation et expansion des variables CI/CD dans différents environnements.
title: Où les variables peuvent être utilisées
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Comme décrit dans la documentation sur les [variables CI/CD](_index.md), vous pouvez définir de nombreuses variables différentes. Certaines d'entre elles peuvent être utilisées pour toutes les fonctionnalités GitLab CI/CD, mais d'autres sont plus ou moins limitées.

Ce document décrit où et comment les différents types de variables peuvent être utilisés.

## Utilisation des variables {#variables-usage}

Il existe deux endroits où les variables définies peuvent être utilisées. Sur le :

1. Côté GitLab, dans le fichier `.gitlab-ci.yml`.
1. Côté GitLab Runner, dans `config.toml`.

### Fichier `.gitlab-ci.yml` {#gitlab-ciyml-file}

{{< history >}}

- Prise en charge des variables `CI_ENVIRONMENT_*` à l'exception de `CI_ENVIRONMENT_SLUG` [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128694) dans GitLab 16.4.

{{< /history >}}

| Définition                                                              | Peut être étendue ? | Lieu d'expansion        | Description |
|:------------------------------------------------------------------------|:-----------------|:-----------------------|:------------|
| [`after_script`](../yaml/_index.md#after_script)                        | oui              | Shell d'exécution de script | L'expansion des variables est effectuée par l'[environnement shell d'exécution](#execution-shell-environment). |
| [`artifacts:name`](../yaml/_index.md#artifactsname)                     | oui              | Runner                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-runner-internal-variable-expansion-mechanism) de GitLab Runner. |
| [`artifacts:paths`](../yaml/_index.md#artifactspaths)                   | oui              | Runner                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-runner-internal-variable-expansion-mechanism) de GitLab Runner. |
| [`artifacts:exclude`](../yaml/_index.md#artifactsexclude)               | oui              | Runner                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-runner-internal-variable-expansion-mechanism) de GitLab Runner. |
| [`before_script`](../yaml/_index.md#before_script)                      | oui              | Shell d'exécution de script | L'expansion des variables est effectuée par l'[environnement shell d'exécution](#execution-shell-environment) |
| [`cache:key`](../yaml/_index.md#cachekey)                               | oui              | Runner                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-runner-internal-variable-expansion-mechanism) de GitLab Runner. |
| [`cache:paths`](../yaml/_index.md#cachepaths)                           | oui              | Runner                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-runner-internal-variable-expansion-mechanism) de GitLab Runner. |
| [`cache:policy`](../yaml/_index.md#cachepolicy)                         | oui              | Runner                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-runner-internal-variable-expansion-mechanism) de GitLab Runner. |
| [`environment:name`](../yaml/_index.md#environmentname)                 | oui              | GitLab                 | Similaire à `environment:url`, mais l'expansion des variables ne prend pas en charge les éléments suivants :<br/><br/>\- Variables `CI_ENVIRONMENT_*`.<br/>- [Variables persistées](#persisted-variables). |
| [`environment:url`](../yaml/_index.md#environmenturl)                   | oui              | GitLab                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-internal-variable-expansion-mechanism) dans GitLab.<br/><br/>Sont prises en charge toutes les variables définies pour un job (variables de projet/groupe, variables provenant de `.gitlab-ci.yml`, variables provenant de déclencheurs, variables provenant de planifications de pipeline).<br/><br/>Ne sont pas prises en charge les variables définies dans le fichier `config.toml` de GitLab Runner et les variables créées dans le `script` du job. |
| [`environment:deployment_tier`](../yaml/_index.md#environmentdeployment_tier) | oui              | GitLab                 | Similaire à `environment:url`, mais l'expansion des variables ne prend pas en charge les éléments suivants :<br/><br/>\- Variables `CI_ENVIRONMENT_*`.<br/>- [Variables persistées](#persisted-variables). |
| [`environment:auto_stop_in`](../yaml/_index.md#environmentauto_stop_in) | oui              | GitLab                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-internal-variable-expansion-mechanism) dans GitLab.<br/><br/> La valeur de la variable substituée doit représenter une période de temps sous une forme en langage naturel lisible. Consultez les [valeurs prises en charge](../yaml/_index.md#environmentauto_stop_in) pour plus d'informations. |
| [`environment:kubernetes:agent`](../yaml/_index.md#environmentkubernetes) | oui            | GitLab                 | Similaire à `environment:url`, mais l'expansion des variables ne prend pas en charge les éléments suivants :<br/><br/>\- Variables `CI_ENVIRONMENT_*`.<br/>- [Variables persistées](#persisted-variables). |
| [`environment:kubernetes:namespace`](../yaml/_index.md#environmentkubernetes) | oui        | GitLab                 | Similaire à `environment:url`, mais l'expansion des variables ne prend pas en charge les éléments suivants :<br/><br/>\- Variables `CI_ENVIRONMENT_*`.<br/>- [Variables persistées](#persisted-variables). |
| [`id_tokens:aud`](../yaml/_index.md#id_tokens)                          | oui              | GitLab                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-internal-variable-expansion-mechanism) dans GitLab. L'expansion des variables a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/414293) dans GitLab 16.1. |
| [`image`](../yaml/_index.md#image)                                      | oui              | Runner                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-runner-internal-variable-expansion-mechanism) de GitLab Runner. |
| [`include`](../yaml/_index.md#include)                                  | oui              | GitLab                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-internal-variable-expansion-mechanism) dans GitLab. <br/><br/>Consultez [Utiliser des variables avec include](../yaml/includes.md#use-variables-with-include) pour plus d'informations sur les variables prises en charge. |
| [`resource_group`](../yaml/_index.md#resource_group)                    | oui              | GitLab                 | Similaire à `environment:url`, mais l'expansion des variables ne prend pas en charge les éléments suivants :<br/>- `CI_ENVIRONMENT_URL`<br/>- [Variables persistées](#persisted-variables). |
| [`rules:changes`](../yaml/_index.md#ruleschanges)                       | non               | GitLab                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-internal-variable-expansion-mechanism) dans GitLab. |
| [`rules:changes:compare_to`](../yaml/_index.md#ruleschangescompare_to)  | non               | GitLab                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-internal-variable-expansion-mechanism) dans GitLab. |
| [`rules:exists`](../yaml/_index.md#rulesexists)                         | non               | GitLab                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-internal-variable-expansion-mechanism) dans GitLab. |
| [`rules:if`](../yaml/_index.md#rulesif)                                 | non               | Non applicable         | La variable doit être sous la forme `$variable`. Les éléments suivants ne sont pas pris en charge :<br/><br/>\- La variable `CI_ENVIRONMENT_SLUG`.<br/>- [Variables persistées](#persisted-variables). |
| [`script`](../yaml/_index.md#script)                                    | oui              | Shell d'exécution de script | L'expansion des variables est effectuée par l'[environnement shell d'exécution](#execution-shell-environment). |
| [`services:name`](../yaml/_index.md#services)                           | oui              | Runner                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-runner-internal-variable-expansion-mechanism) de GitLab Runner. |
| [`tags`](../yaml/_index.md#tags)                                        | oui              | GitLab                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-internal-variable-expansion-mechanism) dans GitLab. |
| [`trigger` et `trigger:project`](../yaml/_index.md#trigger)            | oui              | GitLab                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-internal-variable-expansion-mechanism) dans GitLab. L'expansion des variables pour `trigger:project` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/367660) dans GitLab 15.3. |
| [`variables`](../yaml/_index.md#variables)                              | oui              | GitLab/Runner          | L'expansion des variables est d'abord effectuée par le [mécanisme interne d'expansion des variables](#gitlab-internal-variable-expansion-mechanism) dans GitLab, puis toutes les variables non reconnues ou indisponibles sont étendues par le [mécanisme interne d'expansion des variables](#gitlab-runner-internal-variable-expansion-mechanism) de GitLab Runner. |
| [`workflow:name`](../yaml/_index.md#workflowname)                       | oui              | GitLab                 | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-internal-variable-expansion-mechanism) dans GitLab.<br/><br/>Sont prises en charge toutes les variables disponibles dans `workflow` :<br/>\- Variables de projet/groupe.<br/>- `variables` global et `workflow:rules:variables` (lorsque la règle est satisfaite).<br/>\- Variables héritées des pipelines parents.<br/>\- Variables provenant de déclencheurs.<br/>\- Variables provenant de planifications de pipeline.<br/><br/>Ne sont pas prises en charge les variables définies dans le fichier `config.toml` de GitLab Runner, les variables définies dans les jobs, ni les [variables persistées](#persisted-variables). |

### Fichier `config.toml` {#configtoml-file}

| Définition                           | Peut être étendue ? | Description |
|:-------------------------------------|:-----------------|:------------|
| `runners.environment`                | oui              | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-runner-internal-variable-expansion-mechanism) de GitLab Runner |
| `runners.kubernetes.pod_labels`      | oui              | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-runner-internal-variable-expansion-mechanism) de GitLab Runner |
| `runners.kubernetes.pod_annotations` | oui              | L'expansion des variables est effectuée par le [mécanisme interne d'expansion des variables](#gitlab-runner-internal-variable-expansion-mechanism) de GitLab Runner |

Vous pouvez en savoir plus sur `config.toml` dans la [documentation de GitLab Runner](https://docs.gitlab.com/runner/configuration/advanced-configuration/).

## Mécanismes d'expansion {#expansion-mechanisms}

Il existe trois mécanismes d'expansion :

- GitLab
- GitLab Runner
- Environnement shell d'exécution

### Mécanisme interne d'expansion des variables GitLab {#gitlab-internal-variable-expansion-mechanism}

La partie à étendre doit être sous la forme `$variable`, `${variable}` ou `%variable%`. Chaque forme est traitée de la même manière, quel que soit le système d'exploitation ou le shell qui gère le job, car l'expansion est effectuée dans GitLab avant que tout runner ne reçoive le job.

#### Expansion des variables imbriquées {#nested-variable-expansion}

GitLab développe les valeurs des variables de job de manière récursive avant de les envoyer au runner. Par exemple, dans le scénario suivant :

```yaml
- BUILD_ROOT_DIR: '${CI_BUILDS_DIR}'
- OUT_PATH: '${BUILD_ROOT_DIR}/out'
- PACKAGE_PATH: '${OUT_PATH}/pkg'
```

Le runner reçoit un chemin valide et complet. Par exemple, si `${CI_BUILDS_DIR}` est `/output`, alors `PACKAGE_PATH` serait `/output/out/pkg`.

Les références aux variables indisponibles sont conservées telles quelles. Dans ce cas, le runner [tente d'étendre la valeur de la variable](#gitlab-runner-internal-variable-expansion-mechanism) à l'exécution. Par exemple, une variable comme `CI_BUILDS_DIR` n'est connue du runner qu'à l'exécution.

### Mécanisme interne d'expansion des variables de GitLab Runner {#gitlab-runner-internal-variable-expansion-mechanism}

- Pris en charge : variables de projet/groupe, variables `.gitlab-ci.yml`, variables `config.toml`, et variables provenant de déclencheurs, de planifications de pipeline et de pipelines manuels.
- Non pris en charge : variables définies à l'intérieur des scripts (par exemple, `export MY_VARIABLE="test"`).

Le runner utilise la méthode `os.Expand()` de Go pour l'expansion des variables. Cela signifie qu'il ne traite que les variables définies sous la forme `$variable` et `${variable}`. Il est également important de noter que l'expansion n'est effectuée qu'une seule fois, de sorte que les variables imbriquées peuvent fonctionner ou non, selon l'ordre des définitions de variables et selon que l'[expansion des variables imbriquées](#nested-variable-expansion) est activée dans GitLab.

Pour les téléversements d'artefacts et de cache, le runner utilise [mvdan.cc/sh/v3/expand](https://pkg.go.dev/mvdan.cc/sh/v3/expand) pour l'expansion des variables à la place de `os.Expand()` de Go, car `mvdan.cc/sh/v3/expand` prend en charge l'[expansion des paramètres](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html).

### Environnement shell d'exécution {#execution-shell-environment}

Il s'agit d'une phase d'expansion qui se produit lors de l'exécution de `script`. Son comportement dépend du shell utilisé (`bash`, `sh`, `cmd`, PowerShell). Par exemple, si le `script` du job contient une ligne `echo $MY_VARIABLE-${MY_VARIABLE_2}`, elle devrait être correctement traitée par bash/sh (laissant des chaînes vides ou certaines valeurs selon que les variables sont définies ou non), mais ne fonctionne pas avec `cmd` ou PowerShell de Windows, car ces shells utilisent une syntaxe de variables différente.

Pris en charge :

- Le `script` peut utiliser toutes les variables disponibles par défaut pour le shell (par exemple, `$PATH` qui devrait être présent dans tous les shells bash/sh) et toutes les variables définies par GitLab CI/CD (variables de projet/groupe, variables `.gitlab-ci.yml`, variables `config.toml`, et variables provenant de déclencheurs et de planifications de pipeline).
- Le `script` peut également utiliser toutes les variables définies dans les lignes précédentes. Ainsi, par exemple, si vous définissez une variable `export MY_VARIABLE="test"` :
  - Dans `before_script`, cela fonctionne dans les lignes suivantes de `before_script` et dans toutes les lignes du `script` associé.
  - Dans `script`, cela fonctionne dans les lignes suivantes de `script`.
  - Dans `after_script`, cela fonctionne dans les lignes suivantes de `after_script`.

Dans le cas des scripts `after_script`, ils peuvent :

- Utiliser uniquement les variables définies avant le script dans la même section `after_script`.
- Ne pas utiliser les variables définies dans `before_script` et `script`.

Ces restrictions existent parce que les scripts `after_script` sont exécutés dans un [contexte shell séparé](../yaml/_index.md#after_script).

## Variables persistées {#persisted-variables}

Certaines variables prédéfinies sont dites persistées. Les variables persistées sont :

- Prises en charge pour les définitions dont le [lieu d'expansion](#gitlab-ciyml-file) est :
  - Runner.
  - Shell d'exécution de script.
- Non prises en charge :
  - Pour les définitions dont le [lieu d'expansion](#gitlab-ciyml-file) est GitLab.
  - Dans les [expressions de variables](../jobs/job_rules.md#cicd-variable-expressions) `rules`.

Les [jobs de déclenchement de pipeline](../yaml/_index.md#trigger) ne peuvent pas utiliser les variables persistées au niveau du job, mais peuvent utiliser les variables persistées au niveau du pipeline.

Certaines variables persistées contiennent des jetons et ne peuvent pas être utilisées dans certaines définitions pour des raisons de sécurité.

Variables persistées au niveau du pipeline :

- `CI_PIPELINE_ID`
- `CI_PIPELINE_URL`

Variables persistées au niveau du job :

- `CI_DEPLOY_PASSWORD`
- `CI_DEPLOY_USER`
- `CI_JOB_ID`
- `CI_JOB_STARTED_AT`
- `CI_JOB_TOKEN`
- `CI_JOB_URL`
- `CI_PIPELINE_CREATED_AT`
- `CI_REGISTRY_PASSWORD`
- `CI_REGISTRY_USER`
- `CI_REPOSITORY_URL`

## Variables avec une portée d'environnement {#variables-with-an-environment-scope}

Les variables définies avec une portée d'environnement sont prises en charge. Étant donné qu'une variable `$STAGING_SECRET` est définie dans une portée de `review/staging/*`, le job suivant utilisant des environnements dynamiques est créé, sur la base de l'expression de variable correspondante :

```yaml
my-job:
  stage: staging
  environment:
    name: review/$CI_JOB_STAGE/deploy
  script:
    - 'deploy staging'
  rules:
    - if: $STAGING_SECRET == 'something'
```

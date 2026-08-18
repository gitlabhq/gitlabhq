---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mots-clés obsolètes
---

Certains mots-clés CI/CD sont obsolètes et ne sont plus recommandés.

> [!warning]
> Ces mots-clés sont toujours utilisables pour assurer la rétrocompatibilité, mais leur suppression pourrait être planifiée dans un futur jalon majeur.

## `image`, `services`, `cache`, `before_script`, `after_script` définis globalement {#globally-defined-image-services-cache-before_script-after_script}

La définition globale de `image`, `services`, `cache`, `before_script` et `after_script` est obsolète. Utilisez [`default`](_index.md#default) à la place.

Par exemple :

```yaml
default:
  image: ruby:3.0
  services:
    - docker:dind
  cache:
    paths: [vendor/]
  before_script:
    - bundle config set path vendor/bundle
    - bundle install
  after_script:
    - rm -rf tmp/
```

## `only` / `except` {#only--except}

> [!note]
> `only` et `except` sont obsolètes. Pour contrôler quand ajouter des jobs aux pipelines, utilisez [`rules`](_index.md#rules) à la place.

Vous pouvez utiliser `only` et `except` pour contrôler quand ajouter des jobs aux pipelines.

- Utilisez `only` pour définir quand un job s'exécute.
- Utilisez `except` pour définir quand un job ne s'exécute pas.

### `only:refs` / `except:refs` {#onlyrefs--exceptrefs}

> [!note]
> `only:refs` et `except:refs` sont obsolètes. Pour utiliser des refs, des expressions régulières ou des variables afin de contrôler quand ajouter des jobs aux pipelines, utilisez [`rules:if`](_index.md#rulesif) à la place.

Vous pouvez utiliser les mots-clés `only:refs` et `except:refs` pour contrôler quand ajouter des jobs à un pipeline en fonction des noms de branches ou des types de pipeline.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans le cadre d'un job.

**Valeurs prises en charge** : Un tableau incluant un nombre quelconque de :

- Noms de branches, par exemple `main` ou `my-feature-branch`.
- Expressions régulières correspondant aux noms de branches, par exemple `/^feature-.*/`.
- Les mots-clés suivants :

  | **Valeur**                | **Description** |
  | -------------------------|-----------------|
  | `api`                    | Pour les pipelines déclenchés par l'[API pipelines](../../api/pipelines.md#create-a-new-pipeline). |
  | `branches`               | Lorsque la référence Git d'un pipeline est une branche. |
  | `chat`                   | Pour les pipelines créés à l'aide d'une commande [GitLab ChatOps](../chatops/_index.md). |
  | `external`               | Lorsque vous utilisez des services CI autres que GitLab. |
  | `external_pull_requests` | Lorsqu'une pull request externe sur GitHub est créée ou mise à jour (voir [Pipelines pour les pull requests externes](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests)). |
  | `merge_requests`         | Pour les pipelines créés lorsqu'un merge request est créé ou mis à jour. Active les [pipelines de merge request](../pipelines/merge_request_pipelines.md), les [pipelines de résultats fusionnés](../pipelines/merged_results_pipelines.md) et les [merge trains](../pipelines/merge_trains.md). |
  | `pipelines`              | Pour les [pipelines multi-projets](../pipelines/downstream_pipelines.md#multi-project-pipelines) créés en [utilisant l'API avec `CI_JOB_TOKEN`](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api), ou le mot-clé [`trigger`](_index.md#trigger). |
  | `pushes`                 | Pour les pipelines déclenchés par un événement `git push`, y compris pour les branches et les tags. |
  | `schedules`              | Pour les [pipelines planifiés](../pipelines/schedules.md). |
  | `tags`                   | Lorsque la référence Git d'un pipeline est un tag. |
  | `triggers`               | Pour les pipelines créés à l'aide d'un [token de déclenchement](../triggers/_index.md#configure-cicd-jobs-to-run-in-triggered-pipelines). |
  | `web`                    | Pour les pipelines créés en sélectionnant **Nouveau pipeline** dans l'interface GitLab, depuis la section **Version** > **Pipelines** du projet. |

**Exemple de `only:refs` et `except:refs`** :

```yaml
job1:
  script: echo
  only:
    - main
    - /^issue-.*$/
    - merge_requests

job2:
  script: echo
  except:
    - main
    - /^stable-branch.*$/
    - schedules
```

**Informations complémentaires** :

- Les pipelines planifiés s'exécutent sur des branches spécifiques, donc les jobs configurés avec `only: branches` s'exécutent également sur les pipelines planifiés. Ajoutez `except: schedules` pour empêcher les jobs avec `only: branches` de s'exécuter sur les pipelines planifiés.
- `only` ou `except` utilisés sans aucun autre mot-clé sont équivalents à `only: refs` ou `except: refs`. Par exemple, les deux configurations de jobs suivantes ont le même comportement :

  ```yaml
  job1:
    script: echo
    only:
      - branches

  job2:
    script: echo
    only:
      refs:
        - branches
  ```

- Si un job n'utilise pas `only`, `except` ou [`rules`](_index.md#rules), alors `only` est défini par défaut sur `branches` et `tags`.

  Par exemple, `job1` et `job2` sont équivalents :

  ```yaml
  job1:
    script: echo "test"

  job2:
    script: echo "test"
    only:
      - branches
      - tags
  ```

### `only:variables` / `except:variables` {#onlyvariables--exceptvariables}

> [!note]
> `only:variables` et `except:variables` sont obsolètes. Pour utiliser des refs, des expressions régulières ou des variables afin de contrôler quand ajouter des jobs aux pipelines, utilisez [`rules:if`](_index.md#rulesif) à la place.

Vous pouvez utiliser les mots-clés `only:variables` ou `except:variables` pour contrôler quand ajouter des jobs à un pipeline, en fonction du statut des [variables CI/CD](../variables/_index.md).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans le cadre d'un job.

**Valeurs prises en charge** :

- Un tableau d'[expressions de variables CI/CD](../jobs/job_rules.md#cicd-variable-expressions).

**Exemple de `only:variables`** :

```yaml
deploy:
  script: cap staging deploy
  only:
    variables:
      - $RELEASE == "staging"
      - $STAGING
```

### `only:changes` / `except:changes` {#onlychanges--exceptchanges}

> [!note]
> `only:changes` et `except:changes` sont obsolètes. Pour utiliser les fichiers modifiés afin de contrôler quand ajouter un job à un pipeline, utilisez [`rules:changes`](_index.md#ruleschanges) à la place.

Utilisez le mot-clé `changes` avec `only` pour exécuter un job, ou avec `except` pour ignorer un job, lorsqu'un événement Git push modifie un fichier.

Utilisez `changes` dans les pipelines avec les refs suivants :

- `branches`
- `external_pull_requests`
- `merge_requests`

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans le cadre d'un job.

**Valeurs prises en charge** : Un tableau incluant un nombre quelconque de :

- Chemins vers des fichiers.
- Chemins génériques pour :
  - Répertoires uniques, par exemple `path/to/directory/*`.
  - Un répertoire et tous ses sous-répertoires, par exemple `path/to/directory/**/*`.
- Chemins [glob](https://en.wikipedia.org/wiki/Glob_(programming)) génériques pour tous les fichiers ayant la même extension ou plusieurs extensions, par exemple `*.md` ou `path/to/directory/*.{rb,py,sh}`.
- Chemins génériques vers des fichiers dans le répertoire racine, ou tous les répertoires, entre guillemets doubles. Par exemple `"*.json"` ou `"**/*.json"`.

**Exemple de `only:changes`** :

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  only:
    refs:
      - branches
    changes:
      - Dockerfile
      - docker/scripts/*
      - dockerfiles/**/*
      - more_scripts/*.{rb,py,sh}
      - "**/*.json"
```

**Informations complémentaires** :

- `changes` est résolu à `true` si l'un des fichiers correspondants est modifié (opération `OR`).
- Les motifs glob sont interprétés avec [`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch) de Ruby avec les [indicateurs](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29) `File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`.
- Si vous utilisez des refs autres que `branches`, `external_pull_requests` ou `merge_requests`, `changes` ne peut pas déterminer si un fichier donné est nouveau ou ancien et retourne toujours `true`.
- Si vous utilisez `only: changes` avec d'autres refs, les jobs ignorent les modifications et s'exécutent toujours.
- Si vous utilisez `except: changes` avec d'autres refs, les jobs ignorent les modifications et ne s'exécutent jamais.

**Sujets connexes** :

- [Des jobs ou des pipelines peuvent s'exécuter de manière inattendue lors de l'utilisation de `only: changes`](../jobs/job_troubleshooting.md#jobs-or-pipelines-run-unexpectedly-when-using-changes).

### `only:kubernetes` / `except:kubernetes` {#onlykubernetes--exceptkubernetes}

> [!note]
> `only:kubernetes` et `except:kubernetes` sont obsolètes. Pour contrôler si des jobs sont ajoutés au pipeline lorsque le service Kubernetes est actif dans le projet, utilisez [`rules:if`](_index.md#rulesif) avec la variable CI/CD prédéfinie [`CI_KUBERNETES_ACTIVE`](../variables/predefined_variables.md) à la place.

Utilisez `only:kubernetes` ou `except:kubernetes` pour contrôler si des jobs sont ajoutés au pipeline lorsque le service Kubernetes est actif dans le projet.

**Type de mot-clé** : Spécifique au job. Vous pouvez l'utiliser uniquement dans le cadre d'un job.

**Valeurs prises en charge** :

- La stratégie `kubernetes` accepte uniquement le mot-clé `active`.

**Exemple de `only:kubernetes`** :

```yaml
deploy:
  only:
    kubernetes: active
```

Dans cet exemple, le job `deploy` s'exécute uniquement lorsque le service Kubernetes est actif dans le projet.

## Mot-clé `publish` et nom de job `pages` pour GitLab Pages {#publish-keyword-and-pages-job-name-for-gitlab-pages}

Le mot-clé `publish` au niveau du job et le nom de job `pages` pour les jobs de déploiement GitLab Pages sont obsolètes.

Pour contrôler le déploiement des pages, utilisez les mots-clés [`pages`](_index.md#pages) et [`pages.publish`](_index.md#pagespublish) à la place.

## `environment:kubernetes:namespace` et `environment:kubernetes:flux_resource_path` {#environmentkubernetesnamespace-and-environmentkubernetesflux_resource_path}

> [!note]
> `environment:kubernetes:namespace` et `environment:kubernetes:flux_resource_path` sont obsolètes lorsqu'ils sont utilisés directement sous `kubernetes`. Pour configurer les paramètres du tableau de bord, utilisez `environment:kubernetes:dashboard:namespace` et `environment:kubernetes:dashboard:flux_resource_path` à la place. Pour plus d'informations, consultez [`environment:kubernetes`](_index.md#environmentkubernetes).

Vous pouvez utiliser `environment:kubernetes:namespace` et `environment:kubernetes:flux_resource_path` pour configurer les paramètres du tableau de bord Kubernetes, mais leur utilisation directement sous la section `kubernetes` est obsolète.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans le cadre d'un job.

**Exemple de `environment:kubernetes:namespace` et `environment:kubernetes:flux_resource_path`** :

```yaml
deploy:
  environment:
    name: production
    kubernetes:
      agent: path/to/agent/project:agent-name
      namespace: my-namespace
      flux_resource_path: helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release
```

**Exemple de `environment:kubernetes:dashboard:namespace` et `environment:kubernetes:dashboard:flux_resource_path`** :

```yaml
deploy:
  environment:
    name: production
    kubernetes:
      agent: path/to/agent/project:agent-name
      dashboard:
        namespace: my-namespace
        flux_resource_path: helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release
```

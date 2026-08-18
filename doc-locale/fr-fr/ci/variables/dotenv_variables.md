---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page,
  see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Transmettre des variables dotenv à des jobs spécifiques
description: "Utilisez des rapports dotenv pour transmettre des variables d'environnement entre les jobs dans les pipelines."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour transmettre des variables d'environnement à d'autres jobs, utilisez un fichier dotenv. Un fichier dotenv est un fichier avec l'extension `.env` qui stocke une liste de clés et de valeurs de variables d'environnement. Par exemple, dans un fichier `sample.env` :

```plaintext
REVIEW_URL=review.example.com/123456
BUILD_VERSION=v1.0.0
```

Enregistrez le fichier dotenv en tant qu'[artefact de rapport dotenv](../yaml/artifacts_reports.md#artifactsreportsdotenv), qui peut être transmis à d'autres jobs dans le même pipeline, aux pipelines downstream, ou pour définir des URL d'environnement dynamiques.

Vous pouvez utiliser les variables dotenv des façons suivantes :

- Générer des valeurs dans un job et les utiliser dans les jobs suivants.
- Transmettre des valeurs calculées entre les étapes du pipeline.
- Définir des URL d'environnement dynamiques en fonction des sorties de déploiement.
- Partager des variables entre des pipelines multi-projets.

Vous pouvez utiliser des variables dotenv dans les sections `script` des jobs ou avec des mots-clés qui prennent en charge [l'expansion des variables sur le runner](where_variables_can_be_used.md#gitlab-ciyml-file). Vous ne pouvez pas utiliser de variables dotenv dans les sections `rules`.

Les variables dotenv ont la [priorité](_index.md#cicd-variable-precedence) sur les variables de job et les variables par défaut définies dans `.gitlab-ci.yml`, mais pas sur les variables de projet, de groupe, d'instance ou de pipeline.

Si le même nom de variable apparaît plusieurs fois dans un rapport `dotenv`, la dernière valeur est utilisée.

## Transmettre des variables à des jobs ultérieurs {#pass-variables-to-later-jobs}

Par défaut, les variables dotenv sont disponibles pour tous les jobs dans les étapes ultérieures. Pour transmettre des variables entre des jobs :

1. Dans un job, créez un fichier (par exemple, `build.env`) avec des variables au format `VARIABLE_NAME=value`, une variable par ligne.
1. Exportez le fichier en tant qu'artefact de rapport `dotenv`.
1. Dans les jobs ultérieurs, utilisez les variables dans vos scripts.

Par exemple, `build-job` crée `build.env` avec `BUILD_VERSION=v1.0.0`, et `test-job` le reçoit automatiquement comme variable d'environnement :

```yaml
build-job:
  stage: build
  script:
    - echo "BUILD_VERSION=v1.0.0" >> build.env
  artifacts:
    reports:
      dotenv: build.env

test-job:
  stage: test
  script:
    - echo "Testing version $BUILD_VERSION"  # Output: 'Testing version v1.0.0'
```

> [!warning]
> N'incluez pas de données sensibles telles que des identifiants, des clés API ou des jetons dans les fichiers dotenv. Les utilisateurs du pipeline peuvent accéder au contenu des fichiers dotenv. Pour restreindre l'accès, utilisez [`artifacts:access`](../yaml/_index.md#artifactsaccess).

## Contrôler quels jobs reçoivent les variables dotenv {#control-which-jobs-receive-dotenv-variables}

Pour contrôler quels jobs reçoivent les variables dotenv, utilisez les mots-clés [`dependencies`](../yaml/_index.md#dependencies) ou [`needs`](../yaml/_index.md#needs).

### Hériter de jobs spécifiques {#inherit-from-specific-jobs}

Utilisez `dependencies` pour limiter l'héritage à des jobs spécifiques uniquement :

```yaml
build-job1:
  stage: build
  script:
    - echo "BUILD_VERSION=v1.0.0" >> build.env
  artifacts:
    reports:
      dotenv: build.env

build-job2:
  stage: build
  script:
    - echo "This job has no dotenv artifacts"

test-job:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output: 'v1.0.0'
  dependencies:
    - build-job1
    # build-job2 is not listed, so its artifacts are not inherited
```

### Exclure des variables dotenv {#exclude-dotenv-variables}

Pour empêcher un job de recevoir des variables dotenv d'un job nommé, utilisez `needs` avec `artifacts: false`. Cela bloque tous les téléchargements d'artefacts de ce job, pas seulement les variables dotenv :

```yaml
test-job:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output: '' (empty)
  needs:
    - job: build-job1
      artifacts: false
```

Le [`needs`](../yaml/_index.md#needs) dans cet exemple fait également démarrer le job dès que `build-job1` est terminé.

Ou utilisez un tableau [`dependencies`](../yaml/_index.md) vide pour bloquer les téléchargements d'artefacts de tous les jobs en amont :

```yaml
test-job:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output: '' (empty)
  dependencies: []
```

## Transmettre des variables aux pipelines downstream {#pass-variables-to-downstream-pipelines}

Vous pouvez transmettre des variables dotenv à un pipeline downstream grâce à l'héritage des variables dotenv. Dans un [pipeline multi-projets](../pipelines/downstream_pipelines.md#multi-project-pipelines), créez l'artefact dotenv dans un job en amont et utilisez `needs` dans le job downstream pour en hériter :

1. Enregistrez les variables dans un fichier `.env`.
1. Enregistrez le fichier `.env` en tant qu'artefact de rapport `dotenv`.
1. Déclenchez le pipeline downstream.

```yaml
build_vars:
  stage: build
  script:
    - echo "BUILD_VERSION=hello" >> build.env
  artifacts:
    reports:
      dotenv: build.env

deploy:
  stage: deploy
  trigger: my/downstream_project
```

Dans le pipeline downstream, configurez le job pour hériter des artefacts du job en amont avec `needs`. Le job reçoit les variables dotenv et peut ensuite accéder à `BUILD_VERSION` dans le script :

```yaml
test:
  stage: test
  script:
    - echo $BUILD_VERSION
  needs:
    - project: my/upstream_project
      job: build_vars
      ref: master
      artifacts: true
```

## Définir une URL d'environnement dynamique {#set-a-dynamic-environment-url}

Vous pouvez utiliser des variables dotenv pour définir une URL d'environnement dynamique après la fin d'un job de déploiement. Cela est utile lorsqu'une plateforme d'hébergement externe génère une URL dynamiquement pour chaque déploiement.

Pour plus d'informations, consultez [Définir une URL d'environnement dynamique](../environments/_index.md#set-a-dynamic-environment-url).

## Stocker des valeurs complexes {#store-complex-values}

Les fichiers dotenv présentent des limitations de format spécifiques, telles que des restrictions sur les valeurs multilignes et les caractères spéciaux nécessitant un échappement. Si votre valeur contient du JSON, s'étend sur plusieurs lignes ou inclut des caractères nécessitant un échappement, évitez d'utiliser des variables dotenv. Utilisez plutôt un artefact de fichier distinct. Pour la liste complète des contraintes de valeur, consultez [les exigences de format](#format-requirements).

Au lieu de :

```yaml
# Not supported
- echo 'CONFIG={"key": "value"}' >> build.env
```

Utilisez un artefact distinct :

```yaml
build-job:
  stage: build
  script:
    - echo '{"key": "value"}' > config.json
  artifacts:
    paths:
      - config.json
```

## Exigences relatives aux fichiers dotenv {#dotenv-file-requirements}

Les fichiers dotenv doivent satisfaire les exigences suivantes en matière de format, de taille et de variables.

GitLab utilise le [gem dotenv](https://github.com/bkeepers/dotenv) pour gérer les fichiers dotenv, mais applique des restrictions supplémentaires au-delà des [règles dotenv d'origine](https://github.com/motdotla/dotenv?tab=readme-ov-file#what-rules-does-the-parsing-engine-follow) et de l'implémentation du gem.

### Exigences de format {#format-requirements}

- Seul l'[encodage UTF-8](../jobs/job_artifacts_troubleshooting.md#error-message-fatal-invalid-argument-when-uploading-a-dotenv-artifact-on-a-windows-runner) est pris en charge.
- Le fichier ne peut pas contenir de lignes vides ni de commentaires (lignes commençant par `#`).
- Les noms de variables peuvent uniquement contenir des lettres ASCII (`A-Za-z`), des chiffres (`0-9`) et des tirets bas (`_`).
- Le fichier dotenv ne prend pas en charge les guillemets. Les guillemets simples ou doubles sont conservés tels quels et ne peuvent pas être utilisés pour l'échappement.
- Les valeurs ne peuvent pas contenir de sauts de ligne ou d'autres caractères spéciaux nécessitant un échappement.
- Les valeurs multilignes ne sont pas prises en charge. GitLab rejette le fichier lors du chargement.
- Les espaces et les caractères de saut de ligne (`\n`) en début et en fin de valeur sont supprimés.

### Limites de taille et de variables {#size-and-variable-limits}

| Limite                                                      | Valeur |
| ---------------------------------------------------------- | ----- |
| Taille maximale du fichier                                          | 5 Ko  |
| Nombre maximal de variables héritées par défaut sur GitLab Self-Managed | 20    |

Pour les limites d'édition de GitLab.com, consultez [les paramètres CI/CD de GitLab.com](../../user/gitlab_com/_index.md#cicd).

Pour modifier ces limites sur GitLab Self-Managed, consultez [les limites CI/CD](../../administration/cicd/limits.md#limit-dotenv-file-size).

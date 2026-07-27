---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Exemples de mise en cache CI/CD
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez la mise en cache pour éviter de télécharger des dépendances et des artefacts de build à chaque exécution d'un job. La mise en cache accélère vos pipelines CI/CD en réutilisant le contenu précédemment téléchargé.

Pour plus d'exemples, consultez les [modèles GitLab CI/CD](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).

## Stratégies de cache {#cache-strategies}

Ces exemples présentent différentes approches pour partager des caches entre les jobs et les branches.

### Partager des caches entre les jobs d'une même branche {#share-caches-between-jobs-in-the-same-branch}

Pour que les jobs de chaque branche utilisent le même cache, définissez un cache avec le paramètre `key: $CI_COMMIT_REF_SLUG` :

```yaml
cache:
  key: $CI_COMMIT_REF_SLUG
```

Cette configuration vous protège d'un écrasement accidentel du cache. Cependant, le premier pipeline d'un merge request est lent. La prochaine fois qu'un commit est poussé vers la branche, le cache est réutilisé et les jobs s'exécutent plus rapidement.

Pour activer la mise en cache par job et par branche :

```yaml
cache:
  key: "$CI_JOB_NAME-$CI_COMMIT_REF_SLUG"
```

Pour activer la mise en cache par étape et par branche :

```yaml
cache:
  key: "$CI_JOB_STAGE-$CI_COMMIT_REF_SLUG"
```

### Partager des caches entre les jobs de différentes branches {#share-caches-across-jobs-in-different-branches}

Pour partager un cache entre toutes les branches et tous les jobs, utilisez la même clé pour tout :

```yaml
cache:
  key: one-key-to-rule-them-all
```

Pour partager un cache entre les branches, tout en ayant un cache unique pour chaque job :

```yaml
cache:
  key: $CI_JOB_NAME
```

### Utiliser une variable pour contrôler la politique de cache d'un job {#use-a-variable-to-control-a-jobs-cache-policy}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/371480) dans GitLab 16.1.

{{< /history >}}

Pour éviter la duplication des jobs dont la seule différence est la politique de tirage (pull), vous pouvez utiliser une [variable CI/CD](../variables/_index.md).

Par exemple :

```yaml
conditional-policy:
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      variables:
        POLICY: pull-push
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH
      variables:
        POLICY: pull
  stage: build
  cache:
    key: gems
    policy: $POLICY
    paths:
      - vendor/bundle
  script:
    - echo "This job pulls and pushes the cache depending on the branch"
    - echo "Downloading dependencies..."
```

Dans cet exemple, la politique de cache du job est :

- `pull-push` pour les modifications apportées à la branche par défaut.
- `pull` pour les modifications apportées aux autres branches.

## Dépendances en cache {#cache-dependencies}

Ces exemples montrent comment mettre en cache les dépendances courantes par langage de programmation.

### Node.js {#nodejs}

Si votre projet utilise [npm](https://www.npmjs.com/) pour installer les dépendances Node.js, l'exemple suivant définit un `cache` par défaut afin que tous les jobs en héritent. Par défaut, npm stocke les données de cache dans le dossier personnel (`~/.npm`). Cependant, vous [ne pouvez pas mettre en cache des éléments en dehors du répertoire du projet](../yaml/_index.md#cachepaths). À la place, indiquez à npm d'utiliser `./.npm` et mettez-le en cache par branche :

```yaml
default:
  image: node:latest
  cache:  # Cache modules in between jobs
    key: $CI_COMMIT_REF_SLUG
    paths:
      - .npm/
  before_script:
    - npm ci --cache .npm --prefer-offline

test_async:
  script:
    - node ./specs/start.js ./specs/async.spec.js
```

#### Calculer la clé de cache à partir du fichier de verrouillage {#compute-the-cache-key-from-the-lock-file}

Vous pouvez utiliser [`cache:key:files`](../yaml/_index.md#cachekeyfiles) pour calculer la clé de cache à partir d'un fichier de verrouillage tel que `package-lock.json` ou `yarn.lock`, et la réutiliser dans de nombreux jobs.

```yaml
default:
  cache:  # Cache modules using lock file
    key:
      files:
        - package-lock.json
    paths:
      - .npm/
```

#### Yarn avec miroir hors ligne {#yarn-with-offline-mirror}

Si vous utilisez [Yarn](https://yarnpkg.com/), vous pouvez utiliser [`yarn-offline-mirror`](https://classic.yarnpkg.com/blog/2016/11/24/offline-mirror/) pour mettre en cache les archives tar compressées de `node_modules`. Le cache se génère plus rapidement, car moins de fichiers doivent être compressés :

```yaml
job:
  script:
    - echo 'yarn-offline-mirror ".yarn-cache/"' >> .yarnrc
    - echo 'yarn-offline-mirror-pruning true' >> .yarnrc
    - yarn install --frozen-lockfile --no-progress
  cache:
    key:
      files:
        - yarn.lock
    paths:
      - .yarn-cache/
```

### PHP {#php}

Si votre projet utilise [Composer](https://getcomposer.org/) pour installer les dépendances PHP, l'exemple suivant définit un `cache` par défaut afin que tous les jobs en héritent. Les modules de bibliothèques PHP sont installés dans `vendor/` et mis en cache par branche :

```yaml
default:
  image: php:latest
  cache:  # Cache libraries in between jobs
    key: $CI_COMMIT_REF_SLUG
    paths:
      - vendor/
  before_script:
    # Install and run Composer
    - curl --show-error --silent "https://getcomposer.org/installer" | php
    - php composer.phar install

test:
  script:
    - vendor/bin/phpunit --configuration phpunit.xml --coverage-text --colors=never
```

### Python {#python}

Si votre projet utilise [pip](https://pip.pypa.io/en/stable/) pour installer les dépendances Python, l'exemple suivant définit un `cache` par défaut afin que tous les jobs en héritent. Le cache de pip est défini sous `.cache/pip/` et est mis en cache par branche :

```yaml
default:
  image: python:latest
  cache:                      # Pip's cache doesn't store the python packages
    paths:                    # https://pip.pypa.io/en/stable/topics/caching/
      - .cache/pip
  before_script:
    - python -V               # Print out python version for debugging
    - pip install virtualenv
    - virtualenv venv
    - source venv/bin/activate

variables:  # Change pip's cache directory to be inside the project directory because GitLab can only cache local items.
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

test:
  script:
    - python setup.py test
    - pip install ruff
    - ruff --format=gitlab .
```

### Ruby {#ruby}

Si votre projet utilise [Bundler](https://bundler.io) pour installer les dépendances de gems, l'exemple suivant définit un `cache` par défaut afin que tous les jobs en héritent. Les gems sont installés dans `vendor/ruby/` et mis en cache par branche :

```yaml
default:
  image: ruby:latest
  cache:                                            # Cache gems in between builds
    key: $CI_COMMIT_REF_SLUG
    paths:
      - vendor/ruby
  before_script:
    - ruby -v                                       # Print out ruby version for debugging
    - bundle config set --local path 'vendor/ruby'  # The location to install the specified gems to
    - bundle install -j $(nproc)                    # Install dependencies into ./vendor/ruby

rspec:
  script:
    - rspec spec
```

Si vous avez des jobs nécessitant des gems différents, utilisez le mot-clé `prefix` dans la définition globale de `cache`. Cette configuration génère un cache différent pour chaque job.

Par exemple, un job de test peut ne pas avoir besoin des mêmes gems qu'un job qui déploie en production :

```yaml
default:
  cache:
    key:
      files:
        - Gemfile.lock
      prefix: $CI_JOB_NAME
    paths:
      - vendor/ruby

test_job:
  stage: test
  before_script:
    - bundle config set --local path 'vendor/ruby'
    - bundle install --without production
  script:
    - bundle exec rspec

deploy_job:
  stage: production
  before_script:
    - bundle config set --local path 'vendor/ruby'   # The location to install the specified gems to
    - bundle install --without test
  script:
    - bundle exec deploy
```

### Go {#go}

Si votre projet utilise [Go Modules](https://go.dev/wiki/Modules) pour installer les dépendances Go, l'exemple suivant définit `cache` dans un modèle `go-cache` que tout job peut étendre. Les modules Go sont installés dans `${GOPATH}/pkg/mod/` et mis en cache pour tous les projets `go` :

```yaml
.go-cache:
  variables:
    GOPATH: $CI_PROJECT_DIR/.go
  before_script:
    - mkdir -p .go
  cache:
    paths:
      - .go/pkg/mod/

test:
  image: golang:latest
  extends: .go-cache
  script:
    - go test ./... -v -short
```

## Mettre en cache les artefacts de build et les téléchargements {#cache-build-artifacts-and-downloads}

Ces exemples montrent comment mettre en cache les objets compilés et les fichiers téléchargés pour accélérer les builds.

### Mettre en cache la compilation C/C++ avec Ccache {#cache-cc-compilation-using-ccache}

Si vous compilez des projets C/C++, vous pouvez utiliser [Ccache](https://ccache.dev/) pour accélérer vos temps de build. Ccache accélère la recompilation en mettant en cache les compilations précédentes et en détectant quand la même compilation est effectuée à nouveau. Lors de la compilation de grands projets comme le noyau Linux, vous pouvez vous attendre à des compilations nettement plus rapides.

Utilisez `cache` pour réutiliser le cache créé entre les jobs, par exemple :

```yaml
job:
  cache:
    paths:
      - ccache
  before_script:
    - export PATH="/usr/lib/ccache:$PATH"  # Override compiler path with ccache (this example is for Debian)
    - export CCACHE_DIR="${CI_PROJECT_DIR}/ccache"
    - export CCACHE_BASEDIR="${CI_PROJECT_DIR}"
    - export CCACHE_COMPILERCHECK=content  # Compiler mtime might change in the container, use checksums instead
  script:
    - ccache --zero-stats || true
    - time make                            # Actually build your code while measuring time and cache efficiency.
    - ccache --show-stats || true
```

Si vous avez plusieurs projets dans un seul dépôt, vous n'avez pas besoin d'un `CCACHE_BASEDIR` distinct pour chacun d'eux.

### Mettre en cache les téléchargements avec cURL {#cache-downloads-with-curl}

Si votre projet utilise [cURL](https://curl.se/) pour télécharger des dépendances ou des fichiers, vous pouvez mettre en cache le contenu téléchargé. Les fichiers sont automatiquement mis à jour lorsque des téléchargements plus récents sont disponibles.

```yaml
job:
  script:
    - curl --remote-time --time-cond .curl-cache/caching.md --output .curl-cache/caching.md "https://docs.gitlab.com/ci/caching/"
  cache:
    paths:
      - .curl-cache/
```

Dans cet exemple, cURL télécharge un fichier depuis un serveur web et l'enregistre dans un fichier local dans `.curl-cache/`. L'option `--remote-time` enregistre la date de dernière modification signalée par le serveur, et cURL la compare à l'horodatage du fichier en cache avec `--time-cond`. Si le fichier distant possède un horodatage plus récent, le cache local est automatiquement mis à jour.

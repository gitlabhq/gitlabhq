---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD caching examples
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use caching to avoid downloading dependencies and build artifacts every time a job runs.
Caching speeds up your CI/CD pipelines by reusing previously downloaded content.

For more examples, see the [GitLab CI/CD templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).

## Cache strategies

These examples show different approaches to sharing caches between jobs and branches.

### Share caches between jobs in the same branch

To have jobs in each branch use the same cache, define a cache with the `key: $CI_COMMIT_REF_SLUG`:

```yaml
cache:
  key: $CI_COMMIT_REF_SLUG
```

This configuration prevents you from accidentally overwriting the cache. However, the
first pipeline for a merge request is slow. The next time a commit is pushed to the branch, the
cache is re-used and jobs run faster.

To enable per-job and per-branch caching:

```yaml
cache:
  key: "$CI_JOB_NAME-$CI_COMMIT_REF_SLUG"
```

To enable per-stage and per-branch caching:

```yaml
cache:
  key: "$CI_JOB_STAGE-$CI_COMMIT_REF_SLUG"
```

### Share caches across jobs in different branches

To share a cache across all branches and all jobs, use the same key for everything:

```yaml
cache:
  key: one-key-to-rule-them-all
```

To share a cache between branches, but have a unique cache for each job:

```yaml
cache:
  key: $CI_JOB_NAME
```

### Use a variable to control a job's cache policy

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/371480) in GitLab 16.1.

{{< /history >}}

To reduce duplication of jobs where the only difference is the pull policy, you can use a [CI/CD variable](../variables/_index.md).

For example:

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

In this example, the job's cache policy is:

- `pull-push` for changes to the default branch.
- `pull` for changes to other branches.

## Cache dependencies

These examples show how to cache common dependencies by programming language.

### Node.js

If your project uses [npm](https://www.npmjs.com/) to install Node.js
dependencies, the following example defines a default `cache` so that all jobs inherit it.
By default, npm stores cache data in the home folder (`~/.npm`). However, you
[can't cache things outside of the project directory](../yaml/_index.md#cachepaths).
Instead, tell npm to use `./.npm`, and cache it per-branch:

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

#### Compute the cache key from the lock file

You can use [`cache:key:files`](../yaml/_index.md#cachekeyfiles) to compute the cache
key from a lock file like `package-lock.json` or `yarn.lock`, and reuse it in many jobs.

```yaml
default:
  cache:  # Cache modules using lock file
    key:
      files:
        - package-lock.json
    paths:
      - .npm/
```

#### Yarn with offline mirror

If you're using [Yarn](https://yarnpkg.com/), you can use [`yarn-offline-mirror`](https://classic.yarnpkg.com/blog/2016/11/24/offline-mirror/)
to cache the zipped `node_modules` tarballs. The cache generates more quickly, because
fewer files have to be compressed:

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

### PHP

If your project uses [Composer](https://getcomposer.org/) to install
PHP dependencies, the following example defines a default `cache` so that
all jobs inherit it. PHP libraries modules are installed in `vendor/` and
are cached per-branch:

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

### Python

If your project uses [pip](https://pip.pypa.io/en/stable/) to install
Python dependencies, the following example defines a default `cache` so that
all jobs inherit it. pip's cache is defined under `.cache/pip/` and is cached per-branch:

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

### Ruby

If your project uses [Bundler](https://bundler.io) to install
gem dependencies, the following example defines a default `cache` so that all
jobs inherit it. Gems are installed in `vendor/ruby/` and are cached per-branch:

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

If you have jobs that need different gems, use the `prefix`
keyword in the global `cache` definition. This configuration generates a different
cache for each job.

For example, a testing job might not need the same gems as a job that deploys to
production:

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

### Go

If your project uses [Go Modules](https://go.dev/wiki/Modules) to install
Go dependencies, the following example defines `cache` in a `go-cache` template, that
any job can extend. Go modules are installed in `${GOPATH}/pkg/mod/` and
are cached for all of the `go` projects:

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

## Cache build artifacts and downloads

These examples show how to cache compiled objects and downloaded files to speed up builds.

### Cache C/C++ compilation using Ccache

If you are compiling C/C++ projects, you can use [Ccache](https://ccache.dev/) to
speed up your build times. Ccache speeds up recompilation by caching previous compilations
and detecting when the same compilation is being done again. When building big projects like the Linux kernel,
you can expect significantly faster compilations.

Use `cache` to reuse the created cache between jobs, for example:

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

If you have multiple projects in a single repository you do not need a separate `CCACHE_BASEDIR` for each of them.

### Cache downloads with cURL

If your project uses [cURL](https://curl.se/) to download dependencies or files,
you can cache the downloaded content. The files are automatically updated when
newer downloads are available.

```yaml
job:
  script:
    - curl --remote-time --time-cond .curl-cache/caching.md --output .curl-cache/caching.md "https://docs.gitlab.com/ci/caching/"
  cache:
    paths:
      - .curl-cache/
```

In this example cURL downloads a file from a webserver and saves it to a local file in `.curl-cache/`.
The `--remote-time` flag saves the last modification time reported by the server,
and cURL compares it to the timestamp of the cached file with `--time-cond`. If the remote file has
a more recent timestamp the local cache is automatically updated.

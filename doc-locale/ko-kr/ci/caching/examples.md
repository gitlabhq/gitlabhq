---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 캐싱 예시
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

작업이 실행될 때마다 종속성과 빌드 아티팩트를 다운로드하지 않도록 캐싱을 사용합니다. 캐싱은 이전에 다운로드한 콘텐츠를 재사용하여 CI/CD 파이프라인을 빠르게 합니다.

더 많은 예시를 확인하려면 [GitLab CI/CD 템플릿](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)을 참조하세요.

## 캐시 전략 {#cache-strategies}

이 예시들은 작업과 브랜치 간에 캐시를 공유하는 다양한 방법을 보여줍니다.

### 동일 브랜치의 작업 간 캐시 공유 {#share-caches-between-jobs-in-the-same-branch}

각 브랜치의 작업이 동일한 캐시를 사용하도록 하려면 `key: $CI_COMMIT_REF_SLUG`을 사용하여 캐시를 정의하세요:

```yaml
cache:
  key: $CI_COMMIT_REF_SLUG
```

이 구성은 실수로 캐시를 덮어쓰는 것을 방지합니다. 그러나 머지 리퀘스트의 첫 파이프라인은 느립니다. 브랜치에 커밋이 푸시되면 다음번에는 캐시가 재사용되고 작업이 더 빨리 실행됩니다.

작업별 및 브랜치별 캐싱을 활성화하려면:

```yaml
cache:
  key: "$CI_JOB_NAME-$CI_COMMIT_REF_SLUG"
```

스테이지별 및 브랜치별 캐싱을 활성화하려면:

```yaml
cache:
  key: "$CI_JOB_STAGE-$CI_COMMIT_REF_SLUG"
```

### 다양한 브랜치의 작업 간 캐시 공유 {#share-caches-across-jobs-in-different-branches}

모든 브랜치와 모든 작업 간에 캐시를 공유하려면 모든 항목에 동일한 키를 사용하세요:

```yaml
cache:
  key: one-key-to-rule-them-all
```

브랜치 간에는 캐시를 공유하되 각 작업마다 고유한 캐시를 사용하려면:

```yaml
cache:
  key: $CI_JOB_NAME
```

### CI/CD 변수를 사용하여 작업의 캐시 정책 제어 {#use-a-variable-to-control-a-jobs-cache-policy}

{{< history >}}

- [GitLab 16.1에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/371480).

{{< /history >}}

풀 정책이 유일한 차이인 작업의 중복을 줄이려면 [CI/CD 변수](../variables/_index.md)를 사용할 수 있습니다.

예를 들어:

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

이 예시에서 작업의 캐시 정책은 다음과 같습니다:

- `pull-push` - 기본 브랜치에 대한 변경사항입니다.
- `pull` - 다른 브랜치에 대한 변경사항입니다.

## 캐시 종속성 {#cache-dependencies}

이 예시들은 프로그래밍 언어별로 일반적인 종속성을 캐싱하는 방법을 보여줍니다.

### Node.js {#nodejs}

프로젝트에서 [npm](https://www.npmjs.com/)을 사용하여 Node.js 종속성을 설치하는 경우, 다음 예시에서는 모든 작업이 이를 상속하도록 기본 `cache`을 정의합니다. 기본적으로 npm은 캐시 데이터를 홈 폴더(`~/.npm`)에 저장합니다. 그러나 [프로젝트 디렉토리 외부의 항목을 캐싱할 수 없습니다](../yaml/_index.md#cachepaths). 대신 npm에서 `./.npm`을 사용하도록 지정하고 브랜치별로 캐싱하세요:

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

#### 잠금 파일에서 캐시 키 계산 {#compute-the-cache-key-from-the-lock-file}

[`cache:key:files`](../yaml/_index.md#cachekeyfiles)를 사용하여 `package-lock.json` 또는 `yarn.lock`와 같은 잠금 파일에서 캐시 키를 계산하고 많은 작업에서 재사용할 수 있습니다.

```yaml
default:
  cache:  # Cache modules using lock file
    key:
      files:
        - package-lock.json
    paths:
      - .npm/
```

#### 오프라인 미러가 포함된 Yarn {#yarn-with-offline-mirror}

[Yarn](https://yarnpkg.com/)을 사용하는 경우 [`yarn-offline-mirror`](https://classic.yarnpkg.com/blog/2016/11/24/offline-mirror/)를 사용하여 압축된 `node_modules` 타르볼을 캐싱할 수 있습니다. 더 적은 파일을 압축해야 하므로 캐시가 더 빠르게 생성됩니다:

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

프로젝트에서 [Composer](https://getcomposer.org/)를 사용하여 PHP 종속성을 설치하는 경우, 다음 예시에서는 모든 작업이 이를 상속하도록 기본 `cache`을 정의합니다. PHP 라이브러리 모듈은 `vendor/`에 설치되며 브랜치별로 캐싱됩니다:

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

프로젝트에서 [pip](https://pip.pypa.io/en/stable/)을 사용하여 Python 종속성을 설치하는 경우, 다음 예시에서는 모든 작업이 이를 상속하도록 기본 `cache`을 정의합니다. pip의 캐시는 `.cache/pip/`에 정의되어 있으며 브랜치별로 캐싱됩니다:

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

프로젝트에서 [Bundler](https://bundler.io)를 사용하여 gem 종속성을 설치하는 경우, 다음 예시에서는 모든 작업이 이를 상속하도록 기본 `cache`을 정의합니다. Gem은 `vendor/ruby/`에 설치되며 브랜치별로 캐싱됩니다:

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

다양한 gem이 필요한 작업이 있는 경우 전역 `cache` 정의에서 `prefix` 키워드를 사용하세요. 이 구성은 각 작업에 대해 다른 캐시를 생성합니다.

예를 들어, 테스트 작업은 프로덕션에 배포하는 작업과 동일한 gem이 필요하지 않을 수 있습니다:

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

프로젝트에서 [Go Modules](https://go.dev/wiki/Modules)을 사용하여 Go 종속성을 설치하는 경우, 다음 예시에서는 모든 작업이 확장할 수 있는 `go-cache` 템플릿에서 `cache`을 정의합니다. Go 모듈은 `${GOPATH}/pkg/mod/`에 설치되며 모든 `go` 프로젝트에 대해 캐싱됩니다:

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

## 빌드 아티팩트와 다운로드 캐싱 {#cache-build-artifacts-and-downloads}

이 예시들은 빌드를 빠르게 하기 위해 컴파일된 객체와 다운로드된 파일을 캐싱하는 방법을 보여줍니다.

### Ccache를 사용한 C/C++ 컴파일 캐싱 {#cache-cc-compilation-using-ccache}

C/C++ 프로젝트를 컴파일하는 경우 [Ccache](https://ccache.dev/)를 사용하여 빌드 시간을 단축할 수 있습니다. Ccache는 이전 컴파일을 캐싱하고 동일한 컴파일이 다시 수행되는 시점을 감지하여 재컴파일을 빠르게 합니다. Linux 커널과 같은 큰 프로젝트를 빌드할 때 상당히 더 빠른 컴파일을 기대할 수 있습니다.

`cache`을 사용하여 작업 간에 생성된 캐시를 재사용하세요. 예를 들어:

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

단일 리포지토리에 여러 프로젝트가 있는 경우 각각에 대해 별도의 `CCACHE_BASEDIR`이 필요하지 않습니다.

### cURL을 사용한 다운로드 캐싱 {#cache-downloads-with-curl}

프로젝트에서 [cURL](https://curl.se/)을 사용하여 종속성 또는 파일을 다운로드하는 경우 다운로드한 콘텐츠를 캐싱할 수 있습니다. 파일은 새로운 다운로드를 사용할 수 있을 때 자동으로 업데이트됩니다.

```yaml
job:
  script:
    - curl --remote-time --time-cond .curl-cache/caching.md --output .curl-cache/caching.md "https://docs.gitlab.com/ci/caching/"
  cache:
    paths:
      - .curl-cache/
```

이 예시에서 cURL은 웹서버에서 파일을 다운로드하여 `.curl-cache/`의 로컬 파일에 저장합니다. `--remote-time` 플래그는 서버에서 보고한 마지막 수정 시간을 저장하며, cURL은 `--time-cond`을 사용하여 캐시된 파일의 타임스탬프와 비교합니다. 원격 파일의 타임스탬프가 더 최근이면 로컬 캐시가 자동으로 업데이트됩니다.

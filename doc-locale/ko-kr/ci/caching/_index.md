---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab CI/CD에서 캐싱을 사용하여 작업과 파이프라인에 걸쳐 종속성을 다운로드합니다.
title: GitLab CI/CD의 캐싱
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

캐시는 작업이 다운로드하고 저장하는 하나 이상의 파일입니다. 같은 캐시를 사용하는 후속 작업은 파일을 다시 다운로드할 필요가 없으므로 더 빠르게 실행됩니다.

`.gitlab-ci.yml`.gitlab-ci.yml 파일에서 캐시를 정의하는 방법을 알아보려면 [`cache`cache 참조를 참조하세요.](../yaml/_index.md#cache)

고급 캐시 키 전략의 경우 다음을 사용할 수 있습니다:

- [`cache:key:files`](../yaml/_index.md#cachekeyfiles): 특정 파일의 콘텐츠에 연결된 키를 생성합니다.
- [`cache:key:files_commits`](../yaml/_index.md#cachekeyfiles_commits): 특정 파일의 최신 커밋에 연결된 키를 생성합니다.

더 많은 사용 사례와 예제는 [CI/CD 캐싱 예제](examples.md)를 참조하세요.

## 캐시가 성과물과 다른 점 {#how-cache-is-different-from-artifacts}

인터넷에서 다운로드한 패키지와 같은 종속성에 캐시를 사용합니다. 캐시는 GitLab Runner가 설치된 곳에 저장되며, [분산 캐시가 활성화된](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching) 경우 S3에 업로드됩니다.

성과물을 사용하여 중간 빌드 결과를 스테이지 간에 전달합니다. 성과물은 작업으로 생성되고, GitLab에 저장되며, 다운로드할 수 있습니다.

성과물과 캐시 모두 프로젝트 디렉터리에 상대적인 경로를 정의하며, 이 디렉터리 외부의 파일에 연결할 수 없습니다.

### 캐시 {#cache}

- `cache` 키워드를 사용하여 작업마다 캐시를 정의합니다. 그렇지 않으면 비활성화됩니다.
- 후속 파이프라인은 캐시를 사용할 수 있습니다.
- 같은 파이프라인의 후속 작업은 종속성이 동일한 경우 캐시를 사용할 수 있습니다.
- 다른 프로젝트는 캐시를 공유할 수 없습니다.
- 기본적으로 보호된 브랜치와 보호되지 않은 [브랜치는 캐시를 공유하지 않습니다](#cache-key-names). 그러나 [이 동작을 변경할](#use-the-same-cache-for-all-branches) 수 있습니다.

### 성과물 {#artifacts}

- 작업마다 성과물을 정의합니다.
- 같은 파이프라인의 후속 스테이지의 후속 작업은 성과물을 사용할 수 있습니다.
- 성과물은 기본적으로 30일 후에 만료됩니다. 사용자 지정 [만료 시간](../yaml/_index.md#artifactsexpire_in)을 정의할 수 있습니다.
- [최신 성과물 유지](../jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)가 활성화되어 있으면 최신 성과물은 만료되지 않습니다.
- [종속성](../yaml/_index.md#dependencies)을 사용하여 어느 작업이 성과물을 가져올지 제어합니다.

## 좋은 캐싱 관행 {#good-caching-practices}

캐시의 최대 가용성을 보장하려면 다음 중 하나 이상을 수행합니다:

- [러너에 태그를 지정](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)하고 캐시를 공유하는 작업에 태그를 사용합니다.
- [특정 프로젝트에만 사용 가능한 러너를 사용](../runners/runners_scope.md#prevent-a-project-runner-from-being-enabled-for-other-projects)합니다.
- [`key`를 사용](../yaml/_index.md#cachekey)하여 워크플로에 맞게 합니다. 예를 들어, 각 브랜치마다 다른 캐시를 구성할 수 있습니다.

러너가 캐시와 효율적으로 작동하려면 다음 중 하나를 수행해야 합니다:

- 모든 작업에 단일 러너를 사용합니다.
- [분산 캐싱](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching)이 있는 여러 러너를 사용합니다. 여기서 캐시는 S3 버킷에 저장됩니다. GitLab.com의 인스턴스 러너는 이런 방식으로 동작합니다. 이 러너는 자동 확장 모드일 수 있지만, 반드시 그럴 필요는 없습니다. 캐시 객체를 관리하려면 캐시 객체를 일정 시간 후 삭제하는 수명 주기 규칙을 적용합니다. 수명 주기 규칙은 객체 저장소 서버에서 사용 가능합니다.
- 같은 아키텍처를 가진 여러 러너를 사용하고 이 러너가 공통 네트워크 마운트 디렉터리를 공유하도록 하여 캐시를 저장합니다. 이 디렉터리는 NFS 또는 유사한 것을 사용해야 합니다. 이 러너는 자동 확장 모드여야 합니다.

## 여러 캐시 사용 {#use-multiple-caches}

작업당 최대 4개의 캐시를 가질 수 있습니다:

```yaml
test-job:
  stage: build
  cache:
    - key:
        files:
          - Gemfile.lock
      paths:
        - vendor/ruby
    - key:
        files:
          - yarn.lock
      paths:
        - .yarn-cache/
  script:
    - bundle config set --local path 'vendor/ruby'
    - bundle install
    - yarn install --cache-folder .yarn-cache
    - echo Run tests...
```

여러 캐시가 폴백 캐시 키와 결합되면 캐시를 찾지 못할 때마다 전역 폴백 캐시를 가져옵니다.

## 폴백 캐시 키 사용 {#use-a-fallback-cache-key}

### 캐시별 폴백 키 {#per-cache-fallback-keys}

{{< history >}}

- GitLab 16.0에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110467).

{{< /history >}}

각 캐시 항목은 [`fallback_keys` 키워드](../yaml/_index.md#cachefallback_keys)로 최대 5개의 폴백 키를 지원합니다. 작업이 캐시 키를 찾지 못하면 작업은 폴백 캐시를 검색하려고 시도합니다. 폴백 키는 캐시를 찾을 때까지 순서대로 검색됩니다. 캐시를 찾지 못하면 작업은 캐시를 사용하지 않고 실행됩니다. 예를 들어:

```yaml
test-job:
  stage: build
  cache:
    - key: cache-$CI_COMMIT_REF_SLUG
      fallback_keys:
        - cache-$CI_DEFAULT_BRANCH
        - cache-default
      paths:
        - vendor/ruby
  script:
    - bundle config set --local path 'vendor/ruby'
    - bundle install
    - echo Run tests...
```

이 예에서:

1. 작업은 `cache-$CI_COMMIT_REF_SLUG` 캐시를 찾습니다.
1. `cache-$CI_COMMIT_REF_SLUG`을 찾지 못하면 작업은 `cache-$CI_DEFAULT_BRANCH`을 폴백 옵션으로 찾습니다.
1. `cache-$CI_DEFAULT_BRANCH`도 찾지 못하면 작업은 `cache-default`을 두 번째 폴백 옵션으로 찾습니다.
1. 찾지 못하면 작업은 캐시를 사용하지 않고 모든 Ruby 종속성을 다운로드하지만 작업이 완료되면 `cache-$CI_COMMIT_REF_SLUG`에 대한 새 캐시를 생성합니다.

폴백 키는 `cache:key`과 같은 처리 논리를 따릅니다:

- [캐시를 수동으로 지우면](#clear-the-cache-manually), 캐시별 폴백 키는 다른 캐시 키처럼 인덱스로 추가됩니다.
- [**보호된 브랜치에 별도의 캐시 사용** 설정](#cache-key-names)이 활성화되면 캐시별 폴백 키는 `-protected` 또는 `-non_protected`로 추가됩니다.

### 전역 폴백 키 {#global-fallback-key}

`$CI_COMMIT_REF_SLUG` [사전 정의된 변수](../variables/predefined_variables.md)를 사용하여 [`cache:key`](../yaml/_index.md#cachekey)를 지정할 수 있습니다. 예를 들어, `$CI_COMMIT_REF_SLUG`가 `test`이면 `test`로 태그가 지정된 캐시를 다운로드하도록 작업을 설정할 수 있습니다.

이 태그가 있는 캐시를 찾지 못하면 `CACHE_FALLBACK_KEY`을 사용하여 없을 때 사용할 캐시를 지정할 수 있습니다.

다음 예제에서 `$CI_COMMIT_REF_SLUG`을 찾지 못하면 작업은 `CACHE_FALLBACK_KEY` 변수로 정의된 키를 사용합니다:

```yaml
variables:
  CACHE_FALLBACK_KEY: fallback-key

job1:
  script:
    - echo
  cache:
    key: "$CI_COMMIT_REF_SLUG"
    paths:
      - binaries/
```

캐시 추출 순서는 다음과 같습니다:

1. `cache:key`에 대한 검색 시도
1. `fallback_keys`의 각 항목을 순서대로 검색 시도
1. `CACHE_FALLBACK_KEY`의 전역 폴백 키에 대한 검색 시도

캐시 추출 프로세스는 첫 번째 성공적인 캐시를 검색한 후 중지됩니다.

## 특정 작업에 대해 캐시 비활성화 {#disable-cache-for-specific-jobs}

캐시를 전역적으로 정의하면 각 작업은 같은 정의를 사용합니다. 각 작업에 대해 이 동작을 무시할 수 있습니다.

작업에 대해 완전히 비활성화하려면 빈 목록을 사용합니다:

```yaml
job:
  cache: []
```

## 전역 구성을 상속하되 작업당 특정 설정 무시 {#inherit-global-configuration-but-override-specific-settings-per-job}

[앵커](../yaml/yaml_optimization.md#anchors)를 사용하여 전역 캐시를 덮어쓰지 않고 캐시 설정을 재정의할 수 있습니다. 예를 들어, 한 작업에 대해 `policy`를 무시하려면:

```yaml
default:
  cache: &global_cache
    key: $CI_COMMIT_REF_SLUG
    paths:
      - node_modules/
      - public/
      - vendor/
    policy: pull-push

job:
  cache:
    # inherit all global cache settings
    <<: *global_cache
    # override the policy
    policy: pull
```

자세한 내용은 [`cache: policy`](../yaml/_index.md#cachepolicy)를 참조하세요.

## 캐시 키 이름 {#cache-key-names}

{{< history >}}

- GitLab 15.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/330047)되었습니다.
- `-protected`-protected 접미사는 관리자 역할 이상에 대해 GitLab 18.4.5에서 [도입되었습니다](https://about.gitlab.com/releases/2025/11/26/patch-release-gitlab-18-6-1-released/).

{{< /history >}}

[전역 폴백 캐시 키](#global-fallback-key)를 제외하고 캐시 키에 접미사가 추가됩니다.

캐시 키는 파이프라인이 다음인 경우 `-protected` 접미사를 받습니다:

- 보호된 브랜치 또는 태그에 대해 실행됩니다. 사용자는 [보호된 브랜치](../../user/project/repository/branches/protected.md)에 병합할 권한이 있거나 [보호된 태그](../../user/project/protected_tags.md)를 생성할 권한이 있어야 합니다.
- 관리자 또는 소유자 역할을 가진 사용자가 시작했습니다.

다른 파이프라인에서 생성된 키는 `non_protected` 접미사를 받습니다.

예를 들어, 다음과 같은 경우:

- `cache:key`은(는) `$CI_COMMIT_REF_SLUG`로 설정됩니다.
- `main`은(는) 보호된 브랜치입니다.
- `feature`은(는) 보호되지 않은 브랜치입니다.

| 브랜치      | 개발자 역할 캐시 키 | 관리자 역할 캐시 키 |
|-------------|--------------------------|---------------------------|
| `main`      | `main-protected`         | `main-protected`          |
| `feature`   | `feature-non_protected`  | `feature-protected`       |

또한 태그에 대한 파이프라인의 경우 태그의 보호 상태가 파이프라인이 실행되는 브랜치가 아닌 접미사에 우선합니다. 이 동작은 트리거하는 참조가 캐시 액세스 권한을 결정하기 때문에 일관된 보안 경계를 보장합니다.

예를 들어, 다음과 같은 경우:

- `cache:key`은(는) `$CI_COMMIT_TAG`로 설정됩니다.
- `main`은(는) 보호된 브랜치입니다.
- `feature`은(는) 보호되지 않은 브랜치입니다.
- `1.0.0`은(는) 보호된 태그입니다.
- `1.1.1-rc1`은(는) 보호되지 않은 태그입니다.

| 태그         | 브랜치    | 개발자 역할 캐시 키  | 관리자 역할 캐시 키 |
|-------------|-----------|---------------------------|---------------------------|
| `1.0.0`     | `main`    | `1.0.0-protected`         | `1.0.0-protected`         |
| `1.0.0`     | `feature` | `1.0.0-protected`         | `1.0.0-protected`         |
| `1.1.1-rc1` | `main`    | `1.1.1-rc1-non_protected` | `1.1.1-rc1-protected`     |
| `1.1.1-rc1` | `feature` | `1.1.1-rc1-non_protected` | `1.1.1-rc1-protected`     |

### 모든 브랜치에 대해 같은 캐시 사용 {#use-the-same-cache-for-all-branches}

{{< history >}}

- GitLab 15.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/361643)되었습니다.

{{< /history >}}

[캐시 키 이름](#cache-key-names)을 사용하지 않으려면 모든 브랜치(보호된 것과 보호되지 않은 것)가 같은 캐시를 사용하도록 할 수 있습니다.

[캐시 키 이름](#cache-key-names)을 사용한 캐시 분리는 보안 기능이며 개발자 역할의 모든 사용자가 높은 신뢰성을 가진 환경에서만 비활성화되어야 합니다.

모든 브랜치에 대해 같은 캐시를 사용하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **일반 파이프라인**을 확장합니다.
1. **보호된 브랜치에 별도의 캐시 사용** 체크박스를 지웁니다.
1. **변경사항 저장**을 선택합니다.

## 캐시의 가용성 {#availability-of-the-cache}

캐싱은 최적화이지만 항상 작동하도록 보장되지는 않습니다. 필요한 각 작업에서 캐시된 파일을 재생성해야 할 수 있습니다.

[`.gitlab-ci.yml`에서 캐시를 정의](../yaml/_index.md#cache)한 후 캐시의 가용성은 다음에 따릅니다:

- 러너의 실행기 유형입니다.
- 다른 러너를 작업 간에 캐시를 전달하는 데 사용하는지 여부입니다.

### 캐시가 저장된 위치 {#where-the-caches-are-stored}

작업에 대해 정의된 모든 캐시는 단일 `cache.zip` 파일로 아카이브됩니다. 러너 구성은 파일이 저장되는 위치를 정의합니다. 기본적으로 캐시는 러너가 설치된 머신에 저장됩니다. 위치는 실행기 유형에 따라 다릅니다.

| 러너 실행기        | 캐시의 기본 경로 |
| ---------------------- | ------------------------- |
| [Shell](https://docs.gitlab.com/runner/executors/shell/) | 로컬, `gitlab-runner` 사용자의 홈 디렉터리 아래: `/home/gitlab-runner/cache/<user>/<project>/<cache-key>/cache.zip`. |
| [Docker](https://docs.gitlab.com/runner/executors/docker/) | 로컬, [Docker 볼륨](https://docs.gitlab.com/runner/executors/docker/#configure-directories-for-the-container-build-and-cache) 아래: `/var/lib/docker/volumes/<volume-id>/_data/<user>/<project>/<cache-key>/cache.zip`. |
| [Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine/) (자동 확장 러너) | Docker 실행기와 동일합니다. |

캐시와 성과물을 작업에서 같은 경로에 저장하려면 성과물 전에 캐시가 복원되기 때문에 캐시가 덮어씌워질 수 있습니다.

### 아카이빙 및 추출 작동 방식 {#how-archiving-and-extracting-works}

이 예제는 두 개의 연속 스테이지에서 두 개의 작업을 보여줍니다:

```yaml
stages:
  - build
  - test

default:
  cache:
    key: build-cache
    paths:
      - vendor/
  before_script:
    - echo "Hello"

job A:
  stage: build
  script:
    - mkdir vendor/
    - echo "build" > vendor/hello.txt
  after_script:
    - echo "World"

job B:
  stage: test
  script:
    - cat vendor/hello.txt
```

한 머신에 한 러너가 설치되어 있으면 프로젝트의 모든 작업이 같은 호스트에서 실행됩니다:

1. 파이프라인이 시작됩니다.
1. `job A`이 실행됩니다.
1. 캐시가 추출됩니다(찾은 경우).
1. `before_script`이 실행됩니다.
1. `script`이 실행됩니다.
1. `after_script`이 실행됩니다.
1. `cache`이 실행되고 `vendor/` 디렉터리가 `cache.zip`으로 압축됩니다. 이 파일은 [러너 설정](#where-the-caches-are-stored)과 `cache: key`을 기반으로 디렉터리에 저장됩니다.
1. `job B`이 실행됩니다.
1. 캐시가 추출됩니다(찾은 경우).
1. `before_script`이 실행됩니다.
1. `script`이 실행됩니다.
1. 파이프라인이 끝납니다.

한 머신에서 단일 러너를 사용하면 `job B`이 `job A`와 다른 러너에서 실행될 수 있는 문제가 없습니다. 이 설정은 캐시를 스테이지 간에 재사용할 수 있도록 보장합니다. 실행이 같은 러너/머신에서 `build` 스테이지에서 `test` 스테이지로 진행되는 경우에만 작동합니다. 그렇지 않으면 캐시를 [사용할 수 없을 수 있습니다](#cache-mismatch).

캐싱 프로세스 중에도 고려해야 할 몇 가지 사항이 있습니다:

- 다른 캐시 구성을 가진 다른 작업이 같은 zip 파일에 캐시를 저장했다면 덮어씌워집니다. S3 기반 공유 캐시를 사용하면 파일은 추가로 캐시 키를 기반으로 객체에 S3에 업로드됩니다. 따라서 경로는 다르지만 같은 캐시 키를 가진 두 작업은 캐시를 덮어씁니다.
- `cache.zip`에서 캐시를 추출할 때 zip 파일의 모든 것이 작업의 작업 디렉터리(일반적으로 다운로드된 리포지토리)에 추출되고, 러너는 `job A`의 아카이브가 `job B`의 아카이브를 덮어쓰는 것을 신경 쓰지 않습니다.

한 러너에 대해 생성된 캐시는 다른 것이 사용할 때 유효하지 않은 경우가 많기 때문에 이렇게 작동합니다. 다른 러너는 다른 아키텍처에서 실행될 수 있습니다(예: 캐시에 이진 파일이 포함된 경우). 또한 다양한 단계가 다른 머신에서 실행되는 러너에 의해 실행될 수 있기 때문에 안전한 기본값입니다.

## 캐시 지우기 {#clearing-the-cache}

러너는 [캐시](../yaml/_index.md#cache)를 사용하여 기존 데이터를 재사용함으로써 작업 실행을 가속화합니다. 이는 때때로 일관성 없는 동작으로 이어질 수 있습니다.

캐시의 새로운 복사본으로 시작하는 두 가지 방법이 있습니다.

### `cache:key` 변경으로 캐시 지우기 {#clear-the-cache-by-changing-cachekey}

`cache: key` 값을 `.gitlab-ci.yml` 파일에서 변경합니다. 다음번 파이프라인이 실행되면 캐시는 다른 위치에 저장됩니다.

### 캐시를 수동으로 지우기 {#clear-the-cache-manually}

GitLab UI에서 캐시를 지울 수 있습니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. 오른쪽 상단 모서리에서 **러너 캐시 지우기**를 선택합니다.

다음 커밋에서 CI/CD 작업은 새 캐시를 사용합니다.

> [!note]
> 캐시를 수동으로 지울 때마다 [내부 캐시 이름](#where-the-caches-are-stored)이 업데이트됩니다. 이름은 `cache-<index>` 형식을 사용하며 인덱스는 1씩 증가합니다. 이전 캐시는 삭제되지 않습니다. 러너 저장소에서 이 파일을 수동으로 삭제할 수 있습니다.

## 문제 해결 {#troubleshooting}

### 캐시 불일치 {#cache-mismatch}

캐시 불일치가 있으면 다음 단계를 따라 문제를 해결합니다.

| 캐시 불일치 이유 | 해결 방법 |
| --------------------------- | ------------- |
| 공유 캐시 없이 한 프로젝트에 연결된 여러 독립 실행형 러너(자동 확장 모드가 아닌)를 사용합니다. | 프로젝트에 단일 러너만 사용하거나 분산 캐시가 활성화된 여러 러너를 사용합니다. |
| 분산 캐시가 활성화되지 않은 자동 확장 모드에서 러너를 사용합니다. | 분산 캐시를 사용하도록 자동 확장 러너를 구성합니다. |
| 러너가 설치된 머신의 디스크 공간이 부족하거나, 분산 캐시를 설정한 경우 캐시가 저장된 S3 버킷의 공간이 부족합니다. | 새로운 캐시를 저장할 수 있도록 일부 공간을 비우도록 합니다. 이를 수행하는 자동 방법이 없습니다. |
| 캐시 경로가 다른 작업에 같은 `key`을 사용합니다. | 다른 캐시 키를 사용하여 캐시 아카이브가 다른 위치에 저장되고 잘못된 캐시를 덮어쓰지 않도록 합니다. |
| 러너에서 [분산 러너 캐싱을 활성화](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching)하지 않았습니다. | `Shared = false`을 설정하고 러너를 다시 프로비전합니다. |

#### 캐시 불일치 예제 1 {#cache-mismatch-example-1}

프로젝트에 할당된 러너가 하나만 있으면 캐시는 기본적으로 러너의 머신에 저장됩니다.

두 작업의 캐시 키가 같지만 경로가 다르면 캐시가 덮어씌워질 수 있습니다. 예를 들어:

```yaml
stages:
  - build
  - test

job A:
  stage: build
  script: make build
  cache:
    key: same-key
    paths:
      - public/

job B:
  stage: test
  script: make test
  cache:
    key: same-key
    paths:
      - vendor/
```

1. `job A`이 실행됩니다.
1. `public/`이 `cache.zip`로 캐시됩니다.
1. `job B`이 실행됩니다.
1. 이전 캐시(있는 경우)가 압축 해제됩니다.
1. `vendor/`이 `cache.zip`로 캐시되고 이전 것을 덮어씁니다.
1. 다음 번 `job A`이 실행되면 `job B`의 캐시를 사용하므로 효과적이지 않습니다.

이 문제를 해결하려면 각 작업에 다른 `keys`을 사용합니다.

#### 캐시 불일치 예제 2 {#cache-mismatch-example-2}

이 예제에서 프로젝트에 할당된 러너가 하나 이상 있고 분산 캐시가 활성화되지 않습니다.

두 번째로 파이프라인이 실행되면 `job A`과 `job B`가 캐시를 재사용하기를 원합니다(이 경우 다릅니다):

```yaml
stages:
  - build
  - test

job A:
  stage: build
  script: build
  cache:
    key: keyA
    paths:
      - vendor/

job B:
  stage: test
  script: test
  cache:
    key: keyB
    paths:
      - vendor/
```

`key`이 다르더라도 작업이 후속 파이프라인에서 다른 러너에서 실행되면 각 스테이지 전에 캐시된 파일이 "정리"될 수 있습니다.

### 동시 러너 캐시 누락 {#concurrent-runners-missing-local-cache}

Docker 실행기를 사용하여 여러 동시 러너를 구성한 경우 동시에 실행되는 작업에 대해 로컬 캐시된 파일이 예상대로 없을 수 있습니다. 캐시 볼륨의 이름은 각 러너 인스턴스에 대해 고유하게 구성되므로 한 러너 인스턴스가 캐시한 파일은 다른 러너 인스턴스의 캐시에 없습니다.

동시 러너 간에 캐시를 공유하려면 다음 중 하나를 수행할 수 있습니다:

- 러너의 `[runners.docker]` 섹션을 `config.toml`에서 사용하여 호스트의 단일 마운트 지점을 구성합니다. 이는 각 컨테이너의 `/cache`에 매핑되며, `volumes = ["/mnt/gitlab-runner/cache-for-all-concurrent-jobs:/cache"]`과 같습니다. 이 방법은 러너가 동시 작업에 대한 고유한 볼륨 이름을 만드는 것을 방지합니다.
- 분산 캐시를 사용합니다.

---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD YAML 구문 참고
description: "파이프라인 구성 키워드, 구문, 예제 및 입력."
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 문서는 GitLab `.gitlab-ci.yml` 파일의 구성 옵션을 나열합니다. 이 파일은 파이프라인을 구성하는 CI/CD 작업을 정의하는 위치입니다.

- [기본 CI/CD 개념](../_index.md)에 이미 익숙한 경우 자습서를 따라 `.gitlab-ci.yml` 파일을 직접 만들어보세요. 이 자습서는 [간단한](../quick_start/_index.md) 또는 [복잡한](../quick_start/tutorial.md) 파이프라인을 보여줍니다.
- 예제 모음은 [GitLab CI/CD 예제](../examples/_index.md)를 참조하세요.
- 엔터프라이즈에서 사용되는 대규모 `.gitlab-ci.yml` 파일을 보려면 [`.gitlab-ci.yml` for `gitlab`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab-ci.yml)를 참조하세요.

`.gitlab-ci.yml` 파일을 편집할 때 [CI Lint](lint.md) 도구로 유효성을 검사할 수 있습니다.

GitLab CI/CD 구성은 YAML 형식을 사용하므로, 달리 지정하지 않는 한 키워드의 순서는 중요하지 않습니다.

더 동적인 파이프라인 구성 옵션을 위해 [CI/CD 표현식](expressions.md)을 사용하세요.

<!--
If you are editing content on this page, follow the instructions for documenting keywords:
<https://docs.gitlab.com/development/cicd/cicd_reference_documentation_guide/>
-->

## 키워드 {#keywords}

GitLab CI/CD 파이프라인 구성에는 다음이 포함됩니다:

- 파이프라인 동작을 구성하는 [전역 키워드](#global-keywords):

  | 키워드                           | 설명 |
  |-----------------------------------|:------------|
  | [`default`](#default)             | 작업 키워드의 사용자 정의 기본값입니다. |
  | [`include`](#include)             | 다른 YAML 파일에서 구성을 가져옵니다. |
  | [`stages`](#stages)               | 파이프라인 스테이지의 이름 및 순서입니다. |
  | [`variables`](#default-variables) | 파이프라인의 모든 작업에 대한 기본 CI/CD 변수를 정의합니다. |
  | [`workflow`](#workflow)           | 파이프라인이 실행되는 유형을 제어합니다. |

- [헤더 키워드](#header-keywords)

  | 키워드         | 설명 |
  |-----------------|:------------|
  | [`spec`](#spec) | 외부 구성 파일에 대한 사양을 정의합니다. |

- [작업](../jobs/_index.md)은 [작업 키워드](#job-keywords)로 구성됩니다:

  | 키워드                                       | 설명 |
  |:----------------------------------------------|:------------|
  | [`after_script`](#after_script)               | 작업 후 실행되는 명령 집합을 재정의합니다. |
  | [`allow_failure`](#allow_failure)             | 작업이 실패하도록 허용합니다. 실패한 작업은 파이프라인이 실패하지 않습니다. |
  | [`artifacts`](#artifacts)                     | 작업이 성공할 때 첨부할 파일 및 디렉터리 목록입니다. |
  | [`before_script`](#before_script)             | 작업 전에 실행되는 명령 집합을 재정의합니다. |
  | [`cache`](#cache)                             | 후속 실행 사이에 캐시해야 할 파일 목록입니다. |
  | [`coverage`](#coverage)                       | 지정된 작업에 대한 코드 커버리지 설정입니다. |
  | [`dast_configuration`](#dast_configuration)   | 작업 수준에서 DAST 프로필의 구성을 사용합니다. |
  | [`dependencies`](#dependencies)               | 페칭할 작업의 목록을 제공하여 특정 작업에 전달되는 아티팩트를 제한합니다. |
  | [`environment`](#environment)                 | 작업이 배포하는 환경의 이름입니다. |
  | [`extends`](#extends)                         | 이 작업이 상속하는 구성 항목입니다. |
  | [`identity`](#identity)                       | ID 페더레이션을 사용하여 타사 서비스를 인증합니다. |
  | [`image`](#image)                             | Docker 이미지를 사용합니다. |
  | [`inherit`](#inherit)                         | 모든 작업이 상속하는 전역 기본값을 선택합니다. |
  | [`interruptible`](#interruptible)             | 최신 실행으로 인해 중복된 작업이 취소될 수 있는지를 정의합니다. |
  | [`manual_confirmation`](#manual_confirmation) | 수동 작업을 위한 사용자 정의 확인 메시지를 정의합니다. |
  | [`needs`](#needs)                             | 스테이지 순서보다 먼저 작업을 실행합니다. |
  | [`pages`](#pages)                             | 작업의 결과를 업로드하여 GitLab Pages에서 사용합니다. |
  | [`parallel`](#parallel)                       | 작업의 인스턴스가 병렬로 실행되어야 하는 개수입니다. |
  | [`release`](#release)                         | 러너에 [릴리스](../../user/project/releases/_index.md) 객체를 생성하도록 지시합니다. |
  | [`resource_group`](#resource_group)           | 작업 동시성을 제한합니다. |
  | [`retry`](#retry)                             | 실패 시 작업이 자동으로 재시도될 수 있는 빈도입니다. |
  | [`rules`](#rules)                             | 작업의 선택된 속성을 평가하고 결정하며, 작업이 생성되는지 여부를 결정하는 조건 목록입니다. |
  | [`script`](#script)                           | 러너가 실행하는 셸 스크립트입니다. |
  | [`run`](#run)                                 | 러너가 실행하는 구성을 실행합니다. |
  | [`secrets`](#secrets)                         | 작업이 필요한 CI/CD 암호입니다. |
  | [`services`](#services)                       | Docker 서비스 이미지를 사용합니다. |
  | [`stage`](#stage)                             | 작업 스테이지를 정의합니다. |
  | [`start_in`](#start_in)                       | 지정된 시간 동안 작업 실행을 지연시킵니다. `when: delayed`가 필요합니다. |
  | [`tags`](#tags)                               | 러너를 선택하는 데 사용되는 태그 목록입니다. |
  | [`timeout`](#timeout)                         | 프로젝트 전체 설정보다 우선하는 사용자 정의 작업 수준 시간 제한을 정의합니다. |
  | [`trigger`](#trigger)                         | 다운스트림 파이프라인 트리거를 정의합니다. |
  | [`variables`](#job-variables)                 | 개별 작업에 대한 CI/CD 변수를 정의합니다. |
  | [`when`](#when)                               | 작업을 실행할 시기입니다. |

- 더 이상 권장되지 않는 [더 이상 사용되지 않는 키워드](deprecated_keywords.md)입니다.

---

## 전역 키워드 {#global-keywords}

일부 키워드는 작업 내에서 정의되지 않습니다. 이러한 키워드는 파이프라인 동작을 제어하거나 추가 파이프라인 구성을 가져옵니다.

---

### `default` {#default}

일부 키워드에 대한 전역 기본값을 설정할 수 있습니다. 각 기본 키워드는 이미 정의되지 않은 모든 작업에 복사됩니다.

기본 구성은 작업 구성과 병합되지 않습니다. 작업에 키워드가 이미 정의되어 있으면 작업 키워드가 우선하고 해당 키워드의 기본 구성은 사용되지 않습니다.

**Keyword type**: 전역 키워드입니다.

**Supported values**: 이 키워드는 사용자 정의 기본값을 가질 수 있습니다:

- [`after_script`](#after_script)
- [`artifacts`](#artifacts)
- [`before_script`](#before_script)
- [`cache`](#cache)
- [`hooks`](#hooks)
- [`id_tokens`](#id_tokens)
- [`image`](#image)
- [`interruptible`](#interruptible)
- [`retry`](#retry)
- [`services`](#services)
- [`tags`](#tags)

**`default`의 예**:

```yaml
default:
  image: ruby:3.0
  retry: 2

rspec:
  script: bundle exec rspec

rspec 2.7:
  image: ruby:2.7
  script: bundle exec rspec
```

이 예에서:

- `image: ruby:3.0`과 `retry: 2`는 파이프라인의 모든 작업에 대한 기본 키워드입니다.
- `rspec` 작업에는 `image` 또는 `retry`이 정의되지 않아서 `image: ruby:3.0`과 `retry: 2`의 기본값을 사용합니다.
- `rspec 2.7` 작업에는 `retry`이 정의되지 않았지만 `image`은 명시적으로 정의되어 있습니다. 기본 `retry: 2`을 사용하지만 기본 `image`을 무시하고 작업에서 정의한 `image: ruby:2.7`을 사용합니다.

**Additional details**:

- [`inherit:default`](#inheritdefault)를 사용하여 작업에서 기본 키워드의 상속을 제어합니다.
- 전역 기본값은 [다운스트림 파이프라인](../pipelines/downstream_pipelines.md)에 전달되지 않으며, 이는 다운스트림 파이프라인을 트리거한 업스트림 파이프라인과 독립적으로 실행됩니다.

---

### `include` {#include}

`include`를 사용하여 CI/CD 구성에 외부 YAML 파일을 포함합니다. 하나의 긴 `.gitlab-ci.yml` 파일을 여러 파일로 분할하여 가독성을 높이거나 여러 위치에서 동일한 구성의 중복을 줄일 수 있습니다.

중앙 리포지토리에 템플릿 파일을 저장하고 프로젝트에 포함할 수도 있습니다.

`include` 파일은 다음과 같습니다:

- `.gitlab-ci.yml` 파일의 파일과 병합됩니다.
- 항상 먼저 평가되고 `.gitlab-ci.yml` 파일의 내용과 병합되며, `include` 키워드의 위치와 관계없이 병합됩니다.

모든 파일을 확인하는 시간 제한은 30초입니다.

**Keyword type**: 전역 키워드입니다.

**Supported values**: `include` 부분 키:

- [`include:component`](#includecomponent)
- [`include:local`](#includelocal)
- [`include:project`](#includeproject)
- [`include:remote`](#includeremote)
- [`include:template`](#includetemplate)

그리고 선택적으로:

- [`include:inputs`](#includeinputs)
- [`include:rules`](#includerules)
- [`include:integrity`](#includeintegrity)
- [`include:cache`](#includecache)

**Additional details**:

- [특정 CI/CD 변수](includes.md#use-variables-with-include)만 `include` 키워드와 함께 사용할 수 있습니다.
- 병합을 사용하여 로컬로 포함된 CI/CD 구성을 사용자 정의하고 재정의합니다.
- `.gitlab-ci.yml` 파일에서 동일한 작업 이름 또는 전역 키워드를 사용하여 포함된 구성을 재정의할 수 있습니다. 두 구성이 병합되고, `.gitlab-ci.yml` 파일의 구성이 포함된 구성보다 우선합니다.
- 다음을 다시 실행하는 경우:
  - 작업이면 `include` 파일이 다시 페칭되지 않습니다. 파이프라인의 모든 작업은 파이프라인이 생성될 때 페칭된 구성을 사용합니다. 소스 `include` 파일에 대한 모든 변경 사항은 작업 재실행에 영향을 주지 않습니다.
  - 파이프라인이면 `include` 파일이 다시 페칭됩니다. 마지막 파이프라인 실행 이후 변경된 경우, 새 파이프라인은 변경된 구성을 사용합니다.
- 파이프라인당 최대 150개의 포함을 가질 수 있으며, [중첩된](includes.md#use-nested-includes) 것을 포함합니다. 추가로:
  - [GitLab 16.0 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/207270)에서 GitLab Self-Managed의 사용자는 [최대 포함](../../administration/cicd/limits.md#maximum-number-of-includes) 값을 변경할 수 있습니다.
  - 중첩된 포함에서 동일한 파일이 여러 번 포함될 수 있지만, 중복된 포함은 제한에 포함됩니다.

---

#### `include:component` {#includecomponent}

`include:component`를 사용하여 [CI/CD 구성 요소](../components/_index.md)를 파이프라인 구성에 추가합니다.

**Keyword type**: 전역 키워드입니다.

**Supported values**: CI/CD 구성 요소의 전체 주소입니다. `<fully-qualified-domain-name>/<project-path>/<component-name>@<specific-version>` 형식으로 포맷됩니다.

**`include:component`의 예**:

```yaml
include:
  - component: $CI_SERVER_FQDN/my-org/security-components/secret-detection@1.0
```

**Additional details**:

- 구성 요소의 소스 프로젝트가 비공개인 경우, 파이프라인을 실행하는 사용자는 최소한 Reporter 역할이 필요합니다. 내부 프로젝트의 경우, 인증된 비외부 사용자는 구성 요소에 액세스할 수 있습니다. 공개 프로젝트의 경우, 멤버십이 필요하지 않습니다.

**Related topics**:

- [CI/CD 구성 요소 사용](../components/_index.md#use-a-component).

---

#### `include:local` {#includelocal}

`include:local`를 사용하여 `include` 키워드를 포함하는 구성 파일과 동일한 리포지토리 및 브랜치에 있는 파일을 포함합니다. 기호 링크 대신 `include:local`를 사용합니다.

**Keyword type**: 전역 키워드입니다.

**Supported values**:

루트 디렉터리(`/`)를 기준으로 한 전체 경로입니다:

- YAML 파일에는 `.yml` 또는 `.yaml` 확장자가 있어야 합니다.
- 파일 경로에서 [`*` 및 `**` 와일드카드를 사용](includes.md#use-includelocal-with-wildcard-file-paths)할 수 있습니다.
- [특정 CI/CD 변수](includes.md#use-variables-with-include)를 사용할 수 있습니다.

**`include:local`의 예**:

```yaml
include:
  - local: '/templates/.gitlab-ci-template.yml'
```

또한 더 짧은 구문을 사용하여 경로를 정의할 수도 있습니다:

```yaml
include: '.gitlab-ci-production.yml'
```

**Additional details**:

- `.gitlab-ci.yml` 파일과 로컬 파일은 동일한 브랜치에 있어야 합니다.
- Git 부분 모듈 경로를 통해 로컬 파일을 포함할 수 없습니다.
- `include` 구성은 항상 `include` 키워드를 포함하는 파일의 위치를 기준으로 평가되며, 파이프라인을 실행하는 프로젝트가 아닙니다. 다른 프로젝트의 구성 파일에 [중첩된 `include`](includes.md#use-nested-includes)가 있으면 `include: local`는 다른 프로젝트에서 파일을 확인합니다.

---

#### `include:project` {#includeproject}

동일한 GitLab 인스턴스의 다른 비공개 프로젝트에서 파일을 포함하려면 `include:project`과 `include:file`를 사용합니다.

**Keyword type**: 전역 키워드입니다.

**Supported values**:

- `include:project`: 전체 GitLab 프로젝트 경로입니다.
- `include:file` 루트 디렉터리(`/`)를 기준으로 한 전체 파일 경로 또는 파일 경로 배열입니다. YAML 파일에는 `.yml` 또는 `.yaml` 확장자가 있어야 합니다.
- `include:ref`: 선택 사항. 파일을 검색할 ref입니다. 지정하지 않으면 프로젝트의 `HEAD`로 기본값이 지정됩니다.
- [특정 CI/CD 변수](includes.md#use-variables-with-include)를 사용할 수 있습니다.

**`include:project`의 예**:

```yaml
include:
  - project: 'my-group/my-project'
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-subgroup/my-project-2'
    file:
      - '/templates/.builds.yml'
      - '/templates/.tests.yml'
```

`ref`를 지정할 수도 있습니다:

```yaml
include:
  - project: 'my-group/my-project'
    ref: main                                      # Git branch
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-project'
    ref: v1.0.0                                    # Git Tag
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-project'
    ref: 787123b47f14b552955ca2786bc9542ae66fee5b  # Git SHA
    file: '/templates/.gitlab-ci-template.yml'
```

**Additional details**:

- `include` 구성은 항상 `include` 키워드를 포함하는 파일의 위치를 기준으로 평가되며, 파이프라인을 실행하는 프로젝트가 아닙니다. 다른 프로젝트의 구성 파일에 [중첩된 `include`](includes.md#use-nested-includes)가 있으면 `include: local`는 다른 프로젝트에서 파일을 확인합니다.
- 파이프라인이 시작될 때, 모든 방법으로 포함된 `.gitlab-ci.yml` 파일 구성이 평가됩니다. 구성은 시간의 스냅샷이며 데이터베이스에 유지됩니다. GitLab은 참조된 `.gitlab-ci.yml` 파일 구성의 변경 사항을 다음 파이프라인이 시작될 때까지 반영하지 않습니다.
- `include:project`의 모든 비공개 프로젝트에 대해 파이프라인을 실행하는 사용자는 최소한 Reporter 역할이 필요합니다. 내부 프로젝트의 경우, 인증된 비외부 사용자는 포함된 파일에 액세스할 수 있습니다. 공개 프로젝트의 경우, 멤버십이 필요하지 않습니다. 포함된 프로젝트에 대한 충분한 권한이 없으면 `not found or access denied` 오류가 표시됩니다.
- 다른 프로젝트의 CI/CD 구성 파일을 포함할 때는 주의하세요. CI/CD 구성 파일이 변경되면 파이프라인 또는 알림이 트리거되지 않습니다. 보안 관점에서, 이는 타사 종속성을 가져오는 것과 유사합니다. `ref`의 경우 다음을 고려하세요:
  - 특정 SHA 해시를 사용합니다. 이것이 가장 안정적인 옵션이어야 합니다. 전체 40자 SHA 해시를 사용하여 원하는 커밋이 참조되도록 합니다. `ref`에 짧은 SHA 해시를 사용하면 모호할 수 있기 때문입니다.
  - 다른 프로젝트의 `ref`에 [보호된 브랜치](../../user/project/repository/branches/protected.md)와 [보호된 태그](../../user/project/protected_tags.md#prevent-tag-creation-with-branch-names) 규칙을 모두 적용합니다. 보호된 태그 및 브랜치는 변경 전에 변경 관리를 통과할 가능성이 더 높습니다.

---

#### `include:remote` {#includeremote}

`include:remote`을 사용하여 전체 URL로 다른 위치에서 파일을 포함합니다.

**Keyword type**: 전역 키워드입니다.

**Supported values**:

HTTP/HTTPS `GET` 요청으로 액세스할 수 있는 공개 URL:

- 원격 URL로의 인증은 지원되지 않습니다.
- YAML 파일에는 `.yml` 또는 `.yaml` 확장자가 있어야 합니다.
- [특정 CI/CD 변수](includes.md#use-variables-with-include)를 사용할 수 있습니다.

**`include:remote`의 예**:

```yaml
include:
  - remote: 'https://gitlab.com/example-project/-/raw/main/.gitlab-ci.yml'
```

**Additional details**:

- 모든 [중첩된 포함](includes.md#use-nested-includes)은 공개 사용자로 컨텍스트 없이 실행되므로 공개 프로젝트 또는 템플릿만 포함할 수 있습니다. 중첩된 포함의 `include` 섹션에서는 변수를 사용할 수 없습니다.
- 다른 프로젝트의 CI/CD 구성 파일을 포함할 때는 주의하세요. 다른 프로젝트의 파일이 변경되면 파이프라인 또는 알림이 트리거되지 않습니다. 보안 관점에서, 이는 타사 종속성을 가져오는 것과 유사합니다. 포함된 파일의 무결성을 확인하려면 [`integrity`](#includeintegrity) 키워드를 사용하는 것을 고려하세요. 소유한 다른 GitLab 프로젝트에 연결하는 경우, 변경 관리 규칙을 적용하기 위해 [보호된 브랜치](../../user/project/repository/branches/protected.md) 및 [보호된 태그](../../user/project/protected_tags.md#prevent-tag-creation-with-branch-names)의 사용을 모두 고려하세요.

---

#### `include:template` {#includetemplate}

`include:template`를 사용하여 [`.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)을 포함합니다.

**Keyword type**: 전역 키워드입니다.

**Supported values**:

- CI/CD 템플릿의 파일명입니다. 예를 들어 `Auto-DevOps.gitlab-ci.yml`입니다.
- [특정 CI/CD 변수](includes.md#use-variables-with-include)를 사용할 수 있습니다.

**`include:template`의 예**:

```yaml
# File sourced from the GitLab template collection
include:
  - template: Auto-DevOps.gitlab-ci.yml
```

여러 `include:template` 파일:

```yaml
include:
  - template: Android-Fastlane.gitlab-ci.yml
  - template: Auto-DevOps.gitlab-ci.yml
```

**Additional details**:

- 모든 템플릿은 [`lib/gitlab/ci/templates`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)에서 볼 수 있습니다. 모든 템플릿이 `include:template`와 함께 사용하도록 설계된 것은 아니므로 템플릿을 사용하기 전에 템플릿 주석을 확인하세요.
- 모든 [중첩된 포함](includes.md#use-nested-includes)은 공개 사용자로 컨텍스트 없이 실행되므로 공개 프로젝트 또는 템플릿만 포함할 수 있습니다. 중첩된 포함의 `include` 섹션에서는 변수를 사용할 수 없습니다.

---

#### `include:inputs` {#includeinputs}

{{< history >}}

- GitLab 15.11에서 베타 기능으로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)되었습니다.
- GitLab 17.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062)하게 되었습니다.

{{< /history >}}

`include:inputs`을 사용하여 포함된 구성이 [`spec:inputs`](#specinputs)를 사용하고 파이프라인에 추가될 때 입력 매개변수의 값을 설정합니다.

**Keyword type**: 전역 키워드입니다.

**Supported values**: 문자열, 숫자 값 또는 부울입니다.

**`include:inputs`의 예**:

```yaml
include:
  - local: 'custom_configuration.yml'
    inputs:
      website: "My website"
```

이 예에서:

- `custom_configuration.yml`에 포함된 구성이 파이프라인에 추가되며, `website` 입력은 포함된 구성에 대해 `My website` 값으로 설정됩니다.

**Additional details**:

- 포함된 구성 파일이 [`spec:inputs:type`](#specinputstype)를 사용하면 입력 값이 정의된 유형과 일치해야 합니다.
- 포함된 구성 파일이 [`spec:inputs:options`](#specinputsoptions)를 사용하면 입력 값이 나열된 옵션 중 하나와 일치해야 합니다.

**Related topics**:

- [`include`를 사용할 때 입력 값 설정](../inputs/_index.md#for-configuration-added-with-include).

---

#### `include:rules` {#includerules}

[`rules`](#rules)를 `include`과 함께 사용하여 조건부로 다른 구성 파일을 포함할 수 있습니다.

**Keyword type**: 전역 키워드입니다.

**Supported values**: 이 `rules` 부분 키:

- [`rules:if`](#rulesif).
- [`rules:exists`](#rulesexists).
- [`rules:changes`](#ruleschanges).

일부 [CI/CD 변수가 지원됩니다](includes.md#use-variables-with-include).

**`include:rules`의 예**:

```yaml
include:
  - local: build_jobs.yml
    rules:
      - if: $INCLUDE_BUILDS == "true"

test-job:
  stage: test
  script: echo "This is a test job"
```

이 예에서 `INCLUDE_BUILDS` 변수가 다음인 경우:

- `true`이면 `build_jobs.yml` 구성이 파이프라인에 포함됩니다.
- `true`가 아니거나 존재하지 않으면 `build_jobs.yml` 구성이 파이프라인에 포함되지 않습니다.

**Related topics**:

- `include`과 함께 사용하는 예제:
  - [`rules:if`](includes.md#include-with-rulesif).
  - [`rules:changes`](includes.md#include-with-ruleschanges).
  - [`rules:exists`](includes.md#include-with-rulesexists).

---

#### `include:integrity` {#includeintegrity}

{{< history >}}

- [GitLab 17.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178593).

{{< /history >}}

`integrity`를 `include:remote`와 함께 사용하여 포함된 원격 파일의 SHA256 해시를 지정합니다. `integrity`이 실제 내용과 일치하지 않으면 원격 파일이 처리되지 않고 파이프라인이 실패합니다.

**Keyword type**: 전역 키워드입니다.

**Supported values**: 포함된 내용의 Base64 인코딩된 SHA256 해시입니다.

**`include:integrity`의 예**:

```yaml
include:
  - remote: 'https://gitlab.com/example-project/-/raw/main/.gitlab-ci.yml'
    integrity: 'sha256-L3/GAoKaw0Arw6hDCKeKQlV1QPEgHYxGBHsH4zG1IY8='
```

---

#### `include:cache` {#includecache}

{{< history >}}

- [GitLab 18.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/351252) [실험](../../policy/development_stages_support.md#experiment)으로 [기능 플래그](../../administration/feature_flags/_index.md) `ci_cache_remote_includes` 이름으로. 기본적으로 비활성화되어 있습니다.
- GitLab 19.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235028)합니다. 기능 플래그 `ci_cache_remote_includes`이 제거되었습니다.

{{< /history >}}

`cache`을 `include:remote`와 함께 사용하여 페칭된 원격 파일 내용을 캐시하고 HTTP 요청을 줄입니다. 활성화되면 원격 파일이 지정된 TTL(Time-To-Live) 기간 동안 캐시되어 동일한 원격 포함을 반복적으로 사용하는 구성의 파이프라인 성능이 향상됩니다.

캐시 기간을 설정할 때 성능과 신선도 간의 균형을 고려하세요. 캐시 기간이 길수록 성능이 향상되지만 원격 파일이 자주 변경되면 오래된 내용이 사용될 수 있습니다.

`cache`이 정의되지 않으면 원격 파일이 매번 페칭됩니다.

**Keyword type**: 전역 키워드입니다.

**Supported values**:

- `true`: 1시간의 기본 TTL(Time-To-Live)로 캐싱을 활성화합니다.
- 기간(문자열): 유효한 TTL 기간 문자열은 `minutes`, `hours` 또는 `days` 같은 시간 단위를 사용합니다. (최소 `1 minute`).

**`include:cache`의 예**:

```yaml
include:
  - remote: 'https://gitlab.com/example-project/-/raw/main/sample1.gitlab-ci.yml'
    cache: true
  - remote: 'https://gitlab.com/example-project/-/raw/main/sample2.gitlab-ci.yml'
    cache: '1 day'
```

**Additional details**:

- 캐싱은 `include:remote`에만 사용 가능합니다.
- 원격 파일이 캐시된 후, TTL이 만료될 때까지 원격 파일 내용이 변경되어도 캐시된 버전이 계속 사용됩니다.
- [`integrity`](#includeintegrity)를 `cache`와 함께 사용하면 캐시된 내용을 사용할 때도 무결성 검사가 모든 파이프라인 실행에서 수행됩니다.

---

### `stages` {#stages}

`stages`를 사용하여 작업 그룹을 포함하는 스테이지를 정의합니다. 작업에서 [`stage`](#stage)를 사용하여 작업이 특정 스테이지에서 실행되도록 구성합니다.

`stages`이 `.gitlab-ci.yml` 파일에서 정의되지 않으면 기본 파이프라인 스테이지는 다음과 같습니다:

- [`.pre`](#stage-pre)
- `build`
- `test`
- `deploy`
- [`.post`](#stage-post)

`stages`의 항목 순서는 작업의 실행 순서를 정의합니다:

- 동일한 스테이지의 작업은 병렬로 실행됩니다.
- 다음 스테이지의 작업은 이전 스테이지의 작업이 성공적으로 완료된 후 실행됩니다.

파이프라인에 `.pre` 또는 `.post` 스테이지의 작업만 포함되어 있으면 실행되지 않습니다. 다른 스테이지에 최소한 하나의 다른 작업이 있어야 합니다.

**Keyword type**: 전역 키워드입니다.

**`stages`의 예**:

```yaml
stages:
  - build
  - test
  - deploy
```

이 예에서:

1. `build`의 모든 작업이 병렬로 실행됩니다.
1. `build`의 모든 작업이 성공하면 `test` 작업이 병렬로 실행됩니다.
1. `test`의 모든 작업이 성공하면 `deploy` 작업이 병렬로 실행됩니다.
1. `deploy`의 모든 작업이 성공하면 파이프라인이 `passed`로 표시됩니다.

모든 작업이 실패하면 파이프라인이 `failed`로 표시되고 이후 스테이지의 작업이 시작되지 않습니다. 현재 스테이지의 작업은 중지되지 않으며 계속 실행됩니다.

**Additional details**:

- 작업이 [`stage`](#stage)를 지정하지 않으면 작업에 `test` 스테이지가 할당됩니다.
- 스테이지가 정의되었지만 작업이 사용하지 않으면 스테이지는 파이프라인에 표시되지 않으므로 [준수 파이프라인 구성](../../user/compliance/compliance_pipelines.md)을 도울 수 있습니다:
  - 스테이지는 준수 구성에서 정의할 수 있지만 사용하지 않으면 숨겨진 상태로 유지됩니다.
  - 개발자가 작업 정의에서 사용할 때 정의된 스테이지가 표시됩니다.

**Related topics**:

- 작업을 시작하고 스테이지 순서를 무시하려면 [`needs`](#needs) 키워드를 사용하세요.

---

### `workflow` {#workflow}

[`workflow`](workflow.md)를 사용하여 파이프라인 동작을 제어합니다.

일부 [사전 정의된 CI/CD 변수](../variables/predefined_variables.md)를 `workflow` 구성에서 사용할 수 있지만 작업이 시작할 때만 정의되는 변수는 사용할 수 없습니다.

**Related topics**:

- [`workflow: rules` 예제](workflow.md#workflow-rules-examples)
- [브랜치 파이프라인과 머지 리퀘스트 파이프라인 간 전환](workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)

---

#### `workflow:auto_cancel:on_new_commit` {#workflowauto_cancelon_new_commit}

`workflow:auto_cancel:on_new_commit`을 사용하여 [중복된 파이프라인 자동 취소](../pipelines/settings.md#auto-cancel-redundant-pipelines) 기능의 동작을 구성합니다.

**Supported values**:

- `conservative`: 파이프라인을 취소하되, `interruptible: false`인 작업이 아직 시작되지 않은 경우에만 취소합니다. 정의하지 않으면 기본값입니다.
- `interruptible`: `interruptible: true`인 작업만 취소합니다.
- `none`: 작업을 자동으로 취소하지 않습니다.

**`workflow:auto_cancel:on_new_commit`의 예**:

```yaml
workflow:
  auto_cancel:
    on_new_commit: interruptible

job1:
  interruptible: true
  script: sleep 60

job2:
  interruptible: false  # Default when not defined.
  script: sleep 60
```

이 예에서:

- 새 커밋이 브랜치에 푸시되면 GitLab이 새 파이프라인을 생성하고 `job1`과 `job2`가 시작됩니다.
- 작업이 완료되기 전에 새 커밋이 브랜치에 푸시되면 `job1`만 취소됩니다.

---

#### `workflow:auto_cancel:on_job_failure` {#workflowauto_cancelon_job_failure}

`workflow:auto_cancel:on_job_failure`을 사용하여 한 작업이 실패하면 즉시 취소해야 하는 작업을 구성합니다.

**Supported values**:

- `all`: 한 작업이 실패하자마자 파이프라인 및 모든 실행 중인 작업을 취소합니다.
- `none`: 작업을 자동으로 취소하지 않습니다.

**`workflow:auto_cancel:on_job_failure`의 예**:

```yaml
stages: [stage_a, stage_b]

workflow:
  auto_cancel:
    on_job_failure: all

job1:
  stage: stage_a
  script: sleep 60

job2:
  stage: stage_a
  script:
    - sleep 30
    - exit 1

job3:
  stage: stage_b
  script:
    - sleep 30
```

이 예에서 `job2`이 실패하면 `job1`은 계속 실행 중이면 취소되고 `job3`은 시작되지 않습니다.

**Related topics**:

- [다운스트림 파이프라인에서 상위 파이프라인 자동 취소](../pipelines/downstream_pipelines.md#auto-cancel-the-parent-pipeline-from-a-downstream-pipeline)

---

#### `workflow:name` {#workflowname}

`name`을 `workflow:`에서 사용하여 파이프라인 이름을 정의할 수 있습니다.

모든 파이프라인에는 정의된 이름이 할당됩니다. 이름의 모든 선행 또는 후행 공백이 제거됩니다.

**Supported values**:

- 문자열입니다.
- [CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).
- 둘의 조합입니다.

**`workflow:name`의 예**:

사전 정의된 변수가 포함된 간단한 파이프라인 이름:

```yaml
workflow:
  name: 'Pipeline for branch: $CI_COMMIT_BRANCH'
```

파이프라인 조건에 따라 다른 파이프라인 이름이 있는 구성:

```yaml
variables:
  PROJECT1_PIPELINE_NAME: 'Default pipeline name'  # A default is not required

workflow:
  name: '$PROJECT1_PIPELINE_NAME'
  rules:
    - if: '$CI_MERGE_REQUEST_LABELS =~ /pipeline:run-in-ruby3/'
      variables:
        PROJECT1_PIPELINE_NAME: 'Ruby 3 pipeline'
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      variables:
        PROJECT1_PIPELINE_NAME: 'MR pipeline: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME'
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH  # For default branch pipelines, use the default name
```

**Additional details**:

- 이름이 빈 문자열이면 파이프라인에 이름이 할당되지 않습니다. CI/CD 변수로만 구성된 이름은 모든 변수도 비어 있으면 빈 문자열로 평가될 수 있습니다.
- `workflow:rules:variables`은 모든 작업에서 사용 가능한 [기본 변수](#default-variables)가 되며, [`trigger`](#trigger) 작업을 포함합니다. 이는 기본적으로 다운스트림 파이프라인에 변수를 전달합니다. 다운스트림 파이프라인이 동일한 변수를 사용하면 [변수가 업스트림 변수 값으로 덮어쓰기됩니다](../variables/_index.md#cicd-variable-precedence). 다음 중 하나를 확인하세요:
  - `PROJECT1_PIPELINE_NAME` 같은 모든 프로젝트 파이프라인 구성에서 고유한 변수 이름을 사용합니다.
  - 트리거 작업에서 [`inherit:variables`](#inheritvariables)를 사용하고 다운스트림 파이프라인으로 전달하려는 정확한 변수를 나열합니다.

---

#### `workflow:rules` {#workflowrules}

`rules`의 `workflow` 키워드는 작업에서 정의된 [`rules`](#rules)와 유사하지만 전체 파이프라인을 생성할지 여부를 제어합니다.

어떤 규칙도 true로 평가되지 않으면 파이프라인이 실행되지 않습니다.

**Supported values**: 작업 수준 [`rules`](#rules)과 동일한 키워드를 일부 사용할 수 있습니다:

- [`rules: if`](#rulesif).
- [`rules: changes`](#ruleschanges).
- [`rules: exists`](#rulesexists).
- [`when`](#when)는 `workflow`와 함께 사용할 때 `always` 또는 `never`만 가능합니다.
- [`variables`](#workflowrulesvariables).

**`workflow:rules`의 예**:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_TITLE =~ /-draft$/
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

이 예에서 커밋 제목(커밋 메시지의 첫 번째 줄)이 `-draft`으로 끝나지 않고 파이프라인이 다음 중 하나인 경우 파이프라인이 실행됩니다:

- 머지 리퀘스트
- 기본 브랜치.

**Additional details**:

- 규칙이 브랜치 파이프라인(기본 브랜치 제외)과 머지 리퀘스트 파이프라인을 모두 일치하면 [중복 파이프라인](../jobs/job_rules.md#avoid-duplicate-pipelines)이 발생할 수 있습니다.
- `start_in`, `allow_failure`, `needs`은 `workflow:rules`에서 지원되지 않지만 구문 위반을 일으키지는 않습니다. 영향이 없더라도 `workflow:rules`에서 사용하지 마세요. 향후에 구문 실패를 일으킬 수 있습니다. 자세한 내용은 [이슈 436473](https://gitlab.com/gitlab-org/gitlab/-/issues/436473)을 참조하세요.

**Related topics**:

- [`workflow:rules`에 대한 일반적인 `if` 절](workflow.md#common-if-clauses-for-workflowrules).
- [`rules`를 사용하여 머지 리퀘스트 파이프라인 실행](../pipelines/merge_request_pipelines.md#configure-merge-request-pipelines).

---

#### `workflow:rules:variables` {#workflowrulesvariables}

[`variables`](#variables)를 `workflow:rules`에서 사용하여 특정 파이프라인 조건에 대한 변수를 정의할 수 있습니다.

조건이 일치하면 변수가 생성되고 파이프라인의 모든 작업에서 사용할 수 있습니다. 변수가 이미 최상위 수준 기본 변수로 정의되어 있으면 `workflow` 변수가 우선하고 기본 변수를 재정의합니다.

**Keyword type**: 전역 키워드입니다.

**Supported values**: 변수 이름 및 값 쌍:

- 이름은 숫자, 문자 및 밑줄(`_`)만 사용할 수 있습니다.
- 값은 문자열이어야 합니다.

**`workflow:rules:variables`의 예**:

```yaml
variables:
  DEPLOY_VARIABLE: "default-deploy"

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      variables:
        DEPLOY_VARIABLE: "deploy-production"  # Override globally-defined DEPLOY_VARIABLE
    - if: $CI_COMMIT_BRANCH =~ /feature/
      variables:
        IS_A_FEATURE: "true"                  # Define a new variable.
    - if: $CI_COMMIT_BRANCH                   # Run the pipeline in other cases

job1:
  variables:
    DEPLOY_VARIABLE: "job1-default-deploy"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      variables:                                   # Override DEPLOY_VARIABLE defined
        DEPLOY_VARIABLE: "job1-deploy-production"  # at the job level.
    - when: on_success                             # Run the job in other cases
  script:
    - echo "Run script with $DEPLOY_VARIABLE as an argument"
    - echo "Run another script if $IS_A_FEATURE exists"

job2:
  script:
    - echo "Run script with $DEPLOY_VARIABLE as an argument"
    - echo "Run another script if $IS_A_FEATURE exists"
```

브랜치가 기본 브랜치인 경우:

- job1의 `DEPLOY_VARIABLE`은 `job1-deploy-production`입니다.
- job2의 `DEPLOY_VARIABLE`은 `deploy-production`입니다.

브랜치가 `feature`인 경우:

- job1의 `DEPLOY_VARIABLE`은 `job1-default-deploy`이고 `IS_A_FEATURE`은 `true`입니다.
- job2의 `DEPLOY_VARIABLE`은 `default-deploy`이고 `IS_A_FEATURE`은 `true`입니다.

브랜치가 다른 것인 경우:

- job1의 `DEPLOY_VARIABLE`은 `job1-default-deploy`입니다.
- job2의 `DEPLOY_VARIABLE`은 `default-deploy`입니다.

**Additional details**:

- `workflow:rules:variables`은 모든 작업에서 사용 가능한 [기본 변수](#variables)가 되며, [`trigger`](#trigger) 작업을 포함합니다. 이는 기본적으로 다운스트림 파이프라인에 변수를 전달합니다. 다운스트림 파이프라인이 동일한 변수를 사용하면 [변수가 업스트림 변수 값으로 덮어쓰기됩니다](../variables/_index.md#cicd-variable-precedence). 다음 중 하나를 확인하세요:
  - 모든 프로젝트 파이프라인 구성에서 고유한 변수 이름을 사용합니다. 예를 들어 `PROJECT1_VARIABLE_NAME`.
  - 트리거 작업에서 [`inherit:variables`](#inheritvariables)를 사용하고 다운스트림 파이프라인으로 전달하려는 정확한 변수를 나열합니다.

---

#### `workflow:rules:auto_cancel` {#workflowrulesauto_cancel}

`workflow:rules:auto_cancel`을 사용하여 [`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit) 또는 [`workflow:auto_cancel:on_job_failure`](#workflowauto_cancelon_job_failure) 기능의 동작을 구성합니다.

**Supported values**:

- `on_new_commit`: [`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit)
- `on_job_failure`: [`workflow:auto_cancel:on_job_failure`](#workflowauto_cancelon_job_failure)

**`workflow:rules:auto_cancel`의 예**:

```yaml
workflow:
  auto_cancel:
    on_new_commit: interruptible
    on_job_failure: all
  rules:
    - if: $CI_COMMIT_REF_PROTECTED == 'true'
      auto_cancel:
        on_new_commit: none
        on_job_failure: none
    - when: always                  # Run the pipeline in other cases

test-job1:
  script: sleep 10
  interruptible: false

test-job2:
  script: sleep 10
  interruptible: true
```

이 예에서 [`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit)는 `interruptible`로 설정되고 [`workflow:auto_cancel:on_job_failure`](#workflowauto_cancelon_job_failure)는 기본적으로 모든 작업에 대해 `all`으로 설정됩니다. 그러나 파이프라인이 보호된 브랜치에서 실행되면 규칙이 기본값을 `on_new_commit: none`과 `on_job_failure: none`로 재정의합니다. 예를 들어, 파이프라인이 다음에서 실행 중인 경우:

- 비보호 브랜치이고 새 커밋이 푸시되면 `test-job1`은 계속 실행되고 `test-job2`는 취소됩니다.
- 보호된 브랜치이고 새 커밋이 푸시되면 `test-job1`과 `test-job2` 모두 계속 실행됩니다.

---

## 헤더 키워드 {#header-keywords}

일부 키워드는 YAML 구성 파일의 헤더 섹션에서 정의해야 합니다. 헤더는 파일의 맨 위에 있어야 하며 `---`로 구성의 나머지 부분과 분리되어야 합니다.

---

### `spec` {#spec}

구성이 `include` 키워드를 사용하여 파이프라인에 추가될 때 파이프라인의 동작을 구성하려면 YAML 파일의 헤더에 `spec` 섹션을 추가하세요.

스펙은 `---`로 구성의 나머지 부분과 분리된 헤더 섹션의 구성 파일 맨 위에 선언해야 합니다.

---

#### `spec:inputs` {#specinputs}

`spec:inputs`를 사용하여 CI/CD 구성에 대한 [입력](../inputs/_index.md)을 정의할 수 있습니다.

보간 형식 `$[[ inputs.input-id ]]`를 사용하여 헤더 섹션 외부의 값을 참조합니다. 입력은 파이프라인 생성 중에 구성이 페칭될 때 평가되고 보간됩니다. `inputs`를 사용할 때 보간은 구성이 `.gitlab-ci.yml` 파일의 내용과 병합되기 전에 완료됩니다.

**Keyword type**: 헤더 키워드. `spec`은 구성 파일의 맨 위, 헤더 섹션에서 선언해야 합니다.

**Supported values**: 예상 입력을 나타내는 문자열의 해시입니다.

**`spec:inputs`의 예**:

```yaml
spec:
  inputs:
    environment:
    job-stage:
---

scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

**Additional details**:

- 입력은 [`spec:inputs:default`](#specinputsdefault)를 사용하여 기본값을 설정하지 않는 한 필수입니다. [`include:inputs`](#includeinputs)와만 입력을 사용하지 않는 한 필수 입력을 피하세요.
- 입력은 [`spec:inputs:type`](#specinputstype)를 사용하여 다른 입력 유형을 설정하지 않는 한 문자열을 예상합니다.
- 보간 블록이 포함된 문자열은 1MB를 초과할 수 없습니다.
- 보간 블록 내의 문자열은 1KB를 초과할 수 없습니다.
- [새 파이프라인을 실행할 때 입력 값을 정의](../inputs/_index.md#for-a-pipeline)할 수 있습니다.

**Related topics**:

- [`spec:inputs`로 입력 매개변수 정의](../inputs/_index.md#define-input-parameters-with-specinputs).

---

##### `spec:inputs:default` {#specinputsdefault}

포함될 때 입력은 필수이며, `spec:inputs:default`로 기본값을 설정하지 않으면 필수입니다.

기본값을 갖지 않으려면 `default: ''`를 사용합니다.

**Keyword type**: 헤더 키워드. `spec`은 구성 파일의 맨 위, 헤더 섹션에서 선언해야 합니다.

**Supported values**: 기본값을 나타내는 문자열 또는 `''`입니다.

**`spec:inputs:default`의 예**:

```yaml
spec:
  inputs:
    website:
    user:
      default: 'test-user'
    flags:
      default: ''
---
# The pipeline configuration would follow...
```

이 예에서:

- `website`은 필수이며 정의해야 합니다.
- `user`는 선택 사항입니다. 정의되지 않으면 값은 `test-user`입니다.
- `flags`는 선택 사항입니다. 정의되지 않으면 값이 없습니다.

**Additional details**:

- 입력이 다음인 경우 파이프라인이 유효성 검사 오류로 실패합니다:
  - `default`과 [`options`](#specinputsoptions)를 모두 사용하지만 기본값이 나열된 옵션 중 하나가 아닙니다.
  - `default`과 `regex`를 모두 사용하지만 기본값이 정규식과 일치하지 않습니다.
  - 값이 [`type`](#specinputstype)와 일치하지 않습니다.

---

##### `spec:inputs:description` {#specinputsdescription}

`description`를 사용하여 특정 입력에 설명을 제공합니다. 설명은 입력의 동작에 영향을 주지 않으며 파일의 사용자가 입력을 이해하는 데만 도움이 됩니다.

**Keyword type**: 헤더 키워드. `spec`은 구성 파일의 맨 위, 헤더 섹션에서 선언해야 합니다.

**Supported values**: 설명을 나타내는 문자열입니다.

**`spec:inputs:description`의 예**:

```yaml
spec:
  inputs:
    flags:
      description: 'Sample description of the `flags` input details.'
---
# The pipeline configuration would follow...
```

---

##### `spec:inputs:options` {#specinputsoptions}

{{< history >}}

- GitLab 16.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/393401)되었습니다.
- 배열 유형 입력 지원은 [GitLab 19.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/566155).

{{< /history >}}

입력은 `options`를 사용하여 입력의 허용된 값 목록을 지정할 수 있습니다. 제한은 입력당 50개의 옵션입니다.

**Keyword type**: 헤더 키워드. `spec`은 구성 파일의 맨 위, 헤더 섹션에서 선언해야 합니다.

**Supported values**: 입력 옵션 배열입니다.

**`spec:inputs:options`의 예**:

```yaml
spec:
  inputs:
    environment:
      options:
        - development
        - staging
        - production
---
# The pipeline configuration would follow...
```

이 예에서:

- `environment`은 필수이며 목록의 값 중 하나로 정의해야 합니다.

**Additional details**:

- 파이프라인이 다음인 경우 유효성 검사 오류로 실패합니다:
  - 입력이 `options`과 [`default`](#specinputsdefault)를 모두 사용하지만 기본값이 나열된 옵션 중 하나가 아닙니다.
  - 입력 옵션 중 하나가 [`type`](#specinputstype)와 일치하지 않으며, `string` 또는 `number`일 수 있지만 `options`를 사용할 때는 `boolean`가 아닙니다.

---

##### `spec:inputs:regex` {#specinputsregex}

`spec:inputs:regex`을 사용하여 입력이 일치해야 하는 정규식을 지정합니다.

**Keyword type**: 헤더 키워드. `spec`은 구성 파일의 맨 위, 헤더 섹션에서 선언해야 합니다.

**Supported values**: 정규식이어야 합니다.

**`spec:inputs:regex`의 예**:

```yaml
spec:
  inputs:
    version:
      regex: ^v\d\.\d+(\.\d+)?$
---
# The pipeline configuration would follow...
```

이 예에서 `v1.0` 또는 `v1.2.3` 입력은 정규식과 일치하고 유효성 검사를 통과합니다. `v1.A.B` 입력은 정규식과 일치하지 않아 유효성 검사에 실패합니다.

**Additional details**:

- `inputs:regex`은 `string`이 아닌 `number` 또는 `boolean`의 [`type`](#specinputstype)와만 사용할 수 있습니다.
- 정규식을 `/` 문자로 묶지 마세요. 예를 들어 `regex.*`을 사용하고 `/regex.*/`은 사용하지 마세요.
- `inputs:regex`은 [RE2](https://github.com/google/re2/wiki/Syntax)를 사용하여 정규식을 구문 분석합니다.
- 입력을 정규식으로 검증하는 것은 변수 확장 전에 발생합니다. 입력 텍스트에 변수 이름이 포함되어 있으면 입력의 원시 값(변수 이름)이 변수 값이 아닌 검증됩니다.

---

##### `spec:inputs:rules` {#specinputsrules}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/582671)되었습니다.

{{< /history >}}

`spec:inputs:rules`을 사용하여 다른 입력의 값을 기반으로 입력에 대한 조건부 `options` 및 `default` 값을 정의합니다.

**Keyword type**: 헤더 키워드. `spec`은 구성 파일의 맨 위, 헤더 섹션에서 선언해야 합니다.

**Supported values**: 규칙 객체 배열입니다. 각 규칙에는 다음이 있을 수 있습니다:

- `if`: [`$[[ inputs.input-id ]]` 구문](../inputs/_index.md#define-input-parameters-with-specinputs)을 사용하여 입력 값을 확인하는 조건부 표현입니다.
- `options`: 입력의 허용된 값 배열입니다.
- `default`: 이 규칙이 일치할 때 입력의 기본값입니다. [`default: null`](../inputs/_index.md#allow-user-entered-values-with-default-null)를 사용하여 사용자가 입력에 대해 자신의 값을 입력하도록 허용합니다.

**`spec:inputs:rules`의 예**:

```yaml
spec:
  inputs:
    environment:
      options: ['development', 'production']
      default: 'development'

    instance_type:
      description: 'VM instance size'
      rules:
        - if: $[[ inputs.environment ]] == 'development'
          options: ['small', 'medium']
          default: 'small'
        - if: $[[ inputs.environment ]] == 'production'
          options: ['large', 'xlarge']
          default: 'large'
---

deploy:
  script: echo "Deploying $[[ inputs.instance_type ]] instance"
```

이 예에서 `environment`이 `development`인 경우, 사용자는 `small` 또는 `medium` 인스턴스만 선택할 수 있습니다. `environment`가 `production`인 경우, `large` 또는 `xlarge` 인스턴스만 사용 가능합니다.

**Additional details**:

- 규칙은 순서대로 평가됩니다. 일치하는 `if` 조건이 있는 첫 번째 규칙이 사용됩니다.
- `if` 조건이 없는 규칙은 다른 규칙이 일치하지 않을 때 폴백 역할을 합니다.
- 폴백 규칙은 최소 하나의 값이 있는 `options`을 정의해야 합니다.
- `options`이 있는 모든 규칙은 `options` 목록에 있는 `default` 값도 정의해야 합니다.
- 동일한 입력에 대해 `rules`과 최상위 수준 `options` 또는 `default`를 동시에 사용할 수 없습니다.

**Related topics**:

- [`spec:inputs:rules`로 조건부 입력 옵션 정의](../inputs/_index.md#define-conditional-input-options-with-specinputsrules).

---

##### `spec:inputs:type` {#specinputstype}

기본적으로 입력은 문자열을 예상합니다. `spec:inputs:type`을 사용하여 입력에 필요한 다른 유형을 설정합니다.

**Keyword type**: 헤더 키워드. `spec`은 구성 파일의 맨 위, 헤더 섹션에서 선언해야 합니다.

**Supported values**: 다음 중 하나일 수 있습니다:

- `array`, 입력의 [배열](../inputs/_index.md#array-type)을 수락하려면.
- 문자열 입력을 수락하려면 `string`(정의하지 않으면 기본값).
- 숫자 입력만 수락하려면 `number`.
- `boolean` `true` 또는 `false` 입력만 수락하려면.

**`spec:inputs:type`의 예**:

```yaml
spec:
  inputs:
    job_name:
    website:
      type: string
    port:
      type: number
    available:
      type: boolean
    array_input:
      type: array
---
# The pipeline configuration would follow...
```

---

#### `spec:include` {#specinclude}

{{< history >}}

- GitLab 18.6에서 `ci_file_inputs` [플래그](../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206931)되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 18.9에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/579240)합니다. 기능 플래그 `ci_file_inputs`이 제거되었습니다.

{{< /history >}}

`spec:include`를 사용하여 다른 파일에서 외부 입력 정의를 포함합니다. 여러 파이프라인 구성에서 입력 정의를 공유하고 재사용할 수 있습니다.

**Keyword type**: 헤더 키워드. `spec`은 구성 파일의 맨 위, 헤더 섹션에서 선언해야 합니다.

**Supported values**: 위치 배열을 포함합니다. `local`, `remote` 및 `project` 포함만 지원합니다.

**`spec:include`의 예**:

```yaml
spec:
  include:
    - local: /shared-inputs.yml
  inputs:
    environment:
      default: production
---

deploy:
  script: echo "Deploying to $[[ inputs.environment ]]"
```

다양한 소스의 여러 포함:

```yaml
spec:
  include:
    - local: /base-inputs.yml
    - remote: 'https://example.com/ci/common-inputs.yml'
    - project: 'my-group/shared-configs'
      ref: main
      file: '/ci/team-inputs.yml'
  inputs:
    environment:
      default: production
---

deploy:
  script: echo "Deploying to $[[ inputs.environment ]]"
```

**Additional details**:

- [CI/CD 구성 요소](../components/_index.md#component-spec-section)에서 `spec:include`를 사용할 수 없습니다.
- 외부 입력 파일에는 `inputs` 키만 포함되어야 합니다. 다른 키는 유효성 검사 오류를 일으킵니다.
- 외부 입력이 먼저 병합된 다음 인라인 입력이 적용됩니다.
- 인라인 입력은 포함된 입력과 동일한 이름을 가질 수 없습니다.
- 여러 입력 파일을 포함하면 지정된 순서로 병합됩니다.
- [`local`](#includelocal), [`remote`](#includeremote) 및 [`project`](#includeproject) 포함 유형을 지원합니다. `template`, `component` 또는 `artifact` 포함은 지원하지 않습니다.

**Related topics**:

- [외부 파일에서 입력 사용](../inputs/_index.md#define-pipeline-inputs-in-external-files).

---

#### `spec:component` {#speccomponent}

{{< history >}}

- GitLab 18.6에서 [베타](../../policy/development_stages_support.md#beta)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/438275)되었으며 [플래그](../../administration/feature_flags/_index.md) 이름은 `ci_component_context_interpolation`입니다. 기본적으로 활성화됩니다.
- GitLab 18.7에서 [일반 공급 개시](https://gitlab.com/gitlab-org/gitlab/-/issues/571986)됨. 기능 플래그 `ci_component_context_interpolation`이 제거되었습니다.

{{< /history >}}

`spec:component`을 사용하여 [CI/CD 구성 요소](../components/_index.md)의 보간에 사용 가능한 구성 요소 컨텍스트 데이터를 정의합니다.

구성 요소 컨텍스트는 구성 요소의 이름, 버전, 커밋 SHA와 같은 구성 요소 자체에 대한 메타데이터를 제공합니다. 이를 통해 구성 요소 템플릿이 자신의 메타데이터를 동적으로 참조할 수 있습니다.

보간 형식 `$[[ component.field-name ]]`를 사용하여 구성 요소 템플릿의 구성 요소 컨텍스트 값을 참조합니다.

**Keyword type**: 헤더 키워드. `spec`은 구성 파일의 맨 위, 헤더 섹션에서 선언해야 합니다.

**Supported values**: 문자열 배열입니다. 각 문자열은 다음 중 하나여야 합니다:

- `name`: 구성 요소 경로에 지정된 구성 요소 이름입니다.
- `sha`: 컴포넌트의 커밋 SHA입니다.
- `version`: 카탈로그 리소스에서 확인된 시맨틱 버전입니다. 다음의 경우 `null`을 반환합니다:
  - 컴포넌트가 카탈로그 리소스가 아닙니다.
  - 참조가 브랜치 이름 또는 커밋 SHA입니다(릴리스 버전 아님).
- `reference`: 컴포넌트 경로에서 `@` 뒤에 지정된 원본 참조입니다. 예를 들어 `1.0`, `~latest`, 브랜치 이름 또는 커밋 SHA입니다.

**`spec:component`의 예**:

```yaml
spec:
  component: [name, version, reference]
  inputs:
    stage:
      default: build
---

build-image:
  stage: $[[ inputs.stage ]]
  image: registry.example.com/$[[ component.name ]]:$[[ component.version ]]
  script:
    - echo "Building with component version $[[ component.version ]]"
    - echo "Component reference: $[[ component.reference ]]"
```

**Additional details**:

- `version` 필드는 다음을 사용할 때 실제 시맨틱 버전으로 확인됩니다:
  - `@1.0.0`과 같은 전체 버전(`1.0.0` 반환)
  - `@1.0`과 같은 부분 버전(최신 일치 버전 반환, 예: `1.0.2`)
  - `@~latest`(최신 버전 반환)
- `reference` 필드는 항상 `@` 뒤에 지정된 정확한 값을 반환합니다:
  - `@1.0`은 `1.0`을 반환합니다(`version`은 `1.0.2`을 반환할 수 있는 반면).
  - `@~latest`은 `~latest`을 반환합니다(`version`은 실제 버전 번호를 반환하는 반면).
  - `@abc123`은 `abc123`을 반환합니다(`version`은 `null`를 반환하는 반면).

**Related topics**:

- [컴포넌트에서 컴포넌트 컨텍스트 사용](../components/_index.md#use-component-context-in-components).

---

#### `spec:description` {#specdescription}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/588286)되었습니다.

{{< /history >}}

`spec:description`을 사용하여 컴포넌트에 대한 간단한 설명을 제공합니다. 설명은 CI/CD 카탈로그의 컴포넌트 세부 정보 페이지에 입력 테이블 위에 표시됩니다.

**Keyword type**: 헤더 키워드. `spec`은 구성 파일의 맨 위, 헤더 섹션에서 선언해야 합니다.

**Supported values**: 컴포넌트를 설명하는 문자열입니다.

**`spec:description`의 예**:

```yaml
spec:
  description: "A description of the component visible to users in the CI/CD Catalog."
  inputs:
    stage:
      default: test
---
scan-job:
  stage: $[[ inputs.stage ]]
  script: ./run-scan.sh
```

---

## 작업 키워드 {#job-keywords}

다음 항목에서는 키워드를 사용하여 CI/CD 파이프라인을 구성하는 방법을 설명합니다.

---

### `after_script` {#after_script}

{{< history >}}

- 취소된 작업에 대해 `after_script` 명령 실행 [GitLab 17.0에서 도입됨](https://gitlab.com/groups/gitlab-org/-/epics/10158).

{{< /history >}}

`after_script`을 사용하여 작업의 `before_script` 및 `script` 섹션이 완료된 후 마지막으로 실행할 명령 배열을 정의합니다. `after_script` 명령은 다음의 경우에도 실행됩니다:

- `before_script` 또는 `script` 섹션이 여전히 실행 중인 동안 작업이 취소됩니다.
- 작업이 `script_failure`의 실패 유형으로 실패하지만 [다른 실패 유형](#retrywhen)으로는 실패하지 않습니다.

작업 구성과 기본 구성은 함께 병합되지 않습니다. 파이프라인에 [`default:after_script`](#default)가 정의되어 있고 작업에도 `after_script`이 있으면 작업 구성이 우선적으로 적용되고 기본 구성은 사용되지 않습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**: 다음을 포함하는 배열:

- 한 줄 명령.
- 여러 줄로 [분할된](script.md#split-long-commands) 긴 명령.
- [YAML 앵커](yaml_optimization.md#yaml-anchors-for-scripts).

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`after_script`의 예**:

```yaml
job:
  script:
    - echo "An example script section."
  after_script:
    - echo "Execute this command after the `script` section completes."
```

**Additional details**:

`after_script`에 지정된 스크립트는 `before_script` 또는 `script` 명령과 분리된 새 셸에서 실행됩니다. 결과적으로 다음과 같은 특징이 있습니다:

- 현재 작업 디렉터리가 기본값으로 설정됩니다([러너가 Git 요청을 처리하는 방식을 정의하는 변수](../runners/configure_runners.md#configure-runner-behavior-with-variables) 참고).
- `before_script` 또는 `script`에 정의된 명령으로 인한 변경 사항에 접근할 수 없습니다. 여기에는 다음이 포함됩니다:
  - `script` 스크립트에서 내보낸 명령 별칭 및 변수.
  - `before_script` 또는 `script` 스크립트로 설치된 소프트웨어 등 작업 트리 외부의 변경 사항(러너 실행기에 따라 다름).
- 별도의 타임아웃을 갖습니다. GitLab Runner 16.4 이상의 경우 기본값은 5분이며 [`RUNNER_AFTER_SCRIPT_TIMEOUT`](../runners/configure_runners.md#set-script-and-after_script-timeouts) 변수로 구성할 수 있습니다. GitLab 16.3 이전 버전에서는 타임아웃이 5분으로 고정되어 있습니다.
- 작업의 종료 코드에 영향을 주지 않습니다. `script` 섹션이 성공하고 `after_script`가 시간 초과되거나 실패하면 작업은 코드 `0`(`Job Succeeded`)으로 종료됩니다.
- 시간이 초과된 작업의 경우:
  - `after_script` 명령은 기본적으로 실행되지 않습니다.
  - `after_script`이 실행되도록 [타임아웃 값 구성](../runners/configure_runners.md#ensuring-after_script-execution)을 수행하여 적절한 `RUNNER_SCRIPT_TIMEOUT` 및 `RUNNER_AFTER_SCRIPT_TIMEOUT` 값이 작업의 타임아웃을 초과하지 않는지 확인할 수 있습니다.
- `after_script`을 최상위 수준에서 사용하되 `default` 섹션에서는 사용하지 않는 것은 [더 이상 사용되지 않습니다](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script).

**Execution timing and file inclusion**:

`after_script` 명령은 캐시 및 아티팩트 업로드 작업 전에 실행됩니다.

- 아티팩트 수집을 구성한 경우:
  - `after_script`에서 생성되거나 수정된 파일이 아티팩트에 포함됩니다.
  - `after_script`에서 수행된 변경 사항이 캐시 업로드에 포함됩니다.
- `after_script`이 지정된 캐시 또는 아티팩트 경로에서 생성하거나 수정하는 모든 파일이 캡처되어 업로드됩니다. 이 타이밍은 다음과 같은 시나리오에 사용할 수 있습니다:
  - 기본 스크립트 후 테스트 리포트 또는 커버리지 데이터 생성.
  - 요약 파일 또는 로그 생성.
  - 빌드 출력 후 처리.

다음 예에서 포함되지 않는 유일한 파일은 아티팩트 또는 캐시 업로드 스테이지 후에 생성되거나 수정된 파일입니다:

```yaml
job:
  script:
    - echo "main" > output.txt
    - build_something

  after_script:
    - echo "modified in after_script" >> output.txt  # This WILL be in the artifact
    - generate_test_report > report.html            # This WILL be in the artifact

  artifacts:
    paths:
      - output.txt
      - report.html

  cache:
    paths:
      - output.txt  # Will include the "modified in after_script" line
```

자세한 내용은 [작업 실행 흐름](../jobs/job_execution.md)을 참조하세요.

**Related topics**:

- [`after_script`과 `default` 사용](script.md#set-a-default-before_script-or-after_script-for-all-jobs)하여 모든 작업 후에 실행해야 할 명령의 기본 배열을 정의합니다.
- 작업이 취소된 경우 [`after_script` 명령 건너뛰기](script.md#skip-after_script-commands-if-a-job-is-canceled)로 작업을 구성할 수 있습니다.
- [0이 아닌 종료 코드 무시](script.md#ignore-non-zero-exit-codes)할 수 있습니다.
- [`after_script`과 함께 색상 코드 사용](script.md#add-color-codes-to-script-output)하여 작업 로그를 더 쉽게 검토할 수 있습니다.
- [사용자 정의 축소 가능한 섹션 만들기](../jobs/job_logs.md#create-custom-collapsible-sections)로 작업 로그 출력을 단순화합니다.
- [`after_script`의 오류 무시](../runners/configure_runners.md#ignore-errors-in-after_script)할 수 있습니다.

---

### `allow_failure` {#allow_failure}

`allow_failure`을 사용하여 작업이 실패할 때 파이프라인이 계속 실행되어야 하는지 여부를 결정합니다.

- 파이프라인이 계속 실행되도록 하려면 `allow_failure: true`을 사용합니다.
- 파이프라인이 후속 작업 실행을 중지하도록 하려면 `allow_failure: false`을 사용합니다.

작업이 실패하도록 허용되면(`allow_failure: true`) 주황색 경고({{< icon name="status_warning" >}})가 작업이 실패했음을 나타냅니다. 하지만 파이프라인은 성공하고 연결된 커밋은 경고 없이 통과로 표시됩니다.

이 동일한 경고는 다음의 경우에 표시됩니다:

- 스테이지의 다른 모든 작업이 성공합니다.
- 파이프라인의 다른 모든 작업이 성공합니다.

`allow_failure`의 기본값은:

- [수동 작업](../jobs/job_control.md#create-a-job-that-must-be-run-manually)의 경우 `true`.
- [`rules`](#rules) 내에서 `when: manual`을 사용하는 작업의 경우 `false`.
- 다른 모든 경우의 경우 `false`.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `true` 또는 `false`.

**`allow_failure`의 예**:

```yaml
job1:
  stage: test
  script:
    - execute_script_1

job2:
  stage: test
  script:
    - execute_script_2
  allow_failure: true

job3:
  stage: deploy
  script:
    - deploy_to_staging
  environment: staging
```

이 예에서 `job1` 및 `job2`는 병렬로 실행됩니다:

- `job1`이 실패하면 `deploy` 스테이지의 작업이 시작되지 않습니다.
- `job2`이 실패해도 `deploy` 스테이지의 작업이 여전히 시작될 수 있습니다.

**Additional details**:

- `allow_failure`을 [`rules`](#rulesallow_failure)의 하위 키로 사용할 수 있습니다.
- `allow_failure: true`이 설정되면 작업은 항상 성공한 것으로 간주되며 이 작업이 실패하면 [`when: on_failure`](#when)을 사용하는 후속 작업이 시작되지 않습니다.
- `allow_failure: false`을 수동 작업과 함께 사용하여 [차단 수동 작업](../jobs/job_control.md#types-of-manual-jobs)을 만들 수 있습니다. 차단된 파이프라인은 수동 작업이 시작되고 성공적으로 완료될 때까지 이후 스테이지의 작업을 실행하지 않습니다.

---

#### `allow_failure:exit_codes` {#allow_failureexit_codes}

`allow_failure:exit_codes`을 사용하여 작업이 실패하도록 허용되어야 하는 시기를 제어합니다. 작업은 나열된 종료 코드의 경우 `allow_failure: true`이며 다른 종료 코드의 경우 `allow_failure` false입니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 단일 종료 코드.
- 종료 코드 배열.

**`allow_failure`의 예**:

```yaml
test_job_1:
  script:
    - echo "Run a script that results in exit code 1. This job fails."
    - exit 1
  allow_failure:
    exit_codes: 137

test_job_2:
  script:
    - echo "Run a script that results in exit code 137. This job is allowed to fail."
    - exit 137
  allow_failure:
    exit_codes:
      - 137
      - 255
```

---

### `artifacts` {#artifacts}

{{< history >}}

- [업데이트됨](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5543) GitLab Runner 18.1에서. 캐싱 프로세스 중에 `symlinks`은 더 이상 따라가지 않으며, 이는 이전 러너 버전의 일부 엣지 케이스에서 발생했습니다.

{{< /history >}}

`artifacts`을 사용하여 [작업 아티팩트](../jobs/job_artifacts.md)로 저장할 파일을 지정합니다. 작업 아티팩트는 작업이 [성공, 실패 또는 항상](#artifactswhen)하면 작업에 첨부되는 파일 및 디렉터리의 목록입니다.

아티팩트는 작업이 완료된 후 GitLab으로 전송됩니다. 크기가 [최대 아티팩트 크기](../../user/gitlab_com/_index.md#cicd)보다 작으면 GitLab UI에서 다운로드할 수 있습니다.

기본적으로 이후 스테이지의 작업은 이전 스테이지의 작업에서 만든 모든 아티팩트를 자동으로 다운로드합니다. [`dependencies`](#dependencies)를 사용하여 작업에서 아티팩트 다운로드 동작을 제어할 수 있습니다.

[`needs`](#needs) 키워드를 사용할 때 작업은 `needs` 구성에 정의된 작업의 아티팩트만 다운로드할 수 있습니다.

작업 아티팩트는 기본적으로 성공한 작업에서만 수집되며 아티팩트는 [캐시](#cache) 후에 복원됩니다.

작업 구성과 기본 구성은 함께 병합되지 않습니다. 파이프라인에 [`default:artifacts`](#default)가 정의되어 있고 작업에도 `artifacts`이 있으면 작업 구성이 우선적으로 적용되고 기본 구성은 사용되지 않습니다.

[아티팩트에 대해 자세히 알아보기](../jobs/job_artifacts.md).

---

#### `artifacts:paths` {#artifactspaths}

경로는 프로젝트 디렉터리(`$CI_PROJECT_DIR`)를 기준으로 하며 직접 외부로 연결할 수 없습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 프로젝트 디렉터리를 기준으로 한 파일 경로 배열입니다.
- [glob](https://en.wikipedia.org/wiki/Glob_(programming)) 패턴 및 [`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match) 패턴을 사용하는 와일드카드를 사용할 수 있습니다.
- [GitLab Pages 작업](#pages)의 경우:
  - [GitLab 17.10 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)에서 [`pages.publish`](#pagespublish) 경로가 자동으로 `artifacts:paths`에 추가되므로 다시 지정할 필요가 없습니다.
  - [GitLab 17.10 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)에서 [`pages.publish`](#pagespublish) 경로가 지정되지 않으면 `public` 디렉터리가 자동으로 `artifacts:paths`에 추가됩니다.

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`artifacts:paths`의 예**:

```yaml
job:
  artifacts:
    paths:
      - binaries/
      - .config
```

이 예는 `.config` 및 `binaries` 디렉터리의 모든 파일이 포함된 아티팩트를 생성합니다.

**Additional details**:

- [`artifacts:name`](#artifactsname)와 함께 사용하지 않으면 아티팩트 파일의 이름은 `artifacts`이며, 다운로드할 때 `artifacts.zip`가 됩니다.

**Related topics**:

- 특정 작업이 아티팩트를 가져오는 작업을 제한하려면 [`dependencies`](#dependencies)를 참조하세요.
- [작업 아티팩트 만들기](../jobs/job_artifacts.md#create-job-artifacts).

---

#### `artifacts:exclude` {#artifactsexclude}

`artifacts:exclude`을 사용하여 파일이 아티팩트 아카이브에 추가되지 않도록 방지합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 프로젝트 디렉터리를 기준으로 한 파일 경로 배열입니다.
- [glob](https://en.wikipedia.org/wiki/Glob_(programming)) 또는 [`doublestar.PathMatch`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#PathMatch) 패턴을 사용하는 와일드카드를 사용할 수 있습니다.

**`artifacts:exclude`의 예**:

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/**/*.o
```

이 예는 `binaries/`의 모든 파일을 저장하지만 `binaries/`의 하위 디렉터리에 있는 `*.o` 파일은 제외합니다.

**Additional details**:

- `artifacts:exclude` 경로는 재귀적으로 검색되지 않습니다.
- [`artifacts:untracked`](#artifactsuntracked)와 일치하는 파일은 `artifacts:exclude`을 사용하여 제외할 수도 있습니다.

**Related topics**:

- [작업 아티팩트에서 파일 제외](../jobs/job_artifacts.md#without-excluded-files).

---

#### `artifacts:expire_in` {#artifactsexpire_in}

`expire_in`을 사용하여 [작업 아티팩트](../jobs/job_artifacts.md)가 만료되고 삭제되기 전에 저장되는 기간을 지정합니다. `expire_in` 설정은 다음에 영향을 주지 않습니다:

- 최신 작업의 아티팩트. 다만 [프로젝트 수준](../jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)에서 또는 [인스턴스 전체](../../administration/settings/continuous_integration.md#keep-artifacts-from-latest-successful-pipelines)에서 최신 작업 아티팩트 보관이 비활성화되지 않은 경우는 제외됩니다.

만료 후 아티팩트는 기본적으로 시간당 한 번씩(크론 작업 사용) 삭제되며 더 이상 액세스할 수 없습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**: 만료 시간입니다. 단위를 제공하지 않으면 시간이 초 단위입니다. 유효한 값은 다음을 포함합니다:

- `'42'`
- `42 seconds`
- `3 mins 4 sec`
- `2 hrs 20 min`
- `2h20min`
- `6 mos 1 day`
- `47 yrs 6 mos and 4d`
- `3 weeks and 2 days`
- `never`

**`artifacts:expire_in`의 예**:

```yaml
job:
  artifacts:
    expire_in: 1 week
```

**Additional details**:

- 만료 시간은 아티팩트가 GitLab에 업로드되고 저장될 때 시작됩니다. 만료 시간이 정의되지 않으면 [인스턴스 차원의 설정](../../administration/settings/continuous_integration.md#set-default-artifacts-expiration)으로 기본 설정됩니다.
- 만료 날짜를 무시하고 아티팩트가 자동으로 삭제되지 않도록 보호하려면:
  - 작업 페이지에서 **유지**를 선택합니다.
  - `expire_in`의 값을 `never`로 설정합니다.
- 만료 시간이 너무 짧으면 긴 파이프라인의 이후 스테이지의 작업이 이전 작업의 만료된 아티팩트를 가져오려고 시도할 수 있습니다. 아티팩트가 만료되면 아티팩트를 가져오려고 하는 작업이 [`could not retrieve the needed artifacts` 오류](../jobs/job_artifacts_troubleshooting.md#error-message-this-job-could-not-start-because-it-could-not-retrieve-the-needed-artifacts)로 실패합니다. 만료 시간을 더 길게 설정하거나 [`dependencies`](#dependencies)을 나중의 작업에서 사용하여 만료된 아티팩트를 가져오려고 하지 않도록 합니다.
- `artifacts:expire_in`은 GitLab Pages 배포에 영향을 주지 않습니다. Pages 배포의 만료를 구성하려면 [`pages.expire_in`](#pagesexpire_in)을 사용합니다.

---

#### `artifacts:expose_as` {#artifactsexpose_as}

`artifacts:expose_as` 키워드를 사용하여 [머지 리퀘스트 UI에서 아티팩트 노출](../jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui)합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 머지 리퀘스트 UI의 아티팩트 다운로드 링크에 표시할 이름입니다. [`artifacts:paths`](#artifactspaths)와 함께 사용해야 합니다.

**`artifacts:expose_as`의 예**:

```yaml
test:
  script: ["echo 'test' > file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['file.txt']
```

**Additional details**:

- `expose_as`은 작업당 한 번만 사용할 수 있으며 머지 리퀘스트당 최대 10개의 작업이 가능합니다.
- Glob 패턴은 지원되지 않습니다.
- 아티팩트는 항상 GitLab으로 전송됩니다. `artifacts:paths` 값이 다음과 같은 경우를 제외하고는 UI에 표시됩니다:
  - [CI/CD 변수](../variables/_index.md)를 사용합니다.
  - 디렉터리를 정의하지만 `/`으로 끝나지 않습니다. 예를 들어 `directory/`은 `artifacts:expose_as`과 함께 작동하지만 `directory`은 그렇지 않습니다.
- `artifacts:paths`이 단일 파일만 포함하면 링크가 파일을 직접 엽니다. 다른 모든 경우에는 링크가 [아티팩트 브라우저](../jobs/job_artifacts.md#download-job-artifacts)를 엽니다.
- 연결된 파일은 기본적으로 다운로드됩니다. [GitLab Pages](../../administration/pages/_index.md)가 활성화되어 있으면 브라우저에서 일부 아티팩트 파일 확장자를 직접 미리 볼 수 있습니다. 자세한 내용은 [아티팩트 아카이브의 내용 찾아보기](../jobs/job_artifacts.md#browse-the-contents-of-the-artifacts-archive)를 참조하세요.

**Related topics**:

- [머지 리퀘스트 UI에서 작업 아티팩트 노출](../jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui).

---

#### `artifacts:name` {#artifactsname}

`artifacts:name` 키워드를 사용하여 만든 아티팩트 아카이브의 이름을 정의합니다. 모든 아카이브에 대해 고유한 이름을 지정할 수 있습니다.

정의되지 않으면 기본 이름은 `artifacts`이며, 다운로드할 때 `artifacts.zip`가 됩니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 아티팩트 아카이브의 이름입니다. CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file). [`artifacts:paths`](#artifactspaths)와 함께 사용해야 합니다.

**`artifacts:name`의 예**:

현재 작업의 이름으로 아카이브를 만들려면:

```yaml
job:
  artifacts:
    name: "job1-artifacts-file"
    paths:
      - binaries/
```

**Related topics**:

- [CI/CD 변수를 사용하여 아티팩트 구성 정의](../jobs/job_artifacts.md#with-variable-expansion)

---

#### `artifacts:public` {#artifactspublic}

> [!note]
> `artifacts:public`은 더 많은 옵션이 있는 [`artifacts:access`](#artifactsaccess)로 대체되었습니다.

`artifacts:public`을 사용하여 공개 파이프라인의 작업 아티팩트가 익명 사용자, 게스트 및 리포터 역할에 의해 GitLab UI 및 API를 통해 다운로드되는지 여부를 제어합니다.

> [!warning]
> 이 옵션은 GitLab UI 및 API 액세스에만 영향을 줍니다. 작업 토큰을 사용하는 CI/CD 작업은 여전히 이 설정에 관계없이 러너 API를 사용하여 아티팩트에 액세스할 수 있습니다. 작업 토큰 액세스를 제한하려면 프로젝트의 [CI/CD 가시성 설정](../../user/project/settings/_index.md#configure-project-features-and-permissions)을 **Only project members**으로 구성합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- `true`(기본값): 공개 파이프라인의 작업 아티팩트는 익명 사용자, 게스트 및 리포터 역할을 포함한 모든 사람이 다운로드할 수 있습니다.
- `false`: 작업의 아티팩트는 개발자, 유지 관리자 또는 소유자 역할을 가진 사용자만 다운로드할 수 있습니다.

**`artifacts:public`의 예**:

```yaml
job:
  artifacts:
    public: false
```

---

#### `artifacts:access` {#artifactsaccess}

{{< history >}}

- `maintainer` 옵션은 [GitLab 18.4에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/454398).

{{< /history >}}

`artifacts:access`을 사용하여 GitLab UI 또는 API에서 작업 아티팩트에 액세스할 수 있는 사람을 결정합니다. 이 옵션은 아티팩트를 다운스트림 파이프라인으로 전달하는 것을 방지하지 않습니다.

[`artifacts:public`](#artifactspublic) 및 `artifacts:access`을 동일한 작업에서 사용할 수 없습니다.

> [!warning]
> 이 옵션은 GitLab UI 및 API 액세스에만 영향을 줍니다. 작업 토큰을 사용하는 CI/CD 작업은 여전히 이 설정에 관계없이 러너 API를 사용하여 아티팩트에 액세스할 수 있습니다. 작업 토큰 액세스를 제한하려면 프로젝트의 [CI/CD 가시성 설정](../../user/project/settings/_index.md#configure-project-features-and-permissions)을 **Only project members**으로 구성합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `all`(기본값): 공개 파이프라인의 작업 아티팩트는 익명, 게스트 및 리포터 사용자를 포함한 모든 사람이 다운로드할 수 있습니다.
- `developer`: 작업의 아티팩트는 개발자, 유지 관리자 또는 소유자 역할을 가진 사용자만 다운로드할 수 있습니다.
- `maintainer`: 작업의 아티팩트는 유지 관리자 또는 소유자 역할을 가진 사용자만 다운로드할 수 있습니다.
- `none`: 작업의 아티팩트는 누구도 다운로드할 수 없습니다.

**`artifacts:access`의 예**:

```yaml
job:
  artifacts:
    access: 'developer'
```

**Additional details**:

- `artifacts:access`은 모든 [`artifacts:reports`](#artifactsreports)에도 영향을 주므로 [리포트용 아티팩트](artifacts_reports.md)에 대한 액세스를 제한할 수도 있습니다.

---

#### `artifacts:reports` {#artifactsreports}

[`artifacts:reports`](artifacts_reports.md)을 사용하여 작업에 포함된 템플릿에서 생성한 아티팩트를 수집합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 사용 가능한 [아티팩트 리포트 유형](artifacts_reports.md) 목록을 참조하세요.

**`artifacts:reports`의 예**:

```yaml
rspec:
  stage: test
  script:
    - bundle install
    - rspec --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
```

**Additional details**:

- [자식 파이프라인의 아티팩트](#needspipelinejob)를 사용하여 부모 파이프라인에서 리포트를 결합하는 것은 지원되지 않습니다. 자세한 내용은 [에픽 8205](https://gitlab.com/groups/gitlab-org/-/work_items/8205)를 참조하세요.
- 리포트 출력 파일을 찾아보고 다운로드할 수 있도록 [`artifacts:paths`](#artifactspaths) 키워드를 포함합니다. 이렇게 하면 아티팩트가 두 번 업로드되고 저장됩니다.
- `artifacts: reports`에 대해 생성된 아티팩트는 작업 결과(성공 또는 실패) 관계없이 항상 업로드됩니다. [`artifacts:expire_in`](#artifactsexpire_in)을 사용하여 아티팩트의 만료 날짜를 설정할 수 있습니다.

---

#### `artifacts:untracked` {#artifactsuntracked}

`artifacts:untracked`을 사용하여 `artifacts:paths`에 정의된 경로와 함께 모든 Git 추적되지 않은 파일을 아티팩트로 추가합니다. `artifacts:untracked`은 리포지토리의 `.gitignore` 구성을 무시하므로 `.gitignore`와 일치하는 아티팩트가 포함됩니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- `true` 또는 `false`(정의되지 않은 경우 기본값).

**`artifacts:untracked`의 예**:

모든 Git 추적되지 않은 파일을 저장합니다:

```yaml
job:
  artifacts:
    untracked: true
```

**Related topics**:

- [추적되지 않은 파일을 아티팩트에 추가](../jobs/job_artifacts.md#with-untracked-files).

---

#### `artifacts:when` {#artifactswhen}

`artifacts:when`을 사용하여 작업 실패 또는 실패에 관계없이 아티팩트를 업로드합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- `on_success`(기본값): 작업이 성공할 때만 아티팩트를 업로드합니다.
- `on_failure`: 작업이 실패할 때만 아티팩트를 업로드합니다.
- `always`: 항상 아티팩트를 업로드합니다(작업 시간 초과 제외). 예를 들어 [실패한 테스트를 해결하는 데 필요한 아티팩트 업로드](../testing/unit_test_reports.md#add-screenshots-to-test-reports).

**`artifacts:when`의 예**:

```yaml
job:
  artifacts:
    when: on_failure
```

**Additional details**:

- [`artifacts:reports`](#artifactsreports)에 대해 생성된 아티팩트는 작업 결과(성공 또는 실패)에 관계없이 항상 업로드됩니다. `artifacts:when`은 이 동작을 변경하지 않습니다.

---

### `before_script` {#before_script}

`before_script`을 사용하여 각 작업의 `script` 명령 전에 실행되어야 하지만 [아티팩트](#artifacts)가 복원된 후에 실행되는 명령 배열을 정의합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**: 다음을 포함하는 배열:

- 한 줄 명령.
- 여러 줄로 [분할된](script.md#split-long-commands) 긴 명령.
- [YAML 앵커](yaml_optimization.md#yaml-anchors-for-scripts).

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`before_script`의 예**:

```yaml
job:
  before_script:
    - echo "Execute this command before any 'script:' commands."
  script:
    - echo "This command executes after the job's 'before_script' commands."
```

**Additional details**:

- `before_script`에 지정된 스크립트는 기본 [`script`](#script)에 지정된 모든 스크립트와 연결됩니다. 결합된 스크립트는 단일 셸에서 함께 실행됩니다.
- `before_script`을 최상위 수준에서 사용하되 `default` 섹션에서는 사용하지 않는 것은 [더 이상 사용되지 않습니다](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script).

**Related topics**:

- [`before_script`과 `default` 사용](script.md#set-a-default-before_script-or-after_script-for-all-jobs)하여 모든 작업의 `script` 명령 전에 실행되는 명령의 기본 배열을 정의합니다.
  - 작업 구성과 기본 구성은 함께 병합되지 않습니다. 파이프라인에 [`default:before_script`](#default)가 정의되어 있고 작업에도 `before_script`이 있으면 작업 구성이 우선적으로 적용되고 기본 구성은 사용되지 않습니다.
- [0이 아닌 종료 코드 무시](script.md#ignore-non-zero-exit-codes)할 수 있습니다.
- [`before_script`과 함께 색상 코드 사용](script.md#add-color-codes-to-script-output)하여 작업 로그를 더 쉽게 검토할 수 있습니다.
- [사용자 정의 축소 가능한 섹션 만들기](../jobs/job_logs.md#create-custom-collapsible-sections)로 작업 로그 출력을 단순화합니다.

---

### `cache` {#cache}

{{< history >}}

- [GitLab 15.0에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/330047), 캐시는 보호된 브랜치와 보호되지 않은 브랜치 간에 공유되지 않습니다.
- [업데이트됨](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5543) GitLab Runner 18.1에서. 캐싱 프로세스 중에 `symlinks`은 더 이상 따라가지 않으며, 이는 이전 러너 버전의 일부 엣지 케이스에서 발생했습니다.

{{< /history >}}

`cache`을 사용하여 작업 간 캐시할 파일 및 디렉터리 목록을 지정합니다. 로컬 작업 복사본에 있는 경로만 사용할 수 있습니다.

캐시는 다음과 같은 특징이 있습니다:

- 파이프라인과 작업 간에 공유됩니다.
- 기본적으로 [보호된](../../user/project/repository/branches/protected.md) 브랜치와 보호되지 않은 브랜치 간에 공유되지 않습니다.
- [아티팩트](#artifacts) 전에 복원됩니다.
- 최대 4개의 [서로 다른 캐시](../caching/_index.md#use-multiple-caches)로 제한됩니다.

예를 들어 다음을 무시하기 위해 [특정 작업에 대한 캐싱 비활성화](../caching/_index.md#disable-cache-for-specific-jobs)할 수 있습니다:

- [`default`](#default)로 정의된 기본 캐시.
- [`include`](#include)를 통해 작업에 추가된 구성.

작업 구성과 기본 구성은 함께 병합되지 않습니다. 파이프라인에 [`default:cache`](#default)가 정의되어 있고 작업에도 `cache`이 있으면 작업 구성이 우선적으로 적용되고 기본 구성은 사용되지 않습니다.

캐시에 대한 자세한 내용은 [GitLab CI/CD의 캐싱](../caching/_index.md)을 참조하세요.

`cache`을 최상위 수준에서 사용하되 `default` 섹션에서는 사용하지 않는 것은 [더 이상 사용되지 않습니다](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script).

---

#### `cache:paths` {#cachepaths}

`cache:paths` 키워드를 사용하여 캐시할 파일 또는 디렉터리를 선택합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 프로젝트 디렉터리(`$CI_PROJECT_DIR`)를 기준으로 한 경로 배열입니다. [glob](https://en.wikipedia.org/wiki/Glob_(programming)) 및 [`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match) 패턴을 사용하는 와일드카드를 사용할 수 있습니다.

[CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file) 지원됩니다.

**`cache:paths`의 예**:

`binaries`에서 `.apk`으로 끝나는 모든 파일과 `.config` 파일을 캐시합니다:

```yaml
rspec:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache
    paths:
      - binaries/*.apk
      - .config
```

**Additional details**:

- `cache:paths` 키워드는 `.gitignore` 파일에 있거나 추적되지 않은 경우에도 파일을 포함합니다.

**Related topics**:

- [CI/CD 캐싱 예](../caching/examples.md)에서 더 많은 `cache:paths` 예를 참조하세요.

---

#### `cache:key` {#cachekey}

`cache:key` 키워드를 사용하여 각 캐시에 고유한 식별자를 부여합니다. 동일한 캐시 키를 사용하는 모든 작업은 다른 파이프라인의 동일한 캐시를 사용합니다.

설정되지 않으면 기본 키는 `default`입니다. `cache` 키워드가 있지만 `cache:key`이 없는 모든 작업은 `default` 캐시를 공유합니다.

`cache: paths`과 함께 사용해야 하거나 아무것도 캐시되지 않습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 문자열입니다.
- 미리 정의된 [CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).
- 둘의 조합입니다.

**`cache:key`의 예**:

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

**Additional details**:

- **Windows Batch**를 사용하여 셸 스크립트를 실행하면 `$`을 `%`로 바꿔야 합니다. 예를 들어: `key: %CI_COMMIT_REF_SLUG%`
- `cache:key` 값은 다음을 포함할 수 없습니다:
  - `/` 문자 또는 동등한 URI 인코딩된 `%2F`.
  - `.` 문자만(임의 개수) 또는 동등한 URI 인코딩된 `%2E`.
- 캐시는 작업 간에 공유되므로 다른 작업에 서로 다른 경로를 사용하는 경우 다른 `cache:key`도 설정해야 합니다. 그렇지 않으면 캐시 내용이 덮어쓰기될 수 있습니다.

**Related topics**:

- 지정된 `cache:key`을 찾을 수 없는 경우 사용할 [폴백 캐시 키](../caching/_index.md#use-a-fallback-cache-key)를 지정할 수 있습니다.
- 단일 작업에서 [여러 캐시 키](../caching/_index.md#use-multiple-caches)를 사용할 수 있습니다.
- [CI/CD 캐싱 예](../caching/examples.md)에서 더 많은 `cache:key` 예를 참조하세요.

---

##### `cache:key:files` {#cachekeyfiles}

`cache:key:files`을 사용하여 지정된 파일의 내용이 변경되면 새 캐시 키를 생성합니다. 내용이 변경되지 않으면 캐시 키는 브랜치와 파이프라인에서 일관되게 유지됩니다. 캐시를 재사용하고 덜 자주 다시 빌드할 수 있으므로 후속 파이프라인 실행 속도가 높아집니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 최대 2개의 파일 경로 또는 패턴 배열입니다.

CI/CD 변수는 지원되지 않습니다.

**`cache:key:files`의 예**:

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key:
      files:
        - Gemfile.lock
        - package.json
    paths:
      - vendor/ruby
      - node_modules
```

이 예는 Ruby 및 Node.js 종속성에 대한 캐시를 생성합니다. 캐시는 `Gemfile.lock` 및 `package.json` 파일의 현재 버전과 연결됩니다. 이들 파일 중 하나가 변경되면 새 캐시 키가 계산되고 새 캐시가 생성됩니다. 향후 `Gemfile.lock` 및 `package.json`을 `cache:key:files`와 함께 사용하는 작업 실행은 종속성을 다시 빌드하는 대신 새 캐시를 사용합니다.

**Additional details**:

- 캐시 `key`은 나열된 파일의 내용에서 계산된 SHA입니다. 파일이 없으면 키 계산에서 무시됩니다. 지정된 파일이 없으면 폴백 키는 `default`입니다.
- `**/package.json`과 같은 와일드카드 패턴을 사용할 수 있습니다.
- 최대 2개의 파일을 지정할 수 있습니다. 허용된 경로 또는 패턴의 수를 늘리는 업데이트는 [이슈 301161](https://gitlab.com/gitlab-org/gitlab/-/work_items/301161)을 참조하세요.

---

##### `cache:key:files_commits` {#cachekeyfiles_commits}

`cache:key:files_commits`을 사용하여 지정된 파일의 최신 커밋이 변경되면 새 캐시 키를 생성합니다. `cache:key:files_commits` 캐시 키는 지정된 파일이 새 커밋을 가질 때마다 변경되며, 파일 내용이 동일하게 유지되더라도 변경됩니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 최대 2개의 파일 경로 또는 패턴 배열입니다.

**`cache:key:files_commits`의 예**:

```yaml
cache-job:
  script:
    - echo "This job uses a commit-based cache."
  cache:
    key:
      files_commits:
        - package.json
        - yarn.lock
    paths:
      - node_modules
```

이 예는 `package.json` 및 `yarn.lock`의 커밋 히스토리를 기반으로 캐시를 생성합니다. 이들 파일의 커밋 히스토리가 변경되면 새 캐시 키가 계산되고 새 캐시가 생성됩니다.

**Additional details**:

- 캐시 `key`은 각 지정된 파일의 최근 커밋에서 계산된 SHA입니다.
- 파일이 없으면 키 계산에서 무시됩니다.
- 지정된 파일이 없으면 폴백 키는 `default`입니다.
- 동일한 캐시 구성에서 [`cache:key:files`](#cachekeyfiles)와 함께 사용할 수 없습니다.

---

##### `cache:key:prefix` {#cachekeyprefix}

`cache:key:prefix`을 사용하여 [`cache:key:files`](#cachekeyfiles)에 대해 계산된 SHA로 접두사를 결합합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 문자열입니다.
- 미리 정의된 [CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).
- 둘의 조합입니다.

**`cache:key:prefix`의 예**:

```yaml
rspec:
  script:
    - echo "This rspec job uses a cache."
  cache:
    key:
      files:
        - Gemfile.lock
      prefix: $CI_JOB_NAME
    paths:
      - vendor/ruby
```

예를 들어 `prefix`을 `$CI_JOB_NAME`로 추가하면 키가 `rspec-feef9576d21ee9b6a32e30c5c79d0a0ceb68d1e5`과 같아집니다. 브랜치가 `Gemfile.lock`을 변경하면 해당 브랜치는 `cache:key:files`에 대한 새로운 SHA 체크섬을 갖습니다. 새 캐시 키가 생성되고 해당 키에 대한 새 캐시가 생성됩니다. `Gemfile.lock`을 찾을 수 없으면 접두사가 `default`에 추가되므로 예의 키는 `rspec-default`이 됩니다.

**Additional details**:

- `cache:key:files`의 파일이 커밋에서 변경되지 않으면 접두사가 `default` 키에 추가됩니다.

---

#### `cache:untracked` {#cacheuntracked}

`untracked: true`을 사용하여 Git 리포지토리에서 추적되지 않은 모든 파일을 캐시합니다. 추적되지 않은 파일은 다음을 포함합니다:

- [`.gitignore` 구성](https://git-scm.com/docs/gitignore)으로 인해 무시됩니다.
- [`git add`](https://git-scm.com/docs/git-add)와 함께 체크아웃에 추가되지 않고 생성됩니다.

작업이 다운로드하는 경우 추적되지 않은 파일을 캐시하면 예기치 않게 큰 캐시가 생성될 수 있습니다:

- 일반적으로 추적되지 않는 gem 또는 노드 모듈과 같은 종속성.
- 다른 작업의 [아티팩트](#artifacts). 아티팩트에서 추출된 파일은 기본적으로 추적되지 않습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- `true` 또는 `false`(기본값).

**`cache:untracked`의 예**:

```yaml
rspec:
  script: test
  cache:
    untracked: true
```

**Additional details**:

- `cache:untracked`을 `cache:paths`와 결합하여 구성된 경로의 모든 파일뿐만 아니라 추적되지 않은 모든 파일을 캐시할 수 있습니다. `cache:paths`을 사용하여 추적된 파일을 포함한 특정 파일이나 작업 디렉터리 외부의 파일을 캐시하고, `cache: untracked`을 사용하여 추적되지 않은 모든 파일도 캐시합니다. 예를 들어:

  ```yaml
  rspec:
    script: test
    cache:
      untracked: true
      paths:
        - binaries/
  ```

  이 예에서 작업은 리포지토리의 모든 추적되지 않은 파일 및 `binaries/`의 모든 파일을 캐시합니다. `binaries/`에 추적되지 않은 파일이 있으면 두 키워드 모두 다룹니다.

---

#### `cache:unprotect` {#cacheunprotect}

{{< history >}}

- GitLab 15.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/362114)되었습니다.

{{< /history >}}

`cache:unprotect`을 사용하여 [보호된](../../user/project/repository/branches/protected.md) 브랜치와 보호되지 않은 브랜치 간에 공유되는 캐시를 설정합니다.

> [!warning]
> `true`로 설정되면 보호된 브랜치에 액세스할 수 없는 사용자가 보호된 브랜치에서 사용하는 캐시 키를 읽고 쓸 수 있습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- `true` 또는 `false`(기본값).

**`cache:unprotect`의 예**:

```yaml
rspec:
  script: test
  cache:
    unprotect: true
```

---

#### `cache:when` {#cachewhen}

`cache:when`을 사용하여 작업 상태를 기반으로 캐시를 저장할 시기를 정의합니다.

`cache: paths`과 함께 사용해야 하거나 아무것도 캐시되지 않습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- `on_success`(기본값): 작업이 성공할 때만 캐시를 저장합니다.
- `on_failure`: 작업이 실패할 때만 캐시를 저장합니다.
- `always`: 항상 캐시를 저장합니다.

**`cache:when`의 예**:

```yaml
rspec:
  script: rspec
  cache:
    paths:
      - rspec/
    when: 'always'
```

이 예는 작업이 실패하든지 성공하든지 캐시를 저장합니다.

---

#### `cache:policy` {#cachepolicy}

캐시의 업로드 및 다운로드 동작을 변경하려면 `cache:policy` 키워드를 사용합니다. 기본적으로 작업은 작업 시작 시 캐시를 다운로드하고 작업 종료 시 캐시 변경 사항을 업로드합니다. 이 캐싱 스타일은 `pull-push` 정책(기본값)입니다.

작업이 시작할 때만 캐시를 다운로드하지만 종료할 때 변경 사항을 업로드하지 않도록 하려면 `cache:policy:pull`을 사용합니다.

작업이 종료할 때만 캐시를 업로드하지만 시작할 때 다운로드하지 않도록 하려면 `cache:policy:push`을 사용합니다.

동일한 캐시를 사용하는 많은 작업이 병렬로 실행되는 경우 `pull` 정책을 사용합니다. 이 정책은 작업 실행 속도를 높이고 캐시 서버의 부하를 줄입니다. `push` 정책을 사용하여 캐시를 빌드할 작업을 사용할 수 있습니다.

`cache: paths`과 함께 사용해야 하거나 아무것도 캐시되지 않습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- `pull`
- `push`
- `pull-push`(기본값)
- [CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`cache:policy`의 예**:

```yaml
prepare-dependencies-job:
  stage: build
  cache:
    key: gems
    paths:
      - vendor/bundle
    policy: push
  script:
    - echo "This job only downloads dependencies and builds the cache."
    - echo "Downloading dependencies..."

faster-test-job:
  stage: test
  cache:
    key: gems
    paths:
      - vendor/bundle
    policy: pull
  script:
    - echo "This job script uses the cache, but does not update it."
    - echo "Running tests..."
```

**Related topics**:

- [변수를 사용하여 작업의 캐시 정책 제어](../caching/examples.md#use-a-variable-to-control-a-jobs-cache-policy)할 수 있습니다.

---

#### `cache:fallback_keys` {#cachefallback_keys}

`cache:fallback_keys`을 사용하여 `cache:key`에 대한 캐시가 없는 경우 복원하려고 할 키 목록을 지정합니다. 캐시는 `fallback_keys` 섹션에 지정된 순서대로 검색됩니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 캐시 키 배열

**`cache:fallback_keys`의 예**:

```yaml
rspec:
  script: rspec
  cache:
    key: gems-$CI_COMMIT_REF_SLUG
    paths:
      - rspec/
    fallback_keys:
      - gems
    when: 'always'
```

---

### `coverage` {#coverage}

사용자 정의 정규식으로 `coverage`을 사용하여 작업 출력에서 코드 커버리지를 추출하는 방식을 구성합니다. GitLab은 일치하는 백분율을 머지 리퀘스트 위젯, 파이프라인 작업 목록 및 분석 그래프에 표시합니다.

**Supported values**:

- RE2 정규식입니다. `/`로 시작하고 끝나야 합니다. 커버리지 번호와 일치해야 합니다. 주변 텍스트와도 일치할 수 있으므로 정확한 번호를 캡처하기 위해 정규식 문자 그룹을 사용할 필요가 없습니다. RE2 구문을 사용하므로 모든 그룹은 캡처되지 않아야 합니다.

**`coverage`의 예**:

```yaml
job1:
  script: rspec
  coverage: '/Code coverage: \d+(?:\.\d+)?/'
```

이 예에서:

1. GitLab은 작업 로그에서 정규식과의 일치를 확인합니다. `Code coverage: 67.89% of lines covered`과 같은 줄이 일치합니다.
1. GitLab은 일치하는 조각에서 `\d+(?:\.\d+)?`을 확인하여 번호를 추출합니다. 샘플 정규식은 `67.89`과 일치합니다.

**Additional details**:

- 작업 출력에 두 개 이상의 일치하는 줄이 있으면 마지막 줄이 사용됩니다.
- 단일 줄에 여러 일치가 있으면 마지막 일치가 사용됩니다.
- 일치하는 조각에 여러 커버리지 번호가 있으면 첫 번째 번호가 사용됩니다.
- 선행 0은 제거됩니다.
- [자식 파이프라인](../pipelines/downstream_pipelines.md#parent-child-pipelines)의 커버리지 출력은 기록되지 않습니다. [이슈 280818](https://gitlab.com/gitlab-org/gitlab/-/issues/280818)을 참조하세요.
- 머지 리퀘스트 차이에서 줄 단위 diff 주석을 표시하려면 [`artifacts:reports:coverage_report`](artifacts_reports.md#artifactsreportscoverage_report)을 별도로 구성하세요. 하나를 구성한다고 해서 다른 하나가 활성화되지는 않습니다.

**Related topics**:

- [커버리지 정규식 패턴](../testing/code_coverage/coverage_reporting.md#coverage-regex-patterns)
- [커버리지 시각화](../testing/code_coverage/coverage_visualization.md)

---

### `dast_configuration` {#dast_configuration}

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

`dast_configuration` 키워드를 사용하여 CI/CD 구성에서 사용할 사이트 프로필과 스캐너 프로필을 지정하세요. 두 프로필 모두 먼저 프로젝트에서 생성되어야 합니다. 작업의 스테이지는 `dast`이어야 합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: `site_profile`와 `scanner_profile` 각각 하나씩.

- `site_profile`을 사용하여 작업에서 사용할 사이트 프로필을 지정하세요.
- `scanner_profile`을 사용하여 작업에서 사용할 스캐너 프로필을 지정하세요.

**`dast_configuration`의 예**:

```yaml
stages:
  - build
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  dast_configuration:
    site_profile: "Example Co"
    scanner_profile: "Quick Passive Test"
```

이 예에서 `dast` 작업은 `include` 키워드와 함께 추가된 `dast` 구성을 확장하여 특정 사이트 프로필과 스캐너 프로필을 선택합니다.

**Additional details**:

- 사이트 프로필 또는 스캐너 프로필에 포함된 설정은 DAST 템플릿에 포함된 설정보다 우선합니다.

**Related topics**:

- [사이트 프로필](../../user/application_security/dast/profiles.md#site-profile).
- [스캐너 프로필](../../user/application_security/dast/profiles.md#scanner-profile).

---

### `dependencies` {#dependencies}

`dependencies` 키워드를 사용하여 [아티팩트](#artifacts)를 가져올 특정 작업의 목록을 정의하세요. 지정된 작업은 모두 이전 스테이지에 있어야 합니다. 작업을 설정하여 전혀 아티팩트를 다운로드하지 않도록 할 수도 있습니다.

`dependencies`이 작업에 정의되지 않으면 이전 스테이지의 모든 작업이 종속 작업으로 간주되고 작업은 해당 작업에서 모든 아티팩트를 가져옵니다.

동일한 스테이지의 작업에서 아티팩트를 가져오려면 [`needs:artifacts`](#needsartifacts)을 사용해야 합니다. `dependencies`과 `needs`을 동일한 작업에서 결합하지 않아야 합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 아티팩트를 가져올 작업의 이름.
- 빈 배열(`[]`)로 작업이 아티팩트를 다운로드하지 않도록 구성합니다.

**`dependencies`의 예**:

```yaml
build mac:
  stage: build
  script: make build:mac
  artifacts:
    paths:
      - binaries/

build linux:
  stage: build
  script: make build:linux
  artifacts:
    paths:
      - binaries/

test mac:
  stage: test
  script: make test:mac
  dependencies:
    - build mac

test linux:
  stage: test
  script: make test:linux
  dependencies:
    - build linux

deploy:
  stage: deploy
  script: make deploy
  environment: production
```

이 예에서 두 작업이 아티팩트를 가지고 있습니다: `build mac`과 `build linux`. `test mac`이 실행되면 `build mac`의 아티팩트가 다운로드되어 빌드의 컨텍스트에서 추출됩니다. `test linux`과 `build linux`의 아티팩트에 대해서도 동일한 작업이 발생합니다.

`deploy` 작업은 [스테이지](#stages) 우선순위로 인해 모든 이전 작업의 아티팩트를 다운로드합니다.

**Additional details**:

- 이전 작업이 아티팩트를 생성하지 않거나 실행되지 않은 수동 작업인 경우 종속 작업은 여전히 실행되고 오류가 생성되지 않습니다.
- 종속 작업의 아티팩트가 [만료되었거나](#artifactsexpire_in) [삭제된](../jobs/job_artifacts.md#delete-job-log-and-artifacts) 경우 작업은 실패합니다.

---

### `environment` {#environment}

`environment`을 사용하여 작업이 배포하는 [환경](../environments/_index.md)을 정의하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 작업이 배포하는 환경의 이름(다음 형식 중 하나):

- 문자, 숫자, 공백 및 다음 문자를 포함한 일반 텍스트: `-`, `_`, `/`, `$`, `{`, `}`.
- CI/CD 변수(사전 정의된 변수, 프로젝트, 그룹, 인스턴스 또는 `.gitlab-ci.yml` 파일에 정의된 변수 포함). `script` 섹션에 정의된 변수는 사용할 수 없습니다.

**`environment`의 예**:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment: production
```

**Additional details**:

- `environment`을 지정하고 그 이름의 환경이 존재하지 않으면 환경이 생성됩니다.

---

#### `environment:name` {#environmentname}

[환경](../environments/_index.md)의 이름을 설정하세요.

일반적인 환경 이름은 `qa`, `staging` 및 `production`이지만 모든 이름을 사용할 수 있습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 작업이 배포하는 환경의 이름(다음 형식 중 하나):

- 문자, 숫자, 공백 및 다음 문자를 포함한 일반 텍스트: `-`, `_`, `/`, `$`, `{`, `}`.
- [CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)(사전 정의된 변수, 프로젝트, 그룹, 인스턴스 또는 `.gitlab-ci.yml` 파일에 정의된 변수 포함). `script` 섹션에 정의된 변수는 사용할 수 없습니다.

**`environment:name`의 예**:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment:
    name: production
```

---

#### `environment:url` {#environmenturl}

[환경](../environments/_index.md)의 URL을 설정하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 다음 형식 중 하나의 단일 URL:

- `https://prod.example.com`과 같은 일반 텍스트.
- [CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)(사전 정의된 변수, 프로젝트, 그룹, 인스턴스 또는 `.gitlab-ci.yml` 파일에 정의된 변수 포함). `script` 섹션에 정의된 변수는 사용할 수 없습니다.

**`environment:url`의 예**:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment:
    name: production
    url: https://prod.example.com
```

**Additional details**:

- 작업이 완료된 후 머지 리퀘스트, 환경 또는 배포 페이지에서 버튼을 선택하여 URL에 액세스할 수 있습니다.

---

#### `environment:on_stop` {#environmenton_stop}

환경을 종료(중지)하는 것은 `environment` 아래에 정의된 `on_stop` 키워드로 달성할 수 있습니다. 환경을 종료하기 위해 실행할 다른 작업을 선언합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Additional details**:

- 자세한 내용과 예제는 [`environment:action`](#environmentaction)을 참조하세요.

---

#### `environment:action` {#environmentaction}

`action` 키워드를 사용하여 작업이 환경과 상호 작용하는 방식을 지정하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 다음 키워드 중 하나:

| **값** | **설명** |
|:----------|:----------------|
| `start`   | 기본값. 작업이 환경을 시작함을 나타냅니다. 작업이 시작된 후 배포가 생성됩니다. |
| `prepare` | 작업이 환경을 준비하고 있음을 나타냅니다. 배포를 트리거하지 않습니다. [환경 준비에 대해 자세히 알아보세요](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes). |
| `stop`    | 작업이 환경을 중지함을 나타냅니다. [환경 중지에 대해 자세히 알아보세요](../environments/_index.md#stopping-an-environment). |
| `verify`  | 작업이 환경을 확인하고 있음을 나타냅니다. 배포를 트리거하지 않습니다. [환경 검증에 대해 자세히 알아보세요](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes). |
| `access`  | 작업이 환경에만 액세스하고 있음을 나타냅니다. 배포를 트리거하지 않습니다. [환경 액세스에 대해 자세히 알아보세요](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes). |

**`environment:action`의 예**:

```yaml
stop_review_app:
  stage: deploy
  variables:
    GIT_STRATEGY: none
  script: make delete-app
  when: manual
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
```

---

#### `environment:auto_stop_in` {#environmentauto_stop_in}

{{< history >}}

- CI/CD 변수 지원이 GitLab 15.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/365140)되었습니다.
- GitLab 17.7에서 `prepare`, `access` 및 `verify` 환경 동작을 지원하도록 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)되었습니다.

{{< /history >}}

`auto_stop_in` 키워드는 환경의 수명을 지정합니다. 환경이 만료되면 GitLab이 자동으로 환경을 중지합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 자연 언어로 작성된 기간. 예를 들어 다음은 모두 동등합니다:

- `168 hours`
- `7 days`
- `one week`
- `never`

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`environment:auto_stop_in`의 예**:

```yaml
review_app:
  script: deploy-review-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    auto_stop_in: 1 day
```

`review_app`의 환경이 생성되면 환경의 수명이 `1 day`로 설정됩니다. 검토 앱이 배포될 때마다 해당 수명도 `1 day`로 다시 설정됩니다.

`auto_stop_in` 키워드는 `stop`를 제외한 모든 [환경 동작](#environmentaction)에 사용할 수 있습니다. 일부 동작은 환경의 예약된 중지 시간을 재설정하는 데 사용할 수 있습니다. 자세한 내용은 [준비 또는 검증 목적으로 환경에 액세스](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes)를 참조하세요.

**Related topics**:

- [환경 자동 중지 문서](../environments/_index.md#stop-an-environment-after-a-certain-time-period).

---

#### `environment:kubernetes` {#environmentkubernetes}

{{< history >}}

- `agent` 키워드가 GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467912)되었습니다.
- `namespace`과 `flux_resource_path` 키워드가 GitLab 17.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/500164)되었습니다.
- `namespace`과 `flux_resource_path` 키워드가 GitLab 18.4에서 [지원 중단](deprecated_keywords.md)되었습니다.
- `dashboard:namespace`과 `dashboard:flux_resource_path` 키워드가 GitLab 18.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/515854)되었습니다.

{{< /history >}}

`kubernetes` 키워드를 사용하여 환경에 대한 [Kubernetes 대시보드](../environments/kubernetes_dashboard.md)와 [GitLab 관리 Kubernetes 리소스](../../user/clusters/agent/managed_kubernetes_resources.md)를 구성하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `agent`: [Kubernetes용 GitLab 에이전트](../../user/clusters/agent/_index.md)를 지정하는 문자열. 형식은 `path/to/agent/project:agent-name`입니다. 에이전트가 파이프라인을 실행하는 프로젝트에 연결된 경우 `$CI_PROJECT_PATH:agent-name`를 사용하세요.
- `dashboard:namespace`: 환경이 배포되는 Kubernetes 네임스페이스를 나타내는 문자열. 네임스페이스는 `agent` 키워드와 함께 설정해야 합니다. `namespace`은 [지원 중단](deprecated_keywords.md#environmentkubernetesnamespace-and-environmentkubernetesflux_resource_path)되었습니다.
- `dashboard:flux_resource_path`: `HelmRelease`과 같은 Flux 리소스의 전체 경로를 나타내는 문자열. Flux 리소스는 `agent`과 `dashboard:namespace` 키워드와 함께 설정해야 합니다. `flux_resource_path`는 [지원 중단](deprecated_keywords.md#environmentkubernetesnamespace-and-environmentkubernetesflux_resource_path)되었습니다.
- `managed_resources`: 환경에 대한 [GitLab 관리 Kubernetes 리소스](../../user/clusters/agent/managed_kubernetes_resources.md)를 구성하기 위해 `enabled` 키워드를 사용하는 해시.
  - `managed_resources:enabled`: 환경에 대해 GitLab 관리 Kubernetes 리소스가 활성화되어 있는지 여부를 나타내는 부울 값.
- `dashboard`: 환경에 대한 [Kubernetes 대시보드](../environments/kubernetes_dashboard.md)를 구성하기 위해 `dashboard:namespace`과 `dashboard:flux_resource_path` 키워드를 사용하는 해시.

**`environment:kubernetes`의 예**:

```yaml
deploy:
  stage: deploy
  script: make deploy-app
  environment:
    name: production
    kubernetes:
      agent: path/to/agent/project:agent-name
      dashboard:
        namespace: my-namespace
        flux_resource_path: helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release-resource
```

관리되는 리소스를 비활성화할 때 **`environment:kubernetes`의 예**:

```yaml
deploy:
  stage: deploy
  script: make deploy-app
  environment:
    name: production
    kubernetes:
      agent: path/to/agent/project:agent-name
      managed_resources:
        enabled: false
      dashboard:
        namespace: my-namespace
        flux_resource_path: helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release-resource
```

이 구성은:

- `deploy` 작업을 `production` 환경에 배포하도록 설정합니다.
- `agent-name`라고 하는 [에이전트](../../user/clusters/agent/_index.md)를 환경과 연결합니다.
- 네임스페이스 `my-namespace`와 `flux_resource_path`이 `helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release-resource`로 설정된 환경에 대한 [Kubernetes 대시보드](../environments/kubernetes_dashboard.md)를 구성합니다.

**Additional details**:

- 대시보드를 사용하려면 [Kubernetes용 GitLab 에이전트를 설치](../../user/clusters/agent/install/_index.md)하고 환경의 프로젝트 또는 상위 그룹에 대해 [`user_access`를 구성](../../user/clusters/agent/user_access.md)해야 합니다.
- 작업을 실행하는 사용자는 클러스터 에이전트에 액세스할 권한이 있어야 합니다. 그렇지 않으면 대시보드는 `agent`, `namespace` 및 `flux_resource_path` 속성을 무시합니다.
- `agent`만 설정하려면 `namespace`를 설정할 필요가 없으며 `flux_resource_path`를 설정할 수 없습니다. 그러나 이 구성은 Kubernetes 대시보드에 클러스터의 모든 네임스페이스를 나열합니다.

---

#### `environment:deployment_tier` {#environmentdeployment_tier}

{{< history >}}

- CI/CD 변수 지원이 GitLab 18.5에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/365402)되었습니다.

{{< /history >}}

`deployment_tier` 키워드를 사용하여 배포 환경의 티어를 지정하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 다음 중 하나:

- `production`
- `staging`
- `testing`
- `development`
- `other`
- [CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)(사전 정의된 변수, 프로젝트, 그룹, 인스턴스 또는 `.gitlab-ci.yml` 파일에 정의된 변수 포함). `script` 섹션에 정의된 변수는 사용할 수 없습니다.

**`environment:deployment_tier`의 예**:

```yaml
deploy:
  script: echo
  environment:
    name: customer-portal
    deployment_tier: production
```

**Additional details**:

- 이 작업 정의에서 생성된 환경에는 이 값을 기반으로 [티어](../environments/_index.md#deployment-tier-of-environments)가 할당됩니다.
- 기존 환경은 나중에 이 값을 추가하면 티어가 업데이트되지 않습니다. 기존 환경은 [환경 API](../../api/environments.md#update-an-existing-environment)를 통해 티어를 업데이트해야 합니다.

**Related topics**:

- [환경의 배포 티어](../environments/_index.md#deployment-tier-of-environments).

---

#### 동적 환경 {#dynamic-environments}

CI/CD [변수](../variables/_index.md)를 사용하여 환경의 이름을 동적으로 지정하세요.

예를 들어:

```yaml
deploy as review app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com/
```

`deploy as review app` 작업이 배포로 표시되어 `review/$CI_COMMIT_REF_SLUG` 환경을 동적으로 생성합니다. `$CI_COMMIT_REF_SLUG`은 러너에서 설정한 [CI/CD 변수](../variables/_index.md)입니다. `$CI_ENVIRONMENT_SLUG` 변수는 환경 이름을 기반으로 하지만 URL에 포함하기에 적합합니다. `deploy as review app` 작업이 `pow`이라는 브랜치에서 실행되면 이 환경은 `https://review-pow.example.com/`과 같은 URL로 액세스할 수 있습니다.

일반적인 사용 사례는 브랜치에 대한 동적 환경을 만들고 이를 검토 앱으로 사용하는 것입니다. 검토 앱을 사용하는 예제는 <https://gitlab.com/gitlab-examples/review-apps-nginx/>에서 볼 수 있습니다.

---

### `extends` {#extends}

`extends`을 사용하여 구성 섹션을 재사용하세요. [YAML 앵커](yaml_optimization.md#anchors)의 대안이며 조금 더 유연하고 읽기 쉽습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 파이프라인의 다른 작업의 이름.
- 파이프라인의 다른 작업의 이름 목록(배열).

**`extends`의 예**:

```yaml
.tests:
  stage: test
  image: ruby:3.0

rspec:
  extends: .tests
  script: rake rspec

rubocop:
  extends: .tests
  script: bundle exec rubocop
```

이 예에서 `rspec` 작업은 `.tests` 템플릿 작업에서 구성을 사용합니다. 파이프라인을 생성할 때 GitLab:

- 키를 기반으로 역순 심층 병합을 수행합니다.
- `.tests` 컨텐츠를 `rspec` 작업과 병합합니다.
- 키의 값을 병합하지 않습니다.

결합된 구성은 다음 작업과 동등합니다:

```yaml
rspec:
  stage: test
  image: ruby:3.0
  script: rake rspec

rubocop:
  stage: test
  image: ruby:3.0
  script: bundle exec rubocop
```

**Additional details**:

- `extends`에 여러 부모를 사용할 수 있습니다.
- `extends` 키워드는 최대 11개 수준의 상속을 지원하지만 3개 수준 이상을 사용하지 않아야 합니다.
- 이전 예에서 `.tests`은 [숨겨진 작업](../jobs/_index.md#hide-a-job)이지만 일반 작업에서도 구성을 확장할 수 있습니다.

**Related topics**:

- [`extends`을 사용하여 구성 섹션 재사용](yaml_optimization.md#use-extends-to-reuse-configuration-sections).
- `extends`을 사용하여 [포함된 구성 파일](yaml_optimization.md#use-extends-and-include-together)에서 구성을 재사용하세요.

---

### `hooks` {#hooks}

{{< history >}}

- GitLab 15.6에서 `ci_hooks_pre_get_sources_script`라는 [플래그](../../administration/feature_flags/_index.md)와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/356850)되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 15.10에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/381840)합니다. 기능 플래그 `ci_hooks_pre_get_sources_script`이 제거되었습니다.

{{< /history >}}

`hooks`을 사용하여 Git 리포지토리 검색 전과 같은 작업 실행의 특정 스테이지에서 러너에서 실행할 명령 목록을 지정하세요.

작업 구성과 기본 구성은 함께 병합되지 않습니다. 파이프라인에 [`default:hooks`](#default)가 정의되어 있고 작업에도 `hooks`이 있으면 작업 구성이 우선적으로 적용되고 기본 구성은 사용되지 않습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 훅과 해당 명령의 해시. 사용 가능한 훅: `pre_get_sources_script`.

---

#### `hooks:pre_get_sources_script` {#hookspre_get_sources_script}

{{< history >}}

- GitLab 15.6에서 `ci_hooks_pre_get_sources_script`라는 [플래그](../../administration/feature_flags/_index.md)와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/356850)되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 15.10에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/381840)합니다. 기능 플래그 `ci_hooks_pre_get_sources_script`이 제거되었습니다.

{{< /history >}}

`hooks:pre_get_sources_script`을 사용하여 Git 리포지토리 및 모든 서브모듈을 복제하기 전에 러너에서 실행할 명령 목록을 지정하세요. 예를 들어 다음 용도로 사용할 수 있습니다:

- [Git 구성](../jobs/job_troubleshooting.md#get_sources-job-section-fails-because-of-an-http2-problem)을 조정합니다.
- [추적 변수](../../topics/git/troubleshooting_git.md#debug-git-with-traces)를 내보냅니다.

**Supported values**: 다음을 포함하는 배열:

- 한 줄 명령.
- 여러 줄로 [분할된](script.md#split-long-commands) 긴 명령.
- [YAML 앵커](yaml_optimization.md#yaml-anchors-for-scripts).

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`hooks:pre_get_sources_script`의 예**:

```yaml
job1:
  hooks:
    pre_get_sources_script:
      - echo 'hello job1 pre_get_sources_script'
  script: echo 'hello job1 script'
```

**Related topics**:

- [러너 구성](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)

---

### `identity` {#identity}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 16.9에서 `google_cloud_support_feature_flag` [플래그](../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142054)되었습니다. 이 기능은 [베타](../../policy/development_stages_support.md) 단계입니다.
- GitLab 17.1에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)되었습니다. 기능 플래그 `google_cloud_support_feature_flag`이 제거되었습니다.

{{< /history >}}

이 기능은 [베타](../../policy/development_stages_support.md) 단계입니다.

`identity`을 사용하여 ID 페더레이션을 사용해 제3자 서비스로 인증하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 식별자. 지원되는 제공자:

- `google_cloud`: Google Cloud. [Google Cloud IAM 통합](../../integration/google_cloud_iam.md)으로 구성해야 합니다.

**`identity`의 예**:

```yaml
job_with_workload_identity:
  identity: google_cloud
  script:
    - gcloud compute instances list
```

**Related topics**:

- [워크로드 ID 페더레이션](https://cloud.google.com/iam/docs/workload-identity-federation).
- [Google Cloud IAM 통합](../../integration/google_cloud_iam.md).

---

### `id_tokens` {#id_tokens}

{{< history >}}

- [GitLab 15.7에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/356986)

{{< /history >}}

`id_tokens`을 사용하여 제3자 서비스로 인증하기 위해 [ID 토큰](../secrets/id_token_authentication.md)을 생성하세요. 이렇게 생성된 모든 JWT는 OIDC 인증을 지원합니다. 필수 `aud` 부분-키워드는 JWT의 `aud` 클레임을 구성하는 데 사용됩니다.

작업 구성과 기본 구성은 함께 병합되지 않습니다. 파이프라인에 [`default:id_tokens`](#default)가 정의되어 있고 작업에도 `id_tokens`이 있으면 작업 구성이 우선적으로 적용되고 기본 구성은 사용되지 않습니다.

**Supported values**:

- `aud` 클레임이 포함된 토큰 이름. `aud`지원:
  - 단일 문자열.
  - 문자열 배열입니다.
  - [CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`id_tokens`의 예**:

```yaml
job_with_id_tokens:
  id_tokens:
    ID_TOKEN_1:
      aud: https://vault.example.com
    ID_TOKEN_2:
      aud:
        - https://gcp.com
        - https://aws.com
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  script:
    - command_to_authenticate_with_vault $ID_TOKEN_1
    - command_to_authenticate_with_aws $ID_TOKEN_2
    - command_to_authenticate_with_gcp $ID_TOKEN_2
```

**Related topics**:

- [ID 토큰 인증](../secrets/id_token_authentication.md).
- [클라우드 서비스에 연결](../cloud_services/_index.md).
- [Sigstore를 사용한 서명 없이 사인](signing_examples.md).

---

### `image` {#image}

`image`을 사용하여 작업이 실행되는 Docker 이미지를 지정하세요.

작업 구성과 기본 구성은 함께 병합되지 않습니다. 파이프라인에 [`default:image`](#default)가 정의되어 있고 작업에도 `image`이 있으면 작업 구성이 우선적으로 적용되고 기본 구성은 사용되지 않습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**: 필요한 경우 레지스트리 경로를 포함하는 이미지 이름(다음 형식 중 하나):

- `<image-name>`(`<image-name>`을 `latest` 태그로 사용하는 것과 동일)
- `<image-name>:<tag>`
- `<image-name>@<digest>`

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`image`의 예**:

```yaml
default:
  image: ruby:3.0

rspec:
  script: bundle exec rspec

rspec 2.7:
  image: registry.example.com/my-group/my-project/ruby:2.7
  script: bundle exec rspec
```

이 예에서 `ruby:3.0` 이미지는 파이프라인의 모든 작업에 대한 기본값입니다. `rspec 2.7` 작업은 작업 특화 `image` 섹션으로 기본값을 재정의하기 때문에 기본값을 사용하지 않습니다.

**Additional details**:

- `image`을 최상위 수준에서 사용하되 `default` 섹션에서는 사용하지 않는 것은 [더 이상 사용되지 않습니다](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script).

**Related topics**:

- [Docker 컨테이너에서 CI/CD 작업 실행](../docker/using_docker_images.md).

---

#### `image:name` {#imagename}

작업이 실행되는 Docker 이미지의 이름. [`image`](#image)를 자체적으로 사용하는 것과 유사합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**: 필요한 경우 레지스트리 경로를 포함하는 이미지 이름(다음 형식 중 하나):

- `<image-name>`(`<image-name>`을 `latest` 태그로 사용하는 것과 동일)
- `<image-name>:<tag>`
- `<image-name>@<digest>`

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`image:name`의 예**:

```yaml
test-job:
  image:
    name: "registry.example.com/my/image:latest"
  script: echo "Hello world"
```

**Related topics**:

- [Docker 컨테이너에서 CI/CD 작업 실행](../docker/using_docker_images.md).

---

#### `image:entrypoint` {#imageentrypoint}

컨테이너의 진입점으로 실행할 명령 또는 스크립트.

Docker 컨테이너가 생성되면 `entrypoint`이 Docker `--entrypoint` 옵션으로 변환됩니다. 구문은 [Dockerfile `ENTRYPOINT` 지시문](https://docs.docker.com/reference/dockerfile/#entrypoint)과 유사하며 각 셀 토큰은 배열의 별도 문자열입니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 문자열입니다.

**`image:entrypoint`의 예**:

```yaml
test-job:
  image:
    name: super/sql:experimental
    entrypoint: [""]
  script: echo "Hello world"
```

**Related topics**:

- [이미지의 진입점 재정의](../docker/using_docker_images.md#override-the-entrypoint-of-an-image).

---

#### `image:docker` {#imagedocker}

{{< history >}}

- GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27919)되었습니다. GitLab Runner 16.7 이상이 필요합니다.
- `user` 입력 옵션이 GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137907)되었습니다.

{{< /history >}}

`image:docker`을 사용하여 [Docker 실행기](https://docs.gitlab.com/runner/executors/docker/) 또는 [Kubernetes 실행기](https://docs.gitlab.com/runner/executors/kubernetes/)를 사용하는 러너에 옵션을 전달하세요. 이 키워드는 다른 실행기 유형과 함께 작동하지 않습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

Docker 실행기에 대한 옵션의 해시(다음 포함 가능):

- `platform`: 끌어올 이미지의 아키텍처를 선택합니다. 지정하지 않으면 기본값은 호스트 러너와 동일한 플랫폼입니다.
- `user`: 컨테이너를 실행할 때 사용할 사용자 이름 또는 UID를 지정합니다.

**`image:docker`의 예**:

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image:
    name: super/sql:experimental
    docker:
      platform: arm64/v8
      user: dave
```

**Additional details**:

- `image:docker:platform`은 [`docker pull --platform` 옵션](https://docs.docker.com/reference/cli/docker/image/pull/#options)에 매핑됩니다.
- `image:docker:user`은 [`docker run --user` 옵션](https://docs.docker.com/reference/cli/docker/container/run/#options)에 매핑됩니다.

---

#### `image:kubernetes` {#imagekubernetes}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38451)되었습니다. GitLab Runner 17.11 이상이 필요합니다.
- `user` 입력 옵션이 GitLab Runner 17.11에서 [도입](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5469)되었습니다.
- `user` 입력 옵션이 GitLab 18.0에서 [`uid:gid` 형식을 지원하도록 확장](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5540)되었습니다.

{{< /history >}}

`image:kubernetes`을 사용하여 러너 [Kubernetes 실행기](https://docs.gitlab.com/runner/executors/kubernetes/)에 옵션을 전달하세요. 이 키워드는 다른 실행기 유형과 함께 작동하지 않습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

Kubernetes 실행기에 대한 옵션의 해시(다음 포함 가능):

- `user`: 컨테이너를 실행할 때 사용할 사용자 이름 또는 UID를 지정합니다. `UID:GID` 형식을 사용하여 GID를 설정할 수도 있습니다.

**UID만 사용하는 `image:kubernetes`의 예**:

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image:
    name: super/sql:experimental
    kubernetes:
      user: "1001"
```

**UID와 GID 모두를 사용하는 `image:kubernetes`의 예**:

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image:
    name: super/sql:experimental
    kubernetes:
      user: "1001:1001"
```

---

#### `image:pull_policy` {#imagepull_policy}

{{< history >}}

- GitLab 15.1에서 `ci_docker_image_pull_policy` [플래그](../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/21619)되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 15.2에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)되었습니다.
- GitLab 15.4에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)합니다. [기능 플래그 `ci_docker_image_pull_policy`](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)가 제거되었습니다.
- GitLab Runner 15.1 이상이 필요합니다.

{{< /history >}}

러너가 Docker 이미지를 가져오는 데 사용하는 끌어오기 정책.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 단일 끌어오기 정책 또는 배열의 여러 끌어오기 정책. `always`, `if-not-present` 또는 `never`입니다.

**`image:pull_policy`의 예**:

```yaml
job1:
  script: echo "A single pull policy."
  image:
    name: ruby:3.0
    pull_policy: if-not-present

job2:
  script: echo "Multiple pull policies."
  image:
    name: ruby:3.0
    pull_policy: [always, if-not-present]
```

**Additional details**:

- 러너가 정의된 끌어오기 정책을 지원하지 않으면 작업이 `ERROR: Job failed (system failure): the configured PullPolicies ([always]) are not allowed by AllowedPullPolicies ([never])`과 유사한 오류로 실패합니다.

**Related topics**:

- [Docker 컨테이너에서 CI/CD 작업 실행](../docker/using_docker_images.md).
- [러너가 이미지를 끌어오는 방식 구성](https://docs.gitlab.com/runner/executors/docker/#configure-how-runners-pull-images).
- [여러 끌어오기 정책 설정](https://docs.gitlab.com/runner/executors/docker/#set-multiple-pull-policies).

---

### `inputs` {#inputs}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/17833)되었습니다.

{{< /history >}}

`inputs`을 사용하여 작업에 대해 입력된 유형과 검증을 정의하세요. [작업 입력](../jobs/job_inputs.md)은 작업을 수동으로 실행하거나 다시 시도할 때 재정의할 수 있습니다.

작업 입력은 유형 안전성과 검증을 제공하는 매개 변수입니다. [CI/CD 변수](../variables/_index.md)와 달리 작업을 실행하거나 다시 시도할 때 작업에 명시적으로 정의된 입력만 지정할 수 있습니다. 모든 작업 입력 이름은 미리 정의되어야 합니다.

`${{ job.inputs.INPUT_NAME }}` [Moa 표현식](../functions/moa.md) 구문으로 작업 입력 값을 참조하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

각 입력이 하나 이상의 부분-키로 구성된 입력 이름의 해시:

- [`default`](#inputsdefault) (필수)
- [`type`](#inputstype)
- [`options`](#inputsoptions)
- [`description`](#inputsdescription)
- [`regex`](#inputsregex)

**`inputs`의 예**:

```yaml
test_job:
  inputs:
    test_suite:
      default: unit
      description: Which test suite to run
      options: [unit, integration, e2e]
    parallel_count:
      type: number
      default: 5
      description: Number of parallel test runners
    verbose:
      type: boolean
      default: false
      description: Enable verbose test output
  script:
    - 'echo "Running ${{ job.inputs.test_suite }} tests"'
    - 'if [ "${{ job.inputs.verbose }}" == "true" ]; then export TEST_VERBOSE=1; fi'
    - ./run_tests.sh --suite ${{ job.inputs.test_suite }} --parallel ${{ job.inputs.parallel_count }}
```

**Additional details**:

- 작업 입력은 작업이 생성될 때 그리고 새 입력 값으로 작업을 다시 시도할 때 검증됩니다. 검증에 실패하면 작업이 시작되지 않습니다.
- 작업 입력은 정의된 작업 범위로 지정되며 다른 작업에서 액세스할 수 없습니다.
- 지원되는 키워드의 전체 목록은 [작업 입력을 사용할 수 있는 위치](../jobs/job_inputs.md#where-you-can-use-job-inputs)를 참조하세요.

---

#### `inputs:default` {#inputsdefault}

모든 작업 입력은 `default`로 정의된 기본값을 가져야 합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 입력의 [`type`](#inputstype)과 일치하는 모든 값.

**`inputs:default`의 예**:

```yaml
test_job:
  inputs:
    environment:
      default: staging
    timeout:
      type: number
      default: 30
```

---

#### `inputs:type` {#inputstype}

`type`을 사용하여 입력 값의 데이터 유형을 정의하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `string`(기본값)
- `number`
- `boolean`
- `array`.

**`inputs:type`의 예**:

```yaml
test_job:
  inputs:
    count:
      type: number
      default: 5
    enabled:
      type: boolean
      default: true
```

---

#### `inputs:description` {#inputsdescription}

`description`을 사용하여 입력의 목적에 대한 정보를 제공하세요. 설명은 입력의 동작에 영향을 주지 않습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 문자열입니다.

**`inputs:description`의 예**:

```yaml
deploy_job:
  inputs:
    environment:
      default: staging
      description: Target deployment environment
```

---

#### `inputs:options` {#inputsoptions}

`options`을 사용하여 입력에 대해 허용되는 값의 목록을 지정하세요.

입력 값은 나열된 옵션 중 하나와 정확히 일치해야 합니다(대소문자 구분). 값이 옵션과 일치하지 않으면 검증에 실패합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 허용되는 값의 배열.

**`inputs:options`의 예**:

```yaml
deploy_job:
  inputs:
    environment:
      default: staging
      options: [development, staging, production]
```

---

#### `inputs:regex` {#inputsregex}

`regex`을 사용하여 입력 값이 일치해야 하는 정규 표현식 패턴을 지정하세요.

값이 정규 표현식과 일치하지 않으면 검증에 실패합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 정규 표현식 문자열.

**`inputs:regex`의 예**:

```yaml
deploy_job:
  inputs:
    version:
      default: v1.0.0
      regex: ^v\d+\.\d+\.\d+$
```

이 예에서 `v1.1.1`의 입력 값은 정규식 검증을 통과하지만 `v1.1.1-beta`의 입력은 통과하지 않습니다.

---

### `inherit` {#inherit}

`inherit`을 사용하여 [기본 키워드 및 변수의 상속 제어](../jobs/_index.md#control-the-inheritance-of-default-keywords-and-variables).

---

#### `inherit:default` {#inheritdefault}

`inherit:default`을 사용하여 [기본 키워드](#default)의 상속을 제어하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `true` (기본값) 또는 `false`로 모든 기본 키워드의 상속을 활성화 또는 비활성화합니다.
- 상속할 특정 기본 키워드의 목록.

**`inherit:default`의 예**:

```yaml
default:
  retry: 2
  image: ruby:3.0
  interruptible: true

job1:
  script: echo "This job does not inherit any default keywords."
  inherit:
    default: false

job2:
  script: echo "This job inherits only the two listed default keywords. It does not inherit 'interruptible'."
  inherit:
    default:
      - retry
      - image
```

**Additional details**:

- 기본 키워드를 한 줄에 상속으로 나열할 수도 있습니다: `default: [keyword1, keyword2]`

---

#### `inherit:variables` {#inheritvariables}

`inherit:variables`을 사용하여 [기본 변수](#default-variables) 키워드의 상속을 제어하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `true` (기본값) 또는 `false`로 모든 기본 변수의 상속을 활성화 또는 비활성화합니다.
- 상속할 특정 변수의 목록.

**`inherit:variables`의 예**:

```yaml
variables:
  VARIABLE1: "This is default variable 1"
  VARIABLE2: "This is default variable 2"
  VARIABLE3: "This is default variable 3"

job1:
  script: echo "This job does not inherit any default variables."
  inherit:
    variables: false

job2:
  script: echo "This job inherits only the two listed default variables. It does not inherit 'VARIABLE3'."
  inherit:
    variables:
      - VARIABLE1
      - VARIABLE2
```

**Additional details**:

- 상속할 기본 변수를 한 줄에 나열할 수도 있습니다: `variables: [VARIABLE1, VARIABLE2]`

---

### `interruptible` {#interruptible}

{{< history >}}

- `trigger` 작업 지원이 GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138508)되었습니다.

{{< /history >}}

`interruptible`을 사용하여 동일한 ref의 새 파이프라인이 새 커밋에 대해 시작되면 작업이 완료되기 전에 취소하도록 [중복 파이프라인의 자동 취소](../pipelines/settings.md#auto-cancel-redundant-pipelines) 기능을 구성하세요. 기능이 비활성화되면 키워드는 효과가 없습니다. 새 파이프라인은 새로운 변경 사항이 있는 커밋에 대한 것이어야 합니다. 예를 들어 **중복 파이프라인의 자동 취소** 기능은 UI에서 **새 파이프라인**을 선택하여 동일한 커밋에 대한 파이프라인을 실행하는 경우 효과가 없습니다.

**중복 파이프라인의 자동 취소** 기능의 동작은 [`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit) 설정으로 제어할 수 있습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- `true` 또는 `false`(기본값).

**기본 동작으로 `interruptible`의 예**:

```yaml
workflow:
  auto_cancel:
    on_new_commit: conservative # the default behavior

stages:
  - stage1
  - stage2
  - stage3

step-1:
  stage: stage1
  script:
    - echo "Can be canceled."
  interruptible: true

step-2:
  stage: stage2
  script:
    - echo "Can not be canceled."

step-3:
  stage: stage3
  script:
    - echo "Because step-2 can not be canceled, this step can never be canceled, even though it's set as interruptible."
  interruptible: true
```

이 예에서 새 파이프라인으로 인해 실행 중인 파이프라인이 다음과 같이 됩니다:

- 취소됨(단 `step-1`만 실행 중이거나 대기 중인 경우).
- `step-2`이 시작된 후 취소되지 않음.

**`interruptible` 설정으로 `auto_cancel:on_new_commit:interruptible`의 예**:

```yaml
workflow:
  auto_cancel:
    on_new_commit: interruptible

stages:
  - stage1
  - stage2
  - stage3

step-1:
  stage: stage1
  script:
    - echo "Can be canceled."
  interruptible: true

step-2:
  stage: stage2
  script:
    - echo "Can not be canceled."

step-3:
  stage: stage3
  script:
    - echo "Can be canceled."
  interruptible: true
```

이 예에서 새 파이프라인으로 인해 실행 중인 파이프라인이 `step-1`과 `step-3`을 취소합니다(실행 중이거나 대기 중인 경우).

**Additional details**:

- 빌드 작업과 같이 시작된 후 안전하게 취소할 수 있는 작업인 경우에만 `interruptible: true`을 설정하세요. 배포 작업은 일반적으로 부분 배포를 방지하기 위해 취소되어서는 안 됩니다.
- 기본 동작 또는 `workflow:auto_cancel:on_new_commit: conservative`을 사용할 때:
  - 아직 시작되지 않은 작업은 작업의 구성에 관계없이 항상 `interruptible: true`로 간주됩니다. `interruptible` 구성은 작업이 시작된 후에만 고려됩니다.
  - **실행중** 파이프라인은 모든 실행 중인 작업이 `interruptible: true`로 구성되어 있거나 `interruptible: false`로 구성된 작업이 언제든지 시작되지 않은 경우에만 취소됩니다. `interruptible: false`이 있는 작업이 시작되면 전체 파이프라인은 더 이상 중단 가능하지 않습니다.
  - 파이프라인이 다운스트림 파이프라인을 트리거했지만 다운스트림 파이프라인의 `interruptible: false`이 있는 작업이 아직 시작되지 않은 경우 다운스트림 파이프라인도 취소됩니다.
- 파이프라인의 첫 번째 스테이지에서 `interruptible: false`이 있는 선택적 수동 작업을 추가하여 사용자가 파이프라인이 자동으로 취소되는 것을 수동으로 방지할 수 있습니다. 사용자가 작업을 시작하면 **중복 파이프라인의 자동 취소** 기능으로 인해 파이프라인을 취소할 수 없습니다.
- [트리거 작업](#trigger)과 함께 `interruptible`을 사용할 때:
  - 트리거된 다운스트림 파이프라인은 트리거 작업의 `interruptible` 구성에 영향을 받지 않습니다.
  - [`workflow:auto_cancel`](#workflowauto_cancelon_new_commit)이 `conservative`으로 설정되면 트리거 작업의 `interruptible` 구성은 효과가 없습니다.
  - [`workflow:auto_cancel`](#workflowauto_cancelon_new_commit)이 `interruptible`으로 설정되면 `interruptible: true`이 있는 트리거 작업을 자동으로 취소할 수 있습니다.

---

### `needs` {#needs}

`needs`을 사용하여 작업을 순서 없이 실행하세요. `needs`을 사용하는 작업 간의 관계는 [방향성 비순환 그래프](needs.md)로 시각화할 수 있습니다.

스테이지 순서를 무시하고 다른 작업이 완료될 때까지 기다리지 않고 일부 작업을 실행할 수 있습니다. 여러 스테이지의 작업을 동시에 실행할 수 있습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 작업의 배열(최대 50개 작업).
- 빈 배열(`[]`)로 파이프라인이 생성되는 즉시 작업을 시작하도록 설정합니다.

**`needs`의 예**:

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."

mac:build:
  stage: build
  script: echo "Building mac..."

lint:
  stage: test
  needs: []
  script: echo "Linting..."

linux:rspec:
  stage: test
  needs: ["linux:build"]
  script: echo "Running rspec on linux..."

mac:rspec:
  stage: test
  needs: ["mac:build"]
  script: echo "Running rspec on mac..."

production:
  stage: deploy
  script: echo "Running production..."
  environment: production
```

이 예에서는 4가지 실행 경로를 생성합니다:

- 린터: `lint` 작업은 필요 사항이 없기 때문에 `build` 스테이지가 완료될 때까지 기다리지 않고 즉시 실행됩니다(`needs: []`).
- Linux 경로: `linux:rspec` 작업은 `linux:build` 작업이 완료되는 즉시 실행되며 `mac:build`이 완료될 때까지 기다리지 않습니다.
- macOS 경로: `mac:rspec` 작업은 `mac:build` 작업이 완료되는 즉시 실행되며 `linux:build`이 완료될 때까지 기다리지 않습니다.
- `production` 작업은 모든 이전 작업이 완료되면 실행됩니다: `lint`, `linux:build`, `linux:rspec`, `mac:build`, `mac:rspec`.

**Additional details**:

- 단일 작업이 `needs` 배열에 가질 수 있는 작업의 최대 개수는 제한됩니다:
  - GitLab.com의 경우 제한은 50입니다. 자세한 내용은 [이슈 350398](https://gitlab.com/gitlab-org/gitlab/-/issues/350398)을 참조하세요.
  - GitLab Self-Managed 및 GitLab Dedicated의 경우 기본 제한은 50입니다. 이 제한은 [관리 영역에서 CI/CD 제한을 업데이트](../../administration/cicd/limits.md#maximum-number-of-needs-dependencies)하여 변경할 수 있습니다.
- `needs`이 [`parallel`](#parallel) 키워드를 사용하는 작업을 참조하면 단일 작업이 아닌 병렬로 생성된 모든 작업에 따라 달라집니다. 기본적으로 모든 병렬 작업에서 아티팩트도 다운로드합니다. 아티팩트의 이름이 같으면 서로 덮어쓰기되고 마지막으로 다운로드된 것만 저장됩니다.
  - `needs`이 병렬화된 모든 작업이 아닌 작업의 부분 집합을 참조하도록 하려면 [`needs:parallel:matrix`](#needsparallelmatrix) 키워드를 사용하세요.
- 구성 중인 작업과 동일한 스테이지의 작업을 참조할 수 있습니다.
- `needs`이 `only`, `except` 또는 `rules`로 인해 파이프라인에 추가되지 않을 수 있는 작업을 참조하면 파이프라인 생성이 실패할 수 있습니다. 실패한 파이프라인 생성을 해결하려면 [`needs:optional`](#needsoptional) 키워드를 사용하세요.
- 파이프라인에 `needs: []`이 있는 작업과 [`.pre`](#stage-pre) 스테이지의 작업이 있으면 모두 파이프라인이 생성되는 즉시 시작됩니다. `needs: []`이 있는 작업은 즉시 시작되고 `.pre` 스테이지의 작업도 즉시 시작됩니다.

---

#### `needs:artifacts` {#needsartifacts}

작업이 `needs`을 사용할 때 이전 스테이지의 모든 아티팩트가 기본적으로 다운로드되지 않습니다. `needs`이 있는 작업은 이전 스테이지가 완료되기 전에 시작할 수 있기 때문입니다. `needs`으로 `needs` 구성에 나열된 작업에서만 아티팩트를 다운로드할 수 있습니다.

`artifacts: true` (기본값) 또는 `artifacts: false`을 사용하여 `needs`을 사용하는 작업에서 아티팩트가 다운로드되는 시기를 제어하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다. `needs:job`과 함께 사용해야 합니다.

**Supported values**:

- `true` (기본값) 또는 `false`.

**`needs:artifacts`의 예**:

```yaml
test-job1:
  stage: test
  needs:
    - job: build_job1
      artifacts: true

test-job2:
  stage: test
  needs:
    - job: build_job2
      artifacts: false

test-job3:
  needs:
    - job: build_job1
      artifacts: true
    - job: build_job2
    - build_job3
```

이 예에서:

- `test-job1` 작업이 `build_job1` 아티팩트를 다운로드합니다.
- `test-job2` 작업은 `build_job2` 아티팩트를 다운로드하지 않습니다.
- `test-job3` 작업은 세 개의 `build_jobs` 모두에서 아티팩트를 다운로드합니다. `artifacts`이(가) `true`이거나 세 가지 필요한 작업 모두에 대해 `true`로 기본값이 설정되기 때문입니다.

**Additional details**:

- 같은 작업 내에서 `needs`을(를) [`dependencies`](#dependencies)과(와) 함께 사용하면 안 됩니다.

---

#### `needs:project` {#needsproject}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

`needs:project`을(를) 사용하여 다른 파이프라인에서 최대 5개 작업의 아티팩트를 다운로드합니다. 아티팩트는 지정된 ref에 대해 지정된 작업의 최신 성공 실행에서 다운로드됩니다. 여러 작업을(를) 지정하려면 각각을 `needs` 키워드 아래의 별도 배열 항목으로 추가합니다.

ref에 대해 파이프라인이 실행 중인 경우 `needs:project`이(가) 있는 작업은 파이프라인이 완료될 때까지 기다리지 않습니다. 대신 지정된 작업의 최신 성공 실행에서 아티팩트가 다운로드됩니다.

`needs:project`을(를) `job`, `ref`, `artifacts`와(과) 함께 사용해야 합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `needs:project`: 네임스페이스와 그룹을 포함한 전체 프로젝트 경로입니다.
- `job`: 아티팩트를 다운로드할 작업입니다.
- `ref`: 아티팩트를 다운로드할 ref입니다.
- `artifacts`: 아티팩트를 다운로드하려면 `true`이어야 합니다.

**`needs:project`의 예**:

```yaml
build_job:
  stage: build
  script:
    - ls -lhR
  needs:
    - project: namespace/group/project-name
      job: build-1
      ref: main
      artifacts: true
    - project: namespace/group/project-name-2
      job: build-2
      ref: main
      artifacts: true
```

이 예제에서 `build_job`은(는) `group/project-name` 및 `group/project-name-2` 프로젝트의 `main` 브랜치에서 최신 성공적인 `build-1` 및 `build-2` 작업의 아티팩트를 다운로드합니다.

[CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)를 `needs:project`에서 사용할 수 있습니다. 예를 들면:

```yaml
build_job:
  stage: build
  script:
    - ls -lhR
  needs:
    - project: $CI_PROJECT_PATH
      job: $DEPENDENCY_JOB_NAME
      ref: $ARTIFACTS_DOWNLOAD_REF
      artifacts: true
```

**Additional details**:

- 현재 프로젝트에서 다른 파이프라인의 아티팩트를 다운로드하려면 `project`을(를) 현재 프로젝트와 동일하게 설정하되, 현재 파이프라인과 다른 ref를 사용합니다. 동일한 ref에서 실행되는 동시 파이프라인이 아티팩트를 재정의할 수 있습니다.
- 파이프라인을 실행하는 사용자는 그룹 또는 프로젝트에 대한 Reporter, Developer, Maintainer 또는 Owner 역할이 있거나 그룹/프로젝트는 공개 표시 상태여야 합니다.
- `needs:project`을(를) 같은 작업에서 [`trigger`](#trigger)과(와) 함께 사용할 수 없습니다.
- `needs:project`을(를) 사용하여 다른 파이프라인에서 아티팩트를 다운로드할 때 작업은 필요한 작업이 완료될 때까지 기다리지 않습니다. [`needs`을(를) 사용하여 작업이 완료될 때까지 기다리기](needs.md)는 동일한 파이프라인의 작업으로만 제한됩니다. 다른 파이프라인의 필요한 작업이 그것이 필요한 작업이 아티팩트를 다운로드하려고 시도하기 전에 완료되는지 확인합니다.
- [`parallel`](#parallel)에서 실행되는 작업에서 아티팩트를 다운로드할 수 없습니다.
- [CI/CD 변수](../variables/_index.md) 지원을 `project`, `job`, `ref`에 추가합니다.

**Related topics**:

- [상위-하위 파이프라인](../pipelines/downstream_pipelines.md#parent-child-pipelines) 간에 아티팩트를 다운로드하려면 [`needs:pipeline:job`](#needspipelinejob)을(를) 사용합니다.

---

#### `needs:pipeline:job` {#needspipelinejob}

[하위 파이프라인](../pipelines/downstream_pipelines.md#parent-child-pipelines)은(는) 상위 파이프라인 또는 동일한 상위-하위 파이프라인 계층 구조의 다른 하위 파이프라인에서 성공적으로 완료된 작업의 아티팩트를 다운로드할 수 있습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `needs:pipeline`: 파이프라인 ID입니다. 동일한 상위-하위 파이프라인 계층 구조에 있어야 하는 파이프라인이어야 합니다.
- `job`: 아티팩트를 다운로드할 작업입니다.

**`needs:pipeline:job`의 예**:

- 상위 파이프라인 (`.gitlab-ci.yml`):

  ```yaml
  stages:
    - build
    - test

  create-artifact:
    stage: build
    script: echo "sample artifact" > artifact.txt
    artifacts:
      paths: [artifact.txt]

  child-pipeline:
    stage: test
    trigger:
      include: child.yml
      strategy: mirror
    variables:
      PARENT_PIPELINE_ID: $CI_PIPELINE_ID
  ```

- 하위 파이프라인 (`child.yml`):

  ```yaml
  use-artifact:
    script: cat artifact.txt
    needs:
      - pipeline: $PARENT_PIPELINE_ID
        job: create-artifact
  ```

이 예제에서 상위 파이프라인의 `create-artifact` 작업은(는) 일부 아티팩트를 생성합니다. `child-pipeline` 작업은(는) 하위 파이프라인을 트리거하고 `CI_PIPELINE_ID` 변수를 하위 파이프라인에 새 `PARENT_PIPELINE_ID` 변수로 전달합니다. 하위 파이프라인은 `needs:pipeline`에서 해당 변수를 사용하여 상위 파이프라인에서 아티팩트를 다운로드할 수 있습니다. 후속 스테이지에 `create-artifact` 및 `child-pipeline` 작업을(를) 보유하면 `use-artifact` 작업이(가) `create-artifact`가 성공적으로 완료된 경우에만 실행됩니다.

**Additional details**:

- `pipeline` 속성은 현재 파이프라인 ID (`$CI_PIPELINE_ID`)를 수락하지 않습니다. 현재 파이프라인에서 작업의 아티팩트를 다운로드하려면 [`needs:artifacts`](#needsartifacts)을(를) 사용합니다.
- `needs:pipeline:job`을(를) [트리거 작업](#trigger)에서 사용할 수 없거나 [다중 프로젝트 파이프라인](../pipelines/downstream_pipelines.md#multi-project-pipelines)에서 아티팩트를 가져올 수 없습니다. 다중 프로젝트 파이프라인에서 아티팩트를 가져오려면 [`needs:project`](#needsproject)을(를) 사용합니다.
- `needs:pipeline:job`에 나열된 작업은(는) `success`의 상태로 완료되어야 합니다. 그렇지 않으면 아티팩트를 가져올 수 없습니다. [이슈 367229](https://gitlab.com/gitlab-org/gitlab/-/issues/367229)는 모든 아티팩트가 있는 작업에서 아티팩트를 가져올 수 있도록 제안합니다.

---

#### `needs:optional` {#needsoptional}

파이프라인에 없는 경우도 있는 작업이 필요한 경우 `optional: true`을(를) `needs` 구성에 추가합니다. 정의되지 않으면 `optional: false`이(가) 기본값입니다.

[`rules`](#rules), [`only`, 또는 `except`](deprecated_keywords.md#only--except)을(를) 사용하고 [`include`](#include)을(를) 추가하는 작업은(는) 항상 파이프라인에 추가되지 않을 수 있습니다. GitLab은 파이프라인을 시작하기 전에 `needs` 관계를 확인합니다:

- `needs` 항목에 `optional: true`이(가) 있고 필요한 작업이(가) 파이프라인에 있는 경우 작업은(는) 시작하기 전에 완료될 때까지 기다립니다.
- 필요한 작업이 없으면 다른 모든 needs 요구 사항이 충족될 때 작업을(를) 시작할 수 있습니다.
- `needs` 섹션에 선택적 작업만 포함되고 파이프라인에 추가되지 않은 경우 작업은(는) 즉시 시작됩니다(빈 `needs` 항목과 동일: `needs: []`).
- 필요한 작업에 `optional: false`이(가) 있지만 파이프라인에 추가되지 않은 경우 파이프라인이 시작되지 않고 오류가 발생합니다: `'job1' job needs 'job2' job, but it was not added to the pipeline`.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**`needs:optional`의 예**:

```yaml
build-job:
  stage: build

test-job1:
  stage: test

test-job2:
  stage: test
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

deploy-job:
  stage: deploy
  needs:
    - job: test-job2
      optional: true
    - job: test-job1
  environment: production

review-job:
  stage: deploy
  needs:
    - job: test-job2
      optional: true
  environment: review
```

이 예에서:

- `build-job`, `test-job1`, `test-job2`은(는) 스테이지 순서대로 시작합니다.
- 브랜치가 기본 브랜치인 경우 `test-job2`이(가) 파이프라인에 추가되므로:
  - `deploy-job`은(는) `test-job1` 및 `test-job2`이(가) 완료될 때까지 기다립니다.
  - `review-job`은(는) `test-job2`이(가) 완료될 때까지 기다립니다.
- 브랜치가 기본 브랜치가 아닌 경우 `test-job2`이(가) 파이프라인에 추가되지 않으므로:
  - `deploy-job`은(는) `test-job1`만 완료될 때까지 기다리고 없는 `test-job2`을(를) 기다리지 않습니다.
  - `review-job`은(는) 다른 필요한 작업이 없으며 즉시 시작합니다(`build-job`와 동시에, `needs: []`과(와) 마찬가지).

**Additional details**:

- `needs:optional`을(를) [`needs:parallel:matrix`](#needsparallelmatrix)과(와) 함께 사용할 수 없습니다.

---

#### `needs:pipeline` {#needspipeline}

`needs:pipeline` 키워드를 사용하여 업스트림 파이프라인의 파이프라인 상태를 작업에 반영할 수 있습니다. 기본 브랜치의 최신 파이프라인 상태가 작업에 복제됩니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 네임스페이스와 그룹을 포함한 전체 프로젝트 경로입니다. 프로젝트가 동일한 그룹 또는 네임스페이스에 있는 경우 `project` 키워드에서 제외할 수 있습니다. 예: `project: group/project-name` 또는 `project: project-name`.

**`needs:pipeline`의 예**:

```yaml
upstream_status:
  stage: test
  needs:
    pipeline: other/project
```

**Additional details**:

- `job` 키워드를 `needs:pipeline`에 추가하면 작업이 더 이상 파이프라인 상태를 반영하지 않습니다. 동작이 [`needs:pipeline:job`](#needspipelinejob)(으)로 변경됩니다.

---

#### `needs:parallel:matrix` {#needsparallelmatrix}

{{< history >}}

- GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/254821)되었습니다.

{{< /history >}}

작업은 [`parallel:matrix`](#parallelmatrix)을(를) 사용하여 단일 파이프라인에서 작업을(를) 여러 번 병렬로 실행할 수 있지만 작업의 각 인스턴스에 대해 다른 변수 값을 사용합니다.

병렬화된 작업에 따라 작업을 비순서대로 실행하려면 `needs:parallel:matrix`을(를) 사용합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다. `needs:job`과 함께 사용해야 합니다.

**Supported values**: 행렬 식별자의 해시 배열:

- 식별자 및 값은 `parallel:matrix` 작업에 정의된 식별자 및 값에서 선택해야 합니다.
- [행렬 식](matrix_expressions.md)을(를) 사용할 수 있습니다.

**`needs:parallel:matrix`의 예**:

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."
  parallel:
    matrix:
      - PROVIDER: aws
        STACK:
          - monitoring
          - app1
          - app2

linux:rspec:
  stage: test
  needs:
    - job: linux:build
      parallel:
        matrix:
          - PROVIDER: aws
            STACK: app1
  script: echo "Running rspec on linux..."
```

이전 예제에서는 다음 작업을(를) 생성합니다:

```plaintext
linux:build: [aws, monitoring]
linux:build: [aws, app1]
linux:build: [aws, app2]
linux:rspec
```

`linux:rspec` 작업은(는) `linux:build: [aws, app1]` 작업이 완료되는 즉시 실행됩니다.

**Additional details**:

- `needs:parallel:matrix`을(를) [`needs:optional`](#needsoptional)과(와) 함께 사용할 수 없습니다.
- `needs:parallel:matrix`의 행렬 식별자 순서는 필요한 작업의 행렬 변수 순서와 일치해야 합니다. 예를 들어 이전 예제의 `linux:rspec` 작업에서 변수 순서를 반대로 하면 유효하지 않습니다:

  ```yaml
  linux:rspec:
    stage: test
    needs:
      - job: linux:build
        parallel:
          matrix:
            - STACK: app1        # The variable order does not match `linux:build` and is invalid.
              PROVIDER: aws
    script: echo "Running rspec on linux..."
  ```

**Related topics**:

- [needs가 있는 여러 병렬화된 작업과(과) 함께 병렬화된 작업 지정](../jobs/job_control.md#specify-a-parallelized-job-using-needs-with-multiple-parallelized-jobs).
- [`needs:parallel:matrix`의 행렬 식](matrix_expressions.md#matrix-expressions-in-needsparallelmatrix).

### `pages` {#pages}

`pages`을(를) 사용하여 정적 콘텐츠를 GitLab에 업로드하는 [GitLab Pages](../../user/project/pages/_index.md) 작업을(를) 정의합니다. 그러면 콘텐츠가 웹 사이트로 게시됩니다.

다음을 수행해야 합니다:

- `pages: true`을(를) 정의하여 `public` 이름의 디렉터리를 게시합니다.
- 또는 다른 콘텐츠 디렉터리를 사용하려는 경우 [`pages.publish`](#pagespublish)을(를) 정의합니다.
- 콘텐츠 디렉터리의 루트에 비어 있지 않은 `index.html` 파일이 있어야 합니다.

**Keyword type**: 작업 키워드 또는 작업 이름 (더 이상 사용되지 않음). 작업의 일부로만 사용할 수 있습니다.

**Supported Values**:

- 부울입니다. `true`로 설정하면 기본 구성을 사용합니다.
- 구성 옵션의 해시입니다. 자세한 내용은 다음 섹션을 참조하세요.

**`pages`의 예**:

```yaml
create-pages:
  stage: deploy
  script:
    - mv my-html-content public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

이 예제에서는 `my-html-content/` 디렉터리의 이름을 `public/`로 바꿉니다. 이 디렉터리는 아티팩트로 내보내지고 GitLab Pages와 함께 게시됩니다.

**Example using a configuration hash**:

```yaml
create-pages:
  stage: deploy
  script:
    - echo "nothing to do here"
  pages:  # specifies that this is a Pages job and publishes the default public directory
    publish: my-html-content
    expire_in: "1 week"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

이 예제에서는 디렉터리를 이동하지 않지만 `publish` 속성을 직접 사용합니다. 또한 페이지 배포를 1주일 후에 게시 취소되도록 구성합니다.

**Additional details**:

- `pages`을(를) 작업 이름으로 사용하는 것은 [더 이상 사용되지 않습니다](deprecated_keywords.md#publish-keyword-and-pages-job-name-for-gitlab-pages).
- `pages`을(를) Pages 배포를 트리거하지 않고 작업 이름으로 사용하려면 `pages` 속성을 false로 설정합니다.

---

#### `pages.publish` {#pagespublish}

{{< history >}}

- [GitLab 16.1에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/415821).
- GitLab 17.9에서 `publish` 속성에 전달될 때 변수를 허용하도록 [변경되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/500000).
- GitLab 17.9에서 `publish` 속성을 `pages` 키워드 아래로 [이동했습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/428018).
- GitLab 17.10에서 `pages.publish` 경로를 자동으로 `artifacts:paths`에 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)했습니다.

{{< /history >}}

`pages.publish`을(를) 사용하여 [`pages` 작업](#pages)의 콘텐츠 디렉터리를 구성합니다.

**Keyword type**: 작업 키워드입니다. `pages` 작업의 일부로만 사용할 수 있습니다.

**Supported values**: Pages 콘텐츠를 포함하는 디렉터리의 경로입니다. [GitLab 17.10 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)에서 지정되지 않으면 기본 `public` 디렉터리가 사용되고 지정되면 이 경로가 자동으로 [`artifacts:paths`](#artifactspaths)에 추가됩니다.

**`pages.publish`의 예**:

```yaml
create-pages:
  stage: deploy
  script:
    - npx @11ty/eleventy --input=path/to/eleventy/root --output=dist
  pages:
    publish: dist  # this path is automatically appended to artifacts:paths
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

이 예제에서는 [Eleventy](https://www.11ty.dev)를 사용하여 정적 웹 사이트를 생성하고 생성된 HTML 파일을 `dist/` 디렉터리에 출력합니다. 이 디렉터리는 아티팩트로 내보내지고 GitLab Pages와 함께 게시됩니다.

`pages.publish` 필드에서 변수를 사용할 수도 있습니다. 예를 들어:

```yaml
create-pages:
  stage: deploy
  script:
    - mkdir -p $CUSTOM_FOLDER/$CUSTOM_PATH
    - cp -r public $CUSTOM_FOLDER/$CUSTOM_SUBFOLDER
  pages:
    publish: $CUSTOM_FOLDER/$CUSTOM_SUBFOLDER  # this path is automatically appended to artifacts:paths
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  variables:
    CUSTOM_FOLDER: "custom_folder"
    CUSTOM_SUBFOLDER: "custom_subfolder"
```

지정된 게시 경로는 빌드 루트에 상대적이어야 합니다.

**Additional details**:

- 최상위 `publish` 키워드는 [더 이상 사용되지 않으며](deprecated_keywords.md#publish-keyword-and-pages-job-name-for-gitlab-pages) 이제 `pages` 키워드 아래에 중첩되어야 합니다.

---

#### `pages.path_prefix` {#pagespath_prefix}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 16.7에서 `pages_multiple_versions_setting` 이름의 [플래그](../../administration/feature_flags/_index.md)가 있는 [실험](../../policy/development_stages_support.md)으로 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129534). 기본적으로 비활성화되어 있습니다.
- GitLab 17.4에서 [GitLab.com, GitLab Self-Managed, GitLab Dedicated에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/422145).
- GitLab 17.8에서 마침표를 허용하도록 [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/507423).
- GitLab 17.9에서 [일반 공급 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/487161). 기능 플래그 `pages_multiple_versions_setting`이 제거되었습니다.

{{< /history >}}

`pages.path_prefix`을(를) 사용하여 [GitLab Pages의 병렬 배포](../../user/project/pages/_index.md#parallel-deployments)의 경로 접두사를 구성합니다.

**Keyword type**: 작업 키워드입니다. `pages` 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 문자열
- [CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)
- 둘 다의 조합

주어진 값은 소문자로 변환되고 63바이트로 단축됩니다. 영숫자 문자 또는 마침표를 제외한 모든 항목은 하이픈으로 바뀝니다. 선행 및 후행 하이픈 또는 마침표는 허용되지 않습니다.

**`pages.path_prefix`의 예**:

```yaml
create-pages:
  stage: deploy
  script:
    - echo "Pages accessible through ${CI_PAGES_URL}"
  pages:  # specifies that this is a Pages job and publishes the default public directory
    path_prefix: "$CI_COMMIT_BRANCH"
```

이 예제에서는 각 브랜치에 대해 다른 페이지 배포가 생성됩니다.

---

#### `pages.expire_in` {#pagesexpire_in}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/456478)되었습니다.
- 변수 지원은 GitLab 17.11에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/492289).

{{< /history >}}

`expire_in`을(를) 사용하여 배포가 만료되기 전에 얼마나 오래 사용 가능해야 하는지 지정합니다. 배포가 만료된 후 10분마다 실행되는 cron 작업에 의해 비활성화됩니다.

기본적으로 [병렬 배포](../../user/project/pages/_index.md#parallel-deployments)는 24시간 후에 자동으로 만료됩니다. 이 동작을 비활성화하려면 값을 `never`로 설정합니다.

**Keyword type**: 작업 키워드입니다. `pages` 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 만료 시간입니다. 단위를 제공하지 않으면 시간이 초 단위입니다. 변수도 지원됩니다. 유효한 값은 다음을 포함합니다:

- `'42'`
- `42 seconds`
- `3 mins 4 sec`
- `2 hrs 20 min`
- `2h20min`
- `6 mos 1 day`
- `47 yrs 6 mos and 4d`
- `3 weeks and 2 days`
- `never`
- `$DURATION`

**`pages.expire_in`의 예**:

```yaml
create-pages:
  stage: deploy
  script:
    - echo "Pages accessible through ${CI_PAGES_URL}"
  pages:  # specifies that this is a Pages job and publishes the default public directory
    expire_in: 1 week
```

---

### `parallel` {#parallel}

{{< history >}}

- GitLab 15.9에서 `parallel`의 최대값이 50에서 200으로 [증가했습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/336576).

{{< /history >}}

`parallel`을(를) 사용하여 단일 파이프라인에서 작업을(를) 여러 번 병렬로 실행합니다.

여러 러너가 있거나 단일 러너가 여러 작업을(를) 동시에 실행하도록 구성되어야 합니다.

병렬 작업의 이름은 `job_name 1/N`에서 `job_name N/N`까지 순차적으로 지정됩니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `1`에서 `200`까지의 숫자 값입니다.

**`parallel`의 예**:

```yaml
test:
  script: rspec
  parallel: 5
```

이 예제에서는 병렬로 실행되는 5개 작업을(를) 생성합니다. `test 1/5`에서 `test 5/5`까지의 이름입니다.

**Additional details**:

- 모든 병렬 작업에는 `CI_NODE_INDEX` 및 `CI_NODE_TOTAL` [미리 정의된 CI/CD 변수](../variables/_index.md#predefined-cicd-variables)가 설정됩니다.
- `parallel`을(를) 사용하는 작업이 있는 파이프라인은 다음과 같을 수 있습니다:
  - 사용 가능한 러너보다 더 많은 작업을(를) 병렬로 생성합니다. 초과 작업은(는) 대기열에 들어가며 사용 가능한 러너를 기다리는 동안 `pending`로 표시됩니다.
  - `job_activity_limit_exceeded` 오류가 발생하면 파이프라인 생성으로 인해 모든 활성 파이프라인의 총 작업 수가 [인스턴스 제한을 초과](../../administration/cicd/limits.md#number-of-jobs-in-active-pipelines)하게 됩니다.

**Related topics**:

- [대규모 작업 병렬화](../jobs/job_control.md#parallelize-large-jobs).

---

#### `parallel:matrix` {#parallelmatrix}

{{< history >}}

- GitLab 15.9에서 최대 순열 수가 50에서 200으로 [증가했습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/336576).

{{< /history >}}

`parallel:matrix`을(를) 사용하여 단일 파이프라인에서 작업을(를) 여러 번 병렬로 실행하되 작업의 각 인스턴스에 대해 다른 변수 값을 사용합니다.

여러 러너가 있거나 단일 러너가 여러 작업을(를) 동시에 실행하도록 구성되어야 합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 변수의 해시 배열:

- 행렬 식별자(변수 이름이 됨)는 숫자, 문자, 밑줄(`_`)만 사용할 수 있습니다.
- 값은 문자열이거나 문자열 배열이어야 합니다.
- 순열 수는 200을 초과할 수 없습니다.

**`parallel:matrix`의 예**:

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: aws
        STACK:
          - monitoring
          - app1
          - app2
      - PROVIDER: [gcp, vultr]
        STACK: [data, processing]
  environment: $PROVIDER/$STACK
```

이 예제에서는 7개의 병렬 `deploystacks` 작업을(를) 생성합니다. 각각은 `PROVIDER` 및 `STACK`에 대해 다른 값을 가집니다:

- `deploystacks: [aws, monitoring]`
- `deploystacks: [aws, app1]`
- `deploystacks: [aws, app2]`
- `deploystacks: [gcp, data]`
- `deploystacks: [gcp, processing]`
- `deploystacks: [vultr, data]`
- `deploystacks: [vultr, processing]`

**Additional details**:

- `parallel:matrix` 작업은(는) 행렬 값을 작업 이름에 추가하여 서로 다른 작업을(를) 구분합니다. 그러나 긴 값으로 인해 작업 이름이 255자 제한을 초과할 수 있습니다. 자세한 내용은 [에픽 11791](https://gitlab.com/groups/gitlab-org/-/work_items/11791)을(를) 참조하세요.
- 행렬 변수 값은 [`rules:if`](#rulesif) 식에서 CI/CD 변수로 사용 가능합니다. 자세한 내용은 [`rules:if`에서 행렬 변수 사용](../jobs/job_control.md#use-matrix-variables-in-rulesif)을(를) 참조하세요.
- 동일한 값이지만 다른 이름을 가진 여러 행렬 구성을 만들 수 없습니다. 작업 이름은 이름이 아닌 행렬 값에서 생성되므로 동일한 값을 가진 행렬 항목은 서로를 덮어쓰는 동일한 작업 이름을 생성합니다.

  예를 들어 이 `test` 구성은 동일한 작업의 두 시리즈를 만들려고 시도하지만 `OS2` 버전이 `OS` 버전을 덮어씁니다:

  ```yaml
  test:
    parallel:
      matrix:
        - OS: [ubuntu]
          PROVIDER: [aws, gcp]
        - OS2: [ubuntu]
          PROVIDER: [aws, gcp]
  ```

**Related topics**:

- [병렬 작업의 1차원 행렬 실행](../jobs/job_control.md#run-a-one-dimensional-matrix-of-parallel-jobs).
- [트리거된 병렬 작업의 행렬 실행](../jobs/job_control.md#run-a-matrix-of-parallel-trigger-jobs).
- [각 병렬 행렬 작업에 대해 다른 러너 태그 선택](../jobs/job_control.md#select-different-runner-tags-for-each-parallel-matrix-job).
- [규칙에서 행렬 변수 사용](../jobs/job_control.md#use-matrix-variables-in-rules).
- [`needs:parallel:matrix`의 행렬 식](matrix_expressions.md#matrix-expressions-in-needsparallelmatrix).

---

### `release` {#release}

`release`을(를) 사용하여 [릴리스](../../user/project/releases/_index.md)를 만듭니다.

릴리스 작업은 [`glab` CLI](https://gitlab.com/gitlab-org/cli)에 액세스해야 하며 `$PATH`에 있어야 합니다.

[Docker 실행기](https://docs.gitlab.com/runner/executors/docker/)를 사용하는 경우 GitLab 컨테이너 레지스트리에서 이 이미지를 사용할 수 있습니다: `registry.gitlab.com/gitlab-org/cli:latest`

[Shell 실행기](https://docs.gitlab.com/runner/executors/shell/) 또는 유사한 것을 사용하는 경우 러너가 등록된 서버에 [`glab` CLI 설치](https://gitlab.com/gitlab-org/cli#installation)합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: `release` 부분 키:

- [`tag_name`](#releasetag_name)
- [`tag_message`](#releasetag_message) (선택 사항)
- [`name`](#releasename) (선택 사항)
- [`description`](#releasedescription)
- [`ref`](#releaseref) (선택 사항)
- [`milestones`](#releasemilestones) (선택 사항)
- [`released_at`](#releasereleased_at) (선택 사항)
- [`assets:links`](#releaseassetslinks) (선택 사항)

**`release` 키워드의 예**:

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  rules:
    - if: $CI_COMMIT_TAG                  # Run this job when a tag is created manually
  script:
    - echo "Running the release job."
  release:
    tag_name: $CI_COMMIT_TAG
    name: 'Release $CI_COMMIT_TAG'
    description: 'Release created using the CLI.'
```

이 예제는 릴리스를 만듭니다:

- Git 태그를 푸시할 때입니다.
- **코드** > **태그**의 UI에서 Git 태그를 추가할 때입니다.

**Additional details**:

- 릴리스 작업에는 `script` 키워드가 포함되어야 합니다. 릴리스 작업은 스크립트 명령의 출력을 사용할 수 있습니다. 스크립트가 필요하지 않으면 자리 표시자를 사용할 수 있습니다:

  ```yaml
  script:
    - echo "release job"
  ```

  자세한 내용은 [이슈 223856](https://gitlab.com/gitlab-org/gitlab/-/issues/223856)을(를) 참조하세요. 이 제한을 제거하는 것을 목표로 합니다.

- `release` 섹션은 `script` 키워드 후에 실행되고 `after_script` 전에 실행됩니다.
- 릴리스는 작업의 주 스크립트가 성공한 경우에만 생성됩니다.
- 릴리스가 이미 있으면 업데이트되지 않으며 `release` 키워드가 있는 작업이 실패합니다.

**Related topics**:

- [`release` 키워드의 CI/CD 예](../../user/project/releases/_index.md#creating-a-release-by-using-a-cicd-job).
- [단일 파이프라인에서 여러 릴리스 생성](../../user/project/releases/_index.md#create-multiple-releases-in-a-single-pipeline).
- [사용자 지정 SSL CA 인증서 사용](../../user/project/releases/_index.md#use-a-custom-ssl-ca-certificate-authority).

---

#### `release:tag_name` {#releasetag_name}

필수입니다. 릴리스의 Git 태그입니다.

태그가 프로젝트에 아직 없으면 릴리스와 동시에 생성됩니다. 새 태그는 파이프라인과 관련된 SHA를 사용합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 태그 이름입니다.

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`release:tag_name`의 예**:

프로젝트에 새 태그를 추가할 때 릴리스를 생성하려면:

- `$CI_COMMIT_TAG` CI/CD 변수를 `tag_name`로 사용합니다.
- [`rules:if`](#rulesif)을(를) 사용하여 새 태그에만 실행되도록 작업을(를) 구성합니다.

```yaml
job:
  script: echo "Running the release job for the new tag."
  release:
    tag_name: $CI_COMMIT_TAG
    description: 'Release description'
  rules:
    - if: $CI_COMMIT_TAG
```

동시에 릴리스와 새 태그를 생성하려면 [`rules`](#rules)이(가) 작업을(를) 새 태그에만 실행되도록 구성하지 않아야 합니다. 시멘틱 버전 관리 예:

```yaml
job:
  script: echo "Running the release job and creating a new tag."
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: 'Release description'
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

---

#### `release:tag_message` {#releasetag_message}

태그가 없으면 새로 생성된 태그는 `tag_message`에 지정된 메시지로 주석 처리됩니다. 생략하면 경량 태그가 생성됩니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 텍스트 문자열입니다.

**`release:tag_message`의 예**:

```yaml
  release_job:
    stage: release
    release:
      tag_name: $CI_COMMIT_TAG
      description: 'Release description'
      tag_message: 'Annotated tag message'
```

---

#### `release:name` {#releasename}

릴리스 이름입니다. 생략하면 `release: tag_name`의 값으로 채워집니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 텍스트 문자열입니다.

**`release:name`의 예**:

```yaml
  release_job:
    stage: release
    release:
      name: 'Release $CI_COMMIT_TAG'
```

---

#### `release:description` {#releasedescription}

릴리스의 긴 설명입니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 긴 설명이 있는 문자열입니다.
- 설명을 포함하는 파일의 경로입니다.
  - 파일 위치는 프로젝트 디렉터리(`$CI_PROJECT_DIR`)에 상대적이어야 합니다.
  - 파일이 심볼릭 링크인 경우 `$CI_PROJECT_DIR`에 있어야 합니다.
  - `./path/to/file` 및 파일 이름에 공백이 포함될 수 없습니다.

**`release:description`의 예**:

```yaml
job:
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: './path/to/CHANGELOG.md'
```

**Additional details**:

- `description`은(는) `glab`을(를) 실행하는 셸에서 계산됩니다. CI/CD 변수를 사용하여 설명을 정의할 수 있지만 일부 셸은 [변수를 참조하기 위해 다른 구문을 사용](../variables/job_scripts.md)합니다. 마찬가지로 일부 셸은 특수 문자를 이스케이프해야 할 수 있습니다. 예를 들어 백틱(`` ` ``)은(는) 백슬래시(` \ `)로 이스케이프해야 할 수 있습니다.

---

#### `release:ref` {#releaseref}

릴리스의 `ref`(들의 경우 `release: tag_name`이(가) 아직 없는 경우.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 커밋 SHA, 다른 태그 이름 또는 브랜치 이름입니다.

---

#### `release:milestones` {#releasemilestones}

릴리스가 연결된 각 마일스톤의 제목입니다.

---

#### `release:released_at` {#releasereleased_at}

릴리스가 준비되었을 때의 날짜 및 시간입니다.

**Supported values**:

- ISO 8601 형식으로 표현되고 따옴표로 묶인 날짜입니다.

**`release:released_at`의 예**:

```yaml
released_at: '2021-03-15T08:00:00Z'
```

**Additional details**:

- 정의되지 않으면 현재 날짜 및 시간이 사용됩니다.

---

#### `release:assets:links` {#releaseassetslinks}

`release:assets:links`을(를) 사용하여 릴리스에 [자산 링크](../../user/project/releases/release_fields.md#release-assets)를 포함합니다.

**`release:assets:links`의 예**:

```yaml
assets:
  links:
    - name: 'asset1'
      url: 'https://example.com/assets/1'
    - name: 'asset2'
      url: 'https://example.com/assets/2'
      filepath: '/pretty/url/1' # optional
      link_type: 'other' # optional
```

---

### `resource_group` {#resource_group}

`resource_group`을(를) 사용하여 동일한 프로젝트의 다양한 파이프라인에서 작업이 상호 배타적인지 확인하는 [리소스 그룹](../resource_groups/_index.md)을(를) 만듭니다.

예를 들어 동일한 리소스 그룹에 속하는 여러 작업이 동시에 대기열에 있으면 하나의 작업만 시작됩니다. 다른 작업은(는) `resource_group`이(가) 해제될 때까지 기다립니다.

리소스 그룹은 다른 프로그래밍 언어의 세마포어와 유사하게 동작합니다.

[프로세스 모드](../resource_groups/_index.md#process-modes)를 선택하여 배포 선호도에 따라 작업 동시성을 전략적으로 제어할 수 있습니다. 기본 프로세스 모드는 `unordered`입니다. 리소스 그룹의 프로세스 모드를 변경하려면 [API](../../api/resource_groups.md#update-a-resource-group)를 사용하여 기존 리소스 그룹을 편집하도록 요청을 보냅니다.

환경당 여러 리소스 그룹을 정의할 수 있습니다. 예를 들어 물리적 디바이스에 배포할 때 여러 물리적 디바이스가 있을 수 있습니다. 각 디바이스에 배포할 수 있지만 지정된 시간에 디바이스당 하나의 배포만 발생할 수 있습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 숫자, 문자, `-`, `_`, `/`, `$`, `{`, `}`, `.`, 공백만 가능합니다. `/`로 시작하거나 끝날 수 없습니다. CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`resource_group`의 예**:

```yaml
deploy-to-production:
  script: deploy
  resource_group: production
```

이 예제에서 두 개의 별도 파이프라인의 `deploy-to-production` 작업은(는) 동시에 실행될 수 없습니다. 결과적으로 프로덕션 환경에 동시 배포가 발생하지 않는지 확인할 수 있습니다.

**Related topics**:

- [교차 프로젝트/상위-하위 파이프라인이 있는 파이프라인 수준 동시성 제어](../resource_groups/_index.md#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines).

---

### `retry` {#retry}

`retry`을(를) 사용하여 실패했을 때 작업을(를) 몇 번 재시도하는지 구성합니다. 정의되지 않으면 `0`로 기본값이 설정되고 작업은(는) 재시도되지 않습니다.

작업이 실패하면 작업이 성공하거나 최대 재시도 수에 도달할 때까지 최대 2번 더 처리됩니다.

기본적으로 모든 실패 유형으로 인해 작업이 재시도됩니다. [`retry:when`](#retrywhen) 또는 [`retry:exit_codes`](#retryexit_codes)을(를) 사용하여 재시도할 실패를 선택합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- `0` (기본값), `1`, 또는 `2`.

**`retry`의 예**:

```yaml
test:
  script: rspec
  retry: 2

test_advanced:
  script:
    - echo "Run a script that results in exit code 137."
    - exit 137
  retry:
    max: 2
    when: runner_system_failure
    exit_codes: 137
```

`test_advanced`은(는) 종료 코드가 `137`이거나 러너 시스템 실패가 있으면 최대 2번까지 재시도됩니다.

---

#### `retry:when` {#retrywhen}

`retry:when`을(를) `retry:max`과(와) 함께 사용하여 특정 실패 사례에만 작업을(를) 재시도합니다. `retry:max`은(는) [`retry`](#retry)과(와) 같은 최대 재시도 횟수이며 `0`, `1` 또는 `2`일 수 있습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 단일 실패 유형 또는 하나 이상의 실패 유형 배열:

<!--
  If you change any of the following values, make sure to update the `RETRY_WHEN_IN_DOCUMENTATION`
  array in `spec/lib/gitlab/ci/config/entry/retry_spec.rb`.
  The test there makes sure that all documented
  values are valid as a configuration option and therefore should always
  stay in sync with this documentation.
-->

- `always`: 모든 실패 재시도 (기본값).
- `unknown_failure`: 실패 이유가 불명확한 경우 재시도합니다.
- `script_failure`: 다음의 경우 재시도합니다:
  - 스크립트가 실패했습니다.
  - 러너가 Docker 이미지를 가져오지 못했습니다. `docker`, `docker+machine`, `kubernetes` [실행기](https://docs.gitlab.com/runner/executors/)의 경우.
- `api_failure`: API 실패 시 재시도합니다.
- `stuck_or_timeout_failure`: 작업이 막혔거나 시간 초과된 경우 재시도합니다.
- `runner_system_failure`: 러너 시스템 실패(작업 설정 실패 등)가 있으면 재시도합니다.
- `runner_unsupported`: 러너가 지원되지 않으면 재시도합니다.
- `stale_schedule`: 지연된 작업을(를) 실행할 수 없으면 재시도합니다.
- `job_execution_timeout`: 스크립트가 작업에 설정된 최대 실행 시간을 초과한 경우 재시도합니다.
- `archived_failure`: 작업이 보관되어 실행할 수 없으면 재시도합니다.
- `unmet_prerequisites`: 작업이 필수 구성 요소 작업을 완료하지 못한 경우 재시도합니다.
- `scheduler_failure`: 스케줄러가 작업을(를) 러너에 할당하지 못하면 재시도합니다.
- `data_integrity_failure`: 알 수 없는 작업 문제가 있으면 재시도합니다.

**`retry:when`의 예** (단일 실패 유형):

```yaml
test:
  script: rspec
  retry:
    max: 2
    when: runner_system_failure
```

러너 시스템 실패 이외의 실패가 있으면 작업이 재시도되지 않습니다.

**`retry:when`의 예** (실패 유형 배열):

```yaml
test:
  script: rspec
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
```

---

#### `retry:exit_codes` {#retryexit_codes}

{{< history >}}

- GitLab 16.10에서 `ci_retry_on_exit_codes` [플래그](../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/430037)되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 16.11에서 [GitLab.com 및 GitLab Self-Managed에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/430037).
- GitLab 17.5에서 [일반 공급 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/452412). 기능 플래그 `ci_retry_on_exit_codes`이 제거되었습니다.

{{< /history >}}

`retry:exit_codes`을(를) `retry:max`과(와) 함께 사용하여 특정 실패 사례에만 작업을(를) 재시도합니다. `retry:max`은(는) [`retry`](#retry)과(와) 같은 최대 재시도 횟수이며 `0`, `1` 또는 `2`일 수 있습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 단일 종료 코드.
- 종료 코드 배열.

**`retry:exit_codes`의 예**:

```yaml
test_job_1:
  script:
    - echo "Run a script that results in exit code 1. This job isn't retried."
    - exit 1
  retry:
    max: 2
    exit_codes: 137

test_job_2:
  script:
    - echo "Run a script that results in exit code 137. This job will be retried."
    - exit 137
  retry:
    max: 1
    exit_codes:
      - 255
      - 137
```

**Related topics**:

변수를 사용하여 작업 실행의 특정 스테이지에 대한 [재시도 시도 횟수](../runners/configure_runners.md#job-stages-attempts)를 지정할 수 있습니다.

---

### `rules` {#rules}

`rules`을(를) 사용하여 파이프라인에 작업을(를) 포함하거나 제외합니다.

규칙은 파이프라인이 생성될 때 평가되며 순서대로 평가됩니다. 일치하는 것이 발견되면 더 이상의 규칙이 확인되지 않으며 작업은 구성에 따라 파이프라인에 포함되거나 제외됩니다. 일치하는 규칙이 없으면 작업이 파이프라인에 추가되지 않습니다.

`rules`은(는) 규칙 배열을 허용합니다. 각 규칙에는 최소한 다음 중 하나가 있어야 합니다:

- `if`
- `changes`
- `exists`
- `when`

규칙을 선택적으로 다음과 결합할 수도 있습니다:

- `allow_failure`
- `needs`
- `variables`
- `interruptible`

[복잡한 규칙](../jobs/job_rules.md#complex-rules)을(를) 위해 여러 키워드를 함께 결합할 수 있습니다.

작업이 파이프라인에 추가됩니다:

- `if`, `changes`, 또는 `exists` 규칙이 일치하고 `when: on_success` (정의되지 않은 경우 기본값), `when: delayed`, 또는 `when: always`으로 구성된 경우.
- `when: on_success`, `when: delayed`, 또는 `when: always`인 규칙에 도달한 경우.

작업이 파이프라인에 추가되지 않습니다:

- 일치하는 규칙이 없으면.
- 규칙이 일치하고 `when: never`인 경우.

추가 예제는 [`rules`을(를) 사용하여 작업이 실행되는 시기 지정](../jobs/job_rules.md)을(를) 참조하세요.

---

#### `rules:if` {#rulesif}

언제 파이프라인에 작업을(를) 추가할지 지정하려면 `rules:if` 절을 사용합니다:

- `if` 문이 참이면 작업을(를) 파이프라인에 추가합니다.
- `if` 문이 참이지만 `when: never`과(와) 결합되면 작업을(를) 파이프라인에 추가하지 마세요.
- `if` 문이 거짓이면 다음 `rules` 항목(있는 경우)을 확인합니다.

`if` 절은 다음과 같이 평가됩니다:

- [CI/CD 변수](../variables/_index.md) 또는 [미리 정의된 CI/CD 변수](../variables/predefined_variables.md)의 값을 기반으로 [일부 예외](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)가 있습니다.
- 순서대로 [`rules` 실행 플로우](#rules)를 따릅니다.

**Keyword type**: 작업 특정 및 파이프라인 특정입니다. 작업의 일부로 작업 동작을 구성하거나 [`workflow`](#workflow)을(를) 사용하여 파이프라인 동작을 구성할 수 있습니다.

**Supported values**:

- [CI/CD 변수 식](../jobs/job_rules.md#cicd-variable-expressions).

**`rules:if`의 예**:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/ && $CI_MERGE_REQUEST_TARGET_BRANCH_NAME != $CI_DEFAULT_BRANCH
      when: never
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/
      when: manual
      allow_failure: true
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME
```

**Additional details**:

- `if`에 [중첩 변수](../variables/where_variables_can_be_used.md#nested-variable-expansion)를 사용할 수 없습니다. 자세한 내용은 [이슈 327780](https://gitlab.com/gitlab-org/gitlab/-/issues/327780)을(를) 참조하세요.
- 규칙이 일치하고 `when`이 정의되지 않으면 규칙은 작업에 대해 정의된 `when`을(를) 사용하며, 이는 정의되지 않은 경우 `on_success`으로 기본값이 됩니다.
- `when`을(를) 작업 수준과 규칙의 `when`과(와) 혼합할 수 있습니다. `rules`의 `when` 구성이 작업 수준의 `when`보다 우선합니다.
- [`script` 섹션](../variables/job_scripts.md)의 변수와 달리 규칙 식의 변수는 항상 `$VARIABLE`으로 형식이 지정됩니다.
  - `rules:if`을(를) `include`과(와) 함께 사용하여 [다른 구성 파일을 조건부로 포함](includes.md#use-rules-with-include)할 수 있습니다.
- `=~` 및 `!~` 식의 오른쪽에 있는 CI/CD 변수는 [정규 식으로 계산](../jobs/job_rules.md#store-a-regular-expression-in-a-variable)됩니다.

**Related topics**:

- [`rules`에 대한 일반적인 `if` 식](../jobs/job_rules.md#common-if-clauses-with-predefined-variables).
- [중복 파이프라인 방지](../jobs/job_rules.md#avoid-duplicate-pipelines).
- [`rules`를 사용하여 머지 리퀘스트 파이프라인 실행](../pipelines/merge_request_pipelines.md#configure-merge-request-pipelines).

---

#### `rules:changes` {#ruleschanges}

`rules:changes`을(를) 사용하여 특정 파일의 변경 사항을 확인하여 파이프라인에 작업을(를) 추가할 시기를 지정합니다.

새 브랜치 파이프라인이거나 Git `push` 이벤트가 없을 때 `rules: changes`은(는) 항상 참으로 계산되고 작업은(는) 항상 실행됩니다. 태그 파이프라인, 예약된 파이프라인, 수동 파이프라인과 같은 파이프라인은 모두 관련된 Git `push` 이벤트가 없습니다. 이러한 경우를 해결하려면 [`rules: changes: compare_to`](#ruleschangescompare_to)을(를) 사용하여 파이프라인 ref와 비교할 브랜치를 지정합니다.

`compare_to`을(를) 사용하지 않으면 [브랜치 파이프라인](../pipelines/pipeline_types.md#branch-pipeline) 또는 [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md)에서만 `rules: changes`을(를) 사용해야 하지만 `rules: changes`은(는) 새 브랜치를 생성할 때 여전히 참으로 계산됩니다. 다음:

- 머지 리퀘스트 파이프라인, `rules:changes`은(는) 대상 머지 리퀘스트 브랜치의 변경 사항을 비교합니다.
- 브랜치 파이프라인, `rules:changes`은(는) 브랜치의 이전 커밋과 변경 사항을 비교합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

다음을 포함한 임의 개수의 배열:

- 파일의 경로입니다. 파일 경로에 [CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)가 포함될 수 있습니다.
- 와일드카드 경로:
  - 단일 디렉터리(예: `path/to/directory/*`)입니다.
  - 디렉터리 및 모든 하위 디렉터리(예: `path/to/directory/**/*`)입니다.
- 와일드카드 [glob](https://en.wikipedia.org/wiki/Glob_(programming)) 경로는 동일한 확장명 또는 여러 확장명을 가진 모든 파일(예: `*.md` 또는 `path/to/directory/*.{rb,py,sh}`)입니다.
- 루트 디렉터리 또는 모든 디렉터리의 파일에 대한 와일드카드 경로(큰따옴표로 묶임)입니다. 예를 들어 `"*.json"` 또는 `"**/*.json"`입니다.

**`rules:changes`의 예**:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - Dockerfile
      when: manual
      allow_failure: true

docker build alternative:
  variables:
    DOCKERFILES_DIR: 'path/to/dockerfiles'
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - $DOCKERFILES_DIR/**/*
```

이 예에서:

- 파이프라인이 머지 리퀘스트 파이프라인인 경우 `Dockerfile` 및 `$DOCKERFILES_DIR/**/*`의 파일 변경 사항을 확인합니다.
- `Dockerfile`이(가) 변경된 경우 작업을(를) 수동 작업으로 파이프라인에 추가하고 파이프라인은 작업이 트리거되지 않아도 계속 실행됩니다(`allow_failure: true`).
- `$DOCKERFILES_DIR/**/*`의 파일이 변경된 경우 작업을(를) 파이프라인에 추가합니다.
- 나열된 파일이 변경되지 않은 경우 파이프라인에 작업을(를) 추가하지 마세요 (`when: never`과 동일).

**Additional details**:

- Glob 패턴은 Ruby의 [`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)로 해석되며 [플래그](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29) `File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`를 사용합니다.
- 성능상의 이유로 GitLab은 `changes` 패턴 또는 파일 경로에 대해 최대 50,000개의 검사를 수행합니다. 50,000번째 검사 후 패턴화된 glob이 있는 규칙은 항상 일치합니다. 즉, `changes` 규칙은 50,000개를 초과하는 파일이 변경되었을 때 항상 일치를 가정하거나 50,000개 미만의 변경된 파일이 있지만 `changes` 규칙이 50,000번 이상 확인되었을 때입니다.
- `rules:changes` 섹션당 최대 50개의 패턴 또는 파일 경로를 정의할 수 있습니다.
- `changes`은 일치하는 파일이 변경된 경우(`OR` 작업) `true`로 확인됩니다.
- 추가 예제는 [`rules`을(를) 사용하여 작업이 실행되는 시기 지정](../jobs/job_rules.md)을(를) 참조하세요.
- `$` 문자를 변수와 경로 모두에 사용할 수 있습니다. 예를 들어 `$VAR` 변수가 있으면 해당 값이 사용됩니다. 존재하지 않으면 `$`이(가) 경로의 일부로 해석됩니다.
- `./`, 이중 슬래시(`//`) 또는 기타 종류의 상대 경로를 사용하지 마세요. 경로는 정확한 문자열 비교로 일치하며 셸에서와 같이 평가되지 않습니다.

**Related topics**:

- [작업또는 파이프라인이 `rules: changes`를 사용할 때 예기치 않게 실행될 수 있습니다](../jobs/job_troubleshooting.md#jobs-or-pipelines-run-unexpectedly-when-using-changes).

---

##### `rules:changes:paths` {#ruleschangespaths}

{{< history >}}

- [GitLab 15.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90171)

{{< /history >}}

`rules:changes`을(를) 사용하여 특정 파일이 변경된 경우에만 파이프라인에 작업을(를) 추가하도록 지정하고 `rules:changes:paths`을(를) 사용하여 파일을 지정합니다.

`rules:changes:paths`은(는) 하위 키 없이 [`rules:changes`](#ruleschanges)을(를) 사용하는 것과 동일합니다. 모든 추가 세부 정보 및 관련 항목은 동일합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `rules:changes`과(와) 동일합니다.

**`rules:changes:paths`의 예**:

```yaml
docker-build-1:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - Dockerfile

docker-build-2:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths:
          - Dockerfile
```

이 예제에서는 두 작업 모두 동일한 동작을 합니다.

---

##### `rules:changes:compare_to` {#ruleschangescompare_to}

{{< history >}}

- GitLab 15.3에서 [도입되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/293645) [플래그](../../administration/feature_flags/_index.md)의 이름은 `ci_rules_changes_compare`입니다. 기본적으로 활성화됩니다.
- GitLab 15.5에서 [일반적으로 사용 가능합니다](https://gitlab.com/gitlab-org/gitlab/-/issues/366412). 기능 플래그 `ci_rules_changes_compare`이 제거되었습니다.
- CI/CD 변수 지원은 GitLab 17.2에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/369916).

{{< /history >}}

`rules:changes:compare_to`을(를) 사용하여 [`rules:changes:paths`](#ruleschangespaths) 아래에 나열된 파일의 변경 사항을 비교할 ref를 지정합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있으며 `rules:changes:paths`와(과) 결합해야 합니다.

**Supported values**:

- `main`, `branch1` 또는 `refs/heads/branch1`과(와) 같은 브랜치 이름입니다.
- `tag1` 또는 `refs/tags/tag1`과(와) 같은 태그 이름입니다.
- `2fg31ga14b`과(와) 같은 커밋 SHA입니다.

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`rules:changes:compare_to`의 예**:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths:
          - Dockerfile
        compare_to: 'refs/heads/branch1'
```

이 예제에서 `docker build` 작업은 `Dockerfile`이(가) `refs/heads/branch1`을(를) 기준으로 변경되었고 파이프라인 소스가 머지 리퀘스트 이벤트인 경우에만 포함됩니다.

**Additional details**:

- 일부 상황에서 `compare_to`을 사용하면 예상치 못한 결과가 발생할 수 있습니다:
  - [병합된 결과 파이프라인](../pipelines/merged_results_pipelines.md#troubleshooting)의 경우 비교 기준이 GitLab에서 생성한 내부 커밋이기 때문입니다.
  - 포크된 프로젝트에서 [이슈 424584](https://gitlab.com/gitlab-org/gitlab/-/issues/424584)를 참조하세요.

**Related topics**:

- `rules:changes:compare_to`을 사용하여 [브랜치가 비어 있으면 작업을 건너뜁니다](../jobs/job_rules.md#skip-jobs-if-the-branch-is-empty).

---

#### `rules:exists` {#rulesexists}

{{< history >}}

- CI/CD 변수 지원이 GitLab 15.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/283881)되었습니다.
- `exists` 패턴 또는 파일 경로에 대한 최대 검사 수가 GitLab 17.7에서 10,000에서 50,000으로 [증가](https://gitlab.com/gitlab-org/gitlab/-/issues/227632)했습니다.
- 디렉터리 경로 지원이 GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/327485)되었습니다.

{{< /history >}}

`exists`을 사용하여 리포지토리에 특정 파일 또는 디렉터리가 존재할 때 작업을 실행합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부 또는 [`include`](#include)으로 사용할 수 있습니다.

**Supported values**:

- 파일 또는 디렉터리 경로의 배열입니다. 경로는 프로젝트 디렉터리(`$CI_PROJECT_DIR`)를 기준으로 하며 직접 외부로 연결할 수 없습니다. 파일 경로는 glob 패턴과 [CI/CD 변수](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)를 사용할 수 있습니다.

**`rules:exists`의 예**:

```yaml
job1:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - exists:
        - Dockerfile

job2:
  variables:
    DOCKERPATH: "**/Dockerfile"
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - exists:
        - $DOCKERPATH
```

이 예에서:

- `job1`은 리포지토리의 루트 디렉터리에 `Dockerfile`이 존재하면 실행됩니다.
- `job2`은 리포지토리의 어디든 `Dockerfile`이 존재하면 실행됩니다.

**Additional details**:

- Glob 패턴은 Ruby의 [`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)로 해석되며 [플래그](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29) `File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`를 사용합니다.
- 성능상의 이유로 GitLab은 `exists` 패턴 또는 파일 경로에 대해 최대 50,000개의 검사를 수행합니다. 50,000번째 검사 후 패턴화된 glob이 있는 규칙은 항상 일치합니다. 즉, `exists` 규칙은 파일이 50,000개 이상인 프로젝트에서 또는 파일이 50,000개 미만이지만 `exists` 규칙이 50,000회 이상 검사되는 경우 항상 일치한다고 가정합니다.
  - 패턴이 있는 glob이 여러 개인 경우 제한은 50,000을 glob의 개수로 나눈 값입니다. 예를 들어, 5개의 패턴이 있는 glob 규칙의 파일 제한은 10,000입니다.
- `rules:exists` 섹션당 최대 50개의 패턴 또는 파일 경로를 정의할 수 있습니다.
- `exists`은 나열된 파일 중 하나라도 발견되면(`OR` 작업) `true`로 해석됩니다.
- 작업 수준의 `rules:exists`을 사용하면 GitLab은 파이프라인을 실행하는 프로젝트와 ref에서 파일을 검색합니다. [`include`을 `rules:exists`과 함께](includes.md#include-with-rulesexists) 사용할 때 GitLab은 `include` 섹션을 포함하는 파일의 프로젝트와 ref에서 파일 또는 디렉터리를 검색합니다. `include` 섹션을 포함하는 프로젝트는 파이프라인을 실행하는 프로젝트와 다를 수 있습니다:
  - [중첩된 포함](includes.md#use-nested-includes)을 사용할 때.
  - [컴플라이언스 파이프라인](../../user/compliance/compliance_pipelines.md)을 사용할 때.
- `rules:exists`은 [아티팩트](../jobs/job_artifacts.md)의 존재 여부를 검색할 수 없습니다. `rules` 평가는 작업이 실행되기 전에 발생하고 아티팩트가 가져와지기 전이기 때문입니다.
- 디렉터리의 존재를 테스트하려면 경로가 슬래시(/)로 끝나야 합니다.

---

##### `rules:exists:paths` {#rulesexistspaths}

{{< history >}}

- GitLab 16.11에서 `ci_support_rules_exists_paths_and_project` [플래그](../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 17.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)합니다. 기능 플래그 `ci_support_rules_exists_paths_and_project`이 제거되었습니다.

{{< /history >}}

`rules:exists:paths`은(는) 하위 키 없이 [`rules:exists`](#rulesexists)을(를) 사용하는 것과 동일합니다. 모든 추가 세부사항은 동일합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부 또는 [`include`](#include)으로 사용할 수 있습니다.

**Supported values**:

- 파일 경로의 배열입니다.

**`rules:exists:paths`의 예**:

```yaml
docker-build-1:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      exists:
        - Dockerfile

docker-build-2:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      exists:
        paths:
          - Dockerfile
```

이 예제에서는 두 작업 모두 동일한 동작을 합니다.

---

##### `rules:exists:project` {#rulesexistsproject}

{{< history >}}

- GitLab 16.11에서 `ci_support_rules_exists_paths_and_project` [플래그](../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 17.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)합니다. 기능 플래그 `ci_support_rules_exists_paths_and_project`이 제거되었습니다.

{{< /history >}}

`rules:exists:project`을 사용하여 [`rules:exists:paths`](#rulesexistspaths) 아래에 나열된 파일을 검색할 위치를 지정합니다. `rules:exists:paths`과 함께 사용해야 합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부 또는 [`include`](#include)으로 사용할 수 있으며, `rules:exists:paths`과 결합해야 합니다.

**Supported values**:

- `exists:project`: 네임스페이스와 그룹을 포함한 전체 프로젝트 경로입니다.
- `exists:ref`: 선택 사항. 파일을 검색할 때 사용할 커밋 ref입니다. ref는 태그, 브랜치 이름 또는 SHA일 수 있습니다. 지정하지 않으면 프로젝트의 `HEAD`로 기본값이 지정됩니다.

**`rules:exists:project`의 예**:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - exists:
        paths:
          - Dockerfile
        project: my-group/my-project
        ref: v1.0.0
```

이 예에서 `docker build` 작업은 `v1.0.0` 태그가 지정된 커밋에서 프로젝트 `my-group/my-project`에 `Dockerfile`이 존재할 때만 포함됩니다.

---

#### `rules:when` {#ruleswhen}

`rules:when`을 단독으로 또는 다른 규칙의 일부로 사용하여 파이프라인에 작업을 추가하기 위한 조건을 제어합니다. `rules:when`은 [`when`](#when)과 유사하지만 입력 옵션이 약간 다릅니다.

`rules:when` 규칙이 `if`, `changes`, 또는 `exists`과 결합되지 않으면 작업의 규칙을 평가할 때 도달하면 항상 일치합니다.

**Keyword type**: 작업별입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `on_success`(기본값): 이전 스테이지의 작업이 실패하지 않을 때만 작업을 실행합니다.
- `on_failure`: 이전 스테이지의 최소 하나의 작업이 실패할 때만 작업을 실행합니다.
- `never`: 이전 스테이지의 작업 상태와 관계없이 작업을 실행하지 않습니다.
- `always`: 이전 스테이지의 작업 상태와 관계없이 작업을 실행합니다.
- `manual`: 작업을 [수동 작업](../jobs/job_control.md#create-a-job-that-must-be-run-manually)으로 파이프라인에 추가합니다. [`allow_failure`](#allow_failure)의 기본값이 `false`로 변경됩니다.
- `delayed`: 작업을 [지연된 작업](../jobs/job_control.md#run-a-job-after-a-delay)으로 파이프라인에 추가합니다.

**`rules:when`의 예**:

```yaml
job1:
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_REF_NAME =~ /feature/
      when: delayed
    - when: manual
  script:
    - echo
```

이 예에서 `job1`은 파이프라인에 추가됩니다:

- 기본 브랜치의 경우, `when: on_success`을 사용합니다. 이것은 `when`이 정의되지 않을 때의 기본 동작입니다.
- 기능 브랜치의 경우 지연된 작업으로 실행됩니다.
- 다른 모든 경우에는 수동 작업으로 실행됩니다.

**Additional details**:

- `on_success`과 `on_failure`의 상태를 평가할 때:
  - [`allow_failure: true`](#allow_failure)이 있는 이전 스테이지의 작업은 실패했더라도 성공으로 간주됩니다.
  - 이전 스테이지에서 건너뛴 작업(예: [시작되지 않은 수동 작업](../jobs/job_control.md#create-a-job-that-must-be-run-manually))은 성공으로 간주됩니다.
- `rules:when: manual`을 사용하여 [수동 작업을 추가](../jobs/job_control.md#create-a-job-that-must-be-run-manually)할 때:
  - [`allow_failure`](#allow_failure)은 기본적으로 `false`이 됩니다. 이 기본값은 [`when: manual`](#when)을 사용하여 수동 작업을 추가하는 것과 반대입니다.
  - `when: manual`과 동일한 동작을 달성하려면 `rules` 외부에서 정의하고 [`rules: allow_failure`](#rulesallow_failure)을 `true`로 설정합니다.

---

#### `rules:allow_failure` {#rulesallow_failure}

[`allow_failure: true`](#allow_failure)을 `rules`에서 사용하여 작업이 파이프라인을 중단하지 않고 실패하도록 허용합니다.

`allow_failure: true`을 수동 작업과 함께 사용할 수도 있습니다. 파이프라인은 수동 작업의 결과를 기다리지 않고 계속 실행됩니다. `allow_failure: false`을 규칙의 `when: manual`과 결합하면 파이프라인이 수동 작업이 실행될 때까지 기다렸다가 계속됩니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `true` 또는 `false`. 정의하지 않으면 `false`로 기본 설정됩니다.

**`rules:allow_failure`의 예**:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH
      when: manual
      allow_failure: true
```

규칙이 일치하면 작업은 `allow_failure: true`이 있는 수동 작업입니다.

**Additional details**:

- 규칙 수준의 `rules:allow_failure`은 작업 수준의 [`allow_failure`](#allow_failure)을 재정의하며, 특정 규칙이 작업을 트리거할 때만 적용됩니다.

---

#### `rules:needs` {#rulesneeds}

{{< history >}}

- GitLab 16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/31581)되었으며, `introduce_rules_with_needs`이라는 [플래그](../../administration/feature_flags/_index.md)를 사용합니다. 기본적으로 비활성화되어 있습니다.
- GitLab 16.2에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/408871)되었습니다. 기능 플래그 `introduce_rules_with_needs`이 제거되었습니다.

{{< /history >}}

규칙에서 `needs`을 사용하여 특정 조건에 대한 작업의 [`needs`](#needs)을 업데이트합니다. 조건이 규칙과 일치하면 작업의 `needs` 구성이 규칙의 `needs`로 완전히 대체됩니다.

**Keyword type**: 작업별입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 문자열로 표현된 작업 이름의 배열입니다.
- 작업 이름과 선택적으로 추가 속성이 있는 해시입니다.
- 빈 배열(`[]`)이며, 특정 조건이 충족될 때 작업 needs를 없음으로 설정합니다.

**`rules:needs`의 예**:

```yaml
build-dev:
  stage: build
  rules:
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH
  script: echo "Feature branch, so building dev version..."

build-prod:
  stage: build
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  script: echo "Default branch, so building prod version..."

tests:
  stage: test
  rules:
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH
      needs: ['build-dev']
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      needs: ['build-prod']
  script: echo "Running dev specs by default, or prod specs when default branch..."
```

이 예에서:

- 파이프라인이 기본 브랜치가 아닌 브랜치에서 실행되고 따라서 규칙이 첫 번째 조건과 일치하면 `specs` 작업은 `build-dev` 작업이 필요합니다.
- 파이프라인이 기본 브랜치에서 실행되고 따라서 규칙이 두 번째 조건과 일치하면 `specs` 작업은 `build-prod` 작업이 필요합니다.

**Additional details**:

- 규칙의 `needs`은 작업 수준에서 정의된 모든 `needs`을 재정의합니다. 재정의될 때 동작은 [작업 수준의 `needs`](#needs)과 동일합니다.
- 규칙의 `needs`은 [`artifacts`](#needsartifacts)과 [`optional`](#needsoptional)을 허용할 수 있습니다.

---

#### `rules:variables` {#rulesvariables}

[`variables`](#variables)을 `rules`에서 사용하여 특정 조건에 대한 변수를 정의합니다.

**Keyword type**: 작업별입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `VARIABLE-NAME: value` 형식의 변수 해시입니다.

**`rules:variables`의 예**:

```yaml
job:
  variables:
    DEPLOY_VARIABLE: "default-deploy"
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
      variables:                              # Override DEPLOY_VARIABLE defined
        DEPLOY_VARIABLE: "deploy-production"  # at the job level.
    - if: $CI_COMMIT_REF_NAME =~ /feature/
      variables:
        IS_A_FEATURE: "true"                  # Define a new variable.
  script:
    - echo "Run script with $DEPLOY_VARIABLE as an argument"
    - echo "Run another script if $IS_A_FEATURE exists"
```

---

#### `rules:interruptible` {#rulesinterruptible}

{{< history >}}

- GitLab 16.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/194023)되었습니다.

{{< /history >}}

규칙에서 `interruptible`을 사용하여 특정 조건에 대한 작업의 [`interruptible`](#interruptible) 값을 업데이트합니다.

**Keyword type**: 작업별입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `true` 또는 `false`.

**`rules:interruptible`의 예**:

```yaml
job:
  script: echo "Hello, Rules!"
  interruptible: true
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
      interruptible: false  # Override interruptible defined at the job level.
    - when: on_success
```

**Additional details**:

- 규칙 수준의 `rules:interruptible`은 작업 수준의 [`interruptible`](#interruptible)을 재정의하며, 특정 규칙이 작업을 트리거할 때만 적용됩니다.

---

### `run` {#run}

{{< details >}}

- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/440487) 되었으며 [플래그](../../administration/feature_flags/_index.md) `pipeline_run_keyword`라는 이름입니다. 기본적으로 비활성화되어 있습니다. GitLab Runner 17.1이 필요합니다.
- 기능 플래그 `pipeline_run_keyword`이 GitLab 17.5에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/471925)되었습니다.

{{< /history >}}

> [!note]
> 이 기능은 테스트용으로만 사용 가능하며 프로덕션 사용 준비가 되지 않았습니다.

`run`을 사용하여 작업에서 실행할 [단계](../functions/_index.md)의 시리즈를 정의합니다. 각 단계는 스크립트 또는 사전 정의된 단계일 수 있습니다.

선택사항인 환경 변수 및 입력을 제공할 수도 있습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 각 해시가 다음 가능한 키를 가진 단계를 나타내는 해시 배열입니다:
  - `name`: 단계의 이름을 나타내는 문자열입니다.
  - `script`: 실행할 셸 명령을 포함하는 문자열입니다.
  - `step`: 실행할 사전 정의된 단계를 식별하는 문자열입니다.
  - `env`: 선택 사항. 이 단계에만 해당하는 환경 변수의 해시입니다.
  - `inputs`: 선택 사항. 사전 정의된 단계에 대한 입력 매개변수의 해시입니다.

각 배열 항목은 `name`을 포함해야 하며, `script` 또는 `step` 중 하나만 포함해야 합니다(둘 다는 아님).

**`run`의 예**:

``` yaml
job:
  run:
    - name: 'hello_steps'
      script: 'echo "hello from step1"'
    - name: 'bye_steps'
      step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@main
      inputs:
        echo: 'bye steps!'
      env:
        var1: 'value 1'
```

이 예에서 작업에는 두 개의 단계가 있습니다:

- `hello_steps`은 `echo` 셸 명령을 실행합니다.
- `bye_steps`은 환경 변수와 입력 매개변수를 포함한 사전 정의된 단계를 사용합니다.

**Additional details**:

- 단계는 `script` 또는 `step` 키를 가질 수 있지만 둘 다는 아닙니다.
- `run` 구성은 기존의 [`script`](#script), [`after_script`](#after_script) 또는 [`before_script`](#before_script) 키워드와 함께 사용할 수 없습니다.
- 다중 줄 스크립트는 [YAML 블록 스칼라 구문](script.md#split-long-commands)을 사용하여 정의할 수 있습니다.

---

### `script` {#script}

`script`을 사용하여 실행기가 실행할 명령을 지정합니다.

[트리거 작업](#trigger)을 제외한 모든 작업에는 `script` 키워드가 필요합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 다음을 포함하는 배열:

- 한 줄 명령.
- 여러 줄로 [분할된](script.md#split-long-commands) 긴 명령.
- [YAML 앵커](yaml_optimization.md#yaml-anchors-for-scripts).

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`script`의 예**:

```yaml
job1:
  script: "bundle exec rspec"

job2:
  script:
    - uname -a
    - bundle exec rspec
```

**Additional details**:

- [`script`에서 이러한 특수 문자를 사용](script.md#use-special-characters-with-script)할 때 작은따옴표(`'`) 또는 큰따옴표(`"`)를 사용해야 합니다.

**Related topics**:

- [0이 아닌 종료 코드 무시](script.md#ignore-non-zero-exit-codes)할 수 있습니다.
- [`script`과 함께 색상 코드 사용](script.md#add-color-codes-to-script-output)하여 작업 로그를 더 쉽게 검토할 수 있습니다.
- [사용자 정의 축소 가능한 섹션 만들기](../jobs/job_logs.md#create-custom-collapsible-sections)로 작업 로그 출력을 단순화합니다.

---

### `secrets` {#secrets}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

`secrets`을 사용하여 [CI/CD 비밀](../secrets/_index.md)을 지정하여 다음을 수행합니다:

- 외부 비밀 공급자에서 검색합니다.
- 작업에서 [CI/CD 변수](../variables/_index.md)로 사용 가능하게 만듭니다(기본적으로 [`file` 유형](../variables/_index.md#use-file-type-cicd-variables)).

---

#### `secrets:vault` {#secretsvault}

{{< history >}}

- `generic` 엔진 옵션이 GitLab Runner 16.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)되었습니다.

{{< /history >}}

`secrets:vault`을 사용하여 [HashiCorp Vault](https://www.vaultproject.io/)에서 제공한 비밀을 지정합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `engine:name`: 비밀 엔진의 이름입니다. `kv-v2`(기본값), `kv-v1`, 또는 `generic` 중 하나일 수 있습니다.
- `engine:path`: 비밀 엔진의 경로입니다.
- `path`: 비밀로의 경로입니다.
- `field`: 비밀번호가 저장되는 필드의 이름입니다.

**`secrets:vault`의 예**:

모든 세부사항을 명시적으로 지정하고 [KV-V2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2) 비밀 엔진을 사용하려면:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault:  # Translates to secret: `ops/data/production/db`, field: `password`
        engine:
          name: kv-v2
          path: ops
        path: production/db
        field: password
```

이 구문을 단축할 수 있습니다. 단축 구문을 사용하면 `engine:name`과 `engine:path` 모두 `kv-v2`으로 기본 설정됩니다:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault: production/db/password  # Translates to secret: `kv-v2/data/production/db`, field: `password`
```

단축 구문에서 `@`으로 시작하는 접미사를 추가하여 사용자 지정 비밀 엔진 경로를 지정합니다:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault: production/db/password@ops  # Translates to secret: `ops/data/production/db`, field: `password`
```

---

#### `secrets:gcp_secret_manager` {#secretsgcp_secret_manager}

{{< history >}}

- GitLab 16.8 및 GitLab Runner 16.8에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/11739)되었습니다.

{{< /history >}}

`secrets:gcp_secret_manager`을 사용하여 [GCP Secret Manager](https://cloud.google.com/security/products/secret-manager)에서 제공한 비밀을 지정합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `name`: 비밀의 이름입니다.
- `version`: 비밀의 버전입니다.

**`secrets:gcp_secret_manager`의 예**:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      gcp_secret_manager:
        name: 'test'
        version: 2
```

**Related topics**:

- [GitLab CI/CD에서 GCP Secret Manager 비밀 사용](../secrets/gcp_secret_manager.md).

---

#### `secrets:azure_key_vault` {#secretsazure_key_vault}

{{< history >}}

- GitLab 16.3 및 GitLab Runner 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/271271)되었습니다.

{{< /history >}}

`secrets:azure_key_vault`을 사용하여 [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault/)에서 제공한 비밀을 지정합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `name`: 비밀의 이름입니다.
- `version`: 비밀의 버전입니다.

**`secrets:azure_key_vault`의 예**:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      azure_key_vault:
        name: 'test'
        version: 'test'
```

**Related topics**:

- [GitLab CI/CD에서 Azure Key Vault 비밀 사용](../secrets/azure_key_vault.md).

---

#### `secrets:file` {#secretsfile}

`secrets:file`을 사용하여 비밀을 [`file` 또는 `variable` 유형 CI/CD 변수](../variables/_index.md#use-file-type-cicd-variables)로 저장되도록 구성합니다.

기본적으로 비밀은 작업에 `file` 유형 CI/CD 변수로 전달됩니다. 비밀의 값은 파일에 저장되고 변수는 파일의 경로를 포함합니다.

소프트웨어가 `file` 유형 CI/CD 변수를 사용할 수 없으면 `file: false`을 설정하여 비밀 값을 변수에 직접 저장합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `true` (기본값) 또는 `false`.

**`secrets:file`의 예**:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@ops
      file: false
```

**Additional details**:

- `file` 키워드는 CI/CD 변수에 대한 설정이며 `vault` 섹션이 아닌 CI/CD 변수 이름 아래에 중첩되어야 합니다.

---

#### `secrets:token` {#secretstoken}

{{< history >}}

- GitLab 15.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/356986)되었으며 **Limit JSON Web Token (JWT) access** 설정으로 제어됩니다.
- GitLab 16.0에서 항상 사용 가능하게 만들어졌으며 [**Limit JSON Web Token (JWT) access** 설정이 제거](https://gitlab.com/gitlab-org/gitlab/-/issues/366798)되었습니다.

{{< /history >}}

`secrets:token`을 사용하여 토큰의 CI/CD 변수를 참조하여 외부 비밀 공급자로 인증할 때 사용할 토큰을 명시적으로 선택합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- ID 토큰의 이름

**`secrets:token`의 예**:

```yaml
job:
  id_tokens:
    AWS_TOKEN:
      aud: https://aws.example.com
    VAULT_TOKEN:
      aud: https://vault.example.com
  secrets:
    DB_PASSWORD:
      vault: gitlab/production/db
      token: $VAULT_TOKEN
```

**Additional details**:

- `token` 키워드가 설정되지 않았고 정의된 토큰이 하나뿐일 때 정의된 토큰이 자동으로 사용됩니다.
- 정의된 토큰이 두 개 이상이면 `token` 키워드를 설정하여 사용할 토큰을 지정해야 합니다. 사용할 토큰을 지정하지 않으면 작업이 실행될 때마다 어떤 토큰이 사용되는지 예측할 수 없습니다.

---

### `services` {#services}

`services`을 사용하여 스크립트가 성공적으로 실행되어야 하는 추가 Docker 이미지를 지정합니다. [`services` 이미지](../services/_index.md)는 [`image`](#image) 키워드에서 지정한 이미지에 연결됩니다.

작업 구성과 기본 구성은 함께 병합되지 않습니다. 파이프라인에 [`default:services`](#default)가 정의되어 있고 작업에도 `services`이 있으면 작업 구성이 우선적으로 적용되고 기본 구성은 사용되지 않습니다.

> [!warning]
> 서비스 간 네트워킹을 활성화하려면 `FF_NETWORK_PER_BUILD`을 `true`으로 설정합니다. 이 플래그가 없으면 서비스가 제대로 작동하지 않을 수 있습니다. 자세한 내용은 [기능 플래그](https://docs.gitlab.com/runner/configuration/feature-flags)를 참조하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**: 레지스트리 경로(필요한 경우)를 포함하여 다음 형식 중 하나로 된 서비스 이미지의 이름:

- `<image-name>`(`<image-name>`을 `latest` 태그로 사용하는 것과 동일)
- `<image-name>:<tag>`
- `<image-name>@<digest>`

CI/CD 변수가 [지원되지만](../variables/where_variables_can_be_used.md#gitlab-ciyml-file) `alias`는 아닙니다. `alias`를 동적으로 사용자 지정하려면 [CI/CD 입력](../inputs/_index.md)을 대신 사용합니다.

**`services`의 예**:

```yaml
default:
  image:
    name: ruby:2.6
    entrypoint: ["/bin/bash"]

  services:
    - name: my-postgres:11.7
      alias: db-postgres
      entrypoint: ["/usr/local/bin/db-postgres"]
      command: ["start"]

  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

이 예에서 GitLab은 작업을 위해 두 개의 컨테이너를 시작합니다:

- `script` 명령을 실행하는 Ruby 컨테이너입니다.
- PostgreSQL 컨테이너입니다. Ruby 컨테이너의 `script` 명령이 `db-postgres` 호스트명의 PostgreSQL 데이터베이스에 연결할 수 있습니다.

**Additional details**:

- `services`을 최상위 수준에서 사용하되 `default` 섹션에서는 사용하지 않는 것은 [더 이상 사용되지 않습니다](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script).

**Related topics**:

- [`services`에 대해 사용 가능한 설정](../services/_index.md#available-settings-for-services).
- [`.gitlab-ci.yml` 파일에서 `services`를 정의](../services/_index.md#define-services-in-the-gitlab-ciyml-file)합니다.
- [Docker 컨테이너에서 CI/CD 작업 실행](../docker/using_docker_images.md).
- [Docker를 사용하여 Docker 이미지 빌드](../docker/using_docker_build.md).

---

#### `services:name` {#servicesname}

서비스에 사용할 이미지의 전체 이름입니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**: 레지스트리 경로(필요한 경우)를 포함하여 다음 형식 중 하나로 된 서비스 이미지의 이름:

- `<image-name>`(`<image-name>`을 `latest` 태그로 사용하는 것과 동일)
- `<image-name>:<tag>`
- `<image-name>@<digest>`

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`services:name`의 예**:

```yaml
services:
  - name: postgres:11.7
  - name: registry.example.com/my-org/custom-service:latest
```

**Additional details**:

- [`alias`](#servicesalias)을 사용하여 동일한 서비스 이미지를 여러 개 사용하거나 서비스 이미지 이름이 긴 경우 고유한 이름 별칭을 정의합니다.
- `entrypoint`, `command`, 또는 `variables`과 같은 다른 서비스 옵션과 함께 사용할 때 `name` 키워드가 필요합니다.
- 자세한 내용은 [서비스에 액세스](../services/_index.md#accessing-the-services)를 참조하세요.

---

#### `services:alias` {#servicesalias}

{{< history >}}

- GitLab Runner 17.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/421131)되었습니다.

{{< /history >}}

작업의 컨테이너에서 서비스에 액세스할 수 있는 추가 별칭입니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**: 공백 또는 쉼표로 구분된 하나 이상의 별칭을 포함하는 문자열입니다.

**`services:alias`의 예**:

```yaml
services:
  - name: postgres:11.7
    alias: db,postgres,pg
  - name: mysql:latest
    alias: mysql-1
```

**Additional details**:

- 여러 별칭은 공백 또는 쉼표로 구분할 수 있습니다.
- 자세한 내용은 [서비스 액세스](../services/_index.md#accessing-the-services)와 [Kubernetes 실행기를 위한 서비스 컨테이너 이름으로 별칭 사용](../services/_index.md#using-aliases-as-service-container-names-for-the-kubernetes-executor)을 참조하세요.

---

#### `services:docker` {#servicesdocker}

{{< history >}}

- GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27919)되었습니다. GitLab Runner 16.7 이상이 필요합니다.
- `user` 입력 옵션이 GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137907)되었습니다.

{{< /history >}}

`services:docker`을 사용하여 러너의 Docker 실행기에 옵션을 전달합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

Docker 실행기에 대한 옵션의 해시(다음 포함 가능):

- `platform`: 끌어올 이미지의 아키텍처를 선택합니다. 지정하지 않으면 기본값은 호스트 러너와 동일한 플랫폼입니다.
- `user`: 컨테이너를 실행할 때 사용할 사용자 이름 또는 UID를 지정합니다.

**`services:docker`의 예**:

```yaml
arm-sql-job:
  script: echo "Run sql tests in service container"
  image: ruby:2.6
  services:
    - name: super/sql:experimental
      docker:
        platform: arm64/v8
        user: dave
```

**Additional details**:

- `services:docker:platform`은 [`docker pull --platform` 옵션](https://docs.docker.com/reference/cli/docker/image/pull/#options)에 매핑됩니다.
- `services:docker:user`은 [`docker run --user` 옵션](https://docs.docker.com/reference/cli/docker/container/run/#options)에 매핑됩니다.

---

#### `services:kubernetes` {#serviceskubernetes}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38451)되었습니다. GitLab Runner 17.11 이상이 필요합니다.
- `user` 입력 옵션이 GitLab Runner 17.11에서 [도입](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5469)되었습니다.
- `user` 입력 옵션이 GitLab 18.0에서 [`uid:gid` 형식을 지원하도록 확장](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5540)되었습니다.

{{< /history >}}

`services:kubernetes`을 사용하여 러너 [Kubernetes 실행기](https://docs.gitlab.com/runner/executors/kubernetes/)에 옵션을 전달하세요.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

Kubernetes 실행기에 대한 옵션의 해시(다음 포함 가능):

- `user`: 컨테이너를 실행할 때 사용할 사용자 이름 또는 UID를 지정합니다. `UID:GID` 형식을 사용하여 GID를 설정할 수도 있습니다.

**UID만 사용하는 `services:kubernetes`의 예**:

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image: ruby:2.6
  services:
    - name: super/sql:experimental
      kubernetes:
        user: "1001"
```

**UID와 GID 모두를 사용하는 `services:kubernetes`의 예**:

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image: ruby:2.6
  services:
    - name: super/sql:experimental
      kubernetes:
        user: "1001:1001"
```

---

#### `services:entrypoint` {#servicesentrypoint}

컨테이너의 진입점으로 실행할 명령 또는 스크립트입니다.

Docker 컨테이너가 생성되면 `entrypoint`이 Docker `--entrypoint` 옵션으로 변환됩니다. 구문은 [Dockerfile `ENTRYPOINT` 지시문](https://docs.docker.com/reference/dockerfile/#entrypoint)과 유사하며 각 셀 토큰은 배열의 별도 문자열입니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**: 진입점 명령을 나타내는 문자열의 배열입니다.

**`services:entrypoint`의 예**:

```yaml
services:
  - name: my-postgres:11.7
    entrypoint: ["/usr/local/bin/db-postgres"]
```

---

#### `services:command` {#servicescommand}

컨테이너의 명령으로 사용해야 하는 명령 또는 스크립트입니다.

이미지 이름 뒤의 Docker에 전달된 인수로 변환됩니다. 구문은 [Dockerfile `CMD`](https://docs.docker.com/reference/dockerfile/#cmd) 지시문과 유사하며, 여기서 각 셸 토큰은 배열의 별도 문자열입니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**: 명령을 나타내는 문자열의 배열입니다.

**`services:command`의 예**:

```yaml
services:
  - name: super/sql:latest
    command: ["/usr/bin/super-sql", "run"]
```

---

#### `services:variables` {#servicesvariables}

서비스에만 전달되는 추가 환경 변수입니다. 서비스 변수는 서비스 컨테이너에만 전달되며 작업 컨테이너에서는 사용할 수 없습니다.

구문은 [작업 변수](../variables/_index.md)와 동일합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**: 환경 변수 이름 및 값의 해시입니다.

**`services:variables`의 예**:

```yaml
services:
  - name: postgres:11.7
    alias: db
    variables:
      POSTGRES_DB: "my_custom_db"
      POSTGRES_USER: "postgres"
      POSTGRES_PASSWORD: "example"
      PGDATA: "/var/lib/postgresql/data"
```

**Additional details**:

- 서비스 변수는 자기 자신을 참조할 수 없으며 변수 확장 또는 보간을 지원하지 않습니다.
- 작업 또는 파이프라인 수준에서 정의된 변수는 자동으로 서비스로 전달됩니다. 자세한 내용은 [서비스에 CI/CD 변수 전달](../services/_index.md#passing-cicd-variables-to-services)을 참조하세요.
- 서비스 변수는 정의된 특정 서비스에만 사용 가능합니다.

---

#### `services:pull_policy` {#servicespull_policy}

{{< history >}}

- GitLab 15.1에서 `ci_docker_image_pull_policy` [플래그](../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/21619)되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 15.2에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)되었습니다.
- GitLab 15.4에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)합니다. [기능 플래그 `ci_docker_image_pull_policy`](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)가 제거되었습니다.

{{< /history >}}

러너가 Docker 이미지를 가져오는 데 사용하는 끌어오기 정책. GitLab Runner 15.1 이상이 필요합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 단일 끌어오기 정책 또는 배열의 여러 끌어오기 정책. `always`, `if-not-present` 또는 `never`입니다.

**`services:pull_policy`의 예**:

```yaml
job1:
  script: echo "A single pull policy."
  services:
    - name: postgres:11.6
      pull_policy: if-not-present

job2:
  script: echo "Multiple pull policies."
  services:
    - name: postgres:11.6
      pull_policy: [always, if-not-present]
```

**Additional details**:

- 러너가 정의된 끌어오기 정책을 지원하지 않으면 작업이 `ERROR: Job failed (system failure): the configured PullPolicies ([always]) are not allowed by AllowedPullPolicies ([never])`과 유사한 오류로 실패합니다.

**Related topics**:

- [Docker 컨테이너에서 CI/CD 작업 실행](../docker/using_docker_images.md).
- [러너가 이미지를 끌어오는 방식 구성](https://docs.gitlab.com/runner/executors/docker/#configure-how-runners-pull-images).
- [여러 끌어오기 정책 설정](https://docs.gitlab.com/runner/executors/docker/#set-multiple-pull-policies).

---

### `stage` {#stage}

`stage`을 사용하여 작업이 실행되는 [스테이지](#stages)를 정의합니다. 동일한 `stage`의 작업은 병렬로 실행할 수 있습니다(**Additional details** 참조).

`stage`이 정의되지 않으면 작업은 기본적으로 `test` 스테이지를 사용합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 다음 중 하나일 수 있는 문자열:

- [기본 스테이지](#stages).
- 사용자 정의 스테이지입니다.

**`stage`의 예**:

```yaml
stages:
  - build
  - test
  - deploy

job1:
  stage: build
  script:
    - echo "This job compiles code."

job2:
  stage: test
  script:
    - echo "This job tests the compiled code. It runs when the build stage completes."

job3:
  script:
    - echo "This job also runs in the test stage."

job4:
  stage: deploy
  script:
    - echo "This job deploys the code. It runs when the test stage completes."
  environment: production
```

**Additional details**:

- 스테이지 이름은 255자 이하여야 합니다.
- 작업이 다른 러너에서 실행되면 병렬로 실행할 수 있습니다.
- 러너가 하나만 있으면 러너의 [`concurrent` 설정](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-global-section)이 `1`보다 크면 작업이 병렬로 실행할 수 있습니다.

---

#### `stage: .pre` {#stage-pre}

`.pre` 스테이지를 사용하여 작업이 파이프라인의 시작 부분에서 실행되도록 합니다. 기본적으로 `.pre`은 파이프라인의 첫 번째 스테이지입니다. 사용자 정의 스테이지는 `.pre` 후에 실행됩니다. `.pre`을 [`stages`](#stages)에서 정의할 필요는 없습니다.

파이프라인에 `.pre` 또는 `.post` 스테이지의 작업만 포함되어 있으면 실행되지 않습니다. 다른 스테이지에 최소한 하나의 다른 작업이 있어야 합니다.

**Keyword type**: 작업의 `stage` 키워드와만 함께 사용할 수 있습니다.

**`stage: .pre`의 예**:

```yaml
stages:
  - build
  - test

job1:
  stage: build
  script:
    - echo "This job runs in the build stage."

first-job:
  stage: .pre
  script:
    - echo "This job runs in the .pre stage, before all other stages."

job2:
  stage: test
  script:
    - echo "This job runs in the test stage."
```

**Additional details**:

- 파이프라인에 [`needs: []`](#needs)이 있는 작업과 `.pre` 스테이지의 작업이 있으면 모두 파이프라인이 생성되는 즉시 시작됩니다. `needs: []`이 있는 작업은 즉시 시작되어 모든 스테이지 구성을 무시합니다.
- [파이프라인 실행 정책](../../user/application_security/policies/pipeline_execution_policies.md)은 `.pipeline-policy-pre` 스테이지를 정의할 수 있으며, 이는 `.pre` 전에 실행됩니다.

---

#### `stage: .post` {#stage-post}

`.post` 스테이지를 사용하여 작업이 파이프라인의 끝 부분에서 실행되도록 합니다. 기본적으로 `.post`는 파이프라인의 마지막 스테이지입니다. 사용자 정의 스테이지는 `.post` 전에 실행됩니다. `.post`을 [`stages`](#stages)에서 정의할 필요는 없습니다.

파이프라인에 `.pre` 또는 `.post` 스테이지의 작업만 포함되어 있으면 실행되지 않습니다. 다른 스테이지에 최소한 하나의 다른 작업이 있어야 합니다.

**Keyword type**: 작업의 `stage` 키워드와만 함께 사용할 수 있습니다.

**`stage: .post`의 예**:

```yaml
stages:
  - build
  - test

job1:
  stage: build
  script:
    - echo "This job runs in the build stage."

last-job:
  stage: .post
  script:
    - echo "This job runs in the .post stage, after all other stages."

job2:
  stage: test
  script:
    - echo "This job runs in the test stage."
```

**Additional details**:

- [파이프라인 실행 정책](../../user/application_security/policies/pipeline_execution_policies.md)은 `.pipeline-policy-post` 스테이지를 정의할 수 있으며, 이는 `.post` 이후에 실행됩니다.

---

### `tags` {#tags}

`tags`을 사용하여 프로젝트에 사용 가능한 모든 러너 목록에서 특정 러너를 선택합니다.

러너를 등록할 때 러너 태그(예: `ruby`, `postgres`, 또는 `development`)를 지정할 수 있습니다. 작업을 선택하려면 러너는 작업에 나열된 모든 태그를 할당받아야 합니다.

작업 구성과 기본 구성은 함께 병합되지 않습니다. 파이프라인에 [`default:tags`](#default)가 정의되어 있고 작업에도 `tags`이 있으면 작업 구성이 우선적으로 적용되고 기본 구성은 사용되지 않습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 또는 [`default` 섹션](#default)에서만 사용할 수 있습니다.

**Supported values**:

- 대소문자를 구분하는 태그 이름의 배열입니다.
- CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`tags`의 예**:

```yaml
job:
  tags:
    - ruby
    - postgres
```

이 예에서는 `ruby` 및 `postgres` 태그가 모두 있는 러너만 작업을 실행할 수 있습니다.

**Additional details**:

- 태그 수는 `50`보다 작아야 합니다.

**Related topics**:

- [태그를 사용하여 러너가 실행할 수 있는 작업 제어](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)
- [각 병렬 매트릭스 작업에 대해 다른 러너 태그 선택](../jobs/job_control.md#select-different-runner-tags-for-each-parallel-matrix-job)
- 호스팅된 러너를 위한 러너 태그:
  - [Linux의 호스팅된 러너](../runners/hosted_runners/linux.md)
  - [GPU 지원 호스팅 러너](../runners/hosted_runners/gpu_enabled.md)
  - [macOS의 호스팅된 러너](../runners/hosted_runners/macos.md)
  - [Windows의 호스팅된 러너](../runners/hosted_runners/windows.md)

---

### `timeout` {#timeout}

`timeout`을 사용하여 특정 작업에 대한 시간 초과를 구성합니다. 작업이 시간 초과보다 오래 실행되면 작업이 실패합니다.

작업 수준 시간 초과는 [프로젝트 수준 시간 초과](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)보다 길 수 있지만 [러너의 시간 초과](../runners/configure_runners.md#set-the-maximum-job-timeout)보다 길 수 없습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 자연 언어로 작성된 기간. 예를 들어 다음은 모두 동등합니다:

- `3600 seconds`
- `60 minutes`
- `one hour`

**`timeout`의 예**:

```yaml
build:
  script: build.sh
  timeout: 3 hours 30 minutes

test:
  script: rspec
  timeout: 3h 30m
```

**Additional details**:

- `timeout` 키워드는 `default` 구성에서 지원되지 않습니다. 대신 개별 작업 구성에 `timeout`을 정의합니다. 자세한 내용은 [이슈 213634](https://gitlab.com/gitlab-org/gitlab/-/issues/213634)를 참조하세요.

---

### `trigger` {#trigger}

{{< history >}}

- `environment`에 대한 지원이 GitLab 16.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/369061)되었습니다.

{{< /history >}}

`trigger`을 사용하여 다음 중 하나인 [다운스트림 파이프라인](../pipelines/downstream_pipelines.md)을 시작하는 "트리거 작업"이라는 작업을 선언합니다:

- [다중 프로젝트 파이프라인](../pipelines/downstream_pipelines.md#multi-project-pipelines).
- [자식 파이프라인](../pipelines/downstream_pipelines.md#parent-child-pipelines).

트리거 작업은 제한된 GitLab CI/CD 구성 키워드 집합만 사용할 수 있습니다. 트리거 작업에서 사용 가능한 키워드는:

- [`allow_failure`](#allow_failure).
- [`extends`](#extends).
- [`needs`](#needs)이지만 [`needs:project`](#needsproject)는 아닙니다.
- [`only` 및 `except`](deprecated_keywords.md#only--except).
- [`parallel`](#parallel).
- [`rules`](#rules).
- [`stage`](#stage).
- [`trigger`](#trigger).
- [`variables`](#variables).
- [`when`](#when)(`on_success`, `on_failure`, `always`, 또는 `manual`의 값만 포함).
- [`resource_group`](#resource_group).
- [`environment`](#environment).

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 다중 프로젝트 파이프라인의 경우 다운스트림 프로젝트의 경로입니다. CI/CD 변수는 GitLab 15.3 이상에서 [지원되지만](../variables/where_variables_can_be_used.md#gitlab-ciyml-file) [작업 전용 변수](../variables/predefined_variables.md#variable-availability)는 아닙니다. 또는 [`trigger:project`](#triggerproject)를 사용합니다.
- 자식 파이프라인의 경우 [`trigger:include`](#triggerinclude)를 사용합니다.

**`trigger`의 예**:

```yaml
trigger-multi-project-pipeline:
  trigger: my-group/my-project
```

**Additional details**:

- [`when:manual`](#when)을 `trigger`과 동일한 작업에서 사용할 수 있지만 API를 사용하여 `when:manual` 트리거 작업을 시작할 수 없습니다. 자세한 내용은 [이슈 284086](https://gitlab.com/gitlab-org/gitlab/-/issues/284086)을 참조하세요.
- 수동 트리거 작업을 실행하기 전에 [수동으로 CI/CD 변수를 지정](../jobs/job_control.md#specify-variables-when-running-manual-jobs)할 수 없습니다.
- 최상위 수준의 `variables` 섹션(전역) 또는 트리거 작업에서 정의된 [CI/CD 변수](#variables)는 [트리거 변수](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline)로 다운스트림 파이프라인으로 전달됩니다.
- [파이프라인 변수](../variables/_index.md#cicd-variable-precedence)는 기본적으로 다운스트림 파이프라인으로 전달되지 않습니다. [`trigger:forward`](#triggerforward)을 사용하여 이러한 변수를 다운스트림 파이프라인으로 전달합니다.
- [작업 전용 변수](../variables/predefined_variables.md#variable-availability)는 트리거 작업에서 사용할 수 없습니다.
- [러너의 `config.toml`에서 정의된](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section) 환경 변수는 트리거 작업에서 사용할 수 없으며 다운스트림 파이프라인으로 전달되지 않습니다.
- 트리거 작업에서 [`needs:pipeline:job`](#needspipelinejob)을 사용할 수 없습니다.

**Related topics**:

- [다중 프로젝트 파이프라인 구성 예](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file).
- 특정 브랜치, 태그 또는 커밋에 대한 파이프라인을 실행하려면 [트리거 토큰](../triggers/_index.md)을 사용하여 [파이프라인 트리거 API](../../api/pipeline_triggers.md)로 인증할 수 있습니다. 트리거 토큰은 `trigger` 키워드와 다릅니다.

---

#### `trigger:inputs` {#triggerinputs}

{{< history >}}

- GitLab 17.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/519963)되었습니다.

{{< /history >}}

`trigger:inputs`을 사용하여 다운스트림 파이프라인 구성이 [`spec:inputs`](#specinputs)을 사용할 때 다중 프로젝트 파이프라인에 대한 [입력](../inputs/_index.md)을 설정합니다.

**`trigger:inputs`의 예**:

```yaml
trigger:
  - project: 'my-group/my-project'
    inputs:
      website: "My website"
```

---

#### `trigger:include` {#triggerinclude}

`trigger:include`을 사용하여 [자식 파이프라인](../pipelines/downstream_pipelines.md#parent-child-pipelines)을 시작하는 "트리거 작업"이라는 작업을 선언합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 자식 파이프라인 구성 파일의 경로입니다.

**`trigger:include`의 예**:

```yaml
trigger-child-pipeline:
  trigger:
    include: path/to/child-pipeline.gitlab-ci.yml
```

**Additional details**:

사용:

- `trigger:include:artifact`을 사용하여 [동적 자식 파이프라인](../pipelines/downstream_pipelines.md#dynamic-child-pipelines)을 트리거합니다.
- `trigger:include:inputs`을 사용하여 다운스트림 파이프라인 구성이 [`spec:inputs`](#specinputs)을 사용할 때 [입력](../inputs/_index.md)을 설정합니다.
- 다음 경우일 때 자식 파이프라인 구성 파일의 경로에 `trigger:include:local`을 사용합니다:
  - [여러 자식 파이프라인 구성 파일 결합](../pipelines/downstream_pipelines.md#combine-multiple-child-pipeline-configuration-files).
  - `trigger:include:inputs`과 결합하여 자식 파이프라인에 입력값을 전달합니다. 예를 들어:

    ```yaml
    staging-job:
      trigger:
        include:
          - local: path/to/child-pipeline.yml
            inputs:
              environment: staging
    ```

- `trigger:include:project`을 사용하여 [다른 프로젝트의 구성 파일로 자식 파이프라인을 트리거합니다](../pipelines/downstream_pipelines.md#use-a-child-pipeline-configuration-file-in-a-different-project). 파일에 추가 [`include`](#include) 항목이 있으면 GitLab은 파일을 호스팅하는 프로젝트가 아니라 파이프라인을 실행하는 프로젝트에서 파일을 찾습니다.
- `trigger:include:template`을 사용하여 CI/CD 템플릿으로 자식 파이프라인을 트리거합니다.

**Related topics**:

- [자식 파이프라인 구성 예제](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file).

---

#### `trigger:include:inputs` {#triggerincludeinputs}

{{< history >}}

- GitLab 17.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/519963)되었습니다.

{{< /history >}}

`trigger:include:inputs`을 사용하여 다운스트림 파이프라인 구성이 [`spec:inputs`](#specinputs)를 사용할 때 자식 파이프라인의 [입력값](../inputs/_index.md)을 설정합니다.

**`trigger:inputs`의 예**:

```yaml
trigger-job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
        inputs:
          website: "My website"
```

---

#### `trigger:project` {#triggerproject}

`trigger:project`을 사용하여 작업이 [다중 프로젝트 파이프라인](../pipelines/downstream_pipelines.md#multi-project-pipelines)을 시작하는 "트리거 작업"임을 선언합니다.

기본적으로 다중 프로젝트 파이프라인은 기본 브랜치에 대해 트리거됩니다. `trigger:branch`을 사용하여 다른 브랜치를 지정합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 다운스트림 프로젝트의 경로입니다. CI/CD 변수는 GitLab 15.3 이상에서 [지원되지만](../variables/where_variables_can_be_used.md#gitlab-ciyml-file) [작업 전용 변수](../variables/predefined_variables.md#variable-availability)는 아닙니다.

**`trigger:project`의 예**:

```yaml
trigger-multi-project-pipeline:
  trigger:
    project: my-group/my-project
```

**다른 브랜치의 `trigger:project` 예제**:

```yaml
trigger-multi-project-pipeline:
  trigger:
    project: my-group/my-project
    branch: development
```

**Related topics**:

- [다중 프로젝트 파이프라인 구성 예](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file).
- 특정 브랜치, 태그 또는 커밋에 대해 파이프라인을 실행하려면 [트리거 토큰](../triggers/_index.md)을 사용하여 [파이프라인 트리거 API](../../api/pipeline_triggers.md)로 인증할 수 있습니다. 트리거 토큰은 `trigger` 키워드와 다릅니다.

---

#### `trigger:strategy` {#triggerstrategy}

{{< history >}}

- `strategy:mirror` 옵션은 GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/431882)되었습니다.

{{< /history >}}

`trigger:strategy`을 사용하여 `trigger` 작업이 다운스트림 파이프라인이 완료될 때까지 대기하도록 강제한 후 **성공**으로 표시합니다.

이는 기본 동작과 다르며, 기본 동작은 `trigger` 작업이 다운스트림 파이프라인이 생성되는 즉시 **성공**으로 표시되는 것입니다.

이 설정은 파이프라인 실행을 병렬이 아닌 선형으로 만듭니다.

**Supported values**:

- `mirror`: 다운스트림 파이프라인의 상태를 정확히 미러링합니다.
- `depend`: 권장하지 않으며, 대신 `mirror`을(를) 사용하세요. 트리거 작업 상태는 다운스트림 파이프라인 상태에 따라 **실패**, **성공** 또는 **실행 중**을(를) 표시합니다. 자세한 내용을 확인하세요.

**`trigger:strategy`의 예**:

```yaml
trigger_job:
  trigger:
    include: path/to/child-pipeline.yml
    strategy: mirror
```

이 예제에서는 후속 스테이지의 작업이 트리거된 파이프라인이 성공적으로 완료될 때까지 기다린 후 시작합니다.

**Additional details**:

- 다운스트림 파이프라인의 [선택 사항 수동 작업](../jobs/job_control.md#types-of-manual-jobs)은 다운스트림 파이프라인 또는 업스트림 트리거 작업의 상태에 영향을 주지 않습니다. 다운스트림 파이프라인은 선택 사항 수동 작업을 실행하지 않고도 성공적으로 완료될 수 있습니다.
- 기본적으로 나중 스테이지의 작업은 트리거 작업이 완료될 때까지 시작되지 않습니다.
- 다운스트림 파이프라인의 [차단 수동 작업](../jobs/job_control.md#types-of-manual-jobs)은 트리거 작업이 성공 또는 실패로 표시되기 전에 실행되어야 합니다.
- `strategy:depend`을(를) 사용할 때(더 이상 권장하지 않으며, 대신 `strategy:mirror`을(를) 사용하세요):
  - 트리거 작업은 다운스트림 파이프라인 상태가 수동 작업으로 인해 **수동 실행 대기 중**({{< icon name="status_manual" >}})인 경우 **실행 중**({{< icon name="status_running" >}})을 표시합니다.
  - 다운스트림 파이프라인에 실패한 작업이 있지만 작업이 [`allow_failure: true`](#allow_failure)를 사용하면 다운스트림 파이프라인이 성공한 것으로 간주되고 트리거 작업은 **성공**을 표시합니다.

---

#### `trigger:forward` {#triggerforward}

{{< history >}}

- GitLab 15.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/355572)합니다. [기능 플래그 `ci_trigger_forward_variables`](https://gitlab.com/gitlab-org/gitlab/-/issues/355572)가 제거되었습니다.

{{< /history >}}

`trigger:forward`을 사용하여 다운스트림 파이프라인으로 전달할 항목을 지정합니다. [상위-하위 파이프라인](../pipelines/downstream_pipelines.md#parent-child-pipelines) 및 [다중 프로젝트 파이프라인](../pipelines/downstream_pipelines.md#multi-project-pipelines) 모두로 전달할 항목을 제어할 수 있습니다.

전달된 변수는 기본적으로 중첩된 다운스트림 파이프라인에서 다시 전달되지 않습니다. 단, 중첩된 다운스트림 트리거 작업도 `trigger:forward`을(를) 사용하는 경우는 제외입니다.

**Supported values**:

- `yaml_variables`: `true`(기본값) 또는 `false`. `true`일 때 트리거 작업에 정의된 변수가 다운스트림 파이프라인으로 전달됩니다.
- `pipeline_variables`: `true` 또는 `false`(기본값). `true`일 때 [파이프라인 변수](../variables/_index.md#cicd-variable-precedence)가 다운스트림 파이프라인으로 전달됩니다.

**`trigger:forward`의 예**:

[이 파이프라인을 수동으로 실행](../pipelines/_index.md#run-a-pipeline-manually)하고 CI/CD 변수 `MYVAR = my value`:

```yaml
variables: # default variables for each job
  VAR: value

---

# Default behavior:
---

# - VAR is passed to the child
---

# - MYVAR is not passed to the child
child1:
  trigger:
    include: .child-pipeline.yml

---

# Forward pipeline variables:
---

# - VAR is passed to the child
---

# - MYVAR is passed to the child
child2:
  trigger:
    include: .child-pipeline.yml
    forward:
      pipeline_variables: true

---

# Do not forward YAML variables:
---

# - VAR is not passed to the child
---

# - MYVAR is not passed to the child
child3:
  trigger:
    include: .child-pipeline.yml
    forward:
      yaml_variables: false
```

**Additional details**:

- `trigger:forward`로 다운스트림 파이프라인으로 전달된 CI/CD 변수는 [파이프라인 변수](../variables/_index.md#cicd-variable-precedence)이며 높은 우선순위를 가집니다. 동일한 이름의 변수가 다운스트림 파이프라인에 정의되어 있으면 해당 변수는 일반적으로 전달된 변수에 의해 덮어씌워집니다.

---

### `when` {#when}

`when`을 사용하여 작업이 실행되는 조건을 구성합니다. 작업에 정의되지 않으면 기본값은 `when: on_success`입니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로 사용할 수 있습니다. `when: always` 및 `when: never`도 [`workflow:rules`](#workflow)에서 사용할 수 있습니다.

**Supported values**:

- `on_success`(기본값): 이전 스테이지의 작업이 실패하지 않을 때만 작업을 실행합니다.
- `on_failure`: 이전 스테이지의 최소 하나의 작업이 실패할 때만 작업을 실행합니다.
- `never`: 이전 스테이지의 작업 상태와 관계없이 작업을 실행하지 않습니다. [`rules`](#ruleswhen) 섹션 또는 [`workflow: rules`](#workflowrules)에서만 사용할 수 있습니다.
- `always`: 이전 스테이지의 작업 상태와 관계없이 작업을 실행합니다.
- `manual`: 작업을 [수동 작업](../jobs/job_control.md#create-a-job-that-must-be-run-manually)으로 파이프라인에 추가합니다.
- `delayed`: 작업을 [지연된 작업](../jobs/job_control.md#run-a-job-after-a-delay)으로 파이프라인에 추가합니다.

**`when`의 예**:

```yaml
stages:
  - build
  - cleanup_build
  - test
  - deploy
  - cleanup

build_job:
  stage: build
  script:
    - make build

cleanup_build_job:
  stage: cleanup_build
  script:
    - cleanup build when failed
  when: on_failure

test_job:
  stage: test
  script:
    - make test

deploy_job:
  stage: deploy
  script:
    - make deploy
  when: manual
  environment: production

cleanup_job:
  stage: cleanup
  script:
    - cleanup after jobs
  when: always
```

이 예제에서 스크립트는:

1. `build_job`이 실패한 경우에만 `cleanup_build_job`을(를) 실행합니다.
1. 성공 또는 실패 여부에 관계없이 파이프라인의 마지막 단계로 항상 `cleanup_job`을(를) 실행합니다.
1. GitLab UI에서 수동으로 실행할 때 `deploy_job`을(를) 실행합니다.

**Additional details**:

- `on_success`과 `on_failure`의 상태를 평가할 때:
  - [`allow_failure: true`](#allow_failure)이 있는 이전 스테이지의 작업은 실패했더라도 성공으로 간주됩니다.
  - 이전 스테이지에서 건너뛴 작업(예: [시작되지 않은 수동 작업](../jobs/job_control.md#create-a-job-that-must-be-run-manually))은 성공으로 간주됩니다.
- [`allow_failure`](#allow_failure)의 기본값은 `true` with `when: manual`입니다. 기본값이 `false` with [`rules:when: manual`](#ruleswhen)로 변경됩니다.

**Related topics**:

- `when`을 [`rules`](#rules)과 함께 사용하여 더 동적인 작업 제어를 할 수 있습니다.
- `when`을 [`workflow`](#workflow)과 함께 사용하여 파이프라인이 시작될 수 있는 시점을 제어합니다.

---

#### `manual_confirmation` {#manual_confirmation}

{{< history >}}

- GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/18906)되었습니다.
- 환경 중지 작업 지원이 GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/479318)되었습니다.

{{< /history >}}

`manual_confirmation`을 [`when: manual`](#when)과 함께 사용하여 수동 작업의 사용자 지정 확인 메시지를 정의합니다. `when: manual`로 정의된 수동 작업이 없으면 이 키워드는 효과가 없습니다.

수동 확인은 [`environment:action: stop`](#environmentaction)을(를) 사용하는 환경 중지 작업을 포함한 모든 수동 작업에서 작동합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- 확인 메시지가 포함된 문자열입니다.

**`manual_confirmation`의 예**:

```yaml
delete_job:
  stage: post-deployment
  script:
    - make delete
  when: manual
  manual_confirmation: 'Are you sure you want to delete this environment?'

stop_production:
  stage: cleanup
  script:
    - echo "Stopping production environment"
  environment:
    name: production
    action: stop
  when: manual
  manual_confirmation: "Are you sure you want to stop the production environment?"
```

---

### `start_in` {#start_in}

`start_in`을 사용하여 작업이 생성된 후 지정된 기간 동안 작업 실행을 지연합니다. 작업에 대해 `when: delayed`을(를) 구성해야 합니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Possible inputs**: 초, 분 또는 시간 단위의 시간 기간입니다. 1주일 이하여야 합니다. 유효한 값의 예:

- `'5'`(5초)
- `'10 seconds'`
- `'30 minutes'`
- `'1 hour'`
- `'1 day'`

**`start_in`의 예**:

```yaml
deploy_production:
  stage: deploy
  script:
    - echo "Deploying to production"
  when: delayed
  start_in: 30 minutes
```

이 예제에서 `deploy_production` 작업은 이전 스테이지가 완료된 후 30분 후에 시작됩니다.

**Additional details**:

- 타이머는 이전 작업이 완료될 때가 아니라 작업의 스테이지가 시작될 때 시작됩니다.
- 지연된 작업을 수동으로 즉시 시작하려면 파이프라인 보기에서 **Play**({{< icon name="play" >}})을 선택합니다.
- 최소 지연 기간은 1초이고 최대 지연은 1주일입니다.
- `start_in`은 [`when`](#when)이 `delayed`로 설정되어 있을 때만 작동합니다. `when`에 다른 값을 사용하면 구성이 유효하지 않습니다. 작업이 `rules`을(를) 사용하면 `start_in` 및 `when`을(를) `rules`에 정의해야 하며 작업 수준에서는 안 됩니다. 그렇지 않으면 유효성 검사 오류가 발생합니다: `config key may not be used with 'rules': start_in`.
- `start_in`은 `workflow:rules`에서 지원되지 않지만 구문 위반을 발생하지 않습니다.

**Related topics**:

- [지연 후 작업 실행](../jobs/job_control.md#run-a-job-after-a-delay)

---

## `variables` {#variables}

`variables`을 사용하여 [CI/CD 변수](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)를 정의합니다.

변수는 [CI/CD 작업에서 정의](#job-variables)되거나 모든 작업에 대해 [기본 CI/CD 변수](#default-variables)를 정의하는 최상위(전역) 키워드로 정의될 수 있습니다.

**Additional details**:

- 모든 YAML 정의 변수도 연결된 [Docker 서비스 컨테이너](../services/_index.md)로 설정됩니다.
- YAML 정의 변수는 민감하지 않은 프로젝트 구성용입니다. 민감한 정보를 [보호된 변수](../variables/_index.md#protect-a-cicd-variable) 또는 [CI/CD 시크릿](../secrets/_index.md)에 저장합니다.
- [수동 파이프라인 변수](../variables/_index.md#use-pipeline-variables) 및 [예약된 파이프라인 변수](../pipelines/schedules.md#create-a-pipeline-schedule)는 기본적으로 다운스트림 파이프라인으로 전달되지 않습니다. [`trigger:forward`](#triggerforward)을 사용하여 이러한 변수를 다운스트림 파이프라인으로 전달합니다.

**Related topics**:

- [미리 정의된 변수](../variables/predefined_variables.md)는 러너가 자동으로 생성하고 작업에서 사용 가능하게 하는 변수입니다.
- [변수를 사용하여 러너 동작을 구성](../runners/configure_runners.md#configure-runner-behavior-with-variables)할 수 있습니다.

---

### 작업 `variables` {#job-variables}

작업의 `script`, `before_script` 또는 `after_script` 섹션 및 일부 [작업 키워드](#job-keywords)의 명령에서 작업 변수를 사용할 수 있습니다. 각 작업 키워드의 **Supported values** 섹션을 확인하여 변수를 지원하는지 확인합니다.

[전역 키워드](#global-keywords)(예: [`include`](includes.md#use-variables-with-include))의 값으로 작업 변수를 사용할 수 없습니다.

**Supported values**: 변수 이름 및 값 쌍:

- 이름은 숫자, 문자 및 밑줄(`_`)만 사용할 수 있습니다. 일부 셸에서는 첫 문자가 문자여야 합니다.
- 값은 문자열이어야 합니다.

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**작업 `variables`의 예제**:

```yaml
review_job:
  variables:
    DEPLOY_SITE: "https://dev.example.com/"
    REVIEW_PATH: "/review"
  script:
    - deploy-review-script --url $DEPLOY_SITE --path $REVIEW_PATH
```

이 예에서:

- `review_job`은 `DEPLOY_SITE` 및 `REVIEW_PATH` 작업 변수가 정의되어 있습니다. 두 작업 변수 모두 `script` 섹션에서 사용할 수 있습니다.

---

### 기본 `variables` {#default-variables}

최상위 `variables` 섹션에 정의된 변수는 모든 작업의 기본 변수로 작동합니다.

각 기본 변수는 동일한 이름의 변수가 이미 정의된 작업을 제외한 파이프라인의 모든 작업에서 사용 가능하게 됩니다. 작업에 정의된 변수가 [우선순위를 가지므로](../variables/_index.md#cicd-variable-precedence) 동일한 이름의 기본 변수 값은 작업에서 사용할 수 없습니다.

작업 변수처럼 [`include`](includes.md#use-variables-with-include)와 같은 다른 전역 키워드의 값으로 기본 변수를 사용할 수 없습니다.

**Supported values**: 변수 이름 및 값 쌍:

- 이름은 숫자, 문자 및 밑줄(`_`)만 사용할 수 있습니다. 일부 셸에서는 첫 문자가 문자여야 합니다.
- 값은 문자열이어야 합니다.

CI/CD 변수 [지원됨](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**`variables`의 예**:

```yaml
variables:
  DEPLOY_SITE: "https://example.com/"

deploy_job:
  stage: deploy
  script:
    - deploy-script --url $DEPLOY_SITE --path "/"
  environment: production

deploy_review_job:
  stage: deploy
  variables:
    DEPLOY_SITE: "https://dev.example.com/"
    REVIEW_PATH: "/review"
  script:
    - deploy-review-script --url $DEPLOY_SITE --path $REVIEW_PATH
  environment: production
```

이 예에서:

- `deploy_job`은 정의된 변수가 없습니다. 기본 `DEPLOY_SITE` 변수가 작업으로 복사되고 `script` 섹션에서 사용할 수 있습니다.
- `deploy_review_job`은 이미 `DEPLOY_SITE` 변수가 정의되어 있으므로 기본 `DEPLOY_SITE`이 작업으로 복사되지 않습니다. 작업에는 정의된 `REVIEW_PATH` 작업 변수도 있습니다. 두 작업 변수 모두 `script` 섹션에서 사용할 수 있습니다.

---

#### `variables:description` {#variablesdescription}

`description` 키워드를 사용하여 기본 변수에 대한 설명을 정의합니다. 설명은 [파이프라인을 수동으로 실행할 때 미리 채워진 변수 이름과 함께 표시](../pipelines/_index.md#prefill-variables-in-manual-pipelines)됩니다.

**Keyword type**: 이 키워드는 기본 `variables`에서만 사용할 수 있으며 작업 `variables`에서는 사용할 수 없습니다.

**Supported values**:

- 문자열입니다. Markdown을 사용할 수 있습니다.

**`variables:description`의 예**:

```yaml
variables:
  DEPLOY_NOTE:
    description: "The deployment note. Explain the reason for this deployment."
```

**Additional details**:

- `value` 없이 사용할 때 변수는 수동으로 트리거되지 않은 파이프라인에 존재하며 기본값은 빈 문자열(`''`)입니다.

---

#### `variables:value` {#variablesvalue}

`value` 키워드를 사용하여 파이프라인 수준(기본) 변수의 값을 정의합니다. [`variables: description`](#variablesdescription)과 함께 사용할 때 변수 값은 [파이프라인을 수동으로 실행할 때 미리 채워집니다](../pipelines/_index.md#prefill-variables-in-manual-pipelines).

**Keyword type**: 이 키워드는 기본 `variables`에서만 사용할 수 있으며 작업 `variables`에서는 사용할 수 없습니다.

**Supported values**:

- 문자열입니다.

**`variables:value`의 예**:

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"
    description: "The deployment target. Change this variable to 'canary' or 'production' if needed."
```

**Additional details**:

- [`variables: description`](#variablesdescription) 없이 사용할 때 동작은 [`variables`](#variables)와 동일합니다.

---

#### `variables:options` {#variablesoptions}

{{< history >}}

- [GitLab 15.7에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105502)

{{< /history >}}

`variables:options`을 사용하여 [파이프라인을 수동으로 실행할 때 UI에서 선택 가능한](../pipelines/_index.md#configure-a-list-of-selectable-prefilled-variable-values) 값의 배열을 정의합니다.

`variables: value`과 함께 사용해야 하며 `value`에 정의된 문자열:

- `options` 배열의 문자열 중 하나여야 합니다.
- 기본 선택입니다.

[`description`](#variablesdescription)이 없으면 이 키워드는 효과가 없습니다.

**Keyword type**: 이 키워드는 기본 `variables`에서만 사용할 수 있으며 작업 `variables`에서는 사용할 수 없습니다.

**Supported values**:

- 문자열 배열입니다.

**`variables:options`의 예**:

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"
    options:
      - "production"
      - "staging"
      - "canary"
    description: "The deployment target. Set to 'staging' by default."
```

---

### `variables:expand` {#variablesexpand}

{{< history >}}

- GitLab 15.6에서 `ci_raw_variables_in_yaml_config`라는 [플래그](../../administration/feature_flags/_index.md)와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/353991)되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 15.6에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/375034)되었습니다.
- GitLab 15.7에서 [GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/375034)되었습니다.
- GitLab 15.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/375034)합니다. 기능 플래그 `ci_raw_variables_in_yaml_config`이 제거되었습니다.

{{< /history >}}

`expand` 키워드를 사용하여 변수를 확장 가능하거나 확장 불가능하도록 구성합니다.

**Keyword type**: 이 키워드는 기본 및 작업 `variables` 모두에서 사용할 수 있습니다.

**Supported values**:

- `true`(기본값): 변수는 확장 가능합니다.
- `false`: 변수는 확장 불가능합니다.

**`variables:expand`의 예**:

```yaml
variables:
  VAR1: value1
  VAR2: value2 $VAR1
  VAR3:
    value: value3 $VAR1
    expand: false
```

- `VAR2`의 결과는 `value2 value1`입니다.
- `VAR3`의 결과는 `value3 $VAR1`입니다.

**Additional details**:

- `expand` 키워드는 기본 및 작업 `variables` 키워드하고만 사용할 수 있습니다. [`rules:variables`](#rulesvariables) 또는 [`workflow:rules:variables`](#workflowrulesvariables)과 함께는 사용할 수 없습니다.

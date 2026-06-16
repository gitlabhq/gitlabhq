---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 구성 요소
description: 파이프라인을 위한 재사용 가능하고 버전이 지정된 CI/CD 구성 요소입니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.0에서 [실험적 기능](../../policy/development_stages_support.md#experiment) 으로 도입되었으며, [플래그](../../administration/feature_flags/_index.md) 이름은 `ci_namespace_catalog_experimental`입니다. 기본적으로 비활성화됨.
- [GitLab.com 및 GitLab Self-Managed에서 활성화됨](https://gitlab.com/groups/gitlab-org/-/epics/9897) GitLab 16.2입니다.
- [기능 플래그 `ci_namespace_catalog_experimental` 제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/394772) GitLab 16.3입니다.
- [베타](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/130824) 로 [이동됨](../../policy/development_stages_support.md#beta) GitLab 16.6입니다.
- [일반 공급 개시](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062) GitLab 17.0입니다.

{{< /history >}}

CI/CD 구성 요소는 재사용 가능한 단일 파이프라인 구성 단위입니다. 구성 요소를 사용하여 더 큰 파이프라인의 작은 부분을 만들거나 완전한 파이프라인 구성을 구성할 수 있습니다.

더 동적인 동작을 위해 [입력 매개 변수](../inputs/_index.md)로 구성 요소를 구성할 수 있습니다.

CI/CD 구성 요소는 [`include` 키워드로 추가된 다른 종류의 구성](../yaml/includes.md)과 유사하지만 몇 가지 장점이 있습니다:

- 구성 요소는 [CI/CD 카탈로그](#cicd-catalog)에 나열될 수 있습니다.
- 구성 요소를 릴리스하고 특정 버전으로 사용할 수 있습니다.
- 여러 구성 요소를 같은 프로젝트에서 정의하고 함께 버전을 지정할 수 있습니다.

자신의 구성 요소를 만드는 대신, [CI/CD 카탈로그](#cicd-catalog)에서 필요한 기능을 갖춘 게시된 구성 요소를 검색할 수 있습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 소개 및 실습 예제는 [재사용 가능한 CI/CD 구성 요소로 효율적인 DevSecOps 워크플로우](https://www.youtube.com/watch?v=-yvfSFKAgbA)를 참조하세요.
<!-- Video published on 2024-01-22. DRI: Developer Relations, <https://gitlab.com/groups/gitlab-com/marketing/developer-relations/-/epics/399> -->

일반적인 질문 및 추가 지원은 [: GitLab CI/CD 카탈로그](https://about.gitlab.com/blog/faq-gitlab-ci-cd-catalog/) 블로그 게시물을 참조하세요.

## 구성 요소 프로젝트 {#component-project}

{{< history >}}

- 프로젝트당 최대 구성 요소 수가 [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/436565) GitLab 16.9에서 10에서 30으로 변경되었습니다.
- 프로젝트당 최대 구성 요소 수가 [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/569158) GitLab 18.5에서 30에서 100으로 변경되었습니다.

{{< /history >}}

구성 요소 프로젝트는 하나 이상의 구성 요소를 호스팅하는 리포지토리가 있는 GitLab 프로젝트입니다. 프로젝트의 모든 구성 요소는 함께 버전이 지정되며, 프로젝트당 최대 30개의 구성 요소가 있습니다.

구성 요소가 다른 구성 요소와 다른 버전 관리가 필요한 경우, 구성 요소를 전용 구성 요소 프로젝트로 이동해야 합니다.

### 구성 요소 프로젝트 만들기 {#create-a-component-project}

구성 요소 프로젝트를 만들려면 다음을 수행해야 합니다:

1. [새 프로젝트를 만들고](../../user/project/_index.md#create-a-blank-project) `README.md` 파일을 포함합니다:
   - 설명이 구성 요소에 대한 명확한 소개를 제공하는지 확인합니다.
   - 선택 사항입니다. 프로젝트를 만든 후 [프로젝트 아바타를 추가](../../user/project/working_with_projects.md#add-a-project-avatar)할 수 있습니다.

   [CI/CD 카탈로그](#cicd-catalog)에 게시된 구성 요소는 구성 요소 프로젝트의 요약을 표시할 때 설명과 아바타를 모두 사용합니다.

1. 각 구성 요소에 대해 [필수 디렉터리 구조](#directory-structure)를 따르는 YAML 구성 파일을 추가합니다. 예를 들어:

   ```yaml
   spec:
     inputs:
       stage:
         default: test
   ---
   component-job:
     script: echo job 1
     stage: $[[ inputs.stage ]]
   ```

[구성 요소를 즉시 사용](#use-a-component) 할 수 있지만, [CI/CD 카탈로그](#cicd-catalog)에 구성 요소를 게시하는 것을 고려할 수도 있습니다.

### 디렉터리 구조 {#directory-structure}

리포지토리에는 다음이 포함되어야 합니다:

- `README.md` 마크다운 파일로 리포지토리의 모든 구성 요소에 대한 세부 정보를 문서화합니다.
- 모든 구성 요소 구성을 포함하는 최상위 `templates/` 디렉터리입니다. 이 디렉터리에서 다음을 수행할 수 있습니다:
  - 각 구성 요소에 대해 `.yml`로 끝나는 단일 파일을 사용합니다(예: `templates/secret-detection.yml`).
  - 각 구성 요소에 대해 `template.yml`이 있는 하위 디렉터리를 만듭니다(예: `templates/secret-detection/template.yml`). `template.yml` 파일만 구성 요소를 사용하는 다른 프로젝트에서 사용됩니다. 이러한 디렉터리의 다른 파일은 구성 요소와 함께 릴리스되지 않지만 테스트 또는 컨테이너 이미지 빌드와 같은 작업에 사용될 수 있습니다.

> [!note]
> 선택적으로, 각 구성 요소는 더 자세한 정보를 제공하는 자신의 `README.md` 파일을 가질 수 있으며, 최상위 `README.md` 파일에서 연결될 수 있습니다. 이를 통해 구성 요소 프로젝트와 사용 방법을 더 잘 이해할 수 있습니다.

또한 다음을 수행해야 합니다:

- 프로젝트의 `.gitlab-ci.yml`를 구성하여 [구성 요소를 테스트](#test-the-component) 하고 [새 버전을 릴리스](#publish-a-new-release)합니다.
- 구성 요소의 사용을 포함하는 선택한 라이선스가 있는 `LICENSE.md` 파일을 추가합니다. 예를 들어 [MIT](https://opensource.org/license/mit) 또는 [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0#apply) 오픈 소스 라이선스입니다.

예를 들어:

- 프로젝트에 단일 구성 요소가 포함된 경우 디렉터리 구조는 다음과 유사해야 합니다:

  ```plaintext
  ├── templates/
  │   └── my-component.yml
  ├── LICENSE.md
  ├── README.md
  └── .gitlab-ci.yml
  ```

- 프로젝트에 여러 구성 요소가 포함된 경우 디렉터리 구조는 다음과 유사해야 합니다:

  ```plaintext
  ├── templates/
  │   ├── my-component.yml
  │   └── my-other-component/
  │       ├── template.yml
  │       ├── Dockerfile
  │       └── test.sh
  ├── LICENSE.md
  ├── README.md
  └── .gitlab-ci.yml
  ```

  이 예제에서:

  - `my-component` 구성 요소의 구성은 단일 파일에서 정의됩니다.
  - `my-other-component` 구성 요소의 구성에는 디렉터리의 여러 파일이 포함됩니다. `template.yml` 파일만 구성 요소를 사용하는 다른 프로젝트에서 사용할 수 있습니다.

## 구성 요소 사용 {#use-a-component}

전제 조건:

현재 그룹 또는 프로젝트를 포함하는 상위 그룹의 멤버인 경우:

- 프로젝트의 상위 그룹의 표시 여부 수준으로 설정된 최소 역할이 필요합니다. 예를 들어, 상위 프로젝트가 **비공개**로 설정된 경우 Reporter, Developer, Maintainer 또는 Owner 역할이 필요합니다.

프로젝트의 CI/CD 구성에 구성 요소를 추가하려면 [`include: component`](../yaml/_index.md#includecomponent) 키워드를 사용합니다. 구성 요소 참조는 `<fully-qualified-domain-name>/<project-path>/<component-name>@<specific-version>`로 포맷됩니다. 예를 들어:

```yaml
include:
  - component: $CI_SERVER_FQDN/my-org/security-components/secret-detection@1.0.0
    inputs:
      stage: build
```

이 예제에서:

- `$CI_SERVER_FQDN`은 GitLab 호스트와 일치하는 FQDN(정규화된 도메인 이름)에 대한 [미리 정의된 변수](../variables/predefined_variables.md)입니다. 프로젝트와 같은 GitLab 인스턴스에서만 구성 요소를 참조할 수 있습니다.
- `my-org/security-components`은 구성 요소를 포함하는 프로젝트의 전체 경로입니다.
- `secret-detection`은 `templates/secret-detection.yml`인 단일 파일 또는 `template.yml`을 포함하는 `templates/secret-detection/` 디렉터리로 정의된 구성 요소 이름입니다.
- `1.0.0`은 구성 요소의 [버전](#component-versions)입니다.

파이프라인 구성과 구성 요소 구성은 독립적으로 처리되지 않습니다. 파이프라인이 시작되면 포함된 구성 요소 구성이 파이프라인의 구성으로 [병합](../yaml/includes.md#merge-method-for-include)됩니다. 파이프라인과 구성 요소가 모두 이름이 같은 구성을 포함하면 예상하지 못한 방식으로 상호 작용할 수 있습니다.

예를 들어, 같은 이름의 두 작업은 단일 작업으로 병합됩니다. 마찬가지로 파이프라인의 작업과 같은 이름의 구성에 대해 `extends`을 사용하는 구성 요소는 잘못된 구성을 확장할 수 있습니다. 파이프라인과 구성 요소가 같은 이름의 구성을 공유하지 않는지 확인합니다. 의도적으로 [구성 요소 구성을 재정의](../yaml/includes.md#override-included-configuration-values)하려는 경우가 아니라면 말입니다.

GitLab.com 구성 요소를 GitLab Self-Managed 인스턴스에서 사용하려면 [구성 요소 프로젝트를 미러](#use-a-gitlabcom-component-on-gitlab-self-managed)해야 합니다.

> [!warning]
> 구성 요소가 토큰, 비밀번호 또는 기타 민감한 데이터를 사용해야 하는 경우, 구성 요소의 소스 코드를 감사하여 데이터가 사용자가 기대하고 인증하는 작업을 수행하기 위해서만 사용되는지 확인합니다. 또한 작업을 완료하는 데 필요한 최소 권한, 액세스 또는 범위가 있는 토큰 및 시크릿을 사용해야 합니다.

### 구성 요소 버전 {#component-versions}

최우선순위 순서로, 구성 요소 버전은 다음과 같을 수 있습니다:

- 커밋 SHA, 예를 들어 `e3262fdd0914fa823210cdb79a8c421e2cef79d8`입니다.
- 태그, 예를 들어: `1.0.0`입니다. 같은 이름의 태그와 커밋 SHA가 있으면 커밋 SHA가 태그보다 우선합니다. CI/CD 카탈로그에 릴리스된 구성 요소는 [시멘틱 버전 관리](#semantic-versioning)로 태그되어야 합니다.
- 브랜치 이름, 예를 들어 `main`입니다. 같은 이름의 브랜치와 태그가 있으면 태그가 브랜치보다 우선합니다.
- `~latest` 또는 CI/CD 카탈로그에서 게시된 지정된 패턴 내의 최신 버전을 선택하는 부분 의미 버전입니다. `~latest`을 사용하는 경우는 항상 최신 버전을 사용하려는 경우뿐이며, 이는 주요 변경 사항을 포함할 수 있습니다. `~latest`은 `1.0.1-rc`와 같은 사전 릴리스를 포함하지 않으며, 이는 프로덕션 준비가 되지 않은 것으로 간주됩니다.

구성 요소에서 지원하는 모든 버전을 사용할 수 있지만, CI/CD 카탈로그에 게시된 버전을 사용하는 것이 좋습니다. 커밋 SHA 또는 브랜치 이름으로 참조되는 버전은 CI/CD 카탈로그에 게시되지 않을 수 있지만 테스트에 사용할 수 있습니다.

#### 부분 의미 버전 {#partial-semantic-versions}

{{< history >}}

- GitLab 16.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/450835)

{{< /history >}}

부분 의미 버전 번호와 `~latest` 키워드를 사용하여 CI/CD 카탈로그 구성 요소를 참조할 때 사양과 일치하는 최신 게시 버전을 선택할 수 있습니다.

이러한 형식은 일반 프로젝트 구성 요소가 아니라 게시된 CI/CD 카탈로그 구성 요소에서만 작동합니다. 이렇게 하면 `1.2` 또는 `~latest`과 같은 형식을 사용할 때 리포지토리의 잠재적으로 테스트되지 않은 코드가 아니라 카탈로그에 검증되어 게시된 구성 요소만 가져옵니다.

이 방법은 구성 요소의 소비자와 작성자 모두에게 상당한 이점을 제공합니다:

- 사용자의 경우 부분 버전을 사용하는 것은 주요 릴리스에서 주요 변경 사항의 위험 없이 부 또는 패치 업데이트를 자동으로 받을 수 있는 좋은 방법입니다. 이를 통해 파이프라인을 안정성을 유지하면서 최신 버그 수정 및 보안 패치로 최신 상태로 유지합니다.
- 구성 요소 작성자의 경우, 부분 버전 지원은 기존 파이프라인을 즉시 중단할 위험 없이 주요 버전 릴리스를 허용합니다. 부분 버전을 지정한 사용자는 최신 호환 부 또는 패치 버전을 계속 사용하여 자신의 속도로 파이프라인을 업데이트할 수 있는 시간을 제공합니다.

사용:

- `1.2`을 사용하여 최신 `1.2.*` 버전을 선택합니다.
- `1`을 사용하여 최신 `1.*.*` 버전을 선택합니다.
- `~latest`을 사용하여 최신 릴리스 버전을 선택합니다.

예를 들어 구성 요소에 버전이 있습니다: `1.0.0`, `1.1.0`, `1.1.1`, `1.2.0`, `2.0.0`, `2.0.1`, `2.1.0`

구성 요소를 참조할 때:

- `1`은 `1.2.0`를 선택합니다.
- `1.1`은 `1.1.1`를 선택합니다.
- `~latest`은 `2.1.0`를 선택합니다.

부분 버전 선택을 사용할 때 사전 릴리스 버전은 절대 가져오지 않습니다. 사전 릴리스 버전을 가져오려면 전체 버전(예: `1.0.1-rc`)을 지정합니다.

### 구성 요소 컨텍스트를 구성 요소에서 사용 {#use-component-context-in-components}

{{< history >}}

- GitLab 18.6에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/438275) [베타](../../policy/development_stages_support.md#beta) 로 [플래그](../../administration/feature_flags/_index.md) 이름은 `ci_component_context_interpolation`입니다. 기본적으로 활성화됩니다.
- GitLab 18.7에서 [일반 공급 개시](https://gitlab.com/gitlab-org/gitlab/-/issues/571986)됨. 기능 플래그 `ci_component_context_interpolation` 제거됨.

{{< /history >}}

구성 요소는 구성 요소 컨텍스트 [CI/CD 표현식](../yaml/expressions.md)으로 자신에 대한 메타데이터에 액세스할 수 있습니다. 구성 요소 템플릿에서 이 표현식을 사용하여 버전, 커밋 SHA 및 기타 메타데이터를 동적으로 참조합니다.

구성 요소에서 구성 요소 컨텍스트를 사용하려면 다음을 수행해야 합니다:

1. 구성 요소 [`spec:component` 헤더](../yaml/_index.md#speccomponent)에서 구성 요소에 필요한 구성 요소 컨텍스트 필드를 선언합니다. `spec:component`는 `name`, `sha`, `version` 및 `reference` 필드를 지원합니다.
1. 구성 요소 템플릿에서 CI/CD 표현식 `$[[ component.field-name ]]`을 사용하여 컨텍스트 필드를 참조합니다.

예를 들어, 동일한 버전으로 구축된 Docker 이미지를 참조하는 구성 요소입니다:

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

또한 구성 요소 컨텍스트를 사용하여 [버전이 지정된 리소스를 참조](examples.md#use-component-context-to-reference-versioned-resources)할 수 있습니다.

### 구성 요소 `spec` 섹션 {#component-spec-section}

구성 요소 템플릿의 `spec` 섹션은 구성 요소의 구성과 입력을 정의합니다. `spec` 섹션에서 다음 키워드를 사용할 수 있습니다:

- [`description`](../yaml/_index.md#specdescription):  CI/CD 카탈로그에 표시되는 구성 요소의 간단한 설명을 제공합니다.
- [`inputs`](../yaml/_index.md#specinputs):  사용자가 구성 요소 구성을 사용자 지정할 수 있도록 입력 매개 변수를 정의합니다.
- [`component`](../yaml/_index.md#speccomponent):  보간을 위해 사용 가능하도록 할 구성 요소 컨텍스트 필드를 선언합니다(`name`, `sha`, `version` 및 `reference` 등).

> [!note]
> 구성 요소에서 [`spec:include`](../yaml/_index.md#specinclude)를 사용할 수 없습니다. 구성 요소는 자체 포함되어 외부 파일에 의존하지 않아야 합니다. 별도의 파일에서 포함하는 대신 구성 요소에 직접 입력을 정의합니다.

## 구성 요소 작성 {#write-a-component}

이 섹션은 고품질 구성 요소 프로젝트를 만들기 위한 몇 가지 모범 사례를 설명합니다.

### 의존성 관리 {#manage-dependencies}

구성 요소가 차례로 다른 구성 요소를 사용할 수 있지만, 의존성을 신중하게 선택해야 합니다. 의존성을 관리하려면 다음을 수행해야 합니다:

- 의존성을 최소한으로 유지합니다. 약간의 중복은 의존성이 있는 것보다 일반적으로 더 좋습니다.
- 가능한 한 로컬 의존성에 의존합니다. 예를 들어, [`include:local`](../yaml/_index.md#includelocal)를 사용하는 것은 여러 파일에서 동일한 Git SHA가 사용되도록 하는 좋은 방법입니다.
- 다른 프로젝트의 구성 요소에 의존할 때, `~latest` 또는 Git 참조와 같은 이동 대상 버전을 사용하는 대신 버전을 카탈로그의 릴리스로 고정합니다. 릴리스 또는 Git SHA를 사용하면 항상 동일한 리비전을 가져오고 구성 요소 소비자가 일관된 동작을 얻을 수 있습니다.
- 더 최신 릴리스로 고정하여 의존성을 정기적으로 업데이트합니다. 그런 다음 업데이트된 의존성이 있는 구성 요소의 새 릴리스를 게시합니다.
- 의존성의 권한을 평가하고 최소한의 권한이 필요한 의존성을 사용합니다. 예를 들어, 이미지를 빌드해야 하는 경우 Docker 대신 [Buildah](https://buildah.io/)를 사용하는 것을 고려하면 권한이 있는 Docker 데몬이 있는 Runner가 필요하지 않습니다.

### 명확한 `README.md`을 작성합니다. {#write-a-clear-readmemd}

각 구성 요소 프로젝트는 명확하고 포괄적인 문서를 가져야 합니다. 좋은 `README.md` 파일을 작성하려면:

- 구성 요소가 제공하는 기능 요약으로 시작합니다.
- 프로젝트에 여러 구성 요소가 포함된 경우 [목차](../../user/markdown.md#table-of-contents)를 사용하여 사용자가 특정 구성 요소의 세부 정보로 빠르게 이동할 수 있도록 합니다.
- `## Components` 섹션을 추가하고 각 구성 요소에 대해 `### Component A`과 같은 하위 섹션을 추가합니다.
- 각 구성 요소 섹션에서:
  - 구성 요소가 수행하는 작업을 설명합니다.
  - 사용 방법을 보여주는 최소한 하나의 YAML 예제를 추가합니다.
  - [`spec:inputs:description`](../yaml/_index.md#specinputsdescription)를 사용하여 구성 요소가 사용하는 모든 변수 또는 시크릿을 문서화합니다.
  - `README`에서 입력 문서를 복제하지 마세요. 입력이 구성 요소 페이지에 자동으로 표시됩니다. 대신 게시된 구성 요소에 대한 링크를 제공합니다.
- 기여가 환영되면 `## Contribute` 섹션을 추가합니다.

구성 요소가 더 많은 지시사항이 필요한 경우 구성 요소 디렉터리에 마크다운 파일에 추가 문서를 추가하고 주요 `README.md` 파일에서 연결합니다. 예를 들어:

```plaintext
README.md    # with links to the specific docs.md
templates/
├── component-1/
│   ├── template.yml
│   └── docs.md
└── component-2/
    ├── template.yml
    └── docs.md
```

예제는 [AWS 구성 요소 README](https://gitlab.com/components/aws/-/blob/main/README.md)를 참조하세요.

### 구성 요소 테스트 {#test-the-component}

CI/CD 구성 요소를 개발 워크플로우의 일부로 테스트하는 것이 강력하게 권장되며 일관된 동작을 보장하는 데 도움이 됩니다.

CI/CD 파이프라인에서 (다른 모든 프로젝트처럼) `.gitlab-ci.yml`을(를) 만들어 변경 사항을 테스트합니다. 구성 요소의 동작과 잠재적 부작용을 모두 테스트해야 합니다. 필요한 경우 [GitLab API](../../api/rest/_index.md)를 사용할 수 있습니다.

예를 들어:

```yaml
include:
  # include the component located in the current project from the current SHA
  - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/my-component@$CI_COMMIT_SHA
    inputs:
      stage: build

stages: [build, test, release]

# Check if `component job of my-component` is added.
# This example job could also test that the included component works as expected.
# You can inspect data generated by the component, use GitLab API endpoints, or third-party tools.
ensure-job-added:
  stage: test
  image: badouralix/curl-jq
  # Replace "component job of my-component" with the job name in your component.
  script:
    - |
      route="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/pipelines/${CI_PIPELINE_ID}/jobs"
      count=`curl --silent --header "JOB-TOKEN: ${CI_JOB_TOKEN}" "$route" | jq 'map(select(.name | contains("component job of my-component"))) | length'`
      if [ "$count" != "1" ]; then
        exit 1; else
        echo "Component Job present"
      fi

# If the pipeline is for a new tag with a semantic version, and all previous jobs succeed,
# create the release.
create-release:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  script: echo "Creating release $CI_COMMIT_TAG"
  rules:
    - if: $CI_COMMIT_TAG
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG of components repository $CI_PROJECT_PATH"
```

변경 사항을 커밋하고 푸시한 후 파이프라인은 구성 요소를 테스트한 다음 이전 작업이 통과하면 릴리스를 만듭니다.

> [!note]
> 프로젝트가 비공개인 경우 인증이 필요합니다.

#### 샘플 파일에 대해 구성 요소 테스트 {#test-a-component-against-sample-files}

경우에 따라 구성 요소는 상호 작용할 소스 파일이 필요합니다. 예를 들어, Go 소스 코드를 빌드하는 구성 요소는 테스트할 Go 샘플이 필요합니다. 또는 Docker 이미지를 빌드하는 구성 요소는 테스트할 샘플 Dockerfile이 필요합니다.

구성 요소 프로젝트에 직접 샘플 파일을 포함하여 구성 요소 테스트 중에 사용할 수 있습니다.

[구성 요소 테스트 예제](examples.md#test-a-component)에서 더 알아볼 수 있습니다.

### 인스턴스 또는 프로젝트 관련 값을 하드코딩하지 않음 {#avoid-hard-coding-instance-or-project-specific-values}

구성 요소에서 [다른 구성 요소를 사용](#use-a-component)할 때, 인스턴스의 FQDN(예: `gitlab.com` 등) 대신 `$CI_SERVER_FQDN`을(를) 사용합니다.

구성 요소에서 GitLab API에 액세스할 때, 인스턴스의 전체 URL 및 경로(예: `https://gitlab.com/api/v4` 등) 대신 `$CI_API_V4_URL`을(를) 사용합니다.

이러한 [미리 정의된 변수](../variables/predefined_variables.md) 는 구성 요소가 다른 인스턴스에서 사용될 때도 작동하도록 하며, 예를 들어 [GitLab Self-Managed 인스턴스에서 GitLab.com 구성 요소를 사용](#use-a-gitlabcom-component-on-gitlab-self-managed)할 때도 작동합니다.

### API 리소스가 항상 공개라고 가정하지 마세요 {#do-not-assume-api-resources-are-always-public}

구성 요소와 그 테스트 파이프라인도 [GitLab Self-Managed](#use-a-gitlabcom-component-on-gitlab-self-managed)에서 작동하는지 확인합니다. GitLab.com의 공개 프로젝트의 일부 API 리소스는 인증되지 않은 요청으로 액세스할 수 있지만, GitLab Self-Managed 인스턴스에서 구성 요소 프로젝트는 비공개 또는 내부 프로젝트로 미러될 수 있습니다.

액세스 토큰을 입력 또는 변수를 통해 선택적으로 제공하여 GitLab Self-Managed 인스턴스에서 요청을 인증할 수 있어야 합니다.

### 글로벌 키워드 사용 피하기 {#avoid-using-global-keywords}

구성 요소에서 [글로벌 키워드](../yaml/_index.md#global-keywords)를 사용하지 마세요. 구성 요소에서 이러한 키워드를 사용하면 주 `.gitlab-ci.yml`에 직접 정의된 작업 또는 다른 포함된 구성 요소를 포함한 파이프라인의 모든 작업에 영향을 미칩니다.

글로벌 키워드의 대안으로:

- 구성 요소 구성에서 약간의 중복을 만들더라도 각 작업에 구성을 직접 추가합니다.
- 구성 요소에서 [`extends` 키워드](../yaml/_index.md#extends)를 사용하되, 구성이 구성 요소에 병합될 때 이름 충돌 위험을 줄이는 고유한 이름을 사용합니다.

예를 들어, `default` 글로벌 키워드를 사용하지 않도록 합니다:

```yaml
# Not recommended
default:
  image: ruby:3.0

rspec-1:
  script: bundle exec rspec dir1/

rspec-2:
  script: bundle exec rspec dir2/
```

대신 다음을 수행할 수 있습니다:

- 각 작업에 구성을 명시적으로 추가합니다:

  ```yaml
  rspec-1:
    image: ruby:3.0
    script: bundle exec rspec dir1/

  rspec-2:
    image: ruby:3.0
    script: bundle exec rspec dir2/
  ```

- `extends`을(를) 사용하여 구성을 재사용합니다:

  ```yaml
  .rspec-image:
    image: ruby:3.0

  rspec-1:
    extends:
      - .rspec-image
    script: bundle exec rspec dir1/

  rspec-2:
    extends:
      - .rspec-image
    script: bundle exec rspec dir2/
  ```

### 하드코딩된 값을 입력으로 바꾸기 {#replace-hardcoded-values-with-inputs}

CI/CD 구성 요소에서 하드코딩된 값을 사용하지 마세요. 하드코딩된 값은 구성 요소 사용자가 구성 요소의 내부 세부 정보를 검토하고 구성 요소와 함께 작동하도록 파이프라인을 적응시켜야 할 수 있습니다.

하드코딩된 값이 문제가 되는 일반적인 키워드는 `stage`입니다. 구성 요소 작업의 스테이지가 하드코딩되어 있으면, 구성 요소를 사용하는 모든 파이프라인 **must** 정확히 동일한 스테이지를 정의하거나 [구성을 재정의](../yaml/includes.md#override-included-configuration-values)해야 합니다.

선호하는 방법은 동적 구성 요소 구성을 위해 [`input` 키워드](../inputs/_index.md)를 사용하는 것입니다. 구성 요소 사용자는 필요한 정확한 값을 지정할 수 있습니다.

예를 들어, 사용자가 정의할 수 있는 `stage` 구성으로 구성 요소를 만들려면:

- 구성 요소 구성에서:

  ```yaml
  spec:
    inputs:
      stage:
        default: test
  ---
  unit-test:
    stage: $[[ inputs.stage ]]
    script: echo unit tests

  integration-test:
    stage: $[[ inputs.stage ]]
    script: echo integration tests
  ```

- 구성 요소를 사용하는 프로젝트에서:

  ```yaml
  stages: [verify, release]

  include:
    - component: $CI_SERVER_FQDN/myorg/ruby/test@1.0.0
      inputs:
        stage: verify
  ```

#### 입력으로 작업 이름 정의 {#define-job-names-with-inputs}

`stage` 키워드 값과 유사하게, CI/CD 구성 요소에서 작업 이름을 하드코딩하지 않아야 합니다. 구성 요소의 사용자가 작업 이름을 사용자 지정할 수 있으면 파이프라인의 기존 이름과의 충돌을 방지할 수 있습니다. 사용자는 다른 입력 옵션으로 다른 이름을 사용하여 여러 번 구성 요소를 포함할 수도 있습니다.

구성 요소의 사용자가 특정 작업 이름 또는 작업 이름 접두사를 정의할 수 있도록 `inputs`을(를) 사용합니다. 예를 들어:

```yaml
spec:
  inputs:
    job-prefix:
      description: "Define a prefix for the job name"
    job-name:
      description: "Alternatively, define the job's name"
    job-stage:
      default: test
---

"$[[ inputs.job-prefix ]]-scan-website":
  stage: $[[ inputs.job-stage ]]
  script:
    - scan-website-1

"$[[ inputs.job-name ]]":
  stage: $[[ inputs.job-stage ]]
  script:
    - scan-website-2
```

### 맞춤 CI/CD 변수를 입력으로 바꾸기 {#replace-custom-cicd-variables-with-inputs}

CI/CD 변수를 구성 요소에서 사용할 때, `inputs` 키워드를 대신 사용해야 하는지 평가합니다. `inputs`이 더 나은 솔루션일 때 맞춤 변수를 정의하도록 사용자에게 요청하지 않습니다.

입력은 구성 요소의 `spec` 섹션에 명시적으로 정의되며 변수보다 검증이 더 좋습니다. 예를 들어, 필수 입력이 구성 요소에 전달되지 않으면 GitLab은 파이프라인 오류를 반환합니다. 반대로 변수가 정의되지 않으면 해당 값이 비어 있고 오류가 없습니다.

예를 들어, `inputs`을(를) 사용하여 스캐너의 출력 형식을 구성하는 변수 대신 사용합니다:

- 구성 요소 구성에서:

  ```yaml
  spec:
    inputs:
      scanner-output:
        default: json
  ---
  my-scanner:
    script: my-scan --output $[[ inputs.scanner-output ]]
  ```

- 구성 요소를 사용하는 프로젝트에서:

  ```yaml
  include:
    - component: $CI_SERVER_FQDN/path/to/project/my-scanner@1.0.0
      inputs:
        scanner-output: yaml
  ```

다른 경우에는 CI/CD 변수가 계속 선호될 수 있습니다. 예를 들어:

- [미리 정의된 변수](../variables/predefined_variables.md)를 사용하여 구성 요소를 사용자의 프로젝트와 일치하도록 자동으로 구성합니다.
- 사용자에게 [프로젝트 설정에서 마스킹 또는 보호된 CI/CD 변수](../variables/_index.md#define-a-cicd-variable-in-the-ui)로 민감한 값을 저장하도록 요청합니다.

## CI/CD 카탈로그 {#cicd-catalog}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/407249) [실험](../../policy/development_stages_support.md#experiment)으로.
- GitLab 16.7에서 [베타](https://gitlab.com/gitlab-org/gitlab/-/issues/432045) 로 [이동됨](../../policy/development_stages_support.md#beta).
- GitLab 17.0에서 [일반 공급 개시됨](https://gitlab.com/gitlab-org/gitlab/-/issues/454306).

{{< /history >}}

[CI/CD 카탈로그](https://gitlab.com/explore/catalog)는 CI/CD 워크플로우를 확장하는 데 사용할 수 있는 게시된 CI/CD 구성 요소가 있는 프로젝트 목록입니다.

누구든지 [구성 요소 프로젝트를 만들고](#create-a-component-project) CI/CD 카탈로그에 추가하거나 기존 프로젝트에 기여하여 사용 가능한 구성 요소를 개선할 수 있습니다.

클릭 스루 데모의 경우 [CI/CD 카탈로그 베타 제품 둘러보기](https://gitlab.navattic.com/cicd-catalog)를 참조하세요.
<!-- Demo published on 2024-01-24 -->

### CI/CD 카탈로그 보기 {#view-the-cicd-catalog}

CI/CD 카탈로그에 액세스하고 사용 가능한 게시된 구성 요소를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택합니다.
1. **탐색**을 선택합니다.
1. **CI/CD 카탈로그**를 선택합니다.

또는 프로젝트에 이미 [파이프라인 편집기](../pipeline_editor/_index.md)에 있으면 **CI/CD 카탈로그**를 선택할 수 있습니다.

CI/CD 카탈로그의 구성 요소 표시 여부는 구성 요소 소스 프로젝트의 [표시 여부 설정](../../user/public_access.md)을 따릅니다. 소스 프로젝트가 다음으로 설정된 구성 요소:

- 비공개는 소스 구성 요소 프로젝트에 대해 게스트, 플래너, Reporter, Developer, Maintainer 또는 Owner 역할이 할당된 사용자에게만 표시됩니다. 구성 요소를 사용하려면 Reporter, Developer, Maintainer 또는 Owner 역할이 필요합니다.
- 내부는 GitLab 인스턴스에 로그인한 사용자에게만 표시됩니다.
- 공개는 GitLab 인스턴스에 액세스할 수 있는 모든 사용자에게 표시됩니다.

### 카탈로그 리소스 분석 보기 {#view-catalog-resource-analytics}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.9에서 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/14027).

{{< /history >}}

CI/CD 카탈로그 리소스를 유지 관리하면 구성 요소가 프로젝트 전체에 어떻게 채택되는지 이해하기 위해 사용 분석을 볼 수 있습니다.

전제 조건:

- 하나 이상의 카탈로그 리소스 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.

카탈로그 리소스 분석을 보려면:

1. 상단 표시줄에서 **검색 또는 이동** > **탐색**을 선택합니다.
1. **CI/CD 카탈로그**를 선택합니다.
1. **분석** 탭을 선택합니다.

분석 보기는 Maintainer 또는 Owner 역할이 있는 카탈로그 리소스를 표시합니다. 이 보기에는 다음이 표시됩니다:

- **프로젝트**:  카탈로그 리소스 이름 및 최신 릴리스 버전입니다.
- **사용 통계**:  지난 30일 동안 파이프라인에서 이 카탈로그 리소스의 구성 요소를 사용한 고유 프로젝트 수입니다.
- **컴포넌트**:  카탈로그 리소스의 최신 버전에서 사용 가능한 구성 요소 목록입니다.

예를 들어:

![3개의 구성 요소와 그 사용 번호를 보여주는 카탈로그 리소스 분석 페이지입니다.](img/catalog_analytics_v18_10.png)

이 정보를 사용하여 다음을 수행할 수 있습니다:

- 가장 널리 채택된 카탈로그 리소스를 식별합니다.
- 시간 경과에 따른 구성 요소의 사용 추세를 추적합니다.
- 카탈로그 리소스를 사용 중인 프로젝트를 이해합니다.
- 구성 요소 유지 보수 및 중단에 대한 정보에 입각한 결정을 내립니다.

### 구성 요소 사용 세부 정보 보기 {#view-component-usage-details}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.0에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/579460).

{{< /history >}}

CI/CD 카탈로그 구성 요소 프로젝트를 유지 관리하면 구성 요소를 사용하는 프로젝트와 사용 중인 버전을 이해하기 위해 자세한 구성 요소 사용 정보를 볼 수 있습니다. 이를 통해 업그레이드를 계획하고 중단을 전달하며 오래된 버전을 사용하는 프로젝트를 식별할 수 있습니다.

전제 조건:

- 카탈로그 리소스 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.

구성 요소 사용 세부 정보를 보려면:

1. 상단 표시줄에서 **검색 또는 이동** > **탐색**을 선택합니다.
1. **CI/CD 카탈로그**를 선택합니다.
1. 카탈로그에서 구성 요소 프로젝트를 선택합니다.
1. 세부 정보 페이지에서 **사용량** 탭을 선택합니다.

이 탭은 지난 30일 동안 파이프라인에서 이 프로젝트의 구성 요소를 포함한 프로젝트를 나열합니다. 이 목록에는 보기 권한이 있는 프로젝트만 포함됩니다.

세부 정보에는 다음이 포함됩니다:

- **프로젝트 경로**:  프로젝트의 전체 경로로, 프로젝트에 대한 링크가 있습니다.
- **상태**:  프로젝트가 구성 요소의 최신 버전을 사용한 경우 **최신 상태**로 표시됩니다. 그렇지 않으면 **오래됨**입니다.
- **사용된 컴포넌트**:  프로젝트에서 사용하는 구성 요소의 이름 및 버전입니다.

사용자에게 표시되지 않는 프로젝트는 **Private project**로 링크 없이 표시됩니다.

이 정보를 사용하여 다음을 수행할 수 있습니다:

- 업그레이드가 필요한 오래된 구성 요소 버전을 사용하는 프로젝트를 식별합니다.
- 새 버전을 사용할 수 있거나 구성 요소를 중단할 때 프로젝트 관리자에게 알립니다.
- 조직 전체에서 특정 구성 요소 버전의 채택을 이해합니다.

### 구성 요소 프로젝트 게시 {#publish-a-component-project}

CI/CD 카탈로그에서 구성 요소 프로젝트를 게시하려면 다음을 수행해야 합니다:

1. 프로젝트를 카탈로그 프로젝트로 설정합니다.
1. 새 릴리스를 게시합니다.

#### 구성 요소 프로젝트를 카탈로그 프로젝트로 설정 {#set-a-component-project-as-a-catalog-project}

구성 요소 프로젝트의 게시된 버전을 CI/CD 카탈로그에 표시하려면 프로젝트를 카탈로그 프로젝트로 설정해야 합니다.

전제 조건:

- 프로젝트에 대해 Owner 역할이 필요합니다.

프로젝트를 카탈로그 프로젝트로 설정하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **CI/CD 카탈로그 프로젝트** 토글을 켭니다.

프로젝트는 새 릴리스를 게시한 후에만 카탈로그에서 검색 가능해집니다.

자동화를 사용하여 이 설정을 활성화하려면 [`mutationcatalogresourcescreate`](../../api/graphql/reference/_index.md#mutationcatalogresourcescreate) GraphQL 엔드포인트를 사용할 수 있습니다. [문제 463043](https://gitlab.com/gitlab-org/gitlab/-/issues/463043)은 REST API에도 이를 노출할 것을 제안합니다.

#### 새 릴리스 게시 {#publish-a-new-release}

CI/CD 구성 요소는 CI/CD 카탈로그에 나열되지 않고도 [사용](#use-a-component)할 수 있습니다. 그러나 구성 요소의 릴리스를 카탈로그에 게시하면 다른 사용자가 검색할 수 있게 됩니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.
- 프로젝트는 다음을 수행해야 합니다:
  - [카탈로그 프로젝트](#set-a-component-project-as-a-catalog-project)로 설정되어야 합니다.
  - [프로젝트 설명](../../user/project/working_with_projects.md#edit-a-project)이 정의되어야 합니다.
  - 릴리스되는 태그의 커밋 SHA에 대해 루트 디렉터리에 `README.md` 파일을 가져야 합니다.
  - 릴리스되는 태그의 커밋 SHA에 대해 [`templates/` 디렉터리](#directory-structure)에 최소한 하나의 CI/CD 구성 요소를 가져야 합니다.
- [Releases API](../../api/releases/_index.md#create-a-release) 가 아니라 CI/CD 작업에서 [`release` 키워드](../yaml/_index.md#release)를 사용하여 릴리스를 만들어야 합니다.

구성 요소의 새 버전을 카탈로그에 게시하려면:

1. 태그가 생성되면 `release` 키워드를 사용하여 새 릴리스를 만드는 프로젝트의 `.gitlab-ci.yml` 파일에 작업을 추가합니다. [구성 요소를 테스트](#test-the-component)한 후 릴리스 작업을 실행하도록 태그 파이프라인을 구성해야 합니다. 예를 들어:

   ```yaml
   create-release:
     stage: release
     image: registry.gitlab.com/gitlab-org/cli:latest
     script: echo "Creating release $CI_COMMIT_TAG"
     rules:
       - if: $CI_COMMIT_TAG
     release:
       tag_name: $CI_COMMIT_TAG
       description: "Release $CI_COMMIT_TAG of components in $CI_PROJECT_PATH"
   ```

1. 릴리스에 대해 [새 태그를 만들면](../../user/project/repository/tags/_index.md#create-a-tag), 릴리스를 만드는 책임이 있는 작업을 포함하는 태그 파이프라인이 트리거되어야 합니다. 태그는 [시멘틱 버전 관리](#semantic-versioning)를 사용해야 합니다.

릴리스 작업이 성공적으로 완료되면 릴리스가 생성되고 새 버전이 CI/CD 카탈로그에 게시됩니다.

#### 시멘틱 버전 관리 {#semantic-versioning}

{{< history >}}

- GitLab 16.10에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/427286).

{{< /history >}}

태그를 지정하고 구성 요소를 카탈로그에 [새 버전 릴리스](#publish-a-new-release) 할 때 [시멘틱 버전 관리](https://semver.org)를 사용해야 합니다. 시멘틱 버전 관리는 변경이 주요, 부, 패치 또는 다른 종류의 변경임을 전달하기 위한 표준입니다.

예를 들어, `1.0.0`, `2.3.4` 및 `1.0.0-alpha`은 모두 유효한 시멘틱 버전입니다.

### 구성 요소 프로젝트 게시 취소 {#unpublish-a-component-project}

카탈로그에서 구성 요소 프로젝트를 제거하려면 프로젝트 설정에서 [**CI/CD Catalog resource**](#set-a-component-project-as-a-catalog-project) 토글을 끕니다.

> [!warning]
> 이 작업은 카탈로그에 게시된 구성 요소 프로젝트 및 해당 버전에 대한 메타데이터를 파괴합니다. 프로젝트 및 해당 리포지토리는 계속 존재하지만 카탈로그에는 표시되지 않습니다.

구성 요소 프로젝트를 카탈로그에 다시 게시하려면 [새 릴리스를 게시](#publish-a-new-release)해야 합니다.

### 검증된 구성 요소 작성자 {#verified-component-creators}

{{< history >}}

- GitLab 16.11에서 [GitLab.com용으로 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/433443)
- GitLab 18.1에서 [GitLab Self-Managed 및 GitLab Dedicated용으로 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/460125)

{{< /history >}}

일부 CI/CD 구성 요소는 GitLab 또는 인스턴스 관리자에 의해 검증된 사용자가 만들고 유지 관리하는 구성 요소임을 표시하기 위해 아이콘으로 배지됩니다:

- GitLab 유지 관리 ({{< icon name="tanuki-verified" >}}):  GitLab에서 만들고 유지 관리하는 GitLab.com 구성 요소입니다.
- GitLab Partner ({{< icon name="partner-verified" >}}):  GitLab이 확인한 파트너가 독립적으로 만들고 유지 관리하는 GitLab.com 구성 요소입니다.

  GitLab 파트너는 GitLab Partner Alliance 멤버에게 연락하여 GitLab.com의 네임스페이스를 GitLab 확인으로 플래그할 수 있습니다. 그런 다음 네임스페이스에 위치한 모든 CI/CD 구성 요소는 GitLab Partner 구성 요소로 배지됩니다. Partner Alliance 멤버는 검증된 파트너를 대신하여 [내부 요청 이슈(GitLab 팀 멤버만)](https://gitlab.com/gitlab-com/support/internal-requests/-/issues/new?description_template=CI%20Catalog%20Badge%20Request)를 만듭니다.

  > [!warning]
  > GitLab Partner가 만든 구성 요소는 **as-is** 어떤 종류의 보증 없이 제공됩니다. 최종 사용자가 GitLab Partner가 만든 구성 요소를 사용하는 것은 자신의 책임이며 GitLab은 최종 사용자의 구성 요소 사용과 관련하여 배상 의무나 모든 종류의 책임이 없습니다. 최종 사용자의 이러한 콘텐츠 사용 및 관련 책임은 콘텐츠 게시자와 최종 사용자 간에 있습니다.

- 검증된 작성자 ({{< icon name="check-sm" >}}):  관리자가 검증한 사용자가 만들고 유지 관리하는 구성 요소입니다.

#### 검증된 작성자가 유지 관리하는 구성 요소로 설정 {#set-a-component-as-maintained-by-a-verified-creator}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.1에서 [GitLab Self-Managed 및 GitLab Dedicated용으로 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/460125)

{{< /history >}}

GitLab 관리자는 CI/CD 구성 요소를 검증된 작성자가 만들고 유지 관리하는 것으로 설정할 수 있습니다:

1. 관리자 계정으로 인스턴스에서 GraphiQL을 열고, 예를 들어 `https://gitlab.example.com/-/graphql-explorer`입니다.
1. 이 쿼리를 실행하여 `root-level-group`을(를) 확인할 구성 요소의 루트 네임스페이스로 바꿉니다:

   ```graphql
   mutation {
     verifiedNamespaceCreate(input: { namespacePath: "root-level-group",
       verificationLevel: VERIFIED_CREATOR_SELF_MANAGED
       }) {
       errors
     }
   }
   ```

쿼리가 완료되면 루트 네임스페이스의 프로젝트에 있는 모든 구성 요소가 검증됩니다. **검증된 작성자** 배지는 CI/CD 카탈로그의 구성 요소 이름 옆에 표시됩니다.

구성 요소에서 배지를 제거하려면 `verificationLevel`에 대해 `UNVERIFIED`을(를) 사용하여 쿼리를 반복합니다.

## CI/CD 템플릿을 구성 요소로 변환 {#convert-a-cicd-template-to-a-component}

`include:` 구문을 사용하여 프로젝트에서 사용하는 기존 CI/CD 템플릿은 CI/CD 구성 요소로 변환할 수 있습니다:

1. 구성 요소를 기존 [구성 요소 프로젝트](#component-project) 의 일부로 그룹화할지, 아니면 [새 구성 요소 프로젝트를 만들지](#create-a-component-project) 결정합니다.
1. [디렉터리 구조](#directory-structure)에 따라 구성 요소 프로젝트에서 YAML 파일을 만듭니다.
1. 원본 템플릿 YAML 파일의 내용을 새 구성 요소 YAML 파일로 복사합니다.
1. 새 구성 요소의 구성을 리팩터합니다:
   - [구성 요소 작성](#write-a-component)에 대한 지침을 따릅니다.
   - [병합 요청 파이프라인](../pipelines/merge_request_pipelines.md) 을(를) 활성화하거나 [더 효율적](../pipelines/pipeline_efficiency.md)으로 만드는 것을 포함하여 구성을 개선합니다.
1. 구성 요소 리포지토리에서 `.gitlab-ci.yml`을(를) 활용하여 [구성 요소 변경 사항을 테스트](#test-the-component)합니다.
1. 태그를 지정하고 [구성 요소를 릴리스](#publish-a-new-release)합니다.

[Go CI/CD 템플릿을 CI/CD 구성 요소로 마이그레이션](examples.md#cicd-component-migration-example-go)에 대한 실무 예제를 따라 더 알아볼 수 있습니다.

## GitLab Self-Managed에서 GitLab.com 구성 요소 사용 {#use-a-gitlabcom-component-on-gitlab-self-managed}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 인스턴스를 새로 설치하면 CI/CD 카탈로그가 게시된 CI/CD 구성 요소로 시작되지 않습니다. 인스턴스의 카탈로그를 채우려면 다음을 수행할 수 있습니다:

- [자신의 구성 요소를 게시](#publish-a-component-project)합니다.
- GitLab.com의 구성 요소를 GitLab Self-Managed 인스턴스에 미러합니다.

GitLab.com 구성 요소를 GitLab Self-Managed 인스턴스에 미러하려면:

1. [네트워크 아웃바운드 요청](../../security/webhooks.md)이 `gitlab.com`에 대해 허용되는지 확인합니다.
1. 구성 요소 프로젝트를 호스팅할 [그룹을 만들고](../../user/group/_index.md#create-a-group) (권장 그룹: `components`).
1. 새 그룹에 [구성 요소 프로젝트의 미러를 만듭니다](../../user/project/repository/mirror/pull.md).
1. 리포지토리 미러링이 설명을 복사하지 않으므로 구성 요소 프로젝트 미러에 대해 [프로젝트 설명](../../user/project/working_with_projects.md#edit-a-project)을 작성합니다.
1. [자체 호스팅 구성 요소 프로젝트를 카탈로그 리소스로 설정](#set-a-component-project-as-a-catalog-project)합니다.
1. 자체 호스팅 구성 요소 프로젝트에서 [새 릴리스](../../user/project/releases/_index.md) 를 게시하여 [태그에 대한 파이프라인을 실행](../pipelines/_index.md#run-a-pipeline-manually)합니다(보통 최신 태그).

## CI/CD 구성 요소 보안 모범 사례 {#cicd-component-security-best-practices}

### 구성 요소 사용자의 경우 {#for-component-users}

누구든지 카탈로그에 구성 요소를 게시할 수 있으므로 프로젝트에서 사용하기 전에 구성 요소를 신중하게 검토해야 합니다. GitLab CI/CD 구성 요소의 사용은 자신의 책임이며 GitLab은 제3자 구성 요소의 보안을 보장할 수 없습니다.

제3자 CI/CD 구성 요소를 사용할 때 다음 보안 모범 사례를 고려합니다:

- **Audit and review component source code**:  코드를 신중하게 검토하여 악의적인 콘텐츠가 없는지 확인합니다.
- **Minimize access to credentials and tokens**:
  - 구성 요소의 소스 코드를 감사하여 모든 자격 증명 또는 토큰이 예상하고 인증하는 작업을 수행하기 위해서만 사용되는지 확인합니다.
  - 최소 범위 액세스 토큰을 사용합니다.
  - 오래 지속되는 액세스 토큰 또는 자격 증명을 사용하지 않도록 합니다.
  - CI/CD 구성 요소에서 사용하는 자격 증명 및 토큰의 사용을 감사합니다.
- **Use pinned versions**:  파이프라인에서 사용되는 구성 요소의 무결성을 보장하기 위해 CI/CD 구성 요소를 특정 커밋 SHA(선호) 또는 릴리스 버전 태그에 고정합니다. 구성 요소 유지 관리자를 신뢰하는 경우에만 릴리스 태그를 사용합니다. `latest`를 사용하지 않도록 합니다.
- **Store secrets securely**:  CI/CD 구성 파일에 시크릿을 저장하지 마세요. 대신 외부 시크릿 관리 솔루션을 사용할 수 있으면 프로젝트 설정에 시크릿 및 자격 증명을 저장하지 않도록 합니다.
- **Use ephemeral, isolated runner environments**:  가능한 경우 임시 격리된 환경에서 구성 요소 작업을 실행합니다. 자체 관리 러너를 사용할 때 [보안 위험](https://docs.gitlab.com/runner/security)을 인식합니다.
- **Securely handle cache and artifacts**:  절대적으로 필요한 경우가 아니면 파이프라인의 다른 작업에서 CI/CD 구성 요소 작업으로 캐시 또는 아티팩트를 전달하지 마세요.
- **Limit CI_JOB_TOKEN access**:  CI/CD 구성 요소를 사용하는 프로젝트에 대해 [CI/CD 작업 토큰(`CI_JOB_TOKEN`) 프로젝트 액세스 및 권한](../jobs/ci_job_token.md#control-job-token-access-to-your-project)을 제한합니다.
- **Review CI/CD component changes**:  구성 요소에 대해 업데이트된 커밋 SHA 또는 릴리스 태그를 사용하도록 변경하기 전에 CI/CD 구성 요소 구성에 대한 모든 변경 사항을 신중하게 검토합니다.
- **Audit custom container images**:  CI/CD 구성 요소에서 사용하는 모든 맞춤 컨테이너 이미지를 신중하게 검토하여 악의적인 콘텐츠가 없는지 확인합니다.

### 구성 요소 유지 관리자의 경우 {#for-component-maintainers}

보안 및 신뢰할 수 있는 CI/CD 구성 요소를 유지 관리하고 사용자에게 제공하는 파이프라인 구성의 무결성을 보장하려면 다음 모범 사례를 따르세요:

- **Use two-factor authentication (2FA)**:  모든 CI/CD 구성 요소 프로젝트 유지 관리자 및 소유자가 [2FA 활성화](../../user/profile/account/two_factor_authentication.md#enable-two-factor-authentication) 되어 있는지 확인하거나 [그룹의 모든 사용자에 대해 2FA 적용](../../security/two_factor_authentication.md#enforce-2fa-for-all-users-in-a-group)합니다.
- **Use protected branches**:
  - 구성 요소 프로젝트 릴리스에 [보호된 브랜치](../../user/project/repository/branches/protected.md)를 사용합니다.
  - 기본 브랜치를 보호하고 모든 릴리스 브랜치를 [와일드카드 규칙을 사용](../../user/project/repository/branches/protected.md#use-wildcard-rules)하여 보호합니다.
  - 보호된 브랜치에 대한 변경 사항을 제출하려면 누구나 병합 요청을 제출해야 합니다. **푸시와 머지가 허용됨** 옵션을 보호된 브랜치에 대해 `No one`으로 설정합니다.
  - 보호된 브랜치로 강제 푸시를 차단합니다.
- **Sign all commits**:  구성 요소 프로젝트에 대한 모든 [커밋을 서명](../../user/project/repository/signed_commits/_index.md)합니다.
- **`latest` 사용 자제**: `README.md`에서 `@latest`을(를) 사용하는 예제를 포함하지 않도록 합니다.
- **Limit dependency on caches and artifacts from other jobs**:  절대적으로 필요한 경우에만 CI/CD 구성 요소의 다른 작업에서 캐시 및 아티팩트를 사용합니다.
- **Update CI/CD component dependencies**:  의존성에 대한 업데이트를 정기적으로 확인하고 적용합니다.
- **Review changes carefully**:
  - 기본 또는 릴리스 브랜치에 병합하기 전에 CI/CD 구성 요소 파이프라인 구성에 대한 모든 변경 사항을 신중하게 검토합니다.
  - CI/CD 구성 요소 카탈로그 프로젝트에 대한 모든 사용자 대면 변경 사항에 [병합 요청 승인](../../user/project/merge_requests/approvals/_index.md)을 사용합니다.

## 문제 해결 {#troubleshooting}

### `content not found` 메시지 {#content-not-found-message}

`~latest` 또는 부분 시멘틱 버전 한정자를 사용하여 [카탈로그 프로젝트](#set-a-component-project-as-a-catalog-project)에서 호스팅되는 구성 요소를 참조할 때 다음과 유사한 오류 메시지가 나타날 수 있습니다:

```plaintext
This GitLab CI configuration is invalid: Component 'gitlab.com/my-namespace/my-project/my-component@~latest' - content not found
```

`~latest` 동작이 GitLab 16.10에서 [업데이트됨](https://gitlab.com/gitlab-org/gitlab/-/issues/442238). 이제 카탈로그 리소스의 최신 시멘틱 버전을 나타냅니다. 이 문제를 해결하려면 [새 릴리스를 만듭니다](#publish-a-new-release).

### 오류: `Build component error: Spec must be a valid json schema` {#error-build-component-error-spec-must-be-a-valid-json-schema}

구성 요소의 형식이 잘못되면 릴리스를 만들지 못할 수 있으며 `Build component error: Spec must be a valid json schema`과 유사한 오류가 발생할 수 있습니다.

이 오류는 비어 있는 `spec:inputs` 섹션으로 인해 발생할 수 있습니다. 구성에서 입력을 사용하지 않으면 `spec` 섹션을 비워둘 수 있습니다. 예를 들어:

```yaml
spec:
---

my-component:
  script: echo
```

---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 파이프라인 시크릿 탐지 사용자 지정
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[구독 티어](_index.md#availability)와 구성 방법에 따라 파이프라인 시크릿 검색이 작동하는 방식을 변경할 수 있습니다.

[분석기 동작 커스터마이징](#customize-analyzer-behavior):

- 분석기가 감지하는 시크릿의 유형을 변경합니다.
- 다른 분석기 버전을 사용합니다.
- 특정 방법으로 프로젝트를 스캔합니다.

[분석기 규칙 집합 커스터마이징](#customize-analyzer-rulesets):

- 사용자 정의 시크릿 유형을 감지합니다.
- 기본 스캐너 규칙을 재정의합니다.

## 분석기 동작 커스터마이징 {#customize-analyzer-behavior}

분석기의 동작을 변경하려면 `.gitlab-ci.yml` 파일에서 [`variables`](../../../../ci/yaml/_index.md#variables) 매개변수를 사용하여 변수를 정의합니다.

> [!warning]
> 모든 GitLab 보안 스캔 도구 구성은 이러한 변경사항을 기본 브랜치에 병합하기 전에 머지 리퀘스트에서 테스트해야 합니다. 그렇지 않은 경우 수많은 오탐을 포함하여 예상치 못한 결과가 발생할 수 있습니다.

### 새로운 패턴 추가 {#add-new-patterns}

리포지토리에서 다른 유형의 시크릿을 검색하려면 [분석기 규칙 집합을 커스터마이징](#customize-analyzer-rulesets)할 수 있습니다.

### 새로운 감지 규칙 제안 {#propose-new-detection-rules}

모든 파이프라인 시크릿 검색 사용자에 대해 새로운 감지 규칙을 두 가지 방법으로 제안할 수 있습니다:

- 새 규칙 요청: [시크릿 검색 패턴 변경 이슈 템플릿](https://gitlab.com/gitlab-org/gitlab/-/work_items/new?description_template=Secret_Detection_Pattern_Change)을 사용하여 이슈를 생성합니다. GitLab 팀이 요청을 검토하고 새 규칙이 어떻게 그리고 언제 구현될지 결정하기 위해 연락할 것입니다.
- 새 규칙 기여: 규칙을 직접 기여하려면 시크릿 검색 규칙 리포지토리의 [기여 가이드라인](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/blob/main/README.md#adding-new-rules)을 따릅니다.

클라우드 또는 SaaS 제품을 운영하고 있으며 사용자를 더 잘 보호하기 위해 GitLab과 파트너십을 맺는 데 관심이 있다면 GitLab [유출된 자격증명 알림을 위한 파트너 프로그램](../automatic_response.md#partner-program-for-leaked-credential-notifications)을 참조하세요.

### 특정 분석기 버전으로 고정 {#pin-to-specific-analyzer-version}

GitLab 관리 CI/CD 템플릿은 주 버전을 지정하고 해당 주 버전 내에서 최신 분석기 릴리스를 자동으로 가져옵니다.

경우에 따라 특정 버전을 사용해야 할 수도 있습니다. 예를 들어, 이후 릴리스에서의 회귀를 피해야 할 때가 있습니다.

[`Secret-Detection.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)을 포함한 후 CI/CD 구성 파일에서 `SECRETS_ANALYZER_VERSION` CI/CD 변수를 설정하여 자동 업데이트 동작을 재정의합니다.

태그를 다음과 같이 설정할 수 있습니다:

- `4`과 같은 주 버전입니다. 파이프라인은 이 주 버전 내에서 릴리스되는 모든 부 버전 또는 패치 업데이트를 사용합니다.
- `4.5`과 같은 부 버전입니다. 파이프라인은 이 부 버전 내에서 릴리스되는 모든 패치 업데이트를 사용합니다.
- `4.5.0`과 같은 패치 버전입니다. 파이프라인은 어떠한 업데이트도 받지 않습니다.

이 예시는 분석기의 특정 부 버전을 사용합니다:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRETS_ANALYZER_VERSION: "4.5"
```

### 이력 스캔 활성화 {#enable-historic-scan}

`.gitlab-ci.yml` 파일에서 `SECRET_DETECTION_HISTORIC_SCAN` 변수를 `true`로 설정하여 이력 스캔을 활성화합니다.

### 머지 리퀘스트 파이프라인에서 작업 실행 {#run-jobs-in-merge-request-pipelines}

[머지 리퀘스트 파이프라인으로 보안 스캔 도구 사용](../../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)을 참조하세요.

### 분석기 작업 재정의 {#override-the-analyzer-jobs}

작업 정의를 재정의하려면(`variables` 또는 `dependencies`과 같은 속성 변경의 경우) `secret_detection` 작업과 동일한 이름으로 작업을 선언하여 재정의합니다. 템플릿 포함 선언 뒤에 이 새 작업을 배치하고 그 아래에 추가 키를 지정합니다.

`.gitlab-ci.yml` 파일의 다음 예시 추출에서:

- `Jobs/Secret-Detection` CI/CD 템플릿이 [포함](../../../../ci/yaml/_index.md#include)됩니다.
- `secret_detection` 작업에서 CI/CD 변수 `SECRET_DETECTION_HISTORIC_SCAN`는 `true`으로 설정됩니다. 템플릿은 파이프라인 구성 전에 평가되므로 변수의 마지막 언급이 우선하여 이력 스캔이 수행됩니다.

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_HISTORIC_SCAN: "true"
```

### 사용 가능한 CI/CD 변수 {#available-cicd-variables}

사용 가능한 CI/CD 변수를 정의하여 파이프라인 시크릿 검색의 동작을 변경합니다:

| CI/CD 변수                    | 기본값 | 설명 |
|-----------------------------------|---------------|-------------|
| `SECRET_DETECTION_EXCLUDED_PATHS` | ""            | 경로를 기반으로 출력에서 취약성을 제외합니다. 경로는 쉼표로 구분된 패턴 목록입니다. 패턴은 글로브([`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match)에서 지원되는 패턴 참조)이거나 파일 또는 폴더 경로(예: `doc,spec`)일 수 있습니다. 부모 디렉터리도 패턴과 일치합니다. 이전에 취약성 보고서에 추가된 감지된 시크릿은 제거되지 않습니다. |
| `SECRET_DETECTION_HISTORIC_SCAN`  | false         | 이력 Gitleaks 스캔을 활성화하는 플래그입니다. |
| `SECRET_DETECTION_IMAGE_SUFFIX`   | "" | 이미지 이름에 추가된 접미사. `-fips`로 설정하면 `FIPS-enabled` 이미지가 스캔에 사용됩니다. [FIPS 지원 이미지 사용](_index.md#fips-enabled-images)을 참조하여 자세한 내용을 확인합니다. |
| `SECRET_DETECTION_LOG_OPTIONS`  | ""        | 스캔할 커밋 범위를 지정하는 플래그입니다. Gitleaks는 [`git log`](https://git-scm.com/docs/git-log)를 사용하여 커밋 범위를 결정합니다. 정의되면 파이프라인 시크릿 검색은 브랜치의 모든 커밋을 가져오려고 시도합니다. 분석기가 모든 커밋에 액세스할 수 없으면 이미 체크아웃된 리포지토리로 계속됩니다. |

## 분석기 규칙 집합 커스터마이징 {#customize-analyzer-rulesets}

{{< details >}}

- 티어:  Ultimate

{{< /details >}}

{{< history >}}

- [패스스루 체인 지원 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/336395)되었으며 GitLab 17.2에서 `git` 및 `url`의 추가 패스스루 유형이 포함되었습니다.

{{< /history >}}

파이프라인 시크릿 검색을 사용하여 감지되는 시크릿의 유형을 사용자 정의할 수 있습니다. 스캔 중인 리포지토리 또는 원격 리포지토리에서 사용자 정의 규칙 집합 구성 파일을 생성하면 됩니다.

커스터마이징을 통해 다음을 수행할 수 있습니다

- 기본 규칙 집합의 규칙 동작을 수정합니다.
- 기본 규칙 집합을 사용자 정의 규칙 집합으로 바꿉니다.
- 기본 규칙 집합의 동작을 확장합니다.
- 시크릿 및 경로를 무시합니다.

### 규칙 집합 구성 파일 생성 {#create-a-ruleset-configuration-file}

규칙 집합 구성 파일을 생성하려면:

1. 프로젝트 루트에 `.gitlab` 디렉토리를 생성합니다(아직 없는 경우).
1. `.gitlab` 디렉토리에 `secret-detection-ruleset.toml`라는 파일을 생성합니다.

### 기본 규칙 집합의 규칙 수정 {#modify-rules-from-the-default-ruleset}

[기본 규칙 집합](../detected_secrets.md)에 미리 정의된 규칙을 수정할 수 있습니다.

규칙 수정은 파이프라인 시크릿 검색을 기존 워크플로우 또는 도구에 맞춰 조정하는 데 도움이 될 수 있습니다. 예를 들어 감지된 시크릿의 심각도를 재정의하거나 규칙이 완전히 감지되지 않도록 비활성화할 수 있습니다.

원격으로 저장된 규칙 집합 구성 파일(즉, 원격 Git 리포지토리 또는 웹사이트)을 사용하여 미리 정의된 규칙을 수정할 수도 있습니다. 새 규칙은 [사용자 정의 규칙 형식](custom_rulesets_schema.md#custom-rule-format)을 사용해야 합니다.

#### 규칙 비활성화 {#disable-a-rule}

활성화하고 싶지 않은 규칙을 비활성화할 수 있습니다. 분석기 기본 규칙 집합에서 규칙을 비활성화하려면:

1. [규칙 집합 구성 파일 생성](#create-a-ruleset-configuration-file)(아직 없는 경우).
1. `disabled` 플래그를 [`ruleset` 섹션](custom_rulesets_schema.md#the-secretsruleset-section)의 컨텍스트에서 `true`로 설정합니다.
1. 하나 이상의 `ruleset.identifier` 하위 섹션에서 비활성화할 규칙을 나열합니다. 모든 [`ruleset.identifier` 섹션](custom_rulesets_schema.md#the-secretsrulesetidentifier-section)에는 다음이 있습니다:
   - 미리 정의된 규칙 식별자에 대한 `type` 필드입니다.
   - 규칙 이름에 대한 `value` 필드입니다.

다음 `secret-detection-ruleset.toml` 파일 예시에서 비활성화된 규칙은 식별자의 `type` 및 `value`에 의해 일치합니다:

```toml
[secrets]
  [[secrets.ruleset]]
    disable = true
    [secrets.ruleset.identifier]
      type  = "gitleaks_rule_id"
      value = "RSA private key"
```

#### 규칙 재정의 {#override-a-rule}

커스터마이징할 특정 규칙이 있으면 이를 재정의할 수 있습니다. 예를 들어 유출 시 워크플로우에 더 높은 영향을 미치기 때문에 특정 유형의 시크릿의 심각도를 높일 수 있습니다.

분석기 기본 규칙 집합에서 규칙을 재정의하려면:

1. [규칙 집합 구성 파일 생성](#create-a-ruleset-configuration-file)(아직 없는 경우).
1. 하나 이상의 `ruleset.identifier` 하위 섹션에서 재정의할 규칙을 나열합니다. 모든 [`ruleset.identifier` 섹션](custom_rulesets_schema.md#the-secretsrulesetidentifier-section)에는 다음이 있습니다:
   - 미리 정의된 규칙 식별자에 대한 `type` 필드입니다.
   - 규칙 이름에 대한 `value` 필드입니다.
1. [`ruleset.override` 컨텍스트](custom_rulesets_schema.md#the-secretsrulesetoverride-section)의 [`ruleset` 섹션](custom_rulesets_schema.md#the-secretsruleset-section)에서 재정의할 키를 제공합니다. 키의 조합은 언제든지 재정의할 수 있습니다. 유효한 키는:
   - `description`
   - `message`
   - `name`
   - `severity`(유효한 옵션: `Critical`, `High`, `Medium`, `Low`, `Unknown`, `Info`)

다음 `secret-detection-ruleset.toml` 파일에서 규칙은 식별자의 `type` 및 `value`에 의해 일치된 후 재정의됩니다:

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.identifier]
      type  = "gitleaks_rule_id"
      value = "RSA private key"
    [secrets.ruleset.override]
      description = "OVERRIDDEN description"
      message     = "OVERRIDDEN message"
      name        = "OVERRIDDEN name"
      severity    = "Info"
```

#### 원격 규칙 집합 사용 {#with-a-remote-ruleset}

원격 규칙 집합은 현재 리포지토리 외부에 저장된 구성 파일입니다. 여러 프로젝트 간 규칙을 수정하는 데 사용할 수 있습니다.

원격 규칙 집합으로 미리 정의된 규칙을 수정하려면 `SECRET_DETECTION_RULESET_GIT_REFERENCE` [CI/CD 변수](../../../../ci/variables/_index.md)를 사용할 수 있습니다:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

variables:
  SECRET_DETECTION_RULESET_GIT_REFERENCE: "gitlab.com/example-group/remote-ruleset-project"
```

파이프라인 시크릿 검색은 구성이 원격 규칙 집합이 저장된 CI/CD 변수로 참조되는 리포지토리의 `.gitlab/secret-detection-ruleset.toml` 파일에 정의되어 있다고 가정합니다. 해당 파일이 없으면 [파일을 생성](#create-a-ruleset-configuration-file)하고 [재정의](#override-a-rule) 또는 [비활성화](#disable-a-rule) 단계를 따라 미리 정의된 규칙을 앞서 설명한 대로 수행합니다.

> [!note]
> 프로젝트의 로컬 `.gitlab/secret-detection-ruleset.toml` 파일이 `SECURE_ENABLE_LOCAL_CONFIGURATION`이 `true`로 설정되어 있기 때문에 기본적으로 `SECRET_DETECTION_RULESET_GIT_REFERENCE`을 재정의합니다. `SECURE_ENABLE_LOCAL_CONFIGURATION`을 `false`로 설정하면 로컬 파일이 무시되고 기본 구성 또는 `SECRET_DETECTION_RULESET_GIT_REFERENCE`(설정된 경우)이 사용됩니다.

`SECRET_DETECTION_RULESET_GIT_REFERENCE` 변수는 URI, 선택적 인증 및 선택적 Git SHA를 지정하기 위해 [Git URL](https://git-scm.com/docs/git-clone#_git_urls)과 유사한 형식을 사용합니다. 변수는 다음 형식을 사용합니다:

```plaintext
<AUTH_USER>:<AUTH_PASSWORD>@<PROJECT_PATH>@<GIT_SHA>
```

구성 파일이 인증이 필요한 비공개 프로젝트에 저장되어 있으면 [그룹 액세스 토큰](../../../group/settings/group_access_tokens.md)을 사용하여 CI/CD 변수에 안전하게 저장하면 원격 규칙 집합을 로드할 수 있습니다:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

variables:
  SECRET_DETECTION_RULESET_GIT_REFERENCE: "group_2504721_bot_7c9311ffb83f2850e794d478ccee36f5:$GROUP_ACCESS_TOKEN@gitlab.com/example-group/remote-ruleset-project"
```

그룹 액세스 토큰은 `read_repository` 범위와 리포터, 개발자, 유지보수자 또는 소유자 역할을 가져야 합니다. 자세한 내용은 [리포지토리 권한](../../../permissions.md#project-repositories)을 참조하세요.

[그룹의 봇 사용자](../../../group/settings/group_access_tokens.md#bot-users-for-groups)를 참조하여 그룹 액세스 토큰과 연결된 사용자 이름을 찾는 방법을 알아봅니다.

### 기본 규칙 집합 바꾸기 {#replace-the-default-ruleset}

[커스터마이징](custom_rulesets_schema.md)을 사용하여 기본 규칙 집합 구성을 바꿀 수 있습니다. [패스스루](custom_rulesets_schema.md#passthrough-types)를 사용하여 단일 구성으로 결합할 수 있습니다.

패스스루를 사용하면 다음을 수행할 수 있습니다:

- [20개의 패스스루](custom_rulesets_schema.md#the-secretspassthrough-section)까지 연결하여 미리 정의된 규칙을 바꾸거나 확장할 수 있습니다.
- [패스스루에 환경 변수 포함](custom_rulesets_schema.md#interpolate).
- 패스스루 평가를 위한 [타임아웃](custom_rulesets_schema.md#the-secrets-configuration-section)을 설정합니다.
- 각 정의된 패스스루에서 사용된 TOML 구문을 [검증](custom_rulesets_schema.md#the-secrets-configuration-section)합니다.

#### 인라인 규칙 집합 사용 {#with-an-inline-ruleset}

[`raw` 패스스루](custom_rulesets_schema.md#passthrough-types)를 사용하여 기본 규칙 집합을 인라인으로 제공된 구성으로 바꿀 수 있습니다.

동일한 리포지토리에 저장된 `.gitlab/secret-detection-ruleset.toml` 구성 파일에 다음을 추가하고 `[[rules]]`에서 정의된 규칙을 적절히 조정합니다:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "raw"
    target = "gitleaks.toml"
    value  = """
title = "replace default ruleset with a raw passthrough"

[[rules]]
description = "Test for Raw Custom Rulesets"
regex = '''Custom Raw Ruleset T[est]{3}'''
"""
```

이전 예시는 기본 규칙 집합을 정의된 정규식 - `Custom Raw Ruleset T`을 확인하는 규칙으로 바꾸며 `e`, `s` 또는 `t` 문자 중 하나의 3자 접미사를 가집니다.

패스스루 구문 사용에 대한 자세한 내용은 [스키마](custom_rulesets_schema.md#schema)를 참조하세요.

#### 로컬 규칙 집합 사용 {#with-a-local-ruleset}

[`file` 패스스루](custom_rulesets_schema.md#passthrough-types)를 사용하여 기본 규칙 집합을 현재 리포지토리에 커밋된 다른 파일로 바꿀 수 있습니다.

동일한 리포지토리에 저장된 `.gitlab/secret-detection-ruleset.toml` 구성 파일에 다음을 추가하고 로컬 규칙 집합 구성 파일의 경로를 가리키도록 `value`을 적절히 조정합니다:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "config/gitleaks.toml"
```

이것은 기본 규칙 집합을 `config/gitleaks.toml` 파일에 정의된 구성으로 바꿉니다.

패스스루 구문 사용에 대한 자세한 내용은 [스키마](custom_rulesets_schema.md#schema)를 참조하세요.

#### 원격 규칙 집합 사용 {#with-a-remote-ruleset-1}

`git` 및 `url` 패스스루를 사용하여 원격 Git 리포지토리 또는 온라인의 어딘가에 저장된 파일에 정의된 구성으로 기본 규칙 집합을 바꿀 수 있습니다.

원격 규칙 집합은 여러 프로젝트 간에 사용될 수 있습니다. 예를 들어 동일한 규칙 집합을 네임스페이스의 여러 프로젝트에 적용하려는 경우, 패스스루 유형 중 하나를 사용하여 원격 규칙 집합을 로드하고 여러 프로젝트에서 사용할 수 있습니다. 또한 규칙 집합의 중앙 집중식 관리가 가능하며, 권한 있는 사람만 편집할 수 있습니다.

`git` 패스스루를 사용하려면 리포지토리에 저장된 `.gitlab/secret-detection-ruleset.toml` 구성 파일에 다음을 추가하고 Git 리포지토리의 주소를 가리키도록 `value`을 조정합니다:

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

이 구성에서 분석기는 참조된 리포지토리의 `main` 브랜치의 `config` 디렉토리 내 `gitleaks.toml` 파일에서 규칙 집합을 로드합니다(`user_group/central_repository_with_shared_ruleset` 저장). 그 다음 `user_group/basic_repository` 이외의 프로젝트에 동일한 구성을 포함하도록 진행할 수 있습니다.

또는 `url` 패스스루를 사용하여 기본 규칙 집합을 원격 규칙 집합 구성으로 바꿀 수 있습니다.

`url` 패스스루를 사용하려면 리포지토리에 저장된 `.gitlab/secret-detection-ruleset.toml` 구성 파일에 다음을 추가하고 원격 파일의 주소를 가리키도록 `value`을 조정합니다:

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "url"
    target = "gitleaks.toml"
    value  = "https://example.com/gitleaks.toml"
```

이 구성에서 분석기는 제공된 주소에 저장된 `gitleaks.toml` 파일에서 규칙 집합 구성을 로드합니다.

패스스루 구문 사용에 대한 자세한 내용은 [스키마](custom_rulesets_schema.md#schema)를 참조하세요.

#### 비공개 원격 규칙 집합 사용 {#with-a-private-remote-ruleset}

규칙 집합 구성이 비공개 리포지토리에 저장되어 있으면 패스스루의 [`auth` 설정](custom_rulesets_schema.md#the-secretspassthrough-section)을 사용하여 리포지토리에 액세스하기 위한 자격증명을 제공해야 합니다.

> [!note]
> `auth` 설정은 `git` 패스스루에서만 작동합니다.

비공개 리포지토리에 저장된 원격 규칙 집합을 사용하려면 리포지토리에 저장된 `.gitlab/secret-detection-ruleset.toml` 구성 파일에 다음을 추가하고, Git 리포지토리의 주소를 가리키도록 `value`을 조정하며, 적절한 자격증명을 사용하도록 `auth`을 업데이트합니다:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    auth   = "USERNAME:PASSWORD" # replace USERNAME and PASSWORD as appropriate
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

> [!warning]
> 이 기능을 사용할 때 자격증명 유출을 조심하세요. 자격증명 유출 위험을 최소화하기 위해 환경 변수를 사용하는 방법의 예시는 [이 섹션](custom_rulesets_schema.md#interpolate)을 참조하세요.

패스스루 구문 사용에 대한 자세한 내용은 [스키마](custom_rulesets_schema.md#schema)를 참조하세요.

### 베타 규칙 켜기 {#turn-on-beta-rules}

베타 규칙은 기본 규칙 집합에 포함되지 않은 실험적 감지 규칙입니다. 기본 규칙 집합으로 승격되기 전에 베타 규칙을 사용하여 추가 시크릿 유형을 감지합니다.

> [!warning]
> 베타 규칙은 실험입니다. 기본 규칙보다 거짓 양성이 더 많을 수 있습니다. 통지 없이 변경되거나 제거될 수 있습니다. 베타 규칙의 발견 사항을 신중하게 검토합니다.

분석기 이미지는 `/beta.toml`에 베타 규칙 집합을 포함합니다. 이 규칙 집합은 모든 기본 규칙과 `beta` 성숙도의 규칙을 포함합니다. 분석기는 사용자가 옵트인하지 않으면 베타 규칙 집합을 로드하지 않습니다.

베타 규칙을 켜려면 [`file` 패스스루](custom_rulesets_schema.md#passthrough-types)를 사용하여 기본 규칙 집합을 번들된 베타 규칙 집합으로 바꿉니다. 동일한 리포지토리에 저장된 `.gitlab/secret-detection-ruleset.toml` 구성 파일에 다음을 추가합니다:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "/beta.toml"
```

베타 규칙 집합이 이미 기본 규칙을 포함하므로 기본 규칙 집합을 별도로 확장할 필요가 없습니다.

### 기본 규칙 집합 확장 {#extend-the-default-ruleset}

[기본 규칙 집합](../detected_secrets.md) 구성을 추가 규칙으로 확장할 수도 있습니다. 기본 규칙 집합에서 유지보수하는 높은 신뢰도의 미리 정의된 규칙의 이점을 누리면서도 자신의 프로젝트와 네임스페이스에서 사용할 수 있는 시크릿 유형에 대한 규칙을 추가하고 싶은 경우에 유용할 수 있습니다. 새 규칙은 [사용자 지정 규칙 형식](custom_rulesets_schema.md#custom-rule-format)을 따라야 합니다.

#### 로컬 규칙 집합 사용 {#with-a-local-ruleset-1}

`file` 패스스루를 사용하여 기본 규칙 집합을 확장하고 추가 규칙을 추가할 수 있습니다.

동일한 리포지토리에 저장된 `.gitlab/secret-detection-ruleset.toml` 구성 파일에 다음을 추가하고 확장된 구성 파일의 경로를 가리키도록 `value`을 적절히 조정합니다:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

`extended-gitleaks-config.toml`에 저장된 확장된 구성이 CI/CD 파이프라인의 분석기에서 사용하는 구성에 포함됩니다.

아래 예시에서는 일치할 정규식이 있는 새 `[[rules]]` 섹션을 추가합니다:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  id = "example_api_key"
  description = "Example Service API Key"
  regex = '''example_api_key'''

[[rules]]
  id = "example_api_secret"
  description = "Example Service API Secret"
  regex = '''example_api_secret'''
```

이 규칙 집합 구성으로 분석기는 정의된 정규식 패턴과 일치하는 모든 문자열을 감지합니다.

패스스루 구문 사용에 대한 자세한 내용은 [스키마](custom_rulesets_schema.md#schema)를 참조하세요.

#### 원격 규칙 집합 사용 {#with-a-remote-ruleset-2}

기본 규칙 집합을 원격 규칙 집합으로 바꾸는 방법과 유사하게, `.gitlab/secret-detection-ruleset.toml` 구성 파일이 있는 리포지토리 외부에 저장된 원격 Git 리포지토리 또는 파일에 저장된 구성으로 기본 규칙 집합을 확장할 수도 있습니다.

이는 앞서 논의한 대로 `git` 또는 `url` 패스스루 중 하나를 사용하여 달성할 수 있습니다.

`git` 패스스루로 이를 수행하려면 동일한 리포지토리에 저장된 `.gitlab/secret-detection-ruleset.toml` 구성 파일에 다음을 추가하고 확장된 구성 파일의 경로를 가리키도록 `value`, `ref` 및 `subdir`을 적절히 조정합니다:

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

파이프라인 시크릿 검색은 원격 규칙 집합 구성 파일을 `gitleaks.toml`이라고 하며, 참조된 리포지토리의 `main` 브랜치의 `config` 디렉토리에 저장되어 있다고 가정합니다.

기본 규칙 집합을 확장하려면 `gitleaks.toml` 파일이 이전 예시와 유사한 `[extend]` 지시문을 사용해야 합니다:

```toml
# https://gitlab.com/user_group/central_repository_with_shared_ruleset/-/raw/main/config/gitleaks.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  id = "example_api_key"
  description = "Example Service API Key"
  regex = '''example_api_key'''

[[rules]]
  id = "example_api_secret"
  description = "Example Service API Secret"
  regex = '''example_api_secret'''
```

`url` 패스스루를 사용하려면 동일한 리포지토리에 저장된 `.gitlab/secret-detection-ruleset.toml` 구성 파일에 다음을 추가하고 확장된 구성 파일의 경로를 가리키도록 `value`을 적절히 조정합니다

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "url"
    target = "gitleaks.toml"
    value  = "https://example.com/gitleaks.toml"
```

패스스루 구문 사용에 대한 자세한 내용은 [스키마](custom_rulesets_schema.md#schema)를 참조하세요.

#### 검사 실행 정책으로 사용 {#with-a-scan-execution-policy}

검사 실행 정책으로 규칙 집합을 확장하고 적용하려면:

- [검사 실행 정책으로 파이프라인 시크릿 검색 구성 설정](https://support.gitlab.com/hc/en-us/articles/18863735262364-How-to-set-up-a-centrally-managed-pipeline-secret-detection-configuration-applied-via-Scan-Execution-Policy)의 단계를 따릅니다.

### 패턴 및 경로 무시 {#ignore-patterns-and-paths}

파이프라인 시크릿 검색으로 감지되지 않도록 특정 패턴 또는 경로를 무시해야 하는 경우가 있을 수 있습니다. 예를 들어 테스트 스위트에서 사용할 가짜 시크릿을 포함하는 파일이 있을 수 있습니다.

이 경우 [Gitleaks의 네이티브 `[allowlist]`](https://github.com/gitleaks/gitleaks#configuration) 지시문을 사용하여 특정 패턴 또는 경로를 무시할 수 있습니다.

> [!note]
> 이 기능은 로컬 또는 원격 규칙 집합 구성 파일을 사용 중인지 여부와 관계없이 작동합니다. 아래 예시는 `file` 패스스루를 사용하는 로컬 규칙 집합을 사용합니다.

패턴을 무시하려면 동일한 리포지토리에 저장된 `.gitlab/secret-detection-ruleset.toml` 구성 파일에 다음을 추가하고 확장된 구성 파일의 경로를 가리키도록 `value`을 적절히 조정합니다:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

`extended-gitleaks-config.toml`에 저장된 확장된 구성이 분석기에서 사용하는 구성에 포함됩니다.

아래 예시에서는 무시할 시크릿과 일치하는 정규식을 정의하는 `[allowlist]` 지시문을 추가합니다("허용됨"):

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[allowlist]
  description = "allowlist of patterns to ignore in detection"
  regexTarget = "match"
  regexes = [
    '''glpat-[0-9a-zA-Z_\\-]{20}'''
  ]
```

이것은 `glpat-`과 일치하는 모든 문자열을 무시합니다(숫자 및 문자 20자의 접미사).

마찬가지로 스캔에서 특정 경로를 제외할 수 있습니다. 아래 예시에서는 `[allowlist]` 지시문 아래에서 무시할 경로의 배열을 정의합니다. 경로는 정규식 또는 특정 파일 경로일 수 있습니다:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[allowlist]
  description = "allowlist of patterns to ignore in detection"
  paths = [
    '''/gitleaks.toml''',
    '''(.*?)(jpg|gif|doc|pdf|bin|svg|socket)'''
  ]
```

이것은 `/gitleaks.toml` 파일에서 감지된 모든 시크릿 또는 지정된 확장 중 하나로 끝나는 파일을 무시합니다.

[Gitleaks v8.20.0](https://github.com/gitleaks/gitleaks/releases/tag/v8.20.0)에서는 `regexTarget`를 `[allowlist]`과 함께 사용할 수도 있습니다. 이는 [개인 액세스 토큰 접두사](../../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix) 또는 [사용자 정의 인스턴스 접두사](../../../../administration/settings/account_and_limit_settings.md#instance-token-prefix)를 기존 규칙을 재정의하여 구성할 수 있음을 의미합니다. 예를 들어 `personal access tokens`의 경우 다음과 같이 구성할 수 있습니다:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
# Rule id you want to override:
id = "gitlab_personal_access_token"
# all the other attributes from the default rule are inherited
    [[rules.allowlists]]
    regexTarget = "line"
    regexes = [ '''CUSTOMglpat-''' ]

[[rules]]
id = "gitlab_personal_access_token_with_custom_prefix"
regex = '<Regex that match a personal access token starting with your CUSTOM prefix>'

```

[기본 규칙 집합](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/blob/main/rules/mit/gitlab/gitlab.toml)에 구성된 모든 규칙을 고려해야 함을 명심하세요.

패스스루 구문 사용에 대한 자세한 내용은 [스키마](custom_rulesets_schema.md#schema)를 참조하세요.

### 인라인에서 시크릿 무시 {#ignore-secrets-inline}

경우에 따라 시크릿을 인라인에서 무시하고 싶을 수 있습니다. 예를 들어 예제 또는 테스트 스위트에서 가짜 시크릿을 가질 수 있습니다. 이러한 경우 취약성으로 보고되는 것보다 시크릿을 무시해야 합니다.

시크릿을 무시하려면 시크릿이 포함된 라인에 주석으로 `gitleaks:allow`을 추가합니다.

예를 들어:

```ruby
"A personal token for GitLab will look like glpat-JUST20LETTERSANDNUMB"  # gitleaks:allow
```

### 복잡한 문자열 감지 {#detecting-complex-strings}

[기본 규칙 집합](_index.md#detected-secrets)은 거짓 양성 비율이 낮은 구조화된 문자열을 감지하기 위한 패턴을 제공합니다. 그러나 비밀번호와 같은 더 복잡한 문자열을 감지하고 싶을 수도 있습니다. [Gitleaks는 선행 또는 후행을 지원하지 않으므로](https://github.com/google/re2/issues/411), 비정형 문자열을 감지하기 위한 높은 신뢰도의 일반 규칙을 작성하는 것은 불가능합니다.

모든 복잡한 문자열을 감지할 수는 없지만 특정 사용 사례를 충족하도록 규칙 집합을 확장할 수 있습니다.

예를 들어, 이 규칙은 Gitleaks 기본 규칙 집합의 [`generic-api-key` 규칙](https://github.com/gitleaks/gitleaks/blob/4e43d1109303568509596ef5ef576fbdc0509891/config/gitleaks.toml#L507-L514)을 수정합니다:

```regex
(?i)(?:pwd|passwd|password)(?:[0-9a-z\-_\t .]{0,20})(?:[\s|']|[\s|"]){0,3}(?:=|>|=:|:{1,3}=|\|\|:|<=|=>|:|\?=)(?:'|\"|\s|=|\x60){0,5}([0-9a-z\-_.=\S_]{3,50})(?:['|\"|\n|\r|\s|\x60|;]|$)
```

이 정규식은 다음과 일치합니다:

1. `pwd`, `passwd` 또는 `password`으로 시작하는 대소문자를 구분하지 않는 식별자입니다. `secret` 또는 `key`과 같은 다른 변형으로 이를 조정할 수 있습니다.
1. 식별자를 따르는 접미사입니다. 접미사는 숫자, 문자 및 기호의 조합이며 0~23자 길이입니다.
1. `=`, `:=`, `:` 또는 `=>`과 같은 일반적으로 사용되는 대입 연산자입니다.
1. 시크릿 감지에 도움이 되는 경계로 자주 사용되는 시크릿 접두사입니다.
1. 숫자, 문자 및 기호의 문자열(3~50자 길이)입니다. 이것은 시크릿 자체입니다. 더 긴 문자열을 예상하면 길이를 조정할 수 있습니다.
1. 경계로 자주 사용되는 시크릿 접미사입니다. 이것은 틱, 줄 바꿈 및 새 라인과 같은 일반적인 끝과 일치합니다.

이 정규식과 일치하는 예시 문자열은 다음과 같습니다:

```plaintext
pwd = password1234
passwd = 'p@ssW0rd1234'
password = thisismyverylongpassword
password => mypassword
password := mypassword
password: password1234
"password" = "p%ssward1234"
'password': 'p@ssW0rd1234'
```

이 정규식을 사용하려면 이 페이지에 설명된 방법 중 하나로 규칙 집합을 확장합니다.

예를 들어 이 규칙을 포함하는 기본 규칙 집합을 [로컬 규칙 집합으로](#with-a-local-ruleset-1) 확장하고 싶다고 상상해 봅시다.

동일한 리포지토리에 저장된 `.gitlab/secret-detection-ruleset.toml` 구성 파일에 다음을 추가합니다. 확장된 구성 파일의 경로를 가리키도록 `value`을 조정합니다:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

`extended-gitleaks-config.toml` 파일에서 사용하려는 정규식이 있는 새 `[[rules]]` 섹션을 추가합니다:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  description = "Generic Password Rule"
  id = "generic-password"
  regex = '''(?i)(?:pwd|passwd|password)(?:[0-9a-z\-_\t .]{0,20})(?:[\s|']|[\s|"]){0,3}(?:=|>|=:|:{1,3}=|\|\|:|<=|=>|:|\?=)(?:'|\"|\s|=|\x60){0,5}([0-9a-z\-_.=\S_]{3,50})(?:['|\"|\n|\r|\s|\x60|;]|$)'''
  entropy = 3.5
  keywords = ["pwd", "passwd", "password"]
```

> [!note]
> 이 예시 구성은 편의상만 제공되며 모든 사용 사례에서 작동하지 않을 수 있습니다. 규칙 집합을 복잡한 문자열을 감지하도록 구성하면 많은 수의 거짓 양성이 발생하거나 특정 패턴을 포착하지 못할 수 있습니다.

### 데모 {#demonstrations}

[데모 프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection)가 이러한 구성 옵션 중 일부를 설명합니다.

아래는 데모 프로젝트와 관련 워크플로우를 포함한 표입니다:

| 작업/워크플로우         | 적용 대상/방법   | 인라인 또는 로컬 규칙 집합 사용                                                                                                                                                                                                                                                                                                                                                                                       | 원격 규칙 집합 사용 |
|-------------------------|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------|
| 규칙 비활성화          | 미리 정의된 규칙 | [로컬 규칙 집합](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/disable-rule-project/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/disable-rule-project)   | [원격 규칙 집합](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/disable-rule-ruleset) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/disable-rule-project) |
| 규칙 재정의         | 미리 정의된 규칙 | [로컬 규칙 집합](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/override-rule-project/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/override-rule-project) | [원격 규칙 집합](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/override-rule-ruleset) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/override-rule-project) |
| 기본 규칙 집합 바꾸기 | 파일 패스스루 | [로컬 규칙 집합](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/file-passthrough/-/blob/main/config/gitleaks.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/file-passthrough)                                                                     | 해당 사항 없음      |
| 기본 규칙 집합 바꾸기 | 원시 패스스루  | [인라인 규칙 집합](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/raw-passthrough/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/raw-passthrough)                                      | 해당 사항 없음      |
| 기본 규칙 집합 바꾸기 | Git 패스스루  | 해당 사항 없음                                                                                                                                                                                                                                                                                                                                                                                                     | [원격 규칙 집합](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-replace/config/gitleaks.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/git-passthrough) |
| 기본 규칙 집합 바꾸기 | URL 패스스루  | 해당 사항 없음                                                                                                                                                                                                                                                                                                                                                                                                     | [원격 규칙 집합](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-replace/config/gitleaks.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/url-passthrough) |
| 기본 규칙 집합 확장  | 파일 패스스루 | [로컬 규칙 집합](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/file-passthrough)                                                       | 해당 사항 없음      |
| 기본 규칙 집합 확장  | Git 패스스루  | 해당 사항 없음                                                                                                                                                                                                                                                                                                                                                                                                     | [원격 규칙 집합](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-extend/config/gitleaks.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/git-passthrough) |
| 기본 규칙 집합 확장  | URL 패스스루  | 해당 사항 없음                                                                                                                                                                                                                                                                                                                                                                                                     | [원격 규칙 집합](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-extend/config/gitleaks.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/url-passthrough) |
| 경로 무시            | 파일 패스스루 | [로컬 규칙 집합](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/file-passthrough)                                                                           | 해당 사항 없음      |
| 경로 무시            | Git 패스스루  | 해당 사항 없음                                                                                                                                                                                                                                                                                                                                                                                                     | [원격 규칙 집합](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-paths/config/gitleaks.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/git-passthrough) |
| 경로 무시            | URL 패스스루  | 해당 사항 없음                                                                                                                                                                                                                                                                                                                                                                                                     | [원격 규칙 집합](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-paths/config/gitleaks.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/url-passthrough) |
| 패턴 무시         | 파일 패스스루 | [로컬 규칙 집합](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/file-passthrough)                                                                     | 해당 사항 없음      |
| 패턴 무시         | Git 패스스루  | 해당 사항 없음                                                                                                                                                                                                                                                                                                                                                                                                     | [원격 규칙 집합](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-patterns/config/gitleaks.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/git-passthrough) |
| 패턴 무시         | URL 패스스루  | 해당 사항 없음                                                                                                                                                                                                                                                                                                                                                                                                     | [원격 규칙 집합](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-patterns/config/gitleaks.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/url-passthrough) |
| 값 무시           | 파일 패스스루 | [로컬 규칙 집합](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/file-passthrough)                                                                         | 해당 사항 없음      |
| 값 무시           | Git 패스스루  | 해당 사항 없음                                                                                                                                                                                                                                                                                                                                                                                                     | [원격 규칙 집합](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-values/config/gitleaks.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/git-passthrough) |
| 값 무시           | URL 패스스루  | 해당 사항 없음                                                                                                                                                                                                                                                                                                                                                                                                     | [원격 규칙 집합](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-values/config/gitleaks.toml) / [프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/url-passthrough) |

원격 규칙 집합 설정을 안내하는 비디오 데모도 있습니다:

- [로컬 및 원격 규칙 집합을 사용한 시크릿 검색](https://youtu.be/rsN1iDug5GU)

## 오프라인 구성 {#offline-configuration}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

오프라인 환경은 인터넷을 통한 외부 리소스에 대한 액세스가 제한적이거나 간헐적입니다. 이러한 환경의 인스턴스의 경우 파이프라인 시크릿 검색에는 일부 구성 변경이 필요합니다. 이 섹션의 지침은 [오프라인 환경](../../offline_deployments/_index.md)에서 자세히 설명된 지침과 함께 완료해야 합니다.

### GitLab 러너 구성 {#configure-gitlab-runner}

기본적으로 러너는 로컬 복사본이 사용 가능한 경우에도 GitLab 컨테이너 레지스트리에서 Docker 이미지를 가져오려고 시도합니다. Docker 이미지를 최신 상태로 유지하려면 이 기본 설정을 사용해야 합니다. 그러나 네트워크 연결이 없으면 기본 GitLab 러너 `pull_policy` 변수를 변경해야 합니다.

GitLab 러너 CI/CD 변수 `pull_policy`을 [`if-not-present`](https://docs.gitlab.com/runner/executors/docker/#using-the-if-not-present-pull-policy)로 구성합니다.

### 로컬 파이프라인 시크릿 검색 분석기 이미지 사용 {#use-local-pipeline-secret-detection-analyzer-image}

GitLab 컨테이너 레지스트리 대신 로컬 Docker 레지스트리에서 이미지를 가져오려면 로컬 파이프라인 시크릿 검색 분석기 이미지를 사용합니다.

전제 조건:

- 로컬 오프라인 Docker 레지스트리로 Docker 이미지를 가져오는 것은 네트워크 보안 정책에 따라 달라집니다. IT 담당자에게 문의하여 외부 리소스를 가져오거나 임시로 액세스하기 위한 승인된 프로세스를 찾습니다.

1. `registry.gitlab.com`에서 기본 파이프라인 시크릿 검색 분석기 이미지를 [로컬 Docker 컨테이너 레지스트리](../../../packages/container_registry/_index.md)로 가져옵니다:

   ```plaintext
   registry.gitlab.com/security-products/secrets:7
   ```

   파이프라인 시크릿 검색 분석기의 이미지는 [정기적으로 업데이트](../../detect/vulnerability_scanner_maintenance.md)되므로 로컬 복사본을 정기적으로 업데이트해야 합니다.

1. CI/CD 변수 `SECURE_ANALYZERS_PREFIX`을 로컬 Docker 컨테이너 레지스트리로 설정합니다.

   ```yaml
   include:
     - template: Jobs/Secret-Detection.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
   ```

파이프라인 시크릿 검색 작업은 이제 분석기 Docker 이미지의 로컬 복사본을 사용해야 하며 인터넷 액세스가 필요하지 않습니다.

## 사용자 정의 SSL CA 인증서 기관 사용 {#using-a-custom-ssl-ca-certificate-authority}

사용자 정의 인증서 기관을 신뢰하려면 `ADDITIONAL_CA_CERT_BUNDLE` 변수를 신뢰하는 CA 인증서 번들로 설정합니다. `.gitlab-ci.yml` 파일, 파일 변수 또는 CI/CD 변수에서 이를 수행합니다.

- `.gitlab-ci.yml` 파일에서 `ADDITIONAL_CA_CERT_BUNDLE` 값은 [X.509 PEM 공개 키 인증서의 텍스트 표현](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)을 포함해야 합니다.

  예를 들어:

  ```yaml
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
  ```

- 파일 변수를 사용하는 경우 `ADDITIONAL_CA_CERT_BUNDLE`의 값을 인증서의 경로로 설정합니다.

- 변수를 사용하는 경우 `ADDITIONAL_CA_CERT_BUNDLE`의 값을 인증서의 텍스트 표현으로 설정합니다.

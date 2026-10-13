---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 커스텀 규칙 집합 스키마
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[다양한 종류의 규칙 집합 커스터마이제이션](configure.md#customize-analyzer-rulesets)을(를) 사용하여 파이프라인 시크릿 검색의 동작을 커스터마이징할 수 있습니다.

## 스키마 {#schema}

파이프라인 시크릿 검색 규칙 집합의 커스터마이제이션은 엄격한 스키마를 준수해야 합니다. 다음 섹션에서는 사용 가능한 각 옵션 및 해당 섹션에 적용되는 스키마를 설명합니다.

### 최상위 섹션 {#the-top-level-section}

최상위 섹션에는 [TOML 테이블](https://toml.io/en/v1.0.0#table)로 정의된 하나 이상의 구성 섹션이 포함됩니다.

| 설정     | 설명                                        |
|-------------|----------------------------------------------------|
| `[secrets]` | 분석기에 대한 구성 섹션을 선언합니다. |

구성 예:

```toml
[secrets]
...
```

### `[secrets]` 구성 섹션 {#the-secrets-configuration-section}

`[secrets]` 섹션을 통해 분석기의 동작을 커스터마이징할 수 있습니다. 유효한 속성은 수행하는 구성의 종류에 따라 다릅니다.

| 설정               | 적용 대상       | 설명                                                                                                                                                                                                                                                                              |
|-----------------------|------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `[[secrets.ruleset]]` | 미리 정의된 규칙 | 기존 규칙에 대한 수정 사항을 정의합니다.                                                                                                                                                                                                                                               |
| `interpolate`         | 모두              | `true`로 설정하면 구성에서 `$VAR`을(를) 사용하여 환경 변수를 평가할 수 있습니다. 시크릿 또는 토큰이 유출되지 않도록 이 기능을 신중하게 사용하세요. (기본값: `false`)                                                                                                      |
| `description`         | 통과     | 커스텀 규칙 집합의 설명입니다.                                                                                                                                                                                                                                                       |
| `targetdir`           | 통과     | 최종 구성을 유지해야 하는 디렉터리입니다. 비어 있으면 임의의 이름을 가진 디렉터리가 생성됩니다. 디렉터리에는 최대 100MB의 파일이 포함될 수 있습니다.                                                                                                                   |
| `validate`            | 통과     | `true`로 설정하면 각 통과의 콘텐츠가 유효성 검사됩니다. 유효성 검사는 `yaml`, `xml`, `json` 및 `toml` 콘텐츠에 적용됩니다. 적절한 유효성 검사기는 `[[secrets.passthrough]]` 섹션의 `target` 매개변수에 사용된 확장자를 기반으로 식별됩니다. (기본값: `false`) |
| `timeout`             | 통과     | 통과 체인을 평가하는 데 소요되는 최대 시간(시간 초과 전)입니다. 시간 초과는 300초를 초과할 수 없습니다. (기본값: 60)                                                                                                                                                     |

#### `interpolate` {#interpolate}

> [!warning]
> 시크릿 유출 위험을 줄이려면 이 기능을 신중하게 사용하세요.

아래 예는 `$GITURL` 환경 변수를 사용하여 프라이빗 리포지토리에 액세스하는 구성을 보여줍니다. 변수에는 사용자 이름과 토큰(예: `https://user:token@url`)이 포함되므로 구성 파일에 명시적으로 저장되지 않습니다.

```toml
[secrets]
  description = "My private remote ruleset"
  interpolate = true

  [[secrets.passthrough]]
    type  = "git"
    value = "$GITURL"
    ref = "main"
```

### `[[secrets.ruleset]]` 섹션 {#the-secretsruleset-section}

`[[secrets.ruleset]]` 섹션은 단일 미리 정의된 규칙을 대상으로 하고 수정합니다. 분석기에 대해 이러한 섹션을 하나 이상 정의할 수 있습니다.

| 설정                        | 설명                                             |
|--------------------------------|---------------------------------------------------------|
| `disable`                      | 규칙을 비활성화할지 여부입니다. (기본값: `false`) |
| `[secrets.ruleset.identifier]` | 수정할 미리 정의된 규칙을 선택합니다.             |
| `[secrets.ruleset.override]`   | 규칙에 대한 오버라이드를 정의합니다.                     |

구성 예:

```toml
[secrets]
  [[secrets.ruleset]]
    disable = true
    ...
```

### `[secrets.ruleset.identifier]` 섹션 {#the-secretsrulesetidentifier-section}

`[secrets.ruleset.identifier]` 섹션은 수정하려는 미리 정의된 규칙의 식별자를 정의합니다.

| 설정 | 설명 |
| --------| ----------- |
| `type`  | 미리 정의된 규칙에서 사용하는 식별자의 유형입니다. |
| `value` | 미리 정의된 규칙에서 사용하는 식별자의 값입니다. |

`type` 및 `value`의 올바른 값을 확인하려면 분석기에서 생성한 [`gl-secret-detection-report.json`](_index.md#secret-detection-results)을(를) 봅니다. 이 파일을 분석기의 CI/CD 작업에서 작업 아티팩트로 다운로드할 수 있습니다.

예를 들어, 아래 스니펫은 하나의 식별자가 있는 `gitlab_personal_access_token` 규칙에서의 검색을 보여줍니다. JSON 개체의 `type` 및 `value` 키는 이 섹션에서 제공해야 하는 값에 해당합니다.

```json
...
  "vulnerabilities": [
    {
      "id": "fccb407005c0fb58ad6cfcae01bea86093953ed1ae9f9623ecc3e4117675c91a",
      "category": "secret_detection",
      "name": "GitLab personal access token",
      "description": "GitLab personal access token has been found in commit 5c124166",
      ...
      "identifiers": [
        {
          "type": "gitleaks_rule_id",
          "name": "Gitleaks rule ID gitlab_personal_access_token",
          "value": "gitlab_personal_access_token"
        }
      ]
    }
    ...
  ]
...
```

구성 예:

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.identifier]
      type = "gitleaks_rule_id"
      value = "gitlab_personal_access_token"
    ...
```

### `[secrets.ruleset.override]` 섹션 {#the-secretsrulesetoverride-section}

`[secrets.ruleset.override]` 섹션을 통해 미리 정의된 규칙의 속성을 오버라이드할 수 있습니다.

| 설정       | 설명                                                                                         |
|---------------|-----------------------------------------------------------------------------------------------------|
| `description` | 문제에 대한 자세한 설명입니다.                                                                |
| `message`     | (지원 중단됨) 문제에 대한 설명입니다.                                                            |
| `name`        | 규칙의 이름입니다.                                                                               |
| `severity`    | 규칙의 심각도입니다. 유효한 옵션은 다음과 같습니다: `Critical`, `High`, `Medium`, `Low`, `Unknown`, `Info` |

> [!note]
> `message`은(는) 여전히 분석기에서 채워지지만 [지원 중단](https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/1d86d5f2e61dc38c775fb0490ee27a45eee4b8b3/vulnerability.go#L22)되었으며 `name` 및 `description`로 대체되었습니다.

구성 예:

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.override]
      severity = "Medium"
      name = "systemd machine-id"
    ...
```

### 커스텀 규칙 형식 {#custom-rule-format}

{{< history >}}

- GitLab 17.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/511321)되었습니다.

{{< /history >}}

커스텀 규칙을 만들 때 [Gitleaks의 표준 규칙 형식](https://github.com/gitleaks/gitleaks?tab=readme-ov-file#configuration)과 추가 GitLab 관련 필드를 모두 사용할 수 있습니다. 각 규칙에 사용 가능한 설정은 다음과 같습니다:

| 설정 | 필수 | 설명 |
|---------|-------------|-------------|
| `title` | 아니요 | 규칙에 대한 커스텀 제목을 설정하는 GitLab 관련 필드입니다. |
| `description` | 예 | 규칙이 감지하는 항목에 대한 자세한 설명입니다. |
| `remediation` | 아니요 | 규칙이 트리거될 때 수정 지침을 제공하는 GitLab 관련 필드입니다. |
| `regex` | 예 | 시크릿을 감지하는 데 사용되는 정규식 패턴입니다. |
| `keywords` | 아니요 | 정규식을 적용하기 전에 콘텐츠를 사전 필터링하는 키워드 목록입니다. |
| `id` | 예 |  규칙의 고유 식별자입니다. |

사용 가능한 모든 필드가 있는 커스텀 규칙의 예:

```toml
[[rules]]
  title = "API Key Detection Rule"
  description = "Detects potential API keys in the codebase"
  remediation = "Rotate the exposed API key and store it in a secure credential manager"
  id = "custom_api_key"
  keywords = ["apikey", "api_key"]
  regex = '''api[_-]key[_-][a-zA-Z0-9]{16,}'''
```

확장 규칙 집합의 규칙과 동일한 ID를 공유하는 커스텀 규칙을 만들면 커스텀 규칙이 우선합니다. 커스텀 규칙의 모든 속성이 확장 규칙의 해당 값을 대체합니다.

커스텀 규칙으로 기본 규칙을 확장하는 예:

```toml
title = "Extension of GitLab's default Gitleaks config"

[extend]
  path = "/gitleaks.toml"

[[rules]]
  title = "Custom API Key Rule"
  description = "Detects custom API key format"
  remediation = "Rotate the exposed API key"
  id = "custom_api_123"
  keywords = ["testing"]
  regex = '''testing-key-[1-9]{3}'''
```

### `[[secrets.passthrough]]` 섹션 {#the-secretspassthrough-section}

`[[secrets.passthrough]]` 섹션을 통해 분석기에 대한 커스텀 구성을 합성할 수 있습니다.

분석기당 최대 20개의 이러한 섹션을 정의할 수 있습니다. 그러면 통과가 통과 체인으로 구성되어 분석기의 미리 정의된 규칙을 대체하거나 확장하는 데 사용할 수 있는 완전한 구성으로 평가됩니다.

통과는 순서대로 평가됩니다. 체인의 뒤쪽에 나열된 통과는 우선순위가 더 높으며 (`mode` 기반) 이전 통과에서 생성한 데이터를 덮어쓰거나 추가할 수 있습니다. 기존 구성을 사용하거나 수정해야 할 때 통과를 사용하세요.

단일 통과로 생성된 구성의 크기는 10MB로 제한됩니다.

| 설정     | 적용 대상     | 설명                                                                                                                                                                   |
|-------------|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`      | 모두            | `file`, `raw`, `git` 또는 `url` 중 하나입니다.                                                                                                                                        |
| `target`    | 모두            | 통과 평가로 쓰인 데이터를 포함할 대상 파일입니다. 비어 있으면 임의의 파일 이름이 사용됩니다.                                                               |
| `mode`      | 모두            | `overwrite`이면 `target` 파일을 덮어씁니다. `append`이면 새 콘텐츠가 `target` 파일에 추가됩니다. `git` 유형은 `overwrite`만 지원합니다. (기본값: `overwrite`) |
| `ref`       | `type = "git"` | 끌어올 브랜치, 태그 또는 SHA의 이름을 포함합니다.                                                                                                                     |
| `subdir`    | `type = "git"` | Git 리포지토리의 하위 디렉터리를 구성 소스로 선택하는 데 사용됩니다.                                                                                              |
| `auth`      | `type = "git"` | [프라이빗 Git 리포지토리에 저장된 구성](configure.md#with-a-private-remote-ruleset)을(를) 사용할 때 사용할 자격 증명을 제공하는 데 사용됩니다.                       |
| `value`     | 모두            | `file`, `url` 및 `git` 유형의 경우 파일 또는 Git 리포지토리의 위치를 정의합니다. `raw` 유형의 경우 인라인 구성을 포함합니다.                            |
| `validator` | 모두            | 통과 평가 후 대상 파일에 대한 유효성 검사기(`xml`, `yaml`, `json`, `toml`)를 명시적으로 호출하는 데 사용됩니다.                                                |

#### 통과 유형 {#passthrough-types}

| 형식   | 설명                                           |
|--------|-------------------------------------------------------|
| `file` | 동일한 Git 리포지토리에 저장된 파일을 사용합니다. |
| `raw`  | 규칙 집합 구성을 인라인으로 제공합니다.             |
| `git`  | 원격 Git 리포지토리에서 구성을 끌어옵니다.  |
| `url`  | HTTP를 사용하여 구성을 가져옵니다.                   |

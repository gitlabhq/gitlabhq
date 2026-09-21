---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 소스 코드용 GitLab 시크릿 검색
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 19.0에서 [실험](../../../../policy/development_stages_support.md)으로 도입되었습니다.
- [GitLab 19.3에서 실험에서 베타로 변경되었습니다.](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240774)

{{< /history >}}

소스 코드용 GitLab 시크릿 탐지는 [파이프라인 시크릿 탐지](../pipeline/_index.md)의 대체 분석기입니다. 기본 분석기와 동일한 `secret_detection` CI/CD 작업에서 실행되지만 일반 시크릿을 포함한 추가 시크릿 탐색을 제공합니다.

## 소스 코드용 GitLab 시크릿 검색이 다른 점 {#how-gitlab-secret-scanning-for-source-code-differs}

분석기는 GitLab에서 개발한 독점 검사 엔진을 사용합니다. 패턴 일치에 의존하는 대신 휴리스틱을 사용하여 [표준 GitLab 시크릿 탐지 규칙](../detected_secrets.md)을 넘어 구조화되지 않은 시크릿과 비밀번호를 탐지합니다. 여러 휴리스틱 기법을 결합하여 오탐을 줄입니다.

베타 기간 동안 분석기는 다음을 제공합니다.

- 일반 시크릿 탐지: 표준 GitLab 시크릿 탐지 규칙 범위를 넘어 컨텍스트에 기반한 시크릿을 포함하여 구조화되지 않은 시크릿과 비밀번호를 식별합니다.
- 오탐 감소: 여러 휴리스틱 기법을 결합하여 시크릿과 주변 컨텍스트를 모두 평가하여 검사 결과의 노이즈를 줄입니다.
- 인코딩된 시크릿 탐지: 일반 텍스트로 저장하는 대신 인코딩된 시크릿을 탐지합니다. Base64 인코딩 문자열을 지원합니다.

## 분석기 활성화 {#turn-on-the-analyzer}

사전 요구 사항:

- [`docker`](https://docs.gitlab.com/runner/executors/docker/) 또는 [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/) 실행기가 있는 Linux 기반 러너가 있습니다. GitLab.com의 호스팅된 러너를 사용하는 경우 기본적으로 사용으로 설정되어 있습니다.
  - Windows 러너는 지원되지 않습니다.
  - amd64 이외의 CPU 아키텍처는 지원되지 않습니다.
- `.gitlab-ci.yml` 파일이 있으며 `test` 스테이지를 포함합니다.

분석기를 활성화하려면 최신 시크릿 탐지 템플릿을 사용하고 `SECRET_DETECTION_ENABLE_GSS` CI/CD 변수를 `true`로 설정합니다.

```yaml
include:
  - template: Jobs/Secret-Detection.latest.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_ENABLE_GSS: "true"
```

> [!note]
> 분석기는 높은 신뢰도의 결과만 보고합니다. 중간 및 낮은 신뢰도 결과는 취약성 보고서의 노이즈를 최소화하기 위해 의도적으로 필터링됩니다. 예상 시크릿이 결과에 나타나지 않으면 중간 또는 낮은 신뢰도로 플래그 지정되었을 가능성이 높습니다. 이 동작은 분석기가 검사의 신뢰도 수준 구성을 지원하고 취약성 보고서 UI가 신뢰도 수준별로 결과를 필터링하는 것을 지원할 때까지 유지됩니다. 모든 결과에 대한 다운로드 가능한 아티팩트가 [이슈 611174](https://gitlab.com/gitlab-org/gitlab/-/work_items/611174)에서 제안되었습니다.

### 처음으로 분석기 실행 {#run-the-analyzer-for-the-first-time}

소스 코드용 GitLab 시크릿 검사를 처음 실행할 때 과거 검사를 실행해야 합니다. 분석기는 모든 커밋을 검사하고 [파이프라인 시크릿 탐지](../pipeline/_index.md)에서 기존 결과를 인수하는 것을 포함하여 가장 최근의 결과로 취약성 보고서를 업데이트합니다.

과거 검사를 실행하려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. **새 파이프라인**을 선택합니다.
1. CI/CD 변수를 추가합니다.
   1. 드롭다운 목록에서 **변수**를 선택합니다.
   1. **변수 키 입력** 상자에 `SECRET_DETECTION_HISTORIC_SCAN`를 입력합니다.
   1. **변수 값 입력** 상자에 `true`를 입력합니다.
1. **새 파이프라인**을 선택합니다.

`SECRET_DETECTION_HISTORIC_SCAN`을 `true`로 설정한 경우 `.gitlab-ci.yml` 파일에서 검사이 완료된 후 변수를 제거합니다. 그렇지 않으면 모든 파이프라인이 전체 리포지토리 기록을 검사합니다.

## 기본 구성 {#default-configuration}

분석기를 활성화하면 다음 구성으로 실행됩니다.

| 설정 | 기본값 | 변경 방법 |
|---------|---------|---------------|
| 일반 시크릿 탐지 | 켜짐 | `SECRET_DETECTION_GSS_ENABLE_GENERIC_SECRETS`을 `false`로 설정합니다. [일반 시크릿](#generic-secrets)을 참조합니다. |
| 오탐 감소 | 켜짐 | 구성 불가능합니다. |
| 규칙 | 기본 GitLab 시크릿 탐지 규칙 집합 | [규칙 사용자 지정](#customize-rules)을 참조합니다. |

## 일반 시크릿 {#generic-secrets}

분석기가 활성화되면 일반 시크릿 탐지가 기본적으로 활성화됩니다.

일반 시크릿 탐지를 비활성화하려면 `SECRET_DETECTION_GSS_ENABLE_GENERIC_SECRETS` CI/CD 변수를 `false`로 설정합니다.

```yaml
include:
  - template: Jobs/Secret-Detection.latest.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_ENABLE_GSS: "true"
    SECRET_DETECTION_GSS_ENABLE_GENERIC_SECRETS: "false"
```

## 규칙 사용자 지정 {#customize-rules}

리포지토리에서 `.gitlab/secret-detection-ruleset.toml` 파일을 사용하여 소스 코드용 GitLab 시크릿 검색에 검사 사용자 지정을 적용할 수 있습니다. 이 파일을 만들려면 [규칙 집합 구성 파일 만들기](../pipeline/configure.md#create-a-ruleset-configuration-file)를 참조합니다.

다음을 수행할 수 있습니다.

- 기본 규칙 집합에서 [규칙을 사용 중지](../pipeline/configure.md#disable-a-rule)합니다.
- 고유한 규칙으로 [기본 규칙 집합 확장](../pipeline/configure.md#extend-the-default-ruleset)합니다. 새 규칙은 [사용자 지정 규칙 형식](../pipeline/custom_rulesets_schema.md#custom-rule-format)을 따라야 합니다.
- 허용 목록으로 정규식 또는 파일 경로별로 시크릿을 무시합니다.

예를 들어 기본 규칙 집합을 확장하고 정규식 또는 파일 경로별로 시크릿을 무시하려면 확장 구성 파일을 가리키는 `file` 패스스루를 사용합니다. 패스스루를 `.gitlab/secret-detection-ruleset.toml` 파일에 추가합니다.

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gss.toml"
    value  = "extended-gss-config.toml"
```

확장 구성 파일에서 `[extend]`을 사용하여 기본 규칙 집합을 빌드하고 결과를 무시하기 위해 하나 이상의 `[[allowlists]]` 테이블을 사용합니다. 각 허용 목록은 `regexes`로 시크릿 값을 일치시키고 `paths`로 파일 경로를 일치시킬 수 있습니다.

```toml
# extended-gss-config.toml
[extend]
# Extends the default packaged ruleset. Do not change the path.
path = "/gitleaks.toml"

[[allowlists]]
  description = "Ignore known test values and fixture paths"
  regexes = [
    '''glpat-[0-9a-zA-Z_\-]{20}''',
  ]
  paths = [
    '''spec/fixtures/.*''',
  ]
```

허용 목록의 `regexes`과 `paths`는 논리적 OR로 결합됩니다. 결과의 시크릿이 `regexes` 중 하나와 일치하거나 파일 경로가 `paths` 중 하나와 일치하면 결과가 무시됩니다.

## 기본 분석기에서 마이그레이션 {#migrate-from-the-default-analyzer}

소스 코드용 GitLab 시크릿 검색은 `secret_detection` 작업의 기본 분석기를 대체합니다. `SECRET_DETECTION_ENABLE_GSS` CI/CD 변수가 `true`로 설정되면 소스 코드용 GitLab 시크릿 검색만 실행됩니다.

기본 분석기에서 마이그레이션하려면 다음을 수행합니다.

1. 기능 브랜치에서 [소스 코드에 GitLab 시크릿 검사를 활성화](#turn-on-the-analyzer)합니다.
1. 파이프라인을 실행하고 기본 분석기를 사용하는 검사에 대한 결과를 비교합니다.
1. 규칙 집합 사용자 지정을 검토합니다. 사용 가능한 옵션은 [규칙 사용자 지정](#customize-rules)을 참조합니다.
1. 결과에 만족하면 기본 브랜치에서 분석기를 켭니다.

### 마이그레이션 후 기존 결과 {#existing-findings-after-migration}

기본 브랜치에서 소스 코드용 GitLab 시크릿 검사를 활성화하면 두 분석기 모두가 탐지하는 시크릿을 이 분석기가 담당합니다. 이전에 기본 분석기에서 보고한 취약성에 대한 결과를 일치시킵니다. 기존 취약성 기록은 새 결과로 다시 보고되는 대신 이월됩니다.

기본 분석기에서 이전에 보고했지만 소스 코드용 GitLab 시크릿 검색이 탐지하지 않은 결과는 변경되지 않습니다.

## FIPS 사용 이미지 {#fips-enabled-images}

소스 코드용 GitLab 시크릿 검색이 베타 상태인 동안 FIPS 지원 이미지가 게시되지 않습니다. `SECRET_DETECTION_IMAGE_SUFFIX` CI/CD 변수를 `-fips`로 설정하면 이미지를 가져올 수 없어 `secret_detection` 작업이 실패합니다.

FIPS 지원 이미지로 검사하려면 [파이프라인 시크릿 탐지](../pipeline/_index.md#fips-enabled-images)에 기본 분석기를 사용합니다.

## 관련 항목 {#related-topics}

- [파이프라인 시크릿 탐지 사용자 지정](../pipeline/configure.md)

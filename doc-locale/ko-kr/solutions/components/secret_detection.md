---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: 중앙 집중식 사용자 정의 규칙 집합을 사용하여 최상위 그룹의 모든 프로젝트에서 PII 및 평문 비밀번호를 자동으로 감지하도록 GitLab 시크릿 검색을 구성합니다.
title: 시크릿 검색
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## 시작하기 {#getting-started}

### 솔루션 구성 요소 다운로드 {#download-the-solution-component}

1. 계정 팀으로부터 초대 코드를 입수합니다.
1. 초대 코드를 사용하여 [솔루션 구성 요소 웹스토어](https://cloud.gitlab-accelerator-marketplace.com)에서 솔루션 구성 요소를 다운로드합니다.

### 전제 조건 {#prerequisites}

- GitLab Ultimate 티어
- GitLab 인스턴스 또는 그룹에 대한 관리자 액세스 권한
- 프로젝트에 대해 [시크릿 검색](../../user/application_security/secret_detection/_index.md)이 활성화됨

## 시크릿 검색 사용자 정의 규칙 구성 {#configure-secret-detection-custom-rules}

이 가이드는 글로벌 수준에서 시크릿 검색 정책을 구현하는 데 도움이 됩니다. 이 솔루션은 기본 시크릿 검색 규칙을 확장하여 사회 보장 번호 및 평문 비밀번호와 같은 PII 데이터 요소의 감지를 포함합니다. 규칙 확장은 원격 규칙 집합으로 간주됩니다.

### 사용자 정의 규칙 집합 구성 {#configure-custom-ruleset}

다음 단계를 사용하여 사용자 정의 규칙 집합을 설정할 수 있습니다.

1. 최상위 그룹 `Secret Detection`을(를) 만듭니다.
1. 다운로드한 구성 요소에서 `Secret Detection Custom Ruleset` 프로젝트를 새로 만든 `Secret Detection` 그룹으로 복사합니다.

이 사용자 정의 규칙 집합은 GitLab 미리 빌드된 규칙을 확장합니다. 확장은 다음을 포함한 시크릿을 감지하고 알릴 수 있습니다:

- PII 데이터 요소: 사회 보장 번호
- 평문 비밀번호입니다.

#### 사용자 정의 규칙 집합 파일 {#custom-ruleset-file}

사용자 정의 규칙 집합은 `.gitlab/secret-detection-ruleset.toml`에 정의됩니다. 규칙은 `regex`을(를) 사용하여 정의할 수 있습니다.

#### PII 데이터 요소 감지 {#pii-data-element-detection}

PII 데이터 요소 감지를 위한 확장 규칙

```toml
[[rules]]
id = "ssn"
description = "Social Security Number"
regex = "[0-9]{3}-[0-9]{2}-[0-9]{4}"
tags = ["ssn", "social-security-number"]
keywords = ["ssn"]
```

#### 평문 비밀번호 {#password-in-plain-text}

평문 비밀번호에 대한 확장 규칙

```toml
[[rules]]
id = "password-secret"
description = "Detect secrets starting with Password or PASSWORD"
regex = "(?i)Password[:=]\\s*['\"]?[^'\"]+['\"]?"
tags = ["password", "secret"]
keywords = ["password", "PASSWORD"]
```

### 정의된 사용자 정의 규칙 집합 액세스 {#access-defined-custom-ruleset}

사용자 정의 규칙 집합에 액세스하려면 봇 사용자를 생성하는 그룹 액세스 토큰을 만들어야 합니다. 봇 사용자는 글로벌 정책으로 시크릿 검색을 실행하는 모든 프로젝트에서 사용자 정의 규칙 집합을 인증하고 액세스하는 데 사용될 수 있습니다.

액세스 및 인증을 설정하려면 다음 단계를 따르세요:

1. 그룹 토큰을 만듭니다: 그룹 `Secret Detection`에서 `Settings` 메뉴 옵션 아래에 그룹 액세스 토큰 `Secret Detection Group Token`을(를) 만들고, 토큰 `reporter` 역할에 `read_repository` 액세스 권한을 부여합니다.

![보안 대시보드](img/secret_detection_group_token_v17_9.png)

1. 그룹 변수를 만듭니다: 토큰 값을 복사하고 안전하게 저장합니다. `Settings` 메뉴 옵션 아래에 그룹 변수를 추가하고 `SECRET_DETECTION_GROUP_TOKEN`을(를) 토큰 값의 키로 설정합니다.
1. 그룹 토큰 봇 사용자를 가져옵니다: 같은 그룹에서 `manage` 메뉴 옵션으로 이동하여 `member`을(를) 선택하고 그룹 액세스 토큰 `Secrete Detection Group Token`에 대한 해당 봇 사용자를 찾습니다. `@group_[group_id]_bot_[random_number]` 형식의 그룹에 대한 봇 사용자를 나타내는 값을 복사합니다.

![시크릿 검색 그룹 토큰 봇](img/secret_detection_group_token_bot_v17_9.png)

## 구현 가이드 {#implementation-guide}

이 가이드는 중앙 집중식 사용자 정의 규칙 집합을 사용하여 모든 프로젝트에 대해 시크릿 검색을 실행하도록 정책을 구성하는 단계를 다룹니다.

### 시크릿 검색 정책 구성 {#configure-secret-detection-policy}

시크릿 검색을 강제되는 글로벌 정책으로 파이프라인에서 자동으로 실행하려면 최상위 수준에서 정책을 설정합니다(이 경우 최상위 그룹의 경우). 새 시크릿 검색 정책을 만들려면:

1. 정책을 만듭니다: 같은 그룹 `Secret Detection`에서 해당 그룹의 **보안** > **정책** 페이지로 이동합니다.
1. **새 정책**을(를) 선택합니다.
1. **검사 실행 정책**을 선택합니다.
1. 정책을 구성합니다: 정책 이름을 `Secret Detection Policy`으로 지정하고 설명을 입력하고 `Secret Detection` 스캔을 선택합니다.
1. **정책 범위**를 "이 그룹의 모든 프로젝트"(옵션으로 예외 설정) 또는 "특정 프로젝트"(드롭다운에서 프로젝트 선택)을 선택하여 설정합니다.
1. **조치** 섹션에서 시크릿 검색이 기본값으로 표시됩니다.
1. **조건** 섹션에서, 모든 커밋마다 실행하는 대신 일정에 따라 스캔을 실행하려면 선택적으로 "Triggers:"를 "Schedules:"로 변경할 수 있습니다.
1. 사용자 정의 규칙 집합에 대한 액세스를 설정합니다: 봇 사용자, 그룹 변수 및 사용자 정의 규칙 집합 프로젝트의 URL 값으로 CI 변수를 추가합니다.

   사용자 정의 규칙 집합은 다른 프로젝트에서 호스팅되며 원격 규칙 집합으로 간주되므로 `SECRET_DETECTION_RULESET_GIT_REFERENCE`을(를) 사용해야 합니다.

   ```yaml
   variables:
     SECRET_DETECTION_RULESET_GIT_REFERENCE: "group_[group_id]_bot_[random_number]:$SECRET_DETECTION_GROUP_TOKEN@[custom ruleset project URL]"
     SECRET_DETECTION_HISTORIC_SCAN: "true"
   ```

UI 구성은 이 화면에 표시됩니다: ![보안 대시보드](img/secret_detection_policy_v17_9.png) 이 CI 변수에 대한 자세한 정보는 [자세한 내용은 이 문서를 참조](../../user/application_security/secret_detection/pipeline/configure.md#with-a-remote-ruleset)하세요.

1. **정책 생성**을 클릭합니다.

### 완전한 정책 구성 {#complete-policy-configuration}

정책을 만들 때 참조용으로 다음은 완전한 정책 구성입니다:

```yaml
---
scan_execution_policy:
- name: Scan execution for secret detection with custom rules
  description: ''
  enabled: true
  policy_scope:
    projects:
      excluding: []
  rules:
  - type: pipeline
    branches:
    - "*"
  actions:
  - scan: secret_detection
    variables:
      SECRET_DETECTION_RULESET_GIT_REFERENCE: "@group_[group_id]_bot_[random_number]:$SECRET_DETECTION_GROUP_TOKEN@gitlab.com/example_group/secret-detection/secret-detection-custom-ruleset"
      SECRET_DETECTION_HISTORIC_SCAN: 'true'
  skip_ci:
    allowed: true
    allowlist:
      users: []
approval_policy: []
```

## 작동 방식 {#how-it-works}

정책이 실행되면 글로벌 정책과 연결된 모든 프로젝트는 `secret detect` 작업이(가) `secret_detection_0` 작업으로 파이프라인에서 자동으로 실행됩니다. ![보안 대시보드](img/secret_detection_job_v17_9.png)

시크릿이 감지되고 표시됩니다. 머지 리퀘스트가 있는 경우 새로운 시크릿이 **리포트** 탭에 표시됩니다. 기본 브랜치가 병합된 경우 다음과 같이 보안 취약성 보고서에 표시됩니다: ![시크릿 검색 비밀번호 취약성 결과](img/secret_detection_pwd_vuln_v17_9.png)

다음은 평문 비밀번호의 예입니다: ![시크릿 검색 비밀번호 결과](img/secret_detection_pwd_v17_9.png)

## 문제 해결 {#troubleshooting}

### 정책이 적용되지 않음 {#policy-not-applying}

수정한 보안 정책 프로젝트가 그룹에 올바르게 연결되어 있는지 확인합니다. 자세한 내용은 [보안 정책 프로젝트에 링크](../../user/application_security/policies/enforcement/security_policy_projects.md#link-to-a-security-policy-project)를 참조하세요.

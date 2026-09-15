---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 토큰 개요
description: 다양한 인증 토큰과 보안상 영향을 이해합니다.
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 문서는 GitLab에서 사용되는 토큰, 목적 및 해당하는 경우 보안 지침을 나열합니다.

## 보안 고려사항 {#security-considerations}

토큰을 안전하게 보관하려면:

- 토큰을 비밀번호처럼 취급하고 안전하게 보관합니다.
- 범위가 제한된 토큰을 만들 때 우발적으로 유출된 토큰의 영향을 줄이기 위해 가능한 한 가장 제한된 범위를 사용합니다.
  - 서로 다른 프로세스에서 서로 다른 범위가 필요한 경우(예: `read` 및 `write`), 각 범위에 대해 별도의 토큰을 사용하는 것을 고려하세요. 한 토큰이 유출되면 전체 API 액세스와 같은 광범위한 범위를 가진 단일 토큰보다 적은 액세스 권한을 제공합니다.
- 토큰을 만들 때:
  - 아래의 [토큰 명명 지침](#token-naming-guidance)을 따르는 이름을 선택합니다.
  - 작업이 완료될 때 만료되는 토큰을 설정하는 것을 고려합니다. 예를 들어 일회성 가져오기를 수행해야 하는 경우 토큰이 몇 시간 후에 만료되도록 설정합니다.
  - 관련 URL을 포함한 추가 컨텍스트를 제공하는 설명을 추가합니다.
- URL 대신 헤더로 토큰을 전달합니다:
  - 개인, 프로젝트 및 그룹 액세스 토큰에는 `PRIVATE-TOKEN`을(를) 사용합니다.
  - 작업 토큰에는 `JOB-TOKEN`을(를) 사용합니다.
- 데모 환경이 있는 경우 프로젝트에 대한 비디오를 녹화하거나 블로그 게시물을 게시한 후 모든 토큰을 취소합니다.
- [Git credential storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)를 사용하여 토큰을 저장할 수 있습니다.
- 정기적으로 모든 유형의 모든 활성 액세스 토큰을 검토하고 필요하지 않은 토큰을 취소합니다.

다음을 수행하지 마세요:

- URL에 토큰을 추가합니다:
  - URL의 토큰으로 클론하거나 원격을 추가할 때 Git은 URL을 해당 `.git/config` 파일에 평문으로 작성합니다.
  - URL은 종종 프록시 및 애플리케이션 서버에 의해 로깅되므로 해당 자격 증명이 시스템 관리자에게 유출될 수 있습니다.
- 프로젝트에 평문으로 토큰을 저장합니다.
  - 토큰이 GitLab CI/CD의 외부 비밀인 경우 [CI/CD에서 외부 비밀 사용](../../ci/secrets/_index.md) 방법을 검토합니다.
- 이슈, 머지 리퀘스트 설명, 주석 또는 기타 자유 텍스트 입력에 코드, 콘솔 명령 또는 로그 출력을 붙여넣을 때 토큰을 포함합니다.
- 콘솔 로그 또는 아티팩트에 자격 증명을 로깅합니다. 자격 증명을 [보호](../../ci/variables/_index.md#protect-a-cicd-variable)하고 [마스킹](../../ci/variables/_index.md#mask-a-cicd-variable)하는 것을 고려합니다.

### 토큰 명명 지침 {#token-naming-guidance}

일관된 명명 규칙을 사용하면 액세스 토큰을 감사하고, 목적을 파악하고, 각 토큰을 순환하거나 취소할 때의 영향을 평가하기가 더 쉬워집니다.

명명 규칙은 팀에 따라 다르지만 유용한 규칙은 다음 질문에 답합니다:

- 토큰은 어떤 작업을 수행합니까? 예: `ci-deploy` 또는 `api-read`
- 토큰이 어떤 리소스 또는 서비스를 대상으로 하는가? 예: `gitlab` 또는 `terraform`
- 토큰은 어느 환경이나 소유자와 연결되어 있는가? 예: `production` 또는 `auth-team`

예를 들어:

| 토큰 이름 | 목적 |
| --- | --- |
| `ci-deploy-gitlab-production` | 프로덕션 환경의 GitLab 프로젝트에 대한 CI/CD 배포 작업 |
| `api-read-reporting-dashboard` | 보고 대시보드에 대한 읽기 전용 API 액세스 |
| `automation-sync-vulnmapper-staging` | 스테이징 환경에서 데이터를 동기화하는 자동화 스크립트 |

- 구체적으로 지정합니다. `test`, `mytoken`, `token1`, `GITLAB_API_TOKEN`, `API_TOKEN` 또는 `default`과 같은 일반적인 이름은 피합니다. 감사 중에 토큰의 목적을 식별하는 것이 불가능합니다.
- 사용하는 시스템 또는 도구를 포함합니다. 토큰이 특정 애플리케이션, 스크립트 또는 통합에서 사용되는 경우 해당 이름을 포함합니다. 예: `terraform-state-backend` 또는 `grafana-metrics-reader`.
- 환경을 포함합니다. 해당하는 경우 토큰이 `production`, `staging` 또는 `development`을(를) 대상으로 하는지 표시합니다. 이는 프로덕션 토큰이 낮은 환경에서 실수로 사용되는 것을 방지합니다.
- 민감한 정보 임베딩을 피합니다. 토큰 이름에 사용자 이름, 이메일 주소 또는 기타 개인 식별 정보(PII)를 포함하지 마세요. 토큰 이름은 감사 로그 및 UI에서 볼 수 있기 때문입니다.
- 표준화된 대소문자 및 구두점 규칙을 설정합니다. 일관된 대소문자 및 구분자를 사용하면 토큰을 더 쉽게 읽고 검색할 수 있습니다. 예: 언더스코어(_)보다 하이픈(-)을 사용합니다.
- 설명 필드를 사용합니다. 토큰 설명 필드를 사용하면 관련 이슈로의 링크 또는 토큰을 사용하는 팀의 이름과 같은 추가 세부 정보를 추가할 수 있습니다.

### CI/CD의 토큰 {#tokens-in-cicd}

광범위한 범위 때문에 가능한 한 개인 액세스 토큰을 CI/CD 변수로 사용하지 마세요. CI/CD 작업에서 다른 리소스에 대한 액세스가 필요한 경우 다음 중 하나를 사용하세요. 액세스 범위가 가장 낮은 것부터 가장 높은 것까지 정렬됨:

1. 작업 토큰(가장 낮은 액세스 범위)
1. 프로젝트 토큰
1. 그룹 토큰

[CI/CD 변수 보안](../../ci/variables/_index.md#cicd-variable-security)에 대한 추가 권장 사항은 다음을 포함합니다:

- 모든 자격 증명에 [비밀 저장소](../../ci/pipeline_security/_index.md#secrets-storage)를 사용합니다.
- 민감한 정보를 포함하는 CI/CD 변수는 [보호](../../ci/variables/_index.md#protect-a-cicd-variable)되고 [마스킹](../../ci/variables/_index.md#mask-a-cicd-variable)되고 [숨겨져](../../ci/variables/_index.md#hide-a-cicd-variable)야 합니다.

## 개인 액세스 토큰 {#personal-access-tokens}

[개인 액세스 토큰](../../user/profile/personal_access_tokens.md)을(를) 만들어 다음으로 인증할 수 있습니다:

- GitLab API
- GitLab 리포지토리
- GitLab 컨테이너 레지스트리

개인 액세스 토큰의 범위 및 만료 날짜를 제한할 수 있습니다. 기본적으로 해당 토큰을 만든 사용자의 권한을 상속합니다.

개인 액세스 토큰 API를 사용하여 [개인 액세스 토큰 순환](../../api/personal_access_tokens.md#rotate-a-personal-access-token)과 같은 작업을 프로그래밍 방식으로 수행할 수 있습니다.

개인 액세스 토큰이 곧 만료될 때 [이메일을 수신](../../user/profile/personal_access_tokens.md#personal-access-token-expiry-emails)합니다.

권한이 필요한 CI/CD 작업을 고려할 때 특히 CI/CD 변수로 저장된 경우 개인 액세스 토큰 사용을 피합니다. CI/CD 작업 토큰 및 프로젝트 액세스 토큰은 훨씬 더 적은 위험으로 같은 결과를 달성할 수 있습니다.

## OAuth 2.0 토큰 {#oauth-20-tokens}

GitLab은 [OAuth 2.0 제공자](../../api/oauth2.md)로 작동하여 다른 서비스가 사용자를 대신하여 GitLab API에 액세스할 수 있도록 합니다.

OAuth 2.0 토큰의 범위 및 수명을 제한할 수 있습니다.

## 사칭 토큰 {#impersonation-tokens}

[사칭 토큰](../../api/rest/authentication.md#impersonation-tokens)은 특수한 유형의 개인 액세스 토큰입니다. 관리자만 특정 사용자를 위해 만들 수 있습니다. 사칭 토큰은 특정 사용자로서 GitLab API, 리포지토리 및 GitLab 컨테이너 레지스트리에 인증하는 애플리케이션 또는 스크립트를 빌드하는 데 도움이 될 수 있습니다.

사칭 토큰의 범위를 제한하고 만료 날짜를 설정할 수 있습니다.

## 프로젝트 액세스 토큰 {#project-access-tokens}

[프로젝트 액세스 토큰](../../user/project/settings/project_access_tokens.md)은 프로젝트로 범위가 지정됩니다. 개인 액세스 토큰처럼 다음으로 인증하는 데 사용할 수 있습니다:

- GitLab API
- GitLab 리포지토리
- GitLab 컨테이너 레지스트리

프로젝트 액세스 토큰의 범위 및 만료 날짜를 제한할 수 있습니다. 프로젝트 액세스 토큰을 만들 때 GitLab은 [프로젝트용 봇 사용자](../../user/project/settings/project_access_tokens.md#bot-users-for-projects)를 만듭니다. 프로젝트용 봇 사용자는 서비스 계정이며 라이선스가 있는 사용자로 계산되지 않습니다.

[프로젝트 액세스 토큰 API](../../api/project_access_tokens.md)를 사용하여 [프로젝트 액세스 토큰 순환](../../api/project_access_tokens.md#rotate-a-project-access-token)과 같은 작업을 프로그래밍 방식으로 수행할 수 있습니다.

유지 관리자 또는 소유자 역할을 가진 프로젝트의 구성원은 프로젝트 액세스 토큰이 거의 만료될 때 [이메일을 수신](../../user/project/settings/project_access_tokens.md#project-access-token-expiry-emails)합니다.

## 그룹 액세스 토큰 {#group-access-tokens}

[그룹 액세스 토큰](../../user/group/settings/group_access_tokens.md)은 그룹으로 범위가 지정됩니다. 개인 액세스 토큰처럼 다음으로 인증하는 데 사용할 수 있습니다:

- GitLab API
- GitLab 리포지토리
- GitLab 컨테이너 레지스트리

그룹 액세스 토큰의 범위 및 만료 날짜를 제한할 수 있습니다. 그룹 액세스 토큰을 만들 때 GitLab은 [그룹용 봇 사용자](../../user/group/settings/group_access_tokens.md#bot-users-for-groups)를 만듭니다. 그룹용 봇 사용자는 서비스 계정이며 라이선스가 있는 사용자로 계산되지 않습니다.

[그룹 액세스 토큰 API](../../api/group_access_tokens.md)를 사용하여 [그룹 액세스 토큰 순환](../../api/group_access_tokens.md#rotate-a-group-access-token)과 같은 작업을 프로그래밍 방식으로 수행할 수 있습니다.

소유자 역할을 가진 그룹의 구성원은 그룹 액세스 토큰이 거의 만료될 때 [이메일을 수신](../../user/group/settings/group_access_tokens.md#group-access-token-expiry-emails)합니다.

## 배포 토큰 {#deploy-tokens}

[배포 토큰](../../user/project/deploy_tokens/_index.md)을(를) 사용하면 사용자 및 비밀번호 없이 프로젝트의 패키지 및 컨테이너 레지스트리 이미지를 클론, 푸시 및 풀 할 수 있습니다. 배포 토큰은 GitLab API와 함께 사용할 수 없습니다.

배포 토큰을(를) 관리하려면 최소한 유지 관리자 역할을 가진 프로젝트의 구성원이어야 합니다.

## 배포 키 {#deploy-keys}

[배포 키](../../user/project/deploy_keys/_index.md)는 SSH 공개 키를 GitLab 인스턴스로 가져오는 방식으로 리포지토리에 대한 읽기 전용 또는 읽기-쓰기 액세스를 허용합니다. 배포 키는 GitLab API 또는 레지스트리와 함께 사용할 수 없습니다.

배포 키를 사용하여 가짜 사용자 계정을 설정하지 않고도 리포지토리를 지속적 통합 서버에 클론할 수 있습니다.

프로젝트에 대한 배포 키를 추가하거나 활성화하려면 최소한 유지 관리자 역할이 있어야 합니다.

## 러너 인증 토큰 {#runner-authentication-tokens}

러너를 등록하려면 러너 등록 토큰 대신 러너 인증 토큰을 사용할 수 있습니다. 러너 등록 토큰은 [사용 중지되었습니다](../../ci/runners/new_creation_workflow.md).

러너 및 구성을 만든 후 러너를 등록하는 데 사용하는 러너 인증 토큰을 받습니다. 러너 인증 토큰은 러너를 구성하는 데 사용하는 [`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration/) 파일에 로컬로 저장됩니다.

러너는 러너 인증 토큰을 사용하여 작업 큐에서 작업을 선택할 때 GitLab으로 인증합니다. 러너가 GitLab으로 인증한 후 러너는 [작업 토큰](../../ci/jobs/ci_job_token.md)을(를) 수신하여 작업을 실행하는 데 사용합니다.

러너 인증 토큰은 러너 머신에 남아 있습니다. 다음 실행기의 실행 환경은 작업 토큰에만 액세스할 수 있으며 러너 인증 토큰에는 액세스할 수 없습니다:

- Docker Machine
- Kubernetes
- VirtualBox
- Parallels
- SSH

러너의 파일 시스템에 대한 악의적인 액세스로 인해 `config.toml` 파일 및 러너 인증 토큰이 노출될 수 있습니다. 공격자는 러너 인증 토큰을 사용하여 [러너를 클론](https://docs.gitlab.com/runner/security/#cloning-a-runner)할 수 있습니다.

러너 API를 사용하여 [러너 인증 토큰 순환 또는 취소](../../api/runners.md#reset-runners-authentication-token-by-using-the-current-token)를 수행할 수 있습니다.

## 러너 등록 토큰(레거시) {#runner-registration-tokens-legacy}

> [!warning]
> 러너 등록 토큰을 전달하는 옵션 및 특정 구성 인수 지원은 레거시로 간주되며 권장되지 않습니다. [러너 생성 워크플로우](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하여 러너를 등록하는 인증 토큰을 생성합니다. 이 프로세스는 러너 소유권의 완전한 추적 가능성을 제공하고 러너 플릿의 보안을 향상시킵니다. GitLab은 새로운 [GitLab 러너 토큰 아키텍처](../../ci/runners/new_creation_workflow.md)를 구현했으며, 이는 러너를 등록하는 새로운 방법을 소개하고 러너 등록 토큰을 제거합니다.

러너 등록 토큰은 GitLab으로 [등록](https://docs.gitlab.com/runner/register/)하는 [러너](https://docs.gitlab.com/runner/)에 사용됩니다. 그룹 또는 프로젝트 소유자 또는 인스턴스 관리자는 GitLab 사용자 인터페이스를 통해 해당 토큰을 얻을 수 있습니다. 등록 토큰은 러너 등록으로 제한되며 추가 범위가 없습니다.

러너 등록 토큰을 사용하여 프로젝트 또는 그룹에서 작업을 실행하는 러너를 추가할 수 있습니다. 러너는 프로젝트의 코드에 액세스할 수 있으므로 프로젝트 또는 그룹에 권한을 할당할 때 주의하세요.

## CI/CD 작업 토큰 {#cicd-job-tokens}

[CI/CD](../../ci/jobs/ci_job_token.md) 작업 토큰은 작업의 기간 동안만 유효한 단기 토큰입니다. CI/CD 작업에 제한된 수의 API 엔드포인트에 대한 액세스 권한을 부여합니다. API 인증은 작업을 트리거하는 사용자의 권한을 사용하여 작업 토큰을 사용합니다.

작업 토큰은 짧은 수명과 제한된 범위로 보호됩니다. 이 토큰은 여러 작업이 같은 머신(예: [쉘 러너](https://docs.gitlab.com/runner/security/#usage-of-shell-executor))에서 실행될 경우 유출될 수 있습니다. [프로젝트 허용 목록](../../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)을(를) 사용하여 작업 토큰이 액세스할 수 있는 것을 더욱 제한할 수 있습니다.

Docker Machine 러너에서 [`MaxBuilds=1`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runnersmachine-section)를 구성하여 러너 머신이 한 개의 빌드만 실행하고 그 후 제거되도록 해야 합니다. 프로비저닝에 시간이 걸리므로 이 구성은 성능에 영향을 줄 수 있습니다.

## GitLab 클러스터 에이전트 토큰 {#gitlab-cluster-agent-tokens}

[Kubernetes용 GitLab 에이전트를 등록](../../user/clusters/agent/install/_index.md#register-the-agent-with-gitlab)할 때 GitLab은 클러스터 에이전트를 GitLab으로 인증하기 위한 액세스 토큰을 생성합니다.

이 클러스터 에이전트 토큰을 취소하려면 다음 중 하나를 수행할 수 있습니다:

- [에이전트 API](../../api/cluster_agents.md#revoke-an-agent-token)로 토큰을 취소합니다.
- [토큰을 재설정](../../user/clusters/agent/work_with_agent.md#reset-the-agent-token)합니다.

두 방법 모두 토큰, 에이전트 및 프로젝트 ID를 알아야 합니다. 이 정보를 찾으려면 [Rails 콘솔](../../administration/operations/rails_console.md)을(를) 사용합니다:

```ruby
# Find token ID
Clusters::AgentToken.find_by_token('glagent-xxx').id

# Find agent ID
Clusters::AgentToken.find_by_token('glagent-xxx').agent.id
=> 1234

# Find project ID
Clusters::AgentToken.find_by_token('glagent-xxx').agent.project_id
=> 12345
```

Rails 콘솔에서 직접 토큰을 취소할 수도 있습니다:

```ruby
# Revoke token with RevokeService, including generating an audit event
Clusters::AgentTokens::RevokeService.new(token: Clusters::AgentToken.find_by_token('glagent-xxx'), current_user: User.find_by_username('admin-user')).execute

# Revoke token manually, which does not generate an audit event
Clusters::AgentToken.find_by_token('glagent-xxx').revoke!
```

## 기타 토큰 {#other-tokens}

### 피드 토큰 {#feed-token}

각 사용자는 만료되지 않는 장기 피드 토큰을 가집니다. 이 토큰을 사용하여 다음으로 인증합니다:

- RSS 리더, 개인화된 RSS 피드를 로드합니다.
- 캘린더 애플리케이션, 개인화된 캘린더를 로드합니다.

이 토큰을 사용하여 다른 데이터에 액세스할 수 없습니다.

사용자가 범위가 지정된 피드 토큰을 모든 피드에 사용할 수 있습니다. 하지만 피드 및 캘린더 URL은 하나의 피드에만 유효한 다른 토큰으로 생성됩니다.

당신의 토큰을 가진 사람은 기밀 이슈를 포함한 당신의 피드 활동을 자신인 것처럼 볼 수 있습니다. 토큰이 유출되었다고 생각되면 [토큰을 재설정](../../user/profile/contributions_calendar.md#reset-the-user-activity-feed-token)하세요.

#### 피드 토큰 비활성화 {#disable-a-feed-token}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **피드 토큰** 아래에서 **피드 토큰 비활성화** 확인란을 선택한 후 **변경사항 저장**을 선택합니다.

### 수신 이메일 토큰 {#incoming-email-token}

각 사용자는 만료되지 않는 수신 이메일 토큰을 가집니다. 토큰은 개인 프로젝트와 연결된 이메일 주소에 포함됩니다. 이 토큰을 사용하여 [이메일로 새 이슈 생성](../../user/project/issues/create_issues.md#by-sending-an-email)합니다.

이 토큰을 사용하여 다른 데이터에 액세스할 수 없습니다. 당신의 토큰을 가진 사람은 이슈 및 머지 리퀘스트를 자신인 것처럼 생성할 수 있습니다. 토큰이 유출되었다고 생각되면 즉시 토큰을 재설정하세요.

### 워크스페이스 토큰 {#workspace-token}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194097)되었습니다.

{{< /history >}}

각 [워크스페이스](../../user/workspace/_index.md)는 만료되지 않는 내부 자동 관리 토큰을 가집니다. 워크스페이스와의 HTTP 및 SSH 통신을 허용합니다. 워크스페이스가 **실행 중** 상태가 되도록 요청될 때마다 존재하며 워크스페이스에 의해 자동으로 주입되고 사용됩니다.

중지된 워크스페이스를 시작하면 새로운 워크스페이스 토큰이 생성됩니다. 실행 중인 워크스페이스를 다시 시작하면 기존 토큰이 삭제되고 새 토큰이 생성됩니다.

이 내부 토큰을 직접 보거나 관리할 수 없습니다. 이 토큰을 사용하여 다른 데이터에 액세스할 수 없습니다.

워크스페이스 토큰을 취소하려면 [**stop** 또는 **terminate** 워크스페이스](../../user/workspace/_index.md#manage-workspaces-from-a-project)합니다. 토큰이 즉시 삭제됩니다.

## 사용 가능한 범위 {#available-scopes}

이 테이블은 토큰당 기본 범위를 보여줍니다. 일부 토큰의 경우 토큰을 만들 때 범위를 더욱 제한할 수 있습니다.

| 토큰 이름                  | API 액세스              | 레지스트리 액세스         | 리포지토리 액세스 |
|-----------------------------|-------------------------|-------------------------|-------------------|
| 개인 액세스 토큰       | {{< yes >}}             | {{< yes >}}             | {{< yes >}}       |
| OAuth 2.0 토큰             | {{< yes >}}             | {{< no >}}              | {{< yes >}}       |
| 사칭 토큰         | {{< yes >}}             | {{< yes >}}             | {{< yes >}}       |
| 프로젝트 액세스 토큰        | {{< yes >}}<sup>1</sup> | {{< yes >}}<sup>1</sup> | {{< yes >}}<sup>1</sup> |
| 그룹 액세스 토큰          | {{< yes >}}<sup>2</sup> | {{< yes >}}<sup>2</sup> | {{< yes >}}<sup>2</sup> |
| 배포 토큰                | {{< no >}}              | {{< yes >}}             | {{< yes >}}       |
| 배포 키                  | {{< no >}}              | {{< no >}}              | {{< yes >}}       |
| 러너 등록 토큰   | {{< no >}}              | {{< no >}}              | 제한됨<sup>3</sup> |
| 러너 인증 토큰 | {{< no >}}              | {{< no >}}              | 제한됨<sup>3</sup> |
| 작업 토큰                   | 제한됨<sup>4</sup>     | {{< no >}}              | {{< yes >}}       |

**각주**:

1. 하나의 프로젝트로 제한됩니다.
1. 하나의 그룹으로 제한됩니다.
1. 러너 등록 및 인증 토큰은 리포지토리에 대한 직접 액세스를 제공하지 않지만 리포지토리에 액세스할 수 있는 작업을 실행할 수 있는 새로운 러너를 등록하고 인증하는 데 사용할 수 있습니다.
1. [특정 엔드포인트](../../ci/jobs/ci_job_token.md)만 해당합니다.

## 토큰 접두사 {#token-prefixes}

다음 테이블은 각 토큰 유형의 접두사를 보여줍니다. 개인 액세스 토큰을(를) 제외하고는 이러한 접두사는 표준 식별로 설계되었으므로 구성할 수 없습니다.

|            토큰 이름             |      접두사        |
|-----------------------------------|--------------------|
| 개인 액세스 토큰             | `glpat-`           |
| OAuth 애플리케이션 비밀          | `gloas-`           |
| 사칭 토큰               | `glpat-`           |
| 프로젝트 액세스 토큰              | `glpat-`           |
| 그룹 액세스 토큰                | `glpat-`           |
| 배포 토큰                      | `gldt-`            |
| 러너 인증 토큰       | `glrt-` 또는 등록 토큰을 통해 생성된 경우 `glrtr-` |
| CI/CD 작업 토큰                   | `glcbt-`           |
| 트리거 토큰                     | `glptt-`           |
| 피드 토큰                        | `glft-`            |
| 수신 이메일 토큰               | `glimt-`           |
| Kubernetes용 GitLab 에이전트 토큰 | `glagent-`         |
| 워크스페이스 토큰                   | `glwt-` (GitLab 18.2에서 추가됨) |
| GitLab 세션 쿠키            | `_gitlab_session=` |
| SCIM 토큰                       | `glsoat-`          |
| 기능 플래그 클라이언트 토큰        | `glffct-`          |

---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jira 이슈 통합
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 이름이 GitLab 17.6에서 Jira 이슈 통합으로 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555)되었습니다.

{{< /history >}}

Jira 이슈 통합은 하나 이상의 GitLab 프로젝트를 Jira 인스턴스에 연결합니다. Jira 인스턴스를 직접 호스팅하거나 [Jira Cloud](https://www.atlassian.com/migration/assess/why-cloud)에서 호스팅할 수 있습니다. 지원되는 Jira 버전은 `6.x`, `7.x`, `8.x`, `9.x`, `10.x`입니다.

## 연동 구성 {#configure-the-integration}

{{< history >}}

- Jira 개인 액세스 토큰으로 인증이 GitLab 16.0에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/8222)되었습니다.
- **Jira 이슈**와 **Jira issues for vulnerabilities** 섹션이 GitLab 16.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/440430)되었으며 [기능 플래그](../../administration/feature_flags/_index.md) `jira_multiple_project_keys`와 함께 제공됩니다. 기본적으로 비활성화되었습니다.
- **Jira 이슈**와 **Jira issues for vulnerabilities** 섹션이 GitLab 17.0에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753)되었습니다. `jira_multiple_project_keys` 기능 플래그가 제거되었습니다.
- **Enable Jira issues** 체크박스가 GitLab 17.0에서 **Jira 이슈 보기**로 [이름 변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149055)되었습니다.
- **Enable Jira issue creation from vulnerabilities** 체크박스가 GitLab 17.0에서 **취약성에 대한 Jira 이슈 생성**으로 [이름 변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149055)되었습니다.
- **Jira 이슈 커스터마이징** 설정이 GitLab 17.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/478824)되었습니다.
- **Jira 클라우드 서비스 계정** 인증이 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/576326)되었습니다.

{{< /history >}}

전제 조건:

- GitLab 설치는 [상대 URL](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-relative-url-for-gitlab)을 사용하지 않아야 합니다.
- **For Jira Cloud**:
  - 클래식(범위 지정 안 함) API 토큰으로 **기본 인증**을 사용하려면 [Jira Cloud API 토큰](#create-a-jira-cloud-api-token)과 토큰을 만드는 데 사용한 이메일 주소가 필요합니다.
  - 범위 지정 API 토큰으로 **기본 인증**을 사용하려면 사용자 계정에 대해 범위 지정 토큰을 만들고 Jira API URL을 Jira Platform API 게이트웨이(`https://api.atlassian.com/ex/jira/{cloudId}`)로 설정해야 합니다. 자세한 내용은 [Atlassian 계정의 API 토큰 관리](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/)를 참조하세요.
  - **Jira 클라우드 서비스 계정**을 사용하려면 Jira Cloud 서비스 계정과 해당 서비스 계정의 범위 지정 API 토큰이 필요합니다. 자세한 내용은 [서비스 계정의 API 토큰 관리](https://support.atlassian.com/user-management/docs/manage-api-tokens-for-service-accounts/#Create-an-API-token-with-scopes)를 참조하세요.
  - [IP 허용 목록](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/)을 활성화한 경우 [GitLab.com IP 범위](../../user/gitlab_com/_index.md#ip-range)를 허용 목록에 추가하여 GitLab에서 [Jira 이슈를 볼](#view-jira-issues) 수 있도록 합니다.
- **For Jira Data Center or Jira Server** 다음 중 하나가 필요합니다:
  - [Jira 사용자명 및 비밀번호](jira_server_configuration.md).
  - Jira 개인 액세스 토큰 (GitLab 16.0 이상).

GitLab에서 프로젝트 설정을 구성하여 Jira 이슈 통합을 활성화할 수 있습니다. 또한 GitLab Self-Managed에서 특정 [그룹](../../user/project/integrations/_index.md#manage-group-default-settings-for-a-project-integration) 또는 전체 [인스턴스](../../administration/settings/project_integration_management.md#configure-default-settings-for-an-integration)에 대해 통합을 구성할 수 있습니다.

이 통합을 사용하면 GitLab 프로젝트는 인스턴스의 모든 Jira 프로젝트와 상호 작용할 수 있습니다. GitLab에서 프로젝트 설정을 구성하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **연동**을 선택합니다.
1. **Jira 이슈**를 선택합니다.
1. **통합 활성화** 아래에서 **활성** 체크박스를 선택합니다.
1. **인증 방법** 아래에서 다음 중 하나를 선택합니다:

   - **기본 인증**: Jira Cloud의 경우 이메일 및 API 토큰을 사용하거나, Jira Data Center 또는 Jira Server의 경우 사용자명 및 비밀번호를 사용합니다.
     - **이메일 또는 사용자명**:
       - Jira Cloud의 경우 이메일을 입력합니다.
       - Jira Data Center 또는 Jira Server의 경우 사용자명을 입력합니다.
     - **API 토큰 또는 비밀번호**:
       - Jira Cloud의 경우 API 토큰을 입력합니다.
       - Jira Data Center 또는 Jira Server의 경우 비밀번호를 입력합니다.

   - **개인 액세스 토큰** (Jira Data Center 및 Jira Server만 해당): Jira 개인 액세스 토큰을 입력합니다.

   - **Jira 클라우드 서비스 계정** (Jira Cloud만 해당):

     - **서비스 계정 토큰**: Jira Cloud 서비스 계정의 범위 지정 API 토큰을 입력합니다.
     - 서비스 계정이 GitLab이 액세스하려는 Jira 프로젝트에 대해 충분한 권한을 가지고 있는지 확인합니다.
1. 연결 세부 정보를 제공합니다:

   - **웹 URL**: 이 GitLab 프로젝트에 연결하려는 Jira 인스턴스 웹 인터페이스의 기본 URL(예: `https://jira.example.com` 또는 `https://example.atlassian.net`).
   - **Jira API URL**: Jira 인스턴스 API의 기본 URL입니다. 설정하지 않으면 **웹 URL** 값이 사용됩니다.
     - 클래식(범위 지정 안 함) API 토큰을 사용하는 Jira Cloud의 경우 이 필드를 비워둡니다.
     - 범위 지정 API 토큰(사용자 계정 또는 서비스 계정)을 사용하는 Jira Cloud의 경우 Jira Platform API 게이트웨이를 입력합니다: `https://api.atlassian.com/ex/jira/{cloudId}`. Cloud ID를 찾으려면 [Atlassian 지침](https://support.atlassian.com/jira/kb/retrieve-my-atlassian-sites-cloud-id/)을 참조하세요.
1. 트리거 설정을 제공합니다:
   - **커밋**, **머지 리퀘스트** 또는 둘 다를 트리거로 선택합니다. GitLab에서 Jira 이슈 ID를 언급하면 GitLab이 해당 이슈에 연결합니다.
   - Jira 이슈에 GitLab으로 다시 연결되는 댓글을 추가하려면 **댓글 활성화** 체크박스를 선택합니다.
   - GitLab에서 [Jira 이슈를 자동으로 전환](../../user/project/issues/managing_issues.md#closing-issues-automatically)하려면 **Jira 전환 활성화** 체크박스를 선택합니다.
1. **일치하는 Jira 이슈** 섹션에서:
   - **Jira 이슈 정규식**의 경우 [정규식 패턴을 입력](issues.md#define-a-regex-pattern)합니다.
   - **Jira 이슈 접두사**의 경우 [접두사를 입력](issues.md#define-a-prefix)합니다.
1. 선택 사항. GitLab에서 [Jira 이슈를 보려면](#view-jira-issues) **Jira 이슈** 섹션에서:
   1. **Jira 이슈 보기** 체크박스를 선택합니다.

      > [!warning]
      > GitLab 프로젝트에 액세스할 수 있는 모든 사용자는 인증에 사용되는 API 토큰이 액세스할 수 있는 모든 Jira 이슈를 볼 수 있습니다. 아래에 입력한 Jira 프로젝트 키는 GitLab에 표시되는 이슈 목록을 필터링합니다. API 토큰의 액세스를 제한하지 않습니다. 통합이 읽을 수 있는 이슈를 제한하려면 노출하려는 Jira 프로젝트에만 액세스할 수 있는 Jira 계정을 사용하고 해당 계정에서 API 토큰을 생성합니다.

   1. 표시할 하나 이상의 Jira 프로젝트 키를 입력합니다. API 토큰이 액세스할 수 있는 모든 키를 표시하려면 비워둡니다.
1. 선택 사항. [취약성에 대한 Jira 이슈를 생성](#create-a-jira-issue-for-a-vulnerability)하려면 **Jira issues for vulnerabilities** 섹션에서:
   1. **취약성에 대한 Jira 이슈 생성** 체크박스를 선택합니다.

      > [!note]
      > 이 설정은 개별 프로젝트 및 그룹에 대해서만 활성화할 수 있습니다.

   1. Jira 프로젝트 키를 입력합니다.
   1. **이 프로젝트 키에 대한 이슈 유형 가져오기**({{< icon name="retry" >}})를 선택한 다음 만들 Jira 이슈의 유형을 선택합니다.
   1. 선택 사항. **Jira 이슈 커스터마이징** 체크박스를 선택하여 취약성에 대해 Jira 이슈가 생성될 때 세부 정보를 검토, 수정 또는 추가할 수 있습니다.
1. 선택 사항. **테스트 설정**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## Jira 이슈 보기 {#view-jira-issues}

{{< details >}}

- 티어: Premium, Ultimate

{{< /details >}}

{{< history >}}

- 그룹에 대한 Jira 이슈 활성화가 GitLab 16.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/325715)되었습니다.
- 여러 Jira 프로젝트의 이슈 보기가 GitLab 16.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/440430)되었으며 [기능 플래그](../../administration/feature_flags/_index.md) `jira_multiple_project_keys`와 함께 제공됩니다. 기본적으로 비활성화되었습니다.
- 여러 Jira 프로젝트의 이슈 보기가 GitLab 17.0에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753)되었습니다. `jira_multiple_project_keys` 기능 플래그가 제거되었습니다.

{{< /history >}}

전제 조건:

- Jira 이슈 통합이 [구성](#configure-the-integration)되어 있고 **Jira 이슈 보기** 체크박스가 선택되어 있는지 확인합니다.

특정 그룹 또는 프로젝트에 대해 Jira 이슈를 활성화할 수 있지만 GitLab 프로젝트에서만 이슈를 볼 수 있습니다. GitLab 프로젝트에서 하나 이상의 Jira 프로젝트의 이슈를 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **Jira 이슈**를 선택합니다.

기본적으로 이슈는 **만든 날짜**로 정렬됩니다. 최근에 생성된 이슈가 맨 위에 표시됩니다. [이슈를 필터링](#filter-jira-issues)하고 이슈를 선택하여 GitLab에서 해당 이슈를 볼 수 있습니다.

이슈는 [Jira 상태](https://confluence.atlassian.com/adminjiraserver070/defining-status-field-values-749382903.html)를 기반으로 다음 탭으로 그룹화됩니다:

- **열기**: **완료**가 아닌 다른 Jira 상태의 이슈.
- **닫힘**: **완료** Jira 상태의 이슈.
- **전체**: 모든 Jira 상태의 이슈.

### Jira 이슈 필터링 {#filter-jira-issues}

{{< details >}}

- 티어: Premium, Ultimate

{{< /details >}}

{{< history >}}

- 프로젝트별 Jira 이슈 필터링이 GitLab 16.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/440430)되었으며 [기능 플래그](../../administration/feature_flags/_index.md) `jira_multiple_project_keys`와 함께 제공됩니다. 기본적으로 비활성화되었습니다.
- 프로젝트별 Jira 이슈 필터링이 GitLab 17.0에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753)되었습니다. `jira_multiple_project_keys` 기능 플래그가 제거되었습니다.

{{< /history >}}

전제 조건:

- Jira 이슈 통합이 [구성](#configure-the-integration)되어 있고 **Jira 이슈 보기** 체크박스가 선택되어 있는지 확인합니다.

GitLab에서 [Jira 이슈를 볼](#view-jira-issues) 때 요약 및 설명의 텍스트로 이슈를 필터링할 수 있습니다. 다음으로 이슈를 필터링할 수도 있습니다:

- **라벨**: URL의 `labels[]` 매개변수에 하나 이상의 Jira 이슈 라벨을 지정합니다. 여러 라벨을 지정하면 지정된 모든 라벨이 있는 이슈만 표시됩니다(예: `/-/integrations/jira/issues?labels[]=backend&labels[]=feature&labels[]=QA`).
- **상태**: URL의 `status` 매개변수에 Jira 이슈 상태를 지정합니다(예: `/-/integrations/jira/issues?status=In Progress`).
- **리포터**: URL의 `author_username` 매개변수에 Jira 표시 이름을 지정합니다(예: `/-/integrations/jira/issues?author_username=John Smith`).
- **담당자**: URL의 `assignee_username` 매개변수에 Jira 표시 이름을 지정합니다(예: `/-/integrations/jira/issues?assignee_username=John Smith`).
- **프로젝트**: URL의 `project` 매개변수에 Jira 프로젝트 키를 지정합니다(예: `/-/integrations/jira/issues?project=GTL`).

## Jira 검증 {#jira-verification}

{{< details >}}

- 티어: Premium, Ultimate

{{< /details >}}

{{< history >}}

- [GitLab 18.3에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192795).

{{< /history >}}

전제 조건:

- Jira 이슈 통합이 [구성](#configure-the-integration)되어 있고 **Jira 이슈 보기** 체크박스가 선택되어 있는지 확인합니다.

푸시를 허용하기 전에 커밋 메시지에서 참조된 Jira 이슈가 특정 기준을 충족하는지 확인하도록 검증 규칙을 설정할 수 있습니다. 이 기능은 GitLab과 Jira 간의 일관된 워크플로우를 유지하는 데 도움이 됩니다.

GitLab이 검증을 수행할 때:

- 커밋 메시지에 여러 Jira 이슈 키가 포함된 경우 검증 확인을 위해 첫 번째 키만 사용됩니다.
- 알려진 이슈로 인해 **이슈가 존재하는지 점검** 설정을 지우면 확인이 실행되는 것을 중지하지 않습니다. 확인이 실행되는 것을 중지하는 유일한 방법은 모든 Jira 검증 확인을 지우는 것입니다.

Jira 검증을 구성하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **연동**을 선택합니다.
1. **Jira 이슈**를 선택합니다.
1. **Jira 검증** 섹션으로 이동합니다.
1. 다음 검증 확인을 구성합니다:
   - **이슈가 존재하는지 점검**: 커밋 메시지에서 참조된 Jira 이슈가 Jira에 있는지 확인합니다.
   - **담당자 점검**: 커밋 담당자가 메시지에서 참조된 Jira 이슈의 담당자인지 확인합니다.
   - **이슈 상태 점검**: 커밋 메시지에서 참조된 Jira 이슈가 허용된 상태 중 하나를 가지는지 확인합니다.
   - **허용되는 상태**: 허용된 Jira 이슈 상태의 쉼표로 구분된 목록(예: `Ready, In Progress, Review`). 이 필드는 **이슈 상태 점검**이 활성화된 경우에만 사용 가능합니다.
1. **변경 사항 저장**을 선택합니다.

사용자가 검증 기준을 충족하지 않는 변경 사항을 푸시하려고 하면 GitLab은 푸시가 거부된 이유를 나타내는 오류 메시지를 표시합니다.

### 예제 오류 메시지 {#example-error-messages}

- 참조된 Jira 이슈가 없는 경우(**이슈가 존재하는지 점검**이 활성화된 경우):

  ```plaintext
  Jira issue PROJECT-123 does not exist.
  ```

- 참조된 Jira 이슈가 담당자에게 할당되지 않은 경우(**담당자 점검**이 활성화된 경우):

  ```plaintext
  Jira issue PROJECT-123 is not assigned to you. It is assigned to Jane Doe.
  ```

- 참조된 Jira 이슈의 상태가 허용된 목록에 없는 경우(**이슈 상태 점검**이 활성화된 경우):

  ```plaintext
  Jira issue PROJECT-123 has status 'Done', which is not in the list of allowed statuses: Ready, In Progress, Review.
  ```

### 검증 확인의 사용 사례 {#use-case-for-verification-checks}

다음 예를 고려하세요:

1. 팀이 활발하게 작업 중일 때 Jira 이슈가 특정 상태에 있어야 하는 워크플로우를 사용합니다.
1. Jira 검증을 다음과 같이 구성합니다:
   - 이슈가 존재하는지 확인
   - 이슈가 "진행 중" 또는 "검토" 상태에 있는지 확인
1. 개발자가 "프로젝트-123에 유효성 검사 추가하여 수정" 커밋 메시지로 변경 사항을 푸시하려고 합니다.
1. GitLab이 다음을 확인합니다:
   - Jira 이슈 PROJECT-123이 존재합니다.
   - 이슈의 상태가 "진행 중" 또는 "검토" 중 하나입니다.
1. 모든 확인이 통과하면 푸시가 허용됩니다. 확인이 실패하면 오류 메시지와 함께 푸시가 거부됩니다.

이렇게 하면 해당 Jira 이슈가 올바른 상태에 있지 않을 때 코드 변경 사항이 푸시되는 것을 방지하여 팀이 올바른 워크플로우를 따르도록 합니다.

## 취약성에 대한 Jira 이슈 생성 {#create-a-jira-issue-for-a-vulnerability}

{{< details >}}

- 티어: Ultimate

{{< /details >}}

전제 조건:

- Jira 이슈 통합이 [구성](#configure-the-integration)되어 있고 **취약성에 대한 Jira 이슈 생성** 확인란이 선택되어 있는지 확인하세요.
- 대상 프로젝트에서 이슈를 생성할 수 있는 권한이 있는 Jira 사용자 계정이 필요합니다.

GitLab에서 Jira 이슈를 생성하여 취약성 해결 또는 완화를 위해 수행한 모든 조치를 추적할 수 있습니다. 취약성에 대한 Jira 이슈를 생성하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **취약성 보고서**를 선택합니다.
1. 취약성의 설명을 선택합니다.
1. **Jira 이슈 생성**을 선택합니다.

   [**Jira 이슈 커스터마이징**](#configure-the-integration) 설정이 선택되면 Jira 인스턴스의 이슈 생성 양식으로 리디렉션되며 취약성 데이터로 미리 채워집니다. Jira 이슈를 생성하기 전에 세부 정보를 검토, 수정 또는 추가할 수 있습니다.

이슈는 취약성 보고서의 정보와 함께 대상 Jira 프로젝트에서 생성됩니다.

GitLab 이슈를 생성하려면 [취약성에 대한 GitLab 이슈 생성](../../user/application_security/vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability)을 참조하세요.

## Jira Cloud API 토큰 생성 {#create-a-jira-cloud-api-token}

Jira Cloud에 대해 Jira 이슈 통합을 구성하려면 API 토큰이 필요합니다.

### 사용자 계정의 경우 {#for-a-user-account}

1. Jira 프로젝트에 대한 쓰기 액세스 권한이 있는 계정에서 [Atlassian](https://id.atlassian.com/manage-profile/security/api-tokens)에 로그인합니다.

   링크를 클릭하면 **API tokens** 페이지가 열립니다. 또는 Atlassian 프로필에서 **Account Settings** > **보안** > **Create and manage API tokens**를 선택합니다.
1. **Create API token**을 선택합니다.
1. 대화 상자에서 토큰의 레이블을 입력하고 **생성**을 선택합니다.
1. API 토큰을 복사하려면 **복사**를 선택합니다.

### 서비스 계정의 경우 {#for-a-service-account}

1. Jira Cloud 서비스 계정을 생성하거나 식별합니다. 자세한 내용은 [Atlassian 서비스 계정 설명서](https://support.atlassian.com/user-management/docs/understand-service-accounts/#Create-a-service-account)를 참조하세요.
1. 서비스 계정에 대한 범위 지정 API 토큰을 생성합니다. 자세한 내용은 [서비스 계정의 API 토큰 관리](https://support.atlassian.com/user-management/docs/manage-api-tokens-for-service-accounts/#Create-an-API-token-with-scopes)를 참조하세요.
1. 토큰이 다음과 같은 최소 클래식 Jira 범위를 가지고 있는지 확인합니다:

   - `read:jira-user`
   - `read:jira-work`
   - `write:jira-work`

## 한 Jira 사이트에서 다른 Jira 사이트로 마이그레이션 {#migrate-from-one-jira-site-to-another}

{{< history >}}

- 통합 이름이 GitLab 17.6에서 **Jira 이슈**로 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555)되었습니다.

{{< /history >}}

GitLab에서 한 Jira 사이트에서 다른 사이트로 마이그레이션하고 Jira 이슈 통합을 유지하려면:

1. [통합 구성](#configure-the-integration)의 단계를 따릅니다.
1. 새 Jira 사이트 URL을 입력합니다(예: `https://myjirasite.atlassian.net`).

GitLab 18.6 이상에서는 기존 Jira 이슈 참조가 새 Jira 사이트 URL을 사용하도록 자동으로 업데이트됩니다.

GitLab 18.5 이하에서는 기존 Jira 이슈 참조를 업데이트하기 위해 [Markdown 캐시를 무효화](../../administration/invalidate_markdown_cache.md#invalidate-the-cache)해야 합니다.

---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jira 이슈 통합 이슈 해결
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Jira 이슈 통합](configure.md)을 사용할 때 다음 이슈가 발생할 수 있습니다.

## GitLab이 Jira 이슈에 연결할 수 없음 {#gitlab-cannot-link-to-a-jira-issue}

GitLab에서 Jira 이슈 ID를 언급하면 이슈 링크가 누락될 수 있습니다. [`sidekiq.log`](../../administration/logs/_index.md#sidekiq-logs)에 다음 예외가 포함될 수 있습니다:

```plaintext
No Link Issue Permission for issue 'JIRA-1234'
```

이 이슈를 해결하려면 [Jira 이슈 통합](configure.md)을 위해 생성한 Jira 사용자가 이슈를 연결할 권한이 있는지 확인하세요.

## GitLab이 Jira 이슈에 댓글을 달 수 없음 {#gitlab-cannot-comment-on-a-jira-issue}

GitLab이 Jira 이슈에 댓글을 달 수 없으면 [Jira 이슈 통합](configure.md)을 위해 생성한 Jira 사용자가 다음 권한을 가지고 있는지 확인하세요:

- Jira 이슈에 댓글을 게시합니다.
- Jira 이슈를 전환합니다.

[GitLab 이슈 추적기](../external-issue-tracker.md)가 비활성화되면 Jira 이슈 참조 및 댓글이 작동하지 않습니다. [Jira 액세스에 대한 IP 주소 제한](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/)을 하면 GitLab Self-Managed IP 주소 또는 [GitLab IP 주소](../../user/gitlab_com/_index.md#ip-range)를 Jira의 허용 목록에 추가하세요.

근본 원인을 확인하려면 [`integrations_json.log`](../../administration/logs/_index.md#integrations_jsonlog) 파일을 확인하세요. GitLab이 Jira 이슈에 댓글을 달 때 `Error sending message` 로그 항목이 나타날 수 있습니다.

GitLab 16.1 이상에서 오류가 발생하면 `integrations_json.log` 파일에 Jira에 대한 나가는 API 요청에서 `client_*` 키가 포함됩니다. `client_*` 키를 사용하여 [Atlassian API 설명서](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/#api-group-issues)를 확인하여 오류가 발생한 이유를 확인할 수 있습니다.

다음 예제에서 Jira는 `404 Not Found`로 응답합니다. 이 오류는 다음과 같은 경우에 발생할 수 있습니다:

- Jira 이슈 통합을 위해 생성한 Jira 사용자가 이슈를 볼 수 있는 권한이 없습니다.
- 지정한 Jira 이슈 ID가 존재하지 않습니다.

```json
{
  "severity": "ERROR",
  "time": "2023-07-25T21:38:56.510Z",
  "message": "Error sending message",
  "client_url": "https://my-jira-cloud.atlassian.net",
  "client_path": "/rest/api/2/issue/ALPHA-1",
  "client_status": "404",
  "exception.class": "JIRA::HTTPError",
  "exception.message": "Not Found",
}
```

반환된 상태 코드에 대한 자세한 내용은 [Jira Cloud 플랫폼 REST API 설명서](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/#api-rest-api-2-issue-issueidorkey-get-response)를 참조하세요.

### `curl`을 사용하여 Jira 이슈에 대한 액세스 확인 {#using-curl-to-verify-access-to-a-jira-issue}

Jira 사용자가 특정 Jira 이슈에 액세스할 수 있는지 확인하려면 다음 스크립트를 실행하세요:

```shell
curl --verbose --user "$USER:$API_TOKEN" "https://$ATLASSIAN_SUBDOMAIN.atlassian.net/rest/api/2/issue/$JIRA_ISSUE"
```

사용자가 이슈에 액세스할 수 있으면 Jira는 `200 OK`로 응답하고 반환된 JSON에 Jira 이슈 세부 정보가 포함됩니다.

### GitLab이 Jira 이슈에 댓글을 게시할 수 있는지 확인 {#verify-gitlab-can-post-a-comment-to-a-jira-issue}

> [!warning]
> 데이터를 변경하는 명령은 올바르게 실행하지 않거나 적절한 조건에서 실행하지 않으면 손상을 초래할 수 있습니다. 항상 테스트 환경에서 먼저 명령을 실행하고 복원할 준비가 된 백업 인스턴스를 준비하세요.

Jira 이슈 통합 이슈를 해결하기 위해 프로젝트의 Jira 통합 설정을 사용하여 GitLab이 Jira 이슈에 댓글을 게시할 수 있는지 확인할 수 있습니다.

이렇게 하려면:

- [Rails 콘솔](../../administration/operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행하세요:

  ```ruby
  jira_issue_id = "ALPHA-1" # Change to your Jira issue ID
  project = Project.find_by_full_path("group/project") # Change to your project's path

  integration = project.integrations.find_by(type: "Integrations::Jira")
  jira_issue = integration.client.Issue.find(jira_issue_id)
  jira_issue.comments.build.save!(body: 'This is a test comment from GitLab via the Rails console')
  ```

명령이 성공하면 Jira 이슈에 댓글이 추가됩니다.

## GitLab이 Jira 이슈를 생성할 수 없음 {#gitlab-cannot-create-a-jira-issue}

취약성에서 Jira 이슈를 생성하려고 하면 "필드 필수" 오류가 표시될 수 있습니다. 예를 들어 `Components is required`("Components" 필드가 누락되었음)입니다. 이는 Jira에 GitLab이 전달하지 않는 일부 필수 필드가 구성되어 있기 때문에 발생합니다. 이 이슈를 해결하려면 다음을 수행하세요:

1. Jira 인스턴스에서 새로운 "취약성" [이슈 유형](https://support.atlassian.com/jira-cloud-administration/docs/what-are-issue-types/)을 생성합니다.
1. 새 이슈 유형을 프로젝트에 할당합니다.
1. 필드 스키마를 프로젝트의 모든 "취약성"에 변경하여 누락된 필드를 요구하지 않도록 합니다.

## GitLab이 Jira 이슈를 닫을 수 없음 {#gitlab-cannot-close-a-jira-issue}

GitLab이 Jira 이슈를 닫을 수 없으면 다음을 수행하세요:

- Jira 설정에서 설정한 전환 ID가 프로젝트가 이슈를 닫아야 하는 ID와 일치하는지 확인하세요. 자세한 내용은 [자동 이슈 전환](issues.md#automatic-issue-transitions) 및 [사용자 지정 이슈 전환](issues.md#custom-issue-transitions)을 참조하세요.
- Jira 이슈가 이미 해결됨으로 표시되지 않았는지 확인하세요:
  - Jira 이슈 해결 필드가 설정되지 않았는지 확인하세요.
  - 이슈가 Jira 목록에서 취소선으로 표시되지 않았는지 확인하세요.

## 실패한 로그인 시도 후 CAPTCHA {#captcha-after-failed-sign-in-attempts}

연속 로그인 시도 실패 후 CAPTCHA가 트리거될 수 있습니다. 이러한 실패한 시도는 Jira 이슈 통합 설정을 테스트할 때 `401 Unauthorized`로 이어질 수 있습니다. CAPTCHA가 트리거되면 Jira REST API를 사용하여 Jira 사이트에 인증할 수 없습니다.

이 이슈를 해결하려면 Jira 인스턴스에 로그인하고 CAPTCHA를 완료하세요.

## 가져온 프로젝트에서는 통합이 작동하지 않음 {#integration-does-not-work-for-an-imported-project}

GitLab 19.0 이상에서 Jira 이슈 통합이 가져온 프로젝트에서 작동하지 않을 수 있습니다. 자세한 내용은 [이슈 341571](https://gitlab.com/gitlab-org/gitlab/-/issues/341571)을 참조하세요.

이 이슈를 해결하려면 통합을 비활성화한 후 다시 활성화하세요.

## 오류: `certificate verify failed` {#error-certificate-verify-failed}

Jira 이슈 통합 설정을 테스트할 때 다음 오류가 표시될 수 있습니다:

```plaintext
Connection failed. Check your integration settings. SSL_connect returned=1 errno=0 peeraddr=<jira.example.com> state=error: certificate verify failed (unable to get local issuer certificate)
```

이 오류는 [`integrations_json.log`](../../administration/logs/_index.md#integrations_jsonlog) 파일에도 나타날 수 있습니다:

```json
{
  "severity":"ERROR",
  "integration_class":"Integrations::Jira",
  "message":"Error sending message",
  "exception.class":"OpenSSL::SSL::SSLError",
  "exception.message":"SSL_connect returned=1 errno=0 peeraddr=x.x.x.x:443 state=error: certificate verify failed (unable to get local issuer certificate)",
}
```

Jira 인증서가 공개적으로 신뢰할 수 없거나 인증서 체인이 불완전하기 때문에 오류가 발생합니다. 이 이슈가 해결될 때까지 GitLab은 Jira에 연결하지 않습니다.

이 이슈를 해결하려면 [일반적인 SSL 오류](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting/#common-ssl-errors)를 참조하세요.

## 모든 Jira 프로젝트를 인스턴스 수준 또는 그룹 수준 값으로 변경 {#change-all-jira-projects-to-instance-level-or-group-level-values}

> [!warning]
> 데이터를 변경하는 명령은 올바르게 실행하지 않거나 적절한 조건에서 실행하지 않으면 손상을 초래할 수 있습니다. 항상 테스트 환경에서 먼저 명령을 실행하고 복원할 준비가 된 백업 인스턴스를 준비하세요.

### 인스턴스에서 모든 프로젝트 변경 {#change-all-projects-on-an-instance}

모든 Jira 프로젝트를 인스턴스 수준 통합 설정을 사용하도록 변경하려면 다음을 수행하세요:

1. [Rails 콘솔](../../administration/operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행하세요:

   ```ruby
   Integrations::Jira.where(active: true, instance: false, inherit_from_id: nil).find_each do |integration|
     default_integration = Integration.default_integration(integration.type, integration.project)

     integration.inherit_from_id = default_integration.id

     if integration.save(context: :manual_change)
       if Gitlab.version_info >= Gitlab::VersionInfo.new(16, 9)
         Integrations::Propagation::BulkUpdateService.new(default_integration, [integration]).execute
       else
         BulkUpdateIntegrationService.new(default_integration, [integration]).execute
       end
     end
   end
   ```

1. UI에서 인스턴스 수준 통합을 수정하고 저장하여 모든 그룹 수준 및 프로젝트 수준 통합에 변경 사항을 전파합니다.

### 그룹의 모든 프로젝트 변경 {#change-all-projects-in-a-group}

그룹(및 해당 하위 그룹)의 모든 Jira 프로젝트를 그룹 수준 통합 설정을 사용하도록 변경하려면 다음을 수행하세요:

- [Rails 콘솔](../../administration/operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행하세요:

  ```ruby
  def reset_integration(target)
    integration = target.integrations.find_by(type: Integrations::Jira)

    return if integration.nil? # Skip if the project has no Jira issues integration
    return unless integration.inherit_from_id.nil? # Skip integrations that are already inheriting

    default_integration = Integration.default_integration(integration.type, target)

    integration.inherit_from_id = default_integration.id

    if integration.save(context: :manual_change)
      if Gitlab.version_info >= Gitlab::VersionInfo.new(16, 9)
        Integrations::Propagation::BulkUpdateService.new(default_integration, [integration]).execute
      else
        BulkUpdateIntegrationService.new(default_integration, [integration]).execute
      end
    end
  end

  parent_group = Group.find_by_full_path('top-level-group') # Add the full path of your top-level group
  current_user = User.find_by_username('admin-user') # Add the username of a user with administrator access

  unless parent_group.nil?
    groups = GroupsFinder.new(current_user, { parent: parent_group, include_parent_descendants: true }).execute

    # Reset any projects in subgroups to use the parent group integration settings
    groups.find_each do |group|
      reset_integration(group)

      group.projects.find_each do |project|
        reset_integration(project)
      end
    end

    # Reset any direct projects in the parent group to use the parent group integration settings
    parent_group.projects.find_each do |project|
      reset_integration(project)
    end
  end
  ```

## 모든 프로젝트의 통합 암호 업데이트 {#update-the-integration-password-for-all-projects}

> [!warning]
> 데이터를 변경하는 명령은 올바르게 실행하지 않거나 적절한 조건에서 실행하지 않으면 손상을 초래할 수 있습니다. 항상 테스트 환경에서 먼저 명령을 실행하고 복원할 준비가 된 백업 인스턴스를 준비하세요.

활성 Jira 이슈 통합이 있는 모든 프로젝트의 Jira 사용자 암호를 재설정하려면 [Rails 콘솔](../../administration/operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행하세요:

```ruby
p = Project.find_by_sql("SELECT p.id FROM projects p LEFT JOIN integrations i ON p.id = i.project_id WHERE i.type_new = 'Integrations::Jira' AND i.active = true")

p.each do |project|
  project.jira_integration.update_attribute(:password, '<your-new-password>')
end
```

## Jira 이슈 목록 {#jira-issue-list}

GitLab에서 [Jira 이슈 보기](configure.md#view-jira-issues)를 할 때 다음 이슈가 발생할 수 있습니다.

### 오류: `500 We're sorry` {#error-500-were-sorry}

GitLab에서 Jira 이슈에 액세스할 때 `500 We're sorry. Something went wrong on our end` 오류가 표시될 수 있습니다. [`production.log`](../../administration/logs/_index.md#productionlog)를 확인하여 파일에 다음 예외가 포함되어 있는지 확인하세요:

```plaintext
:NoMethodError (undefined method 'duedate' for #<JIRA::Resource::Issue:0x00007f406d7b3180>)
```

그렇다면 통합된 Jira 프로젝트에서 **마감일** 필드가 [이슈에 대해 표시되도록](https://confluence.atlassian.com/jirakb/due-date-field-is-missing-189431917.html) 하세요.

### 오류: `An error occurred while requesting data from Jira` {#error-an-error-occurred-while-requesting-data-from-jira}

GitLab에서 Jira 이슈 목록을 보거나 Jira 이슈를 생성하려고 할 때 다음 오류 중 하나가 표시될 수 있습니다:

```plaintext
An error occurred while requesting data from Jira
```

```plaintext
An error occurred while fetching issue list. Connection failed. Check your integration settings.
```

이러한 오류는 Jira 이슈 통합에 대한 인증이 완료되지 않았거나 올바르지 않을 때 발생합니다.

이 이슈를 해결하려면 [Jira 이슈 통합 구성](configure.md#configure-the-integration)을 다시 수행하세요. 인증 세부 정보가 올바른지 확인하고, API 토큰이나 암호를 다시 입력하고, 변경 사항을 저장하세요.

프로젝트 키에 예약된 JQL 단어가 포함되어 있으면 Jira 이슈 목록이 로드되지 않습니다. 자세한 내용은 [이슈 426176](https://gitlab.com/gitlab-org/gitlab/-/issues/426176)을 참조하세요. Jira 프로젝트 키에는 [예약된 단어 및 문자](https://confluence.atlassian.com/jirasoftwareserver/advanced-searching-939938733.html#Advancedsearching-restrictionsRestrictedwordsandcharacters)가 없어야 합니다.

### Jira 자격 증명의 오류 {#errors-with-jira-credentials}

GitLab에서 Jira 이슈 목록을 보려고 할 때 다음 오류 중 하나가 표시될 수 있습니다.

#### 오류: `The value '<project>' does not exist for the field 'project'` {#error-the-value-project-does-not-exist-for-the-field-project}

Jira 설치에 잘못된 인증 자격 증명을 사용하면 다음 오류가 표시될 수 있습니다:

```plaintext
An error occurred while requesting data from Jira:
The value '<project>' does not exist for the field 'project'.
Check your Jira issues integration configuration and try again.
```

인증 자격 증명은 Jira 설치 유형에 따라 다릅니다:

- **For Jira Cloud**, Jira Cloud API 토큰과 토큰을 생성하는 데 사용한 이메일 주소가 있어야 합니다.
- **For Jira Data Center or Jira Server**, Jira 사용자 이름 및 암호이거나 GitLab 16.0 이상에서 Jira 개인 액세스 토큰이 있어야 합니다.

자세한 내용은 [Jira 이슈 통합](configure.md)을 참조하세요.

이 이슈를 해결하려면 Jira 설치와 일치하도록 인증 자격 증명을 업데이트하세요.

#### 오류: `The credentials for accessing Jira are not allowed to access the data` {#error-the-credentials-for-accessing-jira-are-not-allowed-to-access-the-data}

Jira 자격 증명이 [Jira 이슈 통합](configure.md#configure-the-integration)에서 지정한 Jira 프로젝트 키에 액세스할 수 없으면 다음 오류가 표시될 수 있습니다:

```plaintext
The credentials for accessing Jira are not allowed to access the data.
Check your Jira issues integration credentials and try again.
```

> [!warning]
> Atlassian은 2024년 10월 31일에 Jira Cloud를 위해 더 이상 사용되는 JQL 검색 엔드포인트 (`GET/POST /rest/api/2/search`)를 제거 예약 2025년 5월 1일로 제거했습니다. Jira Server 및 Data Center는 계속해서 `/rest/api/2/search` 엔드포인트를 사용합니다. 자세한 내용은 [Atlassian 중단 공지](https://developer.atlassian.com/changelog/#CHANGE-2046)를 참조하세요.

이 이슈를 해결하려면 Jira 이슈 통합에서 구성한 Jira 사용자가 지정된 Jira 프로젝트 키와 관련된 이슈를 볼 수 있는 권한이 있는지 확인하세요.

Jira 사용자가 이 권한을 가지고 있는지 확인하려면 다음 중 하나를 수행하세요:

{{< tabs >}}

{{< tab title="Jira Cloud" >}}

- 브라우저에서 Jira 이슈 통합을 위해 구성한 사용자로 Jira에 로그인하세요. Jira API는 쿠키 기반 인증을 지원하므로 브라우저에서 반환된 이슈가 있는지 확인할 수 있습니다:

  ```plaintext
  https://<ATLASSIAN_SUBDOMAIN>.atlassian.net/rest/api/3/search/jql?jql=project=<JIRA_PROJECT_KEY>
  ```

- HTTP 기본 인증을 위해 `curl`을 사용하여 API에 액세스하고 반환된 이슈가 있는지 확인하세요:

  ```shell
  curl --verbose --user "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --request POST \
    --data '{"jql":"project='$JIRA_PROJECT_KEY'"}' \
    "https://$ATLASSIAN_SUBDOMAIN.atlassian.net/rest/api/3/search/jql" | jq
  ```

API 응답은 JSON 응답을 반환합니다:

- `issues`에는 Jira 프로젝트 키와 일치하는 이슈 배열이 포함됩니다.
- `nextPageToken`은 가져올 결과가 더 있으면 제공됩니다.

반환된 상태 코드 및 API 세부 정보에 대한 자세한 내용은 [JQL 향상된 검색을 사용하여 이슈 검색 (POST)](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-search/#api-rest-api-3-search-jql-post)을 참조하세요.

{{< /tab >}}

{{< tab title="Jira Server/Data Center" >}}

- 브라우저에서 Jira 이슈 통합을 위해 구성한 사용자로 Jira에 로그인하세요. Jira API는 쿠키 기반 인증을 지원하므로 브라우저에서 반환된 이슈가 있는지 확인할 수 있습니다:

  ```plaintext
  <JIRA_SERVER_URL>/rest/api/2/search?jql=project=<JIRA_PROJECT_KEY>
  ```

- HTTP 기본 인증을 위해 `curl`을 사용하여 API에 액세스하고 반환된 이슈가 있는지 확인하세요:

  ```shell
  curl --verbose --header 'Authorization: Bearer '$JIRA_API_TOKEN'' \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --request POST \
    --data '{"jql":"project='$JIRA_PROJECT_KEY'"}' \
    "$JIRA_SERVER_URL/rest/api/2/search" | jq
  ```

API 응답은 JSON 응답을 반환합니다:

- `issues`에는 Jira 프로젝트 키와 일치하는 이슈 배열이 포함됩니다.
- `total`은 가져올 결과가 더 있으면 제공됩니다.

반환된 상태 코드 및 API 세부 정보에 대한 자세한 내용은 [JQL로 검색 수행 (POST)](https://developer.atlassian.com/server/jira/platform/rest/v10007/api-group-search/#api-api-2-search-post)을 참조하세요.

{{< /tab >}}

{{< /tabs >}}

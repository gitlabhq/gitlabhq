---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Elasticsearch 액세스 문제 해결
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Elasticsearch 액세스로 작업할 때 다음 이슈가 발생할 수 있습니다.

## Rails 콘솔에서 구성 설정 {#set-configurations-in-the-rails-console}

[Rails 콘솔 세션 시작](../../../administration/operations/rails_console.md#starting-a-rails-console-session)을 참조하세요.

### 속성 나열 {#list-attributes}

사용 가능한 모든 속성을 나열하려면:

1. Rails 콘솔(`sudo gitlab-rails console`)을 엽니다.
1. 다음 명령을 실행하세요:

```ruby
ApplicationSetting.last.attributes
```

출력에는 [Elasticsearch 통합](../../advanced_search/elasticsearch.md)에서 사용 가능한 모든 설정(예: `elasticsearch_indexing`, `elasticsearch_url`, `elasticsearch_replicas`, `elasticsearch_pause_indexing`)이 포함됩니다.

### 속성 설정 {#set-attributes}

Elasticsearch 통합 설정을 설정하려면 다음과 같은 명령을 실행하세요:

```ruby
ApplicationSetting.last.update(elasticsearch_url: '<your ES URL and port>')

#or

ApplicationSetting.last.update(elasticsearch_indexing: false)
```

### 속성 가져오기 {#get-attributes}

설정이 [Elasticsearch 통합](../../advanced_search/elasticsearch.md)에서 또는 Rails 콘솔에서 설정되었는지 확인하려면 다음과 같은 명령을 실행하세요:

```ruby
Gitlab::CurrentSettings.elasticsearch_url

#or

Gitlab::CurrentSettings.elasticsearch_indexing
```

### 암호 변경 {#change-the-password}

Elasticsearch 암호를 변경하려면 다음 명령을 실행하세요:

```ruby
es_url = Gitlab::CurrentSettings.current_application_settings

# Confirm the current Elasticsearch URL
es_url.elasticsearch_url

# Set the Elasticsearch URL
es_url.elasticsearch_url = "http://<username>:<password>@your.es.host:<port>"

# Save the change
es_url.save!
```

## 로그 보기 {#view-logs}

Elasticsearch 통합의 이슈를 파악하기 위한 가장 유용한 도구 중 하나는 로그입니다. 이 통합과 관련된 가장 중요한 로그는 다음과 같습니다:

1. [`sidekiq.log`](../../../administration/logs/_index.md#sidekiqlog) - 모든 인덱싱이 Sidekiq에서 발생하므로 Elasticsearch 통합과 관련된 대부분의 로그를 이 파일에서 찾을 수 있습니다.
1. [`elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog) - Elasticsearch에 특정한 추가 로그가 이 파일로 전송되며, 검색, 인덱싱 또는 마이그레이션에 대한 진단 정보가 포함될 수 있습니다.

다음은 몇 가지 일반적인 문제와 이를 해결하는 방법입니다.

## GitLab 인스턴스가 Elasticsearch를 사용하고 있는지 확인 {#verify-that-your-gitlab-instance-is-using-elasticsearch}

GitLab 인스턴스가 Elasticsearch를 사용하고 있는지 확인하려면:

- 검색을 수행할 때 검색 결과 페이지의 오른쪽 상단 모서리에 **Advanced search is enabled**가 표시되는지 확인하세요.
- **운영자** 영역의 **설정** > **검색**에서 고급 검색 설정이 선택되었는지 확인하세요.

  필요한 경우 Rails 콘솔에서 동일한 설정을 얻을 수 있습니다:

  ```ruby
  ::Gitlab::CurrentSettings.elasticsearch_search?         # Whether or not searches will use Elasticsearch
  ::Gitlab::CurrentSettings.elasticsearch_indexing?       # Whether or not content will be indexed in Elasticsearch
  ::Gitlab::CurrentSettings.elasticsearch_limit_indexing? # Whether or not Elasticsearch is limited only to certain projects/namespaces
  ```

- [Rails 콘솔](../../../administration/operations/rails_console.md)에 액세스하여 다음 명령을 실행함으로써 검색이 Elasticsearch를 사용하는지 확인하세요:

  ```rails
  u = User.find_by_email('email_of_user_doing_search')
  s = SearchService.new(u, {:search => 'search_term'})
  pp s.search_objects.class
  ```

  마지막 명령의 출력이 핵심입니다. 다음을 표시하는 경우:

  - `ActiveRecord::Relation`, **it is not**.
  - `Kaminari::PaginatableArray`, **it is**.
- Elasticsearch가 특정 네임스페이스로 제한되고 특정 프로젝트 또는 네임스페이스에 대해 Elasticsearch를 사용하고 있는지 확인해야 하는 경우 Rails 콘솔을 사용할 수 있습니다:

  ```ruby
  ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: Namespace.find_by_full_path("/my-namespace"))
  ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: Project.find_by_full_path("/my-namespace/my-project"))
  ```

## 오류: `User: anonymous is not authorized to perform: es:ESHttpGet` {#error-user-anonymous-is-not-authorized-to-perform-eseshttpget}

AWS OpenSearch 또는 Elasticsearch와 함께 도메인 수준 액세스 정책을 사용할 때 AWS 역할이 올바른 GitLab 노드에 할당되지 않습니다. GitLab Rails 및 Sidekiq 노드는 검색 클러스터와 통신할 수 있는 권한이 필요합니다.

```plaintext
User: anonymous is not authorized to perform: es:ESHttpGet because no resource-based policy allows the es:ESHttpGet
action
```

이를 해결하려면 AWS 역할이 올바른 GitLab 노드에 할당되어 있는지 확인하세요.

## 유효한 영역이 지정되지 않음 {#no-valid-region-specified}

고급 검색과 함께 AWS 인증을 사용할 때 지정하는 영역이 유효해야 합니다.

## 오류: `no permissions for [indices:data/write/bulk]` {#error-no-permissions-for-indicesdatawritebulk}

IAM 역할 또는 AWS OpenSearch Dashboards를 사용하여 만든 역할과 함께 세분화된 액세스 제어를 사용할 때 다음 오류가 발생할 수 있습니다:

```json
{
  "error": {
    "root_cause": [
      {
        "type": "security_exception",
        "reason": "no permissions for [indices:data/write/bulk] and User [name=arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE, backend_roles=[arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE], requestedTenant=null]"
      }
    ],
    "type": "security_exception",
    "reason": "no permissions for [indices:data/write/bulk] and User [name=arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE, backend_roles=[arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE], requestedTenant=null]"
  },
  "status": 403
}
```

이를 해결하려면 AWS OpenSearch Dashboards에서 [역할을 사용자에게 매핑](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-mapping)해야 합니다.

## AWS OpenSearch Service에서 추가 마스터 사용자 만들기 {#create-additional-master-users-in-aws-opensearch-service}

도메인을 만들 때 마스터 사용자를 설정할 수 있습니다. 이 사용자를 통해 추가 마스터 사용자를 만들 수 있습니다. 자세한 내용은 [AWS 설명서](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-more-masters)를 참조하세요.

권한이 있는 사용자 및 역할을 만들고 사용자를 역할에 매핑하려면 [OpenSearch 설명서](https://opensearch.org/docs/latest/security/access-control/users-roles/)를 참조하세요. 역할에 다음 권한을 포함해야 합니다:

```json
{
  "cluster_permissions": [
    "cluster_composite_ops",
    "cluster_monitor"
  ],
  "index_permissions": [
    {
      "index_patterns": [
        "gitlab*"
      ],
      "allowed_actions": [
        "data_access",
        "manage_aliases",
        "search",
        "create_index",
        "delete",
        "manage"
      ]
    },
    {
      "index_patterns": [
        "*"
      ],
      "allowed_actions": [
        "indices:admin/aliases/get",
        "indices:monitor/stats"
      ]
    }
  ]
}
```

## 열린 TCP 연결 누적 {#accumulation-of-open-tcp-connections}

GitLab 17.11 이상에서는 GitLab 프로세스에서 외부 서비스로의 열린 TCP 연결 수가 증가할 수 있습니다. 이러한 연결은 시간이 지남에 따라 누적되며 제대로 닫히지 않습니다.

이 이슈는 Faraday 어댑터가 GitLab의 연결 풀링을 위해 `net_http`에서 `typhoeus`로 전환되는 것과 관련이 있습니다. 자세한 내용은 [이슈 550805](https://gitlab.com/gitlab-org/gitlab/-/issues/550805)를 참조하세요.

이 이슈를 해결하려면 [`elasticsearch_client_adapter`](../../../api/settings.md#available-settings)를 `net_http`으로 설정하세요.

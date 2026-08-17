---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 토큰 문제 해결
---

GitLab 토큰으로 작업할 때 다음 문제가 발생할 수 있습니다.

## 만료된 액세스 토큰 {#expired-access-tokens}

기존 액세스 토큰이 사용 중이고 `expires_at` 값에 도달하면 토큰이 만료되고:

- 더 이상 인증에 사용할 수 없습니다.
- UI에 표시되지 않습니다.

이 토큰을 사용하여 만든 요청은 `401 Unauthorized` 응답을 반환합니다. 같은 IP 주소에서 짧은 기간 동안 권한이 없는 요청이 많으면 GitLab.com에서 `403 Forbidden` 응답이 반환됩니다.

인증 요청 제한에 대한 자세한 내용은 [Git 및 컨테이너 레지스트리 실패한 인증 금지](../../user/gitlab_com/_index.md#git-and-container-registry-failed-authentication-ban)를 참조하세요.

### 로그에서 만료된 액세스 토큰 식별 {#identify-expired-access-tokens-from-logs}

{{< history >}}

- [GitLab 17.2에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/464652)되었습니다.

{{< /history >}}

전제 조건:

다음 조건을 충족해야 합니다:

- 관리자여야 합니다.
- [`api_json.log`](../../administration/logs/_index.md#api_jsonlog) 파일에 액세스할 수 있어야 합니다.

만료된 액세스 토큰으로 인해 실패하는 `401 Unauthorized` 요청을 식별하려면 `api_json.log` 파일에서 다음 필드를 사용하세요:

| 필드 이름                | 설명 |
|---------------------------|-------------|
| `meta.auth_fail_reason`   | 요청이 거부된 이유입니다. 가능한 값: `token_expired`, `token_revoked`, `insufficient_scope`, `impersonation_disabled`. |
| `meta.auth_fail_token_id` | 시도된 토큰의 유형과 ID를 설명하는 문자열입니다. |

사용자가 만료된 토큰을 사용하려고 할 때 `meta.auth_fail_reason`는 `token_expired`입니다. 다음은 로그 항목의 발췌입니다:

```json
{
  "status": 401,
  "method": "GET",
  "path": "/api/v4/user",
  ...
  "meta.auth_fail_reason": "token_expired",
  "meta.auth_fail_token_id": "PersonalAccessToken/12",
}
```

`meta.auth_fail_token_id`는 ID 12인 액세스 토큰을 사용했음을 나타냅니다. GitLab 18.9부터 `meta.user`도 실패한 요청에 사용된 토큰과 연결된 모든 사용자 이름으로 채워집니다.

이 토큰에 대한 자세한 정보를 확인하려면 [개인 액세스 토큰 API](../../api/personal_access_tokens.md#retrieve-a-personal-access-token)를 사용하세요. API를 사용하여 [토큰 회전](../../api/personal_access_tokens.md#rotate-a-personal-access-token)할 수도 있습니다.

### 만료된 액세스 토큰 교체 {#replace-expired-access-tokens}

토큰을 교체하려면:

1. 이 토큰이 이전에 사용되었을 수 있는 위치를 확인하고 토큰을 계속 사용할 수 있는 모든 자동화에서 제거합니다.
   - 개인 액세스 토큰의 경우 [API](../../api/personal_access_tokens.md#list-all-personal-access-tokens)를 사용하여 최근에 만료된 토큰을 나열합니다. 예를 들어 `https://gitlab.com/api/v4/personal_access_tokens`로 이동하여 특정 `expires_at` 날짜의 토큰을 찾습니다.
   - 프로젝트 액세스 토큰의 경우 [프로젝트 액세스 토큰 API](../../api/project_access_tokens.md#list-all-project-access-tokens)를 사용하여 최근에 만료된 토큰을 나열합니다.
   - 그룹 액세스 토큰의 경우 [그룹 액세스 토큰 API](../../api/group_access_tokens.md#list-all-group-access-tokens)를 사용하여 최근에 만료된 토큰을 나열합니다.
1. 새 액세스 토큰 생성:
   - 개인 액세스 토큰의 경우 [UI 사용](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) 또는 [사용자 토큰 API](../../api/user_tokens.md#create-a-personal-access-token)를 사용합니다.
   - 프로젝트 액세스 토큰의 경우 [UI 사용](../../user/project/settings/project_access_tokens.md#create-a-project-access-token) 또는 [프로젝트 액세스 토큰 API](../../api/project_access_tokens.md#create-a-project-access-token)를 사용합니다.
   - 그룹 액세스 토큰의 경우 [UI 사용](../../user/group/settings/group_access_tokens.md#create-a-group-access-token) 또는 [그룹 액세스 토큰 API](../../api/group_access_tokens.md#create-a-group-access-token)를 사용합니다.
1. 기존 액세스 토큰을 새 액세스 토큰으로 교체합니다. 이 프로세스는 토큰 사용 방식에 따라 다릅니다. 예를 들어 비밀로 구성되었거나 애플리케이션에 포함된 경우입니다. 이 토큰에서 만든 요청은 더 이상 `401` 응답을 반환하지 않아야 합니다.

### 토큰 수명 연장 {#extend-token-lifetime}

이 스크립트로 특정 토큰의 만료를 지연합니다.

GitLab 16.0부터 모든 액세스 토큰에는 만료 날짜가 있습니다. 최소한 GitLab 16.0을 배포한 후 만료되지 않는 모든 액세스 토큰은 배포 날짜로부터 1년 후 만료됩니다.

이 날짜가 다가오고 아직 회전되지 않은 토큰이 있으면 이 스크립트를 사용하여 만료를 지연하고 사용자에게 토큰을 회전할 시간을 더 줄 수 있습니다.

#### 특정 토큰의 수명 연장 {#extend-lifetime-for-specific-tokens}

이 스크립트는 다음을 포함하여 지정된 날짜에 만료되는 모든 토큰의 수명을 연장합니다:

- 개인 액세스 토큰
- 그룹 액세스 토큰
- 프로젝트 액세스 토큰

그룹 및 프로젝트 액세스 토큰의 경우, 이 스크립트는 GitLab 16.0 이상으로 업그레이드할 때 자동으로 만료 날짜가 제공된 경우에만 이러한 토큰의 수명을 연장합니다. 그룹 또는 프로젝트 액세스 토큰이 만료 날짜로 생성되었거나 회전된 경우, 해당 토큰의 유효성은 리소스에 대한 유효한 멤버십에 따라 달라지므로 이 스크립트를 사용하여 토큰 수명을 연장할 수 없습니다.

스크립트를 사용하려면:

{{< tabs >}}

{{< tab title="Rails 콘솔 세션" >}}

1. 터미널 창에서 `sudo gitlab-rails console`로 Rails 콘솔 세션을 시작합니다.
1. 다음 섹션에서 전체 `extend_expiring_tokens.rb` 스크립트를 붙여넣습니다. 원하는 경우 `expiring_date`를 다른 날짜로 변경합니다.
1. <kbd>Enter</kbd>를 누릅니다.

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. 터미널 창에서 인스턴스에 연결합니다.
1. 다음 섹션에서 전체 `extend_expiring_tokens.rb` 스크립트를 복사하여 인스턴스의 파일로 저장합니다:
   - `extend_expiring_tokens.rb`로 이름을 지정합니다.
   - 원하는 경우 `expiring_date`를 다른 날짜로 변경합니다.
   - 파일은 `git:git`에 액세스할 수 있어야 합니다.
1. 이 명령을 실행하고 `/path/to/extend_expiring_tokens.rb`를 `extend_expiring_tokens.rb` 파일의 전체 경로로 변경합니다:

   ```shell
   sudo gitlab-rails runner /path/to/extend_expiring_tokens.rb
   ```

자세한 내용은 [Rails Runner 문제 해결 섹션](../../administration/operations/rails_console.md#troubleshooting)을 참조하세요.

{{< /tab >}}

{{< /tabs >}}

##### `extend_expiring_tokens.rb` {#extend_expiring_tokensrb}

```ruby
expiring_date = Date.new(2024, 5, 30)
new_expires_at = 6.months.from_now

total_updated = PersonalAccessToken
                  .not_revoked
                  .without_impersonation
                  .where(expires_at: expiring_date.to_date)
                  .update_all(expires_at: new_expires_at.to_date)

puts "Updated #{total_updated} tokens with new expiry date #{new_expires_at}"
```

## 개인 액세스 토큰 복원 {#restore-a-personal-access-token}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Self-Managed 또는 GitLab Dedicated 인스턴스에서 관리자는 실수로 취소된 개인 액세스 토큰을 복원할 수 있습니다. GitLab.com에서는 복원을 사용할 수 없습니다.

> [!warning]
> 다음 명령을 실행하면 데이터가 직접 변경됩니다. 올바르게 수행하지 않거나 올바른 조건 없이 수행하면 손상될 수 있습니다. 먼저 인스턴스의 백업이 복원될 준비가 된 테스트 환경에서 이러한 명령을 실행해야 합니다.

1. [Rails 콘솔](../../administration/operations/rails_console.md#starting-a-rails-console-session)을 엽니다.
1. 토큰 복원:

   ```ruby
   token = PersonalAccessToken.find_by_token('<token_string>')
   token.update!(revoked:false)
   ```

   예를 들어 `token-string-here123`의 토큰을 복원하려면:

   ```ruby
   token = PersonalAccessToken.find_by_token('token-string-here123')
   token.update!(revoked:false)
   ```

## 특정 날짜에 만료되는 개인 액세스 토큰, 프로젝트 액세스 토큰, 및 그룹 액세스 토큰 식별 {#identify-personal-project-and-group-access-tokens-expiring-on-a-certain-date}

만료 날짜가 없는 액세스 토큰은 무기한 유효하며, 이는 액세스 토큰이 공개된 경우 보안 위험입니다.

이 위험을 관리하기 위해 GitLab 16.0 이상으로 업그레이드할 때 만료 날짜가 없는 모든 [개인 액세스 토큰](../../user/profile/personal_access_tokens.md), [프로젝트 액세스 토큰](../../user/project/settings/project_access_tokens.md), 또는 [그룹](../../user/group/settings/group_access_tokens.md) 액세스 토큰에는 업그레이드 날짜로부터 1년 후의 만료 날짜가 자동으로 설정됩니다.

GitLab 17.3 이상에서는 기존 토큰에 대한 자동 만료 설정이 되돌려졌으며 [새 액세스 토큰에 대한 만료 날짜 강제 비활성화](../../administration/settings/account_and_limit_settings.md#require-expiration-dates-for-new-access-tokens)할 수 있습니다.

날짜가 변경되어 토큰이 언제 만료되는지 알 수 없으면 해당 날짜에 GitLab에 로그인하려고 할 때 예기치 않은 인증 실패가 발생할 수 있습니다.

이 문제를 관리하려면 GitLab 17.2 이상으로 업그레이드해야 합니다. 이러한 버전에는 [토큰 만료 날짜 분석, 연장 또는 제거를 지원하는 도구](../../administration/raketasks/tokens/_index.md)가 포함되어 있습니다.

도구를 실행할 수 없으면 GitLab Self-Managed 인스턴스에서 스크립트를 실행하여 다음 토큰을 식별할 수 있습니다:

- 특정 날짜에 만료됩니다.
- 만료 날짜가 없습니다.

터미널 창에서 다음 중 하나로부터 이러한 스크립트를 실행합니다:

- [Rails 콘솔 세션](../../administration/operations/rails_console.md#starting-a-rails-console-session).
- [Rails Runner](../../administration/operations/rails_console.md#using-the-rails-runner)를 사용합니다.

GitLab 16.0 이상으로 업그레이드했는지 여부에 따라 실행하는 특정 스크립트가 다릅니다:

- 아직 GitLab 16.0 이상으로 업그레이드하지 않았으면 만료 날짜가 없는 토큰을 식별합니다.
- GitLab 16.0 이상으로 업그레이드한 경우 스크립트를 사용하여 다음을 식별합니다:
  - [특정 날짜에 만료되는 토큰](#find-all-tokens-expiring-on-a-specific-date).
  - [특정 월에 만료되는 토큰](#find-tokens-expiring-in-a-given-month).
  - [많은 토큰이 만료되는 날짜](#identify-dates-when-many-tokens-expire).

이 문제의 영향을 받는 토큰을 식별한 후 필요한 경우 최종 스크립트를 실행하여 특정 토큰의 수명을 연장할 수 있습니다.

이러한 스크립트는 다음 형식으로 결과를 반환합니다:

```plaintext
Expired group access token in Group ID 25, Token ID: 8, Name: Example Token, Scopes: ["read_api", "create_runner"], Last used:
Expired project access token in Project ID 2, Token ID: 9, Name: Test Token, Scopes: ["api", "read_registry", "write_registry"], Last used: 2022-02-11 13:22:14 UTC
```

자세한 내용은 [incident 18003](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18003)을 참조하세요.

### 특정 날짜에 만료되는 모든 토큰 찾기 {#find-all-tokens-expiring-on-a-specific-date}

이 스크립트는 특정 날짜에 만료되는 토큰을 찾습니다.

전제 조건:

- 인스턴스가 GitLab 16.0으로 업그레이드된 정확한 날짜를 알아야 합니다.

사용하려면:

{{< tabs >}}

{{< tab title="Rails 콘솔 세션" >}}

1. 터미널 창에서 인스턴스에 연결합니다.
1. `sudo gitlab-rails console`로 Rails 콘솔 세션을 시작합니다.
1. 필요에 따라 다음 섹션에서 전체 `expired_tokens.rb`를 복사하거나 그 다음 섹션에서 `expired_tokens_date_range.rb` 스크립트를 복사하여 콘솔에 붙여넣습니다. `expires_at_date`를 인스턴스가 GitLab 16.0으로 업그레이드된 후 1년 후의 날짜로 변경합니다.
1. <kbd>Enter</kbd>를 누릅니다.

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. 터미널 창에서 인스턴스에 연결합니다.
1. 필요에 따라 다음 섹션에서 전체 `expired_tokens.rb`를 복사하거나 그 다음 섹션에서 `expired_tokens_date_range.rb` 스크립트를 복사하여 인스턴스의 파일로 저장합니다:
   - `expired_tokens.rb`로 이름을 지정합니다.
   - `expires_at_date`를 인스턴스가 GitLab 16.0으로 업그레이드된 후 1년 후의 날짜로 변경합니다.
   - 파일은 `git:git`에 액세스할 수 있어야 합니다.
1. 이 명령을 실행하고 경로를 `expired_tokens.rb` 파일의 전체 경로로 변경합니다:

   ```shell
   sudo gitlab-rails runner /path/to/expired_tokens.rb
   ```

자세한 내용은 [Rails Runner 문제 해결 섹션](../../administration/operations/rails_console.md#troubleshooting)을 참조하세요.

{{< /tab >}}

{{< /tabs >}}

#### `expired_tokens.rb` {#expired_tokensrb}

이 스크립트를 사용하려면 GitLab 인스턴스가 GitLab 16.0으로 업그레이드된 정확한 날짜를 알아야 합니다.

```ruby
# Change this value to the date one year after your GitLab instance was upgraded.

expires_at_date = "2024-05-22"

# Check for expiring personal access tokens
PersonalAccessToken.for_user_types(:human).where(expires_at: expires_at_date).find_each do |token|
  if token.user.blocked?
    next
    # Hide unusable, blocked PATs from output
  end

  puts "Expired personal access token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
end

# Check for expiring project and group access tokens
PersonalAccessToken.project_access_token.where(expires_at: expires_at_date).find_each do |token|
  token.user.members.each do |member|
    type = member.is_a?(GroupMember) ? 'Group' : 'Project'

    puts "Expired #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
  end
end
```

> [!note]
> 차단된 사용자에 속한 토큰을 숨기고 제거하려면 `token.destroy!`를 `if token.user.blocked?` 바로 아래에 추가합니다. 그러나 이 작업은 [API 메서드](../../api/personal_access_tokens.md#revoke-a-personal-access-token)와 달리 감사 이벤트를 남기지 않습니다.

### 주어진 월에 만료되는 토큰 찾기 {#find-tokens-expiring-in-a-given-month}

이 스크립트는 특정 월에 만료되는 토큰을 찾습니다. 인스턴스가 GitLab 16.0으로 업그레이드된 정확한 날짜를 알 필요가 없습니다. 사용하려면:

{{< tabs >}}

{{< tab title="Rails 콘솔 세션" >}}

1. 터미널 창에서 `sudo gitlab-rails console`로 Rails 콘솔 세션을 시작합니다.
1. 다음 섹션에서 전체 `expired_tokens_date_range.rb` 스크립트를 붙여넣습니다. 원하는 경우 `date_range`를 다른 범위로 변경합니다.
1. <kbd>Enter</kbd>를 누릅니다.

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. 터미널 창에서 인스턴스에 연결합니다.
1. 다음 섹션에서 전체 `expired_tokens_date_range.rb` 스크립트를 복사하여 인스턴스의 파일로 저장합니다:
   - `expired_tokens_date_range.rb`로 이름을 지정합니다.
   - 원하는 경우 `date_range`를 다른 범위로 변경합니다.
   - 파일은 `git:git`에 액세스할 수 있어야 합니다.
1. 이 명령을 실행하고 `/path/to/expired_tokens_date_range.rb`를 `expired_tokens_date_range.rb` 파일의 전체 경로로 변경합니다:

   ```shell
   sudo gitlab-rails runner /path/to/expired_tokens_date_range.rb
   ```

자세한 내용은 [Rails Runner 문제 해결 섹션](../../administration/operations/rails_console.md#troubleshooting)을 참조하세요.

{{< /tab >}}

{{< /tabs >}}

#### `expired_tokens_date_range.rb` {#expired_tokens_date_rangerb}

```ruby
# This script enables you to search for tokens that expire within a
# certain date range (like 1.month) from the current date. Use it if
# you're unsure when exactly your GitLab 16.0 upgrade completed.

date_range = 1.month

# Check for personal access tokens
PersonalAccessToken.for_user_types(:human).where(expires_at: Date.today .. Date.today + date_range).find_each do |token|
  puts "Expired personal access token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
end

# Check for expiring project and group access tokens
PersonalAccessToken.project_access_token.where(expires_at: Date.today .. Date.today + date_range).find_each do |token|
  token.user.members.each do |member|
    type = member.is_a?(GroupMember) ? 'Group' : 'Project'

    puts "Expired #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
  end
end
```

### 많은 토큰이 만료되는 날짜 식별 {#identify-dates-when-many-tokens-expire}

이 스크립트는 대부분의 토큰이 만료되는 날짜를 식별합니다. 이를 이 페이지의 다른 스크립트와 함께 사용하여 팀이 아직 토큰 회전을 설정하지 않은 경우 만료 날짜가 다가올 수 있는 많은 토큰 배치를 식별하고 연장할 수 있습니다.

스크립트는 다음 형식으로 결과를 반환합니다:

```plaintext
42 Personal access tokens will expire at 2024-06-27
17 Personal access tokens will expire at 2024-09-23
3 Personal access tokens will expire at 2024-08-13
```

사용하려면:

{{< tabs >}}

{{< tab title="Rails 콘솔 세션" >}}

1. 터미널 창에서 `sudo gitlab-rails console`로 Rails 콘솔 세션을 시작합니다.
1. 전체 `dates_when_most_of_tokens_expire.rb` 스크립트를 붙여넣습니다.
1. <kbd>Enter</kbd>를 누릅니다.

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. 터미널 창에서 인스턴스에 연결합니다.
1. 전체 `dates_when_most_of_tokens_expire.rb` 스크립트를 복사하여 인스턴스의 파일로 저장합니다:
   - `dates_when_most_of_tokens_expire.rb`로 이름을 지정합니다.
   - 파일은 `git:git`에 액세스할 수 있어야 합니다.
1. 이 명령을 실행하고 `/path/to/dates_when_most_of_tokens_expire.rb`를 `dates_when_most_of_tokens_expire.rb` 파일의 전체 경로로 변경합니다:

   ```shell
   sudo gitlab-rails runner /path/to/dates_when_most_of_tokens_expire.rb
   ```

자세한 내용은 [Rails Runner 문제 해결 섹션](../../administration/operations/rails_console.md#troubleshooting)을 참조하세요.

{{< /tab >}}

{{< /tabs >}}

#### `dates_when_most_of_tokens_expire.rb` {#dates_when_most_of_tokens_expirerb}

```ruby
PersonalAccessToken
  .select(:expires_at, Arel.sql('count(*)'))
  .where('expires_at >= NOW()')
  .group(:expires_at)
  .order(Arel.sql('count(*) DESC'))
  .limit(10)
  .each do |token|
    puts "#{token.count} Personal access tokens will expire at #{token.expires_at}"
  end
```

### 만료 날짜가 없는 토큰 찾기 {#find-tokens-with-no-expiration-date}

이 스크립트는 만료 날짜가 없는 토큰을 찾습니다: `expires_at`은 `NULL`입니다. GitLab 버전 16.0 이상으로 아직 업그레이드하지 않은 사용자의 경우 토큰 `expires_at` 값은 `NULL`이며 만료 날짜를 추가할 토큰을 식별하는 데 사용할 수 있습니다.

[Rails 콘솔](../../administration/operations/rails_console.md) 또는 [Rails Runner](../../administration/operations/rails_console.md#using-the-rails-runner)에서 이 스크립트를 사용할 수 있습니다:

{{< tabs >}}

{{< tab title="Rails 콘솔 세션" >}}

1. 터미널 창에서 인스턴스에 연결합니다.
1. `sudo gitlab-rails console`로 Rails 콘솔 세션을 시작합니다.
1. 다음 섹션에서 전체 `tokens_with_no_expiry.rb` 스크립트를 붙여넣습니다.
1. <kbd>Enter</kbd>를 누릅니다.

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. 터미널 창에서 인스턴스에 연결합니다.
1. 다음 섹션에서 전체 `tokens_with_no_expiry.rb` 스크립트를 복사하여 인스턴스의 파일로 저장합니다:
   - `tokens_with_no_expiry.rb`로 이름을 지정합니다.
   - 파일은 `git:git`에 액세스할 수 있어야 합니다.
1. 이 명령을 실행하고 경로를 `tokens_with_no_expiry.rb` 파일의 전체 경로로 변경합니다:

   ```shell
   sudo gitlab-rails runner /path/to/tokens_with_no_expiry.rb
   ```

자세한 내용은 [Rails Runner 문제 해결 섹션](../../administration/operations/rails_console.md#troubleshooting)을 참조하세요.

{{< /tab >}}

{{< /tabs >}}

#### `tokens_with_no_expiry.rb` {#tokens_with_no_expiryrb}

이 스크립트는 `expires_at`에 대해 설정된 값이 없는 토큰을 찾습니다.

   ```ruby
   # This script finds tokens which do not have an expires_at value set.

   # Check for expiring personal access tokens
   PersonalAccessToken.for_user_types(:human).where(expires_at: nil).find_each do |token|
     puts "Expires_at is nil for personal access token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
   end

   # Check for expiring project and group access tokens
   PersonalAccessToken.project_access_token.where(expires_at: nil).find_each do |token|
     token.user.members.each do |member|
       type = member.is_a?(GroupMember) ? 'Group' : 'Project'

       puts "Expires_at is nil for #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
     end
   end
   ```

---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: LDAP 문제 해결
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

관리자인 경우 다음 정보를 사용하여 LDAP 문제를 해결합니다.

## 일반적인 문제 및 워크플로우 {#common-problems--workflows}

### 연결 {#connection}

#### 연결 거부됨 {#connection-refused}

`Connection Refused` 오류 메시지가 표시되는 경우 LDAP 서버에 연결하려고 할 때 GitLab에서 사용하는 LDAP `port` 및 `encryption` 설정을 검토하세요. 일반적인 조합은 `encryption: 'plain'` 및 `port: 389`, 또는 `encryption: 'simple_tls'` 및 `port: 636`입니다.

#### 연결 시간 초과 {#connection-times-out}

GitLab이 LDAP 엔드포인트에 도달할 수 없는 경우 다음과 같은 메시지가 표시됩니다:

```plaintext
Could not authenticate you from Ldapmain because "Connection timed out - user specified timeout".
```

구성된 LDAP 공급자 및/또는 엔드포인트가 오프라인이거나 GitLab에서 도달할 수 없는 경우 LDAP 사용자는 인증하고 로그인할 수 없습니다. GitLab은 LDAP 서비스 중단 중에 인증을 제공하기 위해 LDAP 사용자의 자격 증명을 캐시하거나 저장하지 않습니다.

이 오류가 표시되면 LDAP 공급자 또는 관리자에게 문의하세요.

#### 조회 오류 {#referral-error}

로그에 `LDAP search error: Referral`이(가) 표시되거나 LDAP 그룹 동기화 문제를 해결할 때 이 오류는 구성 문제를 나타낼 수 있습니다. LDAP 구성 `/etc/gitlab/gitlab.rb`(Omnibus) 또는 `config/gitlab.yml`(소스)은 YAML 형식이며 들여쓰기에 민감합니다. `group_base` 및 `admin_group` 구성 키가 서버 식별자보다 2칸 들여쓰기되어 있는지 확인하세요. 기본 식별자는 `main`이며 예제 스니펫은 다음과 같습니다:

```yaml
main: # 'main' is the GitLab 'provider ID' of this LDAP server
  label: 'LDAP'
  host: 'ldap.example.com'
  # ...
  group_base: 'cn=my_group,ou=groups,dc=example,dc=com'
  admin_group: 'my_admin_group'
```

#### LDAP 쿼리 {#query-ldap}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음은 rails 콘솔을 사용하여 LDAP에서 검색을 수행할 수 있습니다. 수행하려는 작업에 따라 [사용자](#query-a-user-in-ldap) 나 [그룹](#query-a-group-in-ldap) 을 직접 쿼리하거나, [`ldapsearch`](#ldapsearch)을(를) 사용하는 것이 더 나을 수 있습니다.

```ruby
adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain')
options = {
    # :base is required
    # use .base or .group_base
    base: adapter.config.group_base,

    # :filter is optional
    # 'cn' looks for all "cn"s under :base
    # '*' is the search string - here, it's a wildcard
    filter: Net::LDAP::Filter.eq('cn', '*'),

    # :attributes is optional
    # the attributes we want to get returned
    attributes: %w(dn cn memberuid member submember uniquemember memberof)
}
adapter.ldap_search(options)
```

필터에서 OID를 사용할 때 `Net::LDAP::Filter.eq`을(를) `Net::LDAP::Filter.construct`로 바꾸세요:

```ruby
adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain')
options = {
    # :base is required
    # use .base or .group_base
    base: adapter.config.base,

    # :filter is optional
    # This filter includes OID 1.2.840.113556.1.4.1941
    # It will search for all direct and nested members of the group gitlab_grp in the LDAP directory
    filter: Net::LDAP::Filter.construct("(memberOf:1.2.840.113556.1.4.1941:=CN=gitlab_grp,DC=example,DC=com)"),

    # :attributes is optional
    # the attributes we want to get returned
    attributes: %w(dn cn memberuid member submember uniquemember memberof)
}
adapter.ldap_search(options)
```

이것을 실행하는 방법의 예는 [`Adapter` 모듈을 검토하세요](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/auth/ldap/adapter.rb).

### 사용자 로그인 {#user-sign-ins}

#### 사용자를 찾을 수 없음 {#no-users-are-found}

LDAP에 대한 연결을 [확인했지만](#ldap-check) GitLab에서 출력에 LDAP 사용자를 표시하지 않는 경우 다음 중 하나가 가장 가능성이 높습니다:

- `bind_dn` 사용자에게 사용자 트리를 순회할 수 있는 충분한 권한이 없습니다.
- 사용자가 [구성된 `base`](_index.md#configure-ldap) 범위를 벗어납니다.
- [구성된 `user_filter`](_index.md#set-up-ldap-user-filter)이(가) 사용자에 대한 액세스를 차단합니다.

이 경우 [ldapsearch](#ldapsearch)와 기존 LDAP 구성을 `/etc/gitlab/gitlab.rb`에서 사용하여 이전 중 어느 것이 참인지 확인할 수 있습니다.

#### 사용자가 로그인할 수 없음 {#users-cannot-sign-in}

사용자는 여러 가지 이유로 로그인에 문제가 있을 수 있습니다. 시작하기 위해 다음은 자신에게 물어볼 몇 가지 질문입니다:

- 사용자가 LDAP의 [구성된 `base`](_index.md#configure-ldap) 범위에 속하나요? 사용자는 이 `base`에 로그인하기 위해 범위 내에 있어야 합니다.
- [구성된 `user_filter`](_index.md#set-up-ldap-user-filter)을(를) 통과하나요? 구성된 것이 없으면 이 질문은 무시할 수 있습니다. 구성된 것이 있으면 사용자가 이 필터를 통과해야 로그인할 수 있습니다.
  - [`user_filter` 디버깅에 대한 설명서를 참조하세요](#debug-ldap-user-filter).

이전 질문이 모두 괜찮으면 이슈를 찾기 위한 다음 위치는 이슈를 재현하는 동안의 로그 자체입니다.

- 사용자에게 로그인하도록 요청하고 실패하도록 하세요.
- [출력을 살펴보세요](#gitlab-logs) 로그인에 대한 오류 또는 기타 메시지. 이 페이지에서 다른 오류 메시지 중 하나를 볼 수 있으며, 해당 섹션이 이슈를 해결하는 데 도움이 될 수 있습니다.

로그가 문제의 원인으로 이어지지 않으면 [rails 콘솔](#rails-console) 을 사용하여 [이 사용자를 쿼리](#query-a-user-in-ldap)하여 GitLab이 LDAP 서버에서 이 사용자를 읽을 수 있는지 확인하세요.

[사용자 동기화를 디버그](#sync-all-users)하여 추가 조사를 수행할 수도 있습니다.

#### 사용자에게 오류 `Invalid login or password.` 표시 {#users-see-an-error-invalid-login-or-password}

{{< history >}}

- GitLab 16.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/438144)되었습니다.

{{< /history >}}

사용자가 이 오류를 보는 경우 **LDAP** 로그인 양식 대신 **표준** 로그인 양식을 사용하여 로그인하려고 할 수 있습니다.

해결하려면 사용자에게 **LDAP** 로그인 양식에 LDAP 사용자 이름과 비밀번호를 입력하도록 요청하세요.

#### 로그인 시 잘못된 자격 증명 {#invalid-credentials-on-sign-in}

로그인 자격 증명이 LDAP에서 정확한 경우 해당 사용자에 대해 다음을 확인하세요:

- 바인딩하는 사용자가 사용자의 트리를 읽고 순회할 수 있는 충분한 권한이 있는지 확인하세요.
- `user_filter`이(가) 유효한 사용자를 차단하지 않는지 확인하세요.
- [LDAP 확인 명령](#ldap-check) 을(를) 실행하여 LDAP 설정이 올바르고 [GitLab에서 사용자를 볼 수 있는지](#no-users-are-found) 확인하세요.

#### LDAP 계정에 대한 액세스가 거부됨 {#access-denied-for-your-ldap-account}

[버그](https://gitlab.com/gitlab-org/gitlab/-/issues/235930) 가 있을 수 있으며 [감사자 수준 액세스](../../auditor_users.md)가 있는 사용자에게 영향을 줄 수 있습니다. Premium/Ultimate에서 다운그레이드할 때 로그인하려는 감사자 사용자에게 다음 메시지가 표시될 수 있습니다. `Access denied for your LDAP account`.

이 문제를 해결하려면 영향을 받은 사용자의 액세스 수준을 변경합니다.

전제 조건:

- 운영자 액세스

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택하세요.
1. 영향을 받은 사용자의 이름을 선택하세요.
1. 오른쪽 상단 모서리에서 **편집**을 선택하세요.
1. 사용자의 액세스 수준을 `Regular`에서 `Administrator`(으)로 변경하세요.
1. 페이지 하단에서 **변경사항 저장**을 선택하세요.
1. 오른쪽 상단 모서리에서 **편집**을 다시 선택하세요.
1. 사용자의 원래 액세스 수준(`Regular` 또는 `Administrator`)을 복원하고 **변경사항 저장**을 다시 선택하세요.

이제 사용자가 로그인할 수 있어야 합니다.

#### 이메일이 이미 사용 중임 {#email-has-already-been-taken}

사용자가 올바른 LDAP 자격 증명으로 로그인하려고 시도하고 액세스가 거부되며 [production.log](../../logs/_index.md#productionlog)에서 다음과 같은 오류를 표시합니다:

```plaintext
(LDAP) Error saving user <USER DN> (email@example.com): ["Email has already been taken"]
```

이 오류는 LDAP의 이메일 주소 `email@example.com`을(를) 나타냅니다. 이메일 주소는 GitLab에서 고유해야 하며 LDAP는 사용자의 기본 이메일(가능한 여러 보조 이메일과 반대)에 링크됩니다. 다른 사용자(또는 동일한 사용자)가 이메일 `email@example.com`을(를) 보조 이메일로 설정했으며 이로 인해 이 오류가 발생합니다.

[rails 콘솔](#rails-console)을(를) 사용하여 이 충돌하는 이메일 주소의 출처를 확인할 수 있습니다. 콘솔에서 다음을 실행하세요:

```ruby
# This searches for an email among the primary AND secondary emails
user = User.find_by_any_email('email@example.com')
user.username
```

이 이메일 주소를 가진 사용자를 보여줍니다. 여기서 두 가지 단계 중 하나를 수행해야 합니다:

- LDAP로 로그인할 때 이 사용자를 위해 새 GitLab 사용자/사용자 이름을 만들려면 보조 이메일을 제거하여 충돌을 제거합니다.
- 이 사용자가 LDAP를 사용할 기존 GitLab 사용자/사용자 이름을 사용하려면 이 이메일을 보조 이메일로 제거하고 기본 이메일로 설정하여 GitLab이 이 프로필을 LDAP ID와 연결하도록 합니다.

사용자는 [프로필에서](../../../user/profile/_index.md#access-your-user-profile) 이러한 단계 중 하나를 수행하거나 관리자가 수행할 수 있습니다.

#### 프로젝트 한도 오류 {#projects-limit-errors}

다음 오류는 제한 또는 제한이 활성화되었지만 연결된 데이터 필드에 데이터가 없음을 나타냅니다:

- `Projects limit can't be blank`.
- `Projects limit is not a number`.

이를 해결하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. 다음 두 가지를 모두 펼치세요:
   - **계정과 제한**.
   - **사용자 계정 생성 제한사항**.
1. 예를 들어 **기본 프로젝트 한도** 또는 **Allowed domains for new user accounts** 필드를 확인하고 관련 값이 구성되어 있는지 확인하세요.

#### LDAP 사용자 필터 디버그 {#debug-ldap-user-filter}

[`ldapsearch`](#ldapsearch) 을(를) 사용하면 구성된 [사용자 필터](_index.md#set-up-ldap-user-filter)를 테스트하여 예상하는 사용자를 반환하는지 확인할 수 있습니다.

```shell
ldapsearch -H ldaps://$host:$port -D "$bind_dn" -y bind_dn_password.txt  -b "$base" "$user_filter" sAMAccountName
```

- `$`로 시작하는 변수는 구성 파일의 LDAP 섹션의 변수를 참조합니다.
- 일반 인증 방법을 사용 중인 경우 `ldaps://`을(를) `ldap://`로 바꾸세요. 포트 `389`은(는) 기본 `ldap://` 포트이고 `636`은(는) 기본 `ldaps://` 포트입니다.
- `bind_dn` 사용자의 비밀번호가 `bind_dn_password.txt`에 있다고 가정합니다.

#### 모든 사용자 동기화 {#sync-all-users}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

수동 [사용자 동기화](ldap_synchronization.md#user-sync)의 출력은 GitLab이 해당 사용자를 LDAP과 동기화하려고 할 때 발생하는 상황을 보여줍니다. [rails 콘솔](#rails-console)을(를) 입력한 다음 실행하세요:

```ruby
Rails.logger.level = Logger::DEBUG

LdapSyncWorker.new.perform
```

그 다음 [출력을 읽는 방법을 알아보세요](#example-console-output-after-a-user-sync).

##### 사용자 동기화 후 예제 콘솔 출력 {#example-console-output-after-a-user-sync}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

[수동 사용자 동기화](#sync-all-users)의 출력은 매우 자세하며 단일 사용자의 성공적인 동기화는 다음과 같을 수 있습니다:

```shell
Syncing user John, email@example.com
  Identity Load (0.9ms)  SELECT  "identities".* FROM "identities" WHERE "identities"."user_id" = 20 AND (provider LIKE 'ldap%') LIMIT 1
Instantiating Gitlab::Auth::Ldap::Person with LDIF:
dn: cn=John Smith,ou=people,dc=example,dc=com
cn: John Smith
mail: email@example.com
memberof: cn=admin_staff,ou=people,dc=example,dc=com
uid: John

  UserSyncedAttributesMetadata Load (0.9ms)  SELECT  "user_synced_attributes_metadata".* FROM "user_synced_attributes_metadata" WHERE "user_synced_attributes_metadata"."user_id" = 20 LIMIT 1
   (0.3ms)  BEGIN
  Namespace Load (1.0ms)  SELECT  "namespaces".* FROM "namespaces" WHERE "namespaces"."owner_id" = 20 AND "namespaces"."type" IS NULL LIMIT 1
  Route Load (0.8ms)  SELECT  "routes".* FROM "routes" WHERE "routes"."source_id" = 27 AND "routes"."source_type" = 'Namespace' LIMIT 1
  Ci::Runner Load (1.1ms)  SELECT "ci_runners".* FROM "ci_runners" INNER JOIN "ci_runner_namespaces" ON "ci_runners"."id" = "ci_runner_namespaces"."runner_id" WHERE "ci_runner_namespaces"."namespace_id" = 27
   (0.7ms)  COMMIT
   (0.4ms)  BEGIN
  Route Load (0.8ms)  SELECT "routes".* FROM "routes" WHERE (LOWER("routes"."path") = LOWER('John'))
  Namespace Load (1.0ms)  SELECT  "namespaces".* FROM "namespaces" WHERE "namespaces"."id" = 27 LIMIT 1
  Route Exists (0.9ms)  SELECT  1 AS one FROM "routes" WHERE LOWER("routes"."path") = LOWER('John') AND "routes"."id" != 50 LIMIT 1
  User Update (1.1ms)  UPDATE "users" SET "updated_at" = '2019-10-17 14:40:59.751685', "last_credential_check_at" = '2019-10-17 14:40:59.738714' WHERE "users"."id" = 20
```

여기에는 많은 것이 있으므로 디버깅할 때 도움이 될 수 있는 것을 살펴보겠습니다.

먼저 GitLab은 이전에 LDAP로 로그인한 모든 사용자를 찾아 반복합니다. 각 사용자의 동기화는 사용자의 사용자 이름과 이메일이 현재 GitLab에 존재하는지 포함하는 다음 줄로 시작합니다:

```shell
Syncing user John, email@example.com
```

출력에서 특정 사용자의 GitLab 이메일을 찾을 수 없는 경우 해당 사용자는 아직 LDAP로 로그인하지 않았습니다.

그 다음 GitLab은 해당 사용자와 구성된 LDAP 공급자 간의 기존 링크를 위해 `identities` 테이블을 검색합니다:

```sql
  Identity Load (0.9ms)  SELECT  "identities".* FROM "identities" WHERE "identities"."user_id" = 20 AND (provider LIKE 'ldap%') LIMIT 1
```

ID 개체에는 GitLab이 LDAP에서 사용자를 찾는 데 사용하는 DN이 있습니다. DN을 찾을 수 없으면 이메일이 대신 사용됩니다. 이 사용자가 LDAP에서 발견되었는지 확인할 수 있습니다:

```shell
Instantiating Gitlab::Auth::Ldap::Person with LDIF:
dn: cn=John Smith,ou=people,dc=example,dc=com
cn: John Smith
mail: email@example.com
memberof: cn=admin_staff,ou=people,dc=example,dc=com
uid: John
```

DN 또는 이메일로 LDAP에서 사용자를 찾을 수 없는 경우 대신 다음 메시지가 표시될 수 있습니다:

```shell
LDAP search error: No Such Object
```

이 경우 사용자가 차단됩니다:

```shell
  User Update (0.4ms)  UPDATE "users" SET "state" = $1, "updated_at" = $2 WHERE "users"."id" = $3  [["state", "ldap_blocked"], ["updated_at", "2019-10-18 15:46:22.902177"], ["id", 20]]
```

사용자가 LDAP에서 발견된 후 출력의 나머지 부분은 GitLab 데이터베이스를 모든 변경 사항으로 업데이트합니다.

#### LDAP에서 사용자 쿼리 {#query-a-user-in-ldap}

이는 GitLab이 LDAP에 도달하여 특정 사용자를 읽을 수 있는지 테스트합니다. GitLab UI에서 자동으로 실패할 수 있는 LDAP 연결 및/또는 쿼리 오류를 노출할 수 있습니다.

```ruby
Rails.logger.level = Logger::DEBUG

adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain') # If `main` is the LDAP provider
Gitlab::Auth::Ldap::Person.find_by_uid('<uid>', adapter)
```

### 머지 리퀘스트 승인 규칙 {#merge-request-approval-rules}

LDAP 연결 이슈가 발생하면 동기화 작업 중에 사용자가 머지 리퀘스트 승인 규칙에서 제거될 수 있습니다. 이로 인해 승인 규칙이 비워지고 무효로 표시될 수 있습니다.

#### LDAP 연결이 손실될 때 승인 규칙 실패 {#approval-rules-fail-when-ldap-connectivity-is-lost}

LDAP 서버가 일시적으로 사용 불가능하거나 바인드 계정이 실패하는 경우:

- LDAP 기반 승인 규칙에 구성된 사용자가 다음 동기화 주기 중에 제거될 수 있습니다.
- 남은 사용자가 없는 승인 규칙은 [무효](../../../user/project/merge_requests/approvals/_index.md#invalid-rules)가 됩니다.
- 표준 승인 규칙은 **자동 승인**으로 표시되며 더 이상 병합을 차단하지 않습니다.
- 머지 리퀘스트 승인 정책 규칙은 **조치 필요**로 표시되며 계속 병합을 차단합니다.

표준 승인 규칙이 자동으로 무시되지 않도록 방지하려면:

- LDAP 서버가 높은 가용성과 안정적인 연결을 갖도록 하세요.
- LDAP 동기화 작업 실패를 모니터링하세요.
- 중요한 보안 요구 사항을 위해 표준 승인 규칙 대신 [머지 리퀘스트 승인 정책](../../../user/application_security/policies/merge_request_approval_policies.md)을(를) 사용하세요. 승인 정책은 더 강력한 적용을 제공하며 열린 상태로 실패하지 않습니다.

승인 규칙 동작에 대한 자세한 정보는 [무효 규칙](../../../user/project/merge_requests/approvals/_index.md#invalid-rules)을(를) 참조하세요.

사용자가 LDAP 이슈로 인해 승인 규칙에서 제거된 경우 LDAP 연결이 복구될 때 자동으로 다시 추가되지 않습니다. 승인 규칙을 수동으로 복원하거나 백업에서 복구해야 할 수도 있습니다.

### 그룹 멤버십 {#group-memberships}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

#### 멤버십이 부여되지 않음 {#memberships-not-granted}

특정 사용자를 LDAP 그룹 동기화를 통해 GitLab 그룹에 추가해야 한다고 생각하지만 어떤 이유로 발생하지 않는 경우가 있습니다. 상황을 디버그하기 위해 확인할 수 있는 여러 가지가 있습니다.

- LDAP 구성에 `group_base`이(가) 지정되어 있는지 확인하세요. [이 구성](ldap_synchronization.md#group-sync)은 그룹 동기화가 제대로 작동하기 위해 필요합니다.
- 올바른 [LDAP 그룹 링크가 GitLab 그룹에 추가되어 있는지](ldap_synchronization.md#add-group-links) 확인하세요.
- 사용자가 LDAP ID를 가지고 있는지 확인하세요:
  1. 관리자 사용자로 GitLab에 로그인하세요.
  1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
  1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택하세요.
  1. 사용자를 검색하세요.
  1. 이름을 선택하여 사용자를 열다. **편집**을 선택하지 마세요.
  1. **ID** 탭을 선택하세요. LDAP ID가 `Identifier`인 LDAP DN이 있어야 합니다. 없으면 이 사용자는 아직 LDAP로 로그인하지 않았으며 먼저 그렇게 해야 합니다.
- 1시간을 기다렸거나 그룹이 동기화되도록 [구성된 간격](ldap_synchronization.md#adjust-ldap-sync-schedule)을(를) 기다렸습니다. 프로세스를 빠르게 하려면 GitLab 그룹 **관리** > **멤버**로 이동하여 **Sync now** (한 그룹 동기화)를 누르거나 [그룹 동기화 Rake 작업을 실행](../../raketasks/ldap.md#run-a-group-sync)하세요 (모든 그룹 동기화).

모든 확인이 정상이면 rails 콘솔에서 고급 디버깅으로 이동합니다.

1. [rails 콘솔](#rails-console)을(를) 입력하세요.
1. 테스트할 GitLab 그룹을 선택합니다. 이 그룹은 이미 구성된 LDAP 그룹 링크를 가져야 합니다.
1. 디버그 로깅을 사용하고 선택한 GitLab 그룹을 찾아 [LDAP와 동기화](#sync-one-group)합니다.
1. 동기화의 출력을 살펴보세요. [예제 로그 출력](#example-console-output-after-a-group-sync)을(를) 참조하여 출력을 읽는 방법을 알아보세요.
1. 사용자가 추가되지 않는 이유를 여전히 알 수 없는 경우 [LDAP 그룹을 직접 쿼리](#query-a-group-in-ldap)하여 나열된 멤버를 확인하세요.
1. 쿼리된 그룹의 목록 중 하나에 사용자의 DN 또는 UID가 있습니까? DN 또는 UID 중 하나가 이전에 확인한 LDAP ID의 '식별자'와 일치해야 합니다. 그렇지 않으면 사용자가 LDAP 그룹에 없는 것으로 보입니다.

#### LDAP 동기화가 활성화된 경우 서비스 계정 사용자를 그룹에 추가할 수 없음 {#cannot-add-service-account-user-to-group-when-ldap-sync-is-enabled}

그룹에 대해 LDAP 동기화가 활성화된 경우 "초대" 대화 상자를 사용하여 새 그룹 멤버를 초대할 수 없습니다.

GitLab 16.8 이상에서 이 이슈를 해결하려면 [그룹 멤버 API 엔드포인트](../../../api/group_members.md#add-a-group-member)를 사용하여 서비스 계정을 그룹에 초대하고 제거할 수 있습니다.

#### 관리자 권한이 부여되지 않음 {#administrator-privileges-not-granted}

[LDAP 그룹에 관리자 역할을 할당](ldap_synchronization.md#assign-an-admin-role-to-an-ldap-group)하지만 구성된 사용자에게 올바른 관리자 권한이 부여되지 않는 경우 다음 조건이 참인지 확인하세요:

- [`group_base`도 구성](ldap_synchronization.md#group-sync)되어 있습니다.
- 구성된 `admin_group`은(는) `gitlab.rb`의 CN이며 DN 또는 배열이 아닙니다.
- 이 CN은 구성된 `group_base`의 범위에 속합니다.
- `admin_group`의 멤버들은 이미 LDAP 자격 증명으로 GitLab에 로그인했습니다. GitLab은 계정이 이미 LDAP에 연결되어 있는 사용자에게만 관리자 액세스 권한을 부여합니다.

이전의 모든 조건이 참이고 사용자가 여전히 액세스 권한을 받지 못하는 경우 rails 콘솔에서 [수동 그룹 동기화를 실행](#sync-all-groups) 하고 [출력을 살펴보세요](#example-console-output-after-a-group-sync) GitLab이 `admin_group`을(를) 동기화할 때 발생하는 상황을 확인합니다.

#### UI에서 지금 동기화 버튼이 멈춤 {#sync-now-button-stuck-in-the-ui}

**Sync now** 버튼은 **그룹** > **멤버** 페이지에서 멈출 수 있습니다. 버튼이 눌린 후 페이지가 다시 로드되면 버튼이 멈춥니다. 그러면 버튼을 다시 선택할 수 없습니다.

**Sync now** 버튼은 여러 이유로 멈출 수 있으며 특정 경우에 대한 디버깅이 필요합니다. 다음은 문제의 두 가지 가능한 원인과 해결 방안입니다.

##### 유효하지 않은 멤버십 {#invalid-memberships}

**Sync now** 버튼은 그룹의 일부 멤버 또는 요청 멤버가 유효하지 않은 경우 멈춥니다. 이 이슈 개선에 대한 진행 상황을 [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/348226)에서 추적할 수 있습니다. [Rails 콘솔](#rails-console)을(를) 사용하여 이 문제가 **Sync now** 버튼이 멈춘 원인인지 확인할 수 있습니다:

```ruby
# Find the group in question
group = Group.find_by(name: 'my_gitlab_group')

# Look for errors on the Group itself
group.valid?
group.errors.map(&:full_messages)

# Look for errors among the group's members and requesters
group.requesters.map(&:valid?)
group.requesters.map(&:errors).map(&:full_messages)
group.members.map(&:valid?)
group.members.map(&:errors).map(&:full_messages)
```

표시된 오류는 문제를 식별하고 해결책을 지적할 수 있습니다. 예를 들어 지원팀은 다음 오류를 보았습니다:

```ruby
irb(main):018:0> group.members.map(&:errors).map(&:full_messages)
=> [["The member's email address is not allowed for this group. Go to the group's 'Settings > General' page, and check 'Restrict membership by email domain'."]]
```

이 오류는 관리자가 [이메일 도메인별로 그룹 멤버십 제한](../../../user/group/access_and_permissions.md#restrict-group-access-by-domain)을(를) 선택했지만 도메인에 오류가 있음을 보여주었습니다. 도메인 설정이 수정된 후 **Sync now** 버튼이 다시 작동했습니다.

##### Sidekiq 노드에서 LDAP 구성 누락 {#missing-ldap-configuration-on-sidekiq-nodes}

**Sync now** 버튼은 GitLab이 여러 노드 확장되고 LDAP 구성이 [Sidekiq을 실행 중인 노드의 `/etc/gitlab/gitlab.rb`](../../sidekiq/_index.md#configure-ldap-and-user-or-group-synchronization)에서 누락된 경우 멈춥니다. 이 경우 Sidekiq 작업이 사라지는 것으로 보입니다.

LDAP는 로컬 LDAP 구성이 필요한 비동기식으로 실행되는 여러 작업을 가지고 있으므로 Sidekiq 노드에 필요합니다:

- [사용자 동기화](ldap_synchronization.md#user-sync).
- [그룹 동기화](ldap_synchronization.md#group-sync).

Sidekiq을 실행 중인 각 노드에서 [LDAP를 확인하는 Rake 작업](#ldap-check)을(를) 실행하여 LDAP 구성이 누락되었는지 여부를 테스트할 수 있습니다. LDAP이 이 노드에서 올바르게 설정된 경우 LDAP 서버에 연결하고 사용자를 반환합니다.

이 이슈를 해결하려면 Sidekiq 노드에서 [LDAP를 구성](../../sidekiq/_index.md#configure-ldap-and-user-or-group-synchronization)합니다. 구성된 경우 [LDAP를 확인하는 Rake 작업](#ldap-check)을(를) 실행하여 GitLab 노드가 LDAP에 연결할 수 있는지 확인합니다.

#### 모든 그룹 동기화 {#sync-all-groups}

> [!note]
> 디버깅이 불필요할 때 모든 그룹을 수동으로 동기화하려면 [Rake 작업을 사용](../../raketasks/ldap.md#run-a-group-sync)합니다.

수동 [그룹 동기화](ldap_synchronization.md#group-sync)의 출력은 GitLab이 해당 LDAP 그룹 멤버십을 LDAP과 동기화할 때 발생하는 상황을 보여줍니다. [rails 콘솔](#rails-console)을(를) 입력한 다음 실행하세요:

```ruby
Rails.logger.level = Logger::DEBUG

LdapAllGroupsSyncWorker.new.perform
```

그 다음 [출력을 읽는 방법을 알아보세요](#example-console-output-after-a-group-sync).

##### 그룹 동기화 후 예제 콘솔 출력 {#example-console-output-after-a-group-sync}

사용자 동기화의 출력과 마찬가지로 [수동 그룹 동기화](#sync-all-groups)의 출력도 매우 자세합니다. 하지만 유용한 정보가 많이 포함되어 있습니다.

동기화가 실제로 시작되는 지점을 나타냅니다:

```shell
Started syncing 'ldapmain' provider for 'my_group' group
```

다음 항목은 GitLab이 LDAP 서버에서 보는 모든 사용자 DN의 배열을 표시합니다. 이 DN은 GitLab 그룹이 아닌 단일 LDAP 그룹의 사용자입니다. 이 GitLab 그룹에 연결된 여러 LDAP 그룹이 있는 경우 각 LDAP 그룹에 대해 하나씩 이와 같은 여러 로그 항목이 표시됩니다. 이 로그 항목에 LDAP 사용자 DN이 표시되지 않으면 조회를 수행할 때 LDAP이 사용자를 반환하지 않습니다. 사용자가 실제로 LDAP 그룹에 있는지 확인합니다.

```shell
Members in 'ldap_group_1' LDAP group: ["uid=john0,ou=people,dc=example,dc=com",
"uid=mary0,ou=people,dc=example,dc=com", "uid=john1,ou=people,dc=example,dc=com",
"uid=mary1,ou=people,dc=example,dc=com", "uid=john2,ou=people,dc=example,dc=com",
"uid=mary2,ou=people,dc=example,dc=com", "uid=john3,ou=people,dc=example,dc=com",
"uid=mary3,ou=people,dc=example,dc=com", "uid=john4,ou=people,dc=example,dc=com",
"uid=mary4,ou=people,dc=example,dc=com"]
```

각 항목 직후에 해결된 멤버 액세스 수준의 해시가 표시됩니다. 이 해시는 GitLab이 이 그룹에 액세스할 수 있어야 한다고 생각하는 모든 사용자 DN과 그들이 가진 액세스 수준(역할)을 나타냅니다. 이 해시는 추가적이며 추가 LDAP 그룹 조회를 기반으로 더 많은 DN을 추가하거나 기존 항목을 수정할 수 있습니다. 이 항목의 마지막 발생은 GitLab이 그룹에 추가해야 한다고 생각하는 정확한 사용자를 나타냅니다.

> [!note]
> 10은 `Guest`, 20은 `Reporter`, 25는 `Security Manager`, 30은 `Developer`, 40은 `Maintainer`, 50은 `Owner`입니다.

```shell
Resolved 'my_group' group member access: {"uid=john0,ou=people,dc=example,dc=com"=>30,
"uid=mary0,ou=people,dc=example,dc=com"=>30, "uid=john1,ou=people,dc=example,dc=com"=>30,
"uid=mary1,ou=people,dc=example,dc=com"=>30, "uid=john2,ou=people,dc=example,dc=com"=>30,
"uid=mary2,ou=people,dc=example,dc=com"=>30, "uid=john3,ou=people,dc=example,dc=com"=>30,
"uid=mary3,ou=people,dc=example,dc=com"=>30, "uid=john4,ou=people,dc=example,dc=com"=>30,
"uid=mary4,ou=people,dc=example,dc=com"=>30}
```

다음과 같은 경고를 보는 것은 드물지 않습니다. 이는 GitLab이 사용자를 그룹에 추가했을 것이지만 사용자를 GitLab에서 찾을 수 없었음을 나타냅니다. 일반적으로 이는 걱정할 원인이 아닙니다.

특정 사용자가 이미 GitLab에 존재해야 한다고 생각하지만 이 항목이 표시되는 경우 GitLab에 저장된 DN 불일치로 인한 것일 수 있습니다. [사용자 DN 및 이메일 변경](#user-dn-and-email-have-changed)을(를) 참조하여 사용자의 LDAP ID를 업데이트합니다.

```shell
User with DN `uid=john0,ou=people,dc=example,dc=com` should have access
to 'my_group' group but there is no user in GitLab with that
identity. Membership will be updated when the user signs in for
the first time.
```

마지막으로 다음 항목은 이 그룹에 대한 동기화가 완료되었음을 나타냅니다:

```shell
Finished syncing all providers for 'my_group' group
```

구성된 모든 그룹 링크가 동기화되면 GitLab은 동기화할 관리자 또는 외부 사용자를 찾습니다:

```shell
Syncing admin users for 'ldapmain' provider
```

출력은 단일 그룹에서 발생하는 것과 유사하게 보이며 이 줄은 동기화가 완료되었음을 나타냅니다:

```shell
Finished syncing admin users for 'ldapmain' provider
```

[관리자 역할을 할당](ldap_synchronization.md#assign-an-admin-role-to-an-ldap-group)하지 않은 경우 다음 메시지가 표시됩니다:

```shell
No `admin_group` configured for 'ldapmain' provider. Skipping
```

#### 한 그룹 동기화 {#sync-one-group}

[모든 그룹 동기화](#sync-all-groups)는 출력에서 많은 노이즈를 생성할 수 있으므로 단일 GitLab 그룹의 멤버십 문제를 해결하는 데만 관심이 있을 때 혼동할 수 있습니다. 그 경우 이 그룹만 동기화하고 해당 디버그 출력을 보는 방법은 다음과 같습니다:

```ruby
Rails.logger.level = Logger::DEBUG

# Find the GitLab group.
# If the output is `nil`, the group could not be found.
# If a bunch of group attributes are in the output, your group was found successfully.
group = Group.find_by(name: 'my_gitlab_group')

# Sync this group against LDAP
EE::Gitlab::Auth::Ldap::Sync::Group.execute_all_providers(group)
```

출력은 [모든 그룹 동기화에서 얻는 것과 유사](#example-console-output-after-a-group-sync)합니다.

#### LDAP에서 그룹 쿼리 {#query-a-group-in-ldap}

GitLab이 LDAP 그룹을 읽고 모든 멤버를 볼 수 있는지 확인하려면 다음을 실행할 수 있습니다:

```ruby
# Find the adapter and the group itself
adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain') # If `main` is the LDAP provider
ldap_group = EE::Gitlab::Auth::Ldap::Group.find_by_cn('group_cn_here', adapter)

# Find the members of the LDAP group
ldap_group.member_dns
ldap_group.member_uids
```

#### LDAP 동기화가 그룹 생성자를 그룹에서 제거하지 않음 {#ldap-synchronization-does-not-remove-group-creator-from-group}

[LDAP 동기화](ldap_synchronization.md)는 해당 사용자가 그룹에 없는 경우 LDAP 그룹의 생성자를 해당 그룹에서 제거해야 합니다. LDAP 동기화 실행이 이를 수행하지 않는 경우:

1. 사용자를 LDAP 그룹에 추가하세요.
1. LDAP 그룹 동기화가 완료될 때까지 기다리세요.
1. 사용자를 LDAP 그룹에서 제거하세요.

### 사용자 DN 및 이메일 변경됨 {#user-dn-and-email-have-changed}

기본 이메일 **그리고** DN이 모두 LDAP에서 변경되면 GitLab은 사용자의 올바른 LDAP 레코드를 식별할 수 없습니다. 결과적으로 GitLab은 해당 사용자를 차단합니다. GitLab이 LDAP 레코드를 찾을 수 있도록 사용자의 기존 GitLab 프로필을 다음 중 하나 이상으로 업데이트하세요:

- 새 기본 이메일.
- DN 값.

다음 스크립트는 제공된 모든 사용자의 이메일을 업데이트하여 차단되거나 계정에 액세스할 수 없도록 합니다.

> [!note]
> 다음 스크립트는 새 이메일 주소가 있는 새 계정을 먼저 제거해야 함을 요구합니다. 이메일 주소는 GitLab에서 고유해야 합니다.

[rails 콘솔](#rails-console)로 이동한 다음 실행하세요:

```ruby
# Each entry must include the old username and the new email
emails = {
  'ORIGINAL_USERNAME' => 'NEW_EMAIL_ADDRESS',
  ...
}

emails.each do |username, email|
  user = User.find_by_username(username)
  user.email = email
  user.skip_reconfirmation!
  user.save!
end
```

그 다음 [UserSync를 실행](#sync-all-users)하여 이러한 각 사용자에 대해 최신 DN을 동기화합니다.

## AzureActivedirectoryV2에서 인증할 수 없음 (`Invalid grant` {#could-not-authenticate-from-azureactivedirectoryv2-because-invalid-grant}

LDAP에서 SAML로 변환할 때 Azure에서 다음과 같은 오류가 발생할 수 있습니다:

```plaintext
Authentication failure! invalid_credentials: OAuth2::Error, invalid_grant.
```

이 이슈는 다음 두 조건이 모두 참일 때 발생합니다:

- SAML이 해당 사용자에 대해 구성된 후에도 LDAP ID가 여전히 존재합니다.
- 해당 사용자에 대해 LDAP을 비활성화합니다.

로그에서 LDAP 및 Azure 메타데이터를 모두 받으며 이는 Azure에서 오류를 생성합니다.

단일 사용자에 대한 해결 방법은 **운영자** > **ID**에서 사용자의 LDAP ID를 제거하는 것입니다.

여러 LDAP ID를 제거하려면 다음 `Could not authenticate you from Ldapmain because "Unknown provider"` 오류에 대한 해결 방법 중 하나를 사용하세요.

## 오류: `Could not authenticate you from Ldapmain because "Unknown provider"` {#error-could-not-authenticate-you-from-ldapmain-because-unknown-provider}

LDAP 서버로 인증할 때 다음 오류를 받을 수 있습니다:

```plaintext
Could not authenticate you from Ldapmain because "Unknown provider (ldapsecondary). available providers: ["ldapmain"]".
```

이 오류는 이전에 GitLab 구성에서 이름이 변경되거나 제거된 LDAP 서버로 인증한 계정을 사용할 때 발생합니다. 예를 들어:

- 초기에 `main` 및 `secondary`는 GitLab 구성의 `ldap_servers`에서 설정됩니다.
- `secondary` 설정이 제거되거나 `main`로 이름이 변경됩니다.
- 로그인하려는 사용자가 `secondary`에 대한 `identify` 레코드를 가지고 있지만 더 이상 구성되지 않았습니다.

[Rails 콘솔](../../operations/rails_console.md)을(를) 사용하여 영향을 받은 사용자를 나열하고 어떤 LDAP 서버에 ID를 가지고 있는지 확인하세요:

```ruby
ldap_identities = Identity.where(provider: "ldapsecondary")
ldap_identities.each do |identity|
  u=User.find_by_id(identity.user_id)
  ui=Identity.where(user_id: identity.user_id)
  puts "user: #{u.username}\n   #{u.email}\n   last activity: #{u.last_activity_on}\n   #{identity.provider} ID: #{identity.id} external: #{identity.extern_uid}"
  puts "   all identities:"
  ui.each do |alli|
    puts "    - #{alli.provider} ID: #{alli.id} external: #{alli.extern_uid}"
  end
end;nil
```

이 오류를 두 가지 방법으로 해결할 수 있습니다.

### LDAP 서버에 대한 참조 이름 바꾸기 {#rename-references-to-the-ldap-server}

이 해결 방법은 LDAP 서버가 서로 복제본이고 영향을 받은 사용자가 구성된 LDAP 서버를 사용하여 로그인할 수 있어야 할 때 적합합니다. 예를 들어 로드 밸런서가 이제 LDAP 고가용성을 관리하고 별도의 보조 로그인 옵션이 더 이상 필요하지 않은 경우입니다.

> [!note]
> LDAP 서버가 서로 복제본이 아닌 경우 이 해결 방법은 영향을 받은 사용자가 로그인할 수 없도록 합니다.

더 이상 구성되지 않은 LDAP 서버에 대한 [참조 이름을 바꾸려면](../../raketasks/ldap.md#other-options) 실행하세요:

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[ldapsecondary,ldapmain]
```

### `identity` 레코드를 제거하여 제거된 LDAP 서버와 관련된 것 {#remove-the-identity-records-that-relate-to-the-removed-ldap-server}

전제 조건:

- `auto_link_ldap_user`이(가) 활성화되어 있는지 확인합니다.

이 해결 방법을 사용하면 ID가 삭제된 후 영향을 받은 사용자는 구성된 LDAP 서버로 로그인할 수 있으며 GitLab에서 새 `identity` 레코드가 생성됩니다.

제거된 LDAP 서버가 `ldapsecondary`였으므로 [Rails 콘솔](../../operations/rails_console.md)에서 모든 `ldapsecondary` ID를 삭제합니다:

```ruby
ldap_identities = Identity.where(provider: "ldapsecondary")
ldap_identities.each do |identity|
  puts "Destroying identity: #{identity.id} #{identity.provider}: #{identity.extern_uid}"
  identity.destroy!
rescue => e
  puts 'Error generated when destroying identity:\n ' + e.to_s
end; nil
```

## 만료된 라이선스가 여러 LDAP 서버에서 오류를 발생시킴 {#expired-license-causes-errors-with-multiple-ldap-servers}

[여러 LDAP 서버](_index.md#use-multiple-ldap-servers)를 사용하려면 유효한 라이선스가 필요합니다. 만료된 라이선스는 다음을 야기할 수 있습니다:

- 웹 인터페이스의 `502` 오류.
- 다음 로그의 오류 (`/etc/gitlab/gitlab.rb`에서 구성된 실제 전략 이름에 따라 다름):

  ```plaintext
  Could not find a strategy with name `Ldapsecondary'. Please ensure it is required or explicitly set it using the :strategy_class option. (Devise::OmniAuth::StrategyNotFound)
  ```

이 오류를 해결하려면 웹 인터페이스 없이 GitLab 인스턴스에 새 라이선스를 적용해야 합니다:

1. 모든 비 기본 LDAP 서버에 대한 GitLab 구성 줄을 제거하거나 주석 처리하세요.
1. [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 임시로 하나의 LDAP 서버만 사용하도록 합니다.
1. [Rails 콘솔을 입력하고 라이선스 키를 추가](../../license_file.md#add-a-license-through-the-console)하세요.
1. GitLab 구성에서 추가 LDAP 서버를 다시 활성화하고 GitLab을 다시 구성합니다.

## 사용자가 그룹에서 제거되고 다시 추가됨 {#users-are-being-removed-from-group-and-re-added-again}

사용자가 그룹 동기화 중에 그룹에 추가되고 다음 동기화에서 제거되었으며 이것이 반복적으로 발생한 경우 사용자가 여러 개의 중복 LDAP ID를 가지지 않는지 확인하세요.

이 중 하나가 더 이상 사용되지 않는 이전 LDAP 공급자에 대해 추가된 경우 [제거된 LDAP 서버와 관련된 `identity` 레코드를 제거](#remove-the-identity-records-that-relate-to-the-removed-ldap-server)하세요.

## 디버깅 도구 {#debugging-tools}

### LDAP 확인 {#ldap-check}

[LDAP를 확인하는 Rake 작업](../../raketasks/ldap.md#check)은 GitLab이 LDAP에 대한 연결을 성공적으로 설정할 수 있는지 확인하고 사용자까지 읽을 수 있는지 확인하는 데 도움이 되는 귀중한 도구입니다.

연결을 설정할 수 없으면 구성 문제이거나 방화벽이 연결을 차단하고 있을 가능성이 높습니다.

- 방화벽이 연결을 차단하지 않도록 하고 LDAP 서버가 GitLab 호스트에 액세스할 수 있는지 확인합니다.
- Rake 확인 출력에서 오류 메시지를 찾으세요. 이는 LDAP 구성으로 이어질 수 있으며 구성 값(특히 `host`, `port`, `bind_dn`, `password`)이 올바른지 확인합니다.
- [오류](#connection) 를 [로그](#gitlab-logs)에서 찾아 연결 실패를 추가로 디버그합니다.

GitLab이 LDAP에 성공적으로 연결할 수 있지만 사용자를 반환하지 않는 경우 [사용자를 찾을 수 없을 때 수행할 작업을 보세요](#no-users-are-found).

### GitLab 로그 {#gitlab-logs}

사용자 계정이 LDAP 구성으로 인해 차단되거나 차단 해제되면 [`application_json.log`에 로그됩니다](../../logs/_index.md#application_jsonlog).

LDAP 조회 중 예기치 않은 오류(구성 오류, 시간 초과)가 발생하면 로그인이 거부되고 [`production.log`에 로그됩니다](../../logs/_index.md#productionlog).

### ldapsearch {#ldapsearch}

`ldapsearch`은(는) LDAP 서버를 쿼리할 수 있는 유틸리티입니다. 이를 사용하여 LDAP 설정을 테스트하고 사용하는 설정이 예상하는 결과를 반환하도록 할 수 있습니다.

`ldapsearch`을(를) 사용할 때 `gitlab.rb` 구성에 이미 지정한 것과 동일한 설정을 사용하여 해당 정확한 설정이 사용될 때 발생하는 상황을 확인할 수 있는지 확인하세요.

GitLab 호스트에서 이 명령을 실행하면 GitLab 호스트와 LDAP 사이에 장애물이 없는지 확인하는 데도 도움이 됩니다.

예를 들어 다음 GitLab 구성을 생각해보세요:

```shell
gitlab_rails['ldap_servers'] = YAML.load <<-'EOS' # remember to close this block with 'EOS' below
   main: # 'main' is the GitLab 'provider ID' of this LDAP server
     label: 'LDAP'
     host: '127.0.0.1'
     port: 389
     uid: 'uid'
     encryption: 'plain'
     bind_dn: 'cn=admin,dc=ldap-testing,dc=example,dc=com'
     password: 'Password1'
     active_directory: true
     allow_username_or_email_login: false
     block_auto_created_users: false
     base: 'dc=ldap-testing,dc=example,dc=com'
     user_filter: ''
     attributes:
       username: ['uid', 'userid', 'sAMAccountName']
       email:    ['mail', 'email', 'userPrincipalName']
       name:       'cn'
       first_name: 'givenName'
       last_name:  'sn'
     group_base: 'ou=groups,dc=ldap-testing,dc=example,dc=com'
     admin_group: 'gitlab_admin'
EOS
```

다음 `ldapsearch`을(를) 실행하여 `bind_dn` 사용자를 찾습니다:

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -p 389 \
  -h 127.0.0.1 \
  -b "dc=ldap-testing,dc=example,dc=com"
```

`bind_dn`, `password`, `port`, `host`, `base`은(는) `gitlab.rb`에서 구성된 것과 동일합니다.

#### `start_tls` 암호화를 사용하여 ldapsearch 사용 {#use-ldapsearch-with-start_tls-encryption}

이전 예제는 포트 389의 평문으로 LDAP 테스트를 수행합니다. [`start_tls` 암호화](_index.md#basic-configuration-settings)를 사용 중인 경우 `ldapsearch` 명령에 포함합니다:

- `-Z` 플래그.
- LDAP 서버의 FQDN.

TLS 협상 중에 LDAP 서버의 FQDN이 인증서와 비교 평가되므로 이들을 포함해야 합니다:

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -p 389 \
  -h "testing.ldap.com" \
  -b "dc=ldap-testing,dc=example,dc=com" -Z
```

#### `simple_tls` 암호화를 사용하여 ldapsearch 사용 {#use-ldapsearch-with-simple_tls-encryption}

[`simple_tls` 암호화](_index.md#basic-configuration-settings)를 사용 중인 경우 (일반적으로 포트 636) `ldapsearch` 명령에 다음을 포함합니다:

- `-H` 플래그가 있는 LDAP 서버 FQDN 및 포트.
- 완전히 구성된 URI.

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -H "ldaps://testing.ldap.com:636" \
  -b "dc=ldap-testing,dc=example,dc=com"
```

자세한 내용은 [공식 `ldapsearch` 설명서](https://linux.die.net/man/1/ldapsearch)를 참조하세요.

### **AdFind**를 사용 중 (Windows) {#using-adfind-windows}

[`AdFind`](https://learn.microsoft.com/en-us/archive/technet-wiki/7535.adfind-command-examples) 유틸리티(Windows 기반 시스템)를 사용하여 LDAP 서버에 액세스할 수 있고 인증이 올바르게 작동하는지 테스트할 수 있습니다. AdFind는 [Joe Richards](https://www.joeware.net/freetools/tools/adfind/index.htm)에서 구축한 무료 유틸리티입니다.

**Return all objects**

필터 `objectclass=*`을(를) 사용하여 모든 디렉터리 개체를 반환할 수 있습니다.

```shell
adfind -h ad.example.org:636 -ssl -u "CN=GitLabSRV,CN=Users,DC=GitLab,DC=org" -up Password1 -b "OU=GitLab INT,DC=GitLab,DC=org" -f (objectClass=*)
```

**Return single object using filter**

**specifying**하여 단일 객체를 검색하거나 전체 **DN**을(를) 검색할 수도 있습니다. 이 예제에서는 객체 이름만 `CN=Leroy Fox`을(를) 지정합니다.

```shell
adfind -h ad.example.org:636 -ssl -u "CN=GitLabSRV,CN=Users,DC=GitLab,DC=org" -up Password1 -b "OU=GitLab INT,DC=GitLab,DC=org" -f "(&(objectcategory=person)(CN=Leroy Fox))"
```

### Rails 콘솔 {#rails-console}

> [!warning]
> rails 콘솔로 데이터를 생성, 읽기, 수정 및 삭제하는 것은 매우 쉽습니다. 나열된 대로 정확히 명령을 실행해야 합니다.

Rails 콘솔은 LDAP 문제를 디버그하는 데 도움이 되는 귀중한 도구입니다. 명령을 실행하고 GitLab이 응답하는 방식을 확인하여 애플리케이션과 직접 상호 작용할 수 있습니다.

rails 콘솔을 사용하는 방법에 대한 지침은 이 [가이드](../../operations/rails_console.md#starting-a-rails-console-session)를 참조하세요.

#### 디버그 출력 활성화 {#enable-debug-output}

이는 GitLab이 수행하는 작업과 그 내용을 보여주는 디버그 출력을 제공합니다. 이 값은 지속되지 않으며 Rails 콘솔의 이 세션에만 활성화됩니다.

rails 콘솔에서 디버그 출력을 활성화하려면 [rails 콘솔을 입력](#rails-console)하고 실행하세요:

```ruby
Rails.logger.level = Logger::DEBUG
```

#### 그룹, 하위 그룹, 멤버 및 요청자와 관련된 모든 오류 메시지 가져오기 {#get-all-error-messages-associated-with-groups-subgroups-members-and-requesters}

그룹, 하위 그룹, 멤버 및 요청자와 관련된 오류 메시지를 수집합니다. 이는 웹 인터페이스에 표시되지 않을 수 있는 오류 메시지를 캡처합니다. 이는 [LDAP 그룹 동기화](ldap_synchronization.md#group-sync) 이슈를 해결하고 사용자와 그룹 및 하위 그룹의 멤버십과 관련된 예기치 않은 동작을 해결하는 데 특히 도움이 될 수 있습니다.

```ruby
# Find the group and subgroup
group = Group.find_by_full_path("parent_group")
subgroup = Group.find_by_full_path("parent_group/child_group")

# Group and subgroup errors
group.valid?
group.errors.map(&:full_messages)

subgroup.valid?
subgroup.errors.map(&:full_messages)

# Group and subgroup errors for the members AND requesters
group.requesters.map(&:valid?)
group.requesters.map(&:errors).map(&:full_messages)
group.members.map(&:valid?)
group.members.map(&:errors).map(&:full_messages)
group.members_and_requesters.map(&:errors).map(&:full_messages)

subgroup.requesters.map(&:valid?)
subgroup.requesters.map(&:errors).map(&:full_messages)
subgroup.members.map(&:valid?)
subgroup.members.map(&:errors).map(&:full_messages)
subgroup.members_and_requesters.map(&:errors).map(&:full_messages)
```

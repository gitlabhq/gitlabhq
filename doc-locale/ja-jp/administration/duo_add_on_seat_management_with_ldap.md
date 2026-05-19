---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: LDAPによるGitLab Duoアドオンシートの管理
description: 指定したLDAPグループのユーザーメンバーシップとシートのステータスを同期することで、GitLab Duoアドオンシートの割り当てと削除を自動化します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175101)されました。

{{< /history >}}

GitLab管理者は、LDAPグループメンバーシップに基づいて、GitLab Duoアドオンシートの自動割り当てを設定できます。この機能を有効にすると、LDAPグループメンバーシップに応じて、ユーザーのサインイン時にGitLabはアドオンシートを自動的に割り当てまたは削除します。

## シート管理ワークフロー {#seat-management-workflow}

1. **設定**: 管理者は、`duo_add_on_groups`の[設定](#configure-gitlab-duo-add-on-seat-management)でLDAPグループを指定します。
1. **シートの同期**: GitLabは、次の2つの方法でLDAPグループメンバーシップを確認します:
   - **ユーザーサインイン時**: ユーザーがLDAP経由でサインインすると、GitLabはそのグループメンバーシップを即座にチェックします。
   - **定刻同期**: GitLabは毎日午前2:00に、すべてのLDAPユーザーを自動的に同期し、ユーザーがサインインしていなくてもシート割り当てが最新の状態に保たれるようにします。
1. **シートの割り当て**:
   - ユーザーが`duo_add_on_groups`に指定されているいずれかのグループに属している場合、（未割り当てであれば）アドオンシートが割り当てられます。
   - ユーザーがこのリストで指定されているグループに属していない場合、（割り当て済みであれば）アドオンシートが削除されます。
1. **非同期処理**: シートの割り当てと削除は非同期で処理されるため、メインのサインインフローが中断されることはありません。

次の図は、このワークフローを示しています:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    accTitle: Workflow of GitLab Duo add-on seat management with LDAP
    accDescr: Sequence diagram showing automatic GitLab Duo add-on seat management based on LDAP group membership. Users sign in, GitLab authenticates them, then enqueues a background job to sync seat assignment based on their group membership.

    participant User
    participant GitLab
    participant LDAP
    participant Background Job

    User->>GitLab: Sign in with LDAP credentials
    GitLab->>LDAP: Authenticate user
    LDAP-->>GitLab: User authenticated
    GitLab->>Background Job: Enqueue 'LdapAddOnSeatSyncWorker' seat sync job
    GitLab-->>User: Sign-in complete
    Background Job->>Background Job: Start
    Background Job->>LDAP: Check user's groups against duo_add_on_groups
    LDAP-->>Background Job: Return membership of groups
    alt User member of any duo_add_on_groups?
        Background Job->>GitLab: Assign Duo Add-on seat
    else User not in duo_add_on_groups
        Background Job->>GitLab: Remove Duo Add-on seat (if assigned)
    end
    Background Job-->>Background Job: Complete

    Note over GitLab, Background Job: Additionally, LdapAllAddOnSeatSyncWorker runs daily at 2 AM to sync all LDAP users
```

## GitLab Duoアドオンシート管理を設定する {#configure-gitlab-duo-add-on-seat-management}

LDAPによるアドオンシート管理をオンにするには:

1. [インストール](auth/ldap/ldap_synchronization.md#gitlab-duo-add-on-for-groups)用に編集したGitLab設定ファイルを開きます。
1. LDAPサーバーの設定に`duo_add_on_groups`設定を追加します。
1. GitLab Duoアドオンシートを割り当てる必要があるLDAPグループ名の配列を指定します。

次の例は、Linuxパッケージインストールの場合の`gitlab.rb`設定です:

```ruby
gitlab_rails['ldap_servers'] = {
  'main' => {
    # Additional LDAP settings removed for readability
    'duo_add_on_groups' => ['duo_users', 'admins'],
  }
}
```

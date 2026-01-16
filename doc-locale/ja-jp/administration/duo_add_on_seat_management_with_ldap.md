---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: LDAPによるGitLab Duoアドオンシートの管理
description: 指定されたLDAPグループのユーザーメンバーシップとシートのステータスを同期することで、GitLab Duoアドオンシートの割り当てと削除を自動化します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175101)されました。

{{< /history >}}

GitLabの管理者は、LDAPグループメンバーシップに基づいて、GitLab Duoアドオンシートの自動割り当てを設定できます。有効にすると、ユーザーがサインインするときに、LDAPグループメンバーシップに応じて、GitLabはユーザーのアドオンシートを自動的に割り当てまたは削除します。

## シート管理ワークフロー {#seat-management-workflow}

1. **設定**: 管理者は、`duo_add_on_groups`の[設定](#configure-gitlab-duo-add-on-seat-management)でLDAPグループを指定します。
1. **Seat synchronization**: GitLabは、LDAPグループのメンバーシップを次の2つの方法で確認します:
   - **ユーザーサインイン時**: ユーザーがLDAP経由でサインインすると、GitLabはそのグループメンバーシップを即座にチェックします。
   - **定刻同期**: GitLabは、ユーザーのサインインがなくても、シートの割り当てが最新の状態になるように、毎日午前2時にすべてのLDAPユーザーを自動的に同期します。
1. **Seat assignment**:
   - ユーザーが`duo_add_on_groups`にリストされているグループに属している場合、（まだ割り当てられていない場合は）アドオンシートが割り当てられます。
   - ユーザーがリストされているグループに属していない場合、（以前に割り当てられている場合は）アドオンシートが削除されます。
1. **Async processing**: シートの割り当てと削除は非同期で処理されるため、メインのサインインフローが中断されることはありません。

次の図は、ワークフローを示しています:

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

LDAPでアドオンシート管理をオンにするには、次の手順に従います:

1. [インストール](auth/ldap/ldap_synchronization.md#gitlab-duo-add-on-for-groups)用に編集したGitLab設定ファイルを開きます。
1. `duo_add_on_groups`設定をLDAPサーバー設定に追加します。
1. GitLab Duoアドオンシートを持つ必要があるLDAPグループ名の配列を指定します。

次の例は、Linuxパッケージインストールの`gitlab.rb`設定です:

```ruby
gitlab_rails['ldap_servers'] = {
  'main' => {
    # Additional LDAP settings removed for readability
    'duo_add_on_groups' => ['duo_users', 'admins'],
  }
}
```

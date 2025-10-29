---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グローバルユーザー設定を変更する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabインスタンス内のすべてのユーザー設定を変更できます。

## 前提要件 {#prerequisites}

- インスタンスの管理者である。

## トップレベルグループをユーザーが作成できないようにする {#prevent-users-from-creating-top-level-groups}

GitLabの管理者は、トップレベルグループをユーザーが作成できないようにすることができます。

これらのユーザーは次のとおりです:

- トップレベルグループを作成できません。
- 少なくともメンテナーロールを持つグループ内でサブグループを作成できます。これは、グループの[サブグループ作成権限](../user/group/subgroups/_index.md#change-who-can-create-subgroups)によって異なります。

この機能は、すべての新しいユーザー、または特定の既存のユーザーに対してのみ削除できます:

### 新しいユーザーの場合 {#for-new-users}

インスタンスに追加されたすべての新しいユーザーが、新しいトップレベルグループを作成できないようにすることができます。これは既存のユーザーには影響しません。

トップレベルグループを新しいユーザーが作成できないようにするには:

- GitLab 15.5以降では、次のいずれかの方法を使用します:
  - [GitLab UI](settings/account_and_limit_settings.md#prevent-new-users-from-creating-top-level-groups)。
  - [アプリケーション設定API](../api/settings.md#update-application-settings)を使用する。
- GitLab 15.4以前では、設定ファイルを修正します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集して、次の行を追加します:

   ```ruby
   gitlab_rails['gitlab_default_can_create_group'] = false
   ```

1. [GitLabを再設定して再起動](restart_gitlab.md#reconfigure-a-linux-package-installation)。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `config/gitlab.yml`を編集し、次の行のコメントを外します:

   ```yaml
   # default_can_create_group: false  # default: true
   ```

1. [GitLab](restart_gitlab.md#self-compiled-installations)を再起動します。

{{< /tab >}}

{{< /tabs >}}

### 既存のユーザーの場合 {#for-existing-users}

既存のユーザーがサブグループを作成することを許可しながら、トップレベルグループを作成できないようにするには、次のいずれかの方法を使用します:

- [GitLab UI](admin_area.md#prevent-a-user-from-creating-top-level-groups)。
- `can_create_group`設定を変更するための[User API](../api/users.md#modify-a-user)。

## ユーザーがユーザー名を変更できないようにする {#prevent-users-from-changing-their-usernames}

デフォルトでは、ユーザーはユーザー名を変更できます。ユーザーがユーザー名を変更できないようにするには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集して、次の行を追加します:

   ```ruby
   gitlab_rails['gitlab_username_changing_enabled'] = false
   ```

1. [GitLabを再設定して再起動](restart_gitlab.md#reconfigure-a-linux-package-installation)。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `config/gitlab.yml`を編集し、次の行のコメントを外します:

   ```yaml
   # username_changing_enabled: false # default: true - User can change their username/namespace
   ```

1. [GitLab](restart_gitlab.md#self-compiled-installations)を再起動します。

{{< /tab >}}

{{< /tabs >}}

## ゲストユーザーがより高いロールにプロモートされないようにする {#prevent-guest-users-from-promoting-to-a-higher-role}

GitLab Ultimateプランでは、ゲストユーザーは有料シートとしてカウントされません。ただし、ゲストユーザーがプロジェクトとネームスペースを作成すると、ゲストよりも高いロールに自動的にプロモートされ、有料シートを占有します。

ゲストユーザーがより高いロールにプロモートされ、有料シートを占有しないようにするには、ユーザーを[外部](external_users.md)として設定します。

外部ユーザーは、個人プロジェクトまたはネームスペースを作成できません。ゲストロールを持つユーザーが別のユーザーによってより高いロールにプロモートされた場合、個人プロジェクトまたはネームスペースを作成する前に、外部ユーザーの設定を削除する必要があります。外部ユーザーの制限事項の完全なリストについては、[外部ユーザー](external_users.md)を参照してください。

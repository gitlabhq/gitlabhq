---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: デプロイキー
description: SSHキー、リポジトリへのアクセス、ボットユーザー、読み取り専用アクセス。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

デプロイキーを使用して、GitLabでホストされているリポジトリにアクセスします。ほとんどの場合、デプロイキーを使用して、ビルドサーバーや継続的インテグレーション（CI）サーバーなどの外部ホストからリポジトリにアクセスします。

必要に応じて、代わりに[デプロイトークン](../deploy_tokens/_index.md)を使用してリポジトリにアクセスすることもできます。

| 属性        |  デプロイキー | デプロイトークン |
|------------------|-------------|--------------|
| 共有          | 複数のプロジェクト（異なるグループのプロジェクトも含む）間で共有可能です。 | プロジェクトまたはグループに属します。 |
| ソース           | 外部ホストで生成されたパブリックSSHキー。 | GitLabインスタンスで生成され、作成時にのみユーザーに提供されます。 |
| アクセス可能なリソース  | SSH経由のGitリポジトリ | HTTP経由のGitリポジトリ、パッケージレジストリ、およびコンテナレジストリ。 |

[外部認証](../../../administration/settings/external_authorization.md)が有効になっている場合、デプロイキーはGitオペレーションに使用できません。

## スコープ {#scope}

デプロイキーには、作成時に定義されたスコープがあります:

- **Project deploy key**（プロジェクトデプロイキー）: アクセスは、選択したプロジェクトに限定されます。
- **Public deploy key**（パブリックデプロイキー）: GitLabインスタンス内の任意のプロジェクトにアクセスを許可できます。各プロジェクトへのアクセスは、少なくともメンテナーロールを持つユーザーによって[許可](#grant-project-access-to-a-public-deploy-key)される必要があります。

デプロイキーのスコープは、作成後に変更できません。

## 権限 {#permissions}

デプロイキーには、作成時に権限レベルが与えられます:

- **Read-only**（読み取り専用）: 読み取り専用のデプロイキーは、リポジトリから読み取るだけです。
- **Read-write**（読み取り/書き込み）: 読み取り/書き込みデプロイキーは、リポジトリから読み取り、書き込みできます。

デプロイキーの権限レベルは、作成後に変更できます。プロジェクトのデプロイキーの権限を変更すると、現在のプロジェクトにのみ適用されます。

デプロイキーを使用するプッシュが追加のプロセスをトリガーする場合、キーの作成者は認証される必要があります。例:

- デプロイキーを使用して[保護ブランチ](../repository/branches/protected.md)にコミットをプッシュする場合、デプロイキーの作成者はブランチへのアクセス権を持っている必要があります。
- デプロイキーを使用してCI/CDパイプラインをトリガーするコミットをプッシュする場合、デプロイキーの作成者は、保護環境やシークレット変数を含むCI/CDリソースへのアクセス権を持っている必要があります。

### セキュリティ上の注意点 {#security-implications}

デプロイキーは、GitLabとの非人的なインタラクションを容易にするためのものです。たとえば、デプロイキーを使用して、組織内のサーバーで自動的に実行されるスクリプトに権限を付与できます。

[サービスアカウント](../../profile/service_accounts.md)を使用し、サービスアカウントでデプロイキーを作成する必要があります。別のユーザーアカウントを使用してデプロイキーを作成した場合、そのユーザーには、デプロイキーが失効するまで永続する権限が付与されます。

さらに:

- デプロイキーは、作成したユーザーがグループまたはプロジェクトから削除されても機能します。
- デプロイキーの作成者は、ユーザーが降格または削除されても、グループまたはプロジェクトへのアクセス権を保持します。
- デプロイキーが保護ブランチルールで指定されている場合、デプロイキーの作成者は:
  - デプロイキー自体だけでなく、保護ブランチへのアクセス権も取得します。
  - デプロイキーに読み取り/書き込み権限がある場合、保護ブランチにプッシュできます。これは、ブランチがすべてのユーザーからの変更に対して保護されている場合でも当てはまります。
- デプロイキーの作成者がブロックされたり、インスタンスから削除されたりした場合でも、ユーザーはグループまたはプロジェクトから変更をプルできますが、プッシュはできません。

すべての機密情報と同様に、シークレットへのアクセスを必要とするユーザーのみがそれを読み取ることができるようにする必要があります。人的なインタラクションでは、パーソナルアクセストークンなどのユーザーに関連付けられた認証情報を使用します。

潜在的なシークレット漏洩を検出するために、[監査イベント](../../compliance/audit_event_schema.md#example-audit-event-payloads-for-git-over-ssh-events-with-deploy-key)機能を使用できます。

## デプロイキーの表示 {#view-deploy-keys}

プロジェクトで使用可能なデプロイキーを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **デプロイキー**を展開します。

使用可能なデプロイキーが一覧表示されます:

- **有効なデプロイキー**: プロジェクトへのアクセス権を持つデプロイキー。
- **秘密にアクセスできるデプロイキー**: プロジェクトへのアクセス権を持たないプロジェクトデプロイキー。
- **Public accessible deploy keys**（パブリックアクセスが可能なデプロイキー）: プロジェクトへのアクセス権を持たないパブリックデプロイキー。

[GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md)には`glab deploy-key list`コマンドが用意されています。

## プロジェクトデプロイキーの作成 {#create-a-project-deploy-key}

前提要件:

- プロジェクトのメンテナーロール以上を持っている必要があります。
- [SSHキーペアを生成](../../ssh.md#generate-an-ssh-key-pair)します。リポジトリへのアクセスを必要とするホストに、プライベートSSHキーを配置します。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **デプロイキー**を展開します。
1. **新しいキーを追加**を選択します。
1. フィールドに入力します。
1. オプション。`read-write`権限を付与するには、**このキーに書き込み権限を与える**チェックボックスをオンにします。
1. オプション。**有効期限**を更新します。

プロジェクトデプロイキーは、作成時に有効になります。変更できるのは、プロジェクトデプロイキーの名前と権限のみです。デプロイキーが複数のプロジェクトで有効になっている場合、デプロイキー名を変更することはできません。

[GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md)には`glab deploy-key add`コマンドが用意されています。

## パブリックデプロイキーの作成 {#create-a-public-deploy-key}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提要件: 

- インスタンスへの管理者アクセス権を持っている必要があります。
- [SSHキーペアを生成](../../ssh.md#generate-an-ssh-key-pair)する必要があります。
- リポジトリへのアクセスを必要とするホストに、プライベートSSHキーを配置する必要があります。

パブリックデプロイキーを作成するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **デプロイキー**を選択します。
1. **新しいデプロイキー**を選択します。
1. フィールドに入力します。
   - **名前**には意味のある説明を使用します。たとえば、パブリックデプロイキーを使用する外部ホストまたはアプリケーションの名前を含めます。

変更できるのは、パブリックデプロイキーの名前のみです。

## パブリックデプロイキーへのプロジェクトアクセスの許可 {#grant-project-access-to-a-public-deploy-key}

前提要件: 

- プロジェクトのメンテナーロール以上を持っている必要があります。

パブリックデプロイキーにプロジェクトへのアクセスを許可するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **デプロイキー**を展開します。
1. **パブリックアクセスが可能なデプロイキー**を選択します。
1. キーの行で、**有効**を選択します。
1. パブリックデプロイキーに読み取り/書き込み権限を付与するには:
   1. キーの行で、**編集**（{{< icon name="pencil" >}}）を選択します。
   1. **このキーに書き込み権限を与える**チェックボックスをオンにします。

### デプロイキーのプロジェクトアクセス権限の編集 {#edit-project-access-permissions-of-a-deploy-key}

前提要件: 

- プロジェクトのメンテナーロール以上を持っている必要があります。

デプロイキーのプロジェクトアクセス権限を編集するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **デプロイキー**を展開します。
1. キーの行で、**編集**（{{< icon name="pencil" >}}）を選択します。
1. **このキーに書き込み権限を与える**チェックボックスをオンまたはオフにします。

## デプロイキーのプロジェクトアクセスの取り消し {#revoke-project-access-of-a-deploy-key}

プロジェクトへのデプロイキーのアクセスを取り消すには、そのキーを無効にできます。デプロイキーに依存するサービスは、キーが無効になると動作を停止します。

前提要件: 

- プロジェクトのメンテナーロール以上を持っている必要があります。

デプロイキーを無効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **デプロイキー**を展開します。
1. キーの行で、**無効**（{{< icon name="cancel" >}}）を選択します。

無効にされたときのデプロイキーの動作は、以下によって異なります:

- キーがパブリックにアクセス可能な場合、プロジェクトから削除されますが、**パブリックアクセスが可能なデプロイキー**タブでは引き続き使用できます。
- キーがプライベートにアクセス可能で、このプロジェクトでのみ使用されている場合、削除されます。
- キーがプライベートにアクセス可能で、他のプロジェクトでも使用されている場合、プロジェクトから削除されますが、**秘密にアクセスできるデプロイキー**タブでは引き続き使用できます。

## 関連トピック {#related-topics}

- [デプロイキー](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/deploy-key)用のGitLab CLIコマンド

## トラブルシューティング {#troubleshooting}

### デプロイキーが保護ブランチにプッシュできない {#deploy-key-cannot-push-to-a-protected-branch}

デプロイキーが[保護ブランチ](../repository/branches/protected.md)へのプッシュに失敗するシナリオがいくつかあります。

- デプロイキーに関連付けられているオーナーが、保護ブランチのプロジェクトへの[メンバーシップ](../members/_index.md)を持っていません。
- デプロイキーに関連付けられているオーナーの[プロジェクトメンバーシップ権限](../../permissions.md#project-members-permissions)が、**View project code**（プロジェクトコードの表示）に必要な権限よりも低くなっています。
- デプロイキーに[プロジェクトの読み取り/書き込み権限](#edit-project-access-permissions-of-a-deploy-key)がありません。
- デプロイキーが[失効](#revoke-project-access-of-a-deploy-key)しました。
- 保護ブランチの[**プッシュとマージを許可**セクション](../repository/branches/protected.md#protect-a-branch)で**なし**が選択されています。

このイシューは、すべてのデプロイキーがアカウントに関連付けられているために発生します。アカウントの権限は変更される可能性があるため、動作していたデプロイキーが突然保護ブランチにプッシュできなくなるシナリオが発生する可能性があります。

このイシューを解決するには、独自のユーザーではなく、プロジェクトサービスアカウントユーザーのデプロイキーを作成するために、デプロイキーAPIを使用できます:

1. [サービスアカウントユーザーを作成](../../../api/service_accounts.md#create-a-group-service-account)します。
1. そのサービスアカウントユーザーの[パーソナルアクセストークンを作成](../../../api/service_accounts.md#create-a-personal-access-token-for-a-group-service-account)します。このトークンには、少なくとも`api`スコープが必要です。
1. [サービスアカウントユーザーをプロジェクトに招待](../../profile/service_accounts.md#service-account-access-to-groups-and-projects)します。
1. デプロイキーAPIを使用して、[サービスアカウントユーザーのデプロイキーを作成](../../../api/deploy_keys.md#add-deploy-key)します:

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <service_account_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"title": "My deploy key", "key": "ssh-rsa AAAA...", "can_push": "true"}' \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/"
   ```

#### 非メンバーおよびブロックされたユーザーに関連付けられたデプロイキーの特定 {#identify-deploy-keys-associated-with-non-member-and-blocked-users}

非メンバーまたはブロックされたユーザーに属するキーを見つける必要がある場合は、[Railsコンソール](../../../administration/operations/rails_console.md#starting-a-rails-console-session)を使用して、次のようなスクリプトを使用して使用できないデプロイキーを特定できます:

```ruby
ghost_user_id = Users::Internal.ghost.id

DeployKeysProject.with_write_access.find_each do |deploy_key_mapping|
  project = deploy_key_mapping.project
  deploy_key = deploy_key_mapping.deploy_key
  user = deploy_key.user

  access_checker = Gitlab::DeployKeyAccess.new(deploy_key, container: project)

  # can_push_for_ref? tests if deploy_key can push to default branch, which is likely to be protected
  can_push = access_checker.can_do_action?(:push_code)
  can_push_to_default = access_checker.can_push_for_ref?(project.repository.root_ref)

  next if access_checker.allowed? && can_push && can_push_to_default

  if user.nil? || user.id == ghost_user_id
    username = 'none'
    state = '-'
  else
    username = user.username
    user_state = user.state
  end

  puts "Deploy key: #{deploy_key.id}, Project: #{project.full_path}, Can push?: " + (can_push ? 'YES' : 'NO') +
       ", Can push to default branch #{project.repository.root_ref}?: " + (can_push_to_default ? 'YES' : 'NO') +
       ", User: #{username}, User state: #{user_state}"
end
```

#### デプロイキーのオーナーの設定 {#set-the-owner-of-a-deploy-key}

デプロイキーは特定のユーザーに属し、ユーザーがブロックされるかインスタンスから削除されると非アクティブ化されます。ユーザーが削除されたときにデプロイキーが動作し続けるようにするには、そのオーナーをアクティブユーザーに変更します。

デプロイキーのフィンガープリントがある場合は、次のコマンドを使用して、デプロイキーに関連付けられているユーザーを変更できます:

```shell
k = Key.find_by(fingerprint: '5e:51:92:11:27:90:01:b5:83:c3:87:e3:38:82:47:2e')
k.user_id = User.find_by(username: 'anactiveuser').id
k.save()
```

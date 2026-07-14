---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Rakeタスクを使用して、一括ユーザー操作と認証設定を管理します。
title: ユーザー管理Rakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、ユーザー管理用のRakeタスクを提供します。管理者は、**管理者**エリアを使用して[ユーザーを管理](../admin_area.md#administering-users)することもできます。

## ユーザーをすべてのプロジェクトにデベロッパーとして追加 {#add-user-as-a-developer-to-all-projects}

ユーザーをすべてのプロジェクトにデベロッパーとして追加するには、以下を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_projects[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_projects[username@domain.tld] RAILS_ENV=production
```

## すべてのユーザーをすべてのプロジェクトに追加 {#add-all-users-to-all-projects}

すべてのユーザーをすべてのプロジェクトに追加するには、以下を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_projects

# installation from source
bundle exec rake gitlab:import:all_users_to_all_projects RAILS_ENV=production
```

管理者はメンテナーとして、その他のすべてのユーザーはデベロッパーとして追加されます。

## ユーザーをすべてのグループにデベロッパーとして追加 {#add-user-as-a-developer-to-all-groups}

ユーザーをすべてのグループにデベロッパーとして追加するには、以下を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_groups[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_groups[username@domain.tld] RAILS_ENV=production
```

## すべてのユーザーをすべてのグループに追加 {#add-all-users-to-all-groups}

すべてのユーザーをすべてのグループに追加するには、以下を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_groups

# installation from source
bundle exec rake gitlab:import:all_users_to_all_groups RAILS_ENV=production
```

管理者はオーナーとして追加されるため、追加のユーザーをグループに追加できます。

## 指定されたグループのすべてのユーザーを`project_limit:0`および`can_create_group: false`に更新 {#update-all-users-in-a-given-group-to-project_limit0-and-can_create_group-false}

指定されたグループのすべてのユーザーを`project_limit: 0`および`can_create_group: false`に更新するには、以下を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:user_management:disable_project_and_group_creation\[:group_id\]

# installation from source
bundle exec rake gitlab:user_management:disable_project_and_group_creation\[:group_id\] RAILS_ENV=production
```

指定されたグループ内のすべてのユーザー、そのサブグループ、およびこのグループネームスペース内のプロジェクトを、指定された制限で更新します。

## 請求対象ユーザーの数を制御 {#control-the-number-of-billable-users}

この設定を有効にすると、新規ユーザーは管理者によって承認されるまでブロックされます。デフォルトは`false`です:

```plaintext
block_auto_created_users: false
```

## すべてのユーザーの2要素認証を無効にする {#disable-two-factor-authentication-for-all-users}

このタスクは、2要素認証 (2FA) を有効にしているすべてのユーザーに対して無効化します。たとえば、GitLabの`config/secrets.yml`ファイルが失われ、ユーザーがサインインできない場合に役立ちます。

すべてのユーザーの2要素認証を無効にするには、以下を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:two_factor:disable_for_all_users

# installation from source
bundle exec rake gitlab:two_factor:disable_for_all_users RAILS_ENV=production
```

## 2要素認証の暗号化キーをローテーションする {#rotate-two-factor-authentication-encryption-key}

GitLabは、2要素認証 (2FA) に必要なシークレットデータを暗号化されたデータベースカラムに保存します。このデータの暗号化キーは`otp_key_base`として知られ、`config/secrets.yml`に保存されています。

そのファイルが漏洩しても、個々の2FAのシークレットが漏洩していなければ、それらのシークレットを新しい暗号化キーで再暗号化することが可能です。これにより、すべてのユーザーに2FAの詳細を変更させることなく、漏洩したキーを変更できます。

2要素認証の暗号化キーをローテーションするには:

1. `config/secrets.yml`ファイルで古いキーを検索しますが、**make sure you're working with the production section**。対象の行は次のようになります:

   ```yaml
   production:
     otp_key_base: fffffffffffffffffffffffffffffffffffffffffffffff
   ```

1. 新しいシークレットを生成します:

   ```shell
   # omnibus-gitlab
   sudo gitlab-rake secret

   # installation from source
   bundle exec rake secret RAILS_ENV=production
   ```

1. GitLabサーバーを停止し、既存のシークレットファイルをバックアップして、データベースを更新します:

   ```shell
   # omnibus-gitlab
   sudo gitlab-ctl stop
   sudo cp config/secrets.yml config/secrets.yml.bak
   sudo gitlab-rake gitlab:two_factor:rotate_key:apply filename=backup.csv old_key=<old key> new_key=<new key>

   # installation from source
   sudo /etc/init.d/gitlab stop
   cp config/secrets.yml config/secrets.yml.bak
   bundle exec rake gitlab:two_factor:rotate_key:apply filename=backup.csv old_key=<old key> new_key=<new key> RAILS_ENV=production
   ```

   `<old key>`の値は`config/secrets.yml`から読み取ることができます (`<new key>`は以前に生成されました)。ユーザー2FAのシークレットの**encrypted**値は、指定された`filename`に書き込まれます。エラーが発生した場合に、これを使用してロールバックできます。

1. `config/secrets.yml`を変更して`otp_key_base`を`<new key>`に設定し、再起動します。繰り返しになりますが、**production**セクションで操作していることを確認してください。

   ```shell
   # omnibus-gitlab
   sudo gitlab-ctl start

   # installation from source
   sudo /etc/init.d/gitlab start
   ```

何らかの問題がある場合 (たとえば、`old_key`に誤った値を使用している場合) は、`config/secrets.yml`のバックアップを復元し、変更をロールバックできます:

```shell
# omnibus-gitlab
sudo gitlab-ctl stop
sudo gitlab-rake gitlab:two_factor:rotate_key:rollback filename=backup.csv
sudo cp config/secrets.yml.bak config/secrets.yml
sudo gitlab-ctl start

# installation from source
sudo /etc/init.d/gitlab start
bundle exec rake gitlab:two_factor:rotate_key:rollback filename=backup.csv RAILS_ENV=production
cp config/secrets.yml.bak config/secrets.yml
sudo /etc/init.d/gitlab start

```

## GitLab Duoにユーザーを一括割り当て {#bulk-assign-users-to-gitlab-duo}

ユーザーのユーザー名が記載されたCSVファイルを使用して、GitLab Duoにユーザーを一括割り当てできます。CSVファイルには、`username`というヘッダーがあり、その後に各行にユーザー名が続く必要があります。

```plaintext
username
user1
user2
user3
user4
```

### GitLab Duo Pro {#gitlab-duo-pro}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142189)されました。

{{< /history >}}

GitLab Duo Proの一括ユーザー割り当てを実行するには、以下のRakeタスクを使用します:

```shell
bundle exec rake duo_pro:bulk_user_assignment DUO_PRO_BULK_USER_FILE_PATH=path/to/your/file.csv
```

ファイルのパスで角括弧を使用したい場合は、それらをエスケープするか、二重引用符を使用できます:

```shell
bundle exec rake duo_pro:bulk_user_assignment\['path/to/your/file.csv'\]
# or
bundle exec rake "duo_pro:bulk_user_assignment[path/to/your/file.csv]"
```

### GitLab Duo ProおよびEnterprise {#gitlab-duo-pro-and-enterprise}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187230)されました。

{{< /history >}}

#### GitLab Self-Managed {#gitlab-self-managed}

このRakeタスクは、利用可能な購入済みアドオンに基づいて、GitLab Duo ProまたはEnterpriseのシートをインスタンスレベルでCSVファイルからユーザーリストに一括割り当てします。

GitLab Self-Managedインスタンスの一括ユーザー割り当てを実行するには:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment DUO_BULK_USER_FILE_PATH=path/to/your/file.csv
```

ファイルのパスで角括弧を使用したい場合は、それらをエスケープするか、二重引用符を使用できます:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment\['path/to/your/file.csv'\]
# or
bundle exec rake "gitlab_subscriptions:duo:bulk_user_assignment[path/to/your/file.csv]"
```

#### GitLab.com {#gitlabcom}

GitLab.comの管理者も、このRakeタスクを使用して、当該グループで利用可能な購入済みアドオンに基づいて、GitLab.comグループにGitLab Duo ProまたはEnterpriseのシートを一括割り当てできます。

GitLab.comグループの一括ユーザー割り当てを実行するには:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment DUO_BULK_USER_FILE_PATH=path/to/your/file.csv NAMESPACE_ID=<namespace_id>
```

ファイルのパスで角括弧を使用したい場合は、それらをエスケープするか、二重引用符を使用できます:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment\['path/to/your/file.csv','<namespace_id>'\]
# or
bundle exec rake "gitlab_subscriptions:duo:bulk_user_assignment[path/to/your/file.csv,<namespace_id>]"
```

## トラブルシューティング {#troubleshooting}

### 一括ユーザー割り当て中のエラー {#errors-during-bulk-user-assignment}

Rakeタスクを使用して一括ユーザー割り当てを行う際、以下のエラーが発生する可能性があります:

- `User is not found`: 指定されたユーザーが見つかりませんでした。提供されたユーザー名が既存のユーザーと一致していることを確認してください。
- `ERROR_NO_SEATS_AVAILABLE`: ユーザー割り当てに利用できるシートがありません。現在のシートの割り当てを確認するには、[割り当て済みのGitLab Duoユーザーを表示](../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users)する方法を参照してください。
- `ERROR_INVALID_USER_MEMBERSHIP`: ユーザーは非アクティブであるか、ボットであるか、またはゴーストであるため、割り当ての対象ではありません。ユーザーがアクティブであり、GitLab.comにいる場合は、提供されたネームスペースのメンバーであることを確認してください。

## 関連トピック {#related-topics}

- [ユーザーパスワードのリセット](../../security/reset_user_password.md#use-a-rake-task)

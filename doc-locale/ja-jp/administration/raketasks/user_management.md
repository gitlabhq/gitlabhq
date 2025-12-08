---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザー管理Rakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、ユーザーを管理するためのRakeタスクを提供します。は、**管理者**エリアを使用して[ユーザーを管理](../admin_area.md#administering-users)することもできます。

## すべてのプロジェクトにデベロッパーとしてユーザーを追加 {#add-user-as-a-developer-to-all-projects}

すべてのプロジェクトにデベロッパーとしてユーザーを追加するには、次を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_projects[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_projects[username@domain.tld] RAILS_ENV=production
```

## すべてのプロジェクトにすべてのユーザーを追加 {#add-all-users-to-all-projects}

すべてのプロジェクトにすべてのユーザーを追加するには、次を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_projects

# installation from source
bundle exec rake gitlab:import:all_users_to_all_projects RAILS_ENV=production
```

はとして追加され、他のすべてのユーザーはデベロッパーとして追加されます。

## すべてのグループにデベロッパーとしてユーザーを追加 {#add-user-as-a-developer-to-all-groups}

すべてのグループにデベロッパーとしてユーザーを追加するには、次を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_groups[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_groups[username@domain.tld] RAILS_ENV=production
```

## すべてのグループにすべてのユーザーを追加 {#add-all-users-to-all-groups}

すべてのグループにすべてのユーザーを追加するには、次を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_groups

# installation from source
bundle exec rake gitlab:import:all_users_to_all_groups RAILS_ENV=production
```

はオーナーとして追加されるため、グループに他のユーザーを追加できます。

## 指定されたグループのすべてのユーザーを`project_limit:0`および`can_create_group: false`に更新します {#update-all-users-in-a-given-group-to-project_limit0-and-can_create_group-false}

指定されたグループのすべてのユーザーを`project_limit: 0`および`can_create_group: false`に更新するには、次を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:user_management:disable_project_and_group_creation\[:group_id\]

# installation from source
bundle exec rake gitlab:user_management:disable_project_and_group_creation\[:group_id\] RAILS_ENV=production
```

これにより、指定されたグループ、そのサブグループ、およびこのグループネームスペース内のプロジェクトのすべてのユーザーが、注記された制限で更新されます。

## 請求対象ユーザーの数を制御します {#control-the-number-of-billable-users}

この設定を有効にすると、がクリアするまで、新しいユーザーはブロックされたままになります。デフォルトは`false`です:

```plaintext
block_auto_created_users: false
```

## すべてのユーザーに対して2要素認証を無効にする {#disable-two-factor-authentication-for-all-users}

このタスクは、有効になっているすべてのユーザーに対して2要素認証（2FA）を無効にします。これは、たとえば、GitLabの`config/secrets.yml`ファイルが失われ、ユーザーがサインインできない場合に役立ちます。

すべてのユーザーに対して2要素認証を無効にするには、次を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:two_factor:disable_for_all_users

# installation from source
bundle exec rake gitlab:two_factor:disable_for_all_users RAILS_ENV=production
```

## 2要素認証の暗号化キーをローテーションします {#rotate-two-factor-authentication-encryption-key}

GitLabは、encryptedデータベースカラムに2要素認証（2FA）に必要なシークレットデータを保存します。このデータの暗号化キーは`otp_key_base`と呼ばれ、`config/secrets.yml`に保存されます。

そのファイルが漏洩した場合でも、個々の2FAシークレットが漏洩していない場合は、新しい暗号化キーを使用してそれらのシークレットを再encryptedにすることができます。これにより、すべてのユーザーに2FAの詳細の変更を強制することなく、漏洩したキーを変更できます。

2要素認証の暗号化キーをローテーションするには、次の手順を実行します:

1. `config/secrets.yml`ファイルで古いキーを検索しますが、**必ずproductionセクションを操作してください**。対象の行は次のようになります:

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

1. GitLabサーバーを停止し、既存のシークレットファイルをバックアップし、データベースを更新します:

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

   `<old key>`の値は、`config/secrets.yml`から読み取ることができます（`<new key>`は以前に生成されました）。ユーザー2FAシークレットの**encrypted**（暗号化された）値は、指定された`filename`に書き込まれます。これは、エラーが発生した場合にロールバックするために使用できます。

1. `config/secrets.yml`を変更して`otp_key_base`を`<new key>`に設定し、再起動します。繰り返しますが、**production**セクションで操作していることを確認してください。

   ```shell
   # omnibus-gitlab
   sudo gitlab-ctl start

   # installation from source
   sudo /etc/init.d/gitlab start
   ```

問題が発生した場合（`old_key`に間違った値を使用しているなど）、`config/secrets.yml`のバックアップを復元し、変更をロールバックできます:

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

## GitLab Duoにユーザーを一括で割り当て {#bulk-assign-users-to-gitlab-duo}

ユーザーの名前が記載されたCSVファイルを使用して、ユーザーをGitLab GitLab Duoに一括で割り当てできます。CSVファイルには、`username`という名前のヘッダーがあり、その後に後続の各行にユーザー名が続く必要があります。

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

GitLab Duo Proのユーザーの割り当てを一括で実行するには、次のRakeタスクを使用します:

```shell
bundle exec rake duo_pro:bulk_user_assignment DUO_PRO_BULK_USER_FILE_PATH=path/to/your/file.csv
```

ファイルパスで角かっこを使用する場合は、それらをエスケープするか、二重引用符を使用できます:

```shell
bundle exec rake duo_pro:bulk_user_assignment\['path/to/your/file.csv'\]
# or
bundle exec rake "duo_pro:bulk_user_assignment[path/to/your/file.csv]"
```

### GitLab Duo ProとEnterprise {#gitlab-duo-pro-and-enterprise}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187230)されました。

{{< /history >}}

#### GitLab Self-Managed {#gitlab-self-managed}

このRakeタスクは、購入済みのアドオンに基づいて、インスタンスレベルでGitLab Duo ProまたはEnterpriseのシートをCSVファイルからユーザーのリストに一括で割り当てます。

GitLab Self-Managedインスタンスのユーザーの割り当てを一括で実行するには、次のようにします:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment DUO_BULK_USER_FILE_PATH=path/to/your/file.csv
```

ファイルパスで角かっこを使用する場合は、それらをエスケープするか、二重引用符を使用できます:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment\['path/to/your/file.csv'\]
# or
bundle exec rake "gitlab_subscriptions:duo:bulk_user_assignment[path/to/your/file.csv]"
```

#### GitLab.com {#gitlabcom}

GitLab.comのは、このRakeタスクを使用して、グループで使用可能な購入済みアドオンに基づいて、GitLab.comグループのGitLab Duo ProまたはEnterpriseのシートを一括で割り当てることもできます。

GitLab.comグループのユーザーの割り当てを一括で実行するには、次のようにします:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment DUO_BULK_USER_FILE_PATH=path/to/your/file.csv NAMESPACE_ID=<namespace_id>
```

ファイルパスで角かっこを使用する場合は、それらをエスケープするか、二重引用符を使用できます:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment\['path/to/your/file.csv','<namespace_id>'\]
# or
bundle exec rake "gitlab_subscriptions:duo:bulk_user_assignment[path/to/your/file.csv,<namespace_id>]"
```

## トラブルシューティング {#troubleshooting}

### ユーザーの割り当ての一括処理中のエラー {#errors-during-bulk-user-assignment}

ユーザーの割り当ての一括処理にRakeタスクを使用すると、次のエラーが発生する可能性があります:

- `User is not found`: 指定されたユーザーが見つかりませんでした。指定されたユーザー名が既存のユーザーと一致することを確認してください。
- `ERROR_NO_SEATS_AVAILABLE`: ユーザーの割り当てに使用できるシートはもうありません。現在のシートの割り当てを確認する方法については、[GitLab Duoに割り当てられたユーザーの表示](../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users)を参照してください。
- `ERROR_INVALID_USER_MEMBERSHIP`: ユーザーが非アクティブなボット、またはゴーストであるため、割り当ての対象ではありません。ユーザーがアクティブであり、GitLab.comの場合は、指定されたネームスペースのメンバーであることを確認してください。

## 関連トピック {#related-topics}

- [ユーザーパスワードをリセットする](../../security/reset_user_password.md#use-a-rake-task)

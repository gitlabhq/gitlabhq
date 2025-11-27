---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: LDAP Rakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

以下は、LDAP関連のRakeタスクです。

## 確認 {#check}

LDAPチェックRakeタスクは、`bind_dn`と`password`の認証情報（設定されている場合）をテストし、LDAPユーザーのサンプルをリストします。このタスクは、`gitlab:check`タスクの一部としても実行されますが、以下のコマンドを使用して個別に実行できます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:ldap:check
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:check
```

{{< /tab >}}

{{< /tabs >}}

デフォルトでは、このタスクは100人のLDAPユーザーのサンプルを返します。チェックタスクに数値を渡すことで、この制限を変更します:

```shell
rake gitlab:ldap:check[50]
```

## グループ同期を実行 {#run-a-group-sync}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

以下のタスクは、[グループ同期](../auth/ldap/ldap_synchronization.md#group-sync)をすぐに実行します。これは、スケジュールされた次回のグループ同期が実行されるのを待たずに、設定されたすべてのグループグループメンバーシップをLDAPに対して更新したい場合に役立ちます。

{{< alert type="note" >}}

グループ同期の実行頻度を変更したい場合は、代わりに[cronスケジュールを調整](../auth/ldap/ldap_synchronization.md#adjust-ldap-sync-schedule)してください。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:ldap:group_sync
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:group_sync
```

{{< /tab >}}

{{< /tabs >}}

## プロバイダー名の変更 {#rename-a-provider}

`gitlab.yml`または`gitlab.rb`でLDAPサーバーIDを変更する場合は、すべてのユーザーIDを更新する必要があります。そうしないと、ユーザーはサインインできません。新旧のプロバイダーを入力すると、このタスクはデータベース内のすべての一致するIDを更新します。

`old_provider`と`new_provider`は、プレフィックス`ldap`と設定ファイルからのLDAPサーバーIDから派生しています。たとえば、`gitlab.yml`または`gitlab.rb`では、次のようなLDAP設定が表示される場合があります:

```yaml
main:
  label: 'LDAP'
  host: '_your_ldap_server'
  port: 389
  uid: 'sAMAccountName'
  # ...
```

`main`はLDAPサーバーIDです。まとめて、一意のプロバイダーは`ldapmain`です。

{{< alert type="warning" >}}

誤った新しいプロバイダーを入力すると、ユーザーはサインインできません。この問題が発生した場合は、誤ったプロバイダーを`old_provider`として、正しいプロバイダーを`new_provider`として、タスクを再度実行してください。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[old_provider,new_provider]
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:rename_provider[old_provider,new_provider]
```

{{< /tab >}}

{{< /tabs >}}

### 例 {#example}

デフォルトのサーバーID `main`（完全なプロバイダー`ldapmain`）から始めることを検討してください。`main`を`mycompany`に変更すると、`new_provider`は`ldapmycompany`になります。すべてのユーザーIDの名前を変更するには、次のコマンドを実行します:

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[ldapmain,ldapmycompany]
```

出力例: 

```plaintext
100 users with provider 'ldapmain' will be updated to 'ldapmycompany'.
If the new provider is incorrect, users will be unable to sign in.
Do you want to continue (yes/no)? yes

User identities were successfully updated
```

### その他のオプション {#other-options}

`old_provider`と`new_provider`を指定しない場合、タスクはそれらをプロンプトします:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:ldap:rename_provider
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:rename_provider
```

{{< /tab >}}

{{< /tabs >}}

**Example output**（出力例）:

```plaintext
What is the old provider? Ex. 'ldapmain': ldapmain
What is the new provider? Ex. 'ldapcustom': ldapmycompany
```

このタスクは、`force`環境変数も受け入れます。これにより、確認ダイアログがスキップされます:

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[old_provider,new_provider] force=yes
```

## シークレット {#secrets}

GitLabは、[LDAP設定シークレット](../auth/ldap/_index.md#use-encrypted-credentials)を使用して、暗号化されたファイルを読み取りできます。以下のRakeタスクは、暗号化されたファイルの内容を更新するために提供されています。

### シークレットの表示 {#show-secret}

現在のLDAPシークレットの内容を表示します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:ldap:secret:show
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:secret:show
```

{{< /tab >}}

{{< /tabs >}}

**Example output**（出力例）:

```plaintext
main:
  password: '123'
  bind_dn: 'gitlab-adm'
```

### シークレットの編集 {#edit-secret}

シークレットの内容をエディタで開き、終了すると、結果の内容を暗号化されたシークレットファイルに書き込みます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo RAILS_ENV=production EDITOR=vim -u git -H bundle exec rake gitlab:ldap:secret:edit
```

{{< /tab >}}

{{< /tabs >}}

### ローシークレットの書き込み {#write-raw-secret}

STDINで新しいシークレットコンテンツを提供して書き込みます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
echo -e "main:\n  password: '123'" | sudo gitlab-rake gitlab:ldap:secret:write
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
echo -e "main:\n  password: '123'" | sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:secret:write
```

{{< /tab >}}

{{< /tabs >}}

### シークレットの例 {#secrets-examples}

**Editor example**（エディタ）

書き込みタスクは、編集コマンドがエディタで機能しない場合に使用できます:

```shell
# Write the existing secret to a plaintext file
sudo gitlab-rake gitlab:ldap:secret:show > ldap.yaml
# Edit the ldap file in your editor
...
# Re-encrypt the file
cat ldap.yaml | sudo gitlab-rake gitlab:ldap:secret:write
# Remove the plaintext file
rm ldap.yaml
```

**KMS integration example**（KMSインテグレーションの例）

KMSで暗号化されたコンテンツの受信アプリケーションとしても使用できます:

```shell
gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:ldap:secret:write
```

**Google Cloud secret integration example**（Google Cloudシークレットインテグレーションの例）

Google Cloudからシークレットを受信するアプリケーションとしても使用できます:

```shell
gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:ldap:secret:write
```

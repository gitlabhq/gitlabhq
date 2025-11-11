---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linuxパッケージインスタンスのアップグレードのトラブルシューティング
description: Linuxパッケージインスタンスをアップグレードする際の問題の解決策。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

トラブルシューティングを支援するため、以下のコマンドを実行してください。

```shell
sudo gitlab-ctl status
sudo gitlab-rake gitlab:check SANITIZE=true
```

詳細については、次を参照してください:

- メンテナンスに`gitlab-ctl`を使用する方法については、[メンテナンスコマンド](https://docs.gitlab.com/omnibus/maintenance/)を参照してください。
- 設定チェックに`gitlab-rake`を使用する方法については、[GitLabの構成を確認](../../administration/raketasks/maintenance.md#check-gitlab-configuration)を参照してください。

## オペレーティングシステムのアップグレード後に新しいバージョンが見つからない {#no-new-version-found-after-upgrading-operating-system}

GitLabをアップグレードする前に、オペレーティングシステムのアップグレードが必要になる場合があります。オペレーティングシステムをアップグレードする際に、オペレーティングシステムのパッケージマネージャー設定で、GitLabパッケージのソースURLを更新する必要がある場合もあります。

パッケージマネージャーが利用可能なアップグレードを見つけられないが、アップグレードが利用可能であるはずの場合は、GitLabパッケージリポジトリを再度追加してください。詳細については、[Linuxパッケージを使用してGitLabをインストールする](../../install/package/_index.md)に関する情報を参照してください。

今後のGitLabアップグレードは、アップグレードされたオペレーティングシステムに従って取得されます。

## ログに`PG::UndefinedColumn: ERROR:..`メッセージが表示される500エラー {#500-errors-with-pgundefinedcolumn-error-message-in-logs}

アップグレード後、`PG::UndefinedColumn: ERROR:...`のようなメッセージが表示される`500`エラーが発生し始めた場合、これらのエラーの原因は次のいずれかである可能性があります:

- [データベース移行](../background_migrations.md)が完了していません。移行が完了するまで待ってください。
- データベース移行は完了しましたが、GitLabが新しいスキーマを読み込む必要があります。新しいスキーマを読み込むには、[GitLabを再起動](../../administration/restart_gitlab.md)してください。

## エラー: 内部GitLab APIへの接続に失敗しました {#error-failed-to-connect-to-the-internal-gitlab-api}

別のGitLab Pagesサーバーで`Failed to connect to the internal GitLab API`エラーが発生した場合は、[GitLab Pages管理トラブルシューティング](../../administration/pages/troubleshooting.md#failed-to-connect-to-the-internal-gitlab-api)を参照してください。

## 署名の検証中にエラーが発生しました {#an-error-occurred-during-the-signature-verification}

`apt-get update`を実行するときにこのエラーが発生した場合:

```plaintext
An error occurred during the signature verification
```

次のコマンドを使用して、GitLabパッケージサーバーのGPGキーを更新します:

```shell
[ -x /usr/bin/apt-key ] &&
    [ -s /etc/apt/trusted.gpg ] &&
    apt-key --keyring /etc/apt/trusted.gpg del packages@gitlab.com
curl --fail --silent --show-error \
     --output /etc/apt/trusted.gpg.d/gitlab.asc \
     --url "https://packages.gitlab.com/gpg.key"
apt-get update
```

## `Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails] [..] Command timed out after 3600s` {#mixlibshelloutcommandtimeout-rails_migrationgitlab-rails--command-timed-out-after-3600s}

データベーススキーマとデータの変更（データベース移行）の実行に1時間以上かかる場合、アップグレードは`timed out`エラーで失敗します:

```plaintext
FATAL: Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails] (gitlab::database_migrations line 51)
had an error: Mixlib::ShellOut::CommandTimeout: bash[migrate gitlab-rails database]
(/opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/resources/rails_migration.rb line 16)
had an error: Mixlib::ShellOut::CommandTimeout: Command timed out after 3600s:
```

このエラーを修正するには:

1. 残りのデータベース移行を実行します:

   ```shell
   sudo gitlab-rake db:migrate
   ```

   このコマンドの完了には非常に長い時間がかかる場合があります。SSHセッションが切断された場合にプログラムが中断されないように、`screen`またはその他のメカニズムを使用してください。

1. アップグレードを完了します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `puma`サービスと`sidekiq`サービスをホット読み込みします:

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   ```

## アセットファイルが見つかりません {#missing-asset-files}

アップグレード後、GitLabは次のようなアセットを正しく提供しない場合があります:

- 画像
- JavaScript
- スタイルシート

GitLabで500エラーが発生したり、Webユーザーインターフェースが正しく表示されない場合があります。

スケールアウトされたGitLab環境では、ロードバランサーの背後にある1つのWebサーバーがこのイシューを発生させている場合、問題が断続的に発生します。

アセットを再コンパイルする[Rakeタスク](../../administration/raketasks/maintenance.md#precompile-the-assets)は、`/opt/gitlab/embedded/service/gitlab-rails/public/assets`から事前コンパイルされたアセットを提供するLinuxパッケージインストールには適用されません。

以下のセクションでは、考えられる原因と解決策について概説します。

### 古いプロセス {#old-processes}

古いプロセスの最も可能性の高い原因は、古いPumaプロセスが実行されていることです。古いPumaプロセスは、クライアントに以前のリリースのGitLabからのアセットファイルを要求するように指示できます。ファイルが存在しなくなったため、HTTP 404エラーが返されます。

再起動は、これらの古いPumaプロセスが実行されなくなったことを確認する最良の方法です。または、次のことを実行できます:

1. Pumaを停止します:

   ```shell
   gitlab-ctl stop puma
   ```

1. 残りのPumaプロセスを確認し、強制終了します:

   ```shell
   ps -ef | egrep 'puma[: ]'
   kill <processid>
   ```

1. Pumaプロセスが実行を停止したことを`ps`で確認します。
1. Pumaを起動します

   ```shell
   gitlab-ctl start puma
   ```

### 重複するスプロケットファイル {#duplicate-sprockets-files}

コンパイルされたアセットファイルには、各リリースで一意のファイル名があります。スプロケットファイルは、アプリケーションコード内のファイル名から一意のファイル名へのマッピングを提供します。

```plaintext
/opt/gitlab/embedded/service/gitlab-rails/public/assets/.sprockets-manifest*.json
```

スプロケットファイルが1つしかないことを確認してください。[Railsは最初に使用します](https://github.com/rails/sprockets-rails/blob/118ce60b1ffeb7a85640661b014cd2ee3c4e3e56/lib/sprockets/railtie.rb#L201)。

重複するスプロケットファイルのチェックは、Linuxパッケージのアップグレード中に実行されます:

```plaintext
GitLab discovered stale file(s) from the previous install that need to be cleaned up.
The following files need to be removed:

/opt/gitlab/embedded/service/gitlab-rails/public/assets/.sprockets-manifest-e16fdb7dd73cfdd64ed9c2cc0e35718a.json
```

これの解決オプションは次のとおりです:

- パッケージのアップグレードからの出力がある場合は、指定されたファイルを削除します。次に、Pumaを再起動します:

  ```shell
  gitlab-ctl restart puma
  ```

- メッセージがない場合は、再インストールを実行して再度生成します。詳細については、[不完全なインストール](#incomplete-installation)を参照してください。
- すべてのスプロケットファイルを削除し、[不完全なインストール](#incomplete-installation)の手順に従います。

### 不完全なインストール {#incomplete-installation}

不完全なインストールは、アセットファイルが見つからない問題の原因である可能性があります。

この問題であるかどうかを判断するために、パッケージを確認してください:

- Debianディストリビューションの場合:

  ```shell
  apt-get install debsums
  debsums -c gitlab-ee
  ```

- Red Hat/SUSE（RPM）ディストリビューションの場合:

  ```shell
  rpm -V gitlab-ee
  ```

不完全なインストールを修正するためにパッケージを再インストールするには:

1. インストールされているバージョンを確認してください:

   - Debianディストリビューションの場合:

     ```shell
     apt --installed list gitlab-ee
     ```

   - Red Hat/SUSE（RPM）ディストリビューションの場合:

     ```shell
     rpm -qa gitlab-ee
     ```

1. インストールされているバージョンを指定して、パッケージを再インストールします。たとえば、14.4.0 Enterprise Edition:

   - Debianディストリビューションの場合:

     ```shell
     apt-get install --reinstall gitlab-ee=14.4.0-ee.0
     ```

   - Red Hat/SUSE（RPM）ディストリビューションの場合:

     ```shell
     yum reinstall gitlab-ee-14.4.0
     ```

### NGINX Gzipサポートが無効になっています {#nginx-gzip-support-disabled}

`nginx['gzip_enabled']`が無効になっているかどうかを確認します:

```shell
grep gzip /etc/gitlab/gitlab.rb
```

これにより、一部のアセットが提供されなくなる可能性があります。関連するイシューの1つで[詳細をご覧ください](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6087#note_558194395)。

## ActiveRecord::LockWaitTimeoutエラー、スリープ後に再試行 {#activerecordlockwaittimeout-error-retrying-after-sleep}

まれに、Sidekiqがビジー状態になり、移行が変更しようとしているテーブルをロックします。この問題を解決するには、以下を実行します:

1. GitLabを読み取り専用モードにします。
1. Sidekiqを停止します:

   ```shell
   gitlab-ctl stop sidekiq
   ```

## GPG署名の検証エラー: 無効なGPG署名 {#gpg-signature-verification-error-bad-gpg-signature}

`yum update`または`dnf update`を実行すると、次のエラーが発生する可能性があります:

```plaintext
Error: Failed to download metadata for repo 'gitlab_gitlab-ee-source': repomd.xml GPG signature verification error: Bad GPG signature
```

この問題を解決するには、以下を実行します:

1. `dnf clean all`を実行します。
1. [最新の署名キーをフェッチします](https://docs.gitlab.com/omnibus/update/package_signatures/?tab=CentOS%2FOpenSUSE%2FSLES#fetch-latest-signing-key)。
1. もう一度アップグレードを試みます。

`dnf clean all`後もエラーが解決しない場合は、影響を受けるリポジトリキャッシュディレクトリを手動で削除してください。この例では: 

1. `/var/cache/dnf/gitlab_gitlab-ee-source`を削除します。
1. `dnf makecache`を実行します。

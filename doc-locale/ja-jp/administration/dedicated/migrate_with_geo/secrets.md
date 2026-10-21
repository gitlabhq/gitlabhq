---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Self-Managedインスタンスから移行シークレットを収集してアップロードします。
title: Geo移行のシークレットの収集
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

> [!note]
> GitLab Dedicated for Governmentは、継続的なGeoレプリケーションやGeoベースのフェイルオーバーをサポートしていません。新しいテナントのオンボーディング用のGeo移行はサポートされていますが、VPN接続が必要です。これを設定するには、GitLab Dedicated for Governmentのオンボーディングチームにお問い合わせください。

Geo移行には、移行後にGitLab Dedicatedがデータを復号化できるように、GitLab Self-Managedのプライマリインスタンスからのシークレットが必要です。これらのシークレットには、データベースの暗号化キー、CI/CD変数、その他の機密性の高い設定の詳細が含まれます。

SSHホストキーはオプションですが、強く推奨されます。これらを保持しておくと、移行後にユーザーがSSH経由で`git clone`または`git pull`を実行する際のSSHホストキー検証の失敗を防げます。独自のドメインを使用する予定がある場合は、特に重要です。

収集スクリプトは、ファイル暗号化ツールである[age](https://github.com/FiloSottile/age)を使用して、Switchboardにアップロードする前にシークレットを安全に暗号化します。

## 移行シークレットを収集してアップロードする {#collect-and-upload-migration-secrets}

[GitLab Dedicatedインスタンスを作成する](../create_instance/_index.md#create-your-instance)際に、Geo移行シークレットを収集してアップロードします。

前提条件: 

- GitLab Self-Managedのプライマリインスタンスへの管理アクセス権
- Python 3.x
- Switchboardの**Geo移行シークレット**ページにある`age`公開キー
- GitLabクラスターへのアクセス用に設定された`kubectl`（Kubernetesインストールのみ）

移行シークレットを収集してアップロードするには、次の手順に従います:

1. [Switchboard](https://console.gitlab-dedicated.com/)にサインインします。
1. **Geo移行シークレット**ページで、インストールタイプに適した収集スクリプトをダウンロードします。
1. オプション。オフライン環境の場合は、実行する前に`age`バイナリを収集スクリプトに埋め込みます。詳細については、[オフライン環境](#offline-environments)を参照してください。
1. インストールタイプに応じた収集スクリプトを実行し、`<age_public_key>`をページに表示されているキーに置き換えます:

   - Linuxパッケージインストールの場合は、Railsノードで次のコマンドを実行します:

     ```shell
     python3 collect_secrets_linux_package.py <age_public_key>
     ```

     `/etc/gitlab/gitlab-secrets.json`、`/var/opt/gitlab/gitlab-rails/etc/database.yml`、および`/etc/ssh/`への読み取りアクセス権が必要です。

   - Kubernetesインストールの場合は、`kubectl`アクセス権を持つワークステーションから次のコマンドを実行します:

     ```shell
     python3 collect_secrets_k8s.py <age_public_key>
     ```

     デフォルト値を上書きするには、追加のフラグを渡すことができます。詳細については、[Kubernetes収集スクリプトのフラグ](#kubernetes-collection-script-flags)を参照してください。

1. オプション。SSHホストキーのみを収集するには、コマンドに`--hostkeys-only`フラグを追加します。

   このスクリプトは、次を生成します:

   - `migration_secrets.json.age`: GitLabシークレット（必須）
   - `ssh_host_keys.json.age`: SSHホストキー（オプションですが推奨）

1. `migration_secrets.json.age`ファイルをアップロードします。
1. オプション。`ssh_host_keys.json.age`ファイルをアップロードします。
1. 検証が完了するまで待ちます。検証には、ファイルごとに約10～20秒かかります。
1. 表示されるファイル名とフィンガープリントが、アップロードしたファイルと一致することを確認します。

> [!note]
> 検証では、ファイルが適切に暗号化され、期待される構造を含んでいることを確認します。ファイルの内容を復号化したり、公開したりすることはありません。

シークレットをアップロードしたら、残りの手順を完了してテナントを作成します。

### Kubernetes収集スクリプトのフラグ {#kubernetes-collection-script-flags}

デフォルト値を上書きするには、これらのオプションフラグを`collect_secrets_k8s.py`とともに使用します:

| フラグ                     | デフォルト         | 説明 |
|--------------------------|-----------------|-------------|
| `--namespace NAME`       | 現在のコンテキスト | Kubernetesネームスペース。 |
| `--release NAME`         | `gitlab`        | Helmリリース名のプレフィックス。 |
| `--rails-secret NAME`    | なし            | Railsシークレットのシークレット名。 |
| `--registry-secret NAME` | なし            | レジストリシークレット名。 |
| `--postgres-secret NAME` | なし            | Postgresパスワードのシークレット名。 |
| `--hostkeys-secret NAME` | なし            | SSHホストキーのシークレット名。 |

### オフライン環境 {#offline-environments}

GitLab Self-Managedインスタンスにインターネットアクセスがない場合は、実行する前に`age`バイナリを収集スクリプトに埋め込みます。

オフライン環境用に収集スクリプトを設定するには:

1. インターネットアクセスのあるマシンで、[Geoシークレット収集](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/geo-secrets-collection)プロジェクトから`download_age_binaries.py`と`embed_age_binary.py`をダウンロードし、Switchboardからダウンロードした収集スクリプトと同じディレクトリに配置します。
1. `age`バイナリをダウンロードしてエンコードします:

   ```shell
   python3 download_age_binaries.py > age_binaries.txt
   ```

   このスクリプトは、Linux AMD64およびARM64用のbase64エンコードされた`age`バイナリを標準出力に出力するため、その出力を`age_binaries.txt`にリダイレクトする必要があります。

1. バイナリを収集スクリプトに埋め込みます:

   ```shell
   python3 embed_age_binary.py
   ```

   このスクリプトは、現在のディレクトリから`age_binaries.txt`を読み取り、`collect_secrets_linux_package.py`と`collect_secrets_k8s.py`を埋め込みバイナリを含むバージョンで上書きします。

1. 更新された収集スクリプトをオフライン環境に転送します。
1. [移行シークレットを収集してアップロードする](#collect-and-upload-migration-secrets)の説明に従って、GitLab Self-Managedインスタンスでスクリプトを実行します。

更新されたスクリプトは自己完結型であり、埋め込まれた`age`バイナリを自動的に抽出して使用します。

## トラブルシューティング {#troubleshooting}

Geo移行を使用する際に、次の問題が発生する可能性があります。

### エラー: 収集スクリプトの実行時に`Permission denied`が発生する {#error-permission-denied-when-running-the-collection-script}

収集スクリプトがGitLab設定ファイルにアクセスしようとすると、権限エラーが発生することがあります。

この問題は、スクリプトが必要なファイルを読み取るのに十分な権限なしで実行された場合に発生します。

この問題を解決するには:

1. Linuxパッケージインストールの場合は、`root`ユーザーとしてスクリプトを実行するか、`sudo`を使用してください。
1. Kubernetesインストールの場合は、`kubectl`コンテキストがGitLabネームスペースへのアクセス権を持っていることを確認してください。
1. 必要なファイルが想定されるパスに存在することを確認します。

### 収集スクリプトがGitLabインストールを見つけられない {#collection-script-cannot-find-gitlab-installation}

スクリプトがGitLabのインストールまたは設定ファイルを見つけられないというエラーが発生することがあります。

この問題は、次のシナリオで発生します:

- GitLabがインストールされていないマシンでスクリプトが実行される。
- GitLabが非標準の場所にインストールされている。
- 必要な設定ファイルが不足しているか、移動されている。

一般的なエラーメッセージには、次のものがあります:

- Linuxパッケージ: `Error: database.yml not found: /var/opt/gitlab/gitlab-rails/etc/database.yml`の後に`✗ Failed to collect GitLab secrets`が続く
- Kubernetes: `Error: Could not retrieve gitlab-rails-secrets`

この問題を解決するには:

1. スクリプトが正しいマシン（Linuxパッケージインストールの場合はRailsノード）で実行されることを確認します。
1. GitLabが正しくインストールおよび設定されていることを確認します。
1. GitLabが非標準の場所にインストールされている場合は、設定ファイルのパスがインストール内容と一致していることを確認します。
1. 必要なファイルが不足しているか破損している場合は、移行を進める前にプロフェッショナルサービスに連絡して、インストールのヘルスチェックを実施してください。

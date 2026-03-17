---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Self-ManagedからGitLab DedicatedへGeoを使用して移行します。
title: GitLab DedicatedへGeoを使用して移行
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

Geo移行では、移行後にGitLab Dedicatedがデータを復号化するために、GitLab Self-Managedのプライマリインスタンスからシークレットが必要です。これらのシークレットには、データベース暗号化キー、CI/CD変数、およびその他の機密性の高い設定詳細が含まれます。

SSHホストキーはオプションですが、強く推奨されます。これらを保持することで、移行後にユーザーがSSH経由で`git clone`または`git pull`を実行した際のSSHホストキー検証の失敗を防ぐことができます。独自のドメインを使用する予定がある場合は、特に重要です。

コレクションスクリプトはファイル暗号化ツールである[age](https://github.com/FiloSottile/age)を使用して、シークレットをスイッチボードにアップロードする前に安全に暗号化します。

## 移行シークレットを収集およびアップロードする {#collect-and-upload-migration-secrets}

[GitLab Dedicatedインスタンスを作成](create_instance/_index.md#create-your-instance)する際に、Geo移行シークレットを収集してアップロードします。

前提条件: 

- お使いのGitLab Self-Managedプライマリインスタンスへの管理者アクセス
- Python 3.x
- スイッチボードの**Geo migration secrets**ページにある`age`公開キー
- お使いのGitLabクラスターにアクセスできるように設定された`kubectl` （Kubernetesインストールのみ）

移行シークレットを収集してアップロードするには:

1. [Switchboard](https://console.gitlab-dedicated.com/)にサインインします。
1. **Geo migration secrets**ページで、インストールタイプに応じたコレクションスクリプトをダウンロードします。
1. オプション。オフライン環境の場合は、スクリプトを実行する前に`age`バイナリをコレクションスクリプトに埋め込みます。詳細については、[オフライン環境](#offline-environments)を参照してください。
1. インストールタイプに応じたコレクションスクリプトを実行し、ページに表示されているキーで`<age_public_key>`を置き換えます:

   - Linuxパッケージインストールの場合、Railsノードで次のコマンドを実行します:

     ```shell
     python3 collect_secrets_linux_package.py <age_public_key>
     ```

     これには`/etc/gitlab/gitlab-secrets.json`、`/var/opt/gitlab/gitlab-rails/etc/database.yml`、および`/etc/ssh/`への読み取りアクセスが必要です。

   - Kubernetesインストールの場合、`kubectl`アクセス権を持つワークステーションから次のコマンドを実行します:

     ```shell
     python3 collect_secrets_k8s.py <age_public_key>
     ```

     デフォルト値をオーバーライドするには、追加のフラグを渡すことができます。詳細については、[Kubernetes collection script flags](#kubernetes-collection-script-flags)を参照してください。

1. オプション。SSHホストキーのみを収集するには、コマンドに`--hostkeys-only`フラグを追加します。

   スクリプトは以下を生成します:

   - `migration_secrets.json.age`: GitLabシークレット (必須)
   - `ssh_host_keys.json.age`: SSHホストキー (オプションですが推奨)

1. `migration_secrets.json.age`ファイルをアップロードします。
1. オプション。`ssh_host_keys.json.age`ファイルをアップロードします。
1. 検証が完了するのを待ちます。検証にはファイルごとに約10～20秒かかります。
1. 表示されるファイル名とフィンガープリントがアップロードしたファイルと一致することを確認します。

> [!note]
> 検証により、ファイルが適切に暗号化された状態で、予期された構造になっていることが確認されます。これによりファイルのコンテンツが復号化されることも、公開されることもありません。

シークレットをアップロードした後、残りの手順を完了してテナントを作成します。

### Kubernetesコレクションスクリプトフラグ {#kubernetes-collection-script-flags}

`collect_secrets_k8s.py`でこれらのオプションフラグを使用してデフォルト値をオーバーライドします:

| フラグ                     | デフォルト         | 説明 |
|--------------------------|-----------------|-------------|
| `--namespace NAME`       | 現在のコンテキスト | Kubernetesネームスペース。 |
| `--release NAME`         | `gitlab`        | Helmリリース名プレフィックス。 |
| `--rails-secret NAME`    | なし            | Railsシークレットのシークレット名。 |
| `--registry-secret NAME` | なし            | レジストリシークレット名。 |
| `--postgres-secret NAME` | なし            | Postgresパスワードシークレット名。 |
| `--hostkeys-secret NAME` | なし            | SSHホストキーのシークレット名。 |

### オフライン環境 {#offline-environments}

お使いのGitLab Self-Managedインスタンスがインターネットにアクセスできない場合、コレクションスクリプトを実行する前に`age`バイナリを手動でダウンロードします。

オフライン環境用にコレクションスクリプトをセットアップするには:

1. インターネットアクセスのあるマシンで`age`バイナリをダウンロードします:

   ```shell
   python3 download_age_binaries.py
   ```

   これにより、複数のプラットフォーム用の`age`バイナリが含まれる`age_binaries.tar.gz`ファイルが生成されます。

1. `age_binaries.tar.gz`ファイルをオフライン環境に転送します。
1. バイナリをコレクションスクリプトに埋め込みます:

   ```shell
   python3 embed_age_binary.py --binaries age_binaries.tar.gz
   ```

   これにより、`age`バイナリを含む自己完結型スクリプトが作成されます。

1. [migration secretsを収集してアップロード](#collect-and-upload-migration-secrets)の説明に従って、お使いのGitLab Self-Managedインスタンスで埋め込みスクリプトを実行します。

埋め込みスクリプトは、含まれている`age`バイナリを自動的に抽出して使用します。

## トラブルシューティング {#troubleshooting}

Geo移行を操作する際、次の問題に遭遇する可能性があります。

### エラー: コレクションスクリプトの実行中に`Permission denied` {#error-permission-denied-when-running-the-collection-script}

コレクションスクリプトがGitLab設定ファイルにアクセスしようとすると、権限エラーが発生する可能性があります。

この問題は、スクリプトが必要なファイルを読み取りするための十分な権限なしで実行された場合に発生します。

この問題を解決するには、次の手順に従います:

1. Linuxパッケージインストールの場合、`root`ユーザーとしてスクリプトを実行するか、`sudo`を使用します。
1. Kubernetesインストールの場合、`kubectl`コンテキストがGitLabネームスペースにアクセスできることを確認します。
1. 必要なファイルが予期されるパスに存在することを確認します。

### コレクションスクリプトがGitLabインストールを見つけられない {#collection-script-cannot-find-gitlab-installation}

スクリプトがGitLabインストールまたは設定ファイルを見つけられないというエラーが発生する可能性があります。

この問題は、次のシナリオで発生します:

- スクリプトがGitLabがインストールされていないマシンで実行される。
- GitLabが標準以外の場所にインストールされている。
- 必要な設定ファイルが見つからないか、移動されている。

一般的なエラーメッセージには以下が含まれます:

- Linuxパッケージ: `Error: database.yml not found: /var/opt/gitlab/gitlab-rails/etc/database.yml`の後に`✗ Failed to collect GitLab secrets`
- Kubernetes: `Error: Could not retrieve gitlab-rails-secrets`

この問題を解決するには、次の手順に従います:

1. スクリプトが正しいマシン（Linuxパッケージインストールの場合、Railsノード）で実行されていることを確認します。
1. GitLabが正しくインストールされ、設定されていることを確認します。
1. GitLabが標準以外の場所にインストールされている場合、設定ファイルのパスがお使いのインストールと一致していることを確認します。
1. 必要なファイルが見つからないか破損している場合は、移行に進む前にProfessional Servicesに連絡して、インストールのヘルスチェックを実行してもらってください。

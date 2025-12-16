---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: バンドルURI
---

{{< details >}}

プラン: Free、Premium、Ultimate

提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.0で`gitaly_bundle_uri`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/8939)されました。デフォルトでは無効になっています。

{{< /history >}}

Gitalyは、Git [bundle URIs](https://git-scm.com/docs/bundle-uri)をサポートしています。バンドルURIは、リモートから残りのオブジェクトをフェッチする前に、Gitが1つまたは複数のバンドルをダウンロードしてオブジェクトデータベースをブートストラップできる場所です。バンドルURIは、Gitプロトコルに組み込まれています。

バンドルURIを使用すると、次のことが可能になります:

- GitLabサーバーへのネットワーク接続が不十分なユーザーのために、クローン作成とフェッチを高速化します。バンドルはCDNに保存して、世界中で利用できるようにすることができます。
- CI/CDジョブを実行するサーバーの負荷を軽減します。CI/CDジョブが別の場所からバンドルをプリ読み込むできる場合、不足しているオブジェクトと参照を段階的にフェッチするために残りの作業で、サーバーへの負荷を大幅に軽減できます。

## 前提要件 {#prerequisites}

バンドルURIを使用するための前提条件は、CI/CDジョブでクローンを作成するか、ターミナルでローカルにクローンを作成するかによって異なります。

### CI/CDジョブでのクローン作成 {#cloning-in-cicd-jobs}

CI/CDジョブでバンドルURIを使用する準備をするには:

1. 実行するバージョンのGitLab Runnerが使用する[GitLab Runnerヘルパーイメージ](https://gitlab.com/gitlab-org/gitlab-runner/container_registry/1472754)を選択します:

   - Gitバージョン2.49.0以降。
   - GitLab Runnerヘルパーバージョン18.0以降。

   この手順は、バンドルURIが`git clone`中にGitサーバーの負荷を軽減することを目的としたメカニズムであるため、必須です。したがって、CI/CDパイプラインが実行されると、`git`コマンドを開始する`git clone`クライアントは、GitLab Runnerです。`git`プロセスはヘルパーイメージ内で実行されます。

   イメージを選択するときは、GitLab Runnerで使用するオペレーティングシステムのディストリビューションとアーキテクチャに対応していることを確認してください。

   これらのコマンドを実行して、イメージが要件を満たしていることを確認できます:

   ```shell
   docker run -it <image:tag>
   $ git version
   $ gitlab-runner-helper -v
   ```

   オペレーティングシステムのディストリビューションのパッケージマネージャーを使用して、`gitlab-runner-helper`イメージのGitバージョンを管理します。したがって、利用可能な最新のイメージの一部は、まだGit 2.49を実行していない可能性があります。

   要件を満たすイメージが見つからない場合は、独自のカスタムビルドイメージのベースイメージとして`gitlab-runner-helper`を使用します。[GitLabコンテナレジストリ](../../user/packages/container_registry/_index.md)を使用して、カスタムビルドイメージでホストできます。

1. `config.toml`ファイルを更新して、選択したイメージを使用するようにGitLab Runnerインスタンスを設定します:

   ```toml
   [[runners]]
     (...)
     executor = "docker"
     [runners.docker]
       (...)
       helper_image = "image:tag" ## <-- put the image name and tag here
   ```

    詳細については、[ヘルパーイメージに関する情報](https://docs.gitlab.com/runner/configuration/advanced-configuration/#helper-image)を参照してください。

1. 新しい設定を有効にするには、Runnerを再起動します。
1. `FF_USE_GIT_NATIVE_CLONE`ファイルを`true`に設定して、`.gitlab-ci.yml`[GitLab Runner機能フラグ](https://docs.gitlab.com/runner/configuration/feature-flags/)を有効にします:

   ```yaml
   variables:
     FF_USE_GIT_NATIVE_CLONE: "true"
   ```

### ターミナルでローカルにクローンを作成する {#cloning-locally-in-your-terminal}

ターミナルでローカルにクローンを作成するためにバンドルURIを使用する準備として、ローカルGit設定で`bundle-uri`を有効にします:

```shell
git config --global transfer.bundleuri true
```

## サーバーの設定 {#server-configuration}

バンドルの保存場所を設定する必要があります。Gitalyは、次のストレージサービスをサポートしています:

- Google Cloud Storage
- AWS S3（または互換性のあるもの）
- Azure Blobストレージ
- ローカルファイルストレージ（非推奨）

### Azure Blobストレージを構成 {#configure-azure-blob-storage}

バンドルURIのAzure Blobストレージを設定する方法は、お使いのインストールの種類によって異なります。セルフコンパイルインストールでは、GitLabの外部で`AZURE_STORAGE_ACCOUNT`および`AZURE_STORAGE_KEY`の環境変数を設定する必要があります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`bundle_uri.go_cloud_url`を設定します:

```ruby
gitaly['env'] = {
    'AZURE_STORAGE_ACCOUNT' => 'azure_storage_account',
    'AZURE_STORAGE_KEY' => 'azure_storage_key' # or 'AZURE_STORAGE_SAS_TOKEN'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 'azblob://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`go_cloud_url`を設定します:

```toml
[bundle_uri]
go_cloud_url = "azblob://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### Google Cloudストレージを設定する {#configure-google-cloud-storage}

Google Cloudストレージ（GCP）は、アプリケーションのデフォルトの認証情報を使用して認証します。次のいずれかを使用して、各Gitalyサーバーにアプリケーションのデフォルトの認証情報をセットアップします:

- [`gcloud auth application-default login`コマンド](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login):
- `GOOGLE_APPLICATION_CREDENTIALS`環境変数。セルフコンパイルインストールの場合、GitLabの外部で環境変数を設定します。

詳細については、[アプリケーションのデフォルトの認証情報](https://cloud.google.com/docs/authentication/provide-credentials-adc)を参照してください。

デスティネーションバケットは、`go_cloud_url`オプションを使用して設定します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`go_cloud_url`を設定します:

```ruby
gitaly['env'] = {
    'GOOGLE_APPLICATION_CREDENTIALS' => '/path/to/service.json'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 'gs://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`go_cloud_url`を設定します:

```toml
[bundle_uri]
go_cloud_url = "gs://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### S3ストレージを設定する {#configure-s3-storage}

S3ストレージ認証を設定するには:

- AWS CLIで認証する場合、デフォルトのAWSセッションを使用できます。
- それ以外の場合は、`AWS_ACCESS_KEY_ID`および`AWS_SECRET_ACCESS_KEY`の環境変数を使用できます。セルフコンパイルインストールの場合、GitLabの外部で環境変数を設定します。

詳細については、[AWSセッションのドキュメント](https://docs.aws.amazon.com/sdk-for-go/api/aws/session/)を参照してください。

デスティネーションバケットとリージョンは、`go_cloud_url`オプションを使用して設定します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`go_cloud_url`を設定します:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'aws_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'aws_secret_access_key'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 's3://<bucket>?region=us-west-1'
    }
}
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`go_cloud_url`を設定します:

```toml
[bundle_uri]
go_cloud_url = "s3://<bucket>?region=us-west-1"
```

{{< /tab >}}

{{< /tabs >}}

#### S3互換サーバーを設定する {#configure-s3-compatible-servers}

{{< history >}}

- `use_path_style`と`disable_https`のパラメータは、GitLab 17.4で[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/8939)。

{{< /history >}}

MinIOなどのS3互換サーバーは、`endpoint`パラメータを追加してS3と同様に設定されます。

次のパラメータがサポートされています:

- `region`: AWSリージョン。
- `endpoint`: は、エンドポイントURLです。
- `disableSSL`: 無効にするには`true`に設定します。GitLab 17.4.0以前にご利用いただけます。GitLabバージョン17.4.0以降の場合は、`disable_https`を使用してください。
- `disable_https`: エンドポイントオプションでHTTPSを無効にするには、`true`に設定します。
- `s3ForcePathStyle`: S3オブジェクトのパススタイルのURLを強制するには、`true`に設定します。GitLabバージョン17.4.0〜17.4.3では利用できません。これらのバージョンでは、代わりに`use_path_style`を使用します。
- `use_path_style`: パススタイルのS3 URLを有効にするには、`true`（`https://<host>/<bucket>`の代わりに`https://<bucket>.<host>`）に設定します。
- `awssdk`: AWS SDKの特定のバージョンを強制します。AWS SDK v1を強制するには`v1`に設定し、AWS SDK v2を強制するには`v2`に設定します。次の場合:
  - `v1`に設定した場合は、`disable_https`の代わりに`disableSSL`を使用する必要があります。
  - 設定しない場合、`v2`がデフォルトになります。

`use_path_style`は、Go Cloud Development Kit依存関係がv0.38.0からv0.39.0に更新されたときに導入され、AWS SDK v1からv2に切り替えられました。ただし、gocloud.devメンテナーが下位互換性のサポートを追加した後、`s3ForcePathStyle`パラメータはGitLab 17.4.4で復元されました。詳細については、[issue 6489](https://gitlab.com/gitlab-org/gitaly/-/issues/6489)を参照してください。

`disable_https`は、Go Cloud Development Kit v0.40.0（AWS SDK v2）で導入されました。

`awssdk`は、Go Cloud Development Kit v0.24.0で導入されました。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`go_cloud_url`を設定します:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'minio_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'minio_secret_access_key'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 's3://<bucket>?region=minio&endpoint=my.minio.local:8080&disable_https=true&use_path_style=true'
    }
}
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`go_cloud_url`を設定します:

```toml
[bundle_uri]
go_cloud_url = "s3://<bucket>?region=minio&endpoint=my.minio.local:8080&disable_https=true&use_path_style=true"
```

{{< /tab >}}

{{< /tabs >}}

## バンドルの生成 {#generating-bundles}

Gitalyを設定すると、Gitalyは手動または自動でバンドルを生成できます。

### 手動生成 {#manual-generation}

このコマンドはバンドルを生成し、設定されたストレージサービスに保存します。

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly bundle-uri \
                                               --config=<config-file> \
                                               --storage=<storage-name> \
                                               --repository=<relative-path>
```

Gitalyは、生成されたバンドルを自動的に更新しません。バージョンのより新しいバンドルを生成する場合は、コマンドを再度実行する必要があります。

このコマンドは、`cron(8)`のようなツールでスケジュールできます。

### 自動生成 {#automatic-generation}

{{< history >}}

- GitLab 18.0で`gitaly_bundle_generation`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/16007)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

Gitalyは、同じリポジトリに対する頻繁なクローンを処理しているかどうかを判断することにより、自動的にバンドルを生成できます。現在のヒューリスティックは、`git fetch`リクエストが各リポジトリに発行された回数を追跡します。特定の間隔でリクエストの数が特定のしきい値に達すると、Gitalyは自動的にバンドルを生成します。

Gitalyは、リポジトリのバンドルを最後に生成した時刻も追跡します。`threshold`と`interval`に基づいて、新しいバンドルを再生成する必要がある場合、Gitalyは、指定されたリポジトリのバンドルが最後に生成された時刻を確認します。Gitalyは、既存のバンドルが`maxBundleAge`設定よりも古い場合にのみ、新しいバンドルを生成します。その場合、古いバンドルは上書きされます。クラウドストレージ内のリポジトリごとに1つのバンドルしか存在できません。

## バンドルURIの例 {#bundle-uri-example}

次の例では、`gitlab.com/gitlab-org/gitlab.git`をバンドルURIを使用してクローンする場合と使用せずにクローンする場合の違いを示します。

```shell
$ git -c transfer.bundleURI=false clone https://gitlab.com/gitlab-org/gitlab.git
Cloning into 'gitlab'...
remote: Enumerating objects: 5271177, done.
remote: Total 5271177 (delta 0), reused 0 (delta 0), pack-reused 5271177
Receiving objects: 100% (5271177/5271177), 1.93 GiB | 32.93 MiB/s, done.
Resolving deltas: 100% (4140349/4140349), done.
Updating files: 100% (71304/71304), done.

$ git -c transfer.bundleURI=true clone https://gitlab.com/gitlab-org/gitlab.git
Cloning into 'gitlab'...
remote: Enumerating objects: 1322255, done.
remote: Counting objects: 100% (611708/611708), done.
remote: Total 1322255 (delta 611708), reused 611708 (delta 611708), pack-reused 710547
Receiving objects: 100% (1322255/1322255), 539.66 MiB | 22.98 MiB/s, done.
Resolving deltas: 100% (1026890/1026890), completed with 223946 local objects.
Checking objects: 100% (8388608/8388608), done.
Checking connectivity: 1381139, done.
Updating files: 100% (71304/71304), done.
```

前の例では:

- バンドルURIを使用しない場合、GitLabサーバーから5,271,177個のオブジェクトを受信しました。
- バンドルURIを使用する場合、GitLabサーバーから1,322,255個のオブジェクトを受信しました。

この削減は、クライアントが最初にストレージサーバーからバンドルをダウンロードしたため、GitLabがパック化する必要があるオブジェクトが少なくなることを意味します（前の例では、オブジェクト数の約4分の1）。

## バンドルの保護 {#securing-bundles}

バンドルは、署名付きURLを使用してクライアントからアクセスできるようになります。署名付きURLは、リクエストを行うための制限されたアクセス許可と時間を提供するURLです。お使いのストレージサービスが署名付きURLをサポートしているかどうかを確認するには、ストレージサービスのドキュメントを参照してください。

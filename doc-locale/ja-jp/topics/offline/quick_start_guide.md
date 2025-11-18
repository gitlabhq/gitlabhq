---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: オフラインのGitLab Self-Managedインスタンスをインストールする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

これは、GitLab Self-Managedインスタンスを完全にオフラインでインストール、設定、および使用するのに役立つ手順ガイドです。

## インストール {#installation}

{{< alert type="note" >}}

このガイドでは、サーバーが[Linuxパッケージインストール方法](https://docs.gitlab.com/omnibus/)を使用するUbuntu 20.04であり、GitLab [Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/)が実行されていることを前提としています。他のサーバーの手順は異なる場合があります。このガイドでは、サーバーホストが`my-host.internal`として解決されることも前提としています。そのためには、サーバーのFQDNに置き換える必要があり、必要なパッケージファイルをダウンロードするために、インターネットアクセスの可能な別のサーバーへのアクセスが必要となります。

{{< /alert >}}

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>このプロセスのビデオチュートリアルは、[オフラインGitLabインストール: ダウンロードとインストール](https://www.youtube.com/watch?v=TJaq4ua2Prw)を参照してください。

### GitLabパッケージをダウンロードする {#download-the-gitlab-package}

インターネットにアクセスできる同じオペレーティングシステムタイプのサーバーを使用して、[GitLabパッケージと関連する依存関係を手動でダウンロード](../../update/package/_index.md#by-using-a-downloaded-package)する必要があります。

オフライン環境がローカルネットワークアクセスに対応していない場合は、USBドライブなどの物理メディアを介して関連パッケージを手動で転送する必要があります。

Ubuntuでこれを実行するには、インターネットアクセスの可能なサーバーで次のコマンドを使用します。

```shell
# Download the bash script to prepare the repository
curl --silent "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" | sudo bash

# Download the gitlab-ee package and dependencies to /var/cache/apt/archives
sudo apt-get install --download-only gitlab-ee

# Copy the contents of the apt download folder to a mounted media device
sudo cp /var/cache/apt/archives/*.deb /path/to/mount
```

### GitLabパッケージをインストールする {#install-the-gitlab-package}

前提要件:

- オフライン環境にGitLabパッケージをインストールする前に、必要なすべての依存関係が最初にインストールされていることを確認してください。

Ubuntuを使用している場合は、`dpkg`でコピーした依存関係`.deb`パッケージをインストールできます。GitLabパッケージはまだインストールしないでください。

```shell
# Go to the physical media device
sudo cd /path/to/mount

# Install the dependency packages
sudo dpkg -i <package_name>.deb
```

[オペレーティングシステムに関連するコマンドを使用してパッケージをインストール](../../update/package/_index.md#by-using-a-downloaded-package)しますが、`EXTERNAL_URL`インストール手順の`http` URLを指定してください。インストールしたら、SSLを手動で設定できます。

サーバーのIPアドレスにバインドするのではなく、IP解決のためのドメインを設定することを強くお勧めします。これにより、証明書のCNの安定したターゲットが保証され、長期的な解決がより簡単になります。

Ubuntuの次の例では、HTTPを使用して`EXTERNAL_URL`を指定し、GitLabパッケージをインストールします。

```shell
sudo EXTERNAL_URL="http://my-host.internal" dpkg -i <gitlab_package_name>.deb
```

## SSLを有効にする {#enabling-ssl}

これらの手順に従って、新しいインスタンスのSSLを有効にします。これらの手順は、[NGINX設定でSSLを手動で設定する](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually)手順を反映しています。

1. `/etc/gitlab/gitlab.rb`に次の変更を加えます。

   ```ruby
   # Update external_url from "http" to "https"
   external_url "https://my-host.internal"

   # Set Let's Encrypt to false
   letsencrypt['enable'] = false
   ```

1. 自己署名証明書を生成するための適切な権限を持つ次のディレクトリを作成します。

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/gitlab/ssl/my-host.internal.key -out /etc/gitlab/ssl/my-host.internal.crt
   ```

1. インスタンスを再設定して、変更を適用します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## GitLabコンテナレジストリを有効にする {#enabling-the-gitlab-container-registry}

次の手順に従って、コンテナレジストリを有効にします。これらの手順は、[既存のドメインでコンテナレジストリを設定する](../../administration/packages/container_registry.md#configure-container-registry-under-an-existing-gitlab-domain)手順を反映しています。

1. `/etc/gitlab/gitlab.rb`に次の変更を加えます。

   ```ruby
   # Change external_registry_url to match external_url, but append the port 4567
   external_url "https://gitlab.example.com"
   registry_external_url "https://gitlab.example.com:4567"
   ```

1. インスタンスを再設定して、変更を適用します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## DockerデーモンがレジストリとGitLab Runnerを信頼できるように設定する {#allow-the-docker-daemon-to-trust-the-registry-and-gitlab-runner}

[レジストリで信頼できる証明書を使用するための手順に従って](../../administration/packages/container_registry_troubleshooting.md#using-self-signed-certificates-with-container-registry)、証明書をDockerデーモンに提供します。

```shell
sudo mkdir -p /etc/docker/certs.d/my-host.internal:5000

sudo cp /etc/gitlab/ssl/my-host.internal.crt /etc/docker/certs.d/my-host.internal:5000/ca.crt
```

[Runnerで信頼できる証明書を使用するための手順に従って](https://docs.gitlab.com/runner/install/docker.html#installing-trusted-ssl-server-certificates)、証明書をGitLab Runner（次にインストール）に提供します。

```shell
sudo mkdir -p /etc/gitlab-runner/certs

sudo cp /etc/gitlab/ssl/my-host.internal.crt /etc/gitlab-runner/certs/ca.crt
```

## GitLab Runnerを有効にする {#enabling-gitlab-runner}

[GitLab RunnerをDockerサービスとしてインストールする手順と同様のプロセスに従って](https://docs.gitlab.com/runner/install/docker.html#install-the-docker-image-and-start-the-container)、最初にRunnerを登録する必要があります。

```shell
$ sudo docker run --rm -it -v /etc/gitlab-runner:/etc/gitlab-runner gitlab/gitlab-runner register
Updating CA certificates...
Runtime platform                                    arch=amd64 os=linux pid=7 revision=1b659122 version=12.8.0
Running in system-mode.

Enter the GitLab instance URL (for example, https://gitlab.com/):
https://my-host.internal
Enter the registration token:
XXXXXXXXXXX
Enter a description for the runner:
[eb18856e13c0]:
Enter tags for the runner (comma-separated):
Enter optional maintenance note for the runner:

Registering runner... succeeded                     runner=FSMwkvLZ
Please enter the executor: custom, docker, virtualbox, kubernetes, docker+machine, docker-ssh+machine, docker-ssh, parallels, shell, ssh:
docker
Please enter the default Docker image (for example, ruby:2.6):
ruby:2.6
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

ここで、Runnerに追加の設定を行う必要があります。

`/etc/gitlab-runner/config.toml`に次の変更を加えます。

- Dockerソケットをボリューム`volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]`に追加
- `pull_policy = "if-not-present"`をexecutorの設定に追加

これで、Runnerを起動できます。

```shell
sudo docker run -d --restart always --name gitlab-runner -v /etc/gitlab-runner:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest
90646b6587127906a4ee3f2e51454c6e1f10f26fc7a0b03d9928d8d0d5897b64
```

### ホストOSに対してレジストリを認証する {#authenticating-the-registry-against-the-host-os}

[Dockerレジストリ認証ドキュメント](https://distribution.github.io/distribution/about/insecure/#docker-still-complains-about-the-certificate-when-using-authentication)に記載されているように、特定のバージョンのDockerでは、OSレベルで証明書チェーンを信頼する必要があります。

Ubuntuの場合、`update-ca-certificates`を使用します。

```shell
sudo cp /etc/docker/certs.d/my-host.internal\:5000/ca.crt /usr/local/share/ca-certificates/my-host.internal.crt

sudo update-ca-certificates
```

うまくいけば、次のように表示されます。

```plaintext
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```

### バージョンチェックとService Pingを無効にする {#disable-version-check-and-service-ping}

バージョンチェックとService Pingは、GitLabユーザーエクスペリエンスを向上させ、ユーザーがGitLabの最新インスタンスを使用していることを確認する機能です。オフライン環境では、GitLabサービスへの接続を試行して失敗することがないように、これらの2つのサービスをオフにすることができます。

詳細については、[Service Pingを有効または無効にする](../../administration/settings/usage_statistics.md#enable-or-disable-service-ping)を参照してください。

### Runnerのバージョン管理を無効にする {#disable-runner-version-management}

Runnerのバージョン管理では、GitLabから最新のRunnerバージョンを取得して、[環境内のどのRunnerが古くなっているかを判断](../../ci/runners/runners_scope.md#determine-which-runners-need-to-be-upgraded)します。オフライン環境では、[Runnerバージョン管理を無効にする](../../administration/settings/continuous_integration.md#control-runner-version-management)必要があります。

### NTPを設定する {#configure-ntp}

Gitalyクラスター（Praefect）は、`pool.ntp.org`にアクセスできることを前提としています。`pool.ntp.org`にアクセスできない場合は、GitalyおよびPraefectサーバーで[呼び出すタイムサーバー設定をカスタマイズ](../../administration/gitaly/praefect/configure.md#customize-time-server-setting)して、アクセス可能なNTPサーバーを使用できるようにします。

オフラインインスタンスでは、[GitLab GeoチェックRakeタスク](../../administration/geo/replication/troubleshooting/common.md#can-geo-detect-the-current-site-correctly)は`pool.ntp.org`を使用するため、常に失敗します。このエラーは無視できますが、[回避する方法の詳細](../../administration/geo/replication/troubleshooting/common.md#message-machine-clock-is-synchronized--exception)をお読みください。

## パッケージメタデータデータベースを有効にする {#enabling-the-package-metadata-database}

[継続的脆弱性スキャン](../../user/application_security/continuous_vulnerability_scanning/_index.md)と[CycloneDXファイルのライセンススキャン](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md)を有効にするには、パッケージメタデータデータベースを有効にする必要があります。このプロセスでは、[EEライセンス](https://storage.googleapis.com/prod-export-license-bucket-1a6c642fc4de57d4/LICENSE)に基づいてライセンス供与されている、パッケージメタデータデータベースと呼ばれるライセンスやアドバイザリデータを使用する必要があります。パッケージメタデータデータベースの使用に関して、次の点に注意してください。

- 当社は、独自の裁量により、いつでも予告なしに、パッケージメタデータデータベースの全部または一部を変更または中止する場合があります。
- パッケージメタデータデータベースには、サードパーティのWebサイトまたはリソースへのリンクが含まれている場合があります。これらのリンクは便宜上提供しているだけで、当社はこれらのWebサイトまたはリソースからのサードパーティのデータ、コンテンツ、製品、サービス、またはそのようなWebサイトに表示されるリンクについては責任を負いません。
- パッケージメタデータデータベースは、サードパーティが提供する情報に一部基づいており、GitLabは提供されるコンテンツの正確性または完全性について責任を負いません。

パッケージメタデータは、GitLabが保持し、所有する以下のGoogle Cloud Provider（GCP）バケットに保存されます。

- ライセンススキャン - `prod-export-license-bucket-1a6c642fc4de57d4`
- 依存関係スキャン - `prod-export-advisory-bucket-1a6c642fc4de57d4`

### gsutilツールを使用してパッケージメタデータエクスポートをダウンロードする {#using-the-gsutil-tool-to-download-the-package-metadata-exports}

1. [`gsutil`](https://cloud.google.com/storage/docs/gsutil_install)ツールをインストールします。
1. GitLab Railsディレクトリのルートを検索します。

   ```shell
   export GITLAB_RAILS_ROOT_DIR="$(gitlab-rails runner 'puts Rails.root.to_s')"
   echo $GITLAB_RAILS_ROOT_DIR
   ```

1. 同期するデータの種類を設定します。

   ```shell
   # For License Scanning
   export PKG_METADATA_BUCKET=prod-export-license-bucket-1a6c642fc4de57d4
   export DATA_DIR="licenses"

   # For Dependency Scanning
   export PKG_METADATA_BUCKET=prod-export-advisory-bucket-1a6c642fc4de57d4
   export DATA_DIR="advisories"
   ```

1. パッケージメタデータエクスポートをダウンロードします。

   ```shell
   # To download the package metadata exports, an outbound connection to Google Cloud Storage bucket must be allowed.
   mkdir -p "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/$DATA_DIR"
   gsutil -m rsync -r -d gs://$PKG_METADATA_BUCKET "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/$DATA_DIR"

   # Alternatively, if the GitLab instance is not allowed to connect to the Google Cloud Storage bucket, the package metadata
   # exports can be downloaded using a machine with the allowed access, and then copied to the root of the GitLab Rails directory.
   rsync rsync://example_username@gitlab.example.com/package_metadata/$DATA_DIR "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/$DATA_DIR"
   ```

### Google Cloud Storage REST APIを使用してパッケージメタデータエクスポートをダウンロードする {#using-the-google-cloud-storage-rest-api-to-download-the-package-metadata-exports}

パッケージメタデータエクスポートは、Google Cloud Storage APIを使用してダウンロードすることもできます。コンテンツは、[https://storage.googleapis.com/storage/v1/b/prod-export-license-bucket-1a6c642fc4de57d4/o](https://storage.googleapis.com/storage/v1/b/prod-export-license-bucket-1a6c642fc4de57d4/o)および[https://storage.googleapis.com/storage/v1/b/prod-export-advisory-bucket-1a6c642fc4de57d4/o](https://storage.googleapis.com/storage/v1/b/prod-export-advisory-bucket-1a6c642fc4de57d4/o)で利用できます。次に、[cURL](https://curl.se/)と[jq](https://stedolan.github.io/jq/)を使用してこれをダウンロードする方法の例を示します。

```shell
#!/bin/bash

set -euo pipefail

DATA_TYPE=$1

GITLAB_RAILS_ROOT_DIR="$(gitlab-rails runner 'puts Rails.root.to_s')"

if [ "$DATA_TYPE" == "license" ]; then
  PKG_METADATA_DIR="$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses"
elif [ "$DATA_TYPE" == "advisory" ]; then
  PKG_METADATA_DIR="$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/advisories"
else
  echo "Usage: import_script.sh [license|advisory]"
  exit 1
fi

PKG_METADATA_BUCKET="prod-export-$DATA_TYPE-bucket-1a6c642fc4de57d4"
PKG_METADATA_DOWNLOADS_OUTPUT_FILE="/tmp/package_metadata_${DATA_TYPE}_object_links.tsv"

# Download the contents of the bucket
# The script downloads all the objects and creates files with a maximum 1000 objects per file in JSON format.

MAX_RESULTS=1000
TEMP_FILE="out.json"

curl --silent --show-error --request GET "https://storage.googleapis.com/storage/v1/b/$PKG_METADATA_BUCKET/o?maxResults=$MAX_RESULTS" >"$TEMP_FILE"
NEXT_PAGE_TOKEN="$(jq -r '.nextPageToken' $TEMP_FILE)"
jq -r '.items[] | [.name, .mediaLink] | @tsv' "$TEMP_FILE" >"$PKG_METADATA_DOWNLOADS_OUTPUT_FILE"

while [ "$NEXT_PAGE_TOKEN" != "null" ]; do
  curl --silent --show-error --request GET "https://storage.googleapis.com/storage/v1/b/$PKG_METADATA_BUCKET/o?maxResults=$MAX_RESULTS&pageToken=$NEXT_PAGE_TOKEN" >"$TEMP_FILE"
  NEXT_PAGE_TOKEN="$(jq -r '.nextPageToken' $TEMP_FILE)"
  jq -r '.items[] | [.name, .mediaLink] | @tsv' "$TEMP_FILE" >>"$PKG_METADATA_DOWNLOADS_OUTPUT_FILE"
  #use for API rate-limiting
  sleep 1
done

trap 'rm -f "$TEMP_FILE"' EXIT

echo "Fetched $DATA_TYPE export manifest"

# Parse the links and names for the bucket objects and output them into a tsv file

echo -e "Saving package metadata exports to $PKG_METADATA_DIR\n"

# Track how many objects will be downloaded
INDEX=1
TOTAL_OBJECT_COUNT="$(wc -l "$PKG_METADATA_DOWNLOADS_OUTPUT_FILE" | awk '{print $1}')"

# Download the objects
while IFS= read -r line; do
  FILE="$(echo -n "$line" | awk '{print $1}')"
  URL="$(echo -n "$line" | awk '{print $2}')"
  OUTPUT_PATH="$PKG_METADATA_DIR/$FILE"

  echo "Downloading $FILE"

  if [ ! -f "$OUTPUT_PATH" ]; then
    curl --progress-bar --create-dirs --output "$OUTPUT_PATH" --request "GET" "$URL"
  else
    echo "Existing file found"
  fi

  echo -e "$INDEX of $TOTAL_OBJECT_COUNT objects downloaded\n"

  INDEX=$((INDEX + 1))
done <"$PKG_METADATA_DOWNLOADS_OUTPUT_FILE"

echo "All objects saved to $PKG_METADATA_DIR"
```

### 自動同期 {#automatic-synchronization}

GitLabインスタンスは、[定期的](https://gitlab.com/gitlab-org/gitlab/-/blob/63a187d47f6da353ba4514650bbbbeb99c356325/config/initializers/1_settings.rb#L840-842)に`package_metadata`ディレクトリのコンテンツと同期されます。アップストリームの変更に合わせてローカルコピーを自動的に更新するために、定期的に新しいエクスポートをダウンロードするようにcronジョブを追加できます。たとえば、次のcrontabを追加して、30分ごとに実行されるcronジョブを設定できます。

ライセンススキャンの場合:

```plaintext
*/30 * * * * gsutil -m rsync -r -d -y "^v1\/" gs://prod-export-license-bucket-1a6c642fc4de57d4 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses
```

依存関係スキャンの場合:

```plaintext
*/30 * * * * gsutil -m rsync -r -d gs://prod-export-advisory-bucket-1a6c642fc4de57d4 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/advisories
```

### 変更メモ {#change-note}

パッケージメタデータのディレクトリは、16.2のリリースで`vendor/package_metadata_db`から`vendor/package_metadata/licenses`に変更されました。このディレクトリがインスタンスにすでに存在し、依存関係スキャンを追加する必要がある場合は、次の手順を実行する必要があります。

1. ライセンスディレクトリの名前を変更します（`mv vendor/package_metadata_db vendor/package_metadata/licenses`）。
1. `vendor/package_metadata_db`を`vendor/package_metadata/licenses`に変更するために、保存された自動化スクリプトまたはコマンドを更新します。
1. `vendor/package_metadata_db`を`vendor/package_metadata/licenses`に変更するために、cronエントリを更新します。

   ```shell
   sed -i '.bckup' -e 's#vendor/package_metadata_db#vendor/package_metadata/licenses#g' [FILE ...]
   ```

### トラブルシューティング {#troubleshooting}

#### データベースデータが見つからない {#missing-database-data}

ライセンスまたはアドバイザリデータが依存関係リストまたはマージリクエストページにない場合、考えられる原因の1つは、データベースがエクスポートデータと同期していないことです。

`package_metadata`の同期は、cronジョブ（[アドバイザリ同期](https://gitlab.com/gitlab-org/gitlab/-/blob/16-3-stable-ee/config/initializers/1_settings.rb#L864-866)と[ライセンス同期](https://gitlab.com/gitlab-org/gitlab/-/blob/16-3-stable-ee/config/initializers/1_settings.rb#L855-857)）を使用してトリガーされ、[管理者設定](../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)で有効になっているパッケージレジストリタイプのみをインポートします。

`vendor/package_metadata`のファイル構造は、上記で有効になっているパッケージレジストリタイプと一致する必要があります。たとえば、`maven`ライセンスまたはアドバイザリデータを同期するには、Railsディレクトリのパッケージメタデータディレクトリに次の構造が必要です。

- ライセンス: `$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses/v2/maven/**/*.ndjson`。
- アドバイザリ: `$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/advisories/v2/maven/**/*.ndjson`。

正常に実行すると、データベースの`pm_`テーブルのデータが入力されたはずです（[Railsコンソール](../../administration/operations/rails_console.md)を使用して確認してください）。

- ライセンス: `sudo gitlab-rails runner "puts \"Package model has #{PackageMetadata::Package.where(purl_type: 'maven').size} packages\""`
- アドバイザリ: `sudo gitlab-rails runner "puts \"Advisory model has #{PackageMetadata::AffectedPackage.where(purl_type: 'maven').size} packages\""`

さらに、チェックポイントデータは、同期されている特定のパッケージレジストリに存在する必要があります。たとえば、Mavenの場合、同期の実行が成功すると、チェックポイントが作成されているはずです。

- ライセンス: `sudo gitlab-rails runner "puts \"maven data has been synced up to #{PackageMetadata::Checkpoint.where(data_type: 'licenses', purl_type: 'maven')}\""`
- アドバイザリ: `sudo gitlab-rails runner "puts \"maven data has been synced up to #{PackageMetadata::Checkpoint.where(data_type: 'advisories', purl_type: 'maven')}\""`

最後に、[`application_json.log`](../../administration/logs/_index.md#application_jsonlog)ログを調べて、クラスが`PackageMetadata::SyncService`である`DEBUG`メッセージを検索して、同期ジョブが実行され、エラーがないことを確認できます。例: `{"severity":"DEBUG","time":"2023-06-22T16:41:00.825Z","correlation_id":"a6e80150836b4bb317313a3fe6d0bbd6","class":"PackageMetadata::SyncService","message":"Evaluating data for licenses:gcp/prod-export-license-bucket-1a6c642fc4de57d4/v2/pypi/1694703741/0.ndjson"}`。

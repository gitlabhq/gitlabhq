---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: インターネットアクセスがない環境で、GitLab Self-Managedインスタンスをインストール、設定、使用します。
title: オフラインのGitLab Self-Managedインスタンスをインストールする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

これは、GitLab Self-Managedインスタンスを完全にオフラインでインストール、設定、および使用するのに役立つ手順ガイドです。

## インストール {#installation}

> [!note]
> このガイドでは、サーバーがUbuntu 20.04であり、[Linuxパッケージインストール方法](../../install/package/_index.md)を使用していて、GitLab Enterprise Editionを実行していることを前提としています。他のサーバーの手順は異なる場合があります。このガイドでは、サーバーホストが`my-host.internal`として解決されることも前提としています。そのためには、サーバーのFQDNに置き換える必要があり、必要なパッケージファイルをダウンロードするために、インターネットアクセスの可能な別のサーバーへのアクセスが必要となります。

<i class="fa-youtube-play" aria-hidden="true"></i>このプロセスのビデオチュートリアルは、[オフラインGitLabインストール: ダウンロードとインストール](https://www.youtube.com/watch?v=TJaq4ua2Prw)を参照してください。

### GitLabパッケージをダウンロードする {#download-the-gitlab-package}

インターネットにアクセスできる同じオペレーティングシステムタイプのサーバーを使用して、[GitLabパッケージ](../../update/package/_index.md#upgrade-with-a-downloaded-package)と関連する依存関係をダウンロードする必要があります。

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

前提条件: 

- オフライン環境にGitLabパッケージをインストールする前に、必要なすべての依存関係が最初にインストールされていることを確認してください。

Ubuntuを使用している場合は、`dpkg`でコピーした依存関係`.deb`パッケージをインストールできます。GitLabパッケージはまだインストールしないでください。

```shell
# Go to the physical media device
sudo cd /path/to/mount

# Install the dependency packages
sudo dpkg -i <package_name>.deb
```

[オペレーティングシステムに関連するコマンドを使用してパッケージをインストール](../../update/package/_index.md#upgrade-with-a-downloaded-package)しますが、`EXTERNAL_URL`インストール手順の`http` URLを指定してください。インストールが完了したら、SSLを手動で設定できます。

サーバーのIPアドレスにバインドするのではなく、IP解決用のドメインを設定する必要があります。ドメインは、証明書のコモンネーム（CN）に対して安定したターゲットを提供し、長期的な解決を簡素化します。

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

1. インスタンスを再設定して、変更を適用します:

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

1. インスタンスを再設定して、変更を適用します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## DockerデーモンがレジストリとGitLab Runnerを信頼できるように設定する {#allow-the-docker-daemon-to-trust-the-registry-and-gitlab-runner}

[レジストリで信頼できる証明書を使用するための手順に従って](../../administration/packages/container_registry.md#configure-self-signed-certificates)、証明書をDockerデーモンに提供します。

```shell
sudo mkdir -p /etc/docker/certs.d/my-host.internal:5000

sudo cp /etc/gitlab/ssl/my-host.internal.crt /etc/docker/certs.d/my-host.internal:5000/ca.crt
```

[Runnerで信頼できる証明書を使用するための手順に従って](https://docs.gitlab.com/runner/install/docker/#installing-trusted-ssl-server-certificates)、証明書をGitLab Runner（次にインストール）に提供します。

```shell
sudo mkdir -p /etc/gitlab-runner/certs

sudo cp /etc/gitlab/ssl/my-host.internal.crt /etc/gitlab-runner/certs/ca.crt
```

## GitLab Runnerを有効にする {#enabling-gitlab-runner}

[DockerサービスとしてGitLab Runnerをインストールする手順と同様のプロセスに従って](https://docs.gitlab.com/runner/install/docker/#install-the-docker-image-and-start-the-container)、まずRunnerを登録する必要があります:

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

次に、Runnerにいくつかの追加設定を加える必要があります。

`/etc/gitlab-runner/config.toml`に次の変更を加えます。

- Dockerソケットをボリューム`volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]`に追加
- `pull_policy = "if-not-present"`をexecutorの設定に追加

これでRunnerを起動できます:

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

Gitaly Cluster (Praefect)は、`pool.ntp.org`にアクセスできることを前提としています。`pool.ntp.org`にアクセスできない場合は、GitalyおよびPraefectサーバーで[呼び出すタイムサーバー設定をカスタマイズ](../../administration/gitaly/praefect/configure.md#customize-time-server-setting)して、アクセス可能なNTPサーバーを使用できるようにします。

オフラインインスタンスでは、[GitLab GeoチェックRakeタスク](../../administration/geo/replication/troubleshooting/common.md#can-geo-detect-the-current-site-correctly)は`pool.ntp.org`を使用するため、常に失敗します。このエラーは無視できますが、[回避する方法の詳細](../../administration/geo/replication/troubleshooting/common.md#message-machine-clock-is-synchronized--exception)をお読みください。

## パッケージメタデータデータベースを有効にする {#enabling-the-package-metadata-database}

Package Metadata Databaseを有効にすると、[継続的脆弱性スキャン](../../user/application_security/continuous_vulnerability_scanning/_index.md)と[CycloneDXファイルのライセンススキャン](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md)を有効にできます。このプロセスでは、[EEライセンス](https://storage.googleapis.com/prod-export-license-bucket-1a6c642fc4de57d4/LICENSE)に基づいてライセンス供与されている、パッケージメタデータデータベースと呼ばれるライセンスやアドバイザリデータを使用する必要があります。パッケージメタデータデータベースの使用に関して、次の点に注意してください。

- 当社は、独自の裁量により、いつでも予告なしに、パッケージメタデータデータベースの全部または一部を変更または中止する場合があります。
- パッケージメタデータデータベースには、サードパーティのWebサイトまたはリソースへのリンクが含まれている場合があります。これらのリンクは便宜上提供しているだけで、当社はこれらのWebサイトまたはリソースからのサードパーティのデータ、コンテンツ、製品、サービス、またはそのようなWebサイトに表示されるリンクについては責任を負いません。
- パッケージメタデータデータベースは、サードパーティが提供する情報に一部基づいており、GitLabは提供されるコンテンツの正確性または完全性について責任を負いません。

パッケージメタデータは2つの形式バージョン（v2とv3）で公開されており、各データセットはそのいずれかを使用します:

| 形式バージョン | データセット            | 読み取り元                 | ダウンロード元                        |
|----------------|--------------------|-------------------------|----------------------------------------|
| v2             | ライセンス           | GitLab 19.3以前 | パブリックGCPバケット                      |
| v2             | アドバイザリ         | すべてのGitLabバージョン     | パブリックGCPバケット                      |
| v2             | CVEエンリッチメント     | すべてのGitLabバージョン     | パブリックGCPバケット                      |
| v3             | ライセンス           | GitLab 19.4以降   | Package Metadata Database配布サービス |
| v3             | マルウェアアドバイザリ | GitLab 19.3以降   | Package Metadata Database配布サービス |

2つの形式バージョンは異なるデータを保持し、ダウンロード方法も異なるため、それぞれに独自の手順があります。ライセンスのレイアウトの詳細については、[v3ライセンスデータ形式バージョン](#v3-license-data-format-version)を参照してください。

v2データは、GitLabが管理所有し、認証情報なしで読み取り可能な以下のGoogle Cloud Provider（GCP）バケットに保存されています:

- ライセンススキャン: `prod-export-license-bucket-1a6c642fc4de57d4`
- 依存関係スキャン: `prod-export-advisory-bucket-1a6c642fc4de57d4`
- CVEエンリッチメント: `prod-export-cve-enrichment-bucket-1a6c642fc4de57d4`

v3データにはパブリックバケットがありません。これは認証されたGitLabサービスによって配布されるため、ダウンロードにはライセンスキーが必要です。[v3 Package Metadata Databaseデータのダウンロード](#download-v3-package-metadata-database-data)を参照してください。

CVEエンリッチメントには、脆弱性に表示される[EPSSスコアとKEVステータス](../../user/application_security/vulnerabilities/risk_assessment_data.md)が含まれています。ライセンスとアドバイザリのバケットのみを同期するインスタンスには、依存関係スキャンとライセンスデータはありますが、リスク評価データはありません。

> [!note]
> すべてのデータセットについて、GitLabは`vendor/package_metadata`の下のディレクトリが存在する場合は常にそれを読み取り、データ自体のダウンロードよりもそれを優先します。存在するディレクトリは常に優先され、バケットや配布サービスへのフォールバックはありません。古いデータを保持するディレクトリは、したがって古いデータを提供し、エラーは報告されません。[マルウェアアドバイザリ](#confirm-gitlab-detects-the-offline-directory)も同じルールに従います。

### 最初の読み込みの前に {#before-the-first-load}

何かをダウンロードする前に、同期するパッケージレジストリのタイプを決定してください。[管理者設定](../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)で有効にされているタイプのみがインポートされます。無効にしたタイプをダウンロードすると、時間とディスク容量が消費されますが、データベースには何も届きません。

同期ジョブのスロットルはインポート速度を設定するものであり、インスタンスのリソースではないため、大規模なインスタンスでもインポートが速くなることはありません。各実行は一定時間後に停止し、次回の実行時にチェックポイントから再開します。すべてのレジストリタイプを有効にした最初の読み込みには、約1日かかることがあります。それを短縮するには、有効にするタイプを絞り込んでください。

### v2: gsutilツールを使用してパッケージメタデータエクスポートをダウンロードする {#v2-using-the-gsutil-tool-to-download-the-package-metadata-exports}

このセクションでは、v2データのダウンロード方法について説明します。

1. [`gsutil`](https://docs.cloud.google.com/storage/docs/gsutil_install)ツールをインストールします。
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

   # For dependency scanning
   export PKG_METADATA_BUCKET=prod-export-advisory-bucket-1a6c642fc4de57d4
   export DATA_DIR="advisories"

   # For CVE enrichment
   export PKG_METADATA_BUCKET=prod-export-cve-enrichment-bucket-1a6c642fc4de57d4
   export DATA_DIR="cve_enrichment"
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

1. GitLab 19.4以前のCVEエンリッチメントでは、ダウンロードしたファイルをディレクトリ階層1つ上に移動してください。GitLab 19.5以降では、この手順をスキップしてください。詳細については、[マージリクエスト253401](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253401)を参照してください。

   ライセンスおよびアドバイザリバケットは、`v2/`の下にパッケージレジストリごとに1つのディレクトリを保持しており、GitLabはそれらをそのままコピーして読み取ります。CVEエンリッチメントにはパッケージレジストリがなく、そのバケットはその位置に単一の`cve_enrichment`ディレクトリを保持しています。GitLab 19.4以前では、GitLabはCVEエンリッチメントを`cve_enrichment/v2/<sequence>/<chunk>.ndjson`からのみ、その正確な深さで読み取ります。そのままコピーすると、ファイルが1ディレクトリ階層分深くなりすぎます。その結果、GitLabは何もインポートせず、何もログに記録しません。

   ```shell
   cd "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/cve_enrichment/v2"
   cp -a cve_enrichment/. . && rm -r cve_enrichment
   ```

   CVEエンリッチメントエクスポートをダウンロードするたびに、この手順を繰り返してください。`cp -a`は、すでに存在するシーケンスディレクトリに新しいファイルをマージしますが、`mv`では停止してしまいます。

### v2: Google Cloud Storage REST APIを使用してパッケージメタデータエクスポートをダウンロードする {#v2-using-the-google-cloud-storage-rest-api-to-download-the-package-metadata-exports}

このセクションでは、v2パッケージメタデータをダウンロードする別の方法について説明します。

パッケージメタデータエクスポートは、Google Cloud Storage APIを使用してダウンロードすることもできます。コンテンツは<https://storage.googleapis.com/storage/v1/b/prod-export-license-bucket-1a6c642fc4de57d4/o>および<https://storage.googleapis.com/storage/v1/b/prod-export-advisory-bucket-1a6c642fc4de57d4/o>で入手できます。次に、[cURL](https://curl.se/)と[jq](https://stedolan.github.io/jq/)を使用してこれをダウンロードする方法の例を示します。

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

### v3 Package Metadata Databaseデータのダウンロード {#download-v3-package-metadata-database-data}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

前述の`gsutil`手順でパブリックバケットからミラーリングされるv2のライセンスおよびアドバイザリエクスポートとは異なり、v3のライセンスおよびマルウェアアドバイザリは認証されたGitLabサービスであるPackage Metadata Database配布サービス（PDS）によって配布されるため、オフラインインスタンスはどちらも単独でダウンロードできません。代わりに、インターネットアクセスのあるマシンでデータをダウンロードし、オフラインインスタンスにコピーします。スクリプトはデータセットを最初の引数として受け取り、それ以外は両方で同じです。2つのデータセットの違いは、読み取り元の配布サービスのパスと、コピー先のベンダーディレクトリのみです。

スクリプトは、オンラインインスタンスが同期するのと同じアーカイブを配布サービスに要求し、すべてのアーカイブがダウンロードされた後にのみ各レジストリのチェックポイントを書き込みます。ライセンスキーを3日間有効なトークンと交換します。インターネットアクセスのあるマシンにはライセンスファイルのコピーが必要ですが、オフラインインスタンスへのアクセスは不要です。

前提条件: 

- 管理者アクセス権。
- オフラインライセンス。レガシーライセンスファイルは機能しません: トークンリクエストは`Invalid cloud license`で失敗し、スクリプトは停止します。**管理者**エリアのダッシュボードには、**ライセンスの概要**の下にライセンスタイプが表示されます。
- インターネットアクセスのあるマシンでは、cURL、jq 1.6以降、および`customers.gitlab.com`、`pmdb-dist-svc.runway.gitlab.net`、`storage.googleapis.com`への送信アクセスが必要です。配布サービスは`gitlab.net`ドメインにあるため、`gitlab.com`に限定された許可リストではアクセスできません。
- オフラインインスタンスでは、rsyncが必要です。

オフラインライセンスを取得するには、承認が必要な[クラウドライセンスのオプトアウト例外](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#offline-cloud-licensing)を受ける必要があります。詳細については、GitLabの営業担当者にお問い合わせください。すでにオフラインライセンスをお持ちの場合は、[カスタマーポータル](https://customers.gitlab.com)からファイルを再度ダウンロードできます。

スクリプトにはライセンスキーが必要です。これは、ライセンスファイルが保持する長いテキストブロックです。それをファイルに書き込むには、オフラインインスタンスで以下を実行します:

```shell
sudo gitlab-rails runner 'puts License.current.data' > Gitlab.gitlab-license
```

アクティベーションコードはライセンスキーではありません。アクティベーションコードは短い文字列であり、トークンリクエストはそれを拒否します。

これらの手順はLinuxパッケージインストールに適用されます。Kubernetesインストールでは、データはSidekiqポッドが読み取るボリューム上になければなりません。これは[イシュー561085](https://gitlab.com/gitlab-org/gitlab/-/issues/561085)で追跡されています。

> [!warning]
> Dockerインストールでは、Railsディレクトリはマウントされたボリューム上にありません。データをコピーする前に`vendor/package_metadata`をバインドマウントしてください。そうしないと、コンテナをアップグレードしたときに失われます。

以下のスクリプトを`download_pmdb_data.sh`として保存し、`chmod +x download_pmdb_data.sh`で実行可能にします。

```shell
#!/bin/bash

set -euo pipefail

CDOT_URL="${CDOT_URL:-https://customers.gitlab.com}"
PDS_URL="${PDS_URL:-https://pmdb-dist-svc.runway.gitlab.net}"

# A registry far enough behind is cheaper to replace with a fresh snapshot than
# to catch up one delta at a time. Set to 0 to never download a delta.
MAX_DELTAS="${MAX_DELTAS:-100}"

if [ $# -lt 5 ]; then
  echo "Usage: download_pmdb_data.sh <license_file> <gitlab_version> <dataset> <output_dir> <registry>"
  echo "dataset is licenses or malware_advisories."
  echo "Pass the package registries to download separated by space, or 'all' for every supported registry."
  exit 1
fi

LICENSE_FILE=$1
GITLAB_VERSION=$2
DATASET=$3
OUTPUT_DIR=$4
shift 4
REQUESTED_REGISTRIES="$*"

# The two datasets differ only in their distribution service path and the name
# used in the closing message. Everything after this point is common to both.
case "$DATASET" in
licenses)
  DATASET_PATH="licenses"
  DATASET_LABEL="License data"
  ;;
malware_advisories)
  DATASET_PATH="malware/advisories"
  DATASET_LABEL="Advisories"
  ;;
*)
  echo "dataset must be licenses or malware_advisories"
  exit 1
  ;;
esac

if [ -z "$OUTPUT_DIR" ]; then
  echo "output_dir must not be empty"
  exit 1
fi

if [ ! -r "$LICENSE_FILE" ]; then
  echo "Cannot read $LICENSE_FILE"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Serialize runs against this output directory. Two concurrent runs would race
# on the same dataset directory: one can write checkpoint.json while the other
# has deleted and re-created the directory, leaving a partial shard set that
# GitLab imports as a complete snapshot. mkdir either creates the directory or
# fails, in one step, so it needs nothing beyond the shell.
LOCK_DIR="$OUTPUT_DIR/.download.lock"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "Another download is already running for $OUTPUT_DIR"
  echo "If no other run is active, remove $LOCK_DIR and try again."
  exit 1
fi

REQUEST_FILE="$(mktemp)"
RESPONSE_FILE="$(mktemp)"
SNAPSHOT_FILE="$(mktemp)"
SHARDS_FILE="$(mktemp)"
DELTAS_FILE="$(mktemp)"
HEADER_FILE="$(mktemp)"
trap 'rm -f "$REQUEST_FILE" "$RESPONSE_FILE" "$SNAPSHOT_FILE" "$SHARDS_FILE" "$DELTAS_FILE" "$HEADER_FILE"; rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
chmod 600 "$HEADER_FILE"

# Exchange the license key for a Cloud Connector token.
GRAPHQL_QUERY='query($licenseKey: String!, $gitlabVersion: String!) {
  cloudConnectorAccess(licenseKey: $licenseKey, gitlabVersion: $gitlabVersion) {
    serviceToken { token }
  }
}'

jq --null-input --arg query "$GRAPHQL_QUERY" --rawfile licenseKey "$LICENSE_FILE" \
  --arg gitlabVersion "$GITLAB_VERSION" \
  '{query: $query, variables: {licenseKey: $licenseKey, gitlabVersion: $gitlabVersion}}' >"$REQUEST_FILE"

HTTP_STATUS="$(curl --silent --show-error --request POST "$CDOT_URL/graphql" \
  --header 'Content-Type: application/json' --data @"$REQUEST_FILE" \
  --output "$RESPONSE_FILE" --write-out '%{http_code}')"

if [ "$HTTP_STATUS" != "200" ]; then
  echo "Token request to $CDOT_URL failed with HTTP $HTTP_STATUS"
  head -c 500 "$RESPONSE_FILE"
  exit 1
fi

TOKEN="$(jq --raw-output '.data.cloudConnectorAccess.serviceToken.token // empty' "$RESPONSE_FILE")"

if [ -z "$TOKEN" ]; then
  echo "$CDOT_URL refused to issue a token for $LICENSE_FILE"
  echo "It must hold the license key, the output of: gitlab-rails runner 'puts License.current.data'"
  echo "An activation code is not a license key, and a legacy license is not accepted."
  echo "The customer portal reported:"
  jq --raw-output '.errors[]?.message // "no reason given"' "$RESPONSE_FILE"
  exit 1
fi

# The distribution service requires X-Gitlab-Instance-Id to equal the token's
# subject claim and X-Gitlab-Realm to equal its realm claim. Both are in the
# payload, which is the second dot-separated segment of the token.
CLAIMS="$(printf '%s' "$TOKEN" |
  jq --raw-input 'split(".")[1] | gsub("-"; "+") | gsub("_"; "/") | @base64d | fromjson')"

INSTANCE_ID="$(jq --raw-output '.sub // empty' <<<"$CLAIMS")"
REALM="$(jq --raw-output '.gitlab_realm // empty' <<<"$CLAIMS")"

if [ -z "$INSTANCE_ID" ] || [ -z "$REALM" ]; then
  echo "The token is missing its subject or realm claim"
  exit 1
fi

# Pass the headers through a file so the token never appears in a process
# list. It is readable there by any local user for the download's duration.
{
  printf 'header = "Authorization: Bearer %s"\n' "$TOKEN"
  printf 'header = "X-Gitlab-Instance-Id: %s"\n' "$INSTANCE_ID"
  printf 'header = "X-Gitlab-Realm: %s"\n' "$REALM"
} >"$HEADER_FILE"

# Writes the response body to $2 and returns the HTTP status.
pds_request() {
  curl --silent --show-error --config "$HEADER_FILE" \
    --output "$2" --write-out '%{http_code}' "$1"
}

HTTP_STATUS="$(pds_request "$PDS_URL/v1/$DATASET_PATH/supported" "$RESPONSE_FILE")"

if [ "$HTTP_STATUS" != "200" ]; then
  echo "Request for the supported package registries failed with HTTP $HTTP_STATUS"
  head -c 500 "$RESPONSE_FILE"
  exit 1
fi

SUPPORTED="$(jq --raw-output '.registries[]' "$RESPONSE_FILE")"
SKIPPED=""

if [ -z "$SUPPORTED" ]; then
  echo "No package registries are available"
  exit 1
fi

echo "Available package registries: $(echo "$SUPPORTED" | tr '\n' ' ')"

# Disable filename expansion so a registry name is never treated as a glob.
set -f

if [ "$REQUESTED_REGISTRIES" = "all" ]; then
  REGISTRIES="$SUPPORTED"
else
  REGISTRIES="$REQUESTED_REGISTRIES"

  for REGISTRY in $REGISTRIES; do
    if ! grep --quiet --fixed-strings --line-regexp "$REGISTRY" <<<"$SUPPORTED"; then
      echo "$REGISTRY is not a supported package registry"
      exit 1
    fi
  done
fi

# Downloads the current snapshot into a registry's full_dataset directory, and
# removes any delta archives beside it: a snapshot supersedes every delta older
# than itself, and GitLab reads whatever is newer than its own checkpoint, so
# leaving them would re-apply changes the snapshot already contains.
download_snapshot() {
  REGISTRY=$1
  UNTIL=$2
  DATASET_DIR="$OUTPUT_DIR/v3/$REGISTRY/full_dataset"

  # Remove any previous snapshot. GitLab reads every archive in this directory,
  # so archives left over from an earlier snapshot would be imported alongside
  # the new ones, restoring data that changed since.
  rm -rf "$DATASET_DIR" "$OUTPUT_DIR/v3/$REGISTRY/deltas"
  mkdir -p "$DATASET_DIR"

  # Read the shards from the saved /all body. The delta loop reuses
  # $RESPONSE_FILE, so by the time a fallback lands here it no longer holds it.
  jq --raw-output '.shards[] | [.shard, (.signed_url // .url)] | @tsv' "$SNAPSHOT_FILE" >"$SHARDS_FILE"
  SHARD_COUNT="$(wc -l <"$SHARDS_FILE" | tr -d ' ')"

  while IFS=$'\t' read -r SHARD URL; do
    echo "Downloading $REGISTRY snapshot archive $SHARD"
    curl --fail --silent --show-error --location --output "$DATASET_DIR/$SHARD.tar.zst.part" "$URL"
    mv "$DATASET_DIR/$SHARD.tar.zst.part" "$DATASET_DIR/$SHARD.tar.zst"
  done <"$SHARDS_FILE"

  # Write the checkpoint last. GitLab ignores a directory that has no
  # checkpoint, so an interrupted download is never imported as a snapshot.
  jq --null-input --argjson until "$UNTIL" --argjson shards "$SHARD_COUNT" \
    '{until: $until, shards: $shards}' >"$DATASET_DIR/checkpoint.json"
}

for REGISTRY in $REGISTRIES; do
  HTTP_STATUS="$(pds_request "$PDS_URL/v1/$DATASET_PATH/all?purl_type=$REGISTRY" "$RESPONSE_FILE")"

  # A pending snapshot is the only skippable outcome. Every other 503 is
  # transient, and treating it as "no data" would delete a registry that the
  # instance already has.
  if [ "$HTTP_STATUS" = "503" ]; then
    # A 503 from in front of the service has no JSON body, so keep the reason
    # empty rather than letting jq abort the script.
    REASON="$(jq --raw-output '.reason // empty' "$RESPONSE_FILE" 2>/dev/null || true)"

    if [ "$REASON" = "snapshot_not_yet_published" ]; then
      echo "Skipping $REGISTRY, no snapshot is published yet"
      SKIPPED="$SKIPPED $REGISTRY"
      continue
    fi

    echo "Request for $REGISTRY failed with HTTP 503, try again later ($REASON)"
    exit 1
  fi

  if [ "$HTTP_STATUS" != "200" ]; then
    echo "Request for $REGISTRY failed with HTTP $HTTP_STATUS"
    head -c 500 "$RESPONSE_FILE"
    exit 1
  fi

  # Keep the /all body: the snapshot is the fallback for every branch below,
  # and the delta loop writes over $RESPONSE_FILE before one can be taken.
  cp "$RESPONSE_FILE" "$SNAPSHOT_FILE"

  UNTIL="$(jq --raw-output '.until // empty' "$SNAPSHOT_FILE")"

  if [ -z "$UNTIL" ]; then
    echo "The response for $REGISTRY has no snapshot timestamp"
    exit 1
  fi

  REGISTRY_DIR="$OUTPUT_DIR/v3/$REGISTRY"
  LOCAL_UNTIL="$(jq --raw-output '.until // empty' \
    "$REGISTRY_DIR/full_dataset/checkpoint.json" 2>/dev/null || true)"

  # Take the whole snapshot unless the output directory already holds one this
  # run can continue from. A delta cannot bootstrap a registry, and `since` has
  # to be a 10-digit unix-seconds value or the service answers 400, so a
  # checkpoint that is missing, unreadable or in another unit starts over.
  if ! [[ "$LOCAL_UNTIL" =~ ^[0-9]{10}$ ]]; then
    download_snapshot "$REGISTRY" "$UNTIL"
    continue
  fi

  # Resume from the newest archive on disk, snapshot or delta, which is where
  # GitLab's own checkpoint ends up once it has imported them. Asking from an
  # older timestamp would download deltas that are already here. Names that are
  # not a bare timestamp are ignored, matching what the connector reads.
  SINCE="$(find "$REGISTRY_DIR/deltas" -type f -name '*.tar.zst' 2>/dev/null |
    sed -e 's#.*/##' -e 's#\.tar\.zst$##' | grep -E '^[0-9]{10}$' |
    sort -n | tail -1 || true)"

  if [ -z "$SINCE" ] || [ "$LOCAL_UNTIL" -gt "$SINCE" ]; then
    SINCE="$LOCAL_UNTIL"
  fi

  # With deltas disabled, the published snapshot decides everything.
  if [ "$MAX_DELTAS" -le 0 ]; then
    if [ "$UNTIL" -gt "$LOCAL_UNTIL" ]; then
      echo "Replacing $REGISTRY, the published snapshot moved to $UNTIL"
      download_snapshot "$REGISTRY" "$UNTIL"
    else
      echo "Skipping $REGISTRY, snapshot $LOCAL_UNTIL is already downloaded"
    fi
    continue
  fi

  # Page forward. The service caps a response at 20 archives per registry and
  # sends the oldest of the backlog first, so re-asking from the newest archive
  # received walks the whole backlog without gaps.
  : >"$DELTAS_FILE"
  DELTA_TOTAL=0
  CAPPED=""

  while :; do
    HTTP_STATUS="$(pds_request "$PDS_URL/v1/$DATASET_PATH/delta?since=$REGISTRY:$SINCE" "$RESPONSE_FILE")"

    if [ "$HTTP_STATUS" != "200" ]; then
      echo "Delta request for $REGISTRY failed with HTTP $HTTP_STATUS"
      head -c 500 "$RESPONSE_FILE"
      exit 1
    fi

    # Registries are keyed by the identifier /supported gave us, and one that is
    # up to date comes back as an empty array rather than being left out.
    PAGE_COUNT="$(jq --arg r "$REGISTRY" '.purl_types[$r] // [] | length' "$RESPONSE_FILE")"

    if [ "$PAGE_COUNT" -eq 0 ]; then
      break
    fi

    jq --raw-output --arg r "$REGISTRY" \
      '.purl_types[$r] | sort_by(.delta | tonumber) | .[] | [.delta, (.signed_url // .url)] | @tsv' \
      "$RESPONSE_FILE" >>"$DELTAS_FILE"

    DELTA_TOTAL=$((DELTA_TOTAL + PAGE_COUNT))
    SINCE="$(cut -f1 "$DELTAS_FILE" | tail -1)"

    # Past the ceiling, one snapshot is fewer bytes than the rest of the backlog.
    if [ "$DELTA_TOTAL" -gt "$MAX_DELTAS" ]; then
      CAPPED=yes
      break
    fi
  done

  if [ -n "$CAPPED" ]; then
    echo "Replacing $REGISTRY, it is more than $MAX_DELTAS deltas behind"
    download_snapshot "$REGISTRY" "$UNTIL"
    continue
  fi

  if [ "$DELTA_TOTAL" -eq 0 ]; then
    echo "Skipping $REGISTRY, it is up to date at $SINCE"
    continue
  fi

  # Deltas sit beside the snapshot rather than replacing it: GitLab reads the
  # snapshot on a first sync and the deltas on every sync after it.
  mkdir -p "$REGISTRY_DIR/deltas"

  while IFS=$'\t' read -r DELTA URL; do
    echo "Downloading $REGISTRY delta $DELTA"
    curl --fail --silent --show-error --location \
      --output "$REGISTRY_DIR/deltas/$DELTA.tar.zst.part" "$URL"
    mv "$REGISTRY_DIR/deltas/$DELTA.tar.zst.part" "$REGISTRY_DIR/deltas/$DELTA.tar.zst"
  done <"$DELTAS_FILE"

  echo "Downloaded $DELTA_TOTAL delta(s) for $REGISTRY"
done

set +f

if [ -n "$SKIPPED" ]; then
  echo "Warning: no snapshot is published yet for:$SKIPPED"
  echo "The downloaded registries are complete and safe to copy. Run the script again later to pick up the rest."
fi

echo "$DATASET_LABEL saved to $OUTPUT_DIR"
```

スクリプトは次のように呼び出します:

```shell
./download_pmdb_data.sh <license_file> <gitlab_version> <dataset> <output_dir> <registry>
```

以下の表は、スクリプトの各フラグが表すものを説明しています:

| 引数         | 説明 |
|------------------|-------------|
| `license_file`   | インスタンスのライセンスキーを保持するファイルへのパス。これは`sudo gitlab-rails runner 'puts License.current.data'`の出力です。アクティベーションコードはライセンスキーではありません。 |
| `gitlab_version` | データをインポートするGitLabインスタンスのバージョン。これは`sudo gitlab-rails runner 'puts Gitlab::VERSION'`の出力です。例: `19.4.0-ee`。 |
| `dataset`        | `licenses`または`malware_advisories`。 |
| `output_dir`     | 書き込み先のディレクトリ。存在しない場合は作成されます。毎回の実行で同じディレクトリを使用することで、変更されていないスナップショットはスキップされます。 |
| `registry`   | 1つ以上のパッケージレジストリ（例: `npm`や`pypi`）、またはサポートされているすべてのレジストリに対しては`all`を指定します。[管理者設定](../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)で有効になっているタイプのレジストリを渡します。複数のレジストリはスペースで区切る必要があります。スクリプトは、何かをダウンロードする前にサポートされているリストを表示します。 |

スクリプトは、パッケージタイプではなくレジストリ識別子にちなんで名付けられた、パッケージレジストリごとに1つのディレクトリを作成します。例:

```plaintext
licenses/
└── v3/
    └── npm/
        ├── full_dataset/
        │   ├── 00.tar.zst
        │   ├── 01.tar.zst
        │   ├── ...
        │   ├── 7f.tar.zst
        │   └── checkpoint.json
        └── deltas/
            ├── 1757520000.tar.zst
            └── 1757606400.tar.zst
```

各スナップショットアーカイブは、その16進数シャード識別子にちなんで名付けられます。レジストリごとのアーカイブ数はサービスによって設定され、データを含まないアーカイブが存在することもあります。各デルタアーカイブは、そのウィンドウを終了するUnixタイムスタンプにちなんで名付けられます。GitLabがこれらのフォルダーから読み取る内容については、[v3ライセンスデータ形式バージョン](#v3-license-data-format-version)を参照してください。

レジストリの最初の実行では、スナップショット全体をダウンロードし、それ以降の実行では、出力ディレクトリ内の最新のアーカイブ以降にサービスが公開したものだけを要求します。

> [!note]
> 毎回の実行で同じ出力ディレクトリを再利用してください。そうしないと、スクリプトは再開するものがなく、スナップショット全体を再度ダウンロードします。

レジストリが`MAX_DELTAS`アーカイブ以上遅れている場合、スクリプトはスナップショットを置き換え、その横の`deltas/`フォルダーを削除します。サービスは独自のスケジュールで再構築するため、隣にあるデルタよりも新しいスナップショットが存在することは想定内であり、スクリプトはそのスナップショットを再ダウンロードするのではなく、デルタを読み続けます。`MAX_DELTAS`のデフォルトは100で、サービスは1リクエストあたり最大20のデルタアーカイブを提供します。デルタを絶対にダウンロードしないようにするには、`0`に設定します。これにより、毎回の実行でスナップショットを置き換えていた以前の動作が復元されます。

スクリプトは出力ディレクトリにロックも作成するため、最初のパスがまだデータを書き込んでいる間に再度実行すると、ディレクトリを破損させるのではなく終了します。出力ディレクトリがすでに保持しているものより新しいものがない場合、スクリプトはそのレジストリをスキップするため、スケジュールで実行しても安全です。

各データセットを独自のセクションの手順に従って配置します: [ライセンスデータ](#download-v3-license-data)および[マルウェアアドバイザリ](#download-gitlab-v3-malware-advisories)。

### GitLab v3マルウェアアドバイザリのダウンロード {#download-gitlab-v3-malware-advisories}

{{< details >}}

- プラン: Ultimate
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.3で`sync_malware_advisories`および`ingest_malware_advisories`という名前の[フラグ付きで](../../administration/feature_flags/_index.md) [導入されました](https://gitlab.com/groups/gitlab-org/-/epics/20876)。デフォルトでは有効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。Ultimateに加えて、この機能は依存関係ファイアウォールアドオンを持つPremium顧客も利用できます。

[GitLabマルウェアアドバイザリ](../../user/application_security/gitlab_advisory_database/_index.md#gitlab-malware-advisories)は、パッケージレジストリで見つかった既知の悪意のあるパッケージを対象としています。これらはPackage Metadata Database配布サービスによって配布されるため、インターネットアクセスのあるマシンでダウンロードし、オフラインインスタンスにコピーします。[v3 Package Metadata Databaseデータのダウンロード](#download-v3-package-metadata-database-data)に記載されている共有スクリプトとその前提条件を使用してダウンロードします:

```shell
./download_pmdb_data.sh ./Gitlab.gitlab-license 19.3.0-ee malware_advisories ./malware_advisories npm pypi
```

アドバイザリをオフラインインスタンスにコピーするには:

1. 出力ディレクトリをオフラインインスタンスに転送します。

1. オフラインインスタンスで、GitLab Railsディレクトリのルートを見つけ、アドバイザリを所定の場所にコピーして権限を更新します。

   ```shell
   export GITLAB_RAILS_ROOT_DIR="$(sudo gitlab-rails runner 'puts Rails.root.to_s')"
   echo $GITLAB_RAILS_ROOT_DIR
   sudo mkdir -p "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/malware_advisories"
   sudo rsync --recursive --delete ./malware_advisories/ "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/malware_advisories/"
   sudo chmod -R 755 "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/"
   ```

`PackageMetadata::MalwareAdvisoriesSyncWorker` cronジョブは5分ごとに実行され、次回の実行時にアドバイザリをインポートします。GitLab Self-Managedでは、負荷をインスタンス間で分散するために最大5分のオフセットがジョブに追加されるため、ファイルをコピーしてからインポートが開始されるまで最大10分かかることがあります。[管理者設定](../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)で有効にされているパッケージレジストリタイプのみがインポートされるため、インスタンスは決してインポートしないレジストリのデータを保持することがあります。

アドバイザリを更新するには、この手順を繰り返してください。以前のスナップショットのアーカイブが新しいものと一緒にインポートされないように、`rsync --delete`が必要です。毎回の実行で同じ出力ディレクトリを再利用してください: `rsync --delete`は、スナップショットがまだ公開されていないためスキップされたレジストリを含め、そこに存在しないレジストリを削除します。

### v3ライセンスデータのダウンロード {#download-v3-license-data}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

{{< history >}}

- GitLab 19.4で`sync_v3_license_expressions`という名前のフラグを付けて[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/22880)。デフォルトでは有効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。
>
> フラグをオフにすると、インスタンスはv2レイアウトにフォールバックし、v3のチェックポイントを破棄します。フラグを再度オンにすると、インスタンスは最後に同期されたスナップショットから再開するのではなく、最初からv3データを再インポートします。

v3ライセンスデータのレイアウトは、単一のライセンス識別子ではなく、Software Package Data Exchange（SPDX）ライセンス式を保持します。例: `MIT OR Apache-2.0`。

Package Metadata Database配布サービスがv3ライセンスデータを配布するため、インターネットアクセスのあるマシンでダウンロードし、オフラインインスタンスにコピーします。ライセンスバケットが保持するすべての形式ではなく、有効にしたレジストリが必要とするものだけをダウンロードします。`gsutil`は必要ありません。[v3 Package Metadata Databaseデータのダウンロード](#download-v3-package-metadata-database-data)に記載されている共有スクリプトとその前提条件を使用してダウンロードします:

```shell
./download_pmdb_data.sh ./Gitlab.gitlab-license 19.4.0-ee licenses ./licenses npm pypi
```

`vendor/package_metadata/licenses`の下に`v3`ディレクトリが存在する場合、インスタンスは`v2`ディレクトリの代わりにそこからライセンスを同期します。同期ジョブが実行される前に、以下のコピー手順を完了してください。

ライセンスデータをオフラインインスタンスにコピーするには:

1. 出力ディレクトリをオフラインインスタンスに転送します。

1. オフラインインスタンスで、GitLab Railsディレクトリのルートを見つけ、ライセンスデータを所定の場所にコピーして権限を更新します。

   ```shell
   export GITLAB_RAILS_ROOT_DIR="$(sudo gitlab-rails runner 'puts Rails.root.to_s')"
   echo $GITLAB_RAILS_ROOT_DIR
   export LICENSES_DIR="$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses"
   sudo rm -rf "$LICENSES_DIR/v3.old" "$LICENSES_DIR/v3.incoming"
   sudo mkdir -p "$LICENSES_DIR/v3" "$LICENSES_DIR/v3.incoming"
   sudo rsync --recursive ./licenses/v3/ "$LICENSES_DIR/v3.incoming/"
   sudo mv "$LICENSES_DIR/v3" "$LICENSES_DIR/v3.old" && \
     sudo mv "$LICENSES_DIR/v3.incoming" "$LICENSES_DIR/v3" && \
     sudo rm -rf "$LICENSES_DIR/v3.old"
   sudo chmod -R 755 "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/"
   ```

   コマンドは`v3`ディレクトリにのみ書き込むため、既存の`v2`ディレクトリは使用されないままディスクに残ります。

   インスタンスは、`v3`ディレクトリが存在すると、そこからすぐにライセンスを読み取ります。同期ジョブは5分ごとに実行されるため、`v3`に直接コピーすると、同期ジョブがまだ書き込み中のディレクトリを読み取ってしまい、`v3`が欠落または中途半端な状態になる可能性があります。代わりに`v3.incoming`にコピーし、リネームによって公開してください。

`PackageMetadata::LicensesSyncWorker` cronジョブは5分ごとに実行され、次回の実行時にライセンスデータをインポートします。アドバイザリと同様に、このジョブは**管理者**エリアで有効にされているパッケージレジストリタイプのみをインポートするため、インスタンスは決してインポートしないレジストリのデータを保持することがあります。

ライセンスデータを更新するには、この手順を繰り返してください。公開すると`v3`ディレクトリ全体が置き換えられるため、後の実行で除外されたレジストリは更新を受け取らなくなります。そのレジストリに対してすでにインポートされたライセンスデータはデータベースに残り、次回の実行でそれを含めると更新が再開されます。

### 自動同期 {#automatic-synchronization}

GitLabインスタンスは、[定期的](https://gitlab.com/gitlab-org/gitlab/-/blob/63a187d47f6da353ba4514650bbbbeb99c356325/config/initializers/1_settings.rb#L840-842)に`package_metadata`ディレクトリのコンテンツと同期されます。アップストリームの変更に合わせてローカルコピーを自動的に更新するために、定期的に新しいエクスポートをダウンロードするようにcronジョブを追加できます。たとえば、次のcrontabを追加して、30分ごとに実行されるcronジョブを設定できます。

ライセンスおよびアドバイザリジョブは`-y "^(v1|v3)\/"`を渡して`v1/`フォルダーと`v3/`フォルダーを除外するため、v2形式バージョンのみをミラーリングします。

v2ライセンススキャン（GitLab 19.3以前）の場合:

```plaintext
*/30 * * * * gsutil -m rsync -r -d -y "^(v1|v3)\/" gs://prod-export-license-bucket-1a6c642fc4de57d4 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses
```

v2依存関係スキャンの場合:

```plaintext
*/30 * * * * gsutil -m rsync -r -d -y "^(v1|v3)\/" gs://prod-export-advisory-bucket-1a6c642fc4de57d4 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/advisories
```

GitLab 19.4以前のCVEエンリッチメントでは、`-d`を省略し、ダウンロード手順の移動ステップを連結します:

```plaintext
*/30 * * * * gsutil -m rsync -r gs://prod-export-cve-enrichment-bucket-1a6c642fc4de57d4 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/cve_enrichment && cd $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/cve_enrichment/v2 && cp -a cve_enrichment/. . && rm -r cve_enrichment
```

移動ステップの後、ローカルレイアウトはバケットと一致しなくなるため、`-d`は移動されたファイルを削除してしまいます。この移動は、`gsutil rsync`が比較対象とするディレクトリも削除するため、`-d`の有無にかかわらず、毎回の実行でエクスポート全体が再ダウンロードされます。

GitLab 19.5以降では、移動ステップなしでダウンロードを実行します。以前のバージョンからアップグレードする場合は、既存のCVEエンリッチメント行を以下に置き換えてください:

```plaintext
*/30 * * * * gsutil -m rsync -r -d gs://prod-export-cve-enrichment-bucket-1a6c642fc4de57d4 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/cve_enrichment
```

> [!warning]
> ライセンスおよびアドバイザリの例、ならびにGitLab 19.5以降のCVEエンリッチメントの例にある`-d`フラグは、バケットにもうないローカルファイルを削除し、進行中のインポートを破棄する可能性があります。GitLabは、各データタイプとパッケージレジストリについて最後にインポートしたファイルを記録し、その後のファイルから再開します。プルーニングによって、そのレコードが指すシーケンスディレクトリが削除された場合、GitLabはそのレコードを見つけられません。その結果、データタイプ全体を最初からもう一度インポートします。プルーニングを行う前に、各データタイプの記録されたシーケンスがまだディスクにあることを確認してください。記録されたシーケンスを読み取るには、[データの検証](#verify-data)を参照してください。複数のインスタンスが読み取るディレクトリでは、それらのいずれかが記録した最も古いシーケンスより前だけをプルーニングしてください。
>
> この動作は、GitLabが一度に1つのファイルをインポートするライセンス、アドバイザリ、およびCVEエンリッチメントのエクスポートに適用されます。前述のマルウェアアドバイザリの手順は異なります。これはGitLabが全体として読み取るディレクトリをミラーリングするため、そこでは`rsync --delete`が必要です。

### v3ライセンスデータ形式バージョン {#v3-license-data-format-version}

{{< history >}}

- GitLab 19.4で[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/22880)。

{{< /history >}}

`v2`と`v3`はライセンスエクスポートの形式バージョンであり、それぞれ独自のフォルダーに公開され、異なる種類のライセンスデータを保持しています:

| 形式バージョン | フォルダー                                 | ライセンスデータ                                      | 読み取り元 |
|----------------|----------------------------------------|---------------------------------------------------|---------|
| v2             | `licenses/v2/<registry>/`              | 単一のSPDX識別子を`.ndjson`ファイルに格納。      | GitLab 19.3以前 |
| v3             | `licenses/v3/<registry>/full_dataset/` | SPDXライセンス式を圧縮アーカイブに格納。 | GitLab 19.4以降 |

形式バージョンを選択するのはGitLabであり、ユーザーが選択するわけではありません。インスタンスは両方のフォルダーを保持できますが、GitLabはどちらか一方のみを読み取ります。

GitLab 19.4以降では、`sync_v3_license_expressions`フラグが有効で、`vendor/package_metadata/licenses`の下に`v3/`フォルダーが存在する場合、GitLabはv3を読み取ります。両方のフォルダーが存在する場合、v3が優先され、`v2/`は無視されます。代わりにv2を読み取るには、フラグをオフにしてください。以前のバージョンは常にv2を読み取ります。

v3フォルダー構造について:

- GitLabはデータを`v3/<registry>`の下に整理します。ここで`<registry>`は`go`、`rubygem`、または`packagist`などの名前です。
- 各レジストリフォルダーは`full_dataset/`フォルダーと、オプションで`deltas/`フォルダーを保持します。`full_dataset/`は完全なスナップショットで、シャードに分割されています: スナップショットのタイムスタンプを含む`checkpoint.json`と、シャードIDにちなんで名付けられたシャードごとの`.tar.zst`アーカイブ（例: `00.tar.zst`）です。`deltas/`は、そのウィンドウを終了するタイムスタンプの増分変更を保持します。

  ```plaintext
  $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses/v3/rubygem/full_dataset/checkpoint.json
  $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses/v3/rubygem/full_dataset/00.tar.zst
  $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses/v3/rubygem/full_dataset/01.tar.zst
  $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses/v3/rubygem/full_dataset/...
  $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses/v3/rubygem/deltas/1757520000.tar.zst
  $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses/v3/rubygem/deltas/1757606400.tar.zst
  ```

- デルタは完全なデータセットの代わりにはなり得ないため、レジストリの最初の同期では`full_dataset/`を読み取り、`deltas/`を無視します。それ以降の同期では、チェックポイントより新しいものを古いものから順に読み取ります。

  > [!warning]
  > デルタアーカイブはそのウィンドウの終了のみを名前として持つため、ギャップのある`deltas/`フォルダーは完全なものと同じように見え、GitLabはエラーを報告しません。アーカイブの一部を選んでコピーするのではなく、ダウンロードスクリプトが生成する`deltas/`フォルダー全体をコピーしてください。

- 同期ジョブは一定時間後に停止するため、大規模なレジストリには複数回の実行が必要です。スナップショットは最初の1回だけでなく、毎回の同期でシャードごとに再開するため、中断された実行は最大でも1つのシャードを再読み込みするだけです。デルタアーカイブは全体として再開するため、中断されたものは次の実行の最初から再読み込みされます。スナップショットと同様に大きなデルタをシャード化することは、[イシュー608196](https://gitlab.com/gitlab-org/gitlab/-/issues/608196)で追跡されています。

### Helmチャートでインストールされたインスタンス {#instances-installed-with-the-helm-chart}

これらの手順は、LinuxパッケージインストールのRailsディレクトリに書き込みます。同期ジョブはSidekiqで実行されます。GitLab Helmチャートを使用するインストールでは、同じファイルがSidekiqポッドが`/srv/gitlab/vendor/package_metadata`で読み取るボリューム上になければなりません。toolboxポッドにのみマウントされたボリュームでは不十分です。同期は引き続きSidekiqで実行され、ディレクトリが見つからないままで、毎回ネットワークパスを試みます。

`gitlab.sidekiq`の下にあるチャートの値でボリュームを宣言します:

```yaml
gitlab:
  sidekiq:
    extraVolumes: |
      - name: package-metadata
        persistentVolumeClaim:
          claimName: gitlab-package-metadata
          readOnly: true
    extraVolumeMounts: |
      - name: package-metadata
        mountPath: /srv/gitlab/vendor/package_metadata
        readOnly: true
```

他の設定は必要ありません。GitLabは、ディレクトリの存在によってオフラインパスを選択します。この変更は、再起動やRakeタスクなしで、次回の同期実行時に反映されます。

すべてのSidekiqポッドがクレームをマウントするため、`ReadOnlyMany`のように、それを許可するアクセスモードをボリュームに与えてください。GitLabはこれらのファイルを読み取るだけです。

値に関する2つの間違いに注意してください:

- `extraVolumes`と`extraVolumeMounts`を[YAMLリストではなく文字列](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/)として記述してください。リストは、テンプレート名を示す型エラーでレンダリング時に失敗します。キーを間違ったレベルに置いた値ファイルは、代わりにサイレントに失敗します。Helmは認識しないキーを無視し、Deploymentはマウントなしでレンダリングされ、コマンドは成功します。レンダリングの成功は証拠にはなりません。マウントがDeploymentに到達したことを確認します:

  ```shell
  kubectl get deployment -l app=sidekiq -o yaml | grep -c 'vendor/package_metadata'
  ```

  チャートはこれらの文字列をHelmテンプレートエンジンに通すため、ボリューム名やマウントパスに`{{`がある場合はエスケープしてください。

- マウントは`kubectl set env`や`kubectl patch`ではなく、値に属します。次の`helm upgrade`がそれを上書きします。保存された設定から調整するデプロイでは、次の調整でインスタンスがネットワークパスに戻ります。オフライン環境では、それは脆弱性データがまったくないことを意味します。

インポートを追跡するには、[トラブルシューティング](#troubleshooting)に記載されているように、WebserviceポッドではなくSidekiqポッド上の記録されたシーケンスとログを読み取ってください。

### トラブルシューティング {#troubleshooting}

#### データベースデータが見つからない {#missing-database-data}

依存関係リスト、脆弱性レポート、またはマージリクエストページからライセンスまたはアドバイザリデータが欠落している場合、データベースがエクスポートデータと同期していない可能性があります。

##### 有効なパッケージレジストリタイプの確認 {#confirm-enabled-package-registry-types}

`package_metadata`の同期は、cronジョブ（[アドバイザリ同期](https://gitlab.com/gitlab-org/gitlab/-/blob/16-3-stable-ee/config/initializers/1_settings.rb#L864-866)および[ライセンス同期](https://gitlab.com/gitlab-org/gitlab/-/blob/16-3-stable-ee/config/initializers/1_settings.rb#L855-857)）を使用してトリガーされます。[管理者設定](../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)で有効にされているパッケージレジストリタイプのみがインポートされます。

たとえば、`maven`が選択されていて`golang`が選択されていない場合、Mavenのアドバイザリとライセンス情報のみが表示されます。

##### 正しいファイル構造の確認 {#confirm-correct-file-structure}

`vendor/package_metadata`のファイル構造は、上記で有効になっているパッケージレジストリタイプと一致する必要があります。たとえば、`maven`のライセンスまたはアドバイザリデータを同期するには、Railsディレクトリ配下のパッケージメタデータディレクトリが以下の構造を持つ必要があります。ここで`$GITLAB_RAILS_ROOT_DIR`はコマンド`gitlab-rails runner 'puts Rails.root.to_s'`の出力と一致します:

- v2上のライセンス（GitLab 19.3以前）の場合: `$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses/v2/maven/**/*.ndjson`。
- v3上のライセンス（GitLab 19.4以降）の場合: `$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses/v3/maven/full_dataset/*`。[v3ライセンスデータ形式バージョン](#v3-license-data-format-version)を参照してください。
- v2上のアドバイザリの場合: `$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/advisories/v2/maven/**/*.ndjson`。

CVEエンリッチメントはパッケージレジストリタイプによって分割されていません。GitLab 19.5以降では、GitLabは`$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/cve_enrichment/v2/cve_enrichment/*/*.ndjson`からそのままコピーされたバケットのコピーを読み取ります。その`cve_enrichment`ディレクトリが存在する場合、GitLabはそのディレクトリのみを読み取ります。GitLab 19.4以前、またはそのディレクトリが存在しない場合、CVEエンリッチメントファイルはバージョンディレクトリの正確に2ディレクトリ階層下になければなりません:

- CVEエンリッチメントの場合: `$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/cve_enrichment/v2/*/*.ndjson`。

GitLab 19.4以前では、そのままコピーされたCVEエンリッチメントバケットのコピーは、ファイルを必要以上に1階層深く配置するため、GitLabはそれらを一切読み取りません。修正するには、[ダウンロード手順のCVEエンリッチメントステップ](#v2-using-the-gsutil-tool-to-download-the-package-metadata-exports)を参照してください。

GitLabがファイルパスを認識しているかどうかは、[Railsコンソール](../../administration/operations/rails_console.md)で確認できます:

- ライセンス: `sudo gitlab-rails runner "puts File.exist?(PackageMetadata::SyncConfiguration::Location::LICENSES_PATH)"`
- アドバイザリ: `sudo gitlab-rails runner "puts File.exist?(PackageMetadata::SyncConfiguration::Location::ADVISORIES_PATH)"`
- CVEエンリッチメントの場合: `sudo gitlab-rails runner "puts File.exist?(PackageMetadata::SyncConfiguration::Location::CVE_ENRICHMENT_PATH)"`

上記のコマンドが`false`を返す場合、GitLabは期待されるパッケージパスを見つけられません。パス内のすべてのフォルダーとファイルには`755`権限が必要です。権限を更新するには:

`sudo chmod -R 755 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/`

##### データの検証 {#verify-data}

同期ジョブが正常に実行された後、データベース内の`pm_`テーブルにデータが入力されているはずです。

[Railsコンソール](../../administration/operations/rails_console.md)を使用して、ベンダーに存在するパッケージ数を確認することで確認できます。たとえば、Mavenのライセンスおよびアドバイザリデータが読み込まれたことを確認するには、以下を実行します:

- ライセンス: `sudo gitlab-rails runner "puts \"Package model has #{PackageMetadata::Package.where(purl_type: 'maven').size} packages\""`
- アドバイザリ: `sudo gitlab-rails runner "puts \"Advisory model has #{PackageMetadata::AffectedPackage.where(purl_type: 'maven').size} packages\""`

さらに、チェックポイントデータは、同期されている特定のパッケージレジストリに存在する必要があります。たとえば、Mavenの場合、同期の実行が成功すると、チェックポイントが作成されているはずです。

- ライセンス: `sudo gitlab-rails runner "puts \"maven data has been synced up to #{PackageMetadata::Checkpoint.where(data_type: 'licenses', purl_type: 'maven')}\""`
- アドバイザリ: `sudo gitlab-rails runner "puts \"maven data has been synced up to #{PackageMetadata::Checkpoint.where(data_type: 'advisories', purl_type: 'maven')}\""`

##### ログ {#logs}

[`application_json.log`](../../administration/logs/_index.md#application_jsonlog)ファイルは、同期ジョブが実行され、エラーがないことを確認するのに役立ちます。同期に関連するイベントは`DEBUG`の重大度を持ち、クラスは`PackageMetadata::SyncService`です。例: `{"severity":"DEBUG","time":"2026-01-07T02:15:49.618Z","meta.caller_id":"PackageMetadata::AdvisoriesSyncWorker","correlation_id":"43008e30dd708eadbe1ab16ad7fa953f","meta.root_caller_id":"Cronjob","meta.feature_category":"software_composition_analysis","meta.client_id":"ip/","class":"PackageMetadata::SyncService","message":"Evaluating data for advisories:offline//opt/gitlab/embedded/service/gitlab-rails/vendor/package_metadata/advisories/v2/maven/1761761049/0.ndjson"}`

[`sidekiq`](../../administration/logs/_index.md#sidekiq-logs)ログは、同期ジョブ中にエラーが発生したかどうかを示します。同期のためにログに記録されたイベントは、関連するクラスに言及します:

- ライセンス: `PackageMetadata::LicensesSyncWorker`
- アドバイザリ: `PackageMetadata::AdvisoriesSyncWorker`

#### v3ライセンスデータの欠落 {#missing-v3-license-data}

インスタンスにコピーした後にライセンスデータが欠落している場合、同期ジョブはディレクトリを見つけられなかったか、新しくインポートするものが見つからなかったかのいずれかです。どちらの結果もサイレントであるため、エラーを探すのではなく、以下のチェックを実行してください。

はじめる前:

- [データベースデータの欠落](#missing-database-data)に関するトラブルシューティングガイダンスに従い、特に有効なパッケージレジストリタイプとライセンスのファイル構造を確認してください。
- v3ライセンスファイル構造を確認してください。[マルウェアアドバイザリファイル構造](#confirm-the-malware-advisory-file-structure)と一致している必要があります。

##### v3ライセンスデータの検証 {#verify-v3-license-data}

式はライセンスレコードに保存されます。同期されたv3スナップショットを確認するには、式を持つライセンスが少なくとも1つあることを確認してください。Railsコンソールで確認できます:

- `sudo gitlab-rails runner "puts \"#{PackageMetadata::License.where.not(spdx_expression: nil).count} licenses have an expression\""`

パッケージとチェックポイントは存在するが式を持つライセンスがない場合、インスタンスはv3ではなくv2レイアウトを同期しています。ディスク上のデータが`v3/`の下にあることを確認してください。

スナップショットは、記録されたチェックポイントより新しい場合にのみインポートされるため、同じスナップショットを2回コピーしても効果はありません。より新しいライセンスデータを取得するには、ダウンロードスクリプトを再度実行してください。

#### マルウェアアドバイザリデータの欠落 {#missing-malware-advisory-data}

インスタンスにコピーした後にマルウェアアドバイザリが欠落している場合、同期ジョブはディレクトリを見つけられなかったか、新しくインポートするものが見つからなかったかのいずれかです。どちらの結果もサイレントであるため、エラーを探すのではなく、以下のチェックを実行してください。

##### マルウェアアドバイザリの有効なパッケージレジストリタイプの確認 {#confirm-enabled-package-registry-types-for-malware-advisories}

[管理者設定](../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)で有効にされているパッケージレジストリタイプのみがインポートされます。コピーしたが有効にしなかったレジストリは読み取られず、何もログに記録されません。

##### GitLabがオフラインディレクトリを検出することの確認 {#confirm-gitlab-detects-the-offline-directory}

GitLabは、ベンダーディレクトリが存在する場合はディスクからマルウェアアドバイザリを読み取り、存在しない場合は配布サービスから読み取ります。GitLabがファイルパスを認識しているかどうかは、[Railsコンソール](../../administration/operations/rails_console.md)で確認できます:

- `sudo gitlab-rails runner "puts File.exist?(PackageMetadata::SyncConfiguration::Location::MALWARE_ADVISORIES_PATH)"`

コマンドが`false`を返す場合、GitLabは期待されるパスを見つけられません。パス内のすべてのフォルダーとファイルには`755`権限が必要です。Kubernetesインストールでは、Sidekiqと同じボリュームをマウントするポッドでコマンドを実行してください。そうしないと、結果が同期ジョブの読み取り内容を反映しません。

##### マルウェアアドバイザリファイル構造の確認 {#confirm-the-malware-advisory-file-structure}

ディレクトリは、パッケージタイプではなくパッケージレジストリ識別子にちなんで名付けられます。これらの識別子は常に同じとは限りません: `gem`アドバイザリは`rubygem`の下に、`golang`は`go`の下に、`composer`は`packagist`の下に保存されます。パッケージタイプにちなんで名付けられたディレクトリは無視され、エラーはログに記録されません。

各`full_dataset`ディレクトリには`checkpoint.json`も含まれている必要があります。GitLabはチェックポイントのないディレクトリを無視します。これにより、中断されたダウンロードがインポートされるのを防ぎます。

##### マルウェアアドバイザリデータの検証 {#verify-malware-advisory-data}

同期ジョブが正常に実行された後、マルウェアアドバイザリが入力されているはずです。[Railsコンソール](../../administration/operations/rails_console.md)でアドバイザリの数を数えることで確認できます:

- `sudo gitlab-rails runner "puts \"Malware advisory model has #{PackageMetadata::MalwareAdvisory.count} advisories\""`

コピーしたパッケージレジストリのチェックポイントデータも存在するはずです:

- `sudo gitlab-rails runner "puts PackageMetadata::Checkpoint.where(data_type: 'malware_advisories').pluck(:purl_type, :sequence).to_h"`

スナップショットは、記録されたチェックポイントより新しい場合にのみインポートされるため、同じスナップショットを2回コピーしても効果はありません。

##### マルウェアアドバイザリログ {#malware-advisory-logs}

マルウェアアドバイザリ同期に関連するイベントは、`INFO`の重大度で[`application_json.log`](../../administration/logs/_index.md#application_jsonlog)に記録されます。同期自体のクラスは`PackageMetadata::MalwareAdvisorySyncService`、インポートのクラスは`PackageMetadata::MalwareAdvisoryIngestionService`です。同期はSidekiqで実行されるため、Kubernetesインストールでは、これらのイベントはWebserviceポッドではなく、`subcomponent="application_json"`キーの下のSidekiqポッドにあります。

[`sidekiq`](../../administration/logs/_index.md#sidekiq-logs)ログは、`PackageMetadata::MalwareAdvisoriesSyncWorker`クラスに対してログに記録された発生したエラーを示します。

各レジストリは、実行ごとに`started`イベントと`completed`イベントをログに記録します。`files_ingested: 0`を伴う`completed`イベントは、その実行がインポートするものを何も見つけられなかったことを意味します。そのイベントの`storage_type`フィールドは、どちらのケースであるかを示します: `offline`はGitLabがベンダーディレクトリを読み取ったことを意味し、`pds`はディレクトリが見つからず代わりに配布サービスを試みたことを意味します。Kubernetesでは、このフィールドは同期を実行するプロセスから得られるため、前述の`File.exist?`チェックよりも信頼性が高くなります。

`PackageMetadata::MalwareAdvisorySyncService`イベントがまったく表示されない場合は、`DEBUG`の重大度を持つ`PackageMetadata::MalwareAdvisoriesSyncWorker`イベントを探してください。無効化された`sync_malware_advisories`機能フラグなど、実行が開始されなかった理由を示します。

`Malware advisory upsert skipped: ingest_malware_advisories disabled`イベントは、`ingest_malware_advisories`機能フラグがオフであることを意味します。同期は毎回実行時にファイルを読み取りますが何も書き込まず、チェックポイントは進みません。

大規模なレジストリの最初のインポートには数分かかることがあり、その間もcronは5分ごとに再度起動します。重複する各実行は、`ERROR`の重大度で`application_json.log`に`Cannot obtain an exclusive lease. There must be another instance already in execution.`をログに記録し、その後終了します。リースは2つの同期が同時に実行されるのを防ぐものであるため、これらのイベントは長時間のインポート中は想定内であり、同期が失敗したことを意味するものではありません。

---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab汎用パッケージリポジトリ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

汎用パッケージリポジトリを使用して、プロジェクトのパッケージレジストリにリリースバイナリなどの汎用ファイルを公開および管理します。この機能は、npmやMavenなどの特定のパッケージ形式に適合しないアーティファクトの保存および配布に特に役立ちます。

汎用パッケージリポジトリには、次の機能があります:

- あらゆるファイルタイプをパッケージとして保存する場所。
- パッケージのバージョン管理。
- GitLab CI/CDとのインテグレーション。
- 自動化のためのAPIアクセス。

## パッケージレジストリに対して認証する {#authenticate-to-the-package-registry}

パッケージレジストリを操作するには、次のいずれかの方法で認証する必要があります:

- スコープが`api`に設定された[パーソナルアクセストークン](../../profile/personal_access_tokens.md)。
- スコープが`api`に設定され、少なくともデベロッパーロールを持つ[プロジェクトアクセストークン](../../project/settings/project_access_tokens.md)。
- [CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)。
- スコープが`read_package_registry`、`write_package_registry`、またはその両方に設定された[デプロイトークン](../../project/deploy_tokens/_index.md)。

ここに記載されている方法以外の認証方法は使用しないでください。記載されていない認証方法は、将来削除される可能性があります。

パッケージレジストリで認証する場合は、次のベストプラクティスに従ってください:

- デベロッパーロールに関連付けられた権限にアクセスするには、パーソナルアクセストークンを使用します。
- 自動化されたパイプラインには、CI/CDジョブトークンを使用します。
- 外部システムインテグレーションには、デプロイトークンを使用します。
- 常にHTTPS経由で認証情報を送信します。

### HTTP基本認証 {#http-basic-authentication}

標準の認証方法をサポートしていないツールを使用する場合は、HTTP基本認証を使用できます:

```shell
curl --user "<username>:<token>" <other options> <GitLab API endpoint>
```

無視されますが、ユーザー名を入力する必要があります。トークンは、パーソナルアクセストークン、CI/CDジョブトークン、またはデプロイトークンです。

## パッケージを公開する {#publish-a-package}

APIを使用してパッケージを公開できます。

### 単一のファイルを公開する {#publish-a-single-file}

単一のファイルを公開するには、次のAPIエンドポイントを使用します:

```shell
PUT /projects/:id/packages/generic/:package_name/:package_version/:file_name
```

URLのプレースホルダーを特定の値に置き換えます:

- `:id`: プロジェクトIDまたはURLエンコードされたパス
- `:package_name`: パッケージの名前
- `:package_version`: パッケージのバージョン
- `:file_name`: アップロードするファイルの名前以下の[有効なパッケージファイル名の形式](#valid-package-filename-format)を参照してください。

次に例を示します: 

{{< tabs >}}

{{< tab title="パーソナルアクセストークン" >}}

HTTPヘッダーを使用:

```shell
curl --location --header "PRIVATE-TOKEN: <personal_access_token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/1.0.0/file.txt"
```

HTTP基本認証を使用:

```shell
curl --location --user "<username>:<personal_access_token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/1.0.0/file.txt"
```

{{< /tab >}}

{{< tab title="プロジェクトアクセストークン" >}}

HTTPヘッダーを使用:

```shell
curl --location --header  "PRIVATE-TOKEN: <project_access_token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/1.0.0/file.txt"
```

HTTP基本認証を使用:

```shell
curl --location --user "<project_access_token_username>:project_access_token" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/1.0.0/file.txt"
```

{{< /tab >}}

{{< tab title="デプロイトークン" >}}

HTTPヘッダーを使用:

```shell
curl --location --header  "DEPLOY-TOKEN: <deploy_token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/1.0.0/file.txt"
```

HTTP基本認証を使用:

```shell
curl --location --user "<deploy_token_username>:<deploy_token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/1.0.0/file.txt"
```

`<deploy_token_username>`をデプロイトークンのユーザー名に、`<deploy_token>`を実際のデプロイトークンに置き換えます。

{{< /tab >}}

{{< tab title="CI/CDジョブトークン" >}}

これらの例は、`.gitlab-ci.yml`ファイル用です。GitLab CI/CDは、`CI_JOB_TOKEN`を自動的に提供します。

HTTPヘッダーを使用:

```yaml
publish:
  stage: deploy
  script:
    - |
      curl --location --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
           --upload-file path/to/file.txt \
           "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/${CI_COMMIT_TAG}/file.txt"
```

HTTP基本認証を使用:

```yaml
publish:
  stage: deploy
  script:
    - |
      curl --location --user "gitlab-ci-token:${CI_JOB_TOKEN}" \
           --upload-file path/to/file.txt \
           "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/${CI_COMMIT_TAG}/file.txt"
```

{{< /tab >}}

{{< /tabs >}}

各リクエストは、成功または失敗を示す応答を返します。アップロードに成功した場合、応答ステータスは`201 Created`です。

### 複数のファイルを公開する {#publish-multiple-files}

複数のファイルまたはディレクトリ全体を公開するには、ファイルごとに1回ずつAPIコールを実行する必要があります。

リポジトリに複数のファイルを公開する場合は、次のベストプラクティスに従ってください:

- バージョニング: パッケージには一貫したバージョニングスキームを使用します。プロジェクトのバージョン、ビルド番号、または日付に基づいてバージョンを指定することをおすすめします。
- ファイルの構成: パッケージ内のファイルをどのように構造化するかを検討してください。含まれているすべてのファイルとその目的を記載したマニフェストファイルを含めることをおすすめします。
- 自動化: 可能な限り、CI/CDパイプラインを通じて公開プロセスを自動化します。これにより、一貫性が確保され、手動によるエラーが削減されます。
- エラー処理: スクリプト内でエラーチェックを実装します。たとえば、cURLからのHTTP応答コードをチェックして、各ファイルが正常にアップロードされたことを確認します。
- ログの生成: どのファイルがいつ、誰によってアップロードされたかのログを保持します。これは、トラブルシューティングや監査において非常に重要です。
- 圧縮: 大きなディレクトリの場合は、アップロードする前にコンテンツを1つのファイルに圧縮することを検討してください。これにより、アップロードプロセスが簡素化され、APIコールの回数も削減できます。
- チェックサム: ファイルのチェックサム（MD5、SHA256）を生成して保存します。これにより、ユーザーはダウンロードしたファイルの整合性を検証できます。

次に例を示します:

{{< tabs >}}

{{< tab title="Bashスクリプトを使用" >}}

Bashスクリプトを作成して、ファイルのイテレーションを行い、それらをアップロードします:

```shell
#!/bin/bash

TOKEN="<access_token>"
PROJECT_ID="24"
PACKAGE_NAME="my_package"
PACKAGE_VERSION="1.0.0"
DIRECTORY_PATH="./files_to_upload"

for file in "$DIRECTORY_PATH"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        curl --location --header  "PRIVATE-TOKEN: $TOKEN" \
             --upload-file "$file" \
             "https://gitlab.example.com/api/v4/projects/$PROJECT_ID/packages/generic/$PACKAGE_NAME/$PACKAGE_VERSION/$filename"
        echo "Uploaded: $filename"
    fi
done
```

{{< /tab >}}

{{< tab title="GitLab CI/CDを使用" >}}

CI/CDパイプラインでの自動アップロードでは、ファイルのイテレーションを行い、それらをアップロードできます:

```yaml
upload_package:
  stage: publish
  script:
    - |
      for file in ./build/*; do
        if [ -f "$file" ]; then
          filename=$(basename "$file")
          curl --header "JOB-TOKEN: $CI_JOB_TOKEN" \
               --upload-file "$file" \
               "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/${CI_COMMIT_TAG}/$filename"
          echo "Uploaded: $filename"
        fi
      done
```

{{< /tab >}}

{{< /tabs >}}

### ディレクトリ構造を保持する {#maintain-directory-structure}

公開されたディレクトリの構造を保持するには、ファイル名に相対パスを含めます:

```shell
#!/bin/bash

TOKEN="<access_token>"
PROJECT_ID="24"
PACKAGE_NAME="my_package"
PACKAGE_VERSION="1.0.0"
DIRECTORY_PATH="./files_to_upload"

find "$DIRECTORY_PATH" -type f | while read -r file; do
    relative_path=${file#"$DIRECTORY_PATH/"}
    curl --location --header  "PRIVATE-TOKEN: $TOKEN" \
         --upload-file "$file" \
         "https://gitlab.example.com/api/v4/projects/$PROJECT_ID/packages/generic/$PACKAGE_NAME/$PACKAGE_VERSION/$relative_path"
    echo "Uploaded: $relative_path"
done
```

## パッケージをダウンロードする {#download-a-package}

APIを使用してパッケージをダウンロードできます。

### 単一のファイルをダウンロードする {#download-a-single-file}

単一のパッケージファイルをダウンロードするには、次のAPIエンドポイントを使用します:

```shell
GET /projects/:id/packages/generic/:package_name/:package_version/:file_name
```

URLのプレースホルダーを特定の値に置き換えます:

- `:id`: プロジェクトIDまたはURLエンコードされたパス
- `:package_name`: パッケージの名前
- `:package_version`: パッケージのバージョン
- `:file_name`: アップロードするファイルの名前

次に例を示します:

{{< tabs >}}

{{< tab title="パーソナルアクセストークン" >}}

HTTPヘッダーを使用:

```shell
curl --header "PRIVATE-TOKEN: <access_token>" \
     --location \
     "https://gitlab.example.com/api/v4/projects/1/packages/generic/my_package/0.0.1/file.txt" \
     --output file.txt
```

HTTP基本認証を使用:

```shell
curl --user "<username>:<access_token>" \
     --location \
     "https://gitlab.example.com/api/v4/projects/1/packages/generic/my_package/0.0.1/file.txt" \
     --output file.txt
```

{{< /tab >}}

{{< tab title="プロジェクトアクセストークン" >}}

HTTPヘッダーを使用:

```shell
curl --header "PRIVATE-TOKEN: <project_access_token>" \
     --location \
     "https://gitlab.example.com/api/v4/projects/1/packages/generic/my_package/0.0.1/file.txt" \
     --output file.txt
```

HTTP基本認証を使用:

```shell
curl --user "<project_access_token_username>:<project_access_token>" \
     --location \
     "https://gitlab.example.com/api/v4/projects/1/packages/generic/my_package/0.0.1/file.txt" \
     --output file.txt
```

{{< /tab >}}

{{< tab title="デプロイトークン" >}}

HTTPヘッダーを使用:

```shell
curl --header "DEPLOY-TOKEN: <deploy_token>" \
     --location \
     "https://gitlab.example.com/api/v4/projects/1/packages/generic/my_package/0.0.1/file.txt" \
     --output file.txt
```

HTTP基本認証を使用:

```shell
curl --user "<deploy_token_username>:<deploy_token>" \
     --location \
     "https://gitlab.example.com/api/v4/projects/1/packages/generic/my_package/0.0.1/file.txt" \
     --output file.txt
```

{{< /tab >}}

{{< tab title="CI/CDジョブトークン" >}}

これらの例は、`.gitlab-ci.yml`ファイル用です。GitLab CI/CDは、`CI_JOB_TOKEN`を自動的に提供します。

HTTPヘッダーを使用:

```yaml
download:
  stage: test
  script:
    - |
      curl --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
           --location \
           --output file.txt \
           "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/${CI_COMMIT_TAG}/file.txt"
```

HTTP基本認証を使用:

```yaml
download:
  stage: test
  script:
    - |
      curl --user "gitlab-ci-token:${CI_JOB_TOKEN}" \
           --location \
           --output file.txt \
           "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/${CI_COMMIT_TAG}/file.txt"
```

各リクエストは、成功または失敗を示す応答を返します。アップロードに成功した場合、応答ステータスは`201 Created`です。

{{< /tab >}}

{{< /tabs >}}

### 複数のファイルをダウンロードする {#download-multiple-files}

複数のファイルまたはディレクトリ全体をダウンロードするには、ファイルごとに1回ずつAPIコールを実行するか、追加のツールを使用する必要があります。

リポジトリから複数のファイルをダウンロードする場合は、次のベストプラクティスに従ってください:

- バージョニング: 一貫性を確保するために、ダウンロードするパッケージの正確なバージョンを常に指定してください。
- ディレクトリ構造: ダウンロードするときは、ファイル構成を維持するために、パッケージの元のディレクトリ構造を保持します。
- 自動化: 自動化されたワークフローを実現するため、パッケージのダウンロードをCI/CDパイプラインまたはビルドスクリプトに統合します。
- エラー処理: すべてのファイルが正常にダウンロードされたことを確認するためのチェックを実装します。HTTPステータスコードを検証したり、ダウンロード後にファイルの存在を確認したりできます。
- キャッシュ: 頻繁に使用されるパッケージの場合は、ネットワーク使用量を削減し、ビルド時間を改善するために、キャッシュメカニズムの実装を検討してください。
- 並列ダウンロード: 多数のファイルを含む大規模なパッケージの場合は、プロセスを高速化するために並列ダウンロードの実装を検討してください。
- チェックサム: 利用可能な場合は、パッケージの公開元から提供されたチェックサムを使用して、ダウンロードしたファイルの整合性を検証します。
- 増分ダウンロード: 頻繁に変更される大規模なパッケージの場合は、最後のダウンロード以降に変更されたファイルのみをダウンロードするメカニズムの実装を検討してください。

次に例を示します:

{{< tabs >}}

{{< tab title="Bashスクリプトを使用" >}}

複数のファイルをダウンロードするbashスクリプトを作成します:

```shell
#!/bin/bash

TOKEN="<access_token>"
PROJECT_ID="24"
PACKAGE_NAME="my_package"
PACKAGE_VERSION="1.0.0"
OUTPUT_DIR="./downloaded_files"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Array of files to download
files=("file1.txt" "file2.txt" "subdirectory/file3.txt")

for file in "${files[@]}"; do
    curl --location --header  "PRIVATE-TOKEN: $TOKEN" \
         --output "$OUTPUT_DIR/$file" \
         --create-dirs \
         "https://gitlab.example.com/api/v4/projects/$PROJECT_ID/packages/generic/$PACKAGE_NAME/$PACKAGE_VERSION/$file"
    echo "Downloaded: $file"
done
```

{{< /tab >}}

{{< tab title="GitLab CI/CDを使用" >}}

CI/CDパイプラインでの自動ダウンロードの場合:

```yaml
download_package:
  stage: build
  script:
    - |
      FILES=("file1.txt" "file2.txt" "subdirectory/file3.txt")
      for file in "${FILES[@]}"; do
        curl --location --header  "JOB-TOKEN: $CI_JOB_TOKEN" \
             --output "$file" \
             --create-dirs \
             "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/${CI_COMMIT_TAG}/$file"
        echo "Downloaded: $file"
      done
```

{{< /tab >}}

{{< /tabs >}}

### パッケージ全体をダウンロードする {#download-an-entire-package}

パッケージ内のすべてのファイルをダウンロードするには、以下を実行する必要があります:

1. はパッケージIDです。
1. GitLab APIを使用してパッケージの内容をリスト表示します。
1. 各ファイルをダウンロードします。

パッケージ内のすべてのファイルをダウンロードするには、次のコマンドを実行します:

```shell
TOKEN="<access_token>"
PROJECT_ID="24"
PACKAGE_NAME="my_package"
PACKAGE_VERSION="1.0.0"
GITLAB_URL="https://gitlab.example.com"
OUTPUT_DIR="./downloaded_package"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Step 1: Get the package ID
PACKAGE_ID=$(curl --location --header "PRIVATE-TOKEN: $TOKEN" \
     "$GITLAB_URL/api/v4/projects/$PROJECT_ID/packages?package_type=generic&package_name=$PACKAGE_NAME&package_version=$PACKAGE_VERSION" \
     | jq -r ".[] | select(.name==\"$PACKAGE_NAME\" and .version==\"$PACKAGE_VERSION\") | .id")

if [ -z "$PACKAGE_ID" ] || [ "$PACKAGE_ID" = "null" ]; then
    echo "Error: Package '$PACKAGE_NAME' version '$PACKAGE_VERSION' not found"
    exit 1
fi

echo "Found package ID: $PACKAGE_ID"

# Step 2: Get list of files in the package
files=$(curl --location --header "PRIVATE-TOKEN: $TOKEN" \
     "$GITLAB_URL/api/v4/projects/$PROJECT_ID/packages/$PACKAGE_ID/package_files" \
     | jq -r '.[].file_name')

if [ -z "$files" ]; then
    echo "Error: No files found in package"
    exit 1
fi

# Step 3: Download each file
for file in $files; do
    echo "Downloading: $file"
    curl --location --header "PRIVATE-TOKEN: $TOKEN" \
         --output "$OUTPUT_DIR/$file" \
         --create-dirs \
         "$GITLAB_URL/api/v4/projects/$PROJECT_ID/packages/generic/$PACKAGE_NAME/$PACKAGE_VERSION/$file"
    # Check if download was successful
    if [ $? -eq 0 ]; then
        echo "✓ Downloaded: $file"
    else
        echo "✗ Failed to download: $file"
    fi
done

echo "Package download complete"
```

## 重複するパッケージ名の公開を無効にする {#disable-publishing-duplicate-package-names}

{{< history >}}

- GitLab 15.0で、必要なロールがデベロッパーからメンテナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/350682)されました。
- GitLab 17.0で、必要なロールがメンテナーからオーナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/370471)されました。

{{< /history >}}

デフォルトでは、既存のパッケージと同じ名前とバージョンを持つパッケージを公開すると、新しいファイルが既存のパッケージに追加されます。設定で重複するファイル名の公開を無効にすることができます。

前提要件:

- オーナーロールが必要です。

重複するファイル名の公開を無効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **パッケージの重複**テーブルの**一般**行で、**重複を許可**の切替をオフにします。
1. オプション。**例外**テキストボックスに、許可するパッケージの名前とバージョンに一致する正規表現を入力します。

{{< alert type="note" >}}

**重複を許可**がオンになっている場合は、**例外**テキストボックスで、重複してはならないパッケージ名とバージョンを指定できます。

{{< /alert >}}

## パッケージ保持ポリシーを追加する {#add-a-package-retention-policy}

ストレージを管理し、関連バージョンを維持するために、パッケージ保持ポリシーを実装します。

これを行うには、次の手順に従います:

- 組み込みのGitLab[クリーンアップポリシー](../package_registry/reduce_package_registry_storage.md#cleanup-policy)を使用します。

APIを使用して、カスタムクリーンアップスクリプトを実装することもできます。

## 汎用パッケージのサンプルプロジェクト {#generic-package-sample-project}

[パイプラインでCI/CD変数を設定する](https://gitlab.com/guided-explorations/cfg-data/write-ci-cd-variables-in-pipeline)プロジェクトには、GitLab CI/CDで汎用パッケージを作成、アップロード、ダウンロードする際に使用できる実用的な例が含まれています。

また、汎用パッケージのセマンティックバージョンを管理する方法も示しています。具体的には、バージョンをCI/CD変数に保存し、取得して、インクリメントし、ダウンロードのテストが正しく動作した場合にCI/CD変数に書き戻します。

## 有効なパッケージファイル名の形式 {#valid-package-filename-format}

有効なパッケージファイル名には、以下を含めることができます:

- 文字: A-Z、a-z
- 数字: 0～9
- 特殊文字: .（ドット）、_（アンダースコア）、-（ハイフン）、+（プラス）、〜（チルダ）、@（アットマーク）、/（スラッシュ）

パッケージファイル名には以下を含めることはできません:

- チルダ（〜）またはアットマーク（@）で開始する
- チルダ（〜）またはアットマーク（@）で終わる
- スペースを含める

## トラブルシューティング {#troubleshooting}

### HTTP 403エラー {#http-403-errors}

`HTTP 403 Forbidden`（閲覧禁止）エラーが発生する可能性があります。このエラーは、次のいずれかの場合に発生します:

- リソースにアクセスする権限がない。
- パッケージレジストリがプロジェクトで有効になっていない。

この問題を解決するには、パッケージレジストリが有効になっていること、そのレジストリにアクセスする権限があることを確認してください。

### S3に大きなファイルをアップロードする際の内部サーバーエラー {#internal-server-error-on-large-file-uploads-to-s3}

S3互換オブジェクトストレージでは、[単一のPUTリクエストのサイズが5 GBに制限されています](https://docs.aws.amazon.com/AmazonS3/latest/userguide/upload-objects.html)。[オブジェクトストレージ接続の設定](../../../administration/object_storage.md)で、`aws_signature_version`が`2`に設定されている場合、5 GBの制限を超えるパッケージファイルを公開しようとすると、`HTTP 500: Internal Server Error`（内部サーバーエラー）応答が発生する可能性があります。

S3に大きなファイルを公開するときに`HTTP 500: Internal Server Error`（内部サーバーエラー）応答が表示される場合は、`aws_signature_version`を`4`に設定します:

```ruby
# Consolidated Object Storage settings
gitlab_rails['object_store']['connection'] = {
  # Other connection settings
  'aws_signature_version' => '4'
}
# OR
# Storage-specific form settings
gitlab_rails['packages_object_store_connection'] = {
  # Other connection settings
  'aws_signature_version' => '4'
}
```

---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リリースフィールド
---

以下のフィールドは、リリースを作成または編集するときに使用できます。

## タイトル {#title}

リリースの**リリースタイトル**フィールドを使用して、リリースのタイトルをカスタマイズできます。タイトルが指定されていない場合は、リリースのタグ名が代わりに使用されます。

## タグ名 {#tag-name}

リリースのタグ名には、リリースのバージョンを含める必要があります。GitLabでは、[セマンティックバージョニング](https://semver.org/)をリリースに使用しており、同様に使用することをお勧めします。[GitLabのバージョニングポリシー](../../../policy/maintenance.md#versioning)で詳しく説明されているように、`(Major).(Minor).(Patch)`を使用します。

たとえば、GitLabのバージョン`16.1.1`の場合:

- `16`はメジャーバージョンを表します。メジャーリリースは`16.0.0`でしたが、`16.0`と呼ばれることがよくあります。
- `10`はマイナーバージョンを表します。マイナーリリースは`16.1.0`でしたが、`16.1`と呼ばれることがよくあります。
- `1`はパッチ番号を表します。

バージョン番号のどの部分も、複数の桁に増やすことができます（例：`16.10.11`）。

## リリースノートの説明 {#release-notes-description}

すべてのリリースには説明が含まれています。任意のテキストを追加できますが、リリースの内容を説明するために変更履歴を含めることをお勧めします。これにより、公開する各リリース間の違いをユーザーがすばやくスキャンできます。

[Gitでのタグ付けメッセージ](https://git-scm.com/book/en/v2/Git-Basics-Tagging)は、**Include tag message in the release notes**（リリースノートにタグメッセージを含める）を選択すると、リリースノートの説明に含めることができます。

説明では[Markdown](../../markdown.md)がサポートされています。

## リリースアセット {#release-assets}

リリースには、次の種類のアセットが含まれています。:

- [ソースコード](#source-code)
- [関連資料へのリンク](#links)

### ソースコード {#source-code}

GitLabは、指定されたGitタグから、アーカイブされたソースコードである`zip`、`tar.gz`、`tar.bz2`、`tar`を自動的に生成します。これらのリリースアセットは読み取り専用であり、[ダウンロードできます](../repository/_index.md#download-repository-source-code)。

### リンク {#links}

リンクとは、ドキュメント、バイナリ、またはその他の関連資料など、必要なものを指すことができるURLのことです。これらは、GitLabインスタンスからの内部リンクと外部リンクの両方になります。アセットとしての各リンクには、次の属性があります。:

| 属性   | 説明                                                                                                  | 必須 |
|-------------|--------------------------------------------------------------------------------------------------------------|----------|
| `name`      | リンクの名前。                                                                                        | はい      |
| `url`       | ファイルをダウンロードするためのURL。                                                                                  | はい      |
| `filepath`  | `url`へのリダイレクトリンク。スラッシュ（`/`）で始める必要があります。詳細については、[このセクション](#permanent-links-to-release-assets)を参照してください。 | いいえ       |
| `link_type` | ユーザーが`url`でダウンロードできるコンテンツの種類。詳細については、[このセクション](#link-types)を参照してください。 | いいえ       |

#### リリースアセットへの永続的なリンク {#permanent-links-to-release-assets}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/375489)されました。プライベートリリースへのリンクは、パーソナルアクセストークンを使用してアクセスできます。

{{< /history >}}

リリースに関連付けられたアセットには、永続的なURLを介してアクセスできます。GitLabはこのURLを実際のアセットの場所に常にリダイレクトするため、アセットの場所が異なっても、同じURLを引き続き使用できます。これは、`filepath` API属性を使用して、[リンクの作成](../../../api/releases/links.md#create-a-release-link)または[更新](../../../api/releases/links.md#update-a-release-link)中に定義されます。

URLの形式:

```plaintext
https://host/namespace/project/-/releases/:release/downloads:filepath
```

たとえば、`gitlab.com`の`gitlab-org`ネームスペースと`gitlab-runner`プロジェクトにある`v16.9.0-rc2`リリースのアセットがある場合:

```json
{
  "name": "linux amd64",
  "filepath": "/binaries/gitlab-runner-linux-amd64",
  "url": "https://gitlab-runner-downloads.s3.amazonaws.com/v16.9.0-rc2/binaries/gitlab-runner-linux-amd64",
  "link_type": "other"
}
```

このアセットには、次の直接リンクがあります。:

```plaintext
https://gitlab.com/gitlab-org/gitlab-runner/-/releases/v16.9.0-rc2/downloads/binaries/gitlab-runner-linux-amd64
```

アセットの物理的な場所はいつでも変更でき、直接リンクは変更されません。

リリースがプライベートの場合は、`api`または`read_api`スコープのいずれかを持つパーソナルアクセストークンを、`private_token`クエリパラメータまたは`HTTP_PRIVATE_TOKEN`ヘッダーを使用してリクエストを行うときに指定する必要があります。次に例を示します: 

```shell
curl --location --output filename "https://gitlab.example.com/my-group/my-project/-/releases/myrelease/downloads</path-to-file>?private_token=<your_access_token>"
curl --location --output filename --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/my-group/my-project/-/releases/myrelease/downloads</path-to-file>
```

#### 最新のリリースアセットへの永続的なリンク {#permanent-links-to-latest-release-assets}

[リリースの永続的なアセットへのリンク](#permanent-links-to-release-assets)の`filepath`を、[最新のリリースへの永続的なリンク](_index.md#permanent-link-to-latest-release)と組み合わせて使用できます。`filepath`は、スラッシュ（`/`）で始める必要があります。

URLの形式:

```plaintext
https://host/namespace/project/-/releases/permalink/latest/downloads:filepath
```

この形式を使用して、最新のリリースからのアセットへの永続的なリンクを提供できます。

たとえば、`gitlab.com`の`gitlab-org`ネームスペースと`gitlab-runner`プロジェクトにある`v16.9.0-rc2`最新のリリースの[`filepath`](../../../api/releases/links.md#create-a-release-link)を持つアセットがある場合:

```json
{
  "name": "linux amd64",
  "filepath": "/binaries/gitlab-runner-linux-amd64",
  "url": "https://gitlab-runner-downloads.s3.amazonaws.com/v16.9.0-rc2/binaries/gitlab-runner-linux-amd64",
  "link_type": "other"
}
```

このアセットには、次の直接リンクがあります。:

```plaintext
https://gitlab.com/gitlab-org/gitlab-runner/-/releases/permalink/latest/downloads/binaries/gitlab-runner-linux-amd64
```

#### リンクの種類 {#link-types}

リンクの4つのタイプは、「手順書」、「パッケージ」、「画像」、「その他」です。`link_type`パラメータは、次の4つの値のいずれかを受け入れます。:

- `runbook`
- `package`
- `image`
- `other`（デフォルト）

このフィールドはURLに影響を与えず、プロジェクトのリリースページでの視覚的な目的にのみ使用されます。

#### バイナリを添付するための汎用パッケージの使用 {#use-a-generic-package-for-attaching-binaries}

[汎用パッケージ](../../packages/generic_packages/_index.md)を使用して、リリースまたはタグパイプラインからのアーティファクトを保存できます。これは、個々のリリースエントリにバイナリファイルを添付するためにも使用できます。基本的には、次のことを行う必要があります。:

1. [アアーティファクトを汎用パッケージレジストリにプッシュします](../../packages/generic_packages/_index.md#publish-a-package)。
1. [パッケージリンクをリリースに添付します](#links)。

次の例では、リリースアセットを生成し、汎用パッケージとして公開してから、リリースを作成します。:

```yaml
stages:
  - build
  - upload
  - release

variables:
  # Package version can only contain numbers (0-9), and dots (.).
  # Must be in the format of X.Y.Z, and should match the /\A\d+\.\d+\.\d+\z/ regular expression.
  # See https://docs.gitlab.com/ee/user/packages/generic_packages/#publish-a-package-file
  PACKAGE_VERSION: "1.2.3"
  DARWIN_AMD64_BINARY: "myawesomerelease-darwin-amd64-${PACKAGE_VERSION}"
  LINUX_AMD64_BINARY: "myawesomerelease-linux-amd64-${PACKAGE_VERSION}"
  PACKAGE_REGISTRY_URL: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/myawesomerelease/${PACKAGE_VERSION}"

build:
  stage: build
  image: alpine:latest
  rules:
    - if: $CI_COMMIT_TAG
  script:
    - mkdir bin
    - echo "Mock binary for ${DARWIN_AMD64_BINARY}" > bin/${DARWIN_AMD64_BINARY}
    - echo "Mock binary for ${LINUX_AMD64_BINARY}" > bin/${LINUX_AMD64_BINARY}
  artifacts:
    paths:
      - bin/

upload:
  stage: upload
  image: curlimages/curl:latest
  rules:
    - if: $CI_COMMIT_TAG
  script:
    - |
      curl --header "JOB-TOKEN: ${CI_JOB_TOKEN}" --upload-file bin/${DARWIN_AMD64_BINARY} "${PACKAGE_REGISTRY_URL}/${DARWIN_AMD64_BINARY}"
    - |
      curl --header "JOB-TOKEN: ${CI_JOB_TOKEN}" --upload-file bin/${LINUX_AMD64_BINARY} "${PACKAGE_REGISTRY_URL}/${LINUX_AMD64_BINARY}"

release:
  # Caution, as of 2021-02-02 these assets links require a login, see:
  # https://gitlab.com/gitlab-org/gitlab/-/issues/299384
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  rules:
    - if: $CI_COMMIT_TAG
  script:
    - |
      glab release create "$CI_COMMIT_TAG" --name "Release $CI_COMMIT_TAG" \
        --assets-links="[{\"name\":\"${DARWIN_AMD64_BINARY}\",\"url\":\"${PACKAGE_REGISTRY_URL}/${DARWIN_AMD64_BINARY}\"},{\"name\":\"${LINUX_AMD64_BINARY}\",\"url\":\"${PACKAGE_REGISTRY_URL}/${LINUX_AMD64_BINARY}\"}]"
```

PowerShellユーザーは、`release-cli`に渡す前に、`--assets-link`および`ConvertTo-Json`の`` ` ``（バックティック）を使用して、JSON文字列内の二重引用符`"`をエスケープする必要がある場合があります。次に例を示します: 

```yaml
release:
  script:
    - $env:assets = "[{`"name`":`"MyFooAsset`",`"url`":`"https://gitlab.com/upack/artifacts/download/$env:UPACK_GROUP/$env:UPACK_NAME/$($env:GitVersion_SemVer)?contentOnly=zip`"}]"
    - $env:assetsjson = $env:assets | ConvertTo-Json
    - glab release create $env:CI_COMMIT_TAG --name "Release $env:CI_COMMIT_TAG" --notes "Release $env:CI_COMMIT_TAG" --ref $env:CI_COMMIT_TAG --assets-links=$env:assetsjson
```

{{< alert type="note" >}}

[ジョブアーティファクト](../../../ci/jobs/job_artifacts.md)リンクをリリースに直接アタッチすることはお勧めしません。アーティファクトは一時的なものであり、同じパイプラインでデータを渡すために使用されるためです。これは、それらが期限切れになるか、誰かが手動で削除する可能性があることを意味します。

{{< /alert >}}

### 新規および合計機能の数 {#number-of-new-and-total-features}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/releases)では、プロジェクト内の新規および合計機能の数を表示できます。

![GitLabリリースに含まれる新規および合計機能の数を示すバッジ。](img/feature_count_v14_6.png "リリースに含まれる機能の数")

合計は[shields](https://shields.io/)に表示され、[`www-gitlab-com`リポジトリのRakeタスク](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/lib/tasks/update_gitlab_project_releases_page.rake)によってリリースごとに生成されます。

| 項目             | 式                                                                            |
|------------------|------------------------------------------------------------------------------------|
| `New features`   | プロジェクト内の単一リリースのすべての層にわたるリリース投稿の総数。 |
| `Total features` | プロジェクト内のすべてのリリースについて、逆の順序でのリリース投稿の総数。     |

カウントはライセンス層別にも表示されます。

| 項目             | 式                                                                                             |
|------------------|-----------------------------------------------------------------------------------------------------|
| `New features`   | プロジェクト内の単一リリースの単一層にわたるリリース投稿の総数。              |
| `Total features` | プロジェクト内のすべてのリリースについて、単一層にわたるリリース投稿の総数（逆順）。 |

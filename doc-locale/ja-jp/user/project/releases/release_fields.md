---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: リリースフィールド
---

リリースを作成または編集する際に、以下のフィールドが利用できます。

## タイトル {#title}

リリースの作成または編集時に、**リリースタイトル**フィールドを使用してリリースタイトルをカスタマイズできます。タイトルが指定されていない場合、リリースのタグ名が代わりに使用されます。

## タグ名 {#tag-name}

リリースのタグ名には、リリースのバージョンを含める必要があります。GitLabはリリースに[セマンティックバージョニング](https://semver.org/)を使用しており、あなたもそれを使用できます。[GitLab Policy forバージョニング](../../../policy/maintenance.md#versioning)に詳述されているように、`(Major).(Minor).(Patch)`を使用します。

たとえば、GitLabバージョン`16.10.1`の場合:

- `16`はメジャーバージョンを表します。メジャーリリースは`16.0.0`でしたが、しばしば`16.0`と表記されます。
- `10`はマイナーバージョンを表します。マイナーリリースは`16.10.0`でしたが、しばしば`16.10`と表記されます。
- `1`はパッチ番号を表します。

バージョン番号のどの部分も複数桁にすることができます。たとえば、`16.10.11`です。

## リリースノートの説明 {#release-notes-description}

すべてのリリースには説明があります。好きなテキストを追加できますが、リリースの内容を説明するために変更履歴を含めることを検討してください。これにより、ユーザーは公開する各リリース間の差分を素早く確認できます。

[タグ付けmessages in Git](https://git-scm.com/book/en/v2/Git-Basics-Tagging)は、**Include tag message in the release notes**を選択することでリリースノートの説明に含めることができます。

説明は[Markdown](../../markdown.md)をサポートしています。

## リリースアセット {#release-assets}

リリースには以下の種類のアセットが含まれます:

- [ソースコード](#source-code)
- [関連資料へのリンク](#links)

### ソースコード {#source-code}

GitLabは、指定されたGitタグから、`zip`、`tar.gz`、`tar.bz2`、`tar`のアーカイブされたソースコードを自動的に生成します。これらのアセットは読み取り専用で、[ダウンロード可能](../repository/_index.md#download-repository-source-code)です。

### リンク {#links}

リンクとは、ドキュメント、ビルドされたバイナリ、またはその他の関連資料など、任意のものを指すことができるURLです。これらは、GitLabインスタンスからの内部リンクと外部リンクの両方になり得ます。URLは、`http`、`https`、または`ftp`のいずれかのスキームを使用する必要があります。アセットとしての各リンクには、以下の属性があります:

| 属性   | 必須 | 説明 |
|-------------|----------|-------------|
| `name`      | はい      | リンクの名前。 |
| `url`       | はい      | ファイルをダウンロードするためのURL。 |
| `filepath`  | いいえ       | `url`へのリダイレクトリンク。スラッシュ(`/`)で始まる必要があります。詳細については、[このセクション](#permanent-links-to-release-assets)を参照してください。 |
| `link_type` | いいえ       | ユーザーが`url`でダウンロードできるコンテンツの種類。詳細については、[このセクション](#link-types)を参照してください。 |

#### リリースアセットへのパーマリンク {#permanent-links-to-release-assets}

{{< history >}}

- GitLab 15.9で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/375489)、プライベートなリリースへのリンクは、パーソナルアクセストークンを使用してアクセスできます。

{{< /history >}}

リリースに関連付けられたアセットは、永続的なURLを介してアクセスできます。GitLabは常にこのURLを実際のアセットの場所にリダイレクトするため、アセットが別の場所に移動しても、同じURLを使い続けることができます。これは、[リンク作成](../../../api/releases/links.md#create-a-release-link)または[更新](../../../api/releases/links.md#update-a-release-link)中に、`filepath` API属性を使用して定義されます。

URLの形式:

```plaintext
https://host/namespace/project/-/releases/:release/downloads:filepath
```

たとえば、`gitlab.com`上の`gitlab-org`ネームスペースおよび`gitlab-runner`プロジェクト内の`v16.9.0-rc2`リリース用のアセットがある場合:

```json
{
  "name": "linux amd64",
  "filepath": "/binaries/gitlab-runner-linux-amd64",
  "url": "https://gitlab-runner-downloads.s3.amazonaws.com/v16.9.0-rc2/binaries/gitlab-runner-linux-amd64",
  "link_type": "other"
}
```

このアセットには直接リンクがあります:

```plaintext
https://gitlab.com/gitlab-org/gitlab-runner/-/releases/v16.9.0-rc2/downloads/binaries/gitlab-runner-linux-amd64
```

アセットの物理的な場所はいつでも変更される可能性がありますが、直接リンクは変更されません。

リリースがプライベートである場合、リクエストを行う際に`private_token`クエリパラメータまたは`HTTP_PRIVATE_TOKEN`ヘッダーを使用して、`api`または`read_api`スコープのいずれかのパーソナルアクセストークンを提供する必要があります。例: 

```shell
curl --location --output filename "https://gitlab.example.com/my-group/my-project/-/releases/myrelease/downloads/<path-to-file>?private_token=<your_access_token>"
curl --location --output filename --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/my-group/my-project/-/releases/myrelease/downloads/<path-to-file>"
```

#### 最新のリリースアセットへのパーマリンク {#permanent-links-to-latest-release-assets}

[リリースアセットへのパーマリンク](#permanent-links-to-release-assets)の`filepath`を、[最新のリリースへのパーマリンク](_index.md#permanent-link-to-latest-release)と組み合わせて使用できます。`filepath`はスラッシュ(`/`)で始まる必要があります。

URLの形式:

```plaintext
https://host/namespace/project/-/releases/permalink/latest/downloads:filepath
```

この形式を使用して、最新のリリースからのアセットへの永続的なリンクを提供できます。

たとえば、`gitlab.com`上の`gitlab-org`ネームスペースおよび`gitlab-runner`プロジェクト内の`v16.9.0-rc2`最新リリースの[`filepath`](../../../api/releases/links.md#create-a-release-link)を含むアセットがある場合:

```json
{
  "name": "linux amd64",
  "filepath": "/binaries/gitlab-runner-linux-amd64",
  "url": "https://gitlab-runner-downloads.s3.amazonaws.com/v16.9.0-rc2/binaries/gitlab-runner-linux-amd64",
  "link_type": "other"
}
```

このアセットには直接リンクがあります:

```plaintext
https://gitlab.com/gitlab-org/gitlab-runner/-/releases/permalink/latest/downloads/binaries/gitlab-runner-linux-amd64
```

#### リンクの種類 {#link-types}

リンクの種類は、「手順書」、「パッケージ」、「Image」、「Other」の4種類です。`link_type`パラメータは、以下の4つの値のいずれかを受け入れます:

- `runbook`
- `package`
- `image`
- `other`（デフォルト）

このフィールドはURLには影響せず、プロジェクトのリリースページでの視覚的な目的のみに使用されます。

#### バイナリを添付するための汎用パッケージを使用する {#use-a-generic-package-for-attaching-binaries}

[汎用パッケージ](../../packages/generic_packages/_index.md)を使用して、リリースまたはタグパイプラインからの任意のアーティファクトを保存でき、これらは個々のリリースエントリにバイナリファイルを添付するためにも使用できます。基本的には、次のことを行う必要があります:

1. [アーティファクトを汎用パッケージレジストリにプッシュ](../../packages/generic_packages/_index.md#publish-a-package)する。
1. [パッケージリンクをリリースに添付](#links)する。

以下の例は、リリースアセットを生成し、それを汎用パッケージとして公開してから、リリースを作成します:

```yaml
stages:
  - build
  - upload
  - release

variables:
  # Package version can only contain numbers (0-9), and dots (.).
  # Must be in the format of X.Y.Z, and should match the /\A\d+\.\d+\.\d+\z/ regular expression.
  # See https://docs.gitlab.com/user/packages/generic_packages/#publish-a-package
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

PowerShellユーザーは、`release-cli`に渡す前に、JSON文字列内の二重引用符`"`を、`--assets-link`および`ConvertTo-Json`のためにバックティック`` ` ``でエスケープする必要がある場合があります。例: 

```yaml
release:
  script:
    - $env:assets = "[{`"name`":`"MyFooAsset`",`"url`":`"https://gitlab.com/upack/artifacts/download/$env:UPACK_GROUP/$env:UPACK_NAME/$($env:GitVersion_SemVer)?contentOnly=zip`"}]"
    - $env:assetsjson = $env:assets | ConvertTo-Json
    - glab release create $env:CI_COMMIT_TAG --name "Release $env:CI_COMMIT_TAG" --notes "Release $env:CI_COMMIT_TAG" --ref $env:CI_COMMIT_TAG --assets-links=$env:assetsjson
```

> [!note]
> [ジョブアーティファクト](../../../ci/jobs/job_artifacts.md)リンクをリリースに直接添付することは推奨されません。なぜなら、アーティファクトは一時的なものであり、同じパイプライン内でデータを渡すために使用されるためです。これは、それらが期限切れになるか、誰かが手動で削除する可能性があるというリスクを意味します。

### 新規および合計機能の数 {#number-of-new-and-total-features}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/releases)では、プロジェクト内の新規および合計機能の数を表示できます。

![GitLabリリースにおける新規機能と合計機能の数を示すバッジ。](img/feature_count_v14_6.png "リリースにおける機能の数")

合計は[shields](https://shields.io/)に表示され、[`www-gitlab-com`リポジトリ内のRakeタスク](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/lib/tasks/update_gitlab_project_releases_page.rake)によってリリースごとに生成されます。

| 項目             | 計算式                                                                            |
|------------------|------------------------------------------------------------------------------------|
| `New features`   | プロジェクト内の単一のリリースに対するすべてのティアにわたるリリース投稿の総数。 |
| `Total features` | プロジェクト内のすべてのリリースに対するリリース投稿の総数を逆順でカウント。     |

これらの数は、ライセンスティアごとにも表示されます。

| 項目             | 計算式                                                                                             |
|------------------|-----------------------------------------------------------------------------------------------------|
| `New features`   | プロジェクト内の単一のリリースに対する単一のティアにわたるリリース投稿の総数。              |
| `Total features` | プロジェクト内のすべてのリリースに対する単一のティアにわたるリリース投稿の総数を逆順でカウント。 |

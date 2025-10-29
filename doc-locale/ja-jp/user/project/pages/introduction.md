---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pagesの設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Pagesには、静的サイトのデプロイと表示をカスタマイズするための設定オプションがあります。Pagesの設定では、次のことができます:

- 403応答と404応答にカスタムエラーページを提供する。
- `_redirects`ファイルを介してURLリダイレクトを設定する。
- CI/CDルールを使用して、任意のブランチからPagesをデプロイする。
- 事前に圧縮されたアセットを提供してページの読み込みを速くする。
- サイトの公開元となるフォルダーをカスタマイズする。
- サイトの一意のドメインを生成および管理する。

このドキュメントでは、GitLab Pagesサイトで利用可能な設定と設定オプションについて説明します。Pagesの概要については、[GitLab Pages](_index.md)を参照してください。

## GitLab Pagesの要件 {#gitlab-pages-requirements}

簡単に言うと、GitLab Pagesでウェブサイトをアップロードするために必要なものは次のとおりです:

1. インスタンスのドメイン: GitLab Pagesに使用されるドメイン名（管理者に確認してください）。
1. GitLab CI/CD: リポジトリのルートディレクトリにある、[`pages`](../../../ci/yaml/_index.md#pages)という名前の特定のジョブを含む`.gitlab-ci.yml`ファイル。
1. プロジェクトに対してGitLab Runnerが有効になっている。

## GitLab.comのGitLab Pages {#gitlab-pages-on-gitlabcom}

ウェブサイトのホスティングに[GitLab.comのGitLab Pages](#gitlab-pages-on-gitlabcom)を使用している場合は、次のようになります:

- GitLab.comのGitLab Pagesのドメイン名は、`gitlab.io`です。
- カスタムドメインとTLSのサポートが有効になっています。
- インスタンスRunnerはデフォルトで有効になっており、無料で提供され、ウェブサイトのビルドに使用できます。必要に応じて、Runnerを自分で持ち込むこともできます。

## プロジェクトの例 {#example-projects}

プロジェクトの例の完全なリストについては、[GitLab Pagesグループ](https://gitlab.com/groups/pages)を参照してください。コントリビュートを歓迎します。

## カスタムエラーコードページ {#custom-error-codes-pages}

`403.html`ファイルと`404.html`ファイルを`public/`ディレクトリのルートディレクトリに作成することで、`403`および`404`のエラーページを自分で用意できます。通常、これはプロジェクトのルートディレクトリですが、静的サイトジェネレーターの設定によっては異なる場合があります。

`404.html`の場合、複数のシナリオがあります。次に例を示します:

- プロジェクトのPages（`/project-slug/`で提供）を使用していて、`/project-slug/non/existing_file`にアクセスしようとした場合、GitLab Pagesは最初に`/project-slug/404.html`、次に`/404.html`を表示しようとします。
- ユーザーまたはグループのPages（`/`で提供）を使用していて、`/non/existing_file`にアクセスしようとした場合、GitLab Pagesは`/404.html`を表示しようとします。
- カスタムドメインを使用していて、`/non/existing_file`にアクセスしようとした場合、GitLab Pagesは`/404.html`のみを表示しようとします。

## GitLab Pagesでのリダイレクト {#redirects-in-gitlab-pages}

`_redirects`ファイルを使用して、サイトのリダイレクトを設定できます。詳細については、[GitLab Pagesのリダイレクトの作成方法](redirects.md)を参照してください。

## Pagesサイトを削除する {#delete-a-pages-site}

プロジェクトのすべてのPagesデプロイを完全に削除します。これは永続的なもので、元に戻すことはできません。

Pagesを削除するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. **Delete pages**（Pagesを削除）を選択します。

Pagesサイトはデプロイされなくなりました。このPagesサイトを再度デプロイするには、新しいパイプラインを実行します。

## サブドメインのサブドメイン {#subdomains-of-subdomains}

GitLabインスタンスのトップレベルドメイン（`*.example.io`）でPagesを使用する場合、サブドメインのサブドメインでHTTPSを使用することはできません。ネームスペースまたはグループ名にドットが含まれている場合（たとえば、`foo.bar`）、ドメイン`https://foo.bar.example.io`は機能**not**（しません）。

この制限は、[HTTP Over TLSプロトコル](https://www.rfc-editor.org/rfc/rfc2818#section-3.1)が原因です。HTTPをHTTPSにリダイレクトしない限り、HTTPページは機能します。

## プロジェクトとグループのGitLab Pages {#gitlab-pages-in-projects-and-groups}

GitLab Pagesのウェブサイトは、プロジェクトでホストする必要があります。このプロジェクトは、[プライベート、内部、または公開](../../public_access.md)にすることができ、[グループ](../../group/_index.md)または[サブグループ](../../group/subgroups/_index.md)に属することができます。

[グループのウェブサイト](getting_started_part_one.md#user-and-group-website-examples)の場合、グループはトップレベルに配置する必要があり、サブグループは使用できません。

[プロジェクトのウェブサイト](getting_started_part_one.md#project-website-examples)の場合、最初にプロジェクトを作成し、`http(s)://namespace.example.io/project-path`でそのプロジェクトにアクセスできます。

## Pagesの特定の設定オプション {#specific-configuration-options-for-pages}

特定のユースケースに合わせてGitLab CI/CDをセットアップする方法を説明します。

### プレーンHTMLウェブサイトの`.gitlab-ci.yml` {#gitlab-ciyml-for-plain-html-websites}

リポジトリに次のファイルが含まれているとします:

```plaintext
├── index.html
├── css
│   └── main.css
└── js
    └── main.js
```

次に、以下の`.gitlab-ci.yml`の例では、プロジェクトのルートディレクトリから`public/`ディレクトリにすべてのファイルが移動されます。`.public`回避策は、`cp`が無限ループで`public/`をそれ自体にコピーしないようにします:

```yaml
create-pages:
  script:
    - mkdir .public
    - cp -r * .public
    - mv .public public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

以前のYAMLの例では、[ユーザー定義のジョブ名](_index.md#user-defined-job-names)を使用しています。

### 静的サイトジェネレーターの`.gitlab-ci.yml` {#gitlab-ciyml-for-a-static-site-generator}

[手順ガイド](getting_started/pages_from_scratch.md)については、こちらのドキュメントを参照してください。

### コードを含むリポジトリの`.gitlab-ci.yml` {#gitlab-ciyml-for-a-repository-with-code}

GitLab Pagesはデフォルトではブランチ/タグに依存せず、そのデプロイは`.gitlab-ci.yml`で指定した内容のみに依存することに注意してください。新しいコミットがページ専用のブランチにプッシュされるたびに、[`rules:if`](../../../ci/yaml/_index.md#rulesif)を使用して`pages`ジョブを制限できます。

そうすることで、プロジェクトのコードを`main`ブランチに保持し、孤立したブランチ（`pages`という名前にします）を使用して静的サイトジェネレーターサイトをホスティングできます。

次のようにして、新しい空のブランチを作成できます:

```shell
git checkout --orphan pages
```

この新しいブランチで行われる最初のコミットには親がなく、他のすべてのブランチとコミットから完全に切断された新しい履歴のルートになります。静的サイトジェネレーターのソースファイルを`pages`ブランチにプッシュします。

以下は、`.gitlab-ci.yml`のコピーです。最も重要な行は最後の行で、`pages`ブランチですべてを実行することを指定しています:

```yaml
create-pages:
  image: ruby:2.6
  script:
    - gem install jekyll
    - jekyll build -d public/
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  rules:
    - if: '$CI_COMMIT_REF_NAME == "pages"'
```

[`main`ブランチ](https://gitlab.com/pages/jekyll-branched/tree/main)に異なるファイルがあり、Jekyllのソースファイルが[`pages`ブランチ](https://gitlab.com/pages/jekyll-branched/tree/pages)にあり、`.gitlab-ci.yml`も含まれている例を参照してください。

以前のYAMLの例では、[ユーザー定義のジョブ名](_index.md#user-defined-job-names)を使用しています。

### 圧縮されたアセットの提供 {#serving-compressed-assets}

最新のほとんどのブラウザーは、圧縮形式でのファイルのダウンロードをサポートしています。これにより、ファイルサイズが削減され、ダウンロードのスピードが速くなります。

圧縮されていないファイルを提供する前に、Pagesは同じファイルが`.br`拡張子または`.gz`拡張子で存在するかどうかを確認します。存在し、ブラウザーが圧縮ファイルの受信をサポートしている場合、Pagesは圧縮されていないバージョンではなく、そのバージョンを提供します。

この機能を活用するには、Pagesにアップロードするアーティファクトに次の構造が必要です:

```plaintext
public/
├─┬ index.html
│ | index.html.br
│ └ index.html.gz
│
├── css/
│   └─┬ main.css
│     | main.css.br
│     └ main.css.gz
│
└── js/
    └─┬ main.js
      | main.js.br
      └ main.js.gz
```

この構造を実現するには、`.gitlab-ci.yml`Pagesジョブに次のような`script:`コマンドを含めます:

```yaml
create-pages:
  # Other directives
  script:
    # Build the public/ directory first
    - find public -type f -regex '.*\.\(htm\|html\|xml\|txt\|text\|js\|css\|svg\)$' -exec gzip -f -k {} \;
    - find public -type f -regex '.*\.\(htm\|html\|xml\|txt\|text\|js\|css\|svg\)$' -exec brotli -f -k {} \;
  pages: true  # specifies that this is a Pages job
```

ファイルを事前に圧縮し、両方のバージョンをアーティファクトに含めることで、Pagesはオンデマンドでファイルを圧縮することなく、圧縮されたコンテンツと圧縮されていないコンテンツの両方に対するリクエストに対応できます。

以前のYAMLの例では、[ユーザー定義のジョブ名](_index.md#user-defined-job-names)を使用しています。

### あいまいなURLの解決 {#resolving-ambiguous-urls}

GitLab Pagesは、拡張子を含まないURLのリクエストを受信した場合に、提供するファイルを仮定します。

Pagesサイトが次のファイルでデプロイされているとします:

```plaintext
public/
├── index.html
├── data.html
├── info.html
├── data/
│   └── index.html
└── info/
    └── details.html
```

Pagesは、いくつかの異なるURLを介してこれらの各ファイルに到達することをサポートしています。特に、URLがディレクトリのみを指定する場合、常に`index.html`ファイルを探します。URLが、存在しないファイルを参照しているが、URLに`.html`を追加すると存在するファイルになる場合は、代わりにそのファイルが提供されます。以下に、前のPagesサイトの場合に行われる動作の例を示します:

| URLパス             | HTTP応答 |
| -------------------- | ------------- |
| `/`                  | `200 OK`: `public/index.html` |
| `/index.html`        | `200 OK`: `public/index.html` |
| `/index`             | `200 OK`: `public/index.html` |
| `/data`              | `302 Found`: `/data/`にリダイレクト |
| `/data/`             | `200 OK`: `public/data/index.html` |
| `/data.html`         | `200 OK`: `public/data.html` |
| `/info`              | `302 Found`: `/info/`にリダイレクト |
| `/info/`             | `404 Not Found`エラーページ |
| `/info.html`         | `200 OK`: `public/info.html` |
| `/info/details`      | `200 OK`: `public/info/details.html` |
| `/info/details.html` | `200 OK`: `public/info/details.html` |

`public/data/index.html`が存在する場合、`/data`と`/data/`両方のURLパスで、`public/data.html`ファイルよりも優先されます。

## デフォルトフォルダーをカスタマイズする {#customize-the-default-folder}

{{< history >}}

- GitLab 16.1で`FF_CONFIGURABLE_ROOT_DIR` Pagesフラグとともに[導入](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/859)されました。デフォルトでは無効になっています。
- GitLab 16.1の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1073)。
- GitLab 16.2の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/890)になりました。
- GitLab 17.9で、`publish`プロパティに渡す際に変数を利用できるように[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/500000)。
- GitLab 17.9で、`publish`プロパティが`pages`キーワードの下に[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)されました。
- GitLab 17.10で、`pages.publish`パスが`artifacts:paths`に自動的に[付加](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)されるようになりました。

{{< /history >}}

デフォルトでは、Pagesはビルドファイルで`public`という名前のフォルダーを探して公開します。

そのフォルダー名を他の値に変更するには、`.gitlab-ci.yml`の`deploy-pages`ジョブ設定に`pages.publish`プロパティを追加します。

次の例では、代わりに`dist`という名前のフォルダーを公開します:

```yaml
create-pages:
  script:
    - npm run build
  pages:  # specifies that this is a Pages job
    publish: dist
```

以前のYAMLの例では、[ユーザー定義のジョブ名](_index.md#user-defined-job-names)を使用しています。

`pages.publish`フィールドで変数を使用する方法については、[`pages.publish`](../../../ci/yaml/_index.md#pagespublish)を参照してください。

Pagesはアーティファクトを使用してサイトのファイルを保存するため、`pages.publish`の値は[`artifacts:paths`](../../../ci/yaml/_index.md#artifactspaths)に自動的に付け加えられます。前の例は、以下と同等です:

```yaml
create-pages:
  script:
    - npm run build
  pages:
    publish: dist
  artifacts:
    paths:
      - dist
```

{{< alert type="warning" >}}

トップレベルキーワード`publish`はGitLab 17.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/519499)になりました。現在は`pages`キーワードの下にネストされた状態にする必要があります。

{{< /alert >}}

## GitLab Pagesの一意のドメインを再生成する {#regenerate-unique-domain-for-gitlab-pages}

{{< history >}}

- GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481746)されました。

{{< /history >}}

GitLab Pagesサイトの専任のドメインを再生成できます。

ドメインが再生成されると、以前のURLはアクティブではなくなります。古いURLにアクセスしようとすると、`404`エラーが表示されます。

前提要件

- プロジェクトのメンテナーロール以上を持っている必要があります。
- プロジェクトのPages設定で、**一意のドメインを使用**の設定を[有効にする](_index.md#unique-domains)必要があります。

GitLab Pagesサイトの専任のドメインを再生成するには:

1. 左側のサイドバーで、**デプロイ** > **Pages**を選択します。
1. **ページへアクセス**の横にある**一意のドメインを再生成**を押します。
1. GitLabは、Pagesサイトの新しい一意のドメインを生成します。

## 既知の問題 {#known-issues}

既知の問題のリストについては、GitLabの[公開イシュートラッカー](https://gitlab.com/gitlab-org/gitlab/-/issues?label_name[]=Category%3APages)を参照してください。

## トラブルシューティング {#troubleshooting}

### GitLab PagesサイトのURLにアクセスするときの404エラー {#404-error-when-accessing-a-gitlab-pages-site-url}

この問題は、ほとんどの場合、公開ディレクトリに`index.html`ファイルがないことが原因で発生します。Pagesサイトをデプロイした後に404エラーが発生した場合は、公開ディレクトリに`index.html`ファイルが含まれていることを確認します。ファイルに`test.html`などの異なる名前が含まれている場合でも、Pagesサイトにアクセスできますが、フルパスが必要になります。たとえば、`https//group-name.pages.example.com/project-slug/test.html`のようになります。

公開ディレクトリの内容は、最新のパイプラインから[アーティファクトを閲覧](../../../ci/jobs/job_artifacts.md#download-job-artifacts)することで確認できます。

公開ディレクトリにリストされているファイルには、プロジェクトのPages URLからアクセスできます。

404は、権限が正しくないことにも関連している可能性があります。[Pagesアクセス制御](pages_access_control.md)が有効になっていて、ユーザーがPages URLにアクセスして404応答を受け取った場合、サイトを表示する権限がユーザーにない可能性があります。これを修正するには、ユーザーがプロジェクトのメンバーであることを確認します。

### 壊れた相対リンク {#broken-relative-links}

GitLab Pagesは、拡張子のないURLをサポートしています。ただし、[イシュー#354](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/354)で説明されている問題により、拡張子のないURLがフォワードスラッシュ（`/`）で終わる場合、ページの相対リンクが壊れます。

この問題を解決するには:

- Pagesサイトを指すURLに拡張子が含まれているか、または末尾のスラッシュが含まれていないことを確認します。
- 可能であれば、サイトで絶対URLのみを使用してください。

### Safariでメディアコンテンツを再生できない {#cannot-play-media-content-on-safari}

Safariでは、メディアコンテンツを再生するために、ウェブサーバーが[Rangeリクエストヘッダー](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/CreatingVideoforSafarioniPhone/CreatingVideoforSafarioniPhone.html#//apple_ref/doc/uid/TP40006514-SW6)をサポートしている必要があります。GitLab PagesがHTTP Rangeリクエストをパスするには、`.gitlab-ci.yml`ファイルで次の2つの変数を使用する必要があります:

```yaml
create-pages:
  stage: deploy
  variables:
    FF_USE_FASTZIP: "true"
    ARTIFACT_COMPRESSION_LEVEL: "fastest"
  script:
    - echo "Deploying pages"
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  environment: production
```

`FF_USE_FASTZIP`変数は、[`ARTIFACT_COMPRESSION_LEVEL`](../../../ci/runners/configure_runners.md#artifact-and-cache-settings)に必要な[機能フラグ](https://docs.gitlab.com/runner/configuration/feature-flags.html#available-feature-flags)を有効にします。

以前のYAMLの例では、[ユーザー定義のジョブ名](_index.md#user-defined-job-names)を使用しています。

### 複数のブラウザータブでプライベートGitLab Pagesサイトにアクセスしたときの`401`エラー {#401-error-when-accessing-private-gitlab-pages-sites-in-multiple-browser-tabs}

事前の認証なしに、2つの異なるタブ形式でプライベートPages URLに同時にアクセスしようとすると、各タブ形式に対して2つの異なる`state`値が返されます。ただし、Pagesセッションでは、特定のクライアントに対して最新の`state`値のみが保存されます。このため、認証情報を送信した後、いずれかのタブで`401 Unauthorized`エラーが返されます。

`401`エラーを解決するには、ページを更新してください。

### `pages:deploy`ジョブの失敗 {#failing-pagesdeploy-job}

GitLab Pagesでデプロイするには、ルートコンテンツディレクトリに空でない`index.html`ファイルが含まれている必要があります。そうでない場合、`pages:deploy`ジョブは失敗します。

コンテンツディレクトリは、デフォルトで`public/`であるか、`pages.publish`ファイルで`.gitlab-ci.yml`キーワードで指定されたディレクトリです。

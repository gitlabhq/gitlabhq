---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pagesのデフォルトドメイン名とURL
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Pagesは、ネームスペースとプロジェクト名に基づいてデフォルトのドメイン名を提供します。これらのドメインは、次のとおりです:

- プロジェクトサイト、ユーザーサイト、およびグループサイトに対して予測可能なURLを生成します。
- GitLabの組織構造を反映した階層パスをサポートします。
- 有効にすると、自動リダイレクトで一意のドメイン名を作成します。
- カスタムドメイン名とSSL/TLS証明書でシームレスに動作します。
- ユーザー、グループ、およびサブグループのプロジェクト全体でスケールします。

このガイドでは、GitLab Pagesがドメイン名とURLをWebサイトに割り当てる方法と、それに応じて静的サイトジェネレーターを設定する方法について説明します。

## GitLab Pagesのデフォルトドメイン名 {#gitlab-pages-default-domain-names}

{{< history >}}

- GitLab 17.4で一意のドメインのURLが[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163523)され、短くなりました。

{{< /history >}}

独自のGitLabインスタンスを使用してGitLab Pagesでサイトをデプロイする場合は、Pagesワイルドカードドメインをシステム管理者にご確認ください。このガイドは、GitLab.com（`*.gitlab.io`）のPagesワイルドカードドメインを独自のドメインに置き換える場合は、どのGitLabインスタンスにも有効です。

GitLabでGitLab Pagesプロジェクトを設定すると、`namespace.example.io`のサブドメインで自動的にアクセスできるようになります。[`namespace`](../../namespace/_index.md)は、GitLab.comのユーザー名、またはこのプロジェクトを作成したグループ名で定義されます。GitLab Self-Managedの場合は、`example.io`をインスタンスのPagesドメインに置き換えます。GitLab.comの場合、Pagesドメインは`*.gitlab.io`です。

| GitLab Pagesの種類 | GitLabのプロジェクトのパスの例 | WebサイトのURL |
| -------------------- | ------------ | ----------- |
| ユーザーページ  | `username/username.example.io`  | `http(s)://username.example.io`  |
| グループページ | `acmecorp/acmecorp.example.io` | `http(s)://acmecorp.example.io` |
| ユーザーが所有するプロジェクトページ  | `username/my-website` | `http(s)://username.example.io/my-website` |
| グループが所有するプロジェクトページ | `acmecorp/webshop` | `http(s)://acmecorp.example.io/webshop`|
| サブグループが所有するプロジェクトページ | `acmecorp/documentation/product-manual` | `http(s)://acmecorp.example.io/documentation/product-manual`|

**一意のドメインを使用**設定が有効になっている場合、Pagesはフラット化されたプロジェクト名と6文字の一意のIDから一意のドメイン名を構築します。ユーザーは、これらのユニークドメインURLにブラウザをリダイレクトする`308 Permanent Redirect`ステータスを受け取ります。ブラウザは、このリダイレクトを次のようにキャッシュする可能性があります:

| GitLab Pagesの種類              | GitLabのプロジェクトのパスの例     | WebサイトのURL |
| --------------------------------- | --------------------------------------- | ----------- |
| ユーザーページ                        | `username/username.example.io`          | `http(s)://username-example-io-123456.example.io` |
| グループページ                       | `acmecorp/acmecorp.example.io`          | `http(s)://acmecorp-example-io-123456.example.io` |
| ユーザーが所有するプロジェクトページ     | `username/my-website`                   | `https://my-website-123456.gitlab.io/` |
| グループが所有するプロジェクトページ    | `acmecorp/webshop`                      | `http(s)://webshop-123456.example.io/` |
| サブグループが所有するプロジェクトページ | `acmecorp/documentation/product-manual` | `http(s)://product-manual-123456.example.io/` |

例のURLの`123456`は、6文字の一意のIDです。たとえば、一意のIDが`f85695`の場合、最後の例は`http(s)://product-manual-f85695.example.io/`です。

{{< alert type="warning" >}}

一般的なドメイン名とHTTPSで提供されるネームスペースに関する既知の[制限事項](introduction.md#subdomains-of-subdomains)がいくつかあります。そのセクションを必ずお読みください。

{{< /alert >}}

Pagesドメインを明確に理解するには、以下の例をお読みください。

{{< alert type="note" >}}

以下の例は、**一意のドメインを使用**設定を無効にしたことを示唆しています。無効にしていない場合は、前のテーブルを参照して、`example.io`を`gitlab.io`で置き換えてください。

{{< /alert >}}

### プロジェクトのWebサイトの例 {#project-website-examples}

- ユーザー名`john`で`blog`というプロジェクトを作成したので、プロジェクトのURLは`https://gitlab.com/john/blog/`になります。このプロジェクトでGitLab Pagesを有効にし、サイトをビルドした後、`https://john.gitlab.io/blog/`でアクセスできます。
- `websites`というすべてのWebサイトのグループを作成し、このグループのプロジェクトは`blog`と呼ばれます。プロジェクトのURLは`https://gitlab.com/websites/blog/`です。このプロジェクトでGitLab Pagesを有効にすると、サイトは`https://websites.gitlab.io/blog/`で利用できるようになります。
- エンジニアリング`engineering`という部署のグループ、すべてのドキュメントWebサイトのサブグループ`docs`を作成し、このサブグループのプロジェクトは`workflows`と呼ばれます。プロジェクトのURLは`https://gitlab.com/engineering/docs/workflows/`です。このプロジェクトでGitLab Pagesを有効にすると、サイトは`https://engineering.gitlab.io/docs/workflows`で利用できるようになります。

### ユーザーおよびグループのWebサイトの例 {#user-and-group-website-examples}

- ユーザー名`john`で、`john.gitlab.io`というプロジェクトを作成しました。プロジェクトのURLは`https://gitlab.com/john/john.gitlab.io`です。プロジェクトでGitLab Pagesを有効にすると、Webサイトは`https://john.gitlab.io`で公開されます。
- グループ`websites`で、`websites.gitlab.io`というプロジェクトを作成しました。プロジェクトのURLは`https://gitlab.com/websites/websites.gitlab.io`です。プロジェクトでGitLab Pagesを有効にすると、Webサイトは`https://websites.gitlab.io`で公開されます。

**General example**（一般的な例）:

- GitLab.comでは、プロジェクトサイトは常に`https://namespace.gitlab.io/project-slug`で利用できます。
- GitLab.comでは、ユーザーまたはグループのWebサイトは`https://namespace.gitlab.io/`で利用できます。
- GitLabインスタンスで、`gitlab.io`をPagesサーバーのドメインに置き換えます。システム管理者にこの情報を問い合わせてください。

## URLとベースURL {#urls-and-base-urls}

{{< alert type="note" >}}

`baseurl`オプションの名前は、静的サイトジェネレーターによって異なる場合があります。

{{< /alert >}}

すべての静的サイトジェネレーター（SSG）のデフォルト設定では、Webサイトが（サブ）ドメイン（`example.com`）の下にあることを想定しており、そのドメインのサブディレクトリ（`example.com/subdir`）にあることは想定していません。したがって、プロジェクトWebサイト（たとえば、`namespace.gitlab.io/project-slug`）を公開する場合は常に、静的サイトジェネレーターのドキュメントでこの設定（ベースURL）を探し、このパターンを反映するように設定する必要があります。

たとえば、Jekyllサイトの場合、`baseurl`はJekyll設定ファイル、`_config.yml`で定義されます。WebサイトのURLが`https://john.gitlab.io/blog/`の場合は、次のようにこの行を`_config.yml`に追加する必要があります:

```yaml
baseurl: "/blog"
```

反対に、[デフォルトの例](https://gitlab.com/pages)のいずれかをフォークした後にWebサイトをデプロイする場合、すべての例がプロジェクトWebサイトであるため、`baseurl`はすでにこの方法で設定されています。ユーザーまたはグループのWebサイトを作成する場合は、プロジェクトからこの設定を削除する必要があります。先ほど説明したJekyllの例では、Jekyllの`_config.yml`を次のように変更する必要があります:

```yaml
baseurl: ""
```

[プレーンHTMLの例](https://gitlab.com/pages/plain-html)を使用している場合は、`baseurl`を設定する必要はありません。

## カスタムドメイン {#custom-domains}

GitLab Pagesは、HTTPまたはHTTPSで提供されるカスタムドメインとサブドメインをサポートしています。詳細については、[GitLab PagesカスタムドメインとSSL/TLS証明書](custom_domains_ssl_tls_certification/_index.md)を参照してください。

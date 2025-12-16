---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pagesリダイレクト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Pagesでは、[Netlifyスタイル](https://docs.netlify.com/routing/redirects/#syntax-for-the-redirects-file)のHTTPリダイレクトを使用して、あるURLを別のURLに転送するルールを設定できます。

[Netlifyが提供するすべての特別なオプション](https://docs.netlify.com/routing/redirects/redirect-options/)がサポートされているわけではありません。

| 機能                                           | サポート対象              | 例 |
|---------------------------------------------------|------------------------|---------|
| [リダイレクト(`301`、`302`)](#redirects)            | {{< icon name="check-circle" >}}対応 | `/wardrobe.html /narnia.html 302` |
| [リライト(`200`)](#rewrites)                     | {{< icon name="check-circle" >}}対応 | `/* / 200` |
| [Splat](#splats)                                 | {{< icon name="check-circle" >}}対応 | `/news/*  /blog/:splat` |
| [プレースホルダー](#placeholders)                     | {{< icon name="check-circle" >}}対応 | `/news/:year/:month/:date /blog-:year-:month-:date.html` |
| リライト（`200`以外）                       | {{< icon name="dotted-circle" >}}対象外 | `/en/* /en/404.html 404` |
| クエリパラメータ                                  | {{< icon name="dotted-circle" >}}対象外 | `/store id=:id  /blog/:id  301` |
| 強制 ([シャドウイング](https://docs.netlify.com/routing/redirects/rewrites-proxies/#shadowing)) | {{< icon name="dotted-circle" >}}対象外 | `/app/  /app/index.html  200!` |
| [ドメインレベルのリダイレクト](#domain-level-redirects) | {{< icon name="check-circle" >}}対応 | `http://blog.example.com/* https://www.example.com/blog/:splat 301` |
| 国または言語によるリダイレクト                   | {{< icon name="dotted-circle" >}}対象外 | `/  /anz     302  Country=au,nz` |
| ロールによるリダイレクト                                  | {{< icon name="dotted-circle" >}}対象外 | `/admin/*  200!  Role=admin` |

{{< alert type="note" >}}

[マッチング動作テストケース](https://gitlab.com/gitlab-org/gitlab-pages/-/blob/master/internal/redirects/matching_test.go)は、GitLabがルールマッチングをどのように詳細に実装しているかを理解するための優れたリソースです。このテストケーススイートに含まれていないエッジケースに対するコミュニティからのコントリビュートをお待ちしています。

{{< /alert >}}

## リダイレクトを作成 {#create-redirects}

リダイレクトを作成するには、GitLab Pagesサイトの`public/`ディレクトリに`_redirects`という名前の設定ファイルを作成します。

- すべてのパスは、フォワードスラッシュ`/`で始まる必要があります。
- [ステータスコード](#http-status-codes)が指定されていない場合、`301`のデフォルトのステータスコードが適用されます。
- `_redirects`ファイルには、インスタンスレベルで設定された、ファイルサイズの制限とプロジェクトごとのルールの最大数があります。設定された最大数の中で最初に一致するルールのみが処理されます。デフォルトのファイルサイズの制限は64 KBで、デフォルトのルールの最大数は1,000です。
- GitLab Pagesサイトがデフォルトのドメイン名（`namespace.gitlab.io/project-slug`など）を使用している場合は、すべてのルールにパスをプレフィックスとして付ける必要があります:

  ```plaintext
  /project-slug/wardrobe.html /project-slug/narnia.html 302
  ```

- GitLab Pagesサイトが[カスタムドメイン](custom_domains_ssl_tls_certification/_index.md)を使用している場合は、プロジェクトパスのプレフィックスは不要です。たとえば、カスタムドメインが`example.com`の場合、`_redirects`ファイルは次のようになります:

  ```plaintext
  /wardrobe.html /narnia.html 302
  ```

## ファイルはリダイレクトをオーバーライドします {#files-override-redirects}

ファイルはリダイレクトよりも優先されます。ファイルがディスク上に存在する場合、GitLab Pagesはリダイレクトの代わりにそのファイルを提供します。たとえば、`hello.html`と`world.html`のファイルが存在し、`_redirects`ファイルに次の行が含まれている場合、`hello.html`が存在するため、リダイレクトは無視されます:

```plaintext
/project-slug/hello.html /project-slug/world.html 302
```

GitLabは、この動作を変更するためのNetlify [force option](https://docs.netlify.com/routing/redirects/rewrites-proxies/#shadowing)をサポートしていません。

## HTTPステータスコード {#http-status-codes}

ステータスコードが指定されていない場合は、`301`のデフォルトのステータスコードが適用されますが、独自のステータスコードを明示的に設定できます。次のHTTPコードがサポートされています:

- **301**: 永続的なリダイレクト。
- **302**: 一時的なリダイレクト。
- **200**: 成功したHTTPリクエストに対する標準的な応答。アドレスバーのURLを変更せずに、`to`ルールにコンテンツが存在する場合、Pagesはそのコンテンツを提供します。

## リダイレクト {#redirects}

リダイレクトを作成するには、`from`パス、`to`パス、および[HTTPステータスコード](#http-status-codes)を含むルールを追加します:

```plaintext
# 301 permanent redirect
/old/file.html /new/file.html 301

# 302 temporary redirect
/old/another_file.html /new/another_file.html 302
```

## リライト {#rewrites}

{{< history >}}

- GitLab 15.2の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/619)になりました。

{{< /history >}}

`200`のステータスコードを指定して、リクエストが`from`に一致した場合に`to`パスのコンテンツを提供します:

```plaintext
/old/file.html /new/file.html 200
```

このステータスコードは、[Splatルール](#splats)と組み合わせて使用​​して、URLを動的に書き換えることができます。

## ドメインレベルのリダイレクト {#domain-level-redirects}

{{< history >}}

- GitLab 16.8で`FF_ENABLE_DOMAIN_REDIRECT`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/936)されました。デフォルトでは無効になっています。
- GitLab 16.9で[GitLab.comで有効](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/merge_requests/3395)になりました。
- GitLab 16.10で[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1087)になりました。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1097)になりました。機能フラグ`FF_ENABLE_DOMAIN_REDIRECT`は削除されました。

{{< /history >}}

ドメインレベルのリダイレクトを作成するには、ドメインレベルのパス（`http://`または`https://`で始まる）を次のいずれかに追加します:

- `to`パスのみ。
- `from`と`to`のパス。

サポートされている[HTTPステータスコード](#http-status-codes)は、`301`と`302`です:

```plaintext
# 301 permanent redirect
http://blog.example.com/file_1.html https://www.example.com/blog/file_1.html 301
/file_2.html https://www.example.com/blog/file_2.html 301

# 302 temporary redirect
http://blog.example.com/file_3.html https://www.example.com/blog/file_3.html 302
/file_4.html https://www.example.com/blog/file_4.html 302
```

ドメインレベルのリダイレクトは、[Splatルール](#splats)（Splatプレースホルダーを含む）と組み合わせて使用​​して、URLパスを動的に書き換えることができます。

## Splat {#splats}

Splatとして知られる、その`from`パスにアスタリスク(`*`)を持つルールは、リクエストされたパスの先頭、中間、または末尾の何かに一致します。この例は、`/old/`の後の何かに一致し、`/new/file.html`に書き換えます:

```plaintext
/old/* /new/file.html 200
```

### Splatプレースホルダー {#splat-placeholders}

ルールの`from`パス内の`*`によって一致したコンテンツは、`:splat`プレースホルダーを使用して`to`パスに挿入できます:

```plaintext
/old/* /new/:splat 200
```

この例では、`/old/file.html`へのリクエストは、`200`ステータスコードで`/new/file.html`のコンテンツを提供します。

ルールの`from`パスに複数のSplatが含まれている場合、最初のSplat一致の値は、`to`パス内の`:splat`をすべて置き換えます。

### Splatマッチング動作 {#splat-matching-behavior}

Splatは「貪欲」であり、可能な限り多くの文字に一致します:

```plaintext
/old/*/file /new/:splat/file 301
```

この例では、ルールは`/old/a/b/c/file`を`/new/a/b/c/file`にリダイレクトします。

Splatは空の文字列にも一致するため、前のルールは`/old/file`を`/new/file`にリダイレクトします。

### ルート`index.html`へのすべてのリクエストを書き換えます {#rewrite-all-requests-to-a-root-indexhtml}

シングルページアプリケーション（SPA）は、クライアントサイドルートを使用して独自ルーティングを実行することがよくあります。これらのアプリケーションでは、ルーティングロジックをJavaScriptアプリケーションで処理できるように、ルート`index.html`へのすべてのリクエストを書き換えます。

`index.html`へのリクエストを書き換えるには、次のようにします:

1. この`_redirects`ルールを追加します:

   ```plaintext
   /* /index.html 200
   ```

1. シングルページアプリケーションを並行デプロイで使用できるようにするには、リダイレクトルールを編集して、パスのプレフィックスを含めます:

   ```plaintext
   /project/base/<prefix>/* /project/base/<prefix>/index.html 200
   ```

   `<prefix>`をパスプレフィックス値に置き換えます。

## プレースホルダー {#placeholders}

ルールでプレースホルダーを使用して、リクエストされたURLの一部に一致させ、新しいURLへの書き換えまたはリダイレクト時にこれらのテストケースを使用します。

プレースホルダーは、`:`文字と、`from`および`to`のパスの両方の文字の文字列（`[a-zA-Z]+`）が続く形式でフォーマットされます:

```plaintext
/news/:year/:month/:date/:slug /blog/:year-:month-:date-:slug 200
```

このルールは、`200`で`/blog/2021-08-12-file.html`のコンテンツを提供することにより、`/news/2021/08/12/file.html`のリクエストに応答するようにPagesに指示します。

### プレースホルダーマッチングの動作 {#placeholder-matching-behavior}

[Splat](#splats)と比較して、プレースホルダーが一致するコンテンツの量は制限されています。プレースホルダーは、フォワードスラッシュ（`/`）の間のテキストに一致するため、プレースホルダーを使用して単一のパスセグメントを照合します。

さらに、プレースホルダーは空の文字列と一致しません。次のようなルールは、`/old/file`のようなリクエストURLと一致**not**（しません）:

```plaintext
/old/:path /new/:path
```

## リダイレクトルールのデバッグ {#debug-redirect-rules}

リダイレクトが期待どおりに機能しない場合、またはリダイレクト構文を検証する場合は、`[your pages url]/_redirects`にアクセスしてください。`_redirects`ファイルは直接提供されませんが、ブラウザにはリダイレクトルールの番号付きリストと、ルールが有効か無効かが表示されます:

```plaintext
11 rules
rule 1: valid
rule 2: valid
rule 3: error: splats are not supported
rule 4: valid
rule 5: error: placeholders are not supported
rule 6: valid
rule 7: error: no domain-level redirects to outside sites
rule 8: error: url path must start with forward slash /
rule 9: error: no domain-level redirects to outside sites
rule 10: valid
rule 11: valid
```

## Netlify実装との違い {#differences-from-netlify-implementation}

サポートされているほとんどの`_redirects`ルールは、GitLabとNetlifyの両方で同じように動作します。ただし、いくつかの小さな違いがあります:

- **All rule URLs must begin with a slash**（すべてのルールURLはスラッシュで始まる必要があります）:

  Netlifyでは、URLがフォワードスラッシュで始まる必要はありません:

  ```plaintext
  # Valid in Netlify, invalid in GitLab
  */path /new/path 200
  ```

  GitLabは、すべてのURLがフォワードスラッシュで始まることを検証します。前の例の有効な同等テストケース:

  ```plaintext
  # Valid in both Netlify and GitLab
  /old/path /new/path 200
  ```

- **All placeholder values are populated**（すべてのプレースホルダーの値が入力された）:

  Netlifyは、`to`パスに表示されるプレースホルダー値のみを入力されたします:

  ```plaintext
  /old /new/:placeholder
  ```

  `/old`へのリクエストが指定されている場合:

  - Netlifyは`/new/:placeholder`にリダイレクトします（リテラルの`:placeholder`を使用）。
  - GitLabは`/new/`にリダイレクトします。

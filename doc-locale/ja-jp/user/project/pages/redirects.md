---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pagesリダイレクト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Pagesでは、[Netlifyスタイル](https://docs.netlify.com/routing/redirects/#syntax-for-the-redirects-file)のHTTPリダイレクトを使用して、あるURLを別のURLに転送するルールを構成できます。

[Netlifyが提供する特別なオプション](https://docs.netlify.com/routing/redirects/redirect-options/)のすべてがサポートされているわけではありません。

| 機能                                           | サポート対象              | 例 |
|---------------------------------------------------|------------------------|---------|
| [リダイレクト (`301`, `302`)](#redirects)            | {{< yes >}} | `/wardrobe.html /narnia.html 302` |
| [リライト (`200`)](#rewrites)                     | {{< yes >}} | `/* / 200` |
| [Splat](#splats)                                 | {{< yes >}} | `/news/*  /blog/:splat` |
| [プレースホルダー](#placeholders)                     | {{< yes >}} | `/news/:year/:month/:date /blog-:year-:month-:date.html` |
| リライト (`200`以外)                       | {{< no >}} | `/en/* /en/404.html 404` |
| クエリパラメータ                                  | {{< no >}} | `/store id=:id  /blog/:id  301` |
| 強制 ([シャドーイング](https://docs.netlify.com/routing/redirects/rewrites-proxies/#shadowing)) | {{< no >}} | `/app/  /app/index.html  200!` |
| [ドメインレベルリダイレクト](#domain-level-redirects) | {{< yes >}} | `http://blog.example.com/* https://www.example.com/blog/:splat 301` |
| 国または言語によるリダイレクト                   | {{< no >}} | `/  /anz     302  Country=au,nz` |
| ロールによるリダイレクト                                  | {{< no >}} | `/admin/*  200!  Role=admin` |

> [!note]
> [マッチング動作のテストケース](https://gitlab.com/gitlab-org/gitlab-pages/-/blob/master/internal/redirects/matching_test.go)は、GitLabがどのようにルールマッチングを詳細に実装しているかを理解するのに良い資料です。このテストスイートに含まれていないエッジケースに対するコミュニティのコントリビュートを歓迎します！

## リダイレクトを作成する {#create-redirects}

リダイレクトを作成するには、GitLab Pagesサイトの`public/`ディレクトリに`_redirects`という名前の設定ファイルを作成します。

- すべてのパスはスラッシュ`/`で始まる必要があります。
- [ステータスコード](#http-status-codes)が指定されていない場合、`301`のデフォルトステータスコードが適用されます。
- `_redirects`ファイルには、インスタンス用に構成されたファイルサイズ制限と、プロジェクトあたりのルール最大数が設定されています。設定された最大値内の最初の合致するルールのみが処理されます。デフォルトのファイルサイズ制限は64 KBで、デフォルトの最大ルール数は1,000です。
- あなたのGitLab Pagesサイトがデフォルトドメイン名 (`namespace.gitlab.io/project-slug`など) を使用している場合、すべてのルールに次のパスをプレフィックスとして付ける必要があります:

  ```plaintext
  /project-slug/wardrobe.html /project-slug/narnia.html 302
  ```

- GitLab Pagesサイトが[カスタムドメイン](custom_domains_ssl_tls_certification/_index.md)を使用している場合、プロジェクトのパスプレフィックスは不要です。たとえば、カスタムドメインが`example.com`の場合、`_redirects`ファイルは次のようになります:

  ```plaintext
  /wardrobe.html /narnia.html 302
  ```

## ファイルがリダイレクトをオーバーライドする {#files-override-redirects}

ファイルはリダイレクトよりも優先されます。ファイルがディスク上に存在する場合、GitLab Pagesはリダイレクトではなくそのファイルを配信します。たとえば、`hello.html`と`world.html`ファイルが存在し、`_redirects`ファイルに次の行が含まれている場合、`hello.html`が存在するため、リダイレクトは無視されます:

```plaintext
/project-slug/hello.html /project-slug/world.html 302
```

GitLabは、この動作を変更するためのNetlifyの[強制オプション](https://docs.netlify.com/routing/redirects/rewrites-proxies/#shadowing)をサポートしていません。

## HTTPステータスコード {#http-status-codes}

ステータスコードが指定されていない場合、`301`のデフォルトステータスコードが適用されますが、独自に明示的に設定することもできます。以下のHTTPコードがサポートされています:

- **301**: 恒久的なリダイレクト。
- **302**: 一時的なリダイレクト。
- **200**: 成功したHTTPリクエストに対する標準レスポンス。`to`ルール内のコンテンツが存在する場合、アドレスバーのURLを変更せずにPagesがそのコンテンツを提供します。

## リダイレクト {#redirects}

リダイレクトを作成するには、`from`パス、`to`パス、および[HTTPステータスコード](#http-status-codes)を含むルールを追加します:

```plaintext
# 301 permanent redirect
/old/file.html /new/file.html 301

# 302 temporary redirect
/old/another_file.html /new/another_file.html 302
```

## リライト {#rewrites}

`from`にリクエストが一致する場合、`to`パスのコンテンツを提供するには、`200`のステータスコードを指定します:

```plaintext
/old/file.html /new/file.html 200
```

このステータスコードは、[Splatルール](#splats)と組み合わせてURLを動的にリライトするために使用できます。

## ドメインレベルリダイレクト {#domain-level-redirects}

{{< history >}}

- GitLab 16.8で`FF_ENABLE_DOMAIN_REDIRECT`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/936)されました。デフォルトでは無効になっています。
- [GitLab.comで有効](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/merge_requests/3395)になりました (GitLab 16.9)。
- GitLab 16.10で[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1087)になりました。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1097)になりました。機能フラグ`FF_ENABLE_DOMAIN_REDIRECT`は削除されました。

{{< /history >}}

ドメインレベルリダイレクトを作成するには、ドメインレベルのパス (`http://`または`https://`で始まる) を次のいずれかに追​​加します:

- `to`パスのみ。
- `from`パスと`to`パス。

サポートされている[HTTPステータスコード](#http-status-codes)は`301`と`302`です:

```plaintext
# 301 permanent redirect
http://blog.example.com/file_1.html https://www.example.com/blog/file_1.html 301
/file_2.html https://www.example.com/blog/file_2.html 301

# 302 temporary redirect
http://blog.example.com/file_3.html https://www.example.com/blog/file_3.html 302
/file_4.html https://www.example.com/blog/file_4.html 302
```

ドメインレベルリダイレクトは、[Splatルール](#splats) (Splatプレースホルダーを含む) と組み合わせて、URLパスを動的にリライトするために使用できます。

## Splat {#splats}

`from`パスにアスタリスク (`*`) が含まれるルール (これはSplatとして知られています) は、リクエストされたパスの先頭、途中、または末尾の任意の項目と一致します。この例では、`/old/`の後に続くすべてに一致し、それを`/new/file.html`にリライトします:

```plaintext
/old/* /new/file.html 200
```

### Splatプレースホルダー {#splat-placeholders}

ルールの`from`パス内の`*`に一致するコンテンツは、`:splat`プレースホルダーを使用して`to`パスに挿入できます:

```plaintext
/old/* /new/:splat 200
```

この例では、`/old/file.html`へのリクエストに対し、`200`ステータスコードで`/new/file.html`のコンテンツが提供されます。

ルールの`from`パスに複数のSplatが含まれている場合、最初の一致するSplatの値が`to`パス内のすべての`:splat`sを置き換えます。

### Splatの一致動作 {#splat-matching-behavior}

Splatは「貪欲」で、できるだけ多くの文字に一致します:

```plaintext
/old/*/file /new/:splat/file 301
```

この例では、ルールは`/old/a/b/c/file`を`/new/a/b/c/file`にリダイレクトします。

Splatは空の文字列とも一致するため、前のルールは`/old/file`を`/new/file`にリダイレクトします。

### すべてのリクエストをルートの`index.html` {#rewrite-all-requests-to-a-root-indexhtml}

SPA（シングルページアプリケーション）は、クライアントサイドルートを使用して独自のルーティングを行うことがよくあります。これらのアプリケーションでは、ルーティングロジックをJavaScriptアプリケーションで処理できるように、すべてのリクエストをルートの`index.html`にリライトします。

`index.html`へのリクエストをリライトするには:

1. この`_redirects`ルールを追加します:

   ```plaintext
   /* /index.html 200
   ```

1. シングルページアプリケーションが並列デプロイで動作するようにするには、リダイレクトルールを編集してパスプレフィックスを含めます:

   ```plaintext
   /project/base/<prefix>/* /project/base/<prefix>/index.html 200
   ```

   `<prefix>`をパスプレフィックスの値に置き換えます。

## プレースホルダー {#placeholders}

ルール内のプレースホルダーを使用して、リクエストされたURLの一部に一致させ、これらのマッチを新しいURLへのリライトまたはリダイレクト時に使用します。

プレースホルダーは、`from`パスと`to`パスの両方で、`:`文字の後に文字列 (`[a-zA-Z]+`) が続く形式です:

```plaintext
/news/:year/:month/:date/:slug /blog/:year-:month-:date-:slug 200
```

このルールは、`/news/2021/08/12/file.html`へのリクエストに対し、`/blog/2021-08-12-file.html`のコンテンツを`200`で提供するようにPagesに指示します。

### プレースホルダーの一致動作 {#placeholder-matching-behavior}

[Splat](#splats)と比較して、プレースホルダーが一致するコンテンツの量はより制限されています。プレースホルダーはスラッシュ (`/`) の間のテキストに一致するため、単一のパスセグメントに一致させるにはプレースホルダーを使用します。

さらに、プレースホルダーは空文字列には一致しません。次のようなルールは、`/old/file`のようなリクエストURLには**not**:

```plaintext
/old/:path /new/:path
```

## リダイレクトルールをデバッグする {#debug-redirect-rules}

リダイレクトが期待通りに機能しない場合や、リダイレクト構文を確認したい場合は、`[your pages url]/_redirects`にアクセスしてください。`_redirects`ファイルは直接提供されませんが、ブラウザにリダイレクトルールが番号付きリストで表示され、そのルールが有効か無効かを示します:

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

## Netlifyの実装との違い {#differences-from-netlify-implementation}

ほとんどのサポートされている`_redirects`ルールは、GitLabとNetlifyの両方で同じように動作します。ただし、いくつかの小さな違いがあります:

- **All rule URLs must begin with a slash**:

  NetlifyはURLがスラッシュで始まることを必須としません:

  ```plaintext
  # Valid in Netlify, invalid in GitLab
  */path /new/path 200
  ```

  GitLabは、すべてのURLがスラッシュで始まることを検証する。前の例の有効な同等品は次のとおりです:

  ```plaintext
  # Valid in both Netlify and GitLab
  /old/path /new/path 200
  ```

- **All placeholder values are populated**:

  Netlifyは、`to`パスに表示されるプレースホルダー値のみを入力します:

  ```plaintext
  /old /new/:placeholder
  ```

  `/old`へのリクエストの場合:

  - Netlifyは`/new/:placeholder` (リテラルの`:placeholder`を含む) にリダイレクトします。
  - GitLabは`/new/`にリダイレクトします。

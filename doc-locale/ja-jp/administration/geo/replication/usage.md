---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geoサイトの使用
---

<!-- Please update EE::GitLab::GeoGitAccess::GEO_SERVER_DOCS_URL if this file is moved) -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[データベースのレプリケーションを設定し、Geoノードを構成した](../setup/_index.md)後、プライマリサイトと同様に、最寄りのGitLabサイトを使用します。

## Gitの操作 {#git-operations}

**セカンダリ**サイトに直接プッシュできます（HTTP、SSH、Git LFSを含む）。そのリクエストは代わりにプライマリサイトにプロキシされます。

**セカンダリ**サイトにプッシュするときに表示される出力の例:

```shell
$ git push
remote:
remote: This request to a Geo secondary node will be forwarded to the
remote: Geo primary node:
remote:
remote:   ssh://git@primary.geo/user/repo.git
remote:
Everything up-to-date
```

{{< alert type="note" >}}

[SSH](../../../user/ssh.md)の代わりにHTTPSを使用してセカンダリにプッシュする場合、`user:password@URL`のようにURLに認証情報を保存することはできません。代わりに、Unix系のオペレーティングシステムの場合は[`.netrc`ファイル](https://www.gnu.org/software/inetutils/manual/html_node/The-_002enetrc-file.html)、Windowsの場合は`_netrc`を使用できます。その場合、認証情報はプレーンテキストとして保存されます。より安全な方法で認証情報を保存する場合は、[Git Credential Storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)を使用できます。

{{< /alert >}}

## ウェブユーザーインターフェース {#web-user-interface}

**セカンダリ**サイトのWebユーザーインターフェースは読み取り/書き込み可能です。ユーザーとして、**プライマリ**サイトで許可されているすべてのアクションは、制限なしに**セカンダリ**サイトで実行できます。

**セカンダリ**サイトのWebインターフェースアクセスリクエストは、自動的かつ透過的に**プライマリ**サイトにプロキシされます。

## GeoセカンダリサイトからGo言語のモジュールをフェッチする {#fetch-go-modules-from-geo-secondary-sites}

Go言語のモジュールは、いくつかの制限付きで、セカンダリサイトからプルできます:

- Gitの設定（`insteadOf`を使用）は、Geoセカンダリサイトからデータをフェッチするために必要です。
- プライベートプロジェクトの場合、認証の詳細は`~/.netrc`で指定する必要があります。

詳細については、[Go言語のパッケージとしてプロジェクトを使用する](../../../user/project/use_project_as_go_package.md#fetch-go-modules-from-geo-secondary-sites)を参照してください。

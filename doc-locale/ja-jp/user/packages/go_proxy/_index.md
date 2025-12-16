---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabのGoプロキシ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 13.1で、`go_proxy`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/27376)されました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。[エピック3043](https://gitlab.com/groups/gitlab-org/-/epics/3043)を参照してください。

{{< /alert >}}

GitLab用Goプロキシを使用すると、GitLabのすべてのプロジェクトを[Goプロキシプロトコル](https://proxy.golang.org/)でフェッチできます。

GitLabのGoプロキシは[実験](../../../policy/development_stages_support.md)であるため、大規模なリポジトリでパフォーマンスの問題が発生する可能性があるため、本番環境での使用には適していません。[イシュー218083](https://gitlab.com/gitlab-org/gitlab/-/issues/218083)を参照してください。

Goプロキシが有効になっている場合でも、GitLabはパッケージレジストリにGoモジュールを表示しません。[イシュー213770](https://gitlab.com/gitlab-org/gitlab/-/issues/213770)を参照してください。

Goプロキシが使用する特定のAPIエンドポイントのドキュメントについては、[Go Proxy APIドキュメント](../../../api/packages/go_proxy.md)を参照してください。

## GoプロキシとしてGitLabを追加 {#add-gitlab-as-a-go-proxy}

GitLabをGoプロキシとして使用するには、Go 1.13以降を使用する必要があります。

利用可能なプロキシエンドポイントは、プロジェクトごとにモジュールをフェッチするためのものです: `/api/v4/projects/:id/packages/go`

GitLabからGoモジュールをフェッチするには、プロジェクト固有のエンドポイントを`GOPROXY`に追加します。

Goはエンドポイントをクエリし、デフォルトの動作に戻ります:

```shell
go env -w GOPROXY='https://gitlab.example.com/api/v4/projects/1234/packages/go,https://proxy.golang.org,direct'
```

この設定では、Goは次の順序で依存関係をフェッチします:

1. Goは、プロジェクト固有のGoプロキシからフェッチを試みます。
1. Goは、[`proxy.golang.org`](https://proxy.golang.org)からフェッチを試みます。
1. Goは、バージョン管理システムの操作（`git clone`、`svn checkout`など）で直接フェッチします。

`GOPROXY`が指定されていない場合、Goはステップ2と3に従います。これは、`GOPROXY`を`https://proxy.golang.org,direct`に設定することに対応します。`GOPROXY`にプロジェクト固有のエンドポイントのみが含まれている場合、Goはそのエンドポイントのみをクエリします。

Goの環境変数の設定方法の詳細については、[環境変数の設定](#set-environment-variables)を参照してください。

## プライベートプロジェクトからモジュールをフェッチ {#fetch-modules-from-private-projects}

`go`は、脆弱な接続を介した認証情報の送信をサポートしていません。次の手順は、GitLabがHTTPS用に設定されている場合にのみ機能します:

1. GitLab用のGoプロキシからフェッチするときに、HTTP基本認証認証情報を含めるようにGoを設定します。
1. パブリックチェックサムデータベースから、プライベートGitLabプロジェクトのチェックサムのダウンロードをスキップするようにGoを設定します。

### リクエスト認証を有効にする {#enable-request-authentication}

`api`または`read_api`のスコープが設定された[パーソナルアクセストークン](../../profile/personal_access_tokens.md)を作成します。

[`~/.netrc`](https://everything.curl.dev/usingcurl/netrc.html)ファイルを開き、次のテキストを追加します。`< >`の変数を自分の値に置き換えます。

無効なHTTP認証情報で`go get`リクエストを行うと、404エラーが表示されます。

{{< alert type="warning" >}}

`NETRC`という環境変数を使用すると、Goはその値をファイル名として使用し、`~/.netrc`を無視します。GitLab CIで`~/.netrc`を使用する場合は、環境変数名として`NETRC`を使用しないでください。

{{< /alert >}}

```plaintext
machine <url> login <username> password <token>
```

- `<url>`: GitLab URL（例：`gitlab.com`）。
- `<username>`: ユーザー名。
- `<token>`: パーソナルアクセストークン。

### チェックサムデータベースクエリを無効にする {#disable-checksum-database-queries}

Go 1.13以降で依存関係をダウンロードすると、フェッチされたソースはチェックサムデータベース`sum.golang.org`に対して検証されます。

フェッチされたソースのチェックサムがデータベースのチェックサムと一致しない場合、Goは依存関係をビルドしません。

プライベートモジュールは、`sum.golang.org`がプライベートモジュールのソースをフェッチできないため、ビルドに失敗します。そのため、チェックサムを提供できません。

このイシューを解決するには、`GONOSUMDB`をカンマ区切りのプライベートプロジェクトのリストに設定します。Goの環境変数の設定方法の詳細については、[環境変数の設定](#set-environment-variables)を参照してください。

たとえば、`gitlab.com/my/project`のチェックサムクエリを無効にするには、`GONOSUMDB`を設定します:

```shell
go env -w GONOSUMDB='gitlab.com/my/project,<previous value>'
```

## Goの使用 {#working-with-go}

Goでの依存関係の管理、または一般的なGoに慣れていない場合は、次のドキュメントを確認してください:

- [Go Modules参照](https://go.dev/ref/mod)
- [ドキュメント (`golang.org`)](https://go.dev/doc/)
- [Learn (`go.dev/learn`)](https://go.dev/learn/)

### 環境変数を設定する {#set-environment-variables}

Goは、環境変数を使用してさまざまな機能を制御します。これらの変数は、通常の方法で管理できます。ただし、Go 1.14では、Goの環境変数は、デフォルトで特別なGo環境ファイルである`~/.go/env`との間で読み取りおよび書き込みが行われます。

- `GOENV`がファイルに設定されている場合、Goは代わりにそのファイルとの間で読み取りおよび書き込みを行います。
- `GOENV`が設定されておらず、`GOPATH`が設定されている場合、Goは`$GOPATH/env`を読み取りおよび書き込みます。

Goの環境変数は`go env <var>`で読み取りでき、Go 1.14以降では`go env -w <var>=<value>`で書き込むことができます。例: `go env GOPATH`、`go env -w GOPATH=/go`。

### モジュールをリリースする {#release-a-module}

Goモジュールとモジュールのバージョンは、Git、SVN、Mercurialなどのソースリポジトリによって定義されます。モジュールとは、`go.mod`とGoファイルを含むリポジトリのことです。モジュールのバージョンは、バージョン管理システム (VCS) のタグ付けによって定義されます。

モジュールを公開するには、`go.mod`とソースファイルをVCSリポジトリにプッシュします。モジュールのバージョンを公開するには、VCSのタグをプッシュします。

---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトをGo言語パッケージとして使用する
description: Goモジュールとインポートの呼び出し。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 17.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161162)で、許可されていない`go get`リクエストに対して404エラーを返すように変更されました。

{{< /history >}}

前提要件: 

- サブグループ内のプライベートプロジェクトをGoパッケージとして使用するには、[Goリクエストを認証する](#authenticate-go-requests-to-private-projects)必要があります。認証されていないGoリクエストがあると、`go get`が失敗します。サブグループにないプロジェクトのGoリクエストを認証する必要はありません。

プロジェクトをGoパッケージとして使用するには、`go get`と`godoc.org`のディスカバリリクエストを使用します。メタヘッダーは以下を使用できます:

- [`go-import`](https://pkg.go.dev/cmd/go#hdr-Remote_import_paths)
- [`go-source`](https://github.com/golang/gddo/wiki/Source-Code-Links)

{{< alert type="note" >}}

無効なHTTP認証情報で`go get`リクエストを行うと、404エラーが表示されます。HTTP認証情報は、`~/.netrc` (MacOSおよびLinux)または`~/_netrc` (Windows)にあります。

{{< /alert >}}

## プライベートプロジェクトへのGoリクエストの認証 {#authenticate-go-requests-to-private-projects}

前提要件: 

- お使いのGitLabインスタンスは、HTTPSでアクセスできる必要があります。
- `read_api`スコープを持つ[パーソナルアクセストークン](../profile/personal_access_tokens.md)が必要です。

Goリクエストを認証するには、次の情報を含む[`.netrc`](https://everything.curl.dev/usingcurl/netrc.html)ファイルを作成します:

```plaintext
machine gitlab.example.com
login <gitlab_user_name>
password <personal_access_token>
```

Windowsでは、Goは`~/_netrc`の代わりに`~/.netrc`を読み取ります。

`go`コマンドは、脆弱な接続を介して認証情報を送信しません。Goによって行われたHTTPSリクエストは認証しますが、Gitを介して行われたリクエストは認証しません。

## Gitリクエストを認証 {#authenticate-git-requests}

Goがプロキシからモジュールをフェッチできないバージョン、Gitを使用します。Gitは`.netrc`ファイルを使用してリクエストを認証しますが、他の認証方法を設定できます。

次のいずれかのGitを設定します:

- 認証情報をリクエストURLに埋め込みます:

  ```shell
  git config --global url."https://${user}:${personal_access_token}@gitlab.example.com".insteadOf "https://gitlab.example.com"
  ```

- HTTPSの代わりにSSHを使用します:

  ```shell
  git config --global url."git@gitlab.example.com:".insteadOf "https://gitlab.example.com/"
  ```

## プライベートプロジェクトのGoモジュールのフェッチを無効にします {#disable-go-module-fetching-for-private-projects}

モジュールまたはパッケージをフェッチするには、Goは環境変数を使用します:

- `GOPRIVATE`
- `GONOPROXY`
- `GONOSUMDB`

フェッチを無効にする手順:

1. `GOPRIVATE`を無効にします:
   - 1つのプロジェクトのクエリを無効にするには、`GOPRIVATE=gitlab.example.com/my/private/project`を無効にします。
   - GitLab.comのすべてのプロジェクトのクエリを無効にするには、`GOPRIVATE=gitlab.example.com`を無効にします。
1. `GONOPROXY`でプロキシクエリを無効にします。
1. `GONOSUMDB`でチェックサムクエリを無効にします。

- モジュール名またはそのプレフィックスが`GOPRIVATE`または`GONOPROXY`にあるバージョン、Goはモジュールプロキシにクエリを実行しません。
- モジュール名またはそのプレフィックスが`GOPRIVATE`または`GONOSUMDB`にあるバージョン、Goはチェックサムデータベースにクエリを実行しません。

## プライベートサブグループへのGitリクエストを認証します {#authenticate-git-requests-to-private-subgroups}

Goモジュールが`gitlab.com/namespace/subgroup/go-module`のようなプライベートサブグループにあるバージョン、Git認証は機能しません。これは、`go get`がリポジトリパスを検出するために、認証されていないリクエストを行うために発生します。`.netrc`ファイルを使用したHTTP認証がないバージョン、GitLabは認証されていないユーザーに対してプロジェクトの存在を公開するセキュリティリスクを防ぐために、`gitlab.com/namespace/subgroup.git`で応答します。その結果、Goモジュールをダウンロードできません。

残念ながら、Goは`.netrc`以外にリクエスト認証の手段を提供していません。将来のバージョン、Goは任意の認証ヘッダーのサポートを追加する可能性があります。詳細については、[`golang/go#26232`](https://github.com/golang/go/issues/26232)を参照してください。

### 回避策: モジュール名で`.git`を使用します {#workaround-use-git-in-the-module-name}

`go get`リクエストをスキップして、Git認証を直接使用するようにGoに強制する方法がありますが、モジュール名の変更が必要です。[Goのドキュメントから](https://go.dev/ref/mod#vcs-find):

> モジュールパスにVCS修飾子(`.bzr`、`.fossil`、`.git`、`.hg`、`.svn`のいずれか)がパスコンポーネントの最後にあるバージョン、goコマンドは、そのパス修飾子までのすべてをリポジトリURLとして使用します。たとえば、モジュール`example.com/foo.git/bar`のバージョン、goコマンドはGitを使用して`example.com/foo.git`でリポジトリをダウンロードし、barサブディレクトリにモジュールがあることを期待します。

1. プライベートサブグループ内のGoモジュールの`go.mod`に移動します。
1. モジュール名に`.git`を追加します。たとえば、`module gitlab.com/namespace/subgroup/go-module`を`module gitlab.com/namespace/subgroup/go-module.git`に名前変更します。
1. このコミットとプッシュの変更。
1. このモジュールに依存するGoプロジェクトにアクセスして、`import`呼び出しを調整します。たとえば`import gitlab.com/namespace/subgroup/go-module.git`などです。

この変更後、Goモジュールは正しくフェッチされるはずです。たとえば`GOPRIVATE=gitlab.com/namespace/* go mod tidy`などです。

## GeoのセカンダリサイトからGoモジュールをフェッチします {#fetch-go-modules-from-geo-secondary-sites}

[Geo](../../administration/geo/_index.md)を使用して、セカンダリGeoサーバー上のGoモジュールを含むGitリポジトリにアクセスします。

SSHまたはHTTPを使用して、Geoセカンダリサーバーにアクセスできます。

### SSHを使用してGeoセカンダリサーバーにアクセスします {#use-ssh-to-access-the-geo-secondary-server}

SSHを使用してGeoセカンダリサーバーにアクセスするには:

1. クライアントでGitを再設定して、プライマリからセカンダリにトラフィックを送信します:

   ```shell
   git config --global url."git@gitlab-secondary.example.com".insteadOf "https://gitlab.example.com"
   git config --global url."git@gitlab-secondary.example.com".insteadOf "http://gitlab.example.com"
   ```

   - `gitlab.example.com`の場合は、プライマリサイトのドメイン名を使用します。
   - `gitlab-secondary.example.com`の場合は、セカンダリサイトのドメイン名を使用します。

1. クライアントがGitLabリポジトリへのSSHアクセス用にセットアップされていることを確認します。これはプライマリでテストでき、GitLabは公開キーをセカンダリにレプリケートします。

`go get`リクエストは、プライマリGeoサーバーへのHTTPトラフィックを生成します。モジュールのダウンロードが開始されるバージョン、`insteadOf`設定は、トラフィックをセカンダリGeoサーバーに送信します。

### HTTPを使用してGeoセカンダリにアクセスする {#use-http-to-access-the-geo-secondary}

セカンダリサーバーにレプリケートする永続アクセストークンを使用する必要があります。CI/CDジョブトークンを使用して、HTTPでGoモジュールをフェッチすることはできません。

HTTPを使用してGeoセカンダリサーバーにアクセスするには:

1. クライアントでGit `insteadOf`リダイレクトを追加します:

   ```shell
   git config --global url."https://gitlab-secondary.example.com".insteadOf "https://gitlab.example.com"
   ```

   - `gitlab.example.com`の場合は、プライマリサイトのドメイン名を使用します。
   - `gitlab-secondary.example.com`の場合は、セカンダリサイトのドメイン名を使用します。

1. [パーソナルアクセストークン](../profile/personal_access_tokens.md)を生成し、クライアントの`~/.netrc`ファイルに認証情報を追加します:

   ```shell
   machine gitlab.example.com login USERNAME password TOKEN
   machine gitlab-secondary.example.com login USERNAME password TOKEN
   ```

`go get`リクエストは、プライマリGeoサーバーへのHTTPトラフィックを生成します。モジュールのダウンロードが開始されるバージョン、`insteadOf`設定は、トラフィックをセカンダリGeoサーバーに送信します。

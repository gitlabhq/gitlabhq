---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アセットをプロキシ化する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

公開されているGitLabインスタンスを管理する場合、セキュリティ上の懸念事項として、イシューやコメント内の画像を参照することで、ユーザーのIPアドレスが盗まれる可能性があることが挙げられます。

たとえば、イシューの説明に`![An example image.](http://example.com/example.png)`を追加すると、画像が外部サーバーから読み込まれて表示されます。ただし、これにより、外部サーバーがユーザーのIPアドレスをログに記録することも可能になります。

この問題を軽減する方法の1つは、制御するサーバーに外部画像をプロキシすることです。

GitLabは、イシューやコメントで外部画像/ビデオ/オーディオをリクエストする際に、アセットプロキシサーバーを使用するように構成できます。これにより、悪意のある画像がフェッチされたときに、ユーザーのIPアドレスを公開しないようにすることができます。

現在、[cactus/go-camo](https://github.com/cactus/go-camo#how-it-works)を使用することをお勧めします。これは、ビデオ、オーディオのプロキシをサポートし、より構成可能であるためです。

## Camoサーバーのインストール {#installing-camo-server}

Camoサーバーは、プロキシとして機能するために使用されます。

アセットプロキシとしてCamoサーバーをインストールするには、次の手順に従います:

1. `go-camo`サーバーをデプロイします。役立つ手順は、[building cactus/go-camo](https://github.com/cactus/go-camo#building)にあります。

   {{< alert type="warning" >}}

   アセットプロキシサーバーは、正しいコンテンツセキュリティポリシーヘッダー（`go-camo`ヘッダーと並んで`form-action 'none'`など）を使用するように構成する必要があります。

   {{< /alert >}}

1. GitLabインスタンスが実行されていること、およびプライベートAPIトークンを作成したことを確認してください。APIを使用して、GitLabインスタンスのアセットプロキシ設定を構成します。例: 

   ```shell
   curl --request "PUT" "https://gitlab.example.com/api/v4/application/settings?\
   asset_proxy_enabled=true&\
   asset_proxy_url=https://proxy.gitlab.example.com&\
   asset_proxy_secret_key=<somekey>" \
   --header 'PRIVATE-TOKEN: <my_private_token>'
   ```

   次の設定を使用できます:

   | 属性                | 説明                                                                                                                          |
   |:-------------------------|:-------------------------------------------------------------------------------------------------------------------------------------|
   | `asset_proxy_enabled`    | アセットのプロキシを有効にします。有効にする場合は、`asset_proxy_url`が必要です。                                                                  |
   | `asset_proxy_secret_key` | アセットプロキシサーバーとの共有シークレット。                                                                                           |
   | `asset_proxy_url`        | アセットプロキシサーバーのURL。                                                                                                       |
   | `asset_proxy_whitelist`  | （非推奨: 代わりに`asset_proxy_allowlist`を使用）これらのドメインに一致するアセットはプロキシされません。ワイルドカードを使用できます。GitLabインストールURLは自動的に許可されます。         |
   | `asset_proxy_allowlist`  | これらのドメインに一致するアセットはプロキシされません。ワイルドカードを使用できます。GitLabインストールURLは自動的に許可されます。         |

1. 変更を有効にするには、サーバーを再起動します。アセットプロキシの値を変更するたびに、サーバーを再起動する必要があります。

## Camoサーバーの使用 {#using-the-camo-server}

Camoサーバーが実行され、GitLab設定を有効にすると、外部ソースを参照する画像、ビデオ、またはオーディオはCamoサーバーにプロキシされます。

たとえば、次はMarkdownの画像へのリンクです:

```markdown
![A GitLab logo.](https://about.gitlab.com/images/press/logo/jpg/gitlab-icon-rgb.jpg)
```

次に、結果として得られる可能性のあるソースリンクの例を示します:

```plaintext
http://proxy.gitlab.example.com/f9dd2b40157757eb82afeedbf1290ffb67a3aeeb/68747470733a2f2f61626f75742e6769746c61622e636f6d2f696d616765732f70726573732f6c6f676f2f6a70672f6769746c61622d69636f6e2d7267622e6a7067
```

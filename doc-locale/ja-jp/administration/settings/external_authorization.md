---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 外部認可コントロール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab PremiumからGitLab Freeに11.10で[移動](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/27056)しました。

{{< /history >}}

厳密に管理された環境では、プロジェクトの分類とユーザーアクセスに基づいてアクセスを許可する外部サービスによってアクセスポリシーを制御する必要がある場合があります。GitLabは、独自の定義されたサービスでプロジェクトの認可をチェックする方法を提供します。

外部サービスが設定されて有効になると、プロジェクトにアクセスしたときに、ユーザー情報とプロジェクトに割り当てられたラベルを使用して外部サービスにリクエストが送信されます。サービスが既知の応答で応答すると、結果は6時間キャッシュされます。

外部認可が有効な場合、GitLabはクロスプロジェクトデータをレンダリングするページと機能をさらにブロックします。これには以下が含まれます:

- ダッシュボード下のほとんどのページ（アクティビティ、マイルストーン、スニペット、割り当てられたマージリクエスト、割り当てられたイシュー、To-Doリスト）。
- 特定のグループの下（アクティビティ、コントリビュートアナリティクス、イシュー、イシューボード、ラベル、マイルストーン、マージリクエスト）。
- グローバル検索とグループ検索は無効になっています。

これは、外部認可サービスへの多数のリクエストを一度に実行するのを防ぐためです。

アクセスが許可または拒否されると、`external-policy-access-control.log`というログファイルに記録されます。GitLabが保持するログの詳細については、[Linuxパッケージドキュメント](https://docs.gitlab.com/omnibus/settings/logs/)を参照してください。

自己署名証明書でTLS認証を使用する場合、CA証明書はOpenSSLインストールによって信頼される必要があります。Linuxパッケージを使用してインストールされたGitLabを使用する場合、[Linuxパッケージドキュメント](https://docs.gitlab.com/omnibus/settings/ssl/)でカスタムCAをインストールする方法を学びます。または、`openssl version -d`を使用してカスタム証明書をインストールする場所を学びます。

## 設定 {#configuration}

外部認可サービスは、管理者によって有効にできます:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **外部認可**を展開する。
1. フィールドに入力します。
1. **変更を保存**を選択します。

### デプロイトークンとデプロイキーを使用した外部認可を許可する {#allow-external-authorization-with-deploy-tokens-and-deploy-keys}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/386656)されました。
- デプロイトークンがコンテナまたはパッケージレジストリにアクセスできなくなったことは、GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/387721)されました。

{{< /history >}}

インスタンスを設定して、[デプロイトークン](../../user/project/deploy_tokens/_index.md)または[デプロイキー](../../user/project/deploy_keys/_index.md)を使用したGit操作の外部認可を許可できます。

前提条件: 

- 外部認可には、サービスURLなしで分類ラベルを使用する必要があります。

デプロイトークンとキーを使用した認可を許可するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **外部認可**を展開する、そして:
   - サービスURLフィールドを空のままにします。
   - **外部認可でデプロイトークンとデプロイキーの使用を許可する**を選択します。
1. **変更を保存**を選択します。

> [!warning]
> 外部認可を有効にすると、デプロイトークンはコンテナまたはパッケージレジストリにアクセスできません。デプロイトークンを使用してこれらのレジストリにアクセスしている場合、この対策により、これらのトークンの使用はできなくなります。コンテナまたはパッケージレジストリでトークンを使用するには、外部認証を無効にします。

## GitLabが外部認可サービスに接続する方法 {#how-gitlab-connects-to-an-external-authorization-service}

GitLabがアクセスをリクエストすると、この本文を持つJSON POSTリクエストを外部サービスに送信します:

```json
{
  "user_identifier": "jane@acme.org",
  "project_classification_label": "project-label",
  "user_ldap_dn": "CN=Jane Doe,CN=admin,DC=acme",
  "identities": [
    { "provider": "ldap", "extern_uid": "CN=Jane Doe,CN=admin,DC=acme" },
    { "provider": "bitbucket", "extern_uid": "2435223452345" }
  ]
}
```

`user_ldap_dn`はオプションであり、ユーザーがLDAPを介してサインインした場合にのみ送信されます。

`identities`には、ユーザーに関連付けられているすべてのIDの詳細が含まれています。ユーザーに関連付けられているIDがない場合、これは空の配列です。

外部認可サービスがステータスコード200で応答すると、ユーザーにアクセスが許可されます。外部サービスがステータスコード401または403で応答すると、ユーザーはアクセスを拒否されます。いずれの場合でも、リクエストは6時間キャッシュされます。

アクセスを拒否する場合、`reason`をJSON本文でオプションで指定できます:

```json
{
  "reason": "You are not allowed access to this project."
}
```

200、401、または403以外のステータスコードもユーザーへのアクセスを拒否しますが、応答はキャッシュされません。

サービスがタイムアウトした（500ミリ秒後）場合、「External Policy Server did not respond」というメッセージが表示されます。

## 分類ラベル {#classification-labels}

プロジェクトの**設定** > **一般** > **General project settings**ページの「Classification label」ボックスで独自の分類ラベルを使用できます。プロジェクトに分類ラベルが指定されていない場合、[グローバル設定](#configuration)で定義されたデフォルトのラベルが使用されます。

すべてのプロジェクトページで、右上にラベルが表示されます。

![オーバーライドされた赤いラベルと開いたロックアイコンがプロジェクトの右上に表示されます。](img/classification_label_on_project_page_v14_8.png)

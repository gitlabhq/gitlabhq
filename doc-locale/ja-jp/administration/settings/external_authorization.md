---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 外部認可コントロール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 11.10でGitLab PremiumからGitLab Freeに[移行](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/27056)しました。

{{< /history >}}

高度に管理された環境では、プロジェクトの分類とユーザーアクセスに基づいてアクセスを許可する外部サービスによって、アクセス認可ポリシーが制御されることが必要になる場合があります。GitLabは、独自の定義されたサービスでプロジェクト認可をチェックする方法を提供します。

外部サービスが構成され、有効になっている場合、プロジェクトにアクセスすると、ユーザー情報とプロジェクトに割り当てられたプロジェクト分類ラベルを使用して、外部サービスにリクエストが送信されます。サービスが既知の応答で応答すると、結果は6時間キャッシュされます。

外部認可が有効になっている場合、GitLabは、クロスプロジェクトデータをレンダリングするページと機能もブロックします。これには以下が含まれます:

- ダッシュボード（アクティビティー、マイルストーン、スニペット、割り当てられたマージリクエスト、割り当てられたイシュー、To-Doリスト）の下のほとんどのページ。
- 特定のグループ（アクティビティー、コントリビューション分析、イシュー、イシューボード、ラベル、マイルストーン、マージリクエスト）の下。
- グローバル検索とグループ検索は無効になっています。

これは、外部認可サービスに対して一度に多数のリクエストを実行するのを防ぐためです。

アクセスが許可または拒否されるたびに、`external-policy-access-control.log`というログファイルに記録されます。GitLabが保持するログの詳細については、[Linuxパッケージのドキュメント](https://docs.gitlab.com/omnibus/settings/logs.html)を参照してください。

自己署名証明書でTLS認証を使用する場合、CA証明書はOpenSSLインストールによって信頼される必要があります。[Linuxパッケージのドキュメント](https://docs.gitlab.com/omnibus/settings/ssl/)を使用してインストールされたGitLabを使用する場合は、カスタム認証局をインストールする方法を学んでください。または、`openssl version -d`を使用してカスタム証明書をインストールする場所を確認してください。

## 設定 {#configuration}

外部認可サービスは、管理者が有効にできます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **外部認可**を展開します。
1. フィールドに入力します。
1. **変更を保存**を選択します。

### デプロイトークンとデプロイキーによる外部認可を許可する {#allow-external-authorization-with-deploy-tokens-and-deploy-keys}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/386656)されました。
- デプロイトークンがコンテナまたはパッケージレジストリにアクセスできなくなった措置は、GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/387721)されました。

{{< /history >}}

インスタンスを設定すると、[デプロイトークン](../../user/project/deploy_tokens/_index.md)または[デプロイキー](../../user/project/deploy_keys/_index.md)を使用して、Git操作の外部認可を許可できます。

前提要件: 

- 外部認可のために、サービスURLなしで分類ラベルを使用する必要があります。

デプロイトークンとキーによる認可を許可するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **外部認可**を展開し、以下を行います:
   - サービスURLフィールドを空のままにします。
   - **外部認可でのデプロイトークンとデプロイキーの使用を許可する**を選択します。
1. **変更を保存**を選択します。

{{< alert type="warning" >}}

外部認可を有効にすると、デプロイトークンはコンテナまたはパッケージレジストリにアクセスできなくなります。これらのレジストリへのアクセスにデプロイトークンを使用している場合、この対策により、それらのトークンの使用は中断されます。コンテナまたはパッケージレジストリでトークンを使用するには、外部認可を無効にします。

{{< /alert >}}

## GitLabが外部認可サービスに接続する方法 {#how-gitlab-connects-to-an-external-authorization-service}

GitLabがアクセスをリクエストすると、次の本文を含むJSON POSTリクエストが外部サービスに送信されます:

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

`user_ldap_dn`はオプションであり、ユーザーがLDAP経由でサインインしている場合にのみ送信されます。

`identities`には、ユーザーに関連付けられているすべてのIDの詳細が含まれています。これは、ユーザーに関連付けられているIDがない場合は、空の配列です。

外部認可サービスがステータスコード200で応答すると、ユーザーにアクセス権が付与されます。外部サービスがステータスコード401または403で応答すると、ユーザーはアクセスを拒否されます。いずれにせよ、リクエストは6時間キャッシュされます。

アクセスを拒否する場合、`reason`はJSON本文でオプションで指定できます:

```json
{
  "reason": "You are not allowed access to this project."
}
```

200、401、または403以外の他のステータスコードもユーザーへのアクセスを拒否しますが、応答はキャッシュされません。

サービスがタイムアウトした場合（500ミリ秒後）、「External Policy Server did not respond」というメッセージが表示されます。

## 分類ラベル {#classification-labels}

プロジェクトの**Settings > General > General project settings**（設定 > 一般 > 一般的なプロジェクト設定）ページの「分類ラベル」ボックスで、独自の分類ラベルを使用できます。プロジェクトで分類ラベルが指定されていない場合、[グローバル設定](#configuration)で定義されたデフォルトのラベルが使用されます。

すべてのプロジェクトページの右上隅に、ラベルが表示されます。

![赤いオーバーライドされたラベルと、開いたロックアイコンがプロジェクトの右上隅に表示されます。](img/classification_label_on_project_page_v14_8.png)

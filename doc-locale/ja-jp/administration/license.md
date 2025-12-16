---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Enterprise Edition（EE）をアクティブにする
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

新しいGitLabインスタンスをライセンスなしでインストールすると、Freeの機能のみが有効になります。GitLab Enterprise Edition（EE）の機能をさらに有効にするには、アクティベーションコードを使用してインスタンスをアクティブ化します。

## GitLab EEのアクティブ化 {#activate-gitlab-ee}

前提要件: 

- [サブスクリプション](https://about.gitlab.com/pricing/)を購入する必要があります。
- GitLab Enterprise Edition（EE）を実行している必要があります。
- インスタンスがインターネットに接続されている必要があります。

アクティベーションコードを使用してインスタンスをアクティブにするには、次の手順を実行します:

1. アクティベーションコード（24文字の英数字文字列）を以下からコピーします:
   - サブスクリプション確認メール。
   - [カスタマーポータル](https://customers.gitlab.com/customers/sign_in)の**Manage Purchases**（購入の管理）ページ。
1. インスタンスにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **サブスクリプション**を選択します。
1. **アクティベーションコード**にアクティベーションコードを貼り付けます。
1. 利用規約を読んで同意します。
1. **アクティブ化**を選択します。

サブスクリプションがアクティブ化されました。

### 複数のインスタンスでの1つのアクティベーションコードの使用 {#using-one-activation-code-for-multiple-instances}

ユーザーが次のいずれかに該当する場合、複数のGitLab Self-Managedインスタンスに対して単一のアクティベーションコードまたはライセンスキーを使用できます:

- ライセンスされた本番環境インスタンスと同一。
- ライセンスされた本番環境インスタンスのサブセット。

グループおよびプロジェクトでのユーザーの構成方法に関係なく、アクティベーションコードはこれらのインスタンスに対して有効です。

### スケールされたアーキテクチャの場合 {#for-scaled-architectures}

スケールされたアーキテクチャでインスタンスをアクティブ化するには:

- ライセンスファイルを1つのアプリケーションインスタンスのみにアップロードします。

ライセンスはデータベースに保存され、すべてのインスタンスにレプリケートされます。

### GitLab Geoの場合 {#for-gitlab-geo}

GitLab Geoの使用時にインスタンスをアクティブ化するには:

- プライマリGeoインスタンスにライセンスをアップロードします。

ライセンスはデータベースに保存され、すべてのインスタンスにレプリケートされます。

### オフライン環境の場合 {#for-offline-environments}

オフライン環境でインスタンスをアクティブ化するには:

- [ライセンスファイルまたはキーを使用してGitLab EEをアクティブ化](license_file.md)。

インスタンスのアクティブ化に関して質問または支援が必要な場合は、[GitLabサポート](https://about.gitlab.com/support/#contact-support)にお問い合わせください。

[ライセンスが期限切れ](license_file.md#what-happens-when-your-license-expires)になると、一部の機能がロックされます。

## GitLabエディションの確認 {#verify-your-gitlab-edition}

エディションを確認するには、GitLabにサインインして**ヘルプ**（{{< icon name="question-o" >}}）> **ヘルプ**を選択します。GitLabのエディションとバージョンはページの上部に表示されます。

GitLab Community Edition（CE）を実行している場合は、インストールをGitLab EEにアップグレードできます。詳細については、[エディション間のアップグレード](../update/upgrade.md#upgrading-between-editions)を参照してください。

ご質問または支援が必要な場合は、[GitLabサポート](https://about.gitlab.com/support/#contact-support)にお問い合わせください。

## トラブルシューティング {#troubleshooting}

GitLab Self-Managedインスタンスで有料サブスクリプション機能をアクティブ化する場合、次の問題が発生する可能性があります。

### エラー: `An error occurred while adding your subscription`{#error-an-error-occurred-while-adding-your-subscription}

この問題は、アクティベーションコードを入力した後に発生する可能性があります。

エラーの詳細を確認するには、ブラウザの開発者ツールを使用します:

1. デベロッパーツールを開くには、ページを右クリックして**Inspect**を選択します。
1. **ネットワーク**タブを選択します。
1. GitLabで、アクティベーションコードを再試行します。
1. **ネットワーク**タブで、`graphql`エントリを選択します。
1. **応答**タブを選択し、次のようなエラーがないか確認します:

      ```plaintext
      [{"data":{"gitlabSubscriptionActivate":{"errors":["<error> returned=1 errno=0 state=error: <error>"],"license":null,"__typename":"GitlabSubscriptionActivatePayload"}}}]
      ```

この問題を解決するには:

- GraphQL応答に`only get, head, options, and trace methods are allowed in silent mode`が含まれている場合は、インスタンスの[サイレントモード](silent_mode/_index.md#turn-off-silent-mode)を無効にします。

問題を特定できない場合は、[GitLabサポート](https://about.gitlab.com/support/portal/)に連絡し、問題の説明にGraphQL応答を記載してください。

### 接続エラーが原因でインスタンスをアクティブ化できません {#cannot-activate-instance-due-to-connectivity-error}

インスタンスのアクティブ化時に、GitLabサーバーへの接続を妨げる接続の問題が発生する可能性があります。これは、次の原因が考えられます:

- **ファイアウォールの設定**:
  - GitLabインスタンスが`https://customers.gitlab.com`のポート443への暗号化された接続を確立できることを確認するには、次のcURLコマンドを使用します:

    ```shell
    curl --verbose "https://customers.gitlab.com/"
    ```

  - cURLコマンドがエラーを返す場合は、次のいずれかの操作を行います:
    - ファイアウォールまたはプロキシを確認してください。ドメイン`https://customers.gitlab.com`はCloudflareによってフロントされています。アクティブ化が機能するように、ファイアウォールまたはプロキシがCloudflare [IPv4](https://www.cloudflare.com/ips-v4/)および[IPv6](https://www.cloudflare.com/ips-v6/)の範囲へのトラフィックを許可していることを確認してください。
    - サーバーを指すように、`gitlab.rb`で[プロキシを構成](https://docs.gitlab.com/omnibus/settings/environment-variables.html)します。

    既存のプロキシまたはファイアウォールを変更するには、ネットワーク管理者に連絡してください。
  - SSL検査アプライアンスを使用する場合は、アプライアンスのルート認証局証明書をインスタンス上の`/etc/gitlab/trusted-certs`に追加し、`gitlab-ctl reconfigure`を実行する必要があります。

- **カスタマーズポータルが動作していない場合**:
  - [ステータス](https://status.gitlab.com/)のカスタマーポータルに対するアクティブな中断がないか確認します。

- **オフライン環境の場合**:
  - GitLabサーバーへの接続を許可するように設定を構成できない場合は、営業担当者に連絡して[オフラインライセンス](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#what-is-an-offline-cloud-license)をリクエストしてください。

    セールス担当者の検索支援については、[GitLabサポート](https://about.gitlab.com/support/#contact-support)にお問い合わせください。

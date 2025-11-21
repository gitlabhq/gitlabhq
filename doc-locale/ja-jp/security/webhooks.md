---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 送信リクエストをフィルタリングする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

データ損失と漏洩のリスクから保護するために、GitLabのインスタンスの管理者は、送信リクエストフィルタリングコントロールを使用して、GitLabインスタンスによって行われる特定の送信リクエストを制限できるようになりました。

## Webhookとインテグレーションの保護 {#secure-webhooks-and-integrations}

少なくともメンテナーロールを持つユーザーは、プロジェクトまたはグループで特定の変更が発生したときにトリガーされる[webhooks](../user/project/integrations/webhooks.md)をセットアップできます。トリガーされると、`POST` HTTPリクエストがURLに送信されます。Webhookは通常、特定の外部Webサービスにデータを送信するように構成されており、そのWebサービスは適切な方法でデータを処理します。

ただし、Webhookは、外部Webサービスの代わりに、内部WebサービスのURLで構成できます。Webhookがトリガーされると、GitLabサーバーまたはそのローカルネットワーク上で実行されているGitLab以外のWebサービスが、悪用される可能性があります。

Webhookリクエストは、GitLabサーバー自体によって作成され、認可のために、ユーザートークンまたはリポジトリ固有のトークンの代わりに、フックごとに1つのオプションのシークレットトークンを使用します:

- ユーザートークン。
- リポジトリ固有のトークン。

その結果、これらのリクエストは、意図されているよりも広範なアクセスを持つ可能性があり、Webhookをホストするサーバー上で実行されているすべてのもの（以下を含む）へのアクセスが含まれます:

- GitLabサーバー。
- API自体。
- 一部のWebhookの場合、そのWebhookサーバーのローカルネットワーク内の他のサーバーへのネットワークアクセス。これらのサービスが保護されていて、外部からアクセスできない場合でも同様です。

Webhookを使用して、認証を必要としないWebサービスを使用して破壊的なコマンドをトリガーできます。これらのWebhookは、GitLabサーバーに`POST` HTTPリクエストをリソースを削除するエンドポイントに送信させることができます。

### Webhookとインテグレーションからのローカルネットワークへのリクエストを許可する {#allow-requests-to-the-local-network-from-webhooks-and-integrations}

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

脆弱なな内部Webサービスが悪用されるのを防ぐため、次のローカルネットワークアドレスへのすべてのWebhookおよびインテグレーションリクエストは許可されていません:

- 現在のGitLabインスタンスサーバーアドレス。
- `127.0.0.1`、`::1`、`0.0.0.0`、`10.0.0.0/8`、`172.16.0.0/12`、`192.168.0.0/16`などのプライベートネットワークアドレス、およびIPv6サイトローカル（`ffc0::/10`）アドレス。

これらのアドレスへのアクセスを許可するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **アウトバウンドリクエスト**を展開する。
1. **ウェブフックとインテグレーションからローカルネットワークへの要求を許可する**チェックボックスを選択します。

### システムフックからのローカルネットワークへのリクエストを禁止する {#prevent-requests-to-the-local-network-from-system-hooks}

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

[システムフック](../administration/system_hooks.md)は、デフォルトでローカルネットワークにリクエストを行うことができます。ローカルネットワークへのシステムフックリクエストを防ぐには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **アウトバウンドリクエスト**を展開する。
1. **システムフックからのローカルネットワークへのリクエストを許可する**チェックボックスをオフにします。

### DNSリバインディング攻撃保護の実施 {#enforce-dns-rebinding-attack-protection}

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

[DNSリバインディング](https://en.wikipedia.org/wiki/DNS_rebinding)は、悪意のあるドメイン名がローカルネットワークアクセス制限を回避するために、内部ネットワークリソースに解決されるようにする手法です。GitLabには、この攻撃に対する保護がデフォルトで有効になっています。この保護を無効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **アウトバウンドリクエスト**を展開する。
1. **DNSリバインディング攻撃の保護を実施する**チェックボックスをオフにします。

## リクエストのフィルタリング {#filter-requests}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/377371)されました。

{{< /history >}}

前提要件: 

- GitLabインスタンスへの管理者アクセス権が必要です。

多数のリクエストをブロックすることでリクエストをフィルタリングするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **アウトバウンドリクエスト**を展開する。
1. **許可リストで定義されているIPアドレス、IP範囲、およびドメイン名を除くすべてのリクエストをブロック**で定義されているIPアドレス、IP範囲、およびドメイン名を除くすべてのリクエストをブロックするチェックボックスを選択します。

このチェックボックスがオンになっている場合でも、次のリクエストはブロックされません:

- Geo、Git、GitLab Shell、Gitaly、PostgreSQL、Redisなどのコアサービス。
- オブジェクトストレージ。
- [許可リスト](#allow-outbound-requests-to-certain-ip-addresses-and-domains)にあるIPアドレスとドメイン。

この設定は、メインのGitLabアプリケーションでのみ有効です。そのため、Gitalyなどの他のサービスは、ルールを破るリクエストを行うことができます。さらに、[GitLabの一部の領域](https://gitlab.com/groups/gitlab-org/-/epics/8029)では、送信フィルタリングルールが適用されません。

## 特定のIPアドレスおよびドメインへの送信リクエストを許可する {#allow-outbound-requests-to-certain-ip-addresses-and-domains}

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

特定のIPアドレスとドメインへの送信リクエストを許可するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **アウトバウンドリクエスト**を展開する。
1. **フックとインテグレーションがアクセスできる、ローカルIPアドレスとドメイン名**に、IPアドレスとドメインを入力します。

エントリは、次のようになります:

- セミコロン、カンマ、または空白（改行を含む）で区切ることができます。
- ホスト名、IPアドレス、IPアドレス範囲などのさまざまな形式にすることができます。IPv6がサポートされています。Unicode文字を含むホスト名は、[Internationalized Domain Names in Applications](https://www.icann.org/en/icann-acronyms-and-terms/internationalized-domain-names-in-applications-en)（IDNA）エンコードを使用する必要があります。
- ポートを含めます。たとえば、`127.0.0.1:8080`は、`127.0.0.1`のポート8080への接続のみを許可します。ポートが指定されていない場合、そのIPアドレスまたはドメイン上のすべてのポートが許可されます。IPアドレス範囲は、その範囲内のすべてのIPアドレスのすべてのポートを許可します。
- 各エントリに255文字以下の1000個以下のエントリを番号付けします。
- ワイルドカード（たとえば、`*.example.com`）を含めないでください。

例: 

```plaintext
example.com;gitlab.example.com
127.0.0.1,1:0:0:0:0:0:0:1
127.0.0.0/8 1:0:0:0:0:0:0:0/124
[1:0:0:0:0:0:0:1]:8080
127.0.0.1:8080
example.com:8080
```

## トラブルシューティング {#troubleshooting}

送信リクエストをフィルタリングすると、次のイシューが発生する可能性があります。

### 構成されたURLがブロックされている {#configured-urls-are-blocked}

構成されたURLがブロックされない場合、**許可リストで定義されているIPアドレス、IP範囲、およびドメイン名を除くすべてのリクエストをブロック**で定義されているIPアドレス、IP範囲、およびドメイン名を除くすべてのリクエストをブロックするチェックボックスのみを選択できます。そうでない場合、URLがブロックされているというエラーメッセージが表示されることがあります。

この設定を有効にできない場合は、次のいずれかを実行します:

- URL設定を無効にします。
- 別のURLを構成するか、URL設定を空のままにします。
- 構成されたURLを[許可リスト](#allow-requests-to-the-local-network-from-webhooks-and-integrations)に追加します。

### パブリックランナーリリースURLがブロックされている {#public-runner-releases-url-is-blocked}

ほとんどのGitLabインスタンスでは、`public_runner_releases_url`が`https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab-runner/releases`に設定されているため、[リクエストのフィルタリング](#filter-requests)を妨げる可能性があります。

このイシューを解決するには、[GitLabがGitLab.comからランナーリリースバージョンデータをフェッチしないように構成](../administration/settings/continuous_integration.md#control-runner-version-management)します。

### GitLabサブスクリプション管理がブロックされている {#gitlab-subscription-management-is-blocked}

[リクエストをフィルタリング](#filter-requests)すると、[GitLabサブスクリプション管理](../subscriptions/self_managed/_index.md)がブロックされます。

この問題を回避するには、`customers.gitlab.com:443`を[許可リスト](#allow-outbound-requests-to-certain-ip-addresses-and-domains)に追加します。

### GitLabドキュメントがブロックされている {#gitlab-documentation-is-blocked}

[リクエストをフィルタリング](#filter-requests)すると、`Help page documentation base url is blocked: Requests to hosts and IP addresses not on the Allow List are denied`というエラーが表示されることがあります。このエラーを回避するには、次の手順に従います:

1. エラーメッセージ`Help page documentation base url is blocked`が表示されなくなるように、変更を元に戻します。
1. `docs.gitlab.com`、または[リダイレクトヘルプドキュメントページURL](../administration/settings/help_page.md#redirect-help-pages)を[許可リスト](#allow-outbound-requests-to-certain-ip-addresses-and-domains)に追加します。
1. **変更を保存**を選択します。

### GitLab Duo機能がブロックされている {#gitlab-duo-functionality-is-blocked}

[リクエストをフィルタリング](#filter-requests)すると、[GitLab Duoの機能](../user/gitlab_duo/_index.md)を使用しようとしたときに、`401`エラーが表示されることがあります。

このエラーは、GitLabクラウドサーバーへの送信リクエストが許可されていない場合に発生する可能性があります。このエラーを回避するには、次の手順に従います:

1. `https://cloud.gitlab.com:443`を[許可リスト](#allow-outbound-requests-to-certain-ip-addresses-and-domains)に追加します。
1. **変更を保存**を選択します。
1. GitLabが[クラウドサーバー](../user/gitlab_duo/_index.md)にアクセスできるようになったら、[手動でライセンスを同期](../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)します

詳細については、[GitLab Duoコード提案のトラブルシューティングドキュメント](../user/project/repository/code_suggestions/troubleshooting.md)を参照してください。

---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 送信リクエストをフィルタリングする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

データ損失や漏洩のリスクから保護するため、GitLabの管理者は、送信リクエストフィルタリング制御を使用して、GitLabインスタンスが行う特定の送信リクエストを制限できるようになりました。

## 安全なWebhookとインテグレーション {#secure-webhooks-and-integrations}

メンテナーまたはオーナーロールを持つユーザーは、プロジェクトまたはグループで特定の変更が発生したときにトリガーする[Webhook](../user/project/integrations/webhooks.md)を設定できます。トリガーされると、`POST` HTTPリクエストがURLに送信されます。Webhookは通常、特定の外部ウェブサービスにデータを送信するように設定されており、そのサービスはデータを適切な方法で処理します。

ただし、Webhookは外部ウェブサービスの代わりに内部ウェブサービスのURLで設定できます。Webhookがトリガーされると、GitLabサーバーまたはそのローカルネットワークで実行されているGitLab以外のウェブサービスが脆弱な状態になる可能性があります。

WebhookリクエストはGitLabサーバー自体によって行われ、認可のためにユーザートークンやリポジトリ固有のトークンではなく、フックごとに単一のオプションのシークレットトークンを使用します:

- ユーザートークン。
- リポジトリ固有のトークン。

その結果、これらのリクエストは意図されたよりも広範なアクセス権を持つ可能性があり、Webhookをホストするサーバー上で実行されているすべてへのアクセスを含みます:

- GitLabサーバー。
- API自体。
- 一部のWebhookでは、そのWebhookサーバーのローカルネットワーク内の他のサーバーへのネットワークアクセスが可能であり、これらのサービスが外部から保護され、アクセス不能であっても同様です。

Webhookは、認証を必要としないウェブサービスを使用して、破壊的なコマンドをトリガーするために使用できます。これらのWebhookにより、GitLabサーバーはリソースを削除するエンドポイントに対し`POST` HTTPリクエストを行うことができます。

### Webhookとインテグレーションからのローカルネットワークへのリクエストを許可する {#allow-requests-to-the-local-network-from-webhooks-and-integrations}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

脆弱な内部ウェブサービスの悪用を防ぐため、以下のローカルネットワークアドレスへのすべてのWebhookおよびインテグレーションリクエストは許可されていません:

- 現在のGitLabインスタンスサーバーアドレス。
- プライベートネットワークアドレス（`127.0.0.1`、`::1`、`0.0.0.0`、`10.0.0.0/8`、`172.16.0.0/12`、`192.168.0.0/16`、およびIPv6サイトローカル（`ffc0::/10`）アドレスを含む）。

これらのアドレスへのアクセスを許可するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **アウトバウンドリクエスト**を展開します。
1. **ウェブフックとインテグレーションからローカルネットワークへの要求を許可する**チェックボックスを選択します。

### システムフックからのローカルネットワークへのリクエストを防ぐ {#prevent-requests-to-the-local-network-from-system-hooks}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

[システムフック](../administration/system_hooks.md)はデフォルトでローカルネットワークへのリクエストを行うことができます。システムフックからのローカルネットワークへのリクエストを防ぐには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **アウトバウンドリクエスト**を展開します。
1. **システムフックからのローカルネットワークへのリクエストを許可する**チェックボックスをオフにします。

### DNSリバインディング攻撃の保護を実施する {#enforce-dns-rebinding-attack-protection}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

[DNS rebinding](https://en.wikipedia.org/wiki/DNS_rebinding)は、悪意のあるドメイン名を内部ネットワークリソースに解決することで、ローカルネットワークアクセス制限をバイパスするための手法です。GitLabでは、この攻撃に対する保護がデフォルトで有効になっています。この保護を無効にするには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **アウトバウンドリクエスト**を展開します。
1. **DNSリバインディング攻撃の保護を実施する**チェックボックスをオフにします。

## リクエストをフィルタリングする {#filter-requests}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/377371)されました。

{{< /history >}}

前提条件: 

- GitLabインスタンスへの管理者アクセス権が必要です。

多数のリクエストをブロックしてリクエストをフィルタリングするには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **アウトバウンドリクエスト**を展開します。
1. **許可リストで定義されているIPアドレス、IP範囲、およびドメイン名を除くすべてのリクエストをブロック**チェックボックスを選択します。

このチェックボックスが選択されている場合でも、以下へのリクエストはブロックされません:

- Git、GitLab Shell、Gitaly、PostgreSQL、Redisなどのコアサービス。
- オブジェクトストレージ。
- [許可リスト](#allow-outbound-requests-to-certain-ip-addresses-and-domains)内のIPアドレスとドメイン。

この設定が有効になっている場合、GitLabはリリースリンクなどの他のオブジェクトに含まれるURLに対してDNS解決を実行する場合があります。DNS解決が失敗すると、リクエストは失敗します。この問題を解決するには、GitLabがそのホストへの送信接続を行う必要がない場合でも、ホスト名を[許可リスト](#allow-outbound-requests-to-certain-ip-addresses-and-domains)に追加します。

この設定は主要なGitLabアプリケーションのみによって尊重されるため、Gitalyなどの他のサービスは依然としてルールに違反するリクエストを行うことができます。さらに、[GitLab](https://gitlab.com/groups/gitlab-org/-/epics/8029)の一部領域は送信フィルタリングルールを尊重しません。

[既存のバグ（#544821）](https://gitlab.com/gitlab-org/gitlab/-/issues/544821)のため、GeoリージョンURLは送信許可リストに追加する必要があります。

## 特定のIPアドレスとドメインへの送信リクエストを許可する {#allow-outbound-requests-to-certain-ip-addresses-and-domains}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

特定のIPアドレスとドメインへの送信リクエストを許可するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **アウトバウンドリクエスト**を展開します。
1. **フックとインテグレーションがアクセスできる、ローカルIPアドレスとドメイン名**に、IPアドレスとドメインを入力します。

エントリは以下のとおりです:

- セミコロン、カンマ、または空白（改行を含む）で区切ることができます。
- ホスト名、IPアドレス、IPアドレス範囲など、さまざまな形式を使用できます。IPv6をサポートしています。Unicode文字を含むホスト名には、[Internationalized Domain Names in Applications](https://www.icann.org/en/icann-acronyms-and-terms/internationalized-domain-names-in-applications-en)（IDNA）エンコードを使用する必要があります。
- ポートを含めます。たとえば、`127.0.0.1:8080`は`127.0.0.1`上のポート8080への接続のみを許可します。ポートが指定されていない場合、そのIPアドレスまたはドメイン上のすべてのポートが許可されます。IPアドレス範囲は、その範囲内のすべてのIPアドレス上のすべてのポートを許可します。
- 各エントリは255文字以下で、エントリ数は1000以下です。
- ワイルドカード（例: `*.example.com`）を含めないでください。

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

送信リクエストをフィルタリングする際に、以下のイシューに遭遇する可能性があります。

### 設定されたURLがブロックされる {#configured-urls-are-blocked}

設定されたURLがブロックされない場合にのみ、**許可リストで定義されているIPアドレス、IP範囲、およびドメイン名を除くすべてのリクエストをブロック**チェックボックスを選択できます。そうでない場合、URLがブロックされたことを示すエラーメッセージが表示されることがあります。

この設定を有効にできない場合は、以下のいずれかを実行してください:

- URL設定を無効にします。
- 別のURLを設定するか、URL設定を空のままにします。
- 設定されたURLを[許可リスト](#allow-requests-to-the-local-network-from-webhooks-and-integrations)に追加します。

### パブリックRunnerリリースURLがブロックされる {#public-runner-releases-url-is-blocked}

ほとんどのGitLabインスタンスでは、`public_runner_releases_url`が`https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab-runner/releases`に設定されており、これにより[リクエストのフィルタリング](#filter-requests)が妨げられる可能性があります。

この問題を解決するには、GitLabがGitLab.comからRunnerリリースバージョンデータをフェッチするのを停止するように[GitLabを設定します](../administration/settings/continuous_integration.md#control-runner-version-management)。

### GitLabサブスクリプション管理がブロックされる {#gitlab-subscription-management-is-blocked}

[リクエストをフィルタリングする](#filter-requests)と、[GitLabサブスクリプション管理](../subscriptions/manage_subscription.md)がブロックされます。

この問題を回避するには、`customers.gitlab.com:443`を[許可リスト](#allow-outbound-requests-to-certain-ip-addresses-and-domains)に追加します。

### GitLabドキュメントがブロックされる {#gitlab-documentation-is-blocked}

[リクエストをフィルタリングする](#filter-requests)と、`Help page documentation base url is blocked: Requests to hosts and IP addresses not on the Allow List are denied`というエラーが表示される場合があります。このエラーを回避するには、次の手順に従います。

1. エラーメッセージ`Help page documentation base url is blocked`が表示されなくなるように変更を元に戻します。
1. `docs.gitlab.com`、または[リダイレクトヘルプドキュメントページURL](../administration/settings/help_page.md#redirect-help-pages)を[許可リスト](#allow-outbound-requests-to-certain-ip-addresses-and-domains)に追加します。
1. **変更を保存**を選択します。

### GitLab Duoの機能がブロックされる {#gitlab-duo-functionality-is-blocked}

[リクエストをフィルタリングする](#filter-requests)と、[GitLab Duo機能](../user/gitlab_duo/_index.md)を使用しようとしたときに`401`エラーが表示される場合があります。

このエラーは、GitLabクラウドサーバーへの送信リクエストが許可されていない場合に発生する可能性があります。このエラーを回避するには、次の手順に従います。

1. `https://cloud.gitlab.com:443`を[許可リスト](#allow-outbound-requests-to-certain-ip-addresses-and-domains)に追加します。
1. **変更を保存**を選択します。
1. GitLabが[クラウドサーバー](../user/gitlab_duo/_index.md)にアクセスした後、[ライセンスを手動で同期](../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)します。

詳細については、[コード提案](../user/duo_agent_platform/code_suggestions/troubleshooting.md)または[コード提案（クラシック）](../user/project/repository/code_suggestions/troubleshooting.md)のトラブルシューティングドキュメントを参照してください。

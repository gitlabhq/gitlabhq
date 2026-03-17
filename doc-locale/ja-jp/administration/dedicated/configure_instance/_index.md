---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicatedインスタンスをスイッチボードで設定します。
title: GitLab Dedicatedを設定する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

このページの手順では、GitLab Dedicatedインスタンスの設定方法について説明しています。[利用可能な機能](../../../subscriptions/gitlab_dedicated/_index.md#available-features)の設定の有効化と更新を含みます。

管理者は、[**管理者**エリア](../../admin_area.md)を使用して、GitLabアプリケーションで追加の設定を設定できます。

GitLabが管理するソリューションであるため、SaaS環境の設定によって制御されるGitLabの機能は変更できません。このようなSaaS環境の設定の例には、`gitlab.rb`設定、およびShell、Railsコンソール、PostgreSQLコンソールへのアクセスが含まれます。

GitLab Dedicatedのエンジニアは、[緊急事態](../../../subscriptions/gitlab_dedicated/_index.md#access-controls)を除き、お客様の環境に直接アクセスすることはありません。

> [!note]
> インスタンスとはGitLab Dedicatedのデプロイを指し、テナントとは顧客を指します。

## インスタンスをスイッチボードで設定する {#configure-your-instance-using-switchboard}

スイッチボードを使用して、GitLab Dedicatedインスタンスに対する限定的な設定変更を行うことができます。

スイッチボードで利用可能な以下の設定があります:

- [IP許可リスト](network_security.md#ip-allowlist)
- [SAML設定](authentication/saml.md)
- [カスタム証明書](network_security.md#custom-certificate-authorities-for-external-services)
- [送信プライベートリンク](network_security.md#outbound-private-link)
- [プライベートホステッドゾーン](network_security.md#private-hosted-zones)

前提条件: 

- [管理者](users_notifications.md#add-switchboard-users)ロールが必要です。

設定を変更するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページ上部の**設定**を選択します。
1. 以下の関連セクションの手順に従ってください。

その他のインスタンスの設定については、[設定変更リクエストポリシー](_index.md#request-configuration-changes-with-a-support-ticket)に従ってサポートチケットを提出してください。

### スイッチボードで設定変更を適用する {#apply-configuration-changes-in-switchboard}

スイッチボードで行われた設定変更は、すぐに適用することも、次回の予定されている週次の[メンテナンス期間](../maintenance.md#maintenance-windows)まで延期することもできます。

変更をすぐに適用する場合:

- デプロイには最大90分かかる場合があります。
- 変更は保存された順序で適用されます。
- 複数の変更を保存し、一度にまとめて適用できます。
- デプロイ中もインスタンスは利用可能です。
- プライベートホストゾーンの変更は、最大5分間、依存するサービスを中断する可能性があります。

デプロイが完了すると、テナントの表示または編集アクセス権を持つすべてのユーザーは、各変更の通知を受け取ります。通知をオンまたはオフにするには、[通知設定の管理](users_notifications.md#manage-notification-settings)を参照してください。

## 設定変更履歴 {#configuration-change-log}

スイッチボードの**Configuration change log**ページは、GitLab Dedicatedインスタンスに対して行われた変更を追跡します。

各変更履歴エントリには、以下の詳細が含まれます:

| フィールド                | 説明                                                                                                                                   |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| 設定変更 | 変更された設定の名称。                                                                                               |
| ユーザー                 | 設定変更を行ったユーザーのメールアドレス。GitLab Operatorによって行われた変更の場合、この値は`GitLab Operator`と表示されます。 |
| IP                   | 設定変更を行ったユーザーのIPアドレス。GitLab Operatorによって行われた変更の場合、この値は`Unavailable`と表示されます。        |
| ステータス               | 設定変更が開始済み、進行中、完了、または延期されているかどうか。                                                           |
| 開始時間           | UTCでの設定変更が開始された日時。                                                                       |
| 終了時間             | UTCでの設定変更がデプロイされた日時。                                                                          |

各設定変更にはステータスがあります:

| ステータス      | 説明 |
|-------------|-------------|
| 開始済み   | 設定変更はスイッチボードで行われましたが、まだインスタンスにデプロイされていません。 |
| 進行中 | 設定変更がインスタンスに積極的にデプロイされています。 |
| 完了    | 設定変更がインスタンスにデプロイされました。 |
| 遅延     | 変更をデプロイする最初のジョブが失敗し、その変更がまだ新しいジョブに割り当てられていません。 |

### 設定変更履歴を表示する {#view-the-configuration-change-log}

設定変更履歴を表示するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページ上部の**Configuration change log**を選択します。

各設定変更は、テーブル内にエントリとして表示されます。各変更の詳細情報を表示するには、**詳細を表示**を選択します。

## GitLab Dedicatedインスタンス向けセルフホスト型AIゲートウェイ {#self-hosted-ai-gateway-for-gitlab-dedicated-instances}

{{< history >}}

- `ALLOW_DEDICATED_SELF_HOSTED_AIGW`環境変数は、GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/584642)されました。

{{< /history >}}

AIゲートウェイをセルフホストするには:

1. [サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を提出し、この機能の有効化を依頼してください。
1. 有効化されたら、[AIゲートウェイをインストール](../../../install/install_ai_gateway.md)に進んでください。

## サポートチケットによる設定変更リクエスト {#request-configuration-changes-with-a-support-ticket}

特定の設定変更には、変更をリクエストするためにサポートチケットの提出が必要です。サポートチケットの作成方法については、[チケットの作成](https://about.gitlab.com/support/portal/#creating-a-ticket)を参照してください。

[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)でリクエストされた設定変更は、以下のポリシーに従います:

- 環境の週次4時間メンテナンス期間中に適用されます。
- オンボーディング中に指定されたオプション、またはこのページに記載されているオプション機能に対してリクエストできます。
- GitLabが高優先度のメンテナンスタスクを実行する必要がある場合、翌週に延期されることがあります。
- [緊急サポート](https://about.gitlab.com/support/#how-to-engage-emergency-support)の対象とならない限り、週次メンテナンス期間外に適用することはできません。

> [!note]
> 変更リクエストが最小リードタイムを満たしている場合でも、次回のメンテナンス期間中に適用されない可能性があります。

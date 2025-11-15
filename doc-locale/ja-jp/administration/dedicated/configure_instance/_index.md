---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: スイッチボードでGitLab Dedicatedインスタンスを設定します。
title: GitLab Dedicatedを設定する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

このページの指示に従ってGitLab Dedicatedインスタンスを設定し、[利用可能な機能](../../../subscriptions/gitlab_dedicated/_index.md#available-features)の有効化と設定の更新を行います。

管理者は、[**管理者**エリア](../../admin_area.md)を使用して、GitLabアプリケーションで追加の設定を設定できます。

GitLabが管理するソリューションとして、SaaS環境設定で制御されるGitLabの機能を変更することはできません。そのようなSaaS環境設定の例としては、`gitlab.rb`設定、およびShell、Railsコンソール、PostgreSQLコンソールへのアクセスがあります。

GitLab Dedicatedのエンジニアは、[緊急事態](../../../subscriptions/gitlab_dedicated/_index.md#access-controls)を除き、お客様の環境に直接アクセスできません。

{{< alert type="note" >}}

インスタンスはGitLab Dedicatedのデプロイを指し、テナントは顧客を指します。

{{< /alert >}}

## スイッチボードを使用してインスタンスを設定する {#configure-your-instance-using-switchboard}

スイッチボードを使用して、GitLab Dedicatedインスタンスに制限付きの設定変更を加えることができます。

スイッチボードでは、次の設定が可能です:

- [IP許可リスト](network_security.md#ip-allowlist)
- [SAML設定](saml.md)
- [カスタム証明書](network_security.md#custom-certificate-authority)
- [送信プライベートリンク](network_security.md#outbound-private-link)
- [プライベートホストゾーン](network_security.md#private-hosted-zones)

前提要件: 

- [管理者](users_notifications.md#add-switchboard-users)ロールが必要です。

設定変更を行うには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページの上部にある**設定**を選択します。
1. 以下の関連セクションの指示に従ってください。

他のすべてのインスタンスの設定については、[設定変更リクエストポリシー](_index.md#request-configuration-changes-with-a-support-ticket)に従ってサポートチケットを送信してください。

### スイッチボードで設定変更を適用する {#apply-configuration-changes-in-switchboard}

スイッチボードで行われた設定変更は、すぐに適用することも、次回の定期的な週ごとの[メンテナンス時間](../maintenance.md#maintenance-windows)まで延期することもできます。

変更をすぐに適用する場合:

- デプロイには最大90分かかる場合があります。
- 変更は保存された順に適用されます。
- 複数の変更を保存し、1つのバッチで適用できます。
- GitLab Dedicatedインスタンスは、デプロイ中も引き続き利用できます。
- プライベートホストゾーンへの変更は、これらのレコードを使用するサービスを最大5分間中断させる可能性があります。

デプロイメントジョブが完了すると、メール通知が届きます。メインの受信トレイに通知が表示されない場合は、スパムフォルダーを確認してください。スイッチボードでテナントを表示または編集するアクセス権を持つすべてのユーザーは、変更ごとに通知を受け取ります。詳細については、[スイッチボードの通知設定を管理する](users_notifications.md#manage-notification-preferences)を参照してください。

{{< alert type="note" >}}

スイッチボードテナント管理者によって行われた変更についてのみ、メール通知が届きます。GitLab Operator（たとえば、メンテナンス時間中に完了したGitLabバージョンの更新）によって行われた変更は、メール通知をトリガーしません。

{{< /alert >}}

## 設定変更ログ {#configuration-change-log}

スイッチボードの**Configuration change log**（設定変更ログ）ページでは、GitLab Dedicatedインスタンスに加えられた変更を追跡します。

各ログエントリには、次の詳細が含まれています:

| フィールド                | 説明                                                                                                                                   |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| 設定変更 | 変更された設定の名前。                                                                                               |
| ユーザー                 | 設定を変更したユーザーのメールアドレス。GitLab Operatorによって行われた変更の場合、この値は`GitLab Operator`として表示されます。 |
| IP                   | 設定を変更したユーザーのIPアドレス。GitLab Operatorによって行われた変更の場合、この値は`Unavailable`として表示されます。        |
| ステータス               | 設定変更が開始、進行中、完了、または延期されたかどうか。                                                           |
| 開始時間           | 設定変更が開始された日時（UTC）。                                                                       |
| 終了時間             | 設定変更がデプロイされた日時（UTC）。                                                                          |

各設定変更にはステータスがあります:

| ステータス      | 説明 |
|-------------|-------------|
| 開始済み   | 設定変更はスイッチボードで行われましたが、まだインスタンスにデプロイされていません。 |
| 進行中 | 設定変更がインスタンスにアクティブにデプロイされています。 |
| 完了:    | 設定変更がインスタンスにデプロイされました。 |
| 遅延     | 変更をデプロイする最初のジョブが失敗し、変更がまだ新しいジョブに割り当てられていません。 |

### 設定変更ログを表示する {#view-the-configuration-change-log}

設定変更ログを表示するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. テナントを選択します。
1. ページの上部にある**Configuration change log**を選択します。

各設定変更は、テーブルにエントリとして表示されます。各変更の詳細を表示するには、**詳細を表示**を選択します。

## サポートチケットで設定変更をリクエストする {#request-configuration-changes-with-a-support-ticket}

特定の設定変更では、変更をリクエストするためにサポートチケットを送信する必要があります。サポートチケットの作成方法の詳細については、[チケットの作成](https://about.gitlab.com/support/portal/#creating-a-ticket)を参照してください。

[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)でリクエストされた設定変更は、次のポリシーを遵守します:

- 環境の毎週4時間のメンテナンス時間中に適用されます。
- オンボーディング中に指定されたオプション、またはこのページにリストされているオプション機能についてリクエストできます。
- GitLabが優先度の高いメンテナンスタスクを実行する必要がある場合、翌週に延期される可能性があります。
- [緊急サポート](https://about.gitlab.com/support/#how-to-engage-emergency-support)の対象とならない限り、毎週のメンテナンス時間外に適用することはできません。

{{< alert type="note" >}}

変更リクエストが最小リードタイムを満たしている場合でも、今後のメンテナンス時間中に適用されない可能性があります。

{{< /alert >}}

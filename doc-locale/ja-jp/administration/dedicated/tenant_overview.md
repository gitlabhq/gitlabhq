---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: スイッチボードでGitLab Dedicatedインスタンスに関する情報を表示します。
title: GitLab Dedicatedインスタンスの詳細を表示
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

スイッチボードで、GitLab Dedicatedインスタンスの詳細、メンテナンスウィンドウ、設定ステータスを監視します。

## インスタンスの詳細を表示する {#view-your-instance-details}

インスタンスの詳細にアクセスするには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. テナントを選択します。

**概要**ページには、以下が表示されます:

- 保留中の設定変更
- インスタンスが更新された日時
- インスタンスの詳細
- メンテナンス時間枠
- ホストされるRunner
- メールでの連絡

## テナント概要 {#tenant-overview}

上部のセクションには、テナントに関する重要な情報が表示されます。以下が含まれます:

- テナント名とURL
- [リポジトリのストレージ](create_instance/storage_types.md#repository-storage)
- 現在のGitLabのバージョン
- リファレンスアーキテクチャ
- メンテナンス時間枠
- データストレージ用のプライマリおよびセカンダリAWSリージョンと、そのアベイラビリティーゾーンID
- バックアップAWSリージョン
- テナントとホストランナーのAWSアカウントID

## メンテナンス時間枠 {#maintenance-windows}

**Maintenance windows**（メンテナンスウィンドウ）セクションには、以下が表示されます:

- 次に予定されているメンテナンスウィンドウ
- 最近完了したメンテナンスウィンドウ
- 最近の緊急メンテナンスウィンドウ（該当する場合）
- 今後のGitLabバージョンのアップグレード

{{< alert type="note" >}}

UTCの毎週日曜日の夜、スイッチボードが更新され、次週のメンテナンスウィンドウで計画されているGitLabバージョンのアップグレードが表示されます。詳細については、[メンテナンスウィンドウ](maintenance.md#maintenance-windows)を参照してください。

{{< /alert >}}

## ホストされるRunner {#hosted-runners}

**Hosted runners**（ホストランナー）セクションには、インスタンスに関連付けられている[hosted runners](hosted_runners.md)が表示されます。

## NATゲートウェイIPアドレス {#nat-ip-addresses}

NATゲートウェイのIPアドレスは、通常、標準操作中は一貫していますが、GitLabがディザスターリカバリー中にインスタンスをリビルドする必要がある場合など、変更されることがあります。

次のような場合は、NATゲートウェイのIPアドレスを知っておく必要があります:

- Webhookレシーバーを設定して、GitLab Dedicatedインスタンスからの受信リクエストを受け入れる。
- 外部サービスがGitLab Dedicatedインスタンスからの接続を受け入れるように、許可リストをセットアップする。

### NATゲートウェイのIPアドレスを表示 {#view-your-nat-gateway-ip-addresses}

GitLab Dedicatedインスタンスの現在のNATゲートウェイIPアドレスを表示するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. テナントを選択します。
1. **設定**タブを選択します。
1. **Tenant Details**（テナントの詳細）で、**NAT gateways**（NATゲートウェイ）を見つけます。

## 顧客とのコミュニケーション {#customer-communication}

**Customer communication**（顧客とのコミュニケーション）セクションには、GitLab Dedicatedインスタンス用に設定された**Operational email addresses**（オペレーションメールアドレス）が表示されます。これらのメールアドレスは、インスタンスに関する通知を受信します。以下を含みます:

- 緊急メンテナンス
- インシデント
- その他の重要な更新

操作用メールアドレスの通知をオフにすることはできません。

顧客とのコミュニケーション情報を更新するには、[サポートチケットを送信](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)してください。

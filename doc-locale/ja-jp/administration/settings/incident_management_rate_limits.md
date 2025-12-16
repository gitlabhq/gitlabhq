---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: インシデント管理レート制限
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

一定期間内に作成できる[インシデント](../../operations/incident_management/incidents.md)の受信アラートの数を制限できます。受信[インシデント管理](../../operations/incident_management/_index.md)アラートレート制限は、アラートまたは重複イシューの数を減らすことによって、インシデント対応者のオーバーロードを防ぐのに役立ちます。

例として、`10`リクエストごとに`60` `11`秒ごとにリクエストをアラート[インテグレーションエンドポイント](../../operations/incident_management/integrations.md)に送信すると、11番目のリクエストがブロックされます。エンドポイントへのアクセスは、1分後に再び許可されます。

この制限は次のとおりです:

- プロジェクトごとに個別に適用されます。
- IPアドレスごとには適用されません。
- デフォルトでは無効になっています。

レート制限を超えるリクエストは、`auth.log`に記録されます。

## 受信アラートのレート制限を設定する {#set-a-limit-on-inbound-alerts}

受信インシデント管理アラートのレート制限を設定するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **インシデント管理制限**を展開します。
1. **Enable Incident Management inbound alert limit**（インシデント管理受信アラート制限を有効にする）チェックボックスを選択します。
1. オプション。**Maximum requests per project per rate limit period**（プロジェクトごとのレート制限期間ごとの最大リクエスト数）のカスタム値を入力します。デフォルトは3600です。
1. オプション。**Rate limit period**（レート制限期間）のカスタム値を入力します。デフォルトは3600秒です。

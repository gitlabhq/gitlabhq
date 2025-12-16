---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ライセンスの使用状況
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

お使いのGitLabライセンスに関連付けられた使用状況を表示し、次の情報を含むライセンス使用状況ファイルをエクスポートできます:

- ライセンスキー
- ライセンシーのメールアドレス
- ライセンス開始日（UTC）
- ライセンス終了日（UTC）
- 会社
- ファイルが生成およびエクスポートされたときのタイムスタンプ（UTC）
- 過去のユーザー数（期間中の毎日）のテーブル:
  - カウントが記録されたタイムスタンプ（UTC）
  - 請求対象ユーザー数

{{< alert type="note" >}}

CSVファイルの[日付](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L7)と[時刻](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L13)にはカスタム形式が使用されます。

{{< /alert >}}

## ライセンス使用状況をエクスポート {#export-license-usage}

前提要件: 

- 管理者である必要があります。

ライセンス使用状況をCSVファイルにエクスポートできます。

このファイルには、GitLabが[四半期ごとの調整](../subscriptions/quarterly_reconciliation.md)および[更新](../subscriptions/manage_subscription.md#renew-subscription)を手動で処理するために使用する情報が含まれています。インスタンスがファイアウォールで保護されているか、オフライン環境の場合は、この情報をGitLabに提供する必要があります。

{{< alert type="warning" >}}

ライセンス使用状況ファイルを開かないでください。ファイルを開くと、[ライセンス使用状況データを送信](license_file.md#submit-license-usage-data)するときにエラーが発生する可能性があります。

{{< /alert >}}

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **サブスクリプション**を選択します。
1. 右上隅で、**ライセンス使用状況ファイルをエクスポート**を選択します。

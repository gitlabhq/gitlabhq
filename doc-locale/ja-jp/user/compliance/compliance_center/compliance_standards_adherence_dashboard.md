---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: プロジェクトのコンプライアンス標準への準拠ダッシュボードを表示し、レポートをエクスポートします。
title: コンプライアンス標準準拠ダッシュボード（非推奨）
---

<!--- start_remove The following content will be removed on remove_date: '2026-02-01' -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

この機能はGitLab 17.11で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/470834)となり、18.6で削除される予定です。代わりに[コンプライアンスステータスレポート](compliance_status_report.md)を使用してください。

{{< /alert >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125875) GitLab 16.2でGraphQL APIを`compliance_adherence_report`という名前の[フラグ付き](../../../administration/feature_flags/_index.md)で追加しました。デフォルトでは無効になっています。
- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125444) GitLab 16.3でコンプライアンス標準準拠ダッシュボードを`adherence_report_ui`という名前の[フラグ](../../../administration/feature_flags/_index.md)付きで追加しました。デフォルトでは無効になっています。
- GitLab 16.5で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/414495)になりました。
- GitLab 16.7で[機能フラグ`compliance_adherence_report`と`adherence_report_ui`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137398)が削除されました。
- GitLab 16.7で標準準拠フィルタリングを[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/413734)しました。
- GitLab 16.9で標準準拠グルーピングを[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/413735)しました。
- チェックが属する標準による標準準拠グルーピングと、チェックが属するプロジェクトによるグルーピングをGitLab 16.10で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/413735)しました。
- **Last Scanned**（最終スキャン日時）列の名称を、GitLab 16.10で**ステータスが最後に変更されてからの日付**に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/439545)しました。
- DASTスキャナーチェックをGitLab 17.6のGitLab Standardに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440721)しました。
- SASTスキャナーチェックをGitLab 17.6のGitLab Standardに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440722)しました。

{{< /history >}}

コンプライアンス標準準拠ダッシュボードには、_GitLab standard_に準拠しているプロジェクトの準拠ステータスがリスト表示されます。

プロジェクトが追加されたとき、または関連するプロジェクトまたはグループの設定が変更されたとき、そのプロジェクトに対する準拠スキャンが実行され、そのプロジェクトの標準準拠が更新されます。**ステータスが最後に変更されてからの日付**列のフィールドには、最初のステータス日と、ステータスに対するその後の変更が反映されます。

## ダッシュボードのコンプライアンス標準準拠を表示します {#view-the-compliance-standards-adherence-dashboard}

前提要件:

- 管理者であるか、プロジェクトまたはグループのオーナーロールを持っている必要があります。

コンプライアンス標準準拠ダッシュボードを表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。[新しいナビゲーションをオン](../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **セキュリティ** > **コンプライアンスセンター**を選択します。

コンプライアンス標準準拠ダッシュボードを以下でフィルタリングできます:

- チェックが実行されたプロジェクト。
- プロジェクトで実行されたチェックのタイプ。
- チェックが属する標準。

コンプライアンス標準準拠ダッシュボードは、以下でグループ化できます:

- チェックが実行されたプロジェクト。
- プロジェクトで実行されたチェックのタイプ。
- チェックが属する標準。

## GitLab standard {#gitlab-standard}

GitLab standardは、次のルールで構成されています:

- 作成者を承認者として禁止します。
- コミッターを承認者として禁止します。
- 少なくとも2件の承認。
- SASTスキャナーアーティファクト。
- DASTスキャナーアーティファクト。

### 作成者を承認者として禁止 {#prevent-authors-as-approvers}

GitLab standardに準拠するには、ユーザーが自分のマージリクエストを承認できないようにする必要があります。詳細については、[作成者による承認を禁止する](../../project/merge_requests/approvals/settings.md#prevent-approval-by-merge-request-creator)を参照してください。

GitLabセルフマネージドでは、[マージリクエストの作成者による承認を禁止する](../../../administration/merge_requests_approvals.md)インスタンスレベルの設定が更新されても、インスタンス上のすべてのプロジェクトの準拠ステータスは自動的に更新されません。これらのプロジェクトの準拠ステータスを更新するには、グループレベルまたはプロジェクトレベルの設定を更新する必要があります。

### コミッターを承認者として禁止 {#prevent-committers-as-approvers}

GitLab standardに準拠するには、コミットを追加したマージリクエストをユーザーが承認できないようにする必要があります。詳しくは、[コミットを追加したユーザーによる承認の禁止](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits)をご覧ください。

GitLabセルフマネージドでは、[コミットを追加したユーザーによる承認を禁止する](../../../administration/merge_requests_approvals.md)インスタンスレベルの設定が更新されても、インスタンス上のすべてのプロジェクトの準拠ステータスは自動的に更新されません。これらのプロジェクトの準拠ステータスを更新するには、グループレベルまたはプロジェクトレベルの設定を更新する必要があります。

### 少なくとも2件の承認 {#at-least-two-approvals}

GitLab standardに準拠するには、マージされるように、少なくとも2人のユーザーにマージリクエストを承認させる必要があります。詳細については、[マージリクエスト承認ルール](../../project/merge_requests/approvals/rules.md)を参照してください。

### SASTスキャナーアーティファクト {#sast-scanner-artifact}

GitLab standardに準拠するには、SASTスキャナーが有効化、設定され、プロジェクトのパイプラインでアーティファクトが生成されるようにする必要があります。詳細については、[静的アプリケーションセキュリティテスト（SAST）](../../application_security/sast/_index.md)を参照してください。

### DASTスキャナーアーティファクト {#dast-scanner-artifact}

GitLab standardに準拠するには、DASTスキャナーが有効化、設定され、プロジェクトのパイプラインでアーティファクトが生成されるようにする必要があります。詳細については、[DASTオンデマンドスキャン](../../application_security/dast/on-demand_scan.md)を参照してください。

## SOC 2 standard {#soc-2-standard}

{{< history >}}

- 少なくとも1人の非作成者承認SOC 2チェックをGitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433201)しました。

{{< /history >}}

SOC 2 standardは、1つのルールで構成されています:

- 作成者以外の少なくとも1人による承認。

### 作成者以外の少なくとも1人による承認 {#at-least-one-non-author-approval}

SOC 2 standardに準拠するには、次のことを行う必要があります:

- ユーザーが自分のマージリクエストを承認できないようにします。詳細については、[作成者による承認を禁止する](../../project/merge_requests/approvals/settings.md#prevent-approval-by-merge-request-creator)を参照してください。
- コミットを追加したマージリクエストをユーザーが承認できないようにします。[コミットを追加したユーザーによる承認を禁止する](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits)を参照してください。
- 少なくとも1つの承認が必要です。[マージリクエスト承認ルール](../../project/merge_requests/approvals/rules.md)をご覧ください。

これらの設定は、インスタンス全体で使用できます。ただし、これらの設定がインスタンスレベルで更新されても、インスタンス上のすべてのプロジェクトの準拠ステータスが自動的に更新されるわけではありません。これらのプロジェクトの準拠ステータスを更新するには、グループレベルまたはプロジェクトレベルの設定を更新する必要があります。インスタンスレベルの設定の詳細については、以下をご覧ください:

- [マージリクエストの作成者による承認を禁止](../../../administration/merge_requests_approvals.md)します。
- [コミットを追加したユーザーによる承認を防ぎます](../../../administration/merge_requests_approvals.md)。

## グループ内のプロジェクトのコンプライアンス標準準拠レポートをエクスポートする {#export-compliance-standards-adherence-report-for-projects-in-a-group}

{{< history >}}

- GitLab 16.8で`compliance_standards_adherence_csv_export`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/413736)されました。デフォルトでは無効になっています。
- GitLab 16.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142568)になりました。機能フラグ`compliance_standards_adherence_csv_export`は削除されました。

{{< /history >}}

グループ内のプロジェクトの標準準拠レポートのコンテンツをエクスポートします。レポートは、サイズの大きいメールの添付ファイルを避けるために、15MBで切り詰めるられています。

前提要件:

- グループの管理者であるか、オーナーロールを持っている必要があります。

グループ内のプロジェクトのコンプライアンス標準準拠レポートをエクスポートするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオン](../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **セキュリティ** > **コンプライアンスセンター**を選択します。
1. 右上隅で、**エクスポート**を選択します。
1. **基準遵守レポートのエクスポート**を選択します。

レポートがコンパイルされ、添付ファイルとしてメールの受信箱に配信されます。

<!--- end_remove -->

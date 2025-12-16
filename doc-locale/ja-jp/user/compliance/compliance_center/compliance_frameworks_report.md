---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンプライアンスフレームワークレポート
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.5で`compliance_framework_report_ui`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422973)されました。デフォルトでは無効になっています。
- GitLab 16.4以前、**Compliance frameworks report**は、現在**Compliance projects report**と呼ばれているものを指していました。正式名称の**Compliance frameworks report**は、GitLab 16.5で[名前が**Compliance projects report**に変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/422963)。
- GitLab 16.8で、[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140825)になりました。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/425242)になりました。機能フラグ`compliance_framework_report_ui`は削除されました。

{{< /history >}}

コンプライアンスフレームワークのレポートを使用すると、グループ内のすべてのコンプライアンスフレームワークを確認できます。レポートの各行には、次のものが表示されます:

- フレームワーク名。
- 関連プロジェクト。

グループのデフォルトのフレームワークには、**デフォルト**バッジが付いています。

## コンプライアンスフレームワークレポートを表示する {#view-the-compliance-frameworks-report}

コンプライアンスフレームワークのレポートを表示するには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **セキュリティ** > **コンプライアンスセンター**を選択します。
1. ページで、**フレームワーク**タブを選択します。

## 新しいコンプライアンスフレームワークを作成 {#create-a-new-compliance-framework}

前提要件: 

- グループの管理者であるか、オーナーロールを持っている必要があります。

コンプライアンスフレームワークのレポートから新しいコンプライアンスフレームワークを作成するには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **セキュリティ** > **コンプライアンスセンター**を選択します。
1. ページで、**フレームワーク**タブを選択します。
1. **新規フレームワーク**を選択します。
1. **空白のフレームワークの作成**を選択します。
1. **フレームワークを追加**を選択して、コンプライアンスフレームワークを作成します。

## コンプライアンスフレームワークを編集 {#edit-a-compliance-framework}

前提要件: 

- グループの管理者であるか、オーナーロールを持っている必要があります。

コンプライアンスフレームワークのレポートからコンプライアンスフレームワークを編集するには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **セキュリティ** > **コンプライアンスセンター**を選択します。
1. ページで、**フレームワーク**タブを選択します。
1. フレームワークにカーソルを合わせ、**フレームワークを編集**を選択します。
1. **変更を保存**を選択して、コンプライアンスフレームワークを編集します。

## コンプライアンスフレームワークを削除 {#delete-a-compliance-framework}

前提要件: 

- グループの管理者であるか、オーナーロールを持っている必要があります。

コンプライアンスフレームワークのレポートからコンプライアンスフレームワークを削除するには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **セキュリティ** > **コンプライアンスセンター**を選択します。
1. ページで、**フレームワーク**タブを選択します。
1. フレームワークにカーソルを合わせ、**フレームワークを編集**を選択します。
1. **フレームワークを削除**を選択して、コンプライアンスフレームワークを削除します。

## コンプライアンスフレームワークをデフォルトとして設定および削除 {#set-and-remove-a-compliance-framework-as-default}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181500)されました。

{{< /history >}}

前提要件:

- グループの管理者であるか、オーナーロールを持っている必要があります。

コンプライアンスフレームワークを[デフォルト](../compliance_frameworks/_index.md#default-compliance-frameworks)として設定] コンプライアンスフレームワークのレポートから:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **セキュリティ** > **コンプライアンスセンター**を選択します。
1. ページで、**フレームワーク**タブを選択します。
1. デフォルトとして設定するコンプライアンスフレームワークの横にある{{< icon name="pencil" >}}アクションを選択します。
1. **デフォルトとして設定**を選択して、デフォルトとして設定します。

コンプライアンスフレームワークをデフォルトとしてレポートから削除するには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **セキュリティ** > **コンプライアンスセンター**を選択します。
1. ページで、**フレームワーク**タブを選択します。
1. デフォルトであるコンプライアンスフレームワークの横にある{{< icon name="pencil" >}}アクションを選択します。
1. **デフォルトで削除**を選択して、デフォルトとして削除します。

## グループ内のコンプライアンスフレームワークのレポートをエクスポートする {#export-a-report-of-compliance-frameworks-in-a-group}

{{< history >}}

- GitLab 16.11で`compliance_frameworks_report_csv_export`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/413736)されました。デフォルトでは無効になっています。
- GitLab 17.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152644)になりました。機能フラグ`compliance_frameworks_report_csv_export`は削除されました。

{{< /history >}}

グループ内のコンプライアンスフレームワークのレポートの内容をエクスポートします。レポートは、メールの添付ファイルが大きくなるのを避けるために、15 MBに切り詰められます。

前提要件: 

- グループの管理者であるか、オーナーロールを持っている必要があります。

グループ内のプロジェクトの標準準拠レポートをエクスポートするには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **セキュリティ** > **コンプライアンスセンター**を選択します。
1. 右上隅で、**エクスポート**を選択します。
1. **Export framework report**（フレームワークレポートをエクスポート）を選択します。

レポートがコンパイルされ、添付ファイルとしてメールの受信トレイに配信されます。

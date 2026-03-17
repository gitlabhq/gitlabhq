---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: セキュリティ属性
description: セキュリティ属性を使用すると、セキュリティチームはカスタムメタデータラベルをプロジェクトやグループに適用して、ビジネスコンテキストに基づいてセキュリティリスクをフィルタリングし、優先順位を付けることができます。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/groups/gitlab-org/-/epics/18010)：GitLab 18.5。フラグの名前は、`security_context_labels`と`security_categories_and_attributes`です。デフォルトでは無効になっています。この機能は、[ベータ](../../../policy/development_stages_support.md)で導入されました
- [GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/551226)：GitLab 18.6。
- [一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/588619)：GitLab 18.9。機能フラグ`security_inventory_dashboard`は削除されました。

{{< /history >}}

セキュリティチームは、セキュリティ属性を使用して、組織とビジネスニーズに固有のメタデータをプロジェクトに適用できるようになりました。

セキュリティ属性は、次のカテゴリ別に編成されています:

- ビジネスインパクト
- アプリケーション
- ビジネスユニット
- インターネット公開
- 場所

これらの属性をプロジェクト全体に適用することで、組織のリスク体制とビジネスニーズに基づいて、どのプロジェクトにアクションが必要かをより迅速に特定できます。セキュリティ属性を使用すると、次のことが可能になります:

- ミッションクリティカルで、より強力なスキャンカバレッジを必要とするプロジェクトを特定します。
- 各アプリケーションまたはビジネスユニットのスキャンカバレッジをレビューします。
- 公開されていて、アクセス可能なアプリケーションに貢献するプロジェクトを特定します。

[epic 16939](https://gitlab.com/groups/gitlab-org/-/work_items/16939)のセキュリティインベントリの開発を追跡します。この機能の開発が継続されるように、[フィードバック](https://gitlab.com/gitlab-org/gitlab/-/issues/553062)をお寄せください。

## グループのセキュリティ属性を管理する {#manage-security-attributes-for-groups}

前提条件: 

- セキュリティ属性を管理するには、グループのメンテナーまたはオーナーロールが必要です。

グループのセキュリティ属性を管理するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。

## プロジェクトのセキュリティ属性を管理する {#manage-security-attributes-for-projects}

前提条件: 

- セキュリティ属性を管理するには、プロジェクトのメンテナーまたはオーナーロールが必要です。

プロジェクトのセキュリティ属性を管理するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。
1. **セキュリティ属性**タブを選択します。

## 関連トピック {#related-topics}

- [セキュリティインベントリ](../security_inventory/_index.md)
- [セキュリティダッシュボード](../security_dashboard/_index.md)
- [脆弱性レポート](../vulnerability_report/_index.md)

## トラブルシューティング {#troubleshooting}

セキュリティ属性を使用する場合、次の問題が発生する可能性があります。

### セキュリティ設定メニュー項目が見つからない {#security-configuration-menu-item-missing}

認証済みユーザーによっては、**セキュリティ設定**メニュー項目にアクセスするために必要な権限がない場合があります。このメニュー項目は、認証済みユーザーがメンテナーまたはオーナーロールを持っている場合にのみグループに表示されます。

セキュリティ属性を管理するには、メンテナーに設定変更を完了するか、必要に応じて管理者からメンテナーロールをリクエストするように依頼してください。

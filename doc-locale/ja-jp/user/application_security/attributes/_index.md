---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セキュリティ属性
description: セキュリティチームはセキュリティ属性を使用することで、カスタムメタデータラベルをプロジェクトやグループに適用し、ビジネスコンテキストに基づいて、セキュリティリスクをフィルタリングしたり、優先順位を付けたりすることができます。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.5で`security_context_labels`および`security_categories_and_attributes`フラグとともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/18010)されました。デフォルトでは無効になっています。この機能は[ベータ版](../../../policy/development_stages_support.md)として導入されました。
- GitLab 18.6の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/551226)になりました。

{{< /history >}}

> [!flag] この機能の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

セキュリティチームはセキュリティ属性を使用して、組織およびビジネスニーズに固有のメタデータをプロジェクトに適用できるようになりました。

セキュリティ属性は、以下に基づいてカテゴリ別に分類されています:

- ビジネスインパクト
- アプリケーション
- ビジネスユニット
- インターネット露出
- 場所

これらの属性をプロジェクト全体に適用することで、組織のリスク管理体制とビジネスニーズに基づいて、アクションが必要なプロジェクトをより迅速に特定できます。セキュリティ属性を使用すると、次のことが可能になります:

- より強力なスキャンカバレッジを必要とするミッションクリティカルなプロジェクトを特定する。
- 各アプリケーションまたはビジネスユニットのスキャンカバレッジをレビューする。
- パブリックアクセスが可能な公開アプリケーションにコントリビュートするプロジェクトを特定する。

この機能はベータ版です。[エピック18010](https://gitlab.com/groups/gitlab-org/-/epics/18010)でセキュリティ属性の開発を追跡してください。この機能の開発を続けていますので、[イシュー576032でフィードバック](https://gitlab.com/gitlab-org/gitlab/-/issues/576032)をお寄せください。セキュリティ属性の機能は、デフォルトで無効になっています。

## グループのセキュリティ属性を管理する {#manage-security-attributes-for-groups}

前提条件: 

- セキュリティ属性を管理するには、グループ内でメンテナーロール以上が必要です。

グループのセキュリティ属性を管理するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。

## プロジェクトのセキュリティ属性を管理する {#manage-security-attributes-for-projects}

前提条件: 

- セキュリティ属性を管理するには、プロジェクト内でメンテナーロール以上が必要です。

プロジェクトのセキュリティ属性を管理するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。
1. **セキュリティ属性**タブを選択します。

## 関連トピック {#related-topics}

- [セキュリティインベントリ](../security_inventory/_index.md)
- [セキュリティダッシュボード](../security_dashboard/_index.md)
- [脆弱性レポート](../vulnerability_report/_index.md)

## トラブルシューティング {#troubleshooting}

セキュリティ属性を使用する際に次の問題が発生する可能性があります。

### セキュリティ設定メニューの項目が見つからない {#security-configuration-menu-item-missing}

一部のユーザーには、**セキュリティ設定**メニューの項目にアクセスするために必要となる権限がありません。認証済みユーザーがメンテナーロール以上を持っている場合にのみ、このメニューの項目がグループに対して表示されます。

セキュリティ属性を管理するには、メンテナーに設定の変更を完了するように依頼するか、必要に応じて、管理者を通じてメンテナーロールをリクエストしてください。

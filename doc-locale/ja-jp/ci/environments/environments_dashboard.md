---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 環境ダッシュボード
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

環境ダッシュボードは、クロスプロジェクトの環境ベースのビューを提供し、各環境で何が起こっているかを全体的に把握できます。単一の場所から、開発からステージング、そして本番環境へと変更が流れる際の進捗状況を追跡できます（または、設定できるカスタム環境フローの任意のシリーズを経由します）。複数のプロジェクトの概要を一目で確認できるため、どのパイプラインがグリーンで、どれがレッドであるかをすぐに確認でき、特定ポイントでブロックが発生しているかどうか、または調査する必要のあるより体系的な問題があるかどうかを診断できます。

1. 左側のサイドバーで、**検索または移動先**を選択します。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **あなたの作業**を選択します。
1. **環境**を選択します。

![デプロイ環境とパイプラインステータスを持つプロジェクトの2つの行を示す環境ダッシュボード。](img/environments_dashboard_v12_5.png)

環境ダッシュボードには、プロジェクトごとに最大3つの環境を含む、プロジェクトのページ分割されたリストが表示されます。

各プロジェクトには、構成された環境が表示されます。レビューアプリやその他のグループ化された環境は表示されません。

## ダッシュボードへのプロジェクトの追加 {#adding-a-project-to-the-dashboard}

ダッシュボードにプロジェクトを追加するには:

1. ダッシュボードのホーム画面で**プロジェクトを追加**を選択します。
1. **プロジェクトを検索**フィールドを使用して、1つまたは複数のプロジェクトを検索して追加します。
1. **プロジェクトを追加**を選択します。

追加されると、各プロジェクトの環境の運用状態の概要（最新のコミット、パイプラインステータス、デプロイ時間など）を確認できます。

環境と[オペレーション](../../user/operations_dashboard/_index.md)ダッシュボードは、プロジェクトの同じリストを共有します。一方のプロジェクトを追加または削除すると、GitLabは他方からプロジェクトを追加または削除します。

GitLabがこのダッシュボードに表示するために、最大150個のプロジェクトを追加できます。

## GitLab.comの環境ダッシュボード {#environment-dashboards-on-gitlabcom}

GitLab.comのユーザーは、パブリックプロジェクトを環境ダッシュボードに無料で追加できます。プロジェクトがプライベートの場合、それが属するグループは[GitLab Premium](https://about.gitlab.com/pricing/)プランを持っている必要があります。

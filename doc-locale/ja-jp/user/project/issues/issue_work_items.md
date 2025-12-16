---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: イシューの新しい外観をテストする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 17.5で`work_items_view_preference`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/9584)されました。デフォルトでは無効になっています。この機能は[ベータ版](../../../policy/development_stages_support.md#beta)です。
- 機能フラグ`work_items_view_preference`が、一部のユーザーに対してGitLab 17.9のGitLab.comで有効になりました。
- `work_items_view_preference`という機能フラグは、17.10のGitLab.com、GitLab Self-Managed、GitLab Dedicatedで[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184496)になりました。
- GitLab 17.11の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/482931)になりました。
- GitLab 18.1で`work_item_view_for_issues`という機能フラグに[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/482931)しました。GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効。機能フラグ`work_items_view_preference`は削除されました。
- プロジェクトのイシューページの追加フィルターが、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198544)されました。[GitLab.com、GitLab Self-Managed、GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/204139)で有効。
- グループのイシューページの追加フィルターが、GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202089)されました。[GitLab.com、GitLab Self-Managed、GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205308)で有効。

{{< /history >}}

<!-- Incorporate this content into issues/index.md or managing_issues.md and redirect this page there -->

アジャイルプランニング製品に対するニーズをより満たすために、イシューを作業アイテム向けの統一フレームワークに移行することで、イシューの外観を変更しました。

これらの変更には、イシューリスト、イシューボード、または子アイテムやリンクされたアイテムから開いたイシューの新しいドロワービュー、イシューとインシデントの新しい作成ワークフロー、およびイシューの新しいビューが含まれています。

詳細については、[epic 9584](https://gitlab.com/groups/gitlab-org/-/epics/9584)およびブログ記事[First look: を参照してください:](https://about.gitlab.com/blog/2024/06/18/first-look-the-new-agile-planning-experience-in-gitlab/)（2024年6月）

## フィードバック {#feedback}

バグを見つけましたか、またはリクエストがありますか？[issue 523713](https://gitlab.com/gitlab-org/gitlab/-/issues/523713)にフィードバックをお寄せください。

## 新機能 {#new-features}

新しいイシューエクスペリエンスには、次の改善が含まれています:

- **Drawer view**（ドロワービュー）: イシューリストからイシューを開くと、現在のページから移動せずにドロワーでイシューが開きます。ドロワーには、イシューの完全なビューが表示されます。

  代わりに、フルページを表示するには、次のいずれかの操作を行います:
  1. ドロワーの上部にある**View in full page**（フルページで表示） を選択します。
  1. 新しいタブでリンクを開きます。

  エピックページのフルページビューで常にイシューを開くには、右上隅にある**オプションの表示**（{{< icon name="preferences" >}}）を選択し、**サイドパネルにアイテムを開く**切替をオフにします。
- **Issue controls**（Issueコントロール）: 機密設定を含むすべてのイシューコントロールが、上部のアクションメニューに表示されるようになりました。このメニューは、ページをスクロールしても表示されたままになります。
- **Redesigned sidebar**（Redesign再設計されたサイドバー）: サイドバーが、マージリクエストやエピックと同様に、ページに埋め込まれるようになりました。画面が小さい場合、サイドバーのコンテンツは説明の下に表示されます。
- **Parent hierarchy**（Parent親の階層）: タイトルの上に、このアイテムが属する階層全体を表示できます。サイドバーには、親の作業アイテム（以前は「Epic」と呼ばれていました）も表示されます。
- **種類の変更**: アイテムの種類の変更が可能です:
  1. 上部のアクションメニューから、**種類の変更**を選択します。
  1. 新しい種類を選択します: イシュー、タスク、インシデント、またはエピック。イシューをエピックに変更すると、エピックは親グループに作成されます。これは、エピックがグループにしか存在できないためです。
- **開発**: このアイテムに関連するマージリクエスト、ブランチ、および機能フラグは、1つのリストに表示されます。
- **Issue list on projects and groups**（プロジェクトとグループのイシューリスト）: プロジェクトとグループのイシューリストは、作業アイテムによって強化されています。次のような新機能が追加されています:
  - エピックでイシューをフィルタリングすることに加えて、親イシューでタスクをフィルタリングします。
  - カスタムステータスでフィルタリングします。
  - アサイン先、ラベル、マイルストーン、日付、ヘルスステータス、コメント、イテレーション、ブロックまたはブロックステータス、人気度などのメタデータの表示設定を構成します。
  - 任意の作業アイテムタイプの状態と親の一括編集。

## 作業アイテムのMarkdown参照 {#work-item-markdown-reference}

{{< history >}}

- GitLab 18.1で`extensible_reference_filters`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352861)されました。デフォルトでは無効になっています。
- GitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197052)になりました。機能フラグ`extensible_reference_filters`は削除されました。

{{< /history >}}

GitLab Flavored Markdownフィールドでは、`[work_item:123]`を使用して作業アイテムを参照できます。詳細については、[GitLab固有の参照](../../markdown.md#gitlab-specific-references)をご覧ください。

---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: イシュー
description: タスク、バグレポート、機能リクエスト、追跡。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

イシューを使用すると、チームと連携して、GitLabで作業を計画、追跡、および提供できます。イシューでは、次のことができます。

- 機能提案、タスク、サポートリクエスト、バグレポートを追跡します。
- 担当者、期日、ヘルスステータスを使用して、作業を整理し、優先順位を付けます。
- コメントとスレッド形式のディスカッションを通じて、チームのディスカッションと意思決定を促進します。
- テンプレート、ラベル、エピック、ボードを通じて、カスタムワークフローをサポートします。
- Zoom、Jira、メールサービスなどの外部ツールと統合します。

イシューは常に特定のプロジェクトに関連付けられています。グループ内に複数のプロジェクトがある場合は、すべてのプロジェクトのイシューを一度に表示できます。

<div class="video-fallback">
  動画をご覧ください。<a href="https://www.youtube.com/watch?v=Mt1EzlKToig">イシュー - GitLabで組織をセットアップする</a>。
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/Mt1EzlKToig" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2023-10-30 -->

<i class="fa-youtube-play" aria-hidden="true"></i> GitLab戦略マーケティング部門が[ラベル](../labels.md)と[イシューボード](../issue_board.md)でイシューをどのように使用しているかについては、[managing commitments with issues](https://www.youtube.com/watch?v=cuIHNintg1o&t=3)ビデオをご覧ください。
<!-- Video published on 2020-04-10 -->

## イシューを作業アイテムとして {#issues-as-work-items}

{{< history >}}

- GitLab 17.5で`work_items_view_preference`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/9584)されました。デフォルトでは無効になっています。この機能は[ベータ版](../../../policy/development_stages_support.md#beta)です。
- 機能フラグ`work_items_view_preference`は、GitLab 17.9でGitLab.comの一部のユーザーで有効になりました。
- 機能フラグ`work_items_view_preference`は、GitLab 17.10でGitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで[有効化されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184496)。
- GitLab 17.11の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/482931)になりました。
- GitLab 18.1で、機能フラグ`work_item_view_for_issues`に[移動されました](https://gitlab.com/gitlab-org/gitlab/-/issues/482931)。GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました。機能フラグ`work_items_view_preference`は削除されました。
- プロジェクトのイシューページへの追加フィルターがGitLab 18.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198544)。[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/204139)。
- グループのイシューページへの追加フィルターがGitLab 18.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202089)。[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205308)。
- GitLab 18.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/520791)になりました。機能フラグ`work_item_view_for_issues`は削除されました。

{{< /history >}}

イシューを作業アイテムの統合フレームワークに移行することで、イシューの見た目を変更し、アジャイルプランニング製品のニーズをより良く満たせるようにしました。

詳細については、[エピック9290](https://gitlab.com/groups/gitlab-org/-/epics/9290)および[GitLabにおける新しいアジャイルプランニングエクスペリエンス](https://about.gitlab.com/blog/first-look-the-new-agile-planning-experience-in-gitlab/)のブログ記事を参照してください。（2024年6月）。

この変更を試しているときに問題が発生した場合は、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523713)を使用して詳細を報告できます。

### 作業アイテムのMarkdown参照 {#work-item-markdown-reference}

{{< history >}}

- GitLab 18.1で`extensible_reference_filters`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352861)されました。デフォルトでは無効になっています。
- GitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197052)になりました。機能フラグ`extensible_reference_filters`は削除されました。

{{< /history >}}

GitLab Flavored Markdownフィールドでは、`[work_item:123]`を使用して作業アイテムを参照できます。詳細については、[GitLab固有の参照](../../markdown.md#gitlab-specific-references)をご覧ください。

## 関連トピック {#related-topics}

- [イシューの作成](create_issues.md)
- [テンプレートからイシューを作成する](../description_templates.md#use-the-templates)
- [イシューを編集](managing_issues.md#edit-an-issue)
- [イシューを移動](managing_issues.md#move-an-issue)
- [イシューを完了にする](managing_issues.md#close-an-issue)
- [イシューを削除](managing_issues.md#delete-an-issue)
- [イシューをプロモート](managing_issues.md#promote-an-issue-to-an-epic)
- [期限を設定する](due_dates.md)
- [イシューをインポート](csv_import.md)
- [イシューをエクスポート](csv_export.md)
- [デザインをイシューにアップロード](design_management.md)
- [リンクされたイシュー](related_issues.md)
- [類似イシュー](managing_issues.md#similar-issues)
- [ヘルスステータス](managing_issues.md#health-status)
- [クロスリンクイシュー](crosslinking_issues.md)
- [イシューリストをソート](sorting_issue_lists.md)
- [イシューを検索](managing_issues.md#filter-the-list-of-issues)
- [エピック](../../group/epics/_index.md)
- [イシューボード](../issue_board.md)
- [イシューAPI](../../../api/issues.md)
- [外部イシュートラッカーを設定する](../../../integration/external-issue-tracker.md)
- [タスク](../../tasks.md)
- [イシュー内のタスクの数とウェイトを表示](../../tasks.md#view-count-and-weight-of-tasks-in-the-parent-issue)
- [子タスクを持つイシューの進捗を表示](../../tasks.md#view-progress-of-the-parent-issue)
- [外部参加者](../service_desk/external_participants.md)

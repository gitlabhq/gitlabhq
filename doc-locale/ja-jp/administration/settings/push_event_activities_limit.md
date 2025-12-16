---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: インスタンスが許可する単一プッシュイベントの数に制限を設定します。
title: プッシュイベントアクティビティーの制限と一括プッシュイベント
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

システムの良好なパフォーマンスを維持し、アクティビティーフィードのスパムを防ぐために、**プッシュイベントアクティビティーの制限**を設定します。デフォルトでは、GitLabはこの制限を`3`に設定しています。3つ以上のブランチとタグに影響する変更をプッシュすると、GitLabは個々のプッシュイベントの代わりに、一括プッシュイベントを作成します。

たとえば、4つのブランチに同時にプッシュすると、アクティビティーフィードには、4つの個別のプッシュイベントではなく、単一の{{< icon name="commit">}} `Pushed to 4 branches at (project name)`イベントが表示されます。

別の**プッシュイベントアクティビティーの制限**を設定するには、次のいずれかの方法があります:

- [Application settings API](../../api/settings.md#available-settings)で、`push_event_activities_limit`を設定します。

- GitLab UIの場合:
  1. 左側のサイドバーの下部で、**管理者**を選択します。
  1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
  1. **パフォーマンスの最適化**を展開します。
  1. **プッシュイベントアクティビティーの制限**設定を編集します。
  1. **変更を保存**を選択します。

値は`0`以上にすることができます。この値を`0`に設定しても、スロットリングは無効になりません。

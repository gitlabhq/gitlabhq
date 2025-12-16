---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 絵文字リアクション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.0で、 「award絵文字」から「絵文字リアクション」に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/409884)。
- 作業アイテム（タスク、主な成果など）で絵文字でリアクションする機能が、GitLab 16.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/393599)。
- デザインディスカッションコメントで絵文字でリアクションする機能が、GitLab 16.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/29756)。

{{< /history >}}

オンラインでコラボレーションしていると、ハイタッチや賛成の絵文字を使う機会が少なくなります。絵文字でリアクションしましょう:

- [イシュー](project/issues/_index.md)。
- [タスク](tasks.md)。
- [マージリクエスト](project/merge_requests/_index.md)と[スニペット](snippets.md)。
- [エピック](group/epics/_index.md)。
- [目標と主な成果](okrs.md)。
- コメントスレッドを使用できる場所ならどこでも使用できます。

![検索ボックスを含む、さまざまなカテゴリの絵文字リアクションピッカー。](img/award_emoji_select_v14_6.png)

絵文字リアクションを使用すると、長いコメントスレッドなしで、フィードバックを簡単にやり取りできます。

「賛成」および「反対」の絵文字は、[人気順で並べ替える](project/issues/sorting_issue_lists.md#sorting-by-popularity)際に、イシューまたはマージリクエストの順位を計算するために使用されます。

関連するAPIについては、[絵文字リアクションAPI](../api/emoji_reactions.md)を参照してください。

## コメントの絵文字リアクション {#emoji-reactions-for-comments}

絵文字リアクションは、成果を祝ったり、意見に同意したりする場合に、個々のコメントに適用することもできます。

絵文字リアクションを追加するには:

1. コメントの右上隅にある笑顔（{{< icon name="slight-smile" >}}）を選択します。
1. 絵文字ピッカーから絵文字を選択します。

絵文字リアクションを削除するには、絵文字をもう一度選択します。

## カスタム絵文字 {#custom-emoji}

{{< history >}}

- GitLab 13.6でGraphQL API向けに、`custom_emoji`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37911)されました。デフォルトでは無効になっています。
- GitLab 14.0でGitLab.comで有効になりました。
- 絵文字を追加するUIがGitLab 16.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/333095)。
- GitLab 16.7で[GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138969)で有効になりました。
- GitLab 16.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/)になりました。機能フラグ`custom_emoji`は削除されました。

{{< /history >}}

カスタム絵文字は、絵文字でリアクションできるすべての場所の絵文字ピッカーに表示されます。

コメントまたは説明に絵文字リアクションを追加するには:

1. **リアクションを追加**（{{< icon name="slight-smile" >}}）を選択します。
1. GitLabロゴ（{{< icon name="tanuki" >}}）を選択するか、**カスタム**セクションまでスクロールします。
1. 絵文字ピッカーから絵文字を選択します。

![リアクションピッカーのカスタム絵文字セクション。](img/custom_emoji_reactions_v16_2.png)

テキストボックスで使用するには、ファイル名を2つのコロンで囲んで入力します。たとえば`:thank-you:`などです。

### グループにカスタム絵文字をアップロード {#upload-custom-emoji-to-a-group}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128355)されました。

{{< /history >}}

すべてのサブグループとプロジェクトで使用するには、カスタム絵文字をグループにアップロードします。

前提要件: 

- グループのデベロッパーロール以上を持っている必要があります。

カスタム絵文字をアップロードするには:

1. 説明またはコメントで、**リアクションを追加**（{{< icon name="slight-smile" >}}）を選択します。
1. 絵文字ピッカーの下部にある**新しい絵文字を作成する**を選択します。
1. カスタム絵文字の名前とURLを入力します。
1. **保存**を選択します。

GraphQL APIを使用して、GitLabインスタンスにカスタム絵文字をアップロードすることもできます。詳細については、[GraphQLでカスタム絵文字を使用する](../api/graphql/custom_emoji.md)を参照してください。

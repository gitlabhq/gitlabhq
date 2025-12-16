---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 不正利用を報告する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

他のGitLabユーザーによる不正利用を、GitLab管理者に報告できます。

GitLabの管理者は、次の[選択ができます](../administration/review_abuse_reports.md):

- ユーザーを削除すると、インスタンスから削除されます。
- ユーザーをブロックすると、インスタンスへのアクセスが拒否されます。
- または、レポートを削除すると、ユーザーはインスタンスへのアクセスを保持します。

ユーザーは以下を通じて報告できます:

- [プロファイル](#report-abuse-from-the-users-profile-page)
- [コメント](#report-abuse-from-a-users-comment)
- [イシュー](#report-abuse-from-an-issue)
- [タスク](#report-abuse-from-a-task)
- [目標](#report-abuse-from-an-objective)
- [主な成果](#report-abuse-from-a-key-result)
- [マージリクエスト](#report-abuse-from-a-merge-request)
- [スニペット](snippets.md#mark-snippet-as-spam)

## ユーザーのプロファイルページから不正利用を報告 {#report-abuse-from-the-users-profile-page}

{{< history >}}

- オーバーフローメニューからの不正利用の報告は、`user_profile_overflow_menu_vue`という[フラグ](../administration/feature_flags/_index.md)を付けてGitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/414773)されました。デフォルトでは無効になっています。
- GitLab 16.4で[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/414773)になりました。
- GitLab 16.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/414773)になりました。機能フラグ`user_profile_overflow_menu_vue`は削除されました。

{{< /history >}}

ユーザーのプロファイルページから不正利用を報告するには、次の手順に従います:

1. GitLabの任意の場所で、ユーザーの名前を選択します。
1. ユーザーのプロフィールの右上隅にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、**不正利用を報告**を選択します。
1. ユーザーを報告する理由を選択します。
1. 不正利用のレポートを完了させます。
1. **レポートを送信**を選択します。

## ユーザーのコメントから不正利用を報告 {#report-abuse-from-a-users-comment}

{{< history >}}

- エピックのコメントからの不正利用の報告は、GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/389992)されました。

{{< /history >}}

ユーザーのコメントから不正利用を報告するには、次の手順に従います:

1. コメントの右上隅にある**追加のアクション**（{{< icon name="ellipsis_v" >}}）を選択します。
1. **不正利用を報告**を選択します。
1. ユーザーを報告する理由を選択します。
1. 不正利用のレポートを完了させます。
1. **レポートを送信**を選択します。

{{< alert type="note" >}}

報告されたユーザーのコメントへのURLは、不正利用のレポートの**メッセージ**フィールドに事前入力されています。

{{< /alert >}}

## イシューから不正利用を報告 {#report-abuse-from-an-issue}

1. イシューの右上隅にある**Issue actions**（{{< icon name="ellipsis_v" >}}）を選択します。
1. **不正利用を報告**を選択します。
1. ユーザーを報告する理由を選択します。
1. 不正利用のレポートを完了させます。
1. **レポートを送信**を選択します。

## タスクから不正利用を報告 {#report-abuse-from-a-task}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461848)されました。

{{< /history >}}

1. タスクの右上隅にある**追加のアクション**（{{< icon name="ellipsis_v" >}}）を選択します。
1. **不正利用を報告**を選択します。
1. ユーザーを報告する理由を選択します。
1. 不正利用のレポートを完了させます。
1. **レポートを送信**を選択します。

## 目標から不正利用を報告 {#report-abuse-from-an-objective}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461848)されました。

{{< /history >}}

1. Objectiveの右上隅にある**追加のアクション**（{{< icon name="ellipsis_v" >}}）を選択します。
1. **不正利用を報告**を選択します。
1. ユーザーを報告する理由を選択します。
1. 不正利用のレポートを完了させます。
1. **レポートを送信**を選択します。

## キー結果から不正利用を報告 {#report-abuse-from-a-key-result}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461848)されました。

{{< /history >}}

1. キー結果の右上隅にある**追加のアクション**（{{< icon name="ellipsis_v" >}}）を選択します。
1. **不正利用を報告**を選択します。
1. ユーザーを報告する理由を選択します。
1. 不正利用のレポートを完了させます。
1. **レポートを送信**を選択します。

## マージリクエストから不正利用を報告 {#report-abuse-from-a-merge-request}

1. マージリクエストの右上隅にある**マージリクエストのアクション**（{{< icon name="ellipsis_v" >}}）を選択します。
1. **不正利用を報告**を選択します。
1. このユーザーを報告する理由を選択します。
1. 不正利用のレポートを完了させます。
1. **レポートを送信**を選択します。

## 関連トピック {#related-topics}

- [不正利用レポート管理ドキュメント](../administration/review_abuse_reports.md)

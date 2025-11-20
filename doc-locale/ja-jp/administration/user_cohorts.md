---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: ユーザーの世代
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

時間の経過とともにユーザーのGitLabアクティビティーを分析できます。

ユーザーコホートテーブルをどのように解釈しますか？次のユーザーコホートの例を見てみましょう:

![保持と非アクティブのメトリクスを示すユーザーコホートテーブル、2020年3月と4月を強調表示。](img/cohorts_v13_9.png)

2020年3月のコホートでは、3人のユーザーがこのサーバーに追加され、今月以降アクティブになっています。1か月後（2020年4月）には、2人のユーザーがまだアクティブです。5か月後（2020年8月）には、このコホートの1人のユーザーがまだアクティブ、つまり3月に参加した3人の元のコホートの33％です。

**アクティブではないユーザー**列は、その月に追加されたものの、インスタンス内でアクティビティーがなかったユーザーの数を示しています。

ユーザーのアクティビティーをどのように測定しますか？GitLabでは、以下の場合にユーザーがアクティブであると見なされます:

- ユーザーがサインインする。
- ユーザーにGitアクティビティーがある（プッシュまたはプル）。
- ユーザーがダッシュボード、プロジェクト、イシュー、またはマージリクエストに関連するページにアクセスした場合
- ユーザーがAPIを使用する。
- ユーザーがGraphQL APIを使用する。

## ユーザーコホートを表示 {#view-user-cohorts}

ユーザーコホートを表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. **コホート**タブを選択します。

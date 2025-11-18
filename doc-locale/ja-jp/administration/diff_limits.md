---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: GitLabセルフマネージドで表示する差分の最大サイズを設定します。
title: 差分の制限の管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

サイズの大きいファイルのコンテンツをすべて表示すると、マージリクエストの読み込みが遅くなることがあります。これを防ぐため、差分サイズ、変更されたファイル数、変更された行数の最大値を設定します。これらの制限は、差分情報を返すGitLabユーザーインターフェースとAPIエンドポイントの両方に適用されます。

差分がいずれかの値の10%に達すると、GitLabはファイルを折りたたまれたビューで表示し、差分を展開するためのリンクを表示します。これらの値を超過する差分は**Too large**と表示され、UIで展開できません:

| 値 | 定義 | デフォルト値 | 最大値 |
| ----- | ---------- | :-----------: | :-----------: |
| **差分パッチの最大サイズ** | 全体の差分の合計サイズ（バイト単位）。 | 200 KiB | 500 KB |
| **Maximum diff files**（差分の最大ファイル数） | 差分で変更されたファイルの合計数。 | 1,000 | 3000 |
| **Maximum diff lines**（差分の最大行数） | 差分で変更された行の合計数。 | 50,000 | 100,000 |

[差分の制限は設定できません](../user/gitlab_com/_index.md#diff-display-limits) GitLab.comで設定できません。

差分ファイルの詳細については、[ファイル間の変更を表示します](../user/project/merge_requests/changes.md)を参照してください。[マージリクエストと差分の組み込み制限](instance_limits.md#merge-requests)の詳細をご覧ください。

## 差分制限の設定 {#configure-diff-limits}

{{< alert type="warning" >}}

これらの設定は試験的なものです。最大値を大きくすると、インスタンスのリソース消費量が増加します。最大値を調整する際は、この点に注意してください。

{{< /alert >}}

マージリクエストで差分表示の最大値を設定するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **差分の制限**を展開します。
1. 差分制限の値を入力します。
1. **変更を保存**を選択します。

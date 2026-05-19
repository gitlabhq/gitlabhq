---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: IBM DevOps ClearCaseから移行する
description: "IBM DevOps ClearCaseからGitへ移行する。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[IBM DevOps ClearCase](https://www.ibm.com/products/devops-code-clearcase)はIBMが開発したツール群で、Gitに似た集中型バージョン管理システムも含まれています。

次の表は、ClearCaseとGitの主な違いを示しています:

| 機能           | ClearCase                    | Git |
|:------------------|:-----------------------------|:----|
| リポジトリモデル  | クライアントサーバー                | 分散型 |
| リビジョンID      | ブランチ + 番号              | グローバル英数字ID |
| 変更のスコープ   | ファイル                         | ディレクトリツリースナップショット |
| 並行処理モデル | マージ                        | マージ |
| 保存方法    | 差分                       | 完全な内容 |
| クライアント            | CLI、Eclipse、CCクライアント      | CLI、Eclipse、Gitクライアント/GUI |
| サーバー            | UNIX、Windowsレガシーシステム | UNIX、macOS |
| ライセンス           | プロプライエタリ                  | GPL |

## Gitへの移行 {#migrate-to-git}

IBM DevOps ClearCaseからGitへ移行するためのツールは提供していません。移行に関する情報は、以下のリソースを参照してください:

- [GitとClearCaseのブリッジ](https://github.com/charleso/git-cc)
- [ClearCaseからGitへ](https://therub.org/2013/07/19/clearcase-to-git/)
- [Dual Syncing ClearCase to Git](https://therub.org/2013/10/22/dual-syncing-clearcase-and-git/)
- [ClearCaseからGitへの移行](https://sateeshkumarb.wordpress.com/2011/01/15/moving-to-git-from-clearcase/)

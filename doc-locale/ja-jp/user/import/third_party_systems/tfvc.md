---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Team Foundation Version Controlからの移行
description: "Team Foundation Version ControlからGitへ移行する。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Team Foundation Version Control](https://learn.microsoft.com/en-us/azure/devops/repos/tfvc/what-is-tfvc?view=azure-devops) (TFVC) は、Gitに似た集中型バージョン管理システムです。

TFVCとGitの主な違いは次のとおりです:

- TFVCがクライアントサーバーアーキテクチャを使用して集中型であるのに対し、Gitは分散型です。Gitはリポジトリ全体のコピーを操作するため、より柔軟なワークフローを備えています。例えば、リモートサーバーと通信することなく、素早くブランチを切り替えたり、マージしたりできます。
- 集中型バージョン管理システムでの変更はファイルごと（チェンジセット）ですが、Gitではコミットされたファイルは全体（スナップショット）として保存されます。

詳細については、以下を参照してください: 

- Microsoftの[GitとTFVCの比較](https://learn.microsoft.com/en-us/azure/devops/repos/tfvc/comparison-git-tfvc?view=azure-devops)。
- Wikipediaの[バージョン管理ソフトウェアの比較](https://en.wikipedia.org/wiki/Comparison_of_version_control_software)。

## Gitへの移行 {#migrate-to-git}

TFVCからGitへ移行するためのツールは提供していません。移行に関する情報は次のとおりです:

- Microsoft Windowsで移行する場合は、以下を参照してください:
  - [`git-tfs`](https://github.com/git-tfs/git-tfs)ツール。
  - この[TFSからGitへの移行情報](https://github.com/git-tfs/git-tfs/blob/master/doc/usecases/migrate_tfs_to_git.md)。
- Unixベースのシステムをお使いの場合は、この[TFVCからGitへの移行ツール](https://github.com/turbo/gtfotfs)を参照してください。

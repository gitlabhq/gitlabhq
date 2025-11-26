---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: TFVCからGitへ移行する
description: "Team Foundation Version Control（TFVC）からGitへ移行します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Team Foundation Server (TFS)（2019年に[Azure DevOps Server](https://azure.microsoft.com/en-us/products/devops/server/)に名称変更）は、Microsoftが開発した一連のツールであり、[Team Foundation Version Control](https://learn.microsoft.com/en-us/azure/devops/repos/tfvc/what-is-tfvc?view=azure-devops)（TFVC）（Gitと同様の集中型バージョン管理システム）も含まれています。

このドキュメントでは、TFVCからGitへの移行に焦点を当てています。

## TFVC対Git {#tfvc-vs-git}

TFVCとGitの主な違いは次のとおりです:

- Gitは分散型である: TFVCはクライアントサーバーアーキテクチャを使用して集中化されていますが、Gitは分散型です。これは、リポジトリ全体のコピーで作業するため、Gitのワークフローがより柔軟になることを意味します。これにより、リモートサーバーと通信しなくても、たとえば、ブランチをすばやく切り替えたり、マージしたりできます。
- ストレージ: 集中型バージョン管理システムの変更はファイルごと（チェンジセット）ですが、Gitではコミットされたファイルは全体（スナップショット）として保存されます。つまり、Gitでは変更全体を元に戻したり、取り消したりすることが非常に簡単です。

詳細については、以下を参照してください:

- Microsoftによる[GitとTFVCの比較](https://learn.microsoft.com/en-us/azure/devops/repos/tfvc/comparison-git-tfvc?view=azure-devops)。
- Wikipediaによる[バージョン管理システムの比較](https://en.wikipedia.org/wiki/Comparison_of_version_control_software)。

## 移行する理由 {#why-migrate}

Git/GitLabへ移行する利点:

- **No licensing costs**（ライセンス費用がかからない）: Gitはオープンソースですが、TFVCはプロプライエタリです。
- **Shorter learning curve**（学習期間の短縮）: Gitには大規模なコミュニティと、開始するための膨大な数のチュートリアルがあります（[Gitのトピック](../../../topics/git/_index.md)を参照）。
- **Integration with modern tools**（最新ツールとの統合）: GitとGitLabに移行すると、バージョン管理、イシュートラッキング、コードレビュー、CI/CDなどが組み込まれた、オープンソースのエンドツーエンドのソフトウェア開発プラットフォームを利用できます。

## 移行方法 {#how-to-migrate}

TFVCからGitへの移行オプションは、オペレーティングシステムによって異なります。

- Microsoft Windowsで移行する場合は、[`git-tfs`](https://github.com/git-tfs/git-tfs)ツールを使用してください。詳細については、[TFSからGitへの移行](https://github.com/git-tfs/git-tfs/blob/master/doc/usecases/migrate_tfs_to_git.md)を参照してください。
- Unixベースのシステムを使用している場合は、この[TFVCからGitへの移行ツール](https://github.com/turbo/gtfotfs)で説明されている手順に従ってください。

---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Perforce P4から移行する
description: "Perforce P4からGitへ移行する。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Perforce P4](https://www.perforce.com/)は、Gitに似た集中型の独自バージョン管理システムを含む一連のツールを提供します。

次に、Perforce P4とGitの主な違いを挙げます:

- Perforce P4のブランチは、Gitの軽量ブランチと比較して重いです。Perforce P4でブランチを作成すると、実際に変更されたファイルの数に関係なく、そのブランチ内のすべてのファイルに対して、独自のデータベースにインテグレーションレコードが作成されます。Gitでは、単一のSHAが変更後のリポジトリ全体の状態へのポインターとして機能し、フィーチャーブランチワークフローを採用する際に役立ちます。
- Gitでは、ブランチ間のコンテキスト切り替えがより簡単です。
- Gitでは、プロジェクトとその履歴の完全なコピーをローカルコンピュータに持つことで、すべてのトランザクションが非常に高速になります。ブランチする、マージする、分離して実験し、変更を他の人と共有する前にクリーンアップできます。
- 変更をデフォルトブランチにマージすることなく共有できるため、Gitはコードレビューをより簡単にします。Perforce P4は、他のユーザーが変更をマージする前にレビューできるように、サーバー上にShelving機能が必要でした。

## Gitへの移行 {#migrate-to-git}

Gitには、Perforce P4リポジトリとGitリポジトリ間を移動するためのサブコマンド (`git p4`) が含まれています。

詳細については、以下を参照してください: 

- [`git-p4`マニュアルページ](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-p4.html)
- [`git-p4`ドキュメント](https://git-scm.com/docs/git-p4)
- [Git book移行ガイド](https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git#_perforce_import)

`git p4`と`git filter-branch`は、小さく効率的なGitパックファイルを作成するにはあまり適していません。初めてGitLabサーバーに送信する前に、リポジトリを適切に再パックすることをお勧めします。詳細については、[このStackOverflowの質問](https://stackoverflow.com/questions/28720151/git-gc-aggressive-vs-git-repack)を参照してください。

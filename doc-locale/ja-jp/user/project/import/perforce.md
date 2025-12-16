---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Perforce Helixからの移行
description: "Perforce HelixからGitへ移行します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Perforce Helix](https://www.perforce.com/)は、Gitと同様に、集中型のプロプライエタリなバージョン管理システムを含むツールセットを提供します。

## PerforceとGitの比較 {#perforce-vs-git}

以下は、Perforce HelixとGitの主な違いを示しています:

- 一般的に、最大の違いは、Perforceのブランチが、Gitの軽量ブランチと比較して、重いことです。Perforceでブランチを作成すると、実際に変更されたファイルの数に関係なく、ブランチ内のすべてのファイルについて、独自のデータベースに統合レコードが作成されます。一方、Gitでは、単一のSHAが、変更後のリポジトリ全体の状態へのポインターとして機能し、フィーチャーブランチワークフローを採用する際に役立ちます。
- Gitでは、ブランチ間のコンテキスト切り替えがより複雑ではありません。マネージャーが「新しい機能の作業を停止して、このセキュリティ脆弱性を修正する必要がある」と言った場合、Gitはこれを行うのに役立ちます。
- プロジェクトとその履歴の完全なコピーをローカルコンピューターに保存すると、すべてのトランザクションが非常に高速になり、Gitはそれを提供します。ブランチまたはマージを実行し、分離して実験してから、他のユーザーと変更を共有する前にクリーンアップできます。
- Gitを使用すると、変更をデフォルトブランチにマージしなくても変更を共有できるため、コードレビューが複雑になりません。これはPerforceと比較したもので、サーバーにシェルブ機能が実装されているため、他のユーザーはマージする前に変更をレビューできます。

## 移行する理由 {#why-migrate}

Perforce Helixは、ユーザーと管理者の両方の観点から管理が難しい場合があります。Git/GitLabに移行すると、次のようになります:

- ライセンス費用はかかりません: Perforce Helixがプロプライエタリであるのに対し、GitはGPLです。
- 学習曲線が短い: Gitには大規模なコミュニティと、開始するための多数のチュートリアルがあります。
- 最新のツールとの統合: GitとGitLabに移行することにより、オープンソースのエンドツーエンドソフトウェア開発プラットフォームを、組み込みのバージョン管理、イシュートラッキング、コードレビュー、CI/CDなどで利用できます。

## 移行する方法 {#how-to-migrate}

Gitには、Perforceからコードをプルし、GitからPerforceに送信するための組み込みメカニズム（`git p4`）が含まれています。

開始するためのリンクをいくつか示します:

- [`git-p4`のマニュアルページ](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-p4.html)
- [`git-p4`の使用例](https://archive.kernel.org/oldwiki/git.wiki.kernel.org/index.php/Git-p4_Usage.html)
- [Git book移行ガイド](https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git#_perforce_import)

`git p4`と`git filter-branch`は、小さくて効率的なGitパックファイルの作成にはあまり適していません。そのため、GitLabサーバーに初めて送信する前に、時間とCPUを費やしてリポジトリを適切に再パックファイルすることをお勧めします。[このStackOverflowの質問](https://stackoverflow.com/questions/28720151/git-gc-aggressive-vs-git-repack/)を参照してください。

## 関連トピック {#related-topics}

- [Git Fusionを使用したPerforce Helixとのミラー](../repository/mirror/bidirectional.md#mirror-with-perforce-helix-with-git-fusion)

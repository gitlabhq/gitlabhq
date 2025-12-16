---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ClearCaseからの移行
description: "IBM ClearCaseからGitへ移行します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[ClearCase](https://www.ibm.com/products/devops-code-clearcase)は、IBMが開発したツールセットであり、Gitと同様の集中型バージョン管理システムも含まれています。

ClearCaseの基本的な概念については、こちらの[StackOverflow post](https://stackoverflow.com/a/645771/974710)をご覧ください。

以下の表は、ClearCaseとGitの主な違いを示しています:

| 側面 | ClearCase | Git |
| ------ | --------- | --- |
| リポジトリモデル | クライアント/サーバー | 分散 |
| リビジョンID | ブランチ + 番号  | グローバル英数字ID |
| 変更スコープ | ファイル | ディレクトリツリースナップショット |
| 並行処理モデル | マージ | マージ |
| ストレージ方法 | 差分 | フルコンテンツ |
| クライアント | CLI、Eclipse、CC Client | CLI、Eclipse、Gitクライアント/GUI |
| サーバー | UNIX、Windowsレガシーシステム | UNIX、macOS |
| ライセンス | プロプライエタリ | GPL |

## 移行する理由 {#why-migrate}

ClearCaseは、ユーザーと管理者の両方の観点から管理が難しい場合があります。Git/GitLabに移行すると、次のようになります:

- ライセンス費用はかかりません: GitはGPLですが、ClearCaseはプロプライエタリです。
- 学習曲線がより短い: Gitには大規模なコミュニティと、始めるための膨大な数のチュートリアルがあります。
- 最新ツールとのインテグレーション: GitとGitLabに移行することで、バージョン管理、イシュートラッキング、コードレビュー、継続的インテグレーションとデリバリーなどを組み込んだオープンソースのエンドツーエンドのソフトウェア開発プラットフォームを手に入れることができます。

## 移行方法 {#how-to-migrate}

ClearCaseからGitに完全に移行するためのツールは存在しませんが、開始に役立つ便利なリンクを以下に示します:

- [Bridge for Git and ClearCase](https://github.com/charleso/git-cc)

- [ClearCase to Git](https://therub.org/2013/07/19/clearcase-to-git/)
- [Dual Syncing ClearCase to Git](https://therub.org/2013/10/22/dual-syncing-clearcase-and-git/)
- [Moving to Git from ClearCase](https://sateeshkumarb.wordpress.com/2011/01/15/moving-to-git-from-clearcase/)
- [ClearCase to Git webinar](https://www.brighttalk.com/webcast/11817/162473)

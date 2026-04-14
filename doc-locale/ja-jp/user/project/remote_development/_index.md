---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: ウェブブラウザを使用して、セキュアな環境でコードを記述します。
title: リモート開発
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

リモート開発は、依存関係をインストールしたり、リポジトリをローカルにクローンしたりすることなく、コード変更を行うために使用できる一連の機能です。これらの機能には以下が含まれます:

- [Web IDE](#web-ide)
- [ワークスペース](#workspaces)

## Web IDE {#web-ide}

[Web IDE](../web_ide/_index.md)を使用して、ウェブブラウザから直接プロジェクトに変更を加え、コミット、プッシュできます。この方法により、依存関係をインストールしたり、リポジトリをローカルにクローンしたりすることなく、任意のプロジェクトを更新できます。

しかし、Web IDEには、コードをコンパイルしたり、テストを実行したり、リアルタイムのフィードバックを生成したりできるネイティブのランタイム環境がありません。

## ワークスペース {#workspaces}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

[ワークスペース](../../workspace/_index.md)を使用して、GitLabから直接、フル機能の開発環境を作成できます。この環境はリモートサーバー上で動作し、依存関係をインストールしたり、リポジトリをローカルにクローンしたりすることなく、完全なIDEエクスペリエンスを提供します。

ワークスペースを使用すると、次のことができます:

- 新しい開発環境を作成します。
- コードエディタ、ターミナル、ビルドツールを含む、フル機能のIDEにアクセスします。
- マージリクエストやCI/CDパイプラインを含む、ワークスペースをGitLabの他の部分と統合します。

---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Webブラウザを使用して、安全な環境でコードを記述します。
title: リモート開発
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

リモート開発は、依存関係をインストールしたり、リポジトリをローカルに複製したりすることなく、コードを変更するために使用できる一連の機能です。これらの機能には、次のものがあります:

- [Web IDE](#web-ide)
- [ワークスペース](#workspaces)

## Web IDE {#web-ide}

[Web IDE](../web_ide/_index.md)を使用して、Webブラウザから直接プロジェクトに対して変更を加え、コミットし、プッシュすることができます。これにより、依存関係をインストールしたり、リポジトリをローカルに複製したりすることなく、任意のプロジェクトを更新できます。

ただし、Web IDEには、コードをコンパイルしたり、テストを実行したり、リアルタイムのフィードバックを生成したりできるネイティブランタイム環境がありません。

## ワークスペース {#workspaces}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

[ワークスペース](../../workspace/_index.md)を使用すると、GitLabから直接、フル機能を備えた開発環境を作成できます。この環境はリモートサーバー上で実行され、依存関係をインストールしたり、リポジトリをローカルに複製したりすることなく、完全なIDEエクスペリエンスを提供します。

ワークスペースを使用すると、次のことができます:

- 新しい開発環境を作成します。
- コードエディタ、ターミナル、ビルドツールなど、フル機能を備えたIDEにアクセスします。
- マージリクエストとCI/CDパイプラインを含む、残りのGitLabとワークスペースを統合します。

---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab VS Code拡張機能を使用して、セキュリティスキャンを実行し、レビューを行います。
title: VS Code向けGitLabでアプリケーションを保護する
---

GitLab VS Code拡張機能を使用して、アプリケーションのセキュリティ脆弱性を確認します。セキュリティ検出結果をレビューし、静的アプリケーションセキュリティテスト（SAST）をIDEで直接ファイルに対して実行します。

## セキュリティ検出結果を表示する {#view-security-findings}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提条件: 

- GitLab for VS Code 3.74.0以降。
- [Security Risk Management](https://about.gitlab.com/features/?stage=secure)機能を含むプロジェクト（静的アプリケーションセキュリティテスト（SAST）、動的アプリケーションセキュリティテスト（DAST）、コンテナスキャン、依存関係スキャンなど）。
- [security risk management](../../user/application_security/secure_your_application.md)機能が構成されていること。

セキュリティ検出結果を表示するには、次の手順に従います。

1. VS Codeの左側のサイドバーで、**GitLab** ({{< icon name="tanuki" >}}) を選択します。
1. 現在のブランチセクションで、**セキュリティスキャン**を展開します。
1. **New findings**（新しい検出結果）または**Fixed findings**（修正された検出結果）のいずれかを選択します。
1. 重大度レベルを選択します。
1. 検出結果を選択すると、VS Codeタブで開きます。

## SASTスキャンを実行する {#perform-sast-scanning}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1675): VS Code拡張機能5.31で。

{{< /history >}}

VS Codeの静的アプリケーションセキュリティテスト（SAST）は、アクティブなファイルの脆弱性を検出します。早期に検出することで、変更をデフォルトブランチにマージする前に脆弱性を修正できます。

SASTスキャンをトリガーすると、アクティブなファイルの内容がGitLabに渡され、SAST脆弱性ルールに照らしてチェックされます。GitLabは、**GitLab** ({{< icon name="tanuki" >}}) 拡張機能パネルにスキャン結果を表示します。

<i class="fa-youtube-play" aria-hidden="true"></i>SASTスキャンのセットアップについては、GitLab Unfilteredの[SAST scanning in VS Code](https://www.youtube.com/watch?v=s-qOSQO0i-8)（VS CodeでのSASTスキャン）を参照してください。
<!-- Video published on 2025-02-10 -->

前提条件: 

- GitLab for VS Code 5.31.0以降。
- 拡張機能が[GitLabで認証済み](setup.md#authenticate-with-gitlab)であること。
- リアルタイムのSASTスキャンが[有効](setup.md#code-security)であること。

VS CodeでファイルのSASTスキャンを実行するには、次の手順に従います。

1. ファイルを開きます。
1. 次のいずれかの方法でSASTスキャンをトリガーします。
   - ファイルを保存する（[ファイル保存時のスキャン](setup.md#code-security)を有効にしている場合）。
   - コマンドパレットを使用する。
     1. コマンドパレットを開きます。
        - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
        - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
     1. **GitLab: Run Remote Scan (SAST)**（GitLab: リモートスキャン（SAST）を実行する）を検索し、<kbd>Enter</kbd>キーを押します。
1. SASTスキャンの結果を表示します。
   1. VS Codeの左側のサイドバーで、**GitLab** ({{< icon name="tanuki" >}}) を選択します。
   1. GitLabリモートスキャン（SAST）セクションを展開します。SASTスキャンの結果は、重大度の降順で一覧表示されます。
   1. 詳細をレビューするには、検出結果を選択します。

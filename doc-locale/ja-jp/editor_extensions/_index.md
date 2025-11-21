---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabの機能をVisual Studio Code、JetBrains IDE、Visual Studio、Eclipse、Neovimに拡張します。
title: エディタ拡張機能
---

GitLabエディタ拡張機能を使用すると、GitLabとGitLab Duoのパワーを、お好みの開発環境に直接取り込むことができます。GitLabの機能とGitLab Duo AI機能を使用して、エディタを離れることなく、日々のタスクを処理できます。例: 

- プロジェクトを管理します。
- コードを記述およびレビューします。
- イシューを追跡します。
- パイプラインを最適化します。

これらの拡張機能は、コーディング環境とGitLabの間のギャップを埋めることで、生産性を向上させ、開発プロセスを向上させます。

## 利用可能な拡張機能 {#available-extensions}

GitLabは、次の開発環境に対応した拡張機能を提供しています:

- [VS Code用GitLab Workflow拡張機能](visual_studio_code/_index.md): GitLab Duoやその他のGitLabの機能をVisual Studio Codeに取り込みます。
- [JetBrains IDE向けGitLab Duo](jetbrains_ide/_index.md): GitLab Duo AI機能をIntelliJ IDEA、PyCharm、WebStorm、その他のJetBrains IDEにもたらします。
- [Visual Studio用のGitLab拡張機能](visual_studio/_index.md): GitLab Duoコード提案をVisual Studioにもたらします。
- [Eclipse用GitLab](eclipse/_index.md): GitLab Duoの機能をEclipseにもたらします。

コマンドラインインターフェースを使用する場合は、以下を試してください:

- GitLab CLIを[`glab`](gitlab_cli/_index.md)。
- [Neovim用GitLab.nvim](neovim/_index.md): GitLab Duoのコード提案をターミナルウィンドウのNeovimに直接取り込みます。

## 機能 {#features}

当社のエディタ拡張機能は、強力なGitLab Duoインテグレーションを提供し、Visual Studio Codeと`glab`はインテグレーションされたGitLabワークフローエクスペリエンスを備えています。

### GitLab Duoコード提案 {#gitlab-duo-code-suggestions}

[GitLab Duoコード提案](../user/project/repository/code_suggestions/_index.md)は、AIアシストコーディング機能を提供します:

- コード補完: 入力中の現在のコード行に対する補完候補を表示します。これを使用して、1つまたは複数のコード行を完成させます。
- コード生成: 自然言語コードのコメントブロックに基づいてコードを生成します。コメントを記述し、<kbd>Enter</kbd>を押して、コメントのコンテキストと残りのコードに基づいてコードを生成します。
- コンテキスト認識型の候補: IDEで開いているファイル、カーソルの前後のコンテンツ、ファイル名、拡張子の種類を使用して、関連性の高い候補を提供します。
- 複数の言語のサポート: 開発環境でサポートされているさまざまなプログラミング言語で動作します。

### GitLab Duoチャット {#gitlab-duo-chat}

[GitLab Duoチャット](../user/gitlab_duo_chat/_index.md)を使用して、開発環境でAIアシスタントと直接やり取りします。

- GitLabについて: GitLabの仕組み、コンセプト、ステップごとの手順に関する回答を入手できます。
- コード関連のクエリ: コードスニペットの説明を求めたり、テストを生成したり、IDEで選択したコードをリファクタリングしたりできます。

## エディタ拡張機能チーム手順書 {#editor-extensions-team-runbook}

サポートされているすべてのエディタ拡張機能のデバッグの詳細については、[エディタ拡張機能チーム手順書](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/editor-extensions)を参照してください。内部ユーザーの場合、この手順書には、内部ヘルプをリクエストするための手順が記載されています。

## フィードバックとコントリビュート {#feedback-and-contributions}

従来の機能とAIネイティブ機能の両方に関するご意見をお待ちしております。拡張機能の開発について、ご提案や問題点、またはコントリビュートしたいことがございましたら:

- GitLabプロジェクトで問題をレポートします。
- [エディタ拡張機能プロジェクト](https://gitlab.com/gitlab-org/editor-extensions/product/-/issues/)で新しいイシューを作成して、機能リクエストを送信してください。
- それぞれのGitLabプロジェクトでマージリクエストを送信します。

## 関連トピック {#related-topics}

- [VS Code用GitLab Workflow拡張機能の作成方法](https://about.gitlab.com/blog/2020/07/31/use-gitlab-with-vscode/)
- [Visual Studio用GitLab](https://about.gitlab.com/blog/2023/06/29/gitlab-visual-studio-extension/)
- [JetBrainsおよびNeovim用GitLab](https://about.gitlab.com/blog/2023/07/25/gitlab-jetbrains-neovim-plugins/)
- [GitLab CLIを使用して、`glab`をすぐに利用できるようにする](https://about.gitlab.com/blog/2022/12/07/introducing-the-gitlab-cli/)

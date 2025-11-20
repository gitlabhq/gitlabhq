---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Visual StudioでGitLab Duoに接続して使用します。
title: Visual Studio用GitLab拡張機能をインストールして設定する
---

拡張機能を入手するには、次のいずれかの方法を使用します:

- Visual Studio内で、アクティビティーバーから**Extensions** を選択し、`GitLab`索します。
- [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio)から。
- GitLabから、[リリースのリスト](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/releases) 、または[最新バージョンを直接ダウンロード](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/releases/permalink/latest/downloads/GitLab.Extension.vsix)します。

拡張機能の要件:

- Visual Studio 2022バージョン17.6以降（AMD64またはArm64）。
- Visual Studio用[IntelliCode](https://visualstudio.microsoft.com/services/intellicode/)コンポーネント。
- GitLabバージョン16.1以降。
  - GitLab Duoコード提案を使用するには、GitLabバージョン16.8以降が必要です。
- Visual Studio for Macはサポートされていないため、使用できません。

この機能を有効にするために、新しい追加データが収集されることはありません。非公開のGitLab顧客データは、トレーニングデータとして使用されません。[Google Vertex AI Codey APIのデータガバナンス](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance)の詳細について確認ください。

## GitLabに接続する {#connect-to-gitlab}

拡張機能をインストールしたら、パーソナルアクセストークンを作成し、GitLabで認証して、GitLabアカウントに接続します。

### パーソナルアクセストークンを作成する {#create-a-personal-access-token}

GitLabセルフマネージドを使用している場合は、パーソナルアクセストークンを作成してください。

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**パーソナルアクセストークン**を選択します。
1. **新しいトークンを追加**を選択します。
1. 名前、説明、有効期限を入力します。
1. `api`と`read_user`のスコープを選択します。
1. **Create personal access token**（パーソナルアクセストークンを作成）を選択します。

### GitLabに対して認証する {#authenticate-with-gitlab}

次に、GitLabで認証します。

1. Visual Studioの上部バーで、**ツール** > **オプション** > **GitLab**に移動します。
1. **アクセストークン**フィールドに、トークンを貼り付けます。トークンは表示されず、他のユーザーもアクセスできません。
1. **GitLab URL**（GitLab URL）テキストボックスに、GitLabインスタンスのURLを入力します。GitLab.comの場合は、`https://gitlab.com`を使用します。

## テレメトリを有効にする {#enable-telemetry}

GitLab拡張機能は、Visual Studio Codeのテレメトリ設定を使用して、使用状況とエラー情報をGitLabに送信します。Visual Studio用GitLabでテレメトリを有効にするには:

1. Visual Studioの上部バーで、**ツール** > **オプション**に移動します。
1. 左側のサイドバーで、**GitLab**を展開し、**一般**を選択します。
1. **Enable telemetry**（テレメトリの有効化）ドロップダウンリストで、**true**を選択します。
1. **OK**を選択します。

## 拡張機能を設定する {#configure-the-extension}

この拡張機能は、GitLabで使用できるカスタムコマンドを提供します。ほとんどのコマンドには、既存のVisual Studio設定との競合を避けるために、デフォルトのキーボードショートカットがありません。

| コマンド名                          | デフォルトのキーボードショートカット                   | 説明 |
|---------------------------------------|---------------------------------------------|-------------|
| `GitLab.ToggleCodeSuggestions`        | なし                                        | コード提案をオンまたはオフにします。 |
| `GitLab.OpenDuoChat`                  | なし                                        | GitLab Duoチャットを開きます。  |
| `GitLab.GitLabDuoNextSuggestions`     | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>N</kbd> | 次のコード提案に切り替えます。 |
| `GitLab.GitLabDuoPreviousSuggestions` | なし                                        | 前のコード提案に切り替えます。 |
| `GitLab.GitLabExplainTerminalWithDuo` | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>E</kbd> | ターミナルで選択したテキストを説明します。 |
| `GitLabDuoChat.ExplainCode`           | なし                                        | 選択したコードを説明します。 |
| `GitLabDuoChat.Fix`                   | なし                                        | 選択したコードのイシューを修正します。 |
| `GitLabDuoChat.GenerateTests`         | なし                                        | 選択したコードのテストを生成します。 |
| `GitLabDuoChat.Refactor`              | なし                                        | 選択したコードをリファクタリングします。 |

キーボードショートカットを使用して、拡張機能のカスタムコマンドにアクセスできます。これらはカスタマイズできます:

1. 上部のバーで、**ツール** > **オプション**に移動します。
1. **環境** > **Keyboard**（キーボード）に移動します。`GitLab.`を検索します。
1. コマンドを選択し、キーボードショートカットを割り当てます。

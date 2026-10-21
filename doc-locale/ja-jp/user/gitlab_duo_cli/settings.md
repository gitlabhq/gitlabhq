---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 設定パネルまたは設定ファイルでGitLab Duo CLIの設定を変更し、管理設定ファイルで設定を強制します。
title: GitLab Duo CLIの設定
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Duo CLIの動作は、次の方法で変更できます:

- インタラクティブモードから、[設定パネル](#settings-panel)で変更する方法。
- 設定パネルでの選択内容を保存する[設定ファイル](#settings-file)で変更する方法。ファイルを直接編集することもできます。
- システム管理者が設定を強制するためにデプロイする[管理設定ファイル](#managed-settings-file)を使用する方法。

## 設定パネル {#settings-panel}

{{< history >}}

- GitLab 19.0リリース時に、GitLab Duo CLI 8.90.0で、設定パネルが[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.90.0)されました。
- GitLab 19.4リリース時に、GitLab Duo CLI 9.11.0で、新しいセッションで作業アイテムを表示する設定が[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.11.0)されました。
- GitLab 19.4リリース時に、GitLab Duo CLI 9.11.0で、テーマを調整する設定が[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.11.0)されました。
- GitLab 19.5リリース時に、GitLab Duo CLI 9.24.0で、提案されたプロンプトを`/goal`セッションとして実行する設定が[導入されました](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.24.0)。

{{< /history >}}

設定を変更するには:

1. インタラクティブモードで`/settings`と入力し、<kbd>Enter</kbd>を押します。
1. 矢印キーを使用して、設定のリスト内を移動します。
1. 選択した設定を変更するには、<kbd>Enter</kbd>または<kbd>Space</kbd>を押します。
1. パネルを閉じるには、<kbd>Escape</kbd>を押します。

変更内容は、セッションをまたいで設定ファイルに保持されます。組織が設定を強制している場合、パネルには**組織によって設定済み**と表示され、変更できません。

次の設定を使用できます:

| 設定                  | 説明                                                                                       |
|--------------------------|---------------------------------------------------------------------------------------------------|
| **Telemetry**            | GitLab Duoの改善に役立てるため、匿名の使用状況データを送信します。                                                  |
| **Notifications**        | [システム通知](use.md#system-notifications)（`auto`または`disabled`）を制御します。                     |
| **Show work items on session start** | 新しいセッションを開始するときに、未完了の作業アイテムを表示します。 |
| **Run suggested prompts as /goal sessions** | 提案されたプロンプトを、通常のチャットメッセージではなく`/goal`セッションとして実行します。変更を有効にするには再起動が必要です。 |
| **Theme**        | テーマの設定を変更します。オプションには、`auto`、`dark`、`light`、`dark high contrast`、`light high contrast`があります。 |

## 設定ファイル {#settings-file}

{{< history >}}

- GitLab 19.5リリース中のGitLab Duo CLI 9.26.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.26.0)されました。

{{< /history >}}

GitLab Duo CLIは、`/settings`パネルで変更した設定を設定ファイルに保存します。ファイルを直接編集することも、たとえばコンテナイメージ内で事前に作成することもできます。

GitLab Duo CLIは、起動時にファイルを読み込みます。ファイルに加えた変更は、次回GitLab Duo CLIを起動したときに適用されます。

### ファイルの場所 {#file-location}

ファイルの場所は、使用しているオペレーティングシステムによって異なります:

| オペレーティングシステム | パス                                 |
|------------------|--------------------------------------|
| LinuxおよびmacOS  | `~/.gitlab/duo/settings.json`        |
| Windows          | `%APPDATA%\GitLab\duo\settings.json` |

`XDG_CONFIG_HOME`を設定している場合、ファイルは`$XDG_CONFIG_HOME/gitlab/duo/settings.json`になります。

GitLab Duo CLIは、`/settings`パネルで初めて設定を変更したときにファイルを作成します。

### ファイル形式 {#file-format}

ファイルにはJSONオブジェクトを含める必要があり、コメント（`//`および`/* */`）や末尾のカンマを含めることができます。`/settings`パネルで設定を変更しても、GitLab Duo CLIはコメント、フォーマット、認識できないキーをそのまま保持します。

次の例では、すべての設定をデフォルト値に設定しています:

```json
{
  "telemetry": {
    "enabled": true
  },
  "showWorkItemsInNewSessions": true,
  "goalFlowInWelcomePrompts": true,
  "notifications": {
    "channel": "auto" // or "disabled"
  },
  "theme": "auto" // or "dark", "light", "dark-high-contrast", "light-high-contrast"
}
```

### 無効なファイルと値 {#invalid-files-and-values}

GitLab Duo CLIは、ファイルを修正するために削除または書き換えることはありません:

- ファイルが有効なJSONでない場合、GitLab Duo CLIはファイル全体を無視し、警告をログに記録します。
- 設定に無効な値が含まれている場合、GitLab Duo CLIはその設定を無視し、警告をログに記録します。
- GitLab Duo CLIが、たとえば新しいバージョンの設定など、認識できない設定がある場合、その設定は無視されます。

ファイルが読み取り専用の場合、`/settings`パネルで行った変更は現在のセッションにのみ適用されます。

## 管理設定ファイル {#managed-settings-file}

{{< history >}}

- GitLab 19.5リリース中のGitLab Duo CLI 9.27.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.27.0)されました。

{{< /history >}}

設定を強制するために、システム管理者は各マシンに管理設定ファイルをデプロイします。たとえば、モバイルデバイス管理ツールやグループポリシーを使用できます。

管理設定ファイル内の設定は、コマンドラインオプション、環境変数、設定ファイル（設定パネルでユーザーが行った変更を含む）よりも優先されます。

強制された設定は、ユーザーが変更できません。ファイルにない設定は、引き続きユーザーが制御できます。

### ファイルの場所 {#file-location-1}

GitLab Duo CLIは、変更できない固定の場所からファイルを読み込みます:

| オペレーティングシステム                  | パス                                                            |
|-----------------------------------|-----------------------------------------------------------------|
| Linuxおよびその他のオペレーティングシステム | `/etc/gitlab/duo/settings.managed.json`                         |
| macOS                             | `/Library/Application Support/GitLab/duo/settings.managed.json` |
| Windows                           | `C:\Program Files\GitLab\duo\settings.managed.json`             |

書き込みアクセスをシステム管理者に制限し、他のすべてのユーザーには読み取り専用アクセスを付与します。

GitLab Duo CLIは、起動時にファイルを読み込みます。ファイルへの変更は、次回ユーザーがGitLab Duo CLIを起動したときに適用されます。

Windows Subsystem for Linux（WSL）では、GitLab Duo CLIはディストリビューション内のLinuxパスを読み込み、Windowsグループポリシーは適用されません。

### ファイル形式 {#file-format-1}

ファイルにはJSONオブジェクトを含める必要があり、コメント（`//`および`/* */`）や末尾のカンマを含めることができます。

次の例では、強制できるすべての設定を設定しています:

```json
{
  "telemetry": {
    "enabled": false
  },
  "showWorkItemsInNewSessions": true,
  "goalFlowInWelcomePrompts": true,
  "notifications": {
    "channel": "auto" // or "disabled"
  },
}
```

## 設定の優先順位 {#settings-precedence}

各設定について、GitLab Duo CLIは次の順序で最初に見つかった値を使用します:

1. 組織が設定を強制している場合は、管理設定ファイル。
1. 現在のセッションにのみ適用される、コマンドラインオプションと環境変数。
1. 設定ファイル。
1. デフォルト値。

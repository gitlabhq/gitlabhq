---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Web IDEを使用して、GitLab UIで複数のファイルを編集し、コミットをステージングして、マージリクエストを作成します。
title: Web IDE
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188427)になりました。機能フラグ`vscode_web_ide`は削除されました。

{{< /history >}}

Web IDEは高度なエディタであり、直接GitLab UIで複数のファイルを編集したり、変更をステージングしたり、コミットを作成したりできます。[Webエディタ](../repository/web_editor.md)とは異なり、Web IDEはソース管理機能を備えたフル機能の開発環境を提供します。

Web IDEでの[GitLab Flavored Markdown](../../markdown.md)のプレビューのサポートは、[エピック15810](https://gitlab.com/groups/gitlab-org/-/epics/15810)で提案されています。

## Web IDEを開く {#open-the-web-ide}

Web IDEには、いくつかの方法でアクセスできます。

### キーボードショートカットを使用する {#with-a-keyboard-shortcut}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. <kbd>.</kbd>キーボードショートカットを使用します。

### ディレクトリから {#from-a-directory}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. ディレクトリに移動します。
1. **コード** > **Web IDEで開く**を選択します。

### ファイルから {#from-a-file}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. ファイルに移動します。
1. **編集** > **Web IDEで開く**を選択します。

### マージリクエストから作成する {#from-a-merge-request}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. マージリクエストに移動します。
1. 右上で、**コード** > **Web IDEで開く**を選択します。

Web IDEでは、新規ファイルと変更されたファイルが別々のタブで開き、変更点が並んで表示されます。読み込み時間を短縮するため、変更された行数が最も多い10個のファイルのみが自動的に開きます。

Web IDEインターフェースの左側のサイドバーの**エクスプローラー**ビューで、新規または変更されたファイルの横に、マージリクエストアイコン（{{< icon name="merge-request" >}}）が表示されます。ファイルの変更を表示するには、ファイルを右クリックして**マージリクエストベースと比較**を選択します。

## ファイルを管理する {#manage-files}

Web IDEを使用して、複数のファイルを開いたり、編集したり、アップロードしたりできます。

### ファイルを開く {#open-a-file}

Web IDEでファイル名を指定してファイルを開くには:

1. <kbd>Command</kbd>+<kbd>P</kbd>を押します。
1. 検索ボックスに、ファイル名を入力します。

### 開いているファイルを検索する {#search-open-files}

Web IDEで開いているファイルを検索するには:

1. <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>F</kbd>を押します。
1. 検索ボックスに検索語句を入力します。

### ファイルをアップロードする {#upload-a-file}

Web IDEでファイルをアップロードするには:

1. Web IDEの左側で、**エクスプローラー**（{{< icon name="documents" >}}）を選択するか、<kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>E</kbd>を押します。
1. ファイルをアップロードするディレクトリに移動します。新しいディレクトリを作成するには:

   - **エクスプローラー**ビューの右上にある**新しいフォルダー**（{{< icon name="folder-new" >}}）を選択します。

1. ディレクトリを右クリックして、**アップロード**を選択します。
1. アップロードするファイルを選択します。

一度に複数のファイルをアップロードできます。ファイルがアップロードされ、自動的にリポジトリに追加されます。

### コミットされていない変更を復元する {#restore-uncommitted-changes}

Web IDEで編集するファイルを手動で保存する必要はありません。Web IDEは変更したファイルをステージングするため、[変更をコミットできます](#commit-changes)。コミットされていない変更は、ブラウザのローカルストレージに保存されます。ブラウザのタブを閉じたり、Web IDEを更新したりしても、変更は保持されます。

コミットされていない変更が利用できない場合は、ローカル履歴から変更を復元できます。Web IDEでコミットされていない変更を復元するには、次の手順に従います。

1. <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>P</kbd>を押します。
1. 検索ボックスに、`Local History: Find Entry to Restore`と入力します。
1. コミットされていない変更を含むファイルを選択します。

## ソース管理を使用する {#use-source-control}

ソース管理を使用して、変更されたファイルを表示したり、ブランチを作成および切り替えたり、変更をコミットしたり、マージリクエストを作成したりできます。

### 変更されたファイルを表示する {#view-modified-files}

Web IDEで変更したファイルの一覧を表示するには:

- Web IDEの左側で、**ソース管理** ({{< icon name="branch" >}}) を選択するか、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>を押します。

`CHANGES`、`STAGED CHANGES`、および`MERGE CHANGES`が表示されます。詳細については、[VS Codeドキュメント](https://code.visualstudio.com/docs/sourcecontrol/overview#_commit)を参照してください。

### ブランチを切り替える {#switch-branches}

Web IDEでは、デフォルトで現在のブランチが使用されます。Web IDEでブランチを切り替えるには、次の手順に従います。

1. 下部のステータスバーの左側で、現在のブランチ名を選択します。
1. 既存のブランチを入力または選択します。

### ブランチを作成する {#create-a-branch}

Web IDEで現在のブランチからブランチを作成するには:

1. 下部のステータスバーの左側で、現在のブランチ名を選択します。
1. ドロップダウンリストから、**新しいブランチを作成**を選択します。
1. 新しいブランチ名を入力します。

Web IDEは、チェックアウトしたブランチをベースとしてブランチを作成します。または、異なるベースからブランチを作成するには、以下の手順に従ってください:

1. Web IDEの左側で、**ソース管理** ({{< icon name="branch" >}}) を選択するか、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>を押します。
1. ソース管理パネルの右上にある省略記号メニュー ({{< icon name="ellipsis_h" >}}) を選択します。
1. ドロップダウンリストから、**ブランチ** > **Create branch from...**を選択します。
1. ドロップダウンリストから、ベースとして使用するブランチを選択します。

リポジトリへの書き込みアクセス権がない場合、**新しいブランチを作成**は表示されません。

### ブランチの削除 {#delete-a-branch}

1. Web IDEの左側で、**ソース管理** ({{< icon name="branch" >}}) を選択するか、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>を押します。
1. ソース管理パネルの右上にある省略記号メニュー ({{< icon name="ellipsis_h" >}}) を選択します。
1. ドロップダウンリストから、**ブランチ** > **ブランチを削除**を選択します。
1. ドロップダウンリストから、削除したいブランチを選択します。

Web IDEからは保護ブランチを削除できません。

### 変更をコミットする {#commit-changes}

Web IDEで変更をコミットするには:

1. Web IDEの左側で、**ソース管理** ({{< icon name="branch" >}}) を選択するか、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>を押します。
1. コミットメッセージを入力します。
1. 次のいずれかのコミットオプションを選択します:
   - **Commit to current branch** \- 現在のブランチにコミットします。
   - **[Create a new branch](#create-a-branch)** \- 新しいブランチを作成し、変更をコミットします。
   - **[Commit and force push](#commit-and-force-push)** \- 変更をリモートブランチに強制プッシュします。
   - **[Amend commit and force push](#amend-commit-and-force-push)** \- 最後のコミットを修正し、強制プッシュします。

### コミットと強制プッシュ {#commit-and-force-push}

変更をコミットし、強制プッシュするには:

1. アクションボタンメニューを選択するか、省略記号 ({{< icon name="ellipsis_h" >}}) を選択します。
1. **Commit and Force push**を選択します。

> [!warning]
> このアクションは現在のブランチのリモート履歴を上書きします。注意して使用してください。注意して使用してください。

### コミットを修正して強制プッシュ {#amend-commit-and-force-push}

最後のコミットを修正して強制プッシュするには:

1. アクションボタンメニューを選択するか、省略記号 ({{< icon name="ellipsis_h" >}}) を選択します。
1. **Amend commit and Force push**を選択します。

これにより、最後のコミットが更新され、リモートリポジトリに強制プッシュされます。これは、新しいコミットを作成せずに最近のコミットを修正するために使用します。

## マージリクエストを作成する {#create-a-merge-request}

Web IDEで[マージリクエスト](../merge_requests/_index.md)を作成するには:

1. [変更をコミット](#commit-changes)します。
1. 右下に表示される通知で、**MRの作成**を選択します。

詳細については、[見逃した通知を表示](#view-missed-notifications)を参照してください。

## Web IDEをカスタマイズする {#customize-the-web-ide}

キーボードショートカット、テーマ、設定、および同期に関する好みに合わせてWeb IDEをカスタマイズします。

### コマンドパレットを使用する {#use-the-command-palette}

コマンドパレットを使用して、多くのコマンドにアクセスできます。Web IDEでコマンドパレットを開いてコマンドを実行するには:

1. <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>P</kbd>を押します。
1. コマンドを入力または選択します。

### 設定を編集する {#edit-settings}

設定エディタを使用して、ユーザーとワークスペースの設定を表示および編集できます。Web IDEで設定エディタを開くには、次の手順に従います。

- トップメニューバーで、**ファイル** > **設定** > **設定**を選択するか、<kbd>Command</kbd>+<kbd>,</kbd>を押します。

設定エディタで、変更する設定を検索できます。

### キーボードショートカットを編集する {#edit-keyboard-shortcuts}

キーボードショートカットエディタを使用して、利用可能なすべてのコマンドのデフォルトのキーバインドを表示および変更できます。Web IDEでキーボードショートカットエディタを開くには、次の手順に従います。

- トップメニューバーで、**ファイル** > **設定** > **Keyboard Shortcuts**を選択するか、<kbd>Command</kbd>+<kbd>K</kbd>の後<kbd>Command</kbd>+<kbd>S</kbd>を押します。

キーボードショートカットエディタでは、以下を検索できます。

- 変更するキーバインド
- キーバインドを追加または削除するコマンド

キーバインドは、キーボードレイアウトに基づいています。キーボードレイアウトを変更すると、既存のキーバインドが自動的に更新されます。

### 配色テーマを変更する {#change-the-color-theme}

Web IDEのさまざまな配色テーマを選択できます。デフォルトのテーマは**GitLab Dark**です。

Web IDEで配色テーマを変更するには:

1. トップメニューバーで、**ファイル** > **設定** > **テーマ** > **Color Theme**を選択するか、<kbd>Command</kbd>+<kbd>K</kbd>の後<kbd>Command</kbd>+<kbd>T</kbd>を押します。
1. ドロップダウンリストから、矢印キーでテーマをプレビューします。
1. テーマを選択します。

Web IDEは、アクティブな配色テーマを[ユーザー設定](#edit-settings)に保存します。

### 同期設定を構成する {#configure-sync-settings}

Web IDEで同期設定を構成するには:

1. <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>P</kbd>を押します。
1. 検索ボックスに、`Settings Sync: Configure`と入力します。
1. 次のチェックボックスをオンまたはオフにします。
   - **設定**
   - **キーボードショートカット**
   - **ユーザースニペット**
   - **ユーザータスク**
   - **UIの状態**
   - **拡張機能**
   - **プロファイル**

これらの設定は、複数のWeb IDEインスタンス間で自動的に同期されます。ユーザープロファイルを同期したり、同期された設定の以前のバージョンに戻したりすることはできません。

### 見逃した通知を表示する {#view-missed-notifications}

Web IDEでアクションを実行すると、右下に通知が表示されます。見逃した可能性のある通知を表示するには、次の手順に従います。

1. 下部のステータスバーの右側で、ベルのアイコン（{{< icon name="notifications" >}}）を選択して、通知の一覧を表示します。
1. 表示する通知を選択します。

## 拡張機能を管理する {#manage-extensions}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.0で`web_ide_oauth`および`web_ide_extensions_marketplace`[フラグ](../../../administration/feature_flags/_index.md)とともに[ベータ](../../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151352)されました。デフォルトでは無効になっています。
- `web_ide_oauth`は、GitLab 17.4の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163181)になりました。
- `web_ide_extensions_marketplace`は、GitLab 17.4の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/459028)になりました。
- `web_ide_oauth`は、GitLab 17.5で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167464)。
- GitLab 17.10で`vscode_extension_marketplace_settings`[機能フラグ](../../../administration/feature_flags/_index.md)を[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/508996)しました。デフォルトでは無効になっています。
- `web_ide_extensions_marketplace`はGitLab 17.11の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184662)になり、`vscode_extension_marketplace_settings`は[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184662)になりました。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192659)になりました。機能フラグ`web_ide_extensions_marketplace`および`vscode_extension_marketplace_settings`は削除されました。

{{< /history >}}

VS Code拡張機能マーケットプレースは、Web IDEの機能を強化する拡張機能へのアクセスを提供します。デフォルトでは、GitLab Web IDEは[Open VSX Registry](https://open-vsx.org/)に接続します。

> [!note]
> VS Code拡張機能マーケットプレースにアクセスするには、ブラウザが`.cdn.web-ide.gitlab-static.net`アセットホストにアクセスできる必要があります。このセキュリティ要件により、サードパーティの拡張機能が分離された環境で実行され、アカウントにアクセスできないようになります。これはGitLab.comとGitLab Self-Managedの両方に適用されます。

前提条件: 

- ユーザー設定で[拡張機能マーケットプレースを統合](../../profile/preferences.md#integrate-with-the-extension-marketplace)する必要があります。
- GitLab Self-ManagedおよびGitLab Dedicatedの場合、GitLabの管理者が[拡張レジストリを有効化](../../../administration/settings/vscode_extension_marketplace.md)する必要があります。
- エンタープライズユーザーの場合、グループのオーナーが[エンタープライズユーザー向け拡張機能マーケットプレースを有効化](../../enterprise_user/_index.md#enable-the-extension-marketplace-for-enterprise-users)する必要があります。

### 拡張機能をインストールする {#install-an-extension}

Web IDEで拡張機能をインストールするには:

1. トップメニューバーで、**表示** > **Extensions**を選択するか、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>X</kbd>を押します。
1. 検索ボックスに、拡張機能名を入力します。
1. インストールする拡張機能を選択します。
1. **インストール**を選択します。

### 拡張機能をアンインストールする {#uninstall-an-extension}

Web IDEで拡張機能をアンインストールするには:

1. トップメニューバーで、**表示** > **Extensions**を選択するか、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>X</kbd>を押します。
1. インストールされている拡張機能の一覧から、アンインストールする拡張機能を選択します。
1. **アンインストール**を選択します。

### 拡張機能のセットアップ {#extension-setup}

Web IDE拡張機能をプロジェクトで動作させるには、追加の設定が必要な場合があります。

#### Vimキーバインドを使用する {#use-vim-keybindings}

Vimキーバインドを使用して、Vimテキストエディタのキーボードショートカットでテキストをナビゲートおよび編集します。拡張機能マーケットプレースを使用すると、VimキーバインドをWeb IDEに追加できます。

Vimキーバインドを有効にするには、[Vim](https://open-vsx.org/extension/vscodevim/vim)拡張機能をインストールします。詳細については、[拡張機能をインストールする](#install-an-extension)を参照してください。

#### AsciiDocサポート {#asciidoc-support}

[AsciiDoc](https://open-vsx.org/extension/asciidoctor/asciidoctor-vscode)拡張機能は、Web IDEでAsciiDocファイルのライブプレビュー、構文ハイライト、およびスニペットを提供します。Web IDEでAsciiDocマークアッププレビューを使用するには、AsciiDoc拡張機能をインストールする必要があります。詳細については、[拡張機能をインストールする](#install-an-extension)を参照してください。

## 関連トピック {#related-topics}

- [Web IDEにおけるGitLab Duo非エージェンティックチャット](../../gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-the-web-ide)

## トラブルシューティング {#troubleshooting}

Web IDEの操作中に、以下の問題が発生する可能性があります。

### 入力時の文字オフセット {#character-offset-when-typing}

Web IDEで入力すると、4文字のオフセットが発生する場合があります。次の回避策で対応します。

1. トップメニューバーで、**ファイル** > **設定** > **設定**を選択するか、<kbd>Command</kbd>+<kbd>,</kbd>を押します。
1. 右上隅で、**設定を開く（JSON）**を選択します。
1. `settings.json`ファイルで、`"editor.disableMonospaceOptimizations": true`を追加するか、`"editor.fontFamily"`設定を変更します。

詳細については、[VS Codeイシュー80170](https://github.com/microsoft/vscode/issues/80170)を参照してください。

### OAuthコールバックURLを更新する {#update-the-oauth-callback-url}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

Web IDEは、認証に[インスタンス全体のOAuthアプリケーション](../../../integration/oauth_provider.md#create-an-instance-wide-application)を使用します。OAuthコールバックURLが正しく設定されていない場合、次のメッセージが示された`Cannot open Web IDE`エラーページが表示されることがあります。

```plaintext
The URL you're using to access the Web IDE and the configured OAuth callback URL do not match. This issue often occurs when you're using a proxy.
```

この問題を解決するには、OAuthコールバックURLを更新して、GitLabインスタンスへのアクセスに使用するURLと一致させる必要があります。

前提条件: 

- 管理者アクセス権が必要です。

OAuthコールバックURLを更新するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**アプリケーション**を選択します。
1. **GitLab Web IDE**で、**編集**を選択します。
1. OAuthコールバックURLを入力します。複数のURLを改行で区切って入力できます。

### アクセストークンのライフタイムを5分未満にできない {#access-token-lifetime-cannot-be-less-than-5-minutes}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

アクセストークンのライフタイムを5分未満にできないというエラーメッセージが表示されることがあります。

このエラーは、GitLabインスタンスの設定で、アクセストークン有効期限が5分未満になっている場合に発生します。Web IDEが正常に機能するには、最低5分のライフタイムを持つアクセストークンが必要です。

この問題を解決するには、インスタンス設定でアクセストークンのライフタイムを5分以上に増やします。アクセストークンの有効期限の設定について詳しくは、[アクセストークンの有効期限](../../../integration/oauth_provider.md#access-token-expiration)を参照してください。

### Workhorseの依存関係 {#workhorse-dependency}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Self-Managedでは、WorkhorseをGitLab Railsサーバーの前にインストールして実行する必要があります。そうでない場合、Web IDEを開いたり、Markdownプレビューなどの特定の機能を使用したりする際に問題が発生する可能性があります。

セキュリティのため、Web IDEの一部は別のoriginで実行する必要があります。このアプローチをサポートするために、Web IDEはWorkhorseを使用して、Web IDEアセットとの間でリクエストを適切にルーティングします。Web IDEアセットは静的なフロントエンドアセットであるため、この作業のためにRailsを使用すると、不要なオーバーヘッドが発生します。

### CORSに関する問題 {#cors-issues}

Web IDEがGitLab Self-Managedのインスタンスで正しく機能するには、特定のクロスオリジンリソース共有 (CORS) 設定が必要です。GitLab APIエンドポイント (`/api/*`) は、Web IDEをサポートするために、次のHTTPレスポンスヘッダーを含める必要があります:

| ヘッダー | 値 | 説明 |
|--------|-------|-------------|
| `Access-Control-Allow-Origin` | `https://[subdomain].cdn.web-ide.gitlab-static.net` | Web IDEのoriginからのリクエストを許可します。The `[subdomain]`は動的に生成される英数字文字列（最大52文字）です。 |
| `Access-Control-Allow-Headers` | `Authorization` | 認可ヘッダーをクロスオリジンリクエストで許可します。 |
| `Access-Control-Allow-Methods` | `GET, POST, PUT, DELETE, OPTIONS` | 許可されるHTTPメソッドを指定します（推奨）。 |
| `Access-Control-Allow-Credentials` | `false` | Web IDEは、この[ヘッダー](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Access-Control-Allow-Credentials)によって制御される認証情報をHTTPリクエストに含める必要はありません。 |
| `Access-Control-Expose-Headers` | `Link, X-Total, X-Total-Pages, X-Per-Page, X-Page, X-Next-Page, X-Prev-Page, X-Gitlab-Blob-Id, X-Gitlab-Commit-Id, X-Gitlab-Content-Sha256, X-Gitlab-Encoding, X-Gitlab-File-Name, X-Gitlab-File-Path, X-Gitlab-Last-Commit-Id X-Gitlab-Ref, X-Gitlab-Size, X-Request-Id, ETag` | GitLab RestおよびGraphQL APIで使用されるヘッダー。 |
| `Vary` | `Origin` | CORSレスポンスの適切なキャッシュ動作を保証します。 |

Web IDEは、拡張機能ホストドメインのサブドメイン部分を動的に生成します。CORSヘッダーが次のルールを満たしていることを確認してください:

- **Pattern matching**: パターン`https://*.cdn.web-ide.gitlab-static.net`に一致するoriginを受け入れます。
- **検証**: サブドメインには英数字のみが含まれ、52文字以下であることを確認してください。
- **セキュリティ**: ワイルドカード (\*) をAccess-Control-Allow-Originに使用しないでください。これはセキュリティ上のリスクをもたらします。

GitLabインスタンスのデフォルトCORS設定はこれらの要件を満たしています。GitLab Self-ManagedインスタンスがHTTPリバースプロキシサーバーの背後にある場合、またはカスタムのCORSポリシー設定を使用している場合、問題が発生する可能性があります。

### オフライン環境 {#offline-environments}

Web IDEは、デフォルトの拡張機能ホストドメイン (`https://*.cdn.web-ide.gitlab-static.net`) に接続できない場合、機能が制限されます。オフライン環境では、GitLab管理者が[カスタム拡張機能ホストドメイン](../../../administration/settings/web_ide.md)を回避策として設定できます。

### 問題を報告する {#report-a-problem}

問題を報告するには、次の情報を含む[新しいイシューを作成します](https://gitlab.com/gitlab-org/gitlab-web-ide/-/issues/new)。

- エラーメッセージ
- エラーの完全な詳細
- 問題が発生する頻度
- 問題を再現する手順

有料プランをご利用の場合は、[サポートにお問い合わせいただくこともできます](https://about.gitlab.com/support/#contact-support)。

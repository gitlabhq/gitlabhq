---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use the Web IDE to edit multiple files in the GitLab UI, stage commits, and create merge requests.
title: Web IDE
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.7で`vscode_web_ide`[フラグ](../../../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95169)されました。デフォルトでは無効になっています。
- GitLab 15.7の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/371084)。
- GitLab 15.11の[GitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115741)。

{{< /history >}}

{{< alert type="flag" >}}

この機能の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

Web IDEは、コミットステージング機能を備えた高度なエディタです。Web IDEを使用すると、GitLab UIから直接複数のファイルを変更できます。より基本的な実装については、[Webエディタ](../repository/web_editor.md)を参照してください。

Web IDEでの[GitLab Flavored Markdown](../../markdown.md)プレビューのサポートは、[イシュー645](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/645)で提案されています。

## Web IDEを開く

Web IDEを開くには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. <kbd>.</kbd>キーボードショートカットを使用します。

### ファイルまたはディレクトリから

ファイルまたはディレクトリからWeb IDEを開くには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. ファイルまたはディレクトリに移動します。
1. **編集 > Web IDEで開く**を選択します。

### マージリクエストから

マージリクエストからWeb IDEを開くには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. マージリクエストに移動します。
1. 右上隅で、**コード > Web IDEで開く**を選択します。

Web IDEでは、新規ファイルと変更されたファイルが別々のタブで開き、変更点が並んで表示されます。ロード時間を短縮するため、変更された行数が最も多い10個のファイルのみが自動的に開きます。

左側の**エクスプローラー**サイドバーで、新規または変更されたファイルの横にマージリクエストアイコン（{{< icon name="merge-request" >}}）が追加されます。ファイルの変更を表示するには、ファイルを右クリックして**マージリクエストベースと比較**を選択します。

## ファイルを開く

Web IDEでファイル名を指定してファイルを開くには:

1. <kbd>Command</kbd>+<kbd>P</kbd>を押します。
1. 検索ボックスに、ファイル名を入力します。

## 開いているファイルを検索する

Web IDEで開いているファイルを検索するには:

1. <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>F</kbd>を押します。
1. 検索ボックスに検索語句を入力します。

## 変更されたファイルの一覧を表示する

Web IDEで変更したファイルの一覧を表示するには:

- 左側のアクティビティバーで、**ソース管理**を選択するか、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>を押します。

`CHANGES`、`STAGED CHANGES`、および`MERGE CHANGES`が表示されます。詳細については、[VS Codeドキュメント](https://code.visualstudio.com/docs/sourcecontrol/overview#_commit)を参照してください。

## コミットされていない変更を復元する

Web IDEで編集するファイルを手動で保存する必要はありません。Web IDEは変更したファイルをステージングするため、[変更をコミットできます](#commit-changes)。コミットされていない変更はブラウザのローカルストレージに保存されるため、ブラウザのタブを閉じた、Web IDEを更新したという場合であっても保持されます。

コミットされていない変更が利用できないという場合は、ローカル履歴から変更を復元できます。Web IDEでコミットされていない変更を復元するには、次の手順に従います。

1. <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>P</kbd>を押します。
1. 検索ボックスに、`Local History: Find Entry to Restore`と入力します。
1. コミットされていない変更を含むファイルを選択します。

## ファイルをアップロードする

Web IDEでファイルをアップロードするには:

1. 左側のアクティビティバーで、**エクスプローラー**を選択するか、<kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>E</kbd>を押します。
1. ファイルをアップロードするディレクトリに移動します。新しいディレクトリを作成する場合は、次の手順に従います。

   - 左側の**エクスプローラー**サイドバーの右上にある**新しいフォルダー**（{{< icon name="folder-new" >}}）を選択します。

1. ディレクトリを右クリックして、**アップロード**を選択します。
1. アップロードするファイルを選択します。

一度に複数のファイルをアップロードできます。ファイルがアップロードされ、自動的にリポジトリに追加されます。

## ブランチを切り替える

Web IDEでは、デフォルトで現在のブランチが使用されます。Web IDEでブランチを切り替えるには、次の手順に従います。

1. 下部のステータスバーの左側で、現在のブランチ名を選択します。
1. 既存のブランチを入力または選択します。

## ブランチを作成する

Web IDEで現在のブランチからブランチを作成するには:

1. 下部のステータスバーの左側で、現在のブランチ名を選択します。
1. ドロップダウンリストから、**新しいブランチを作成**を選択します。
1. 新しいブランチ名を入力します。

リポジトリへの書き込みアクセス権がない場合、**新しいブランチを作成**は表示されません。

## 変更をコミットする

Web IDEで変更をコミットするには:

1. 左側のアクティビティバーで、**ソース管理**を選択するか、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>を押します。
1. コミットメッセージを入力します。
1. 現在のブランチにコミットするか、[新しいブランチを作成](#create-a-branch)します。

## マージリクエストを作成する

Web IDEで[マージリクエスト](../merge_requests/_index.md)を作成するには:

1. [変更をコミット](#commit-changes)します。
1. 右下に表示される通知で、**MRの作成**を選択します。

詳細については、[見逃した通知を表示](#view-missed-notifications)を参照してください。

## コマンドパレットを使用する

コマンドパレットを使用して、多くのコマンドにアクセスできます。Web IDEでコマンドパレットを開いてコマンドを実行するには:

1. <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>P</kbd>を押します。
1. コマンドを入力または選択します。

## 設定を編集する

設定エディタを使用して、ユーザーとワークスペースの設定を表示および編集できます。Web IDEで設定エディタを開くには、次の手順に従います。

- 上部のメニューバーで、**ファイル > 環境設定 > 設定**を選択するか、<kbd>Command</kbd>+<kbd>,</kbd>を押します。

設定エディタで、変更する設定を検索できます。

## キーボードショートカットを編集する

キーボードショートカットエディタを使用して、利用可能なすべてのコマンドのデフォルトのキーバインドを表示および変更できます。Web IDEでキーボードショートカットエディタを開くには、次の手順に従います。

- 上部のメニューバーで、**ファイル > 環境設定 > キーボードショートカット**を選択するか、<kbd>Command</kbd>+<kbd>K</kbd>を押してから<kbd>Command</kbd>+<kbd>S</kbd>を押します。

キーボードショートカットエディタでは、以下を検索できます。

- 変更するキーバインド
- キーバインドを追加または削除するコマンド

キーバインドは、キーボードレイアウトに基づいています。キーボードレイアウトを変更すると、既存のキーバインドが自動的に更新されます。

### Vimキーバインドを使用する

Vimキーバインドを使用して、Vimテキストエディタのキーボードショートカットでテキストをナビゲートおよび編集します。[拡張機能マーケットプレース](#extension-marketplace)を使用すると、VimキーバインドをWeb IDEに追加できます。

Vimキーバインドを有効にするには、[Vim](https://open-vsx.org/extension/vscodevim/vim)拡張機能をインストールします。詳細については、[拡張機能をインストール](#install-an-extension)を参照してください。

## 配色テーマを変更する

Web IDEのさまざまな配色テーマを選択できます。デフォルトのテーマは**GitLab Dark**です。

Web IDEで配色テーマを変更するには:

1. 上部のメニューバーで、**ファイル > 環境設定 > テーマ > 配色テーマ**を選択するか、<kbd>Command</kbd>+<kbd>K</kbd>を押してから<kbd>Command</kbd>+<kbd>T</kbd>を押します。
1. ドロップダウンリストから、矢印キーでテーマをプレビューします。
1. テーマを選択します。

Web IDEは、アクティブな配色テーマを[ユーザー設定](#edit-settings)に保存します。

## 同期設定を構成する

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

## 見逃した通知を表示する

Web IDEでアクションを実行すると、右下に通知が表示されます。見逃した可能性のある通知を表示するには、次の手順に従います。

1. 下部のステータスバーの右側で、ベルのアイコン（{{< icon name="notifications" >}}）を選択して、通知の一覧を表示します。
1. 表示する通知を選択します。

## 拡張機能マーケットプレース

{{< details >}}

- 提供: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.0で、`web_ide_oauth`と`web_ide_extensions_marketplace`という名前の[フラグとともに](../../../administration/feature_flags.md)[ベータ](../../../policy/development_stages_support.md#beta)として[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151352)。デフォルトでは無効になっています。
- `web_ide_oauth`は、GitLab 17.4の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163181)。
- `web_ide_extensions_marketplace`は、GitLab 17.4の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/459028)。
- `web_ide_oauth`は、GitLab 17.5で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167464)。
- GitLab 17.10で`vscode_extension_marketplace_settings`[機能フラグ](../../../administration/feature_flags.md)を[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/508996)しました。デフォルトでは無効になっています。
- `web_ide_extensions_marketplace`と`vscode_extension_marketplace_settings`は、GitLab 17.11の[GitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/459028)。

{{< /history >}}

{{< alert type="flag" >}}

この機能の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

前提要件:

- **管理者**エリアで、GitLab管理者が[拡張機能マーケットプレースを有効にする](../../../administration/settings/vscode_extension_marketplace.md)必要があります。
- ユーザー設定で、[拡張機能マーケットプレースを有効にする](../../profile/preferences.md#integrate-with-the-extension-marketplace)必要があります。
- グループ設定で、オーナーロールのユーザーが、エンタープライズユーザーに対して[拡張機能マーケットプレースを有効にする](../../enterprise_user/_index.md#enable-the-extension-marketplace-for-the-web-ide-and-workspaces)必要があります。

拡張機能マーケットプレースを使用して、Web IDEでVS Code拡張機能をダウンロードして実行できます。

### 拡張機能をインストールする

Web IDEで拡張機能をインストールするには:

1. 上部のメニューバーで、**表示 > 拡張機能**を選択するか、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>X</kbd>を押します。
1. 検索ボックスに、拡張機能名を入力します。
1. インストールする拡張機能を選択します。
1. **インストール**を選択します。

### 拡張機能をアンインストールする

Web IDEで拡張機能をアンインストールするには:

1. 上部のメニューバーで、**表示 > 拡張機能**を選択するか、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>X</kbd>を押します。
1. インストールされている拡張機能の一覧から、アンインストールする拡張機能を選択します。
1. **アンインストール**を選択します。

### 拡張機能のセットアップ

Web IDE拡張機能をプロジェクトで動作させるには、追加の設定が必要な場合があります。

#### YAML言語サポート拡張機能

指定されたパターンに一致するYAMLファイルを検証するには、Red Hat [YAML](https://open-vsx.org/extension/redhat/vscode-yaml)拡張機能を使用します。

1. [YAML拡張機能をインストールします](#install-an-extension)。
1. スキーマを設定します。

   1. 上部のメニューバーで、**ファイル > 環境設定 > 設定**を選択するか、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押して、`Preferences: Open Settings (JSON)`と入力します。
   1. `settings.json`ファイルに、スキーマ設定を追加します。ローカルスキーマパスの場合は、次のプレフィックスを追加します。`gitlab-web-ide://~/`次に例を示します。

      ```json
      "yaml.schemas": {
         "gitlab-web-ide://~/<path-to-local-schema>.json": ["*.yaml", "*.yml"]
      }
      ```

## 関連トピック

- [Web IDEのGitLab Duo Chat](../../gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-the-web-ide)

## トラブルシューティング

Web IDEの操作中に、以下の問題が発生する可能性があります。

### 入力時の文字オフセット

Web IDEで入力すると、4文字のオフセットが発生する場合があります。次の回避策で対応します。

1. 上部のメニューバーで、**ファイル > 環境設定 > 設定**を選択するか、<kbd>Command</kbd>+<kbd>,</kbd>を押します。
1. 右上隅で、**設定を開く（JSON）**を選択します。
1. `settings.json`ファイルで、`"editor.disableMonospaceOptimizations": true`を追加するか、`"editor.fontFamily"`設定を変更します。

詳細については、[VS Codeイシュー80170](https://github.com/microsoft/vscode/issues/80170)を参照してください。

### OAuthコールバックURLを更新する

{{< details >}}

- 提供: GitLab Self-Managed

{{< /details >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

Web IDEは、認証に[インスタンス全体のOAuthアプリケーション](../../../integration/oauth_provider.md#create-an-instance-wide-application)を使用します。OAuthコールバックURLが正しく設定されていない場合、次のメッセージのある`Cannot open Web IDE`エラーページが表示されることがあります。

```plaintext
The URL you're using to access the Web IDE and the configured OAuth callback URL do not match. This issue often occurs when you're using a proxy.
```

この問題を解決するには、OAuthコールバックURLを更新して、GitLabインスタンスへのアクセスに使用するURLと一致させる必要があります。

OAuthコールバックURLを更新するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **アプリケーション**を選択します。
1. **GitLab Web IDE**で、**編集**を選択します。
1. OAuthコールバックURLを入力します。複数のURLを改行で区切って入力できます。

### アクセストークンのライフタイムを5分未満にできない

{{< details >}}

- 提供: GitLab Self-Managed

{{< /details >}}

アクセストークンのライフタイムを5分未満にできないというエラーメッセージが表示されることがあります。

このエラーは、GitLabインスタンスの設定で、アクセストークン有効期限が5分未満になっている場合に発生します。Web IDEが正常に機能するには、最低5分のライフタイムを持つアクセストークンが必要です。

この問題を解決するには、インスタンス設定でアクセストークンのライフタイムを5分以上に増やします。アクセストークンの有効期限の設定について、詳しくは[アクセストークンの有効期限](../../../integration/oauth_provider.md#access-token-expiration)を参照してください。

### Workhorseの依存関係

{{< details >}}

- 提供: GitLab Self-Managed

{{< /details >}}

GitLab Self-Managedでは、[Workhorse](../../../development/workhorse/_index.md)をGitLab Railsサーバーの前にインストールして実行する必要があります。このようになっていない場合、Web IDE を開いたり、Markdown プレビューなどの特定の機能を使用したりする際に問題が発生する可能性があります。

この依存関係の詳細については、[Workhorseに依存する機能](../../../development/workhorse/gitlab_features.md#5-web-ide)を参照してください。

### 問題を報告する

問題を報告するには、次の情報を含む[新しいイシューを作成します](https://gitlab.com/gitlab-org/gitlab-web-ide/-/issues/new)。

- エラーメッセージ
- エラーの完全な詳細
- 問題が発生する頻度
- 問題を再現する手順

有料プランをご利用の場合は、[サポートにお問い合わせいただくこともできます](https://about.gitlab.com/support/#contact-support)。

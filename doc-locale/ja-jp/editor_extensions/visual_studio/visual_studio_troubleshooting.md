---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: NeovimでGitLab Duoを接続して使用します。
title: Visual Studioトラブルシューティング
---

このページのステップで問題を解決できない場合は、Visual Studioプラグインのプロジェクトで[未解決のイシューのリスト](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/?sort=created_date&state=opened&first_page_size=100)を確認してください。イシューがお客様の問題と一致する場合は、そのイシューを更新してください。お客様の問題と一致するイシューがない場合は、[新しいイシューを作成](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/new)してください。

GitLab Duoコード提案の拡張機能のトラブルシューティングについては、[コードの提案のトラブルシューティング](../../user/project/repository/code_suggestions/troubleshooting.md#microsoft-visual-studio-troubleshooting)を参照してください。

## 詳細なログを表示 {#view-more-logs}

より多くのログは、**GitLab Extension Output**ウィンドウで利用可能です:

1. Visual Studioの上部バーで、**ツール** > **オプション**メニューに移動します。
1. **GitLab**オプションを見つけ、**Log Level**（ログレベル）を**デバッグ**に設定します。
1. **表示** > **Output**（出力）に移動して、拡張機能のログを開きます。ドロップダウンリストで、ログフィルターとして**GitLab Extension**を選択します。
1. デバッグログに類似の出力が含まれていることを確認します:

   ```shell
   GetProposalManagerAsync: Code suggestions enabled. ContentType (csharp) or file extension (cs) is supported.
   GitlabProposalSourceProvider.GetProposalSourceAsync
   ```

### アクティビティーログを表示 {#view-activity-log}

拡張機能が読み込まれない場合、またはクラッシュする場合は、アクティビティーログでエラーを確認してください。アクティビティーログは、次の場所にあります:

```plaintext
C:\Users\WINDOWS_USERNAME\AppData\Roaming\Microsoft\VisualStudio\VS_VERSION\ActivityLog.xml
```

次の値をディレクトリパスに置き換えます:

- `WINDOWS_USERNAME`: Windowsユーザー名。
- `VS_VERSION`: Visual Studioインストールのバージョン。

## サポートに必要な情報 {#required-information-for-support}

サポートに連絡する前に、最新のGitLab拡張機能がインストールされていることを確認してください。Visual Studioは、拡張機能の最新のバージョンに自動的に更新されるはずです。

影響を受けるユーザーからこの情報を収集し、バグレポートで提供してください:

1. ユーザーに表示されるエラーメッセージ。
1. ワークフローと言語サーバーのログファイル:
   1. [デバッグログを有効にする](#view-more-logs)。
   1. [ログファイルを取得する](#view-activity-log)。
1. 診断出力:
   1. Visual Studioを開いた状態で、上部のバナーで**ヘルプ** > **About Microsoft Visual Studio**（Microsoft Visual Studioについて）を選択します。
   1. ダイアログで、**Copy Info**（情報をコピー）を選択し、このセクションに必要なすべての情報をクリップボードにコピーします。
1. システム詳細:
   1. Visual Studioを開いた状態で、上部のバナーで**ヘルプ** > **About Microsoft Visual Studio**（Microsoft Visual Studioについて）を選択します。
   1. ダイアログで、**System Info**（システム情報）を選択すると、より詳細な情報が表示されます。
   1. **OS type and version**（OSの種類とバージョン）: `OS Name`と`Version`をコピーします。
   1. **Machine specifications (CPU, RAM)**（マシンの仕様 (CPU、RAM)）: `Processor`と`Installed Physical Memory (RAM)`セクションをコピーします。
1. 影響のスコープを記述します。影響を受けるユーザーの数は？
1. エラーの再現方法を記述します。可能であれば、画面録画を含めてください。
1. 他のGitLab Duo機能がどのように影響を受けているかを記述します:
   - コード提案は機能していますか？
   - Web IDE Duoチャットは応答を返しますか？
1. 拡張機能の分離テストを実行します。他のすべての拡張機能を無効にする（またはアンインストールする）ことを試して、別の拡張機能が問題の原因になっているかどうかを判断します。これにより、問題が当社の拡張機能にあるのか、外部ソースからのものなのかを判断できます。

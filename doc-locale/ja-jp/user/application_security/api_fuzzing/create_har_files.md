---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: HARファイルを作成
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

HTTPアーカイブ（HAR）形式ファイルは、HTTPリクエストとHTTPレスポンスに関する情報を交換するための業界標準です。HARファイルの内容はJSON形式で、Webサイトとのブラウザのインタラクションが含まれています。ファイル拡張子`.har`が一般的に使用されます。

HARファイルは、CI/CDパイプラインで[Web APIファジング](configuration/enabling_the_analyzer.md#http-archive-har)を実行するために使用できます。

{{< alert type="warning" >}}

HARファイルには、WebクライアントとWebサーバー間で交換される情報が保存されます。認証トークン、APIキー、セッションクッキーなどの機密情報も保存される可能性があります。HARファイルの内容をリポジトリに追加する前に、レビューすることを推奨します。

{{< /alert >}}

## HARファイルの作成 {#har-file-creation}

HARファイルは、手動で作成するか、Webセッションを記録するための専用ツールを使用して作成できます。専用ツールを使用することをお勧めします。ただし、これらのツールで作成されたファイルが機密情報を公開せず、安全に使用できることを確認することが重要です。

次のツールは、ネットワークアクティビティーに基づいてHARファイルを生成するために使用できます。ネットワークアクティビティーを自動的に記録し、HARファイルを生成します:

- GitLab HAR recorder
- Insomnia API client
- Fiddlerデバッグproxy
- Safari web browser
- Chrome web browser
- Firefox web browser

{{< alert type="warning" >}}

HARファイルには、認証トークン、APIキー、セッションクッキーなどの機密情報が含まれている場合があります。HARファイルの内容をリポジトリに追加する前に、レビューする必要があります。

{{< /alert >}}

### GitLab HAR recorder {#gitlab-har-recorder}

[GitLab HAR Recorder](https://gitlab.com/gitlab-org/security-products/har-recorder)は、HTTPメッセージを記録し、HARファイルに保存するためのコマンドラインツールです。

#### Install GitLab HAR recorder {#install-gitlab-har-recorder}

前提要件: 

- Python 3.6以上をインストールします。
- Microsoft Windowsの場合は、`Microsoft Visual C++ 14.0`もインストールする必要があります。[Visual Studio Downloads page](https://visualstudio.microsoft.com/downloads/)のVisual Studio用ビルドツールに含まれています。
- HAR Recorderをインストールします。

+GitLab HAR recorderをインストールする:

  ```shell
  pip install gitlab-har-recorder --extra-index-url https://gitlab.com/api/v4/projects/22441624/packages/pypi/simple
  ```

#### Create a HAR file with GitLab HAR recorder {#create-a-har-file-with-gitlab-har-recorder}

1. プロキシポートとHARファイル名でレコーダーを起動します。
1. プロキシを使用して、ブラウザのアクションを完了します。
   1. プロキシが使用されていることを確認してください！
1. レコーダーを停止します。

### Insomnia API client {#insomnia-api-client}

[Insomnia API client](https://insomnia.rest/)は、多くの用途の中でも、APIの設計、記述、テストに役立つAPI設計ツールです。[Web APIファジング](configuration/enabling_the_analyzer.md#http-archive-har)で使用できるHARファイルを生成するためにも使用できます。

#### Create a HAR file with the Insomnia API client {#create-a-har-file-with-the-insomnia-api-client}

1. APIを定義またはインポートします。
   - Postman v2.
   - cURL.
   - OpenAPI v2, v3.
1. 各APIコールが機能することを確認します。
   - OpenAPI仕様をインポートした場合は、作業データを追加します。
1. **API** > **Import/Export**（インポート/エクスポート）を選択します。
1. **Export Data**（データのエクスポート） > **Current Workspace**（現在のワークスペース）を選択します。
1. HARファイルに含めるリクエストを選択します。
1. **エクスポート**を選択します。
1. **Select Export Type**（エクスポートタイプの選択）ドロップダウンリストで、**HAR -- HTTP Archive Format**を選択します。
1. **完了**を選択します。
1. HARファイルの場所とファイル名を入力します。

### Fiddlerデバッグproxy {#fiddler-debugging-proxy}

[Fiddler](https://www.telerik.com/fiddler)は、Webデバッガツールです。HTTPおよびHTTP(S)のネットワークトラフィックをキャプチャし、各リクエストを調べることができます。また、HAR形式でリクエストとレスポンスをエクスポートできます。

#### Create a HAR file with Fiddler {#create-a-har-file-with-fiddler}

1. [Fiddler home page](https://www.telerik.com/fiddler)にアクセスしてサインインします。アカウントをまだお持ちでない場合は、アカウントを作成してください。
1. APIを呼び出すページを参照します。Fiddlerはリクエストを自動的にキャプチャします。
1. 1つまたは複数のリクエストを選択し、コンテキストメニューから**エクスポート** > **Selected Sessions**（選択されたセッション）を選択します。
1. **Choose Format**（形式を選択）ドロップダウンリストで、**HTTPArchive v1.2**を選択します。
1. ファイル名を入力して、**保存**を選択します。

Fiddlerに、エクスポートが成功したことを確認するポップアップメッセージが表示されます。

### Safari web browser {#safari-web-browser}

[Safari](https://www.apple.com/safari/)は、Appleが管理するWebブラウザです。Web開発の進化に伴い、ブラウザは新しい機能をサポートするようになります。Safariを使用すると、ネットワークトラフィックを調査し、HARファイルとしてエクスポートできます。

#### Create a HAR file with Safari {#create-a-har-file-with-safari}

前提要件: 

- `Develop`メニュー項目を有効にします。
  1. Safariの設定を開きます。<kbd>Command</kbd>+<kbd>,</kbd>を押すか、メニューから**Safari** > **設定**を選択します。
  1. **高度な設定**タブを選択し、`Show Develop menu item in menu bar`を選択します。
  1. **設定**ウィンドウを閉じます。

1. **Web Inspector**を開きます。<kbd>Option</kbd>+<kbd>Command</kbd>+<kbd>i</kbd>を押すか、メニューから**Develop** > **Show Web Inspector**（Web Inspectorを表示）を選択します。
1. **ネットワーク**タブを選択し、**Preserve Log**（ログを保持）を選択します。
1. APIを呼び出すページを参照します。
1. **Web Inspector**を開き、**ネットワーク**タブを選択します
1. エクスポートするリクエストを右クリックし、**Export HAR**（HARをエクスポート）を選択します。
1. ファイル名を入力して、**保存**を選択します。

### Chrome web browser {#chrome-web-browser}

[Chrome](https://www.google.com/chrome/)は、Googleが管理するWebブラウザです。Web開発の進化に伴い、ブラウザは新しい機能をサポートするようになります。Chromeを使用すると、ネットワークトラフィックを調査し、HARファイルとしてエクスポートできます。

#### Create a HAR file with Chrome {#create-a-har-file-with-chrome}

1. Chromeのコンテキストメニューから、**Inspect**を選択します。
1. **ネットワーク**タブを選択します。
1. **Preserve log**（ログを保持）を選択します。
1. APIを呼び出すページを参照します。
1. 1つまたは複数のリクエストを選択します。
1. 右クリックして**Save all as HAR with content**（コンテンツ付きでHARとしてすべて保存）を選択します。
1. ファイル名を入力して、**保存**を選択します。
1. 追加のリクエストを追加するには、それらを選択して同じファイルに保存します。

### Firefox web browser {#firefox-web-browser}

[Firefox](https://www.mozilla.org/en-US/firefox/new/)は、Mozillaが管理するWebブラウザです。Web開発の進化に伴い、ブラウザは新しい機能をサポートするようになります。Firefoxを使用すると、ネットワークトラフィックを調査し、HARファイルとしてエクスポートできます。

#### Create a HAR file with Firefox {#create-a-har-file-with-firefox}

1. Firefoxのコンテキストメニューから、**Inspect**を選択します。
1. **ネットワーク**タブを選択します。
1. APIを呼び出すページを参照します。
1. **ネットワーク**タブを確認し、リクエストが記録されていることを確認します。メッセージ`Perform a request or Reload the page to see detailed information about network activity`がある場合は、**再読み込み**を選択してリクエストの記録を開始します。
1. 1つまたは複数のリクエストを選択します。
1. 右クリックして**Save All As HAR**（HARとしてすべて保存）を選択します。
1. ファイル名を入力して、**保存**を選択します。
1. 追加のリクエストを追加するには、それらを選択して同じファイルに保存します。

## HAR verification {#har-verification}

HARファイルを使用する前に、機密情報が公開されていないことを確認することが重要です。

HARファイルごとに、次のことを行う必要があります:

- HARファイルの内容を表示する
- 機密情報についてHARファイルをレビューする
- 機密情報を編集または削除する

### View HAR file contents {#view-har-file-contents}

構造化された方法でコンテンツを表示できるツールで、HARファイルの内容を表示することをお勧めします。いくつかのHARファイルビューアがオンラインで利用できます。HARファイルをアップロードしたくない場合は、コンピューターにインストールされているツールを使用できます。HARファイルはJSON形式を使用しているため、テキストエディタで表示することもできます。

HARファイルの表示に推奨されるツールは次のとおりです:

- [HAR Viewer](http://www.softwareishard.com/har/viewer/) \- (online)
- [Google Admin Toolbox HAR Analyzer](https://toolbox.googleapps.com/apps/har_analyzer/) \- (online)
- [Fiddler](https://www.telerik.com/fiddler) \- local
- [Insomnia API Client](https://insomnia.rest/) \- local

## Review HAR file content {#review-har-file-content}

HARファイルで次のいずれかを確認します:

- アプリケーションへのアクセスを許可するのに役立つ可能性のある情報: 認証トークン、認証トークン、クッキー、APIキー。
- [個人識別情報（PII）](https://en.wikipedia.org/wiki/Personal_data)。

機密情報を[編集または削除すること](#edit-or-remove-sensitive-information)を強くお勧めします。

開始するためのチェックリストとして、以下を使用してください。これは網羅的なリストではありません。

- シークレットを探します。例: アプリケーションで認証が必要な場合は、一般的な場所または認証情報を確認してください:
  - 認証関連ヘッダー。例: Cookie、認可。これらのヘッダーには有効な情報が含まれている可能性があります。
  - 認証に関連するリクエスト。これらのリクエストの本文には、ユーザー認証情報やトークンなどの情報が含まれている場合があります。
  - セッションクッキー。セッションクッキーは、アプリケーションへのアクセスを許可する可能性があります。これらのトークンの場所は異なる場合があります。ヘッダー、クエリパラメータ、または本文に存在する可能性があります。
- 個人識別情報を探す
  - 例: アプリケーションがユーザーのリストとそれらの個人データ（電話、名前、メール）取得する場合。
  - 認証情報にも個人データが含まれている可能性があります。

## Edit or remove sensitive information {#edit-or-remove-sensitive-information}

[HARファイルコンテンツのレビュー](#review-har-file-content)中に見つかった機密情報を編集または削除します。HARファイルはJSONファイルであり、任意のテキストエディタで編集できます。

HARファイルを編集した後、HARファイルビューアで開いて、形式と構造がそのまま残っていることを確認します。

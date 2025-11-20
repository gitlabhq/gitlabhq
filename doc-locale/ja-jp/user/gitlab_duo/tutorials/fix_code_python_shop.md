---
stage: none
group: Tutorials
description: GitLab Duoを使用してPythonでショップアプリケーションを作成する方法のチュートリアル。
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: GitLab Duoを使用してPythonでショップアプリケーションを作成する'
---

<!-- vale gitlab_base.FutureTense = NO -->

あなたはオンライン書店でデベロッパーとして採用されました。現在の在庫管理システムは、スプレッドシートと手動プロセスが混在しており、在庫エラーや更新の遅延が発生しています。あなたのチームは、以下のことが可能なWebアプリケーションを作成する必要があります:

- 書籍の在庫をリアルタイムで追跡します。
- スタッフが新しい書籍を入荷時に登録できるようにします。
- マイナスの価格や数量など、一般的なデータ入力エラーを防止します。
- 将来の顧客向けの機能の基盤を提供します。

このチュートリアルはシリーズの第1部であり、これらの要件を満たすデータベースバックエンドを備えた[Python](https://www.python.org/) Webアプリケーションの作成とデバッグについて説明します。

以下のために、[GitLab Duo Chat](../../gitlab_duo_chat/_index.md)と[GitLab Duoコード提案](../../project/repository/code_suggestions/_index.md)を使用します:

- 標準ディレクトリと必須ファイルを使用して、整理されたPythonプロジェクトをセットアップします。
- Pythonの仮想環境変数を設定します。
- Webアプリケーションの基盤として、[Flask](https://flask.palletsprojects.com/en/stable/)フレームワークをインストールします。
- 必要な依存関係をインストールし、開発のためにプロジェクトを準備します。
- Flaskアプリケーション開発用のPython設定ファイルと環境変数をセットアップします。
- 記事モデル、データベース操作、APIエンドポイント、在庫管理機能などの主要な機能を実装します。
- アプリケーションが意図したとおりに動作することをテストし、作成したコードとサンプルコードファイルを比較します。

## はじめる前 {#before-you-begin}

- システムに[最新バージョンのPythonをインストールする](https://www.python.org/downloads/)。お使いのオペレーティングシステムでそれを実行する方法について、チャットで質問できます。
- GitLab Duoへのアクセス権があることを管理者、グループオーナー、またはプロジェクトオーナーに確認してください。
- お好みのIDEに拡張機能をインストールします:
  - [Web IDE](../../project/web_ide/_index.md): GitLabインスタンスからアクセス
  - [VS Code](../../../editor_extensions/visual_studio_code/setup.md)
  - [Visual Studio](../../../editor_extensions/visual_studio/setup.md)
  - [JetBrains IDE](../../../editor_extensions/jetbrains_ide/_index.md)
  - [Neovim](../../../editor_extensions/neovim/setup.md)
- IDEからGitLabで[OAuth](../../../integration/google.md)または[パーソナルアクセストークン（`api`スコープ付き）](../../profile/personal_access_tokens.md#create-a-personal-access-token)を使用して認証します。

## GitLab Duoチャットとコード提案を使用する {#use-gitlab-duo-chat-and-code-suggestions}

このチュートリアルでは、チャットとコード提案を使用して、Python Webアプリケーションを作成します。これらの機能を使用する方法は複数あります。

### GitLab Duoチャットに質問する {#use-gitlab-duo-chat}

サブスクリプションのアドオンによっては、GitLab UI、Web IDE、またはIDEでチャットを使用できます。

#### GitLab UIでチャットを使用する {#use-chat-in-the-gitlab-ui}

1. 右上隅で、**GitLab Duo Chat**を選択します。画面の右側にドロワーが開きます。
1. チャット入力ボックスに質問を入力します。**Enter**キーを押すか、**送信**を選択します。インタラクティブなAIチャットからの回答の生成には、数秒要することがあります。

#### Web IDEでチャットを使用する {#use-chat-in-the-web-ide}

1. 次の手順でWeb IDEを開きます:
   1. GitLab UIで、左側のサイドバーで**検索または移動先**を選択して、プロジェクトを見つけます。
   1. ファイルを選択します。次に、右上隅で**編集** > **Web IDEで開く**を選択します。
1. 次のいずれかの方法でチャットを開きます:
   - 左側のサイドバーで、**GitLab Duo Chat**を選択します。
   - エディタで開いているファイルで、コードを選択します。
     1. 右クリックして、**GitLab Duo Chat**を選択します。
     1. **Explain selected code**（Explain selected code）、**Generate Tests**（Generate Tests）、または**Refactor**（Refactor）を選択します。
   - キーボードショートカットを使用します。WindowsおよびLinuxの場合は<kbd>ALT</kbd>+<kbd>d</kbd>、Macの場合は<kbd>Option</kbd>+<kbd>d</kbd>を使用します。
1. メッセージボックスに質問を入力します。**Enter**キーを押すか、**送信**を選択します。

#### IDEでチャットを使用する {#use-chat-in-your-ide}

IDEでのチャットの使用方法は、使用するIDEによって異なります。

{{< tabs >}}

{{< tab title="VS Code" >}}

1. VS Codeでファイルを開きます。これは、Gitリポジトリ内のファイルである必要はありません。
1. 左側のサイドバーで、**GitLab Duo Chat**（{{< icon name="duo-chat" >}}）を選択します。
1. メッセージボックスに質問を入力します。**Enter**キーを押すか、**送信**を選択します。
1. チャットペインの右上隅で、**Show Status**（Show Status）を選択して、コマンドパレットに情報を表示します。

コードのサブセットを操作しているときに、GitLab Duoチャットと対話できます。

1. VS Codeでファイルを開きます。これは、Gitリポジトリ内のファイルである必要はありません。
1. ファイルで、コードを選択します。
1. 右クリックして、**GitLab Duo Chat**を選択します。
1. オプションを選択するか、**Open Quick Chat**（クイックチャットを開く）を選択し、`Can you simplify this code?`などの質問をして、<kbd>Enter</kbd>キーを押します。

詳細については、[VS CodeでGitLab Duoチャットを使用する](../../gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-vs-code)を参照してください。

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

1. [PyCharm](https://www.jetbrains.com/pycharm/) 、または[IntelliJ IDEA](https://www.jetbrains.com/idea/)など、PythonをサポートするJetBrains IDEでプロジェクトを開きます。
1. [チャットウィンドウ](../../gitlab_duo_chat/_index.md#in-a-chat-window)または[エディタウィンドウ](../../gitlab_duo_chat/_index.md#use-chat-while-working-in-the-editor-window)でGitLab Duoチャットを開きます。

詳細については、[JetBrains IDEでGitLab Duoチャットを使用する](../../gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-jetbrains-ides)を参照してください。

{{< /tab >}}

{{< /tabs >}}

### コード提案を使用する {#use-code-suggestions}

コード提案を使用するには、以下の手順に従います:

1. [サポートされているIDE](../../project/repository/code_suggestions/supported_extensions.md#supported-editor-extensions)でGitプロジェクトを開きます。
1. [`git remote add`](../../../topics/git/commands.md#git-remote-add)を使用して、ローカルリポジトリのリモートとしてプロジェクトを追加します。
1. 非表示の`.git/`フォルダーを含むプロジェクトディレクトリを、IDEワークスペースまたはプロジェクトに追加します。
1. コードを作成します。入力すると、候補が表示されます。コード提案は、カーソルの位置に応じて、コードスニペットを提供するか、現在の行を完了します。

1. 要件を自然言語で記述します。コード提案は、提供されたコンテキストに基づいて関数とコードスニペットを生成します。

1. 候補を受け取ったら、次のいずれかを実行できます:
   - 候補に賛成の場合は、<kbd>Tab</kbd>キーを押します。
   - 部分的な候補に賛成の場合は、<kbd>Control</kbd>+<kbd>右矢印</kbd>または<kbd>Command</kbd>+<kbd>右矢印</kbd>を押します。
   - 候補に賛成しない場合は、<kbd>Esc</kbd>キーを押します。
   - 候補を無視するには、通常どおり入力を続けます。

詳細については、[コード提案ドキュメント](../../project/repository/code_suggestions/_index.md)を参照してください。

これで、チャットとコード提案の使用方法がわかりました。Webアプリケーションのビルドを開始しましょう。まず、整理されたPythonプロジェクト構造を作成します。

## プロジェクト構造を作成する {#create-the-project-structure}

まず、Pythonのベストプラクティスに従った、適切に構成されたプロジェクト構造が必要です。適切な構造により、コードの保守性、テストのしやすさ、および他のデベロッパーの理解度が向上します。

チャットを使用して、Pythonプロジェクトの編成規則を理解し、適切なファイルを生成できます。これにより、ベストプラクティスの調査時間を節約し、重要なコンポーネントを見逃すことがなくなります。

1. IDEでチャットを開き、次のように入力します:

   ```plaintext
   What is the recommended project structure for a Python web application? Include
   common files, and explain the purpose of each file.
   ```

   このプロンプトは、ファイルを作成する前に、Pythonプロジェクトの編成を理解するのに役立ちます。

1. Pythonプロジェクトの新しいフォルダーを作成し、チャットの応答に基づいてディレクトリとファイル構造を作成します。おそらく次のようになります:

   ```plaintext
   python-shop-app/
   ├── LICENSE
   ├── README.md
   ├── requirements.txt
   ├── setup.py
   ├── .gitignore
   ├── .env
   ├── app/
   │   ├── __init__.py
   │   ├── models/
   │   │   ├── __init__.py
   │   │   └── article.py
   │   ├── routes/
   │   │   ├── __init__.py
   │   │   └── shop.py
   │   └── database.py
   └── tests/
       ├── __init__.py
       └── test_shop.py
   ```

1. `.gitignore`ファイルに入力する必要があります。次に示すコードをチャットに入力します:

   ```plaintext
   Generate a .gitignore file for a Python project that uses Flask, SQLite, and
   virtual environments. Include common IDE files.
   ```

1. 応答を`.gitignore`ファイルにコピーします。

1. `README`ファイルの場合は、次に示すコードをチャットに入力します:

   ```plaintext
   Generate a README.md file for a Python web application that manages a bookstore
   inventory. Make sure that it includes all sections for requirements, setup, and usage.
   ```

これで、業界のベストプラクティスに従った、適切に構造化されたPythonプロジェクトが作成されました。この編成により、コードの保守とテストが容易になります。次に、開発環境をセットアップして、コードの記述を開始します。

## 開発環境のセットアップ {#set-up-the-development-environment}

適切に分離された開発環境により、依存関係の競合が防止され、アプリケーションをデプロイできるようになります。

チャットを使用してPythonの仮想環境変数をセットアップし、適切な依存関係を持つ`requirements.txt`ファイルを作成します。これにより、開発のための安定した基盤が確保されます。

```plaintext
   python-shop-app/
   ├── LICENSE
   ├── README.md
   ├── requirements.txt <= File you are updating
   ├── setup.py
   ├── .gitignore
   ├── .env
   ├── app/
   │   ├── __init__.py
   │   ├── models/
   │   │   ├── __init__.py
   │   │   └── article.py
   │   ├── routes/
   │   │   ├── __init__.py
   │   │   └── shop.py
   │   └── database.py
   └── tests/
       ├── __init__.py
       └── test_shop.py
```

1. オプション。PythonとFlaskが連携してWebアプリケーションを生成する方法について、チャットに質問してください。

1. チャットを使用して、Python環境をセットアップするためのベストプラクティスを理解します:

   ```plaintext
   What are the recommended steps for setting up a Python virtual environment with
   Flask? Include information about requirements.txt and pip.
   ```

   必要に応じて、フォローアップの質問をしてください。次に例を示します: 

   ```plaintext
   What does the requirements.txt do in a Python web app?
   ```

1. 応答に基づいて、まず仮想環境変数を作成してアクティブ化します（たとえば、Homebrewの`python3`パッケージを使用してMacOSで）:

   ```plaintext
   python3 -m venv myenv
   source myenv/bin/activate
   ```

1. `requirements.txt`ファイルも作成する必要があります。次に示すコードをチャットに質問します:

   ```plaintext
   What should be included in requirements.txt for a Flask web application with
   SQLite database and testing capabilities? Include specific version numbers.
   ```

   応答を`requirements.txt`ファイルにコピーします。

1. `requirements.txt`ファイルで指定された依存関係をインストールします:

   ```plaintext
   pip install -r requirements.txt
   ```

これで、開発環境は、競合を防止するために仮想環境変数で分離された、必要なすべての依存関係で設定されました。次に、プロジェクトのパッケージと設定を設定します。

## プロジェクトを設定する {#configure-the-project}

環境変数を含む適切な設定により、アプリケーションは異なる環境間で一貫して実行できます。

コード提案を使用して、設定を生成および改良します。次に、各設定の目的をチャットに質問して、設定している内容とその理由を理解できるようにします。

1. プロジェクトフォルダーに`setup.py`というPython設定ファイルを既に作成しています:

   ```plaintext
      python-shop-app/
      ├── LICENSE
      ├── README.md
      ├── requirements.txt
      ├── setup.py <= File you are updating
      ├── .gitignore
      ├── .env
      ├── app/
      │   ├── __init__.py
      │   ├── models/
      │   │   ├── __init__.py
      │   │   └── article.py
      │   ├── routes/
      │   │   ├── __init__.py
      │   │   └── shop.py
      │   └── database.py
      └── tests/
          ├── __init__.py
          └── test_shop.py
   ```

   このファイルを開き、ファイルの先頭にこのコメントを入力します:

   ```plaintext
   # Populate this setup.py configuration file for a Flask web application
   # Include dependencies for Flask, testing, and database functionality
   # Use semantic versioning
   ```

   コード提案により、設定が生成されます。

1. オプション。生成されたコードを選択し、次の[スラッシュコマンド](../../gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands)を使用します:

   - [`/explain`](../../gitlab_duo_chat/examples.md#explain-selected-code)を使用して、各設定の設定内容を理解します。
   - [`/refactor`](../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide)を使用して、設定構造で改善できる可能性のある箇所を特定します。

1. 必要に応じて、生成されたコードをレビューして調整します。

   設定ファイルで調整できる内容がわからない場合は、チャットに質問してください。

   調整する内容をチャットに質問する場合は、GitLab UIではなく、`setup.py`ファイルでIDEで質問してください。これにより、作成したばかりの`setup.py`ファイルなど、[作業中のコンテキスト](../../gitlab_duo/context.md#gitlab-duo-chat)がチャットに提供されます。

   ```plaintext
   You have used Code Suggestions to generate a Python configuration file, `setup.py`,
   for a Flask web application. This file includes dependencies for Flask, testing,
   and database functionality. If I were to review this file, what might I want
   to change and adjust?
   ```

1. ファイルを保存します。

### 環境変数を設定します。 {#set-the-environment-variables}

次に、チャットとコード提案の両方を使用して、環境変数を設定します。

1. チャットで、次に示すコードを質問します:

   ```plaintext
   In a Python project, what environment variables should be set for a Flask application in development mode? Include database configuration.
   ```

1. 環境変数を格納するために、`.env`ファイルを既に作成しています。

   ```plaintext
      python-shop-app/
      ├── LICENSE
      ├── README.md
      ├── requirements.txt
      ├── setup.py
      ├── .gitignore
      ├── .env <= File you are updating
      ├── app/
      │   ├── __init__.py
      │   ├── models/
      │   │   ├── __init__.py
      │   │   └── article.py
      │   ├── routes/
      │   │   ├── __init__.py
      │   │   └── shop.py
      │   └── database.py
      └── tests/
          ├── __init__.py
          └── test_shop.py
   ```

   このファイルを開き、チャットが推奨する環境変数を含め、ファイルの先頭に次のコメントを入力します:

   ```plaintext
   # Populate this .env file to store environment variables
   # Include the following
   # ...
   # Use semantic versioning
   ```

1. 必要に応じて、生成されたコードをレビューして調整し、ファイルを保存します。

プロジェクトを設定し、環境変数を設定しました。これにより、アプリケーションは異なる環境間で一貫してデプロイできます。次に、在庫システムのアプリケーションコードを作成します。

## アプリケーションコードを作成する {#create-the-application-code}

Flask Webフレームワークには、3つの主要なコンポーネントがあります:

- モデル: データとビジネスロジック、およびデータベースモデルが含まれています。`article.py`ファイルで指定されています。
- ビュー: HTTPリクエストと応答を処理します。`shop.py`ファイルで指定されています。
- コントローラー: データストレージと検索を管理します。`database.py`ファイルで指定されています。

Pythonプロジェクト構造の3つのファイルで、これら3つのコンポーネントをそれぞれ定義するために、チャットとコード提案を使用します:

- `article.py`は、モデルコンポーネント、特にデータベースモデルを定義します。
- `shop.py`は、ビューコンポーネント、特にAPIエンドポイントを定義します。
- `database.py`は、コントローラーコンポーネントを定義します。

### データベースモデルを定義するために記事ファイルを作成する {#create-the-article-file-to-define-the-database-model}

書店では、在庫を効果的に管理するために、データベースモデルと操作が必要です。

書店の在庫システムのアプリケーションコードを作成するには、記事ファイルを使用して記事のデータベースモデルを定義します。

コード提案を使用してコードを生成し、チャットを使用してデータモデリングとデータベース管理のベストプラクティスを実装します。

1. `article.py`ファイルを既に作成しています:

   ```plaintext
      python-shop-app/
      ├── LICENSE
      ├── README.md
      ├── requirements.txt
      ├── setup.py
      ├── .gitignore
      ├── .env
      ├── app/
      │   ├── __init__.py
      │   ├── models/
      │   │   ├── __init__.py
      │   │   └── article.py <= File you are updating
      │   ├── routes/
      │   │   ├── __init__.py
      │   │   └── shop.py
      │   └── database.py
      └── tests/
          ├── __init__.py
          └── test_shop.py
   ```

   このファイルでは、コード提案を使用して、次に示すコードを入力します:

   ```plaintext
   # Create an Article class for a bookstore inventory system
   # Include fields for: name, price, quantity
   # Add data validation for each field
   # Add methods to convert to/from dictionary format
   ```

1. オプション。次に示す[スラッシュコマンド](../../gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands)を使用します:

   - [`/explain`](../../gitlab_duo_chat/examples.md#explain-selected-code)を使用して、記事クラスの動作とその設計パターンを理解します。
   - [`/refactor`](../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide)を使用して、クラス構造とメソッドで改善できる可能性のある箇所を特定します。

1. 必要に応じて、生成されたコードをレビューして調整し、ファイルを保存します。

次に、APIエンドポイントを定義します。

### APIエンドポイントを定義するためにショップファイルを作成する {#create-the-shop-file-to-define-the-api-routes}

データベースモデルを定義するために記事ファイルを作成したので、APIエンドポイントを作成します。

APIエンドポイントは、Webアプリケーションにとって非常に重要です。理由は次のとおりです:

- クライアントがアプリケーションと対話するためのパブリックAPIを定義します。
- HTTPリクエストをアプリケーション内の適切なコードにマップします。
- 入力の検証とエラー応答を処理します。
- 内部モデルと、APIクライアントが予期するJSON形式の間でデータを変換します。

書店在庫システムの場合、これらのエンドポイントを使用すると、スタッフは次のことを実行できます:

- 在庫内のすべての書籍を表示します。
- IDで特定の書籍を検索します。
- 新しい書籍の入荷時に登録します。
- 価格や数量など、書籍の情報を更新します。
- 不要になった書籍を削除します。

Flaskでは、エンドポイントは特定のURLエンドポイントへのリクエストを処理する関数です。たとえば、`GET /books`のエンドポイントはすべての書籍のリストを返し、`POST /books`は新しい書籍を在庫に追加します。

プロジェクト構造ですでにセットアップした`shop.py`ファイルで、チャットとコード提案を使用してこれらのエンドポイントを作成します:

```plaintext
python-shop-app/
├── LICENSE
├── README.md
├── requirements.txt
├── setup.py
├── .gitignore
├── .env
├── app/
│   ├── __init__.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── article.py
│   ├── routes/
│   │   ├── __init__.py
│   │   └── shop.py <= File you are updating
│   └── database.py
└── tests/
   ├── __init__.py
   └── test_shop.py
```

#### Flaskアプリケーションとエンドポイントを作成する {#create-the-flask-application-and-routes}

1. `shop.py`ファイルを開きます。コード提案を使用するには、ファイルの先頭にこのコメントを入力します:

   ```plaintext
   # Create Flask routes for a bookstore inventory system
   # Include routes for:
   # - Getting all books (GET /books)
   # - Getting a single book by ID (GET /books/<id>)
   # - Adding a new book (POST /books)
   # - Updating a book (PUT /books/<id>)
   # - Deleting a book (DELETE /books/<id>)
   # Use the Article class from models.article and database from database.py
   # Include proper error handling and HTTP status codes
   ```

1. 生成されたコードをレビューします。内容は次のとおりです:

   - Flask、リクエスト、および`jsonify`のインポートステートメント。
   - Articleクラスとデータベースモジュールのインポートステートメント。
   - すべてのCRUD操作（作成、読み取り、更新、削除）のエンドポイント定義。
   - 適切なエラー処理とHTTPステータスコード。

1. オプション。次に示すコードのスラッシュコマンドを使用します:

   - [`/explain`](../../gitlab_duo_chat/examples.md#explain-selected-code)を使用して、Flaskルーティングの仕組みを理解します。
   - [`/refactor`](../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide)を使用して、改善できる可能性のある箇所を特定します。

1. 生成されたコードがニーズを完全に満たしていない場合、または改善方法を理解したい場合は、`shop.py`ファイル内からチャットで質問できます:

   ```plaintext
   Can you suggest improvements for my Flask routes in this shop.py file?
   I want to ensure that:
   1. The routes follow RESTful API design principles
   2. Responses include appropriate HTTP status codes
   3. Input validation is handled properly
   4. The code follows Flask best practices
   ```

1. `app`ディレクトリ内の`__init__.py`ファイルでFlaskアプリケーションインスタンスも作成する必要があります。このファイルを開き、コード提案を使用して適切なコードを生成します:

   ```plaintext
   # Create a Flask application factory
   # Configure the app with settings from environment variables
   # Register the shop blueprint
   # Return the configured app
   ```

1. 両方のファイルを保存します。

### データストレージと検索を管理するためにデータベースファイルを作成する {#create-the-database-file-to-manage-data-storage-and-retrieval}

最後に、データベース操作コードを作成します。`database.py`ファイルを既に作成しています。

```plaintext
   python-shop-app/
   ├── LICENSE
   ├── README.md
   ├── requirements.txt
   ├── setup.py
   ├── .gitignore
   ├── .env
   ├── app/
   │   ├── __init__.py
   │   ├── models/
   │   │   ├── __init__.py
   │   │   └── article.py
   │   ├── routes/
   │   │   ├── __init__.py
   │   │   └── shop.py
   │   └── database.py <= File you are updating
   └── tests/
       ├── __init__.py
       └── test_shop.py
```

1. 次に示すコードをチャットに入力します:

   ```plaintext
   Generate a Python class that manages SQLite database operations for a bookstore inventory. Include:
   - Context manager for connections
   - Table creation
   - CRUD operations
   - Error handling
   Show the complete code with comments.
   ```

1. 必要に応じて、生成されたコードをレビューして調整し、ファイルを保存します。

これで、在庫管理システムの基本的なコードが正常に作成され、Flaskフレームワークを使用してビルドされたPython Webアプリケーションの中核コンポーネントが定義されました。

次に、作成したコードをサンプルコードファイルと照合します。

## 作成したコードをサンプルコードファイルと照合する {#check-your-code-against-example-code-files}

次に示すコードは、チュートリアルに従った後に最終的に作成されるコードと同様であるはずの、完全な動作コードを示しています。

{{< tabs >}}

{{< tab title=".gitignore" >}}

このファイルは、標準のPythonプロジェクトの除外を示しています:

```plaintext
# Virtual Environment
myenv/
venv/
ENV/
env/
.venv/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# SQLite database files
*.db
*.sqlite
*.sqlite3

# Environment variables
.env
.env.local
.env.*.local

# IDE specific files
.idea/
.vscode/
*.swp
*.swo
.DS_Store
```

{{< /tab >}}

{{< tab title="README.md" >}}
<!-- markdownlint-disable MD029 -->
設定と使用方法の指示が記載された包括的な`README`ファイル。

````markdown
# Bookstore Inventory Management System

A Python web application for managing bookstore inventory, built with Flask and SQLite.

## Features

- Track book inventory in real time.
- Add, update, and remove books.
- Data validation to prevent common errors.
- RESTful API for inventory management.

## Requirements

- Python 3.8 or higher.
- Flask 2.2.0 or higher.
- SQLite 3.

## Installation

1. Clone the repository:

   ```shell
   git clone https://gitlab.com/your-username/python-shop-app.git
   cd python-shop-app
   ```

2. Create and activate a virtual environment:

   ```shell
   python -m venv myenv
   source myenv/bin/activate  # On Windows: myenv\Scripts\activate
   ```

3. Install dependencies:

   ```shell
   pip install -r requirements.txt
   ```

4. Set up environment variables:

   Copy `.env.example` to `.env` and modify as needed.

## Usage

1. Start the Flask application:

   ```shell
   flask run
   ```

2. The API will be available at `http://localhost:5000/`

## API Endpoints

- `GET /books` - Get all books
- `GET /books/<id>` - Get a specific book
- `POST /books` - Add a new book
- `PUT /books/<id>` - Update a book
- `DELETE /books/<id>` - Delete a book

## Testing

Run tests with `pytest`:

```python
python -m pytest
```
````
<!-- markdownlint-enable MD029 -->
{{< /tab >}}

{{< tab title="requirements.txt" >}}

必要なすべてのPythonパッケージをバージョンとともにリストします。

```plaintext
Flask==2.2.3
pytest==7.3.1
pytest-flask==1.2.0
Flask-SQLAlchemy==3.0.3
SQLAlchemy==2.0.9
python-dotenv==1.0.0
Werkzeug==2.2.3
requests==2.28.2
```

{{< /tab >}}

{{< tab title="setup.py" >}}

パッケージングのプロジェクト設定。

```python
from setuptools import setup, find_packages

setup(
    name="bookstore-inventory",
    version="0.1.0",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "Flask>=2.2.0",
        "Flask-SQLAlchemy>=3.0.0",
        "SQLAlchemy>=2.0.0",
        "pytest>=7.0.0",
        "pytest-flask>=1.2.0",
        "python-dotenv>=1.0.0",
    ],
    python_requires=">=3.8",
    author="Your Name",
    author_email="your.email@example.com",
    description="A Flask web application for managing bookstore inventory",
    keywords="flask, inventory, bookstore",
    url="https://gitlab.com/your-username/python-shop-app",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Environment :: Web Environment",
        "Framework :: Flask",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
    ],
)
```

{{< /tab >}}

{{< tab title=".env" >}}

アプリケーションの環境変数が含まれています。

```plaintext
# Flask configuration
FLASK_APP=app
FLASK_ENV=development
FLASK_DEBUG=1
SECRET_KEY=your-secret-key-change-in-production

# Database configuration
DATABASE_URL=sqlite:///bookstore.db
TEST_DATABASE_URL=sqlite:///test_bookstore.db

# Application settings
BOOK_TITLE_MAX_LENGTH=100
MAX_PRICE=1000.00
MAX_QUANTITY=1000
```

{{< /tab >}}

{{< tab title="app/models/article.py" >}}

完全な検証を備えた記事クラス。

```python
class Article:
    """Article class for a bookstore inventory system."""

    def __init__(self, name, price, quantity, article_id=None):
        """
        Initialize an article with validation.

        Args:
            name (str): The name/title of the book
            price (float): The price of the book
            quantity (int): The quantity in stock
            article_id (int, optional): The unique identifier for the article

        Raises:
            ValueError: If any of the fields fail validation
        """
        self.id = article_id
        self.set_name(name)
        self.set_price(price)
        self.set_quantity(quantity)

    def set_name(self, name):
        """
        Set the name with validation.

        Args:
            name (str): The name/title of the book

        Raises:
            ValueError: If name is empty or too long
        """
        if not name or not isinstance(name, str):
            raise ValueError("Book title cannot be empty and must be a string")

        if len(name) > 100:  # Max length validation
            raise ValueError("Book title cannot exceed 100 characters")

        self.name = name.strip()

    def set_price(self, price):
        """
        Set the price with validation.

        Args:
            price (float): The price of the book

        Raises:
            ValueError: If price is negative or not a number
        """
        try:
            price_float = float(price)
        except (ValueError, TypeError):
            raise ValueError("Price must be a number")

        if price_float < 0:
            raise ValueError("Price cannot be negative")

        if price_float > 1000:  # Max price validation
            raise ValueError("Price cannot exceed 1000")

        # Ensure price has at most 2 decimal places
        self.price = round(price_float, 2)

    def set_quantity(self, quantity):
        """
        Set the quantity with validation.

        Args:
            quantity (int): The quantity in stock

        Raises:
            ValueError: If quantity is negative or not an integer
        """
        try:
            quantity_int = int(quantity)
        except (ValueError, TypeError):
            raise ValueError("Quantity must be an integer")

        if quantity_int < 0:
            raise ValueError("Quantity cannot be negative")

        if quantity_int > 1000:  # Max quantity validation
            raise ValueError("Quantity cannot exceed 1000")

        self.quantity = quantity_int

    def to_dict(self):
        """
        Convert the article to a dictionary.

        Returns:
            dict: Dictionary representation of the article
        """
        return {
            "id": self.id,
            "name": self.name,
            "price": self.price,
            "quantity": self.quantity
        }

    @classmethod
    def from_dict(cls, data):
        """
        Create an article from a dictionary.

        Args:
            data (dict): Dictionary with article data

        Returns:
            Article: New article instance
        """
        article_id = data.get("id")
        return cls(
            name=data["name"],
            price=data["price"],
            quantity=data["quantity"],
            article_id=article_id
        )
```

{{< /tab >}}

{{< tab title="app/routes/shop.py" >}}

エラー処理を備えた完全なAPIエンドポイント。

```python
from flask import Blueprint, request, jsonify, current_app
from app.models.article import Article
from app import database
import logging

# Create a blueprint for the shop routes
shop_bp = Blueprint('shop', __name__, url_prefix='/books')

# Set up logging
logger = logging.getLogger(__name__)

@shop_bp.route('', methods=['GET'])
def get_all_books():
    """Get all books from the inventory."""
    try:
        books = database.get_all_articles()
        return jsonify([book.to_dict() for book in books]), 200
    except Exception as e:
        logger.error(f"Error getting all books: {str(e)}")
        return jsonify({"error": "Failed to retrieve books"}), 500

@shop_bp.route('/<int:book_id>', methods=['GET'])
def get_book(book_id):
    """Get a specific book by ID."""
    try:
        book = database.get_article_by_id(book_id)
        if book:
            return jsonify(book.to_dict()), 200
        return jsonify({"error": f"Book with ID {book_id} not found"}), 404
    except Exception as e:
        logger.error(f"Error getting book {book_id}: {str(e)}")
        return jsonify({"error": f"Failed to retrieve book {book_id}"}), 500

@shop_bp.route('', methods=['POST'])
def add_book():
    """Add a new book to the inventory."""
    data = request.get_json()

    if not data:
        return jsonify({"error": "No data provided"}), 400

    required_fields = ['name', 'price', 'quantity']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Missing required field: {field}"}), 400

    try:
        # Validate data by creating an Article object
        new_book = Article(
            name=data['name'],
            price=data['price'],
            quantity=data['quantity']
        )

        # Save to database
        book_id = database.add_article(new_book)

        # Return the created book
        created_book = database.get_article_by_id(book_id)
        return jsonify(created_book.to_dict()), 201

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error adding book: {str(e)}")
        return jsonify({"error": "Failed to add book"}), 500

@shop_bp.route('/<int:book_id>', methods=['PUT'])
def update_book(book_id):
    """Update an existing book."""
    data = request.get_json()

    if not data:
        return jsonify({"error": "No data provided"}), 400

    try:
        # Check if book exists
        existing_book = database.get_article_by_id(book_id)
        if not existing_book:
            return jsonify({"error": f"Book with ID {book_id} not found"}), 404

        # Update book properties
        if 'name' in data:
            existing_book.set_name(data['name'])
        if 'price' in data:
            existing_book.set_price(data['price'])
        if 'quantity' in data:
            existing_book.set_quantity(data['quantity'])

        # Save updated book
        database.update_article(existing_book)

        # Return the updated book
        updated_book = database.get_article_by_id(book_id)
        return jsonify(updated_book.to_dict()), 200

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error updating book {book_id}: {str(e)}")
        return jsonify({"error": f"Failed to update book {book_id}"}), 500

@shop_bp.route('/<int:book_id>', methods=['DELETE'])
def delete_book(book_id):
    """Delete a book from the inventory."""
    try:
        # Check if book exists
        existing_book = database.get_article_by_id(book_id)
        if not existing_book:
            return jsonify({"error": f"Book with ID {book_id} not found"}), 404

        # Delete the book
        database.delete_article(book_id)

        return jsonify({"message": f"Book with ID {book_id} deleted successfully"}), 200

    except Exception as e:
        logger.error(f"Error deleting book {book_id}: {str(e)}")
        return jsonify({"error": f"Failed to delete book {book_id}"}), 500
```

{{< /tab >}}

{{< tab title="app/database.py" >}}

接続管理によるデータベース操作。

```python
import sqlite3
import os
import logging
from contextlib import contextmanager
from app.models.article import Article

# Set up logging
logger = logging.getLogger(__name__)

# Get database path from environment variable or use default
DATABASE_PATH = os.environ.get('DATABASE_PATH', 'bookstore.db')

@contextmanager
def get_db_connection():
    """
    Context manager for database connections.
    Automatically handles connection opening, committing, and closing.

    Yields:
        sqlite3.Connection: Database connection object
    """
    conn = None
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        # Configure connection to return rows as dictionaries
        conn.row_factory = sqlite3.Row
        yield conn
        conn.commit()
    except sqlite3.Error as e:
        if conn:
            conn.rollback()
        logger.error(f"Database error: {str(e)}")
        raise
    finally:
        if conn:
            conn.close()

def initialize_database():
    """
    Initialize the database by creating the articles table if it doesn't exist.
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            # Create articles table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS articles (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    price REAL NOT NULL,
                    quantity INTEGER NOT NULL
                )
            ''')

            logger.info("Database initialized successfully")
    except sqlite3.Error as e:
        logger.error(f"Failed to initialize database: {str(e)}")
        raise

def add_article(article):
    """
    Add a new article to the database.

    Args:
        article (Article): Article object to add

    Returns:
        int: ID of the newly added article
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                "INSERT INTO articles (name, price, quantity) VALUES (?, ?, ?)",
                (article.name, article.price, article.quantity)
            )

            # Get the ID of the newly inserted article
            article_id = cursor.lastrowid
            logger.info(f"Added article with ID {article_id}")
            return article_id
    except sqlite3.Error as e:
        logger.error(f"Failed to add article: {str(e)}")
        raise

def get_article_by_id(article_id):
    """
    Get an article by its ID.

    Args:
        article_id (int): ID of the article to retrieve

    Returns:
        Article: Article object if found, None otherwise
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("SELECT * FROM articles WHERE id = ?", (article_id,))
            row = cursor.fetchone()

            if row:
                return Article(
                    name=row['name'],
                    price=row['price'],
                    quantity=row['quantity'],
                    article_id=row['id']
                )
            return None
    except sqlite3.Error as e:
        logger.error(f"Failed to get article {article_id}: {str(e)}")
        raise

def get_all_articles():
    """
    Get all articles from the database.

    Returns:
        list: List of Article objects
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("SELECT * FROM articles")
            rows = cursor.fetchall()

            articles = []
            for row in rows:
                article = Article(
                    name=row['name'],
                    price=row['price'],
                    quantity=row['quantity'],
                    article_id=row['id']
                )
                articles.append(article)

            return articles
    except sqlite3.Error as e:
        logger.error(f"Failed to get all articles: {str(e)}")
        raise

def update_article(article):
    """
    Update an existing article in the database.

    Args:
        article (Article): Article object with updated values

    Returns:
        bool: True if successful, False if article not found
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                "UPDATE articles SET name = ?, price = ?, quantity = ? WHERE id = ?",
                (article.name, article.price, article.quantity, article.id)
            )

            # Check if an article was actually updated
            if cursor.rowcount == 0:
                logger.warning(f"No article found with ID {article.id}")
                return False

            logger.info(f"Updated article with ID {article.id}")
            return True
    except sqlite3.Error as e:
        logger.error(f"Failed to update article {article.id}: {str(e)}")
        raise

def delete_article(article_id):
    """
    Delete an article from the database.

    Args:
        article_id (int): ID of the article to delete

    Returns:
        bool: True if successful, False if article not found
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("DELETE FROM articles WHERE id = ?", (article_id,))

            # Check if an article was actually deleted
            if cursor.rowcount == 0:
                logger.warning(f"No article found with ID {article_id}")
                return False

            logger.info(f"Deleted article with ID {article_id}")
            return True
    except sqlite3.Error as e:
        logger.error(f"Failed to delete article {article_id}: {str(e)}")
        raise
```

{{< /tab >}}
<!-- markdownlint-disable -->
{{< tab title="app/__init__.py" >}}
<!-- markdownlint-enable -->
Flaskアプリケーションファクトリー。

```python
import os
from flask import Flask
from dotenv import load_dotenv

def create_app(test_config=None):
    """
    Application factory for creating the Flask app.

    Args:
        test_config (dict, optional): Test configuration to override default config

    Returns:
        Flask: Configured Flask application
    """
    # Load environment variables from .env file
    load_dotenv()

    # Create and configure the app
    app = Flask(__name__, instance_relative_config=True)

    # Set default configuration
    app.config.from_mapping(
        SECRET_KEY=os.environ.get('SECRET_KEY', 'dev'),
        DATABASE_PATH=os.environ.get('DATABASE_URL', 'bookstore.db'),
        BOOK_TITLE_MAX_LENGTH=int(os.environ.get('BOOK_TITLE_MAX_LENGTH', 100)),
        MAX_PRICE=float(os.environ.get('MAX_PRICE', 1000.00)),
        MAX_QUANTITY=int(os.environ.get('MAX_QUANTITY', 1000))
    )

    # Override config with test config if provided
    if test_config:
        app.config.update(test_config)

    # Ensure the instance folder exists
    os.makedirs(app.instance_path, exist_ok=True)

    # Initialize database
    from app import database
    database.initialize_database()

    # Register blueprints
    from app.routes.shop import shop_bp
    app.register_blueprint(shop_bp)

    # Add a simple index route
    @app.route('/')
    def index():
        return {
            "message": "Welcome to the Bookstore Inventory API",
            "endpoints": {
                "books": "/books",
                "book_by_id": "/books/<id>"
            }
        }

    return app
```

{{< /tab >}}

{{< /tabs >}}

1. これらの例と照らし合わせて、コードファイルを確認してください。

1. コードが動作するかどうかを確認するには、チャットでローカルアプリケーションサーバーを起動する方法を尋ねてください:

   ```plaintext
   How do I start a local application server for my Python web application?
   ```

1. 手順に従って、アプリケーションが動作しているか確認してください。

アプリケーションが動作している場合、おめでとうございます。GitLab Duoチャットとコード提案を正常に使用して、動作するオンラインショップアプリケーションを構築しました。

動作していない場合は、理由を調べる必要があります。チャットとコード提案を使用すると、アプリケーションが期待どおりに動作することを確認し、修正が必要なイシューを特定するためのテストを作成できます。

<!-- markdownlint-disable -->
<i class="fa-youtube-play" aria-hidden="true"></i>詳しくは、[Duo /fixの使用](https://youtu.be/agTqx__j6Ko?si=vpLfVvmFVcBivB1g)をご覧ください。
<!-- Video published on 2025-02-13 -->

## 関連トピック {#related-topics}

- [GitLab Duoのユースケース](../use_cases.md)
- [GitLab Duoのスタートガイド](../../get_started/getting_started_gitlab_duo.md)
- ブログ投稿: [GitLab DuoでDevSecOpsエンジニアリングのワークフローを効率化](https://about.gitlab.com/blog/2024/12/05/streamline-devsecops-engineering-workflows-with-gitlab-duo/)
  <!-- Video published on 2024-04-18 -->
- <i class="fa-youtube-play" aria-hidden="true"></i>[GitLab Duoチャット](https://youtu.be/ZQBAuf-CTAY?si=0o9-xJ_ATTsL1oew)
  <!-- Video published on 2024-01-24 -->
- <i class="fa-youtube-play" aria-hidden="true"></i>[GitLab Duoコード提案](https://youtu.be/ds7SG1wgcVM?si=MfbzPIDpikGhoPh7)
  <!-- Video published on 2025-03-18 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duoによるアプリケーションのモダナイゼーション（C++からJavaへ）](https://youtu.be/FjoAmt5eeXA?si=SLv9Mv8eSUAVwW5Z)

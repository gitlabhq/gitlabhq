---
stage: Analytics
group: Platform Insights
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'チュートリアル: GitLab Pagesウェブサイトプロジェクトでプロダクト分析をセットアップする'
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

<!-- vale gitlab_base.FutureTense = NO -->

ウェブサイトまたはアプリケーションでのユーザーのエンゲージメントを理解することは、データに基づいた意思決定を行う上で重要です。ユーザーが最も使用する機能と最も使用しない機能を特定することで、チームはどこに、どのように時間を費やすかを効果的に決定できます。

この手順に従って、ウェブサイトのサンプルプロジェクトをセットアップし、プロジェクトのプロダクト分析をオンボーディングし、イベントの収集を開始するようにウェブサイトをインストルメントし、プロジェクトレベルのダッシュボードを使用してユーザーの行動を理解する方法を学びます。

これから次の手順を実行します:

1. テンプレートからプロジェクトを作成する
1. プロダクト分析でプロジェクトをオンボードする
1. 追跡スニペットでウェブサイトを計測する
1. 利用状況データを収集する
1. ダッシュボードを表示

## はじめる前 {#before-you-begin}

このチュートリアルを実行するには、以下が必要です:

- インスタンスの[プロダクト分析を有効化](../../development/internal_analytics/product_analytics.md#enable-product-analytics)します。
- プロジェクトを作成するグループのオーナーロールが必要です。

## テンプレートからプロジェクトを作成する {#create-a-project-from-a-template}

まず、グループにプロジェクトを作成する必要があります。

GitLabにはプロジェクトテンプレートが用意されており、さまざまなユースケースに必要なすべてのファイルを使用して、プロジェクトを簡単にセットアップできます。ここでは、プレーンなHTML Webサイトのプロジェクトを作成します。

プロジェクトを作成するには、以下を実行します:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **テンプレートから作成**を選択します。
1. **Pages/Plain HTML**テンプレートを選択します。
1. **プロジェクト名**テキストボックスに、名前（たとえば、`My website`）を入力します。
1. **プロジェクトのURL**ドロップダウンリストから、プロジェクトを作成するグループを選択します。
1. **プロジェクトslug**テキストボックスに、プロジェクトのslugを入力します（例：`my-website`）。
1. オプション。**プロジェクトの説明**テキストボックスに、プロジェクトのプロジェクトの説明を入力します。たとえば`Plain HTML website with product analytics`などです。この説明はいつでも追加または編集できます。
1. **表示レベル**で、プロジェクトに必要なレベルを選択します。グループにプロジェクトを作成する場合、プロジェクトの表示レベル設定は、親グループの表示レベルと同じくらい制限されている必要があります。
1. **プロジェクトを作成**を選択します。

これで、プレーンなHTML Webサイトに必要なすべてのファイルを含むプロジェクトが作成されました。

## プロダクト分析でプロジェクトをオンボードする {#onboard-the-project-with-product-analytics}

ウェブサイトの利用状況に関するイベントを収集してダッシュボードを表示するには、プロジェクトにプロダクト分析をオンボードする必要があります。

新しいプロジェクトをプロダクト分析でオンボードするには、次の手順に従います:

1. プロジェクトで、**分析** > **分析ダッシュボード**を選択します。
1. **プロダクト分析**項目を見つけて、**セットアップ**を選択します。
1. **Set up product analytics**（プロダクト分析）のセットアップを選択します。
1. インスタンスの作成が完了するまで待ちます。
1. **HTML script setup**（HTMLスクリプトのセットアップ） スニペットをコピーします。これは、次の手順で必要になります。

プロジェクトがオンボーディングされ、アプリケーションがイベントの送信を開始する準備ができました。

## ウェブサイトを計測する {#instrument-your-website}

利用状況イベントを収集してGitLabに送信するには、コードスニペットをWebサイトに含める必要があります。アプリケーションと統合するために、いくつかのプラットフォームおよびテクノロジー固有の追跡SDKから選択できます。このウェブサイトの例では、Browser SDKを使用します。

新しいウェブサイトをインストルメントするには、次の手順に従います:

1. プロジェクトで、**コード** > **リポジトリ**を選択します。
1. プロジェクトで、**コード** > **Web IDE**を選択します。
1. 左側のWeb統合開発環境ツールバーで、**File Explorer**（ファイルエクスプローラー）を選択し、`public/index.html`ファイルを開きます。
1. `public/index.html`ファイルの閉じ`</body>`タグの前に、前のセクションでコピーしたスニペットを貼り付けます。

   `index.html`ファイル内のコードは次のようになります（`appId`と`host`には、オンボーディングセクションで指定された値があります）:

   ```html
   <!DOCTYPE html>
   <html>
     <head>
       <meta charset="utf-8">
       <meta name="generator" content="GitLab Pages">
       <title>Plain HTML site using GitLab Pages</title>
       <link rel="stylesheet" href="style.css">
     </head>
     <body>
       <div class="navbar">
         <a href="https://pages.gitlab.io/plain-html/">Plain HTML Example</a>
         <a href="https://gitlab.com/pages/plain-html/">Repository</a>
         <a href="https://gitlab.com/pages/">Other Examples</a>
       </div>

       <h1>Hello World!</h1>

       <p>
         This is a simple plain-HTML website on GitLab Pages, without any fancy static site generator.
       </p>
       <script src="https://unpkg.com/@gitlab/application-sdk-browser/dist/gl-sdk.min.js"></script>
       <script>
         window.glClient = window.glSDK.glClientSDK({
           appId: 'YOUR_APP_ID',
           host: 'YOUR_HOST',
         });
       </script>
     </body>
   </html>
   ```

1. 左側のWeb統合開発環境ツールバーで、**Source Control**（ソース管理）を選択します。
1. `Add GitLab product analytics tracking snippet`などのコミットメッセージを入力します。
1. **コミット**を選択し、新しいブランチを作成するかどうかを確認するプロンプトが表示された場合は、**次に進む**を選択します。これで、Web統合開発環境を閉じることができます。
1. プロジェクトで、**ビルド** > **パイプライン**を選択します。最近のコミットからパイプラインがトリガーされます。それが完了し、更新されたウェブサイトをデプロイするまで待ちます。

## 利用状況データを収集する {#collect-usage-data}

計測されたWebサイトがデプロイされると、イベントの収集が開始されます。

1. プロジェクトで、**デプロイ** > **Pages**を選択します。
1. Webサイトを開くには、**ページへアクセス**で独自のURLを選択します。
1. ページビューイベントを収集するには、ページを数回更新します。

## ダッシュボードを表示 {#view-dashboards}

GitLabには、デフォルトで2つのプロダクト分析ダッシュボードが用意されています: **オーディエンス**と**動作**。これらのダッシュボードは、プロジェクトがいくつかのイベントを受信すると使用できるようになります。

これらのダッシュボードを表示するには、次の手順に従います:

1. プロジェクトで、**分析** > **Dashboards**（ダッシュボード）を選択します。
1. 利用可能なダッシュボードのリストから、**オーディエンス**または**動作**を選択します。

以上です。これで、プロダクト分析を備えたウェブサイトプロジェクトが作成されました。これにより、データを収集および視覚化して、ユーザーの行動を理解し、チームの作業をより効率的に行うことができます。

---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: GitLabでHugoサイトをビルド、テスト、デプロイする'
---

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルでは、Hugoサイトをビルド、テスト、およびデプロイするためのCI/CDパイプラインの作成について説明します。

このチュートリアルの終わりまでに、動作するパイプラインと、GitLab PagesにデプロイされたHugoサイトが完成します。

これから行うことの概要は次のとおりです:

1. Hugoサイトを準備します。
1. GitLabプロジェクトを作成します。
1. HugoサイトをGitLabにプッシュします。
1. CI/CDパイプラインを使用してHugoサイトをビルドします。
1. GitLab Pagesを使用してHugoサイトをデプロイします。

## はじめる前 {#before-you-begin}

- GitLab.comのアカウント。
- Gitに精通していること。
- Hugoサイト（まだお持ちでない場合は、[Hugoクイックスタート](https://gohugo.io/getting-started/quick-start/)に従ってください）。

## Hugoサイトを準備する {#prepare-your-hugo-site}

まず、HugoサイトをGitLabにプッシュする準備ができていることを確認します。コンテンツ、テーマ、およびHugo設定ファイルが必要です。

GitLabがサイトをビルドするため、サイトをビルドしないでください。実際、後で競合が発生する可能性があるため、`public`フォルダーをアップロード**not**（しない）ことが重要です。

`public`フォルダーを除外する最も簡単な方法は、`.gitignore`ファイルを作成し、`public/`をテキストとして新しい行を追加することです。

これは、Hugoプロジェクトの最上位レベルで次のコマンドを使用して実行できます:

```shell
echo "public/" >> .gitignore
```

これにより、`public/`が新しい`.gitignore`ファイルに追加されるか、既存のファイルに追加されます。

Hugoサイトは、GitLabプロジェクトを作成した後、プッシュする準備ができました。

## GitLabプロジェクトを作成する {#create-a-gitlab-project}

まだの場合は、Hugoサイト用の空のGitLabプロジェクトを作成します。

空のプロジェクトをGitLabに作成するには:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. プロジェクトの詳細を入力します:
   - **プロジェクト名**フィールドに、プロジェクトの名前を入力します。名前は、小文字または大文字（`a-zA-Z`）、数字（`0-9`）、絵文字、またはアンダースコア（`_`）で始まる必要があります。ドット（`.`）、プラス記号（`+`）、ダッシュ（`-`）、またはスペースも使用できます。
   - **プロジェクトslug**フィールドに、プロジェクトへのパスを入力します。GitLabインスタンスは、このslugをプロジェクトへのURLパスとして使用します。slugを変更するには、最初にプロジェクト名を入力し、次にslugを変更します。
   - **表示レベル**は、PrivateまたはPublicのいずれかです。Privateを選択した場合でも、Webサイトは公開されていますが、コードはプライベートのままです。
   - 既存のリポジトリをプッシュするため、**リポジトリを初期化しREADMEファイルを生成する**のチェックを外します。
1. 準備ができたら、**プロジェクトを作成**を選択します。
1. この新しいプロジェクトにコードをプッシュする手順が表示されます。次の手順では、これらの手順が必要になります。

これで、Hugoサイトのホームができました。

## HugoサイトをGitLabにプッシュする {#push-your-hugo-site-to-gitlab}

次に、ローカルのHugoサイトをリモートのGitLabプロジェクトにプッシュする必要があります。

前の手順で新しいGitLabプロジェクトを作成した場合は、リポジトリを初期化し、ファイルをコミットしてプッシュする手順が表示されます。

それ以外の場合は、ローカルGitリポジトリのリモートオリジンがGitLabプロジェクトと一致することを確認してください。

デフォルトブランチが`main`であると仮定すると、次のコマンドでHugoサイトをプッシュできます:

```shell
git push origin main
```

サイトをプッシュすると、`public`フォルダーを除くすべてのコンテンツが表示されます。`public`フォルダーは、`.gitignore`ファイルによって除外されました。

次の手順では、CI/CDパイプラインを使用してサイトをビルドし、その`public`フォルダーを再作成します。

## CI/CDパイプラインを使用してHugoサイトをビルドする {#build-your-hugo-site-with-a-cicd-pipeline}

GitLabでHugoサイトをビルドするには、まず、CI/CDパイプラインの指示を指定するための`.gitlab-ci.yml`ファイルを作成する必要があります。これを以前に行ったことがない場合は、気が遠くなるように聞こえるかもしれません。ただし、GitLabには必要なものがすべて用意されています。

以下に示す`.gitlab-ci.yml`ファイルを使用するには、`hugo.toml`ファイルも一致するテーマパスを示していることを確認してください。以下の`hugo.toml`ファイルの例は、GitLab Pagesプロジェクトの`baseURL`設定も示しています。

```yaml
baseURL = 'https://<your-namespace>.gitlab.io/<project-path>'
languageCode = 'en-us'
title = 'Hugo on GitLab'
[module]
[[module.imports]]
  path = 'github.com/adityatelange/hugo-PaperMod'
```

### GitLab設定オプションを追加する {#add-your-gitlab-configuration-options}

`.gitlab-ci.yml`という特別なファイルで設定オプションを指定します。

Hugoテンプレートを使用して`.gitlab-ci.yml`ファイルを作成するには:

1. 左側のサイドバーで、**コード** > **リポジトリ**を選択します。
1. ファイルリストの上にあるプラスアイコン（+）を選択し、ドロップダウンリストから**新しいファイル**を選択します。
1. ファイル名に`.gitlab-ci.yml`を入力します。先頭のピリオドを省略しないでください。
1. **テンプレートを適用**ドロップダウンリストを選択し、フィルターボックスに「Hugo」と入力します。
1. 結果**Hugo**を選択すると、<CI/CD</CI/CD>を使用してHugoサイトをビルドするために必要なすべてのコードがファイルに入力された状態になります。

この`.gitlab-ci.yml`ファイルで何が起こっているのかを詳しく見てみましょう。

```yaml
default:
  image: "hugomods/hugo:exts"

variables:
  GIT_SUBMODULE_STRATEGY: recursive
  THEME_URL: "github.com/adityatelange/hugo-PaperMod"

test:  # builds and tests your site
  script:
    - hugo
  rules:
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH

create-pages:  # a user-defined job that builds your pages and saves them to the specified path.
  script:
    - hugo
  pages: true  # specifies that this is a Pages job
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

- `image`は、Hugoを含むGitLabレジストリからのイメージを指定します。このイメージは、サイトがビルドされる環境を作成するために使用されます。
- `GIT_SUBMODULE_STRATEGY`変数は、GitLabがGitサブモジュールも検索するようにします。これらは、Hugoテーマに使用されることがあります。
- `test`は、デプロイする前にHugoサイトでテストを実行できるジョブです。テストジョブは、デフォルトブランチへの変更をコミットする場合を除き、すべての場合に実行されます。`script`の下にコマンドを配置します。このジョブのコマンド-`hugo`-サイトをビルドしてテストできるようにします。
- `deploy-pages`は、静的サイトジェネレーターからページを作成するためにユーザーが定義したジョブです。繰り返しますが、このジョブは[ユーザー定義のジョブ名](../../user/project/pages/_index.md#user-defined-job-names)を使用し、`hugo`コマンドを実行してサイトをビルドします。次に、`pages: true`はこれがページジョブであることを指定し、`artifacts`はこれらの結果のページが`public`というディレクトリに追加されることを指定します。`rules`を使用すると、このコミットがデフォルトブランチで行われたことを確認できます。通常、別のブランチからライブサイトをビルドおよびデプロイすることはお勧めしません。

このファイルに他に何も追加する必要はありません。準備ができたら、ページの先頭にある**変更をコミットする**を選択します。

Hugoサイトをビルドするためのパイプラインをトリガーしたばかりです。

## GitLab Pagesを使用してHugoサイトをデプロイする {#deploy-your-hugo-site-with-gitlab-pages}

手際が良ければ、GitLabがサイトをビルドしてデプロイするのを確認できます。

左側のナビゲーションから、**ビルド** > **パイプライン**を選択します。

GitLabが`test`および`deploy-pages`ジョブを実行したことがわかります。

サイトを表示するには、パイプラインが完了したら、左側のナビゲーションで、**デプロイ** > **Pages**を選択して、ページWebサイトへのリンクを見つけます。

### Hugo設定オプションを追加する {#add-your-hugo-configuration-options}

最初にHugoサイトを表示すると、スタイルシートは機能しません。心配しないでください。Hugo設定ファイルで小さな変更を行う必要があります。Hugoは、スタイルシートやその他のアセットへの相対リンクをビルドできるように、GitLab PagesサイトのURLを知る必要があります:

1. ローカルのHugoサイトで、最新の変更をプルし、`config.yaml`または`config.toml`ファイルを開きます。
1. `BaseURL`パラメータの値を、GitLab Pages設定に表示されるURLと一致するように変更します。
1. 変更したファイルをGitLabにプッシュすると、パイプラインが再度トリガーされます。

### GitLab PagesのURLを見つける {#find-your-gitlab-pages-url}

パイプラインが完了したら、**デプロイ** > **Pages**に移動して、Pagesウェブサイトへのリンクを見つけます。

パイプラインの`pages`ジョブは、`public`ディレクトリのコンテンツをGitLab Pagesにデプロイしました。**ページへアクセス**の下に、`https://<your-namespace>.gitlab.io/<project-path>`形式でリンクが表示されます。

パイプラインをまだ実行していない場合、このリンクは表示されません。

表示されたリンクを選択して、サイトを表示します。Hugo設定で`BaseURL`設定を変更して、GitLabデプロイURLと一致させる必要があります。

### GitLab Pagesの表示レベルを設定する {#set-your-gitlab-pages-visibility}

Hugoサイトがプライベートリポジトリに保存されている場合は、ページサイトが表示されるようにアクセス許可を変更する必要があります。それ以外の場合は、プロジェクトメンバーのみに表示されます。サイトのアクセス許可を変更するには:

1. **設定** > **一般** > **可視性、プロジェクトの機能、権限**に移動します。
1. **Pages**セクションまでスクロールし、ドロップダウンリストから**全員**を選択します。
1. **変更を保存**を選択します。

これで、全員がURLでサイトを表示できます。

GitLabでHugoサイトをビルド、テスト、デプロイしました。素晴らしい出来栄えです。

サイトを変更してGitLabにプッシュするたびに、`.gitlab-ci.yml`ファイルのルールを使用して、サイトが自動的にビルド、テスト、デプロイされます。

CI/CDパイプラインの詳細については、[複雑なパイプラインを作成する方法に関するこのチュートリアル](../../ci/quick_start/tutorial.md)をお試しください。[利用可能なさまざまな種類のテスト](../../ci/testing/_index.md)の詳細についても学ぶことができます。

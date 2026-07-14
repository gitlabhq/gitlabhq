---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'チュートリアル: GitLabでHugoサイトをビルド、テスト、デプロイする'
---

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルでは、HugoサイトをCI/CDパイプラインでビルド、テスト、デプロイする手順を説明します。

チュートリアルの終わりまでに、動作するパイプラインとGitLab PagesにデプロイされたHugoサイトが完成します。

実施する作業の概要を次に示します:

1. Hugoサイトを準備する。
1. GitLabプロジェクトを作成する。
1. HugoサイトをGitLabにプッシュする。
1. CI/CDパイプラインでHugoサイトをビルドする。
1. GitLab PagesでHugoサイトをデプロイする。

## はじめる前 {#before-you-begin}

- GitLab.comのアカウント。
- Gitに関する知識。
- Hugoサイト（まだお持ちでない場合は、[Hugo Quick Start](https://gohugo.io/getting-started/quick-start/)の手順に従ってください）。

## Hugoサイトを準備する {#prepare-your-hugo-site}

まず、HugoサイトがGitLabにプッシュする準備ができていることを確認してください。コンテンツ、テーマ、Hugoの設定ファイルが必要です。

GitLabがビルドするため、サイトをビルドする必要はありません。実際、`public`フォルダーをアップロードしないことが重要です。後で競合が発生する可能性があります。

`public`フォルダーを除外する最も簡単な方法は、`.gitignore`ファイルを作成し、`public/`というテキストの新しい行を追加することです。

これを行うには、Hugoプロジェクトの最上位で次のコマンドを実行します:

```shell
echo "public/" >> .gitignore
```

これにより、`public/`が新しい`.gitignore`ファイルに追加されるか、既存のファイルに追記されます。

Hugoサイトは、GitLabプロジェクトを作成したら、プッシュする準備ができています。

## GitLabプロジェクトを作成する {#create-a-gitlab-project}

まだ作成していない場合は、Hugoサイト用の空のGitLabプロジェクトを作成してください。

GitLabで空のプロジェクトを作成するには:

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. プロジェクトの詳細を入力します。
   - **プロジェクト名**フィールドに、プロジェクトの名前を入力します。名前は、小文字または大文字（`a-zA-Z`）、数字（`0-9`）、絵文字、またはアンダースコア（`_`）で始まる必要があります。ドット（`.`）、プラス記号（`+`）、ダッシュ（`-`）、またはスペースも使用できます。
   - **プロジェクトslug**フィールドに、プロジェクトへのパスを入力します。GitLabインスタンスは、このslugをプロジェクトへのURLパスとして使用します。slugを変更するには、最初にプロジェクト名を入力し、次にslugを変更します。
   - **表示レベル**は非公開または公開のいずれかに設定できます。非公開を選択してもウェブサイトは公開されますが、コードは非公開のままになります。
   - 既存のリポジトリをプッシュするため、**リポジトリを初期化しREADMEファイルを生成する**のチェックボックスをオフにします。
1. 準備ができたら、**プロジェクトを作成**を選択します。
1. この新しいプロジェクトにコードをプッシュするための手順が表示されるはずです。次のステップでそれらの手順が必要になります。

これでHugoサイトの場所ができました！

## HugoサイトをGitLabにプッシュする {#push-your-hugo-site-to-gitlab}

次に、ローカルのHugoサイトをリモートのGitLabプロジェクトにプッシュする必要があります。

前のステップで新しいGitLabプロジェクトを作成した場合、リポジトリを初期化し、ファイルをコミットしてプッシュするための手順が表示されます。

それ以外の場合は、ローカルGitリポジトリのリモートoriginが、あなたのGitLabプロジェクトと一致していることを確認してください。

デフォルトブランチが`main`であると仮定して、次のコマンドでHugoサイトをプッシュすることができます:

```shell
git push origin main
```

サイトをプッシュした後、`public`フォルダーを除くすべてのコンテンツが表示されるはずです。`public`フォルダーは`.gitignore`ファイルによって除外されました。

次のステップでは、CI/CDパイプラインを使用してサイトをビルドし、その`public`フォルダーを再作成します。

## CI/CDパイプラインでHugoサイトをビルドする {#build-your-hugo-site-with-a-cicd-pipeline}

GitLabでHugoサイトをビルドするには、まずCI/CDパイプラインの指示を指定するための`.gitlab-ci.yml`ファイルを作成する必要があります。これを以前に行ったことがない場合は、大変に思えるかもしれません。ただし、GitLabが必要なすべてを提供します。

以下に示す`.gitlab-ci.yml`ファイルを使用するには、`hugo.toml`ファイルも一致するテーマパスを示していることを確認してください。以下の例の`hugo.toml`ファイルは、GitLab Pagesプロジェクトの`baseURL`設定も示しています。

```yaml
baseURL = 'https://<your-namespace>.gitlab.io/<project-path>'
languageCode = 'en-us'
title = 'Hugo on GitLab'
[module]
[[module.imports]]
  path = 'github.com/adityatelange/hugo-PaperMod'
```

### GitLabの設定オプションを追加する {#add-your-gitlab-configuration-options}

設定オプションは、`.gitlab-ci.yml`という特別なファイルで指定します。

Hugoテンプレートを使用して`.gitlab-ci.yml`ファイルを作成するには:

1. 左側のサイドバーで、**コード** > **リポジトリ**を選択します。
1. ファイルリストの上にあるプラスアイコン ( + ) を選択し、ドロップダウンリストから**新しいファイル**を選択します。
1. ファイル名には`.gitlab-ci.yml`と入力します。先頭のピリオドを省略しないでください。
1. **テンプレートを適用**ドロップダウンリストを選択し、フィルターボックスに「Hugo」と入力します。
1. 結果の**Hugo**を選択すると、CI/CDを使用してHugoサイトをビルドするために必要なすべてのコードでファイルが入力された状態になります。

この`.gitlab-ci.yml`ファイルで何が起こっているのか、詳しく見てみましょう。

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

- `image`は、Hugoを含むGitLabのレジストリからのイメージを指定します。このイメージは、サイトがビルドされる環境を作成するために使用されます。
- `GIT_SUBMODULE_STRATEGY`変数は、GitLabがGitサブモジュールも参照するようにします。これはHugoテーマで時々使用されます。
- `test`は、Hugoサイトがデプロイされる前にテストを実行できるジョブです。テストジョブは、デフォルトブランチへの変更をコミットする場合を除き、すべての場合に実行されます。コマンドは`script`の下に配置します。このジョブのコマンドである`hugo`は、サイトをビルドするため、テストすることができます。
- `create-pages`は、静的サイトジェネレーターからページを作成するためのユーザー定義ジョブです。このジョブは、[ユーザー定義ジョブ名](../../user/project/pages/_index.md#user-defined-job-names)を使用し、`hugo`コマンドを実行してサイトをビルドすることができます。次に、`pages: true`はこれがPagesジョブであることを指定し、`artifacts`は生成されたページが`public`というディレクトリに追加されることを指定します。`rules`を使用すると、このコミットがデフォルトブランチで行われたことを確認できます。通常、別のブランチからライブサイトをビルドしてデプロイすることは望ましくありません。

このファイルにこれ以上何も追加する必要はありません。準備ができたら、ページ上部の**変更をコミットする**を選択します。

Hugoサイトをビルドするパイプラインをトリガーすることができました！

## GitLab PagesでHugoサイトをデプロイする {#deploy-your-hugo-site-with-gitlab-pages}

すばやく確認すると、GitLabがサイトをビルドし、デプロイしているのを見ることができます。

左側のナビゲーションから、**ビルド** > **パイプライン**を選択します。

GitLabが`test`と`create-pages`のジョブを実行したことがわかります。

サイトを表示するには、パイプラインの完了後、左側のナビゲーションで**デプロイ** > **Pages**を選択し、Pagesウェブサイトへのリンクを見つけます。

### Hugoの設定オプションを追加する {#add-your-hugo-configuration-options}

初めてHugoサイトを表示したとき、スタイルシートが機能しません。心配しないでください。設定ファイルに小さな変更を加える必要があります。HugoがGitLab PagesサイトのURLを知ることで、スタイルシートやその他のアセットへの相対リンクをビルドすることができるようにする必要があります:

1. ローカルのHugoサイトで最新の変更をプルし、`config.yaml`または`config.toml`ファイルを開きます。
1. `BaseURL`パラメータの値を、GitLab Pagesの設定に表示されるURLと一致するように変更します。
1. 変更したファイルをGitLabにプッシュすると、パイプラインが再度トリガーされるます。

### GitLab PagesのURLを見つける {#find-your-gitlab-pages-url}

パイプラインが完了したら、**デプロイ** > **Pages**に移動してPagesウェブサイトへのリンクを確認できます。

パイプライン内の`pages`ジョブが、`public`ディレクトリのコンテンツをGitLab Pagesにデプロイしました。**ページへアクセス**の下に、`https://<your-namespace>.gitlab.io/<project-path>`という形式のリンクが表示されるはずです。

まだパイプラインを実行していない場合は、このリンクは表示されません。

表示されたリンクを選択してサイトを表示します。Hugoの設定で`BaseURL`設定をGitLabのデプロイURLと一致するように変更する必要があります。

### GitLab Pagesの表示レベルを設定する {#set-your-gitlab-pages-visibility}

Hugoサイトがプライベートリポジトリに保存されている場合、Pagesサイトが表示されるように権限を変更する必要があります。そうしないと、プロジェクトメンバーのみに表示されます。サイトの権限を変更するには:

1. **設定** > **一般** > **可視性、プロジェクトの機能、権限**に移動します。
1. **Pages**セクションまでスクロールし、ドロップダウンリストから**全員**を選択します。
1. **変更を保存**を選択します。

これで誰もがそのURLでサイトを見ることができます。

GitLabでHugoサイトをビルド、テスト、デプロイできました。素晴らしい作業でした！

サイトを変更してGitLabにプッシュするたびに、`.gitlab-ci.yml`ファイルのルールを使用して、サイトが自動的にビルド、テスト、デプロイされます。

CI/CDパイプラインの詳細については、[複雑なパイプラインを作成する方法に関するこのチュートリアル](../../ci/quick_start/tutorial.md)をお試しください。また、[利用可能なさまざまな種類のテスト](../../ci/testing/_index.md)についても詳しく学ぶことができます。

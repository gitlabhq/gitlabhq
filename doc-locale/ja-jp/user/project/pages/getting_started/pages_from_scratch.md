---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: GitLab Pagesウェブサイトをゼロから作成する'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このチュートリアルでは、[Jekyll](https://jekyllrb.com/)静的サイトジェネレーター（SSG）を使用して、Pagesサイトをゼロから作成する方法を説明します。空のプロジェクトから開始し、[Runner](https://docs.gitlab.com/runner/)に指示を与えるCI/CD設定ファイルを自分で作成します。CI/CD[パイプライン](../../../../ci/pipelines/_index.md)を実行すると、Pagesサイトが作成されます。

この例ではJekyllを使用していますが、他のSSGでも同様の手順を実行します。このチュートリアルを完了するために、JekyllまたはSSGに精通している必要はありません。

GitLab Pagesウェブサイトを作成するには:

- [ステップ1: プロジェクトファイルを作成する](#create-the-project-files)
- [ステップ2: Dockerイメージを選択する](#choose-a-docker-image)
- [ステップ3: Jekyllをインストールする](#install-jekyll)
- [ステップ4: 出力用の`public`ディレクトリを指定する](#specify-the-public-directory-for-output)
- [ステップ5: アーティファクト用の`public`ディレクトリを指定する](#specify-the-public-directory-for-artifacts)
- [ステップ6: ウェブサイトをデプロイして表示する](#deploy-and-view-your-website)

## 前提要件 {#prerequisites}

GitLabに[空のプロジェクト](../../_index.md#create-a-blank-project)が必要です。

## プロジェクトファイルを作成する {#create-the-project-files}

ルート（トップレベル）ディレクトリに次の3つのファイルを作成します:

- `.gitlab-ci.yml`: 実行するコマンドを含むYAMLファイル。今のところ、ファイルの内容は空白のままにしておきます。

- `index.html`: 次のような、必要なHTMLコンテンツを入力できる空でないHTMLファイル。たとえば、次のようなファイルです:

  ```html
  <html>
  <head>
    <title>Home</title>
  </head>
  <body>
    <h1>Hello World!</h1>
  </body>
  </html>
  ```

- [`Gemfile`](https://bundler.io/gemfile.html): Rubyプログラムの依存関係を記述するファイル。

  次の内容を入力します:

  ```ruby
  source "https://rubygems.org"

  gem "jekyll"
  ```

## Dockerイメージを選択する {#choose-a-docker-image}

この例では、Runnerは[Dockerイメージ](../../../../ci/docker/using_docker_images.md)を使用してスクリプトを実行し、サイトをデプロイします。

この特定のRubyイメージは、[DockerHub](https://hub.docker.com/_/ruby)で保持されます。

`.gitlab-ci.yml`ファイルの先頭に次のCI/CD設定を追加して、デフォルトのイメージをパイプラインに追加します:

```yaml
default:
  image: ruby:3.2
```

ビルドするためにSSGに[NodeJS](https://nodejs.org/)が必要な場合は、ファイルシステムの一部としてNodeJSを含むイメージを指定する必要があります。たとえば、[Hexo](https://gitlab.com/pages/hexo)サイトの場合は、`image: node:12.17.0`を使用できます。

## Jekyllをインストールする {#install-jekyll}

[Jekyll](https://jekyllrb.com/)をローカルで実行するには、インストールする必要があります:

1. ターミナルを開きます。
1. `gem install bundler`を実行して、[Bundler](https://bundler.io/)をインストールします。
1. `bundle install`を実行して、`Gemfile.lock`を作成します。
1. `bundle exec jekyll build`を実行して、Jekyllをインストールします。

プロジェクトでJekyllを実行するには、`.gitlab-ci.yml`ファイルを編集して、インストールコマンドを追加します:

```yaml
script:
  - gem install bundler
  - bundle install
  - bundle exec jekyll build
```

さらに、`.gitlab-ci.yml`ファイルでは、各`script`は`job`で整理されます。`job`には、特定のタスクに適用するスクリプトと設定が含まれています。

```yaml
job:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build
```

GitLab Pagesの場合、この`job`には、`pages`というプロパティを含める必要があります。この設定は、ジョブでGitLab Pagesを使用してウェブサイトをデプロイすることをRunnerに伝えます:

```yaml
create-pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build
  pages: true  # specifies that this is a Pages job
```

このページの例では、[ユーザー定義のジョブ名](../_index.md#user-defined-job-names)を使用します。

## 出力用の`public`ディレクトリを指定する {#specify-the-public-directory-for-output}

Jekyllは、どこに出力を生成するのかを知る必要があります。GitLab Pagesは、`public`というディレクトリ内のファイルのみを考慮します。

Jekyllは、宛先フラグ（`-d`）を使用して、ビルドされたウェブサイトの出力ディレクトリを指定します。`.gitlab-ci.yml`ファイルに宛先を追加します:

```yaml
create-pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job
```

## アーティファクト用の`public`ディレクトリを指定する {#specify-the-public-directory-for-artifacts}

{{< history >}}

- GitLab 17.10で、Pagesジョブのみを対象に、`artifacts:paths`への`pages.publish`パスの自動付加が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)されました。

{{< /history >}}

Jekyllがファイルを`public`ディレクトリに出力したので、Runnerはどこからファイルを取得するのかを知る必要があります。GitLab 17.10以降では、Pagesジョブの場合のみ、[`pages.publish`](../../../../ci/yaml/_index.md#pagespublish)パスが明示的に指定されていない場合、`public`ディレクトリが自動的に[`artifacts:paths`](../../../../ci/yaml/_index.md#artifactspaths)に付け加えられます:

```yaml
create-pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
```

`.gitlab-ci.yml`ファイルは次のようになるはずです:

```yaml
default:
  image: ruby:3.2

create-pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
```

## ウェブサイトをデプロイして表示する {#deploy-and-view-your-website}

上記の手順を完了したら、ウェブサイトをデプロイします:

1. `.gitlab-ci.yml`ファイルを保存してコミットします。
1. **ビルド** > **パイプライン**に移動して、パイプラインを監視します。
1. パイプラインが完了したら、**デプロイ** > **Pages**に移動して、Pages Webサイトへのリンクを見つけます。

この`pages`ジョブが正常に完了すると、特別な`pages:deploy`ジョブがパイプラインビューに表示されます。このジョブは、GitLab Pagesデーモン用のウェブサイトのコンテンツを準備します。GitLabはこのジョブをバックグラウンドで実行し、Runnerを使用しません。

## CI/CDファイルのその他のオプション {#other-options-for-your-cicd-file}

より高度なタスクを実行する場合は、`.gitlab-ci.yml`ファイルを[他のCI/CD YAMLキーワード](../../../../ci/yaml/_index.md)で更新できます。GitLabに用意されている[CI Lint](../../../../ci/yaml/lint.md)ツールを使用して、`.gitlab-ci.yml`ファイルを検証できます。

次のトピックでは、CI/CDファイルに追加できるその他のオプションの例を示します。

### 特定のブランチをPagesサイトにデプロイする {#deploy-specific-branches-to-a-pages-site}

特定のブランチからのみPagesサイトにデプロイすることをお勧めします。

まず、`workflow`セクションを追加して、変更がブランチにプッシュされた場合にのみパイプラインが実行されるようにします:

```yaml
default:
  image: ruby:3.2

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

create-pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
```

次に、[デフォルトブランチ](../../repository/branches/default.md)（ここでは`main`）に対してのみジョブを実行するようにパイプラインを設定します。

```yaml
default:
  image: ruby:3.2

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

create-pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### デプロイするステージを指定する {#specify-a-stage-to-deploy}

GitLab CI/CDには、Build、Test、Deployの3つのデフォルトステージがあります。

スクリプトをテストし、本番環境にデプロイする前にビルドされたサイトを確認する場合は、[デフォルトブランチ](../../repository/branches/default.md)（ここでは`main`）にプッシュするときのテストとまったく同じようにテストを実行できます。

ジョブを実行するステージを指定するには、`stage`行をCIファイルに追加します:

```yaml
default:
  image: ruby:3.2

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

create-pages:
  stage: deploy
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: production
```

次に、CIファイルに別のジョブを追加して、`main`ブランチを**except**（除く）すべてのブランチへのすべてのプッシュをテストするように指示します:

```yaml
default:
  image: ruby:3.2

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

create-pages:
  stage: deploy
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: production

test:
  stage: test
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d test
  artifacts:
    paths:
      - test
  rules:
    - if: $CI_COMMIT_BRANCH != "main"
```

`test`ステージで`test`ジョブが実行されると、Jekyllは`test`というディレクトリにサイトをビルドします。ジョブは、`main`を除くすべてのブランチに影響します。

ステージを複数のジョブに適用すると、同じステージに含まれるすべてのジョブが並列でビルドします。Webアプリケーションをデプロイする前に複数のテストが必要な場合は、すべてのテストを同時に実行できます。

### 重複するコマンドを削除する {#remove-duplicate-commands}

すべてのジョブで同じ`before_script`コマンドを複製しないようにするために、そのコマンドをデフォルトセクションに追加できます。

この例では、`gem install bundler`と`bundle install`は、`pages`と`test`の両方のジョブで実行されていました。

これらのコマンドを`default`セクションに移動します:

```yaml
default:
  image: ruby:3.2
  before_script:
    - gem install bundler
    - bundle install

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

create-pages:
  stage: deploy
  script:
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: production

test:
  stage: test
  script:
    - bundle exec jekyll build -d test
  artifacts:
    paths:
      - test
  rules:
    - if: $CI_COMMIT_BRANCH != "main"
```

### キャッシュされた依存関係を使用してより高速にビルドする {#build-faster-with-cached-dependencies}

より高速にビルドするには、`cache`パラメータを使用して、プロジェクトの依存関係のインストールファイルをキャッシュできます。

この例では、`bundle install`を実行すると、Jekyllの依存関係が`vendor`ディレクトリにキャッシュされます:

```yaml
default:
  image: ruby:3.2
  before_script:
    - gem install bundler
    - bundle install --path vendor
  cache:
    paths:
      - vendor/

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH


create-pages:
  stage: deploy
  script:
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: production

test:
  stage: test
  script:
    - bundle exec jekyll build -d test
  artifacts:
    paths:
      - test
  rules:
    - if: $CI_COMMIT_BRANCH != "main"
```

この場合、Jekyllがビルドするフォルダーのリストから`/vendor`ディレクトリを除外する必要があります。そうしないと、Jekyllはディレクトリの内容をサイトとともにビルドしようとします。

ルートディレクトリに、`_config.yml`というファイルを作成し、次の内容を追加します:

```yaml
exclude:
  - vendor
```

これで、GitLab CI/CDはウェブサイトをビルドするだけでなく、次のことも行います:

- **continuous tests**（継続的テスト）でフィーチャーブランチにプッシュします。
- Bundlerでインストールされた依存関係を**Caches**（キャッシュ）します。
- `main`ブランチへのすべてのプッシュを**Continuously deploys**（継続的にデプロイ）します。

サイト用に作成されたHTMLおよびその他の資産を表示するには、[ジョブアーティファクトをダウンロード](../../../../ci/jobs/job_artifacts.md#download-job-artifacts)します。

このページの例では、[ユーザー定義のジョブ名](../_index.md#user-defined-job-names)を使用します。

## 関連トピック {#related-topics}

- [ウェブアプリをステージングと本番環境にデプロイする](https://about.gitlab.com/blog/2021/02/05/ci-deployment-and-environments/)
- [ジョブを順番に実行する、ジョブを並列実行する、またはカスタムパイプラインをビルドする](https://about.gitlab.com/blog/2020/12/10/basics-of-gitlab-ci-updated/)
- [異なるプロジェクトから特定のディレクトリをプルする](https://about.gitlab.com/blog/2016/12/07/building-a-new-gitlab-docs-site-with-nanoc-gitlab-ci-and-gitlab-pages/)
- [GitLab Pagesを使用してコードカバレッジレポートを作成する](https://about.gitlab.com/blog/2016/11/03/publish-code-coverage-report-with-gitlab-pages/)

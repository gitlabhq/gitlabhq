---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dplをデプロイツールとして使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Dpl](https://github.com/travis-ci/dpl)（D-P-Lのように発音）は、継続的デプロイのために作成されたデプロイツールであり、Travis CIによって開発および使用されていますが、GitLab CI/CDでも使用できます。

Dplは、[サポートされているプロバイダー](https://github.com/travis-ci/dpl#supported-providers)のいずれかにデプロイするために使用できます。

## 前提条件 {#prerequisite}

Dplを使用するには、gemをインストールする機能とともに、少なくともRuby 1.9.3が必要です。

## 基本的な使い方 {#basic-usage}

Dplは、次の機能を備えた任意のマシンにインストールできます:

```shell
gem install dpl
```

これにより、CIサーバーでテストするのではなく、ローカルターミナルからすべてのコマンドをテストできます。

Rubyがインストールされていない場合は、Debian互換のLinuxで次のように実行できます:

```shell
apt-get update
apt-get install ruby-dev
```

Dplは、次のような多数のサービスをサポートしています: Heroku、Cloud Foundry、/S3など。これを使用するには、プロバイダーと、プロバイダーに必要な追加のパラメータを定義します。

たとえば、アプリケーションをHerokuにデプロイするために使用する場合は、プロバイダーとして`heroku`を指定し、`api_key`と`app`を指定する必要があります。考えられるすべてのパラメータは、[Heroku APIセクション](https://github.com/travis-ci/dpl#heroku-api)にあります。

```yaml
staging:
  stage: deploy
  script:
    - gem install dpl
    - dpl heroku api --app=my-app-staging --api_key=$HEROKU_STAGING_API_KEY
  environment: staging
```

前の例では、`my-app-staging`をセキュアな変数である`HEROKU_STAGING_API_KEY`に格納されているAPIキーを使用してHerokuサーバーにデプロイするためにDplを使用します。

別のプロバイダーを使用するには、[サポートされているプロバイダー](https://github.com/travis-ci/dpl#supported-providers)の長いリストをご覧ください。

## DockerでのDplの使用 {#using-dpl-with-docker}

ほとんどの場合、サーバーのシェルコマンドを使用するように[GitLab Runner](https://docs.gitlab.com/runner/)を設定しました。つまり、すべてのコマンドはローカルユーザー（たとえば、`gitlab_runner`または`gitlab_ci_multi_runner`）のコンテキストで実行されます。また、ほとんどの場合、DockerコンテナにRubyランタイムがインストールされていないことを意味します。インストールする必要があります:

```yaml
staging:
  stage: deploy
  script:
    - apt-get update -yq
    - apt-get install -y ruby-dev
    - gem install dpl
    - dpl heroku api --app=my-app-staging --api_key=$HEROKU_STAGING_API_KEY
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: staging
```

最初の行`apt-get update -yq`は使用可能なパッケージのリストを更新し、2番目の`apt-get install -y ruby-dev`はシステムのRubyランタイムをインストールします。前の例は、すべてのDebian互換システムで有効です。

## ステージング環境と本番環境での使用 {#usage-in-staging-and-production}

ステージング環境（開発）と本番環境を持つことは、開発ワークフローでは非常に一般的です

次の例を考えてみましょう。`main`ブランチを`staging`に、すべてのタグ付けを`production`環境にデプロイするとします。その設定の最終的な`.gitlab-ci.yml`は次のようになります:

```yaml
staging:
  stage: deploy
  script:
    - gem install dpl
    - dpl heroku api --app=my-app-staging --api_key=$HEROKU_STAGING_API_KEY
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: staging

production:
  stage: deploy
  script:
    - gem install dpl
    - dpl heroku api --app=my-app-production --api_key=$HEROKU_PRODUCTION_API_KEY
  rules:
    - if: $CI_COMMIT_TAG
  environment: production
```

異なるイベントで実行される2つのデプロイジョブを作成しました:

- `staging`: `main`ブランチにプッシュされたすべてのコミットに対して実行されます
- `production`: プッシュされたすべてのタグに対して実行

2つのセキュアな変数も使用します:

- `HEROKU_STAGING_API_KEY`: ステージングアプリをデプロイするために使用されるHeroku APIキー
- `HEROKU_PRODUCTION_API_KEY`: 本番環境アプリをデプロイするために使用されるHeroku APIキー

## APIキーの保存 {#storing-api-keys}

APIキーをセキュアな変数として保存するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。

プロジェクト設定で定義された変数は、ビルドスクリプトとともにRunnerに送信されます。セキュアな変数は、リポジトリの外部に保存されます。プロジェクトの`.gitlab-ci.yml`ファイルにシークレットを保存しないでください。シークレットの値がジョブログに表示されないようにすることも重要です。

`$`（非Windows Runnerの場合）または`%`（Windows Batch Runnerの場合）を使用して、追加された変数にプレフィックスを付けてアクセスします:

- `$VARIABLE`: 非Windows Runner用
- `%VARIABLE%`: Windows Batch Runner用

[CI/CD変数](../../variables/_index.md)の詳細をご覧ください。

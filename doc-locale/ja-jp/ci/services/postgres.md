---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: PostgreSQLを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

多くのアプリケーションがデータベースとしてPostgreSQLに依存しているため、それを使用してテストを実行する必要があります。

## Docker executorでPostgreSQLを使用する {#use-postgresql-with-the-docker-executor}

GitLab.com UIで設定された変数をサービスコンテナに渡すには、[変数](../variables/_index.md#define-a-cicd-variable-in-the-ui)を定義する必要があります。変数はグループまたはプロジェクトとして定義し、次の回避策に示すようにジョブで変数を呼び出す必要があります。

Postgres 15.4以降のバージョンでは、引用符(")、バックスラッシュ()、またはドル記号($)が含まれている場合、拡張スクリプトにスキーマまたはオーナー名は代入されません。CI/CD変数が設定されていない場合、値は環境変数名を文字列として代わりに使用します。たとえば、`POSTGRES_USER: $USER`とすると、`POSTGRES_USER`変数が「$USER」に設定され、Postgresに次のエラーが表示されます。

```shell
Fatal: invalid character in extension
```

回避策は、[GitLab CI/CD変数](../variables/_index.md)で変数を設定するか、文字列形式で変数を設定することです。

1. [GitLabでPostgres変数を設定します](../variables/_index.md#for-a-project)。GitLab.com UIで設定された変数は、サービスコンテナに渡されません。

1. `.gitlab-ci.yml`ファイルで、Postgresイメージを指定します。

   ```yaml
   default:
      services:
        - postgres
   ```

1. `.gitlab-ci.yml`ファイルで、定義した変数を追加します。

   ```yaml
   variables:
     POSTGRES_DB: $POSTGRES_DB
     POSTGRES_USER: $POSTGRES_USER
     POSTGRES_PASSWORD: $POSTGRES_PASSWORD
     POSTGRES_HOST_AUTH_METHOD: trust
   ```

   `postgres`を`Host`に使用する方法の詳細については、[サービスがジョブにどのようにリンクされているか](_index.md#how-services-are-linked-to-the-job)を参照してください。

1. データベースを使用するようにアプリケーションを設定します（例）。

   ```yaml
   Host: postgres
   User: $POSTGRES_USER
   Password: $POSTGRES_PASSWORD
   Database: $POSTGRES_DB
   ```

または、`.gitlab-ci.yml`ファイルに文字列として変数を設定することもできます。

```yaml
variables:
  POSTGRES_DB: DB_name
  POSTGRES_USER: username
  POSTGRES_PASSWORD: password
  POSTGRES_HOST_AUTH_METHOD: trust
```

[Docker Hub](https://hub.docker.com/_/postgres)で利用可能な他のDockerイメージを使用できます。たとえば、PostgreSQL 16.10を使用するには、サービスを`postgres:16.10`にします。

`postgres`イメージは、いくつかの環境変数を受け入れることができます。詳細については、[Docker Hub](https://hub.docker.com/_/postgres)のドキュメントを参照してください。

## Shell executorでPostgreSQLを使用する {#use-postgresql-with-the-shell-executor}

Shell executorでGitLab CI/CD Runnerを使用している手動で設定されたサーバーでPostgreSQLを使用することもできます。

まず、PostgreSQLサーバーをインストールします。

```shell
sudo apt-get install -y postgresql postgresql-client libpq-dev
```

次のステップはユーザーを作成することなので、PostgreSQLにサインインします。

```shell
sudo -u postgres psql -d template1
```

次に、アプリケーションで使用されるユーザー（この場合は`runner`）を作成します。次のコマンドの`$password`を強力なパスワードに変更します。

{{< alert type="note" >}}

PostgreSQLプロンプトの一部であるため、次のコマンドに`template1=#`を入力しないようにしてください。

{{< /alert >}}

```shell
template1=# CREATE USER runner WITH PASSWORD '$password' CREATEDB;
```

作成されたユーザーには、データベースを作成する権限（`CREATEDB`）があります。次の手順では、そのユーザーに対してデータベースを明示的に作成する方法について説明します。権限により、テストフレームワークは必要に応じてデータベースを作成および削除できます。

データベースを作成し、ユーザー`runner`にすべての権限を付与します。

```shell
template1=# CREATE DATABASE nice_marmot OWNER runner;
```

すべてうまくいった場合は、データベースセッションを終了できます。

```shell
template1=# \q
```

次に、すべてが整っていることを確認するために、ユーザー`runner`を使用して、新しく作成されたデータベースに接続してみます。

```shell
psql -U runner -h localhost -d nice_marmot -W
```

このコマンドは、md5認証を使用するためにlocalhostに接続するように`psql`に明示的に指示します。このステップを省略すると、アクセスが拒否されます。

最後に、データベースを使用するようにアプリケーションを設定します（例）。

```yaml
Host: localhost
User: runner
Password: $password
Database: nice_marmot
```

## プロジェクトの例 {#example-project}

パブリックに利用可能な[インスタンスRunners](../runners/_index.md)を使用して、[GitLab.com](https://gitlab.com)で実行される便利な[PostgreSQLプロジェクトの例](https://gitlab.com/gitlab-examples/postgres)を設定しました。

ハックしませんか？フォークし、コミットし、変更をプッシュします。しばらくすると、パブリックRunnerによって変更が選択され、ジョブが開始されます。

---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: MySQLを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

多くのアプリケーションはデータベースとしてMySQLに依存しており、テストを実行するためにそれが必要になる場合があります。

## Docker executorでMySQLを使用する {#use-mysql-with-the-docker-executor}

MySQLコンテナを使用する場合、[GitLab Runner](../runners/_index.md)をDocker executorで使用できます。

この例では、GitLabがMySQLコンテナへのアクセスに使用するユーザー名とパスワードを設定する方法を示します。ユーザー名とパスワードを設定しない場合は、`root`を使用する必要があります。

{{< alert type="note" >}}

GitLab UIで設定された変数は、サービスコンテナに渡されません。詳細については、[GitLab CI/CD変数](../variables/_index.md)を参照してください。

{{< /alert >}}

1. MySQLイメージを指定するには、`.gitlab-ci.yml`ファイルに以下を追加します:

   ```yaml
   services:
     - mysql:latest
   ```

   - [Docker Hub](https://hub.docker.com/_/mysql/)で利用可能なDockerイメージを使用できます。たとえば、MySQL 5.5を使用するには、`mysql:5.5`を使用します。
   - `mysql`イメージは、環境変数を受け入れることができます。詳細については、[Docker Hubドキュメント](https://hub.docker.com/_/mysql/)を参照してください。

1. データベース名とパスワードを含めるには、`.gitlab-ci.yml`ファイルに以下を追加します:

   ```yaml
   variables:
     # Configure mysql environment variables (https://hub.docker.com/_/mysql/)
     MYSQL_DATABASE: $MYSQL_DB
     MYSQL_ROOT_PASSWORD: $MYSQL_PASS
   ```

   MySQLコンテナは、データベースに接続するために`MYSQL_DATABASE`と`MYSQL_ROOT_PASSWORD`を使用します。これらの値は、[GitLab CI/CD変数](../variables/_index.md)（上記の例では`$MYSQL_DB`および`$MYSQL_PASS`）を使用して渡し、[直接呼び出すのではなく](https://gitlab.com/gitlab-org/gitlab/-/issues/30178)渡します。

1. データベースを使用するようにアプリケーションを設定します（例）:

   ```yaml
   Host: mysql
   User: runner
   Password: <your_mysql_password>
   Database: <your_mysql_database>
   ```

   この例では、ユーザーは`runner`です。データベースにアクセスする権限を持つユーザーを使用する必要があります。

## Shell executorでMySQLを使用する {#use-mysql-with-the-shell-executor}

Shell executorでGitLab Runnerを使用する手動構成されたサーバーでMySQLを使用することもできます。

1. MySQLサーバーをインストールします:

   ```shell
   sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev
   ```

1. MySQLのrootパスワードを選択し、求められたら2回入力します。

   {{< alert type="note" >}}

   セキュリティ対策として、`mysql_secure_installation`を実行して、匿名ユーザーの削除、テストデータベースの削除、およびrootユーザーによるリモートログインの無効化を行うことができます。

   {{< /alert >}}

1. rootとしてMySQLにログインして、ユーザーを作成します:

   ```shell
   mysql -u root -p
   ```

1. アプリケーションで使用されるユーザー（この場合は`runner`）を作成します。コマンドの`$password`を強力なパスワードに変更します。

   `mysql>`プロンプトで、次のように入力します:

   ```sql
   CREATE USER 'runner'@'localhost' IDENTIFIED BY '$password';
   ```

1. データベースを作成します:

   ```sql
   CREATE DATABASE IF NOT EXISTS `<your_mysql_database>` DEFAULT CHARACTER SET `utf8` \
   COLLATE `utf8_unicode_ci`;
   ```

1. データベースに必要な権限を付与します:

   ```sql
   GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER, LOCK TABLES ON `<your_mysql_database>`.* TO 'runner'@'localhost';
   ```

1. すべてがうまくいった場合は、データベースセッションを終了できます:

   ```shell
   \q
   ```

1. 新しく作成されたデータベースに接続して、すべてが整っていることを確認します:

   ```shell
   mysql -u runner -p -D <your_mysql_database>
   ```

1. データベースを使用するようにアプリケーションを設定します（例）:

   ```shell
   Host: localhost
   User: runner
   Password: $password
   Database: <your_mysql_database>
   ```

## プロジェクト例 {#example-project}

MySQLの例を表示するには、この[サンプルプロジェクト](https://gitlab.com/gitlab-examples/mysql)をフォークしてください。このプロジェクトでは、[インスタンスRunner](../runners/_index.md)を[GitLab.com](https://gitlab.com)で使用します。README.mdファイルを更新し、変更をコミットして、CI/CDパイプラインを表示して、動作を確認します。

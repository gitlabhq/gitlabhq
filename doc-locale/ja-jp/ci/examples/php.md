---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: PHPプロジェクトのテスト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このガイドでは、PHPプロジェクトの基本的なビルド手順について説明します。

ここでは、Docker executorとShell executorを使用する2つのテストシナリオについて説明します。

## Docker executorを使用してPHPプロジェクトをテストする {#test-php-projects-using-the-docker-executor}

PHPアプリケーションはどのシステムでもテストできますが、デベロッパーによる手動設定が必要です。これを克服するために、Docker Hubにある公式の[PHP Dockerイメージ](https://hub.docker.com/_/php)を使用します。

これにより、さまざまなバージョンのPHPに対してPHPプロジェクトをテストできます。ただし、すべてがプラグアンドプレイできるわけではなく、一部を手動で設定する必要があります。

すべてのジョブと同様に、ビルド環境を記述する有効な`.gitlab-ci.yml`を作成する必要があります。

まず、ジョブプロセスに使用されるPHPイメージを指定しましょう。（イメージの意味の詳細については、Runnerの専門用語を読んで、[Dockerイメージの使用](../docker/using_docker_images.md#what-is-an-image)を参照してください）。

まず、イメージを`.gitlab-ci.yml`に追加します:

```yaml
image: php:5.6
```

公式イメージは優れていますが、テストに役立つツールがいくつかありません。まず、ビルド環境を準備する必要があります。これを克服する方法は、実際のテストが完了する前に、すべての前提条件をインストールするスクリプトを作成することです。

次のコンテンツを含む`ci/docker_install.sh`ファイルをリポジトリのルートディレクトリに作成しましょう:

```shell
#!/bin/bash

# We need to install dependencies only for Docker
[[ ! -e /.dockerenv ]] && exit 0

set -xe

# Install git (the php image doesn't have it) which is required by composer
apt-get update -yqq
apt-get install git -yqq

# Install phpunit, the tool that we will use for testing
curl --location --output /usr/local/bin/phpunit "https://phar.phpunit.de/phpunit.phar"
chmod +x /usr/local/bin/phpunit

# Install mysql driver
# Here you can install any other extension that you need
docker-php-ext-install pdo_mysql
```

`docker-php-ext-install`とは何か疑問に思うかもしれません。簡単に言うと、これは拡張機能を簡単にインストールするために使用できる、公式のPHP Dockerイメージによって提供されるスクリプトです。詳細については、[ドキュメント](https://hub.docker.com/_/php)を参照してください。

ビルド環境に必要なすべての前提条件を含むスクリプトを作成したので、`.gitlab-ci.yml`に追加しましょう:

```yaml
before_script:
  - bash ci/docker_install.sh > /dev/null
```

最後の手順として、`phpunit`を使用して実際のテストを実行します:

```yaml
test:app:
  script:
    - phpunit --configuration phpunit_myapp.xml
```

最後に、ファイルをコミットしてプッシュし、GitLabにプッシュして、ビルドが成功（または失敗）することを確認します。

最終的な`.gitlab-ci.yml`は次のようになります:

```yaml
default:
  # Select image from https://hub.docker.com/_/php
  image: php:5.6
  before_script:
    # Install dependencies
    - bash ci/docker_install.sh > /dev/null

test:app:
  script:
    - phpunit --configuration phpunit_myapp.xml
```

### Dockerビルドで異なるPHPバージョンに対してテストする {#test-against-different-php-versions-in-docker-builds}

複数のバージョンのPHPに対してテストするのは非常に簡単です。別のDockerイメージバージョンで別のジョブを追加するだけで、Runnerが残りの処理を行います:

```yaml
default:
  before_script:
    # Install dependencies
    - bash ci/docker_install.sh > /dev/null

# We test PHP5.6
test:5.6:
  image: php:5.6
  script:
    - phpunit --configuration phpunit_myapp.xml

# We test PHP7.0 (good luck with that)
test:7.0:
  image: php:7.0
  script:
    - phpunit --configuration phpunit_myapp.xml
```

### DockerビルドでのカスタムPHP設定 {#custom-php-configuration-in-docker-builds}

`.ini`ファイルを`/usr/local/etc/php/conf.d/`に入れてPHP環境をカスタマイズする必要がある場合があります。そのために、`before_script`アクションを追加します:

```yaml
before_script:
  - cp my_php.ini /usr/local/etc/php/conf.d/test.ini
```

もちろん、`my_php.ini`はリポジトリのルートディレクトリに存在する必要があります。

## Shell executorを使用してPHPプロジェクトをテストする {#test-php-projects-using-the-shell-executor}

Shell executorは、サーバー上のターミナルセッションでジョブを実行します。プロジェクトをテストするには、まず、すべての依存関係がインストールされていることを確認する必要があります。

たとえば、Debian 8を実行しているVMでは、最初にキャッシュを更新してから、`phpunit`と`php5-mysql`をインストールします:

```shell
sudo apt-get update -y
sudo apt-get install -y phpunit php5-mysql
```

次に、次のスニペットを`.gitlab-ci.yml`に追加します:

```yaml
test:app:
  script:
    - phpunit --configuration phpunit_myapp.xml
```

最後に、GitLabにプッシュして、テストを開始しましょう。

### Shellビルドで異なるPHPバージョンに対してテストする {#test-against-different-php-versions-in-shell-builds}

[phpenv](https://github.com/phpenv/phpenv)プロジェクトを使用すると、独自の設定を持つPHPのさまざまなバージョンを管理できます。これは、Shell executorでPHPプロジェクトをテストする場合に特に役立ちます。

[アップストリームのインストールガイド](https://github.com/phpenv/phpenv#installation)に従って、`gitlab-runner`ユーザーでビルドマシンにインストールする必要があります。

phpenvを使用すると、PHP環境を次のように設定することもできます:

```shell
phpenv config-add my_config.ini
```

**Important note**（重要な注意）: `phpenv/phpenv`は[廃止された](https://github.com/phpenv/phpenv/issues/57)ようです。プロジェクトを復活させようとしている[`madumlao/phpenv`](https://github.com/madumlao/phpenv)にフォークがあります。[`CHH/phpenv`](https://github.com/CHH/phpenv)も優れた代替手段のようです。言及されているツールのいずれかを選択すると、基本的なphpenvコマンドで動作します。適切なphpenvを選択するためのガイダンスは、このチュートリアルのスコープ外です。*

### カスタム拡張機能をインストールする {#install-custom-extensions}

これはPHP環境のかなりむき出しのインストールであるため、ビルドマシンに現在存在しない拡張機能が必要になる場合があります。

追加の拡張機能をインストールするには、次を実行します:

```shell
pecl install <extension>
```

これを`.gitlab-ci.yml`に追加することはお勧めしません。このコマンドは、ビルド環境をセットアップするためだけに、1回実行する必要があります。

## テストを拡張する {#extend-your-tests}

### `atoum`を使用する {#using-atoum}

PHPUnitの代わりに、他のツールを使用して単体テストを実行できます。たとえば、[`atoum`](https://github.com/atoum/atoum)を使用できます:

```yaml
test:atoum:
  before_script:
    - wget http://downloads.atoum.org/nightly/mageekguy.atoum.phar
  script:
    - php mageekguy.atoum.phar
```

### Composerの使用 {#using-composer}

ほとんどのPHPプロジェクトは、Composerを使用してPHPパッケージを管理しています。テストを実行する前にComposerを実行するには、次を`.gitlab-ci.yml`に追加します:

```yaml
# Composer stores all downloaded packages in the vendor/ directory.
# Do not use the following if the vendor/ directory is committed to
# your git repository.
default:
  cache:
    paths:
      - vendor/
  before_script:
    # Install composer dependencies
    - wget https://composer.github.io/installer.sig -O - -q | tr -d '\n' > installer.sig
    - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    - php -r "if (hash_file('SHA384', 'composer-setup.php') === file_get_contents('installer.sig')) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    - php composer-setup.php
    - php -r "unlink('composer-setup.php'); unlink('installer.sig');"
    - php composer.phar install
```

## プライベートパッケージまたは依存関係へのアクセス {#access-private-packages-or-dependencies}

テストスイートがプライベートリポジトリにアクセスする必要がある場合は、クローンを作成できるように[SSHキー](../jobs/ssh_keys.md)を設定する必要があります。

## データベースまたはその他のサービスを使用する {#use-databases-or-other-services}

ほとんどの場合、テストを実行できるようにするには、実行中のデータベースが必要です。Docker executorを使用している場合は、Dockerを活用して他のコンテナにリンクできます。GitLab Runnerを使用すると、`service`を定義することでこれを実現できます。

この機能は、[CIサービス](../services/_index.md)ドキュメントで説明されています。

## プロジェクト例 {#example-project}

便宜上、公開されている[インスタンスRunner](../runners/_index.md)を使用して[GitLab.com](https://gitlab.com)で実行される[PHPプロジェクトの例](https://gitlab.com/gitlab-examples/php)を設定しました。

ハッキングしてみませんか？フォークし、コミットして、変更をプッシュします。数分以内に、変更がパブリックRunnerによって選択され、ジョブが開始されます。

---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 自己コンパイルによるインストール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

これは、ソースファイルを使用して本番環境のGitLabサーバーをセットアップするための公式インストールガイドです。**Debian/Ubuntu**オペレーティングシステム用に作成され、テストされています。ハードウェアとオペレーティングシステムの要件については、[requirements.md](../requirements.md)をお読みください。RHEL/CentOSにインストールする場合は、[Linuxパッケージ](https://about.gitlab.com/install/)を使用する必要があります。その他の多くのインストールオプションについては、[インストールのメインページ](_index.md)を参照してください。

このガイドは、多くのケースを網羅し、必要なすべてのコマンドが含まれているため、長くなっています。次の手順は動作することが確認されています。このガイドから**逸脱する場合は注意してください**。その環境についてGitLabが前提としている点を破らないようにしてください。たとえば、ディレクトリの場所を変更したり、間違ったユーザーとしてサービスを実行したりすると、多くのユーザーが権限の問題に遭遇します。

このガイドにバグ/エラーを見つけた場合は、[コントリビュートガイド](https://gitlab.com/gitlab-org/gitlab/-/blob/master/CONTRIBUTING.md)に従って、**マージリクエスト**を送信してください。

## Linuxパッケージインストールを検討する {#consider-the-linux-package-installation}

自己コンパイルによるインストールでは多くの作業とエラーが発生しやすいため、高速で信頼性の高い[Linuxパッケージインストール](https://about.gitlab.com/install/)（deb/rpm）を使用することを強くおすすめします。

Linuxパッケージが信頼性の高い理由の1つは、いずれかのクラッシュが発生した場合にGitLabプロセスを再起動するためにrunitを使用することです。頻繁に使用されるGitLabインスタンスでは、Sidekiqバックグラウンドワーカーのメモリ使用量が増加します。Linuxパッケージでは、メモリを使いすぎると[Sidekiqを正常に終了させる](../../administration/sidekiq/sidekiq_memory_killer.md)ことでこれを解決します。終了すると、runitはSidekiqが実行されていないことを検出し、それを開始します。自己コンパイルによるインストールでは、プロセス監視にrunitを使用しないため、Sidekiqを終了できず、メモリ使用量が増加する可能性があります。

## インストールするバージョンを選択する {#select-a-version-to-install}

インストールするGitLabのブランチ（バージョン、たとえば`16-0-stable`）から[このインストールガイド](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/install/self_compiled/_index.md)を表示していることを確認してください。GitLabの左上隅（メニューバーの下）にあるバージョンドロップダウンリストでブランチを選択できます。

最新の安定したブランチが不明な場合は、バージョン別のインストールガイドリンクについて[GitLabブログ](https://about.gitlab.com/blog/)を確認してください。

## ソフトウェア要件 {#software-requirements}

| ソフトウェア                | 最小バージョン | 注                                                                                                                                                                                                                                                                                  |
|:------------------------|:----------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Ruby](#2-ruby)         | `3.2.x`         | GitLab 16.7から17.4までは、Ruby 3.1が必要です。GitLab 17.5以降では、Ruby 3.2が必要です。Rubyの標準MRI実装を使用する必要があります。[JRuby](https://www.jruby.org/)と[Rubinius](https://github.com/rubinius/rubinius#the-rubinius-language-platform)が好まれますが、GitLabにはネイティブ拡張機能を持ついくつかのgemが必要です。 |
| [RubyGems](#3-rubygems) | `3.5.x`         | 特定のRubyGemsバージョンは必須ではありませんが、既知のパフォーマンス改善のベネフィット得るためにアップデートしてください。 |
| [Go](#4-go)             | `1.22.x`        | GitLab 17.1以降では、Go 1.22以降が必要です。                                                                                                                                                                                                                                        |
| [Git](#git)             | `2.47.x`        | GitLab 17.7以降では、Git 2.47.x以降が必要です。[Gitalyから提供されるGitバージョン](#git)を使用する必要があります。                                                                                                                                                   |
| [Node.js](#5-node)      | `20.13.x`       | GitLab 17.0以降では、Node.js 20.13以降が必要です。                                                                                                                                                                                                                                  |
| [PostgreSQL](#7-database) | `16.x`          | GitLab 18.0以降では、PostgreSQL 16以降が必要です。                                                                                                                                                                                                                                  |

## GitLabディレクトリ構造 {#gitlab-directory-structure}

インストール手順を実行すると、次のディレクトリが作成されます:

```plaintext
|-- home
|   |-- git
|       |-- .ssh
|       |-- gitlab
|       |-- gitlab-shell
|       |-- repositories
```

- `/home/git/.ssh` - OpenSSH設定が含まれています。具体的には、GitLab Shellによって管理される`authorized_keys`ファイルです。
- `/home/git/gitlab` - GitLabコアソフトウェア。
- `/home/git/gitlab-shell` - GitLabのコアアドオンコンポーネント。SSHクローンやその他の機能を維持します。
- `/home/git/repositories` - ネームスペースで整理されたすべてのプロジェクトのベアリポジトリ。このディレクトリは、プッシュ/プルされるGitリポジトリがすべてのプロジェクトで維持される場所です。**この領域には、プロジェクトの重要なデータが含まれています。[バックアップを保持します](../../administration/backup_restore/_index.md)**。

リポジトリのデフォルトの場所は、GitLabの`config/gitlab.yml`とGitLab Shellの`config.yml`で構成できます。

これらのディレクトリを手動で作成する必要はありません。作成すると、インストールの後半でエラーが発生する可能性があります。

## インストールのワークフロー {#installation-workflow}

GitLabのインストールは、次のコンポーネントの設定で構成されています:

1. [パッケージと依存関係](#1-packages-and-dependencies)。
1. [Ruby](#2-ruby)。
1. [RubyGems](#3-rubygems)。
1. [Go](#4-go)。
1. [ノード](#5-node)。
1. [システムユーザー](#6-system-users)。
1. [データベース](#7-database)。
1. [Redis](#8-redis)。
1. [GitLab](#9-gitlab)。
1. [NGINX](#10-nginx)。

## 1\.パッケージと依存関係 {#1-packages-and-dependencies}

### sudo {#sudo}

`sudo`は、デフォルトではDebianにインストールされていません。システムが最新であることを確認し、インストールします。

```shell
# run as root!
apt-get update -y
apt-get upgrade -y
apt-get install sudo -y
```

### ビルドの依存関係 {#build-dependencies}

必要なパッケージ（Rubyおよびネイティブ拡張機能をRuby gemにコンパイルするために必要）をインストールします:

```shell
sudo apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libre2-dev \
  libreadline-dev libncurses5-dev libffi-dev curl openssh-server libxml2-dev libxslt-dev \
  libcurl4-openssl-dev libicu-dev libkrb5-dev logrotate rsync python3-docutils pkg-config cmake \
  runit-systemd
```

{{< alert type="note" >}}

GitLabにはOpenSSLバージョン1.1が必要です。Linuxディストリビューションに異なるバージョンのOpenSSLが含まれている場合は、1.1を手動でインストールする必要があるかもしれません。

{{< /alert >}}

### Git {#git}

次の[Gitalyから提供されるGitバージョン](https://gitlab.com/gitlab-org/gitaly/-/issues/2729)を使用する必要があります:

- GitLabに必要なバージョン。
- 適切な動作に必要なカスタムパッチが含まれている。

1. 必要な依存関係をインストールします:

   ```shell
   sudo apt-get install -y libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev libpcre2-dev build-essential git-core
   ```

1. Gitalyリポジトリをクローンし、Gitをコンパイルします。インストールするGitLabバージョンに一致する安定したブランチで`<X-Y-stable>`を置き換えます。たとえば、GitLab 16.7をインストールする場合は、ブランチ名`16-7-stable`を使用します:

   ```shell
   git clone https://gitlab.com/gitlab-org/gitaly.git -b <X-Y-stable> /tmp/gitaly
   cd /tmp/gitaly
   sudo make git GIT_PREFIX=/usr/local
   ```

1. オプションで、システムGitとその依存関係を削除できます:

   ```shell
   sudo apt remove -y git-core
   sudo apt autoremove
   ```

[後で`config/gitlab.yml`を編集](#configure-it)する場合は、Gitパスを変更することを忘れないでください:

- 変更前:

  ```yaml
  git:
    bin_path: /usr/bin/git
  ```

- 変更後:

  ```yaml
  git:
    bin_path: /usr/local/bin/git
  ```

### GraphicsMagick {#graphicsmagick}

[カスタムファビコン](../../administration/appearance.md#customize-the-favicon)を機能させるには、GraphicsMagickをインストールする必要があります。

```shell
sudo apt-get install -y graphicsmagick
```

### メールサーバー {#mail-server}

メール通知を受信するには、メールサーバーがインストールされていることを確認してください。デフォルトでは、Debianには`exim4`が付属していますが、これには[問題があり](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/12754)、Ubuntuには付属していません。推奨されるメールサーバーは`postfix`であり、次の方法でインストールできます:

```shell
sudo apt-get install -y postfix
```

次に、`Internet Site`を選択し、<kbd>Enter</kbd>を押して、ホスト名を確認します。

### ExifTool {#exiftool}

[GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse#dependencies)には、アップロードされた画像からEXIFデータを削除するために`exiftool`が必要です。

```shell
sudo apt-get install -y libimage-exiftool-perl
```

## 2\.Ruby {#2-ruby}

GitLabを実行するには、Rubyインタプリタが必要です。最小Ruby要件については、[要件のセクション](#software-requirements)を参照してください。

RVM、rbenv、chrubyなどのRubyバージョンマネージャーは、GitLabで診断が難しい問題を引き起こす可能性があります。その代わりに、公式ソースコードから[Rubyをインストール](https://www.ruby-lang.org/en/documentation/installation/)してください。

## 3\.RubyGems {#3-rubygems}

Rubyに同梱されているよりも新しいバージョンのRubyGemsが必要になる場合があります。

特定のバージョンに更新するには:

```shell
gem update --system 3.4.12
```

または最新バージョンに更新するには:

```shell
gem update --system
```

## 4\.Go {#4-go}

GitLabには、Goで記述されたいくつかのデーモンがあります。GitLabをインストールするには、Goコンパイラをインストールする必要があります。以下の手順では、64ビット版Linuxを使用することを前提としています。他のプラットフォームのダウンロードは、[Goダウンロードページ](https://go.dev/dl/)にあります。

```shell
# Remove former Go installation folder
sudo rm -rf /usr/local/go

curl --remote-name --location --progress-bar "https://go.dev/dl/go1.22.5.linux-amd64.tar.gz"
echo '904b924d435eaea086515bc63235b192ea441bd8c9b198c507e85009e6e4c7f0  go1.22.5.linux-amd64.tar.gz' | shasum -a256 -c - && \
  sudo tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
sudo ln -sf /usr/local/go/bin/{go,gofmt} /usr/local/bin/
rm go1.22.5.linux-amd64.tar.gz
```

## 5\.Node {#5-node}

GitLabでは、JavaScriptアセットをコンパイルするためにNodeを使用し、JavaScriptの依存関係を管理するためにYarnを使用する必要があります。これらの現在の最小要件は次のとおりです:

- `node` 20.xリリース（v20.13.0以降）。[Node.jsのその他のLTSバージョン](https://github.com/nodejs/release#release-schedule)はアセットを構築できるかもしれませんが、Node.js 20.xのみを保証します。
- `yarn`= v1.22.x（Yarn 2はまだサポートされていません）

多くのディストリビューションでは、公式パッケージリポジトリによって提供されるバージョンが古くなっているため、次のコマンドを使用してインストールする必要があります:

```shell
# install node v20.x
curl --location "https://deb.nodesource.com/setup_20.x" | sudo bash -
sudo apt-get install -y nodejs

npm install --global yarn
```

これらの手順で問題が発生した場合は、[node](https://nodejs.org/en/download)および[yarn](https://classic.yarnpkg.com/en/docs/install/)の公式ウェブサイトにアクセスしてください。

## 6\.システムユーザー {#6-system-users}

GitLabの`git`ユーザーを作成します:

```shell
sudo adduser --disabled-login --gecos 'GitLab' git
```

## 7\.データベース {#7-database}

{{< alert type="note" >}}

PostgreSQLのみがサポートされています。GitLab 18.0以降では、[PostgreSQL 16以降](../requirements.md#postgresql)が必要です。

{{< /alert >}}

1. データベースパッケージをインストールします。

   Ubuntu 22.04以降の場合:

   ```shell
   sudo apt install -y postgresql postgresql-client libpq-dev postgresql-contrib
   ```

   Ubuntu 20.04以前の場合、利用可能なPostgreSQLは最小バージョン要件を満たしていません。PostgreSQLリポジトリを追加する必要があります:

   ```shell
   sudo curl --fail --silent --show-error --output /etc/apt/keyrings/postgresql.asc \
             --url "https://www.postgresql.org/media/keys/ACCC4CF8.asc"
   echo "deb [ signed-by=/etc/apt/keyrings/postgresql.asc ] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" |
        sudo tee /etc/apt/sources.list.d/pgdg.list
   sudo apt-get update
   sudo apt-get -y install postgresql-16
   ```

1. インストールしているGitLabのバージョンでサポートされているPostgreSQLバージョンを確認します:

   ```shell
   psql --version
   ```

1. PostgreSQLサービスを開始し、サービスが実行されていることを確認します:

   ```shell
   sudo service postgresql start
   sudo service postgresql status
   ```

1. GitLabのデータベースユーザーを作成します:

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE USER git CREATEDB;"
   ```

1. `pg_trgm`拡張機能を作成します:

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
   ```

1. `btree_gist`拡張機能を作成します:

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS btree_gist;"
   ```

1. `plpgsql`拡張機能を作成します:

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS plpgsql;"
   ```

1. GitLab本番環境のデータベースを作成し、データベースに対するすべての特権を付与します:

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;"
   ```

1. 新しいユーザーで新しいデータベースへの接続を試みます:

   ```shell
   sudo -u git -H psql -d gitlabhq_production
   ```

1. `pg_trgm`拡張機能が有効であるかを確認します:

   ```sql
   SELECT true AS enabled
   FROM pg_available_extensions
   WHERE name = 'pg_trgm'
   AND installed_version IS NOT NULL;
   ```

   拡張機能が有効である場合、次の出力が生成されます:

   ```plaintext
   enabled
   ---------
    t
   (1 row)
   ```

1. `btree_gist`拡張機能が有効であるかを確認します:

   ```sql
   SELECT true AS enabled
   FROM pg_available_extensions
   WHERE name = 'btree_gist'
   AND installed_version IS NOT NULL;
   ```

   拡張機能が有効である場合、次の出力が生成されます:

   ```plaintext
   enabled
   ---------
    t
   (1 row)
   ```

1. `plpgsql`拡張機能が有効であるかを確認します:

   ```sql
   SELECT true AS enabled
   FROM pg_available_extensions
   WHERE name = 'plpgsql'
   AND installed_version IS NOT NULL;
   ```

   拡張機能が有効である場合、次の出力が生成されます:

   ```plaintext
   enabled
   ---------
    t
   (1 row)
   ```

1. データベースセッションを終了します:

   ```shell
   gitlabhq_production> \q
   ```

## 8\.Redis {#8-redis}

最小Redis要件については、[要件ページ](../requirements.md#redis)を参照してください。

次でRedisをインストールします:

```shell
sudo apt-get install redis-server
```

完了したら、Redisを設定できます:

```shell
# Configure redis to use sockets
sudo cp /etc/redis/redis.conf /etc/redis/redis.conf.orig

# Disable Redis listening on TCP by setting 'port' to 0
sudo sed 's/^port .*/port 0/' /etc/redis/redis.conf.orig | sudo tee /etc/redis/redis.conf

# Enable Redis socket for default Debian / Ubuntu path
echo 'unixsocket /var/run/redis/redis.sock' | sudo tee -a /etc/redis/redis.conf

# Grant permission to the socket to all members of the redis group
echo 'unixsocketperm 770' | sudo tee -a /etc/redis/redis.conf

# Add git to the redis group
sudo usermod -aG redis git
```

### systemdでRedisを管理する {#supervise-redis-with-systemd}

ディストリビューションがsystemd initを使用し、次のコマンドの出力が`notify`の場合、変更を加えないでください:

```shell
systemctl show --value --property=Type redis-server.service
```

出力が`notify`**でない**場合は、以下を実行します:

```shell
# Configure Redis to not daemonize, but be supervised by systemd instead and disable the pidfile
sudo sed -i \
         -e 's/^daemonize yes$/daemonize no/' \
         -e 's/^supervised no$/supervised systemd/' \
         -e 's/^pidfile/# pidfile/' /etc/redis/redis.conf
sudo chown redis:redis /etc/redis/redis.conf

# Make the same changes to the systemd unit file
sudo mkdir -p /etc/systemd/system/redis-server.service.d
sudo tee /etc/systemd/system/redis-server.service.d/10fix_type.conf <<EOF
[Service]
Type=notify
PIDFile=
EOF

# Reload the redis service
sudo systemctl daemon-reload

# Activate the changes to redis.conf
sudo systemctl restart redis-server.service
```

### Redisを管理しない {#leave-redis-unsupervised}

システムがSysV initを使用している場合は、これらのコマンドを実行します:

```shell
# Create the directory which contains the socket
sudo mkdir -p /var/run/redis
sudo chown redis:redis /var/run/redis
sudo chmod 755 /var/run/redis

# Persist the directory which contains the socket, if applicable
if [ -d /etc/tmpfiles.d ]; then
  echo 'd  /var/run/redis  0755  redis  redis  10d  -' | sudo tee -a /etc/tmpfiles.d/redis.conf
fi

# Activate the changes to redis.conf
sudo service redis-server restart
```

## 9\.GitLab {#9-gitlab}

```shell
# We'll install GitLab into the home directory of the user "git"
cd /home/git
```

### ソースのクローンを作成する {#clone-the-source}

Community Editionのクローンを作成する:

```shell
# Clone GitLab repository
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-foss.git -b <X-Y-stable> gitlab
```

Enterprise Editionのクローンを作成する:

```shell
# Clone GitLab repository
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab.git -b <X-Y-stable-ee> gitlab
```

インストールするバージョンに一致する安定したブランチで`<X-Y-stable>`を必ず置き換えてください。たとえば、11.8をインストールする場合は、ブランチ名`11-8-stable`を使用します。

{{< alert type="warning" >}}

「最新」バージョンが必要な場合は`<X-Y-stable>`を`master`に変更できますが、本番環境サーバーに`master`をインストールしないでください。

{{< /alert >}}

### 設定する {#configure-it}

```shell
# Go to GitLab installation folder
cd /home/git/gitlab

# Copy the example GitLab config
sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml

# Update GitLab config file, follow the directions at top of the file
sudo -u git -H editor config/gitlab.yml

# Copy the example secrets file
sudo -u git -H cp config/secrets.yml.example config/secrets.yml
sudo -u git -H chmod 0600 config/secrets.yml

# Make sure GitLab can write to the log/ and tmp/ directories
sudo chown -R git log/
sudo chown -R git tmp/
sudo chmod -R u+rwX,go-w log/
sudo chmod -R u+rwX tmp/

# Make sure GitLab can write to the tmp/pids/ and tmp/sockets/ directories
sudo chmod -R u+rwX tmp/pids/
sudo chmod -R u+rwX tmp/sockets/

# Create the public/uploads/ directory
sudo -u git -H mkdir -p public/uploads/

# Make sure only the GitLab user has access to the public/uploads/ directory
# now that files in public/uploads are served by gitlab-workhorse
sudo chmod 0700 public/uploads

# Change the permissions of the directory where CI job logs are stored
sudo chmod -R u+rwX builds/

# Change the permissions of the directory where CI artifacts are stored
sudo chmod -R u+rwX shared/artifacts/

# Change the permissions of the directory where GitLab Pages are stored
sudo chmod -R ug+rwX shared/pages/

# Copy the example Puma config
sudo -u git -H cp config/puma.rb.example config/puma.rb

# Refer to https://github.com/puma/puma#configuration for more information.
# You should scale Puma workers and threads based on the number of CPU
# cores you have available. You can get that number via the `nproc` command.
sudo -u git -H editor config/puma.rb

# Configure Redis connection settings
sudo -u git -H cp config/resque.yml.example config/resque.yml
sudo -u git -H cp config/cable.yml.example config/cable.yml

# Change the Redis socket path if you are not using the default Debian / Ubuntu configuration
sudo -u git -H editor config/resque.yml config/cable.yml
```

必ず`gitlab.yml`と`puma.rb`の両方を編集して、セットアップと一致するようにしてください。

HTTPSを使用する場合は、追加の手順について[HTTPSの使用](#using-https)を参照してください。

### GitLab DB設定を構成する {#configure-gitlab-db-settings}

{{< alert type="note" >}}

[GitLab 15.9](https://gitlab.com/gitlab-org/gitlab/-/issues/387898)以降、セクションが`main:`のみの`database.yml`は非推奨になりました。GitLab 17.0以降では、`database.yml`に`main:`セクションと`ci:`セクションの2つが必要です。

{{< /alert >}}

```shell
sudo -u git cp config/database.yml.postgresql config/database.yml

# Remove host, username, and password lines from config/database.yml.
# Once modified, the `production` settings will be as follows:
#
#   production:
#     main:
#       adapter: postgresql
#       encoding: unicode
#       database: gitlabhq_production
#     ci:
#       adapter: postgresql
#       encoding: unicode
#       database: gitlabhq_production
#       database_tasks: false
#
sudo -u git -H editor config/database.yml

# Remote PostgreSQL only:
# Update username/password in config/database.yml.
# You only need to adapt the production settings (first part).
# If you followed the database guide then please do as follows:
# Change 'secure password' with the value you have given to $password
# You can keep the double quotes around the password
sudo -u git -H editor config/database.yml

# Uncomment the `ci:` sections in config/database.yml.
# Ensure the `database` value in `ci:` matches the database value in `main:`.

# Make config/database.yml readable to git only
sudo -u git -H chmod o-rwx config/database.yml
```

`database.yml`には、`main:`と`ci:`の2つのセクションが必要です。`ci`: 接続は、[同じデータベースへの接続](../../administration/postgresql/_index.md)である必要があります。

### Gemsをインストールする {#install-gems}

{{< alert type="note" >}}

Bundler 1.5.2以降では、`bundle install -jN`（`N`はプロセッサコアの数）を実行することで、gemの並列インストールを完了するのにかかる時間をかなり短縮（約60%高速）できます。`nproc`でコア数を確認してください。詳細については、[こちらの投稿](https://thoughtbot.com/blog/parallel-gem-installing-using-bundler)を参照してください。

{{< /alert >}}

`bundle`があることを確認してください（`bundle -v`を実行）:

- `>= 1.5.2`、一部の[イシュー](https://devcenter.heroku.com/changelog-items/411)は1.5.2で[修正](https://github.com/rubygems/bundler/pull/2817)されたためです。
- `< 2.x`。

ユーザー認証にKerberosを使用する場合は、以下のコマンドの`--without`オプションで`kerberos`を省略して、gemをインストールします:

```shell
sudo -u git -H bundle config set --local deployment 'true'
sudo -u git -H bundle config set --local without 'development test kerberos'
sudo -u git -H bundle config path /home/git/gitlab/vendor/bundle
sudo -u git -H bundle install
```

### GitLab Shellをインストールする {#install-gitlab-shell}

GitLab Shellは、GitLabに特別に開発されたSSHアクセスおよびリポジトリ管理ソフトウェアです。

```shell
# Run the installation task for gitlab-shell:
sudo -u git -H bundle exec rake gitlab:shell:install RAILS_ENV=production

# By default, the gitlab-shell config is generated from your main GitLab config.
# You can review (and modify) the gitlab-shell config as follows:
sudo -u git -H editor /home/git/gitlab-shell/config.yml
```

HTTPSを使用する場合は、追加の手順について[HTTPSの使用](#using-https)を参照してください。

適切なDNSレコードまたは`/etc/hosts`の追加の行（「127.0.0.1ホスト名」）のいずれかによって、ホスト名をマシン自体で解決できることを確認してください。これは、たとえば、リバースプロキシの背後にGitLabを設定する場合に必要になる場合があります。ホスト名を解決できない場合、最終的なインストールチェックは`Check GitLab API access: FAILED. code: 401`で失敗し、コミットのプッシュは`[remote rejected] master -> master (hook declined)`で拒否されます。

### GitLab Workhorseをインストールする {#install-gitlab-workhorse}

GitLab-Workhorseは[GNU Make](https://www.gnu.org/software/make/)を使用します。次のコマンドラインを使うと、推奨される場所である`/home/git/gitlab-workhorse`にGitLab-Workhorseをインストールします。

```shell
sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
```

追加のパラメータとして指定することで、別のGitリポジトリを指定できます:

```shell
sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse,https://example.com/gitlab-workhorse.git]" RAILS_ENV=production
```

### Enterprise EditionにGitLab-Elasticsearch-indexerをインストールする {#install-gitlab-elasticsearch-indexer-on-enterprise-edition}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab-Elasticsearch-Indexerは[GNU Make](https://www.gnu.org/software/make/)を使用します。次のコマンドラインを使うと、推奨される場所である`/home/git/gitlab-elasticsearch-indexer`にGitLab-Elasticsearch-Indexerをインストールします。

```shell
sudo -u git -H bundle exec rake "gitlab:indexer:install[/home/git/gitlab-elasticsearch-indexer]" RAILS_ENV=production
```

追加のパラメータとして指定することで、別のGitリポジトリを指定できます:

```shell
sudo -u git -H bundle exec rake "gitlab:indexer:install[/home/git/gitlab-elasticsearch-indexer,https://example.com/gitlab-elasticsearch-indexer.git]" RAILS_ENV=production
```

ソースコードはまず、最初のパラメータで指定されたパスにフェッチされます。次に、その`bin`ディレクトリの下にバイナリが構築されます。その後、`gitlab.yml`の`production -> elasticsearch -> indexer_path`設定を更新して、そのバイナリを指すようにします。

### GitLab Pagesをインストールする {#install-gitlab-pages}

GitLab Pagesは[GNU Make](https://www.gnu.org/software/make/)を使用します。この手順はオプションであり、GitLab内から静的サイトをホストする場合にのみ必要です。次のコマンドを使うと、`/home/git/gitlab-pages`にGitLab Pagesをインストールします。追加の設定手順については、GitLab Pagesデーモンはいくつかの異なる方法で実行できるため、お使いのバージョンのGitLabの[管理ガイド](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/pages/source.md)を参照してください。

```shell
cd /home/git
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
cd gitlab-pages
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
sudo -u git -H make
```

### Gitalyをインストールする {#install-gitaly}

```shell
# Create and restrict access to the git repository data directory
sudo install -d -o git -m 0700 /home/git/repositories

# Fetch Gitaly source with Git and compile with Go
cd /home/git/gitlab
sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production
```

追加のパラメータとして指定することで、別のGitリポジトリを指定できます:

```shell
sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories,https://example.com/gitaly.git]" RAILS_ENV=production
```

次に、Gitalyが設定されていることを確認します:

```shell
# Restrict Gitaly socket access
sudo chmod 0700 /home/git/gitlab/tmp/sockets/private
sudo chown git /home/git/gitlab/tmp/sockets/private

# If you are using non-default settings, you need to update config.toml
cd /home/git/gitaly
sudo -u git -H editor config.toml
```

Gitalyの設定の詳細については、[Gitalyのドキュメント](../../administration/gitaly/_index.md)を参照してください。

### サービスをインストールする {#install-the-service}

GitLabは常にSysV initスクリプトをサポートしてきました。これは広くサポートされており、移植性がありますが、現在ではsystemdがサービス監視の標準であり、すべての主要なLinuxディストリビューションで使用されています。自動再起動、より優れたサンドボックス化、リソース制御のメリットを享受するには、可能な限りネイティブのsystemdサービスを使用する必要があります。

#### systemdユニットをインストールする {#install-systemd-units}

systemdをinitとして使用する場合は、次の手順を実行します。それ以外の場合は、[SysV initスクリプトの手順](#install-sysv-init-script)に従ってください。

サービスをコピーして`systemctl daemon-reload`を実行し、systemdがそれらを認識するようにします:

```shell
cd /home/git/gitlab
sudo mkdir -p /usr/local/lib/systemd/system
sudo cp lib/support/systemd/* /usr/local/lib/systemd/system/
sudo systemctl daemon-reload
```

GitLabによって提供されるユニットは、RedisおよびPostgreSQLを実行している場所について、ほとんど前提を置いていません。

GitLabを別のディレクトリにインストールした場合、またはデフォルト以外のユーザーとしてインストールした場合は、ユニット内のこれらの値も変更する必要があります。

たとえば、GitLabと同じマシンでRedisとPostgreSQLを実行している場合は、次の手順を実行する必要があります:

- Pumaサービスを編集します:

  ```shell
  sudo systemctl edit gitlab-puma.service
  ```

  開いたエディタで、以下を追加してファイルを保存します:

  ```plaintext
  [Unit]
  Wants=redis-server.service postgresql.service
  After=redis-server.service postgresql.service
  ```

- Sidekiqサービスを編集します:

  ```shell
  sudo systemctl edit gitlab-sidekiq.service
  ```

  以下を追加してファイルを保存します:

  ```plaintext
  [Unit]
  Wants=redis-server.service postgresql.service
  After=redis-server.service postgresql.service
  ```

`systemctl edit`は、`/etc/systemd/system/<name of the unit>.d/override.conf`にドロップイン設定ファイルをインストールするため、後でユニットファイルをアップグレードするときにローカル設定が上書きされることはありません。ドロップイン設定ファイルを分割するには、`/etc/systemd/system/<name of the unit>.d/`にある`.conf`ファイルに先程のスニペットを追加します。

`systemctl edit`を使用せずに、ユニットファイルを手動で変更した場合、またはドロップイン設定ファイルを追加した場合は、次のコマンドを実行して有効にします:

```shell
sudo systemctl daemon-reload
```

ブート時にGitLabを起動させます:

```shell
sudo systemctl enable gitlab.target
```

#### SysV initスクリプトをインストールする {#install-sysv-init-script}

SysV initスクリプトを使用する場合は、次の手順を実行します。systemdを使用する場合は、[systemdユニットの手順](#install-systemd-units)に従ってください。

initスクリプト（`/etc/init.d/gitlab`）をダウンロードします:

```shell
cd /home/git/gitlab
sudo cp lib/support/init.d/gitlab /etc/init.d/gitlab
```

また、デフォルト以外のフォルダーまたはユーザーでインストールする場合は、デフォルトファイルをコピーして編集します:

```shell
sudo cp lib/support/init.d/gitlab.default.example /etc/default/gitlab
```

GitLabを別のディレクトリにインストールした場合、またはデフォルト以外のユーザーとしてインストールした場合は、`/etc/default/gitlab`でこれらの設定を変更する必要があります。アップグレード時に変更されるため、`/etc/init.d/gitlab`を編集しないでください。

ブート時にGitLabを起動させます:

```shell
sudo update-rc.d gitlab defaults 21
# or if running this on a machine running systemd
sudo systemctl daemon-reload
sudo systemctl enable gitlab.service
```

### Logrotateを設定する {#set-up-logrotate}

```shell
sudo cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab
```

### Gitalyを起動する {#start-gitaly}

次のセクションでは、Gitalyが実行されている必要があります。

- systemdを使用してGitalyを起動するには:

  ```shell
  sudo systemctl start gitlab-gitaly.service
  ```

- SysV用にGitalyを手動で起動するには:

  ```shell
  gitlab_path=/home/git/gitlab
  gitaly_path=/home/git/gitaly

  sudo -u git -H sh -c "$gitlab_path/bin/daemon_with_pidfile $gitlab_path/tmp/pids/gitaly.pid \
    $gitaly_path/_build/bin/gitaly $gitaly_path/config.toml >> $gitlab_path/log/gitaly.log 2>&1 &"
  ```

### データベースを初期化して高度な機能をアクティブにする {#initialize-database-and-activate-advanced-features}

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production
# Type 'yes' to create the database tables.

# or you can skip the question by adding force=yes
sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production force=yes

# When done, you see 'Administrator account created:'
```

次のコマンドに示すように、環境変数`GITLAB_ROOT_PASSWORD`および`GITLAB_ROOT_EMAIL`で管理者/rootパスワードとメールアドレスを設定できます。パスワードを設定しない（デフォルトのパスワードに設定されている）場合は、インストールが完了し、最初にサーバーにログインするまで、GitLabをパブリックインターネットに公開しないでください。最初のログイン時に、デフォルトのパスワードの変更が強制されます。Enterprise Editionサブスクリプションは、このとき、`GITLAB_ACTIVATION_CODE`環境変数にアクティベーションコードを指定してアクティブにすることもできます。

```shell
sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production GITLAB_ROOT_PASSWORD=yourpassword GITLAB_ROOT_EMAIL=youremail GITLAB_ACTIVATION_CODE=yourcode
```

### `secrets.yml`をセキュアにする {#secure-secretsyml}

`secrets.yml`ファイルには、セッションとセキュア変数のエンコードキーが格納されています。`secrets.yml`を安全な場所にバックアップしますが、データベースのバックアップと同じ場所に保存しないでください。そうしないと、バックアップのいずれかが侵害された場合に、シークレットが公開されます。

### アプリケーションの状態を確認する {#check-application-status}

GitLabとその環境が正しく設定されているかどうかを検証します:

```shell
sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

### アセットをコンパイルする {#compile-assets}

```shell
sudo -u git -H yarn install --production --pure-lockfile
sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production
```

`rake`が`JavaScript heap out of memory`エラーで失敗する場合は、次のように`NODE_OPTIONS`を設定して実行してみてください。

```shell
sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=4096"
```

### GitLabインスタンスを起動する {#start-your-gitlab-instance}

```shell
# For systems running systemd
sudo systemctl start gitlab.target

# For systems running SysV init
sudo service gitlab start
```

## 10. NGINX {#10-nginx}

NGINXは、GitLabで公式にサポートされているウェブサーバーです。ウェブサーバーとしてNGINXを使用できない場合、または使用したくない場合は、[GitLabレシピ](https://gitlab.com/gitlab-org/gitlab-recipes/)を参照してください。

### インストール {#installation}

```shell
sudo apt-get install -y nginx
```

### サイトの設定 {#site-configuration}

サイト設定の例をコピーします:

```shell
sudo cp lib/support/nginx/gitlab /etc/nginx/sites-available/gitlab
sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab
```

セットアップに合わせて設定ファイルを編集してください。特に`git`ユーザー以外のユーザー用にインストールする場合は、GitLabへのパスが一致していることを確認してください:

```shell
# Change YOUR_SERVER_FQDN to the fully-qualified
# domain name of your host serving GitLab.
#
# Remember to match your paths to GitLab, especially
# if installing for a user other than 'git'.
#
# If using Ubuntu default nginx install:
# either remove the default_server from the listen line
# or else sudo rm -f /etc/nginx/sites-enabled/default
sudo editor /etc/nginx/sites-available/gitlab
```

GitLab Pagesを有効にする場合は、別途NGINX設定を使用する必要があります。すべての必要な設定について、[GitLab Pages管理者ガイド](../../administration/pages/_index.md)をお読みください。

HTTPSを使用する場合は、`gitlab` NGINX設定を`gitlab-ssl`に置き換えます。HTTPS設定の詳細については、[HTTPSの使用](#using-https)を参照してください。

NGINXがGitLab-Workhorseソケットを読み取れるようにするには、GitLabユーザーが所有するソケットを`www-data`ユーザーが読み取れるようにする必要があります。これは、グローバルに読み取り可能である場合（たとえば、デフォルトで`0755`の権限を持っている場合）に実現できます。`www-data`は、親ディレクトリをリストできる必要もあります。

### 設定をテストする {#test-configuration}

次のコマンドを使用して、`gitlab`または`gitlab-ssl` NGINX設定ファイルを検証します:

```shell
sudo nginx -t
```

`syntax is okay`および`test is successful`メッセージが表示されるはずです。エラーメッセージが表示される場合は、そこに示されているように、`gitlab`または`gitlab-ssl` NGINX設定ファイルにタイプミスがないか確認してください。

インストールされているバージョンが1.12.1以降であることを確認します:

```shell
nginx -v
```

それより前のバージョンの場合は、次のエラーが表示されることがあります:

```plaintext
nginx: [emerg] unknown "start$temp=[filtered]$rest" variable
nginx: configuration file /etc/nginx/nginx.conf test failed
```

### 再起動 {#restart}

```shell
# For systems running systemd
sudo systemctl restart nginx.service

# For systems running SysV init
sudo service nginx restart
```

## インストール後 {#post-install}

### アプリケーションの状態を再確認 {#double-check-application-status}

何か見落としがないか確認するには、次のコマンドでより徹底的なチェックを実行します:

```shell
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

すべての項目が緑色の場合は、GitLabのインストールに成功しました。

{{< alert type="note" >}}

チェックコマンドの出力からプロジェクト名を省略するには、`SANITIZE=true`環境変数を`gitlab:check`に指定します。

{{< /alert >}}

### 最初のログイン {#initial-login}

GitLabに初めてログインするには、ウェブブラウザでYOUR_SERVERにアクセスします。

[セットアップ中にrootパスワードを指定](#initialize-database-and-activate-advanced-features)しなかった場合は、パスワードリセット画面にリダイレクトされ、最初の管理者アカウントのパスワードを指定するように求められます。希望するパスワードを入力すると、ログイン画面にリダイレクトされます。

デフォルトのアカウントのユーザー名は**root**です。作成したパスワードを入力してログインします。ログイン後、必要に応じてユーザー名を変更できます。

**ご利用可能になりました**

以下を使用するときにGitLabを起動および停止するには:

- systemdユニット: `sudo systemctl start gitlab.target`または`sudo systemctl stop gitlab.target`を使用します。
- SysV initスクリプト: `sudo service gitlab start`または`sudo service gitlab stop`を使用します。

### 推奨される次の手順 {#recommended-next-steps}

インストールが完了したら、[推奨される次の手順](../next_steps.md)（認証オプションやサインアップ制限など）を実行することを検討してください。

## 高度な設定のヒント {#advanced-setup-tips}

### 相対URLのサポート {#relative-url-support}

相対URLでGitLabを設定する方法の詳細については、[相対URLドキュメント](../relative_url.md)を参照してください。

### HTTPSを使用する {#using-https}

HTTPSでGitLabを使用するには:

1. `gitlab.yml`で:
   1. セクション1の`port`オプションを`443`に設定します。
   1. セクション1の`https`オプションを`true`に設定します。
1. GitLab Shellの`config.yml`で:
   1. `gitlab_url`オプションをGitLabのHTTPSエンドポイント（たとえば、`https://git.example.com`）に設定します。
   1. `ca_file`または`ca_path`オプションのいずれかを使用して証明書を設定します。
1. `gitlab`設定ではなく、`gitlab-ssl` NGINXのサンプル設定を使用します。
   1. `YOUR_SERVER_FQDN`を更新します。
   1. `ssl_certificate`と`ssl_certificate_key`を更新します。
   1. 設定ファイルを確認し、他のセキュリティおよびパフォーマンス強化機能の適用を検討してください。

自己署名証明書を使用することはおすすめできません。どうしても使用する必要がある場合は、標準的な指示に従って自己署名SSL証明書を生成します:

   ```shell
   mkdir -p /etc/nginx/ssl/
   cd /etc/nginx/ssl/
   sudo openssl req -newkey rsa:2048 -x509 -nodes -days 3560 -out gitlab.crt -keyout gitlab.key
   sudo chmod o-r gitlab.key
   ```

### メールによる返信を有効にする {#enable-reply-by-email}

このセットアップ方法の詳細については、[「メールで返信」ドキュメント](../../administration/reply_by_email.md)を参照してください。

### LDAP認証 {#ldap-authentication}

`config/gitlab.yml`でLDAP認証を設定できます。このファイルを編集した後、GitLabを再起動します。

### カスタムOmniAuthプロバイダーを使用する {#using-custom-omniauth-providers}

[OmniAuthインテグレーションドキュメント](../../integration/omniauth.md)を参照してください。

### プロジェクトをビルドする {#build-your-projects}

GitLabではプロジェクトをビルドできます。その機能を有効にするには、それを行うためのRunnerが必要です。Runnerをインストールするには、[GitLab Runnerセクション](https://docs.gitlab.com/runner/)を参照してください。

### 信頼できるプロキシを追加する {#adding-your-trusted-proxies}

別のマシンでリバースプロキシを使用している場合は、プロキシを信頼できるプロキシリストに追加することをお勧めします。そうしないと、ユーザーはプロキシのIPアドレスから署名インしたように表示されます。

`config/gitlab.yml`で、セクション1の`trusted_proxies`オプションをカスタマイズすることにより、信頼できるプロキシを追加できます。ファイルを保存し、変更を有効にするために[GitLabを再構成](../../administration/restart_gitlab.md)します。

URLで不適切にエンコードされた文字に関する問題が発生した場合は、[エラー: リバースプロキシの使用時に`404 Not Found`](../../api/rest/troubleshooting.md#error-404-not-found-when-using-a-reverse-proxy)を参照してください。

### カスタムRedis接続 {#custom-redis-connection}

非標準ポートまたは別のホストでRedisサーバーに接続する場合は、`config/resque.yml`ファイルを使用して接続文字列を設定できます。

```yaml
# example
production:
  url: redis://redis.example.tld:6379
```

ソケット経由でRedisサーバーに接続する場合は、`unix:` URLスキームと、`config/resque.yml`ファイル内のRedisソケットへのパスを使用します。

```yaml
# example
production:
  url: unix:/path/to/redis/socket
```

また、`config/resque.yml`ファイルで環境変数を使用することもできます:

```yaml
# example
production:
  url: <%= ENV.fetch('GITLAB_REDIS_URL') %>
```

### カスタムSSH接続 {#custom-ssh-connection}

非標準ポートでSSHを実行している場合は、GitLabユーザーのSSH設定を変更する必要があります。

```plaintext
# Add to /home/git/.ssh/config
host localhost          # Give your setup a name (here: override localhost)
    user git            # Your remote git user
    port 2222           # Your port number
    hostname 127.0.0.1; # Your server name or IP
```

また、`config/gitlab.yml`ファイルで対応するオプション（`ssh_user`、`ssh_host`、`admin_uri`など）も変更する必要があります。

### 追加のマークアップスタイル {#additional-markup-styles}

常にサポートされているMarkdownスタイルとは別に、GitLabが表示できるリッチテキストファイルが他にもあります。ただし、これを行うには、依存関係をインストールする必要がある場合があります。詳細については、[`github-markup` gem Readme](https://github.com/gitlabhq/markup#markups)を参照してください。

### Prometheusサーバーの設定 {#prometheus-server-setup}

`config/gitlab.yml`でPrometheusサーバーを設定できます:

```yaml
# example
prometheus:
  enabled: true
  server_address: '10.1.2.3:9090'
```

## トラブルシューティング {#troubleshooting}

### 「空のリポジトリを複製したようです」 {#you-appear-to-have-cloned-an-empty-repository}

GitLabがホストするリポジトリを複製しようとしたときにこのメッセージが表示される場合、これは、NGINXまたはApacheの設定が古くなっているか、GitLab Workhorseインスタンスがないか、誤って設定されていることが原因である可能性があります。[Goをインストール](#4-go)し、[GitLab Workhorseをインストール](#install-gitlab-workhorse)し、[NGINXを正しく設定](#site-configuration)したことを再確認してください。

### `google-protobuf`「LoadError: /lib/x86_64-linux-gnu/libc.so.6: バージョン 'GLIBC_2.14' が見つかりません」 {#google-protobuf-loaderror-libx86_64-linux-gnulibcso6-version-glibc_214-not-found}

これは、一部のバージョンの`google-protobuf` gemを使うプラットフォームで発生する可能性があります。回避策は、このgemのソースのみのバージョンをインストールすることです。

まず、GitLabインストールに必要な`google-protobuf`の正確なバージョンを見つける必要があります:

```shell
cd /home/git/gitlab

# Only one of the following two commands will print something. It
# will look like: * google-protobuf (3.2.0)
bundle list | grep google-protobuf
bundle check | grep google-protobuf
```

次のコマンドでは、`3.2.0`を例として使用しています。これを先ほど見つけたバージョン番号に置き換えてください:

```shell
cd /home/git/gitlab
sudo -u git -H gem install google-protobuf --version 3.2.0 --platform ruby
```

最後に、`google-protobuf`が正しく読み込まれるかどうかをテストできます。次は`OK`と表示されるはずです。

```shell
sudo -u git -H bundle exec ruby -rgoogle/protobuf -e 'puts :OK'
```

`gem install`コマンドが失敗する場合は、OSのデベロッパーツールをインストールする必要があるかもしれません。

Debian/Ubuntuの場合:

```shell
sudo apt-get install build-essential libgmp-dev
```

RedHat/CentOSの場合:

```shell
sudo yum groupinstall 'Development Tools'
```

### GitLabアセットのコンパイルエラー {#error-compiling-gitlab-assets}

アセットをコンパイル中に、次のエラーメッセージが表示されることがあります:

```plaintext
Killed
error Command failed with exit code 137.
```

これは、Yarnがメモリ不足で実行されているコンテナを強制終了した場合に発生する可能性があります。これを修正するには:

1. システムのメモリを8 GiB以上に増やします。

1. 次のコマンドを実行して、アセットをクリーンアップします:

   ```shell
   sudo -u git -H bundle exec rake gitlab:assets:clean RAILS_ENV=production NODE_ENV=production
   ```

1. `yarn`コマンドを再度実行して、競合を解決します:

   ```shell
   sudo -u git -H yarn install --production --pure-lockfile
   ```

1. アセットを再コンパイルします:

   ```shell
   sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production
   ```

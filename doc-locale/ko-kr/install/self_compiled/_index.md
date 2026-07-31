---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 소스 파일을 사용하여 Debian 또는 Ubuntu에서 GitLab을 컴파일하고 각 구성 요소를 수동으로 구성하여 설치합니다.
title: 자체 컴파일 설치
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이것은 소스 파일을 사용하여 프로덕션 GitLab 서버를 설정하기 위한 공식 설치 가이드입니다. **Debian/Ubuntu** 운영 체제에서 생성되고 테스트되었습니다. [requirements.md](../requirements.md)에서 하드웨어 및 운영 체제 요구 사항을 읽어보세요. RHEL/CentOS에 설치하려면 [Linux 패키지](https://about.gitlab.com/install/)를 사용해야 합니다. 다른 많은 설치 옵션은 [주 설치 페이지](_index.md)를 참조하세요.

이 가이드는 많은 경우를 다루고 필요한 모든 명령을 포함하기 때문에 깁니다. 다음 단계는 작동하는 것으로 알려져 있습니다. 이 가이드에서 **Use caution when you deviate**. GitLab이 환경에 대해 만드는 가정을 위반하지 않는지 확인하세요. 예를 들어 많은 사람들이 디렉터리의 위치를 변경했거나 잘못된 사용자로 서비스를 실행하기 때문에 권한 문제가 발생합니다.

이 가이드에서 버그/오류를 발견하면 **submit a merge request**하고 [기여 가이드](https://gitlab.com/gitlab-org/gitlab/-/blob/master/CONTRIBUTING.md)를 따르세요.

## Linux 패키지 설치 고려 {#consider-the-linux-package-installation}

자체 컴파일 설치는 많은 작업이 필요하고 오류가 발생하기 쉽기 때문에 빠르고 안정적인 [Linux 패키지 설치](https://about.gitlab.com/install/)(deb/rpm)를 강력히 권장합니다.

Linux 패키지가 더 안정적인 한 가지 이유는 runit을 사용하여 GitLab 프로세스 중 하나가 충돌할 경우 다시 시작하기 때문입니다. GitLab 인스턴스를 많이 사용할 때 Sidekiq 백그라운드 워커의 메모리 사용량이 시간이 지남에 따라 증가합니다. Linux 패키지는 [Sidekiq를 정상적으로 종료](../../administration/sidekiq/sidekiq_memory_killer.md)하여 메모리를 너무 많이 사용할 경우 이 문제를 해결합니다. 이 종료 후 runit은 Sidekiq가 실행 중이 아님을 감지하고 시작합니다. 자체 컴파일 설치는 프로세스 감시에 runit을 사용하지 않기 때문에 Sidekiq를 종료할 수 없고 메모리 사용량이 시간이 지남에 따라 증가합니다.

## 설치할 버전 선택 {#select-a-version-to-install}

설치하려는 GitLab의 [설치 가이드](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/install/self_compiled/_index.md)를 브랜치(버전)에서 확인하세요(예: `16-0-stable`). GitLab의 왼쪽 상단 모서리에 있는 버전 드롭다운 목록에서 브랜치를 선택할 수 있습니다(메뉴 모음 아래).

최고 번호의 안정적인 브랜치가 명확하지 않으면 [GitLab 블로그](https://about.gitlab.com/blog/)에서 버전별 설치 가이드 링크를 확인하세요.

## 소프트웨어 요구 사항 {#software-requirements}

| 소프트웨어                | 최소 버전 | 참고                                                                                                                                                                                                                                                                                  |
|:------------------------|:----------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Ruby](#2-ruby)         | `3.2.x`         | GitLab 16.7에서 17.4까지는 Ruby 3.1이 필요합니다. GitLab 17.5 이상에서는 Ruby 3.2가 필요합니다. Ruby의 표준 MRI 구현을 사용해야 합니다. [JRuby](https://www.jruby.org/)와 [Rubinius](https://github.com/rubinius/rubinius#the-rubinius-language-platform)를 좋아하지만 GitLab에는 네이티브 확장이 있는 여러 Gem이 필요합니다. |
| [RubyGems](#3-rubygems) | `3.5.x`         | 특정 RubyGems 버전이 필요하지 않지만 알려진 성능 개선의 이점을 얻기 위해 업데이트해야 합니다. |
| [Go](#4-go)             | `1.22.x`        | GitLab 17.1 이상에서는 Go 1.22 이상이 필요합니다.                                                                                                                                                                                                                                        |
| [Git](#git)             | `2.47.x`        | GitLab 17.7 이상에서는 Git 2.47.x 이상이 필요합니다. [Gitaly에서 제공하는 Git 버전](#git)을 사용해야 합니다.                                                                                                                                                   |
| [Node.js](#5-node)      | `20.13.x`       | GitLab 17.0 이상에서는 Node.js 20.13 이상이 필요합니다.                                                                                                                                                                                                                                  |
| [PostgreSQL](#7-database) | `16.x`          | GitLab 18.0 이상에서는 PostgreSQL 16 이상이 필요합니다.                                                                                                                                                                                                                                  |

## GitLab 디렉터리 구조 {#gitlab-directory-structure}

다음 디렉터리는 설치 단계를 진행할 때 생성됩니다:

```plaintext
|-- home
|   |-- git
|       |-- .ssh
|       |-- gitlab
|       |-- gitlab-shell
|       |-- repositories
```

- `/home/git/.ssh` - OpenSSH 설정을 포함합니다. 구체적으로 GitLab Shell에서 관리하는 `authorized_keys` 파일입니다.
- `/home/git/gitlab` - GitLab 핵심 소프트웨어입니다.
- `/home/git/gitlab-shell` - GitLab의 핵심 애드온 구성 요소입니다. SSH 복제 및 기타 기능을 유지합니다.
- `/home/git/repositories` - 네임스페이스로 구성된 모든 프로젝트의 베어 리포지토리입니다. 이 디렉터리는 모든 프로젝트에 대해 푸시/풀되는 Git 리포지토리가 유지되는 위치입니다. **이 영역에는 프로젝트의 중요한 데이터가 포함되어 있습니다. [백업 유지](../../administration/backup_restore/_index.md)**.

리포지토리의 기본 위치는 GitLab의 `config/gitlab.yml` 및 GitLab Shell의 `config.yml`에서 구성할 수 있습니다.

지금 이 디렉터리를 수동으로 생성할 필요가 없으며 그렇게 하면 설치 후반에 오류가 발생할 수 있습니다.

## 설치 워크플로 {#installation-workflow}

GitLab 설치는 다음 구성 요소를 설정하는 것으로 구성됩니다:

1. [패키지 및 의존성](#1-packages-and-dependencies).
1. [Ruby](#2-ruby).
1. [RubyGems](#3-rubygems).
1. [Go](#4-go).
1. [Node](#5-node).
1. [시스템 사용자](#6-system-users).
1. [데이터베이스](#7-database).
1. [Redis](#8-redis).
1. [GitLab](#9-gitlab).
1. [NGINX](#10-nginx).

## 1\. 패키지 및 의존성 {#1-packages-and-dependencies}

### sudo {#sudo}

`sudo`은 기본적으로 Debian에 설치되지 않습니다. 시스템이 최신 상태인지 확인하고 설치합니다.

```shell
# run as root!
apt-get update -y
apt-get upgrade -y
apt-get install sudo -y
```

### 빌드 의존성 {#build-dependencies}

필요한 패키지를 설치합니다(Ruby 및 Ruby Gem의 네이티브 확장을 컴파일하는 데 필요):

```shell
sudo apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libre2-dev \
  libreadline-dev libncurses5-dev libffi-dev curl openssh-server libxml2-dev libxslt-dev \
  libcurl4-openssl-dev libicu-dev libkrb5-dev logrotate rsync python3-docutils pkg-config cmake \
  runit-systemd
```

> [!note]
> GitLab에는 OpenSSL 버전 1.1이 필요합니다. Linux 배포판에 다른 버전의 OpenSSL이 포함되어 있으면 1.1을 수동으로 설치해야 할 수 있습니다.

### Git {#git}

[Gitaly에서 제공하는 Git 버전](https://gitlab.com/gitlab-org/gitaly/-/issues/2729)을 사용해야 합니다:

- 항상 GitLab에서 필요한 버전입니다.
- 올바른 작동에 필요한 사용자 정의 패치를 포함할 수 있습니다.

1. 필요한 의존성을 설치합니다:

   ```shell
   sudo apt-get install -y libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev libpcre2-dev build-essential git-core
   ```

1. Gitaly 리포지토리를 복제하고 Git을 컴파일합니다. `<X-Y-stable>`을 설치하려는 GitLab 버전과 일치하는 안정적인 브랜치로 바꿉니다. 예를 들어 GitLab 16.7을 설치하려면 브랜치 이름 `16-7-stable`을 사용합니다:

   ```shell
   git clone https://gitlab.com/gitlab-org/gitaly.git -b <X-Y-stable> /tmp/gitaly
   cd /tmp/gitaly
   sudo make git GIT_PREFIX=/usr/local
   ```

1. 선택적으로 시스템 Git 및 해당 의존성을 제거할 수 있습니다:

   ```shell
   sudo apt remove -y git-core
   sudo apt autoremove
   ```

[`config/gitlab.yml`를 나중에 편집](#configure-it)할 때 Git 경로를 변경하세요:

- From:

  ```yaml
  git:
    bin_path: /usr/bin/git
  ```

- To:

  ```yaml
  git:
    bin_path: /usr/local/bin/git
  ```

### GraphicsMagick {#graphicsmagick}

[사용자 정의 파비콘](../../administration/appearance.md#customize-the-favicon)이 작동하려면 GraphicsMagick을 설치해야 합니다.

```shell
sudo apt-get install -y graphicsmagick
```

### 메일 서버 {#mail-server}

메일 알림을 받으려면 메일 서버를 설치해야 합니다. Debian은 기본적으로 `exim4`와 함께 제공되지만 이것은 [문제가 있으며](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/12754) Ubuntu는 제공되지 않습니다. 권장되는 메일 서버는 `postfix`이며 다음과 같이 설치할 수 있습니다:

```shell
sudo apt-get install -y postfix
```

`Internet Site`을 선택하고 <kbd>Enter</kbd>를 눌러 호스트명을 확인합니다.

### ExifTool {#exiftool}

[GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse#dependencies)는 업로드된 이미지에서 EXIF 데이터를 제거하기 위해 `exiftool`가 필요합니다.

```shell
sudo apt-get install -y libimage-exiftool-perl
```

## 2\. Ruby {#2-ruby}

GitLab을 실행하려면 Ruby 인터프리터가 필요합니다. [요구 사항 섹션](#software-requirements)을 참조하여 최소 Ruby 요구 사항을 확인하세요.

RVM, rbenv 또는 chruby와 같은 Ruby 버전 관리자는 GitLab에 대해 진단하기 어려운 문제를 일으킬 수 있습니다. 대신 공식 소스 코드에서 [Ruby를 설치](https://www.ruby-lang.org/en/documentation/installation/)해야 합니다.

## 3\. RubyGems {#3-rubygems}

때때로 Ruby와 함께 번들로 제공되는 것보다 최신 버전의 RubyGems이 필요합니다.

특정 버전으로 업데이트하려면:

```shell
gem update --system 3.4.12
```

또는 최신 버전:

```shell
gem update --system
```

## 4\. Go {#4-go}

GitLab에는 Go로 작성된 여러 데몬이 있습니다. GitLab을 설치하려면 Go 컴파일러를 설치해야 합니다. 다음 명령어는 64비트 Linux를 사용한다고 가정합니다. [Go 다운로드 페이지](https://go.dev/dl/)에서 다른 플랫폼에 대한 다운로드를 찾을 수 있습니다.

```shell
# Remove former Go installation folder
sudo rm -rf /usr/local/go

curl --remote-name --location --progress-bar "https://go.dev/dl/go1.22.5.linux-amd64.tar.gz"
echo '904b924d435eaea086515bc63235b192ea441bd8c9b198c507e85009e6e4c7f0  go1.22.5.linux-amd64.tar.gz' | shasum -a256 -c - && \
  sudo tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
sudo ln -sf /usr/local/go/bin/{go,gofmt} /usr/local/bin/
rm go1.22.5.linux-amd64.tar.gz
```

## 5\. Node {#5-node}

GitLab은 JavaScript 자산을 컴파일하기 위해 Node를 사용하고 JavaScript 의존성을 관리하기 위해 Yarn을 사용해야 합니다. 현재 최소 요구 사항은 다음과 같습니다:

- `node` 20.x 릴리스(v20.13.0 이상). [Node.js의 다른 LTS 버전](https://github.com/nodejs/release#release-schedule)은 자산을 빌드할 수 있지만 Node.js 20.x만 보장합니다.
- `yarn` = v1.22.x (Yarn 2는 아직 지원되지 않음)

많은 배포판에서 공식 패키지 리포지토리에서 제공하는 버전이 오래되었으므로 다음 명령을 통해 설치해야 합니다:

```shell
# install node v20.x
curl --location "https://deb.nodesource.com/setup_20.x" | sudo bash -
sudo apt-get install -y nodejs

npm install --global yarn
```

이 단계에서 문제가 있으면 [node](https://nodejs.org/en/download) 및 [yarn](https://classic.yarnpkg.com/en/docs/install/)의 공식 웹 사이트를 방문하세요.

## 6\. 시스템 사용자 {#6-system-users}

GitLab용 `git` 사용자를 만듭니다:

```shell
sudo adduser --disabled-login --gecos 'GitLab' git
```

## 7\. 데이터베이스 {#7-database}

> [!note]
> PostgreSQL만 지원됩니다. GitLab 18.0 이상에서는 [PostgreSQL 16+ 필요](../requirements.md#postgresql)합니다.

1. 데이터베이스 패키지를 설치합니다.

   Ubuntu 22.04 이상:

   ```shell
   sudo apt install -y postgresql postgresql-client libpq-dev postgresql-contrib
   ```

   Ubuntu 20.04 이전의 경우 사용 가능한 PostgreSQL이 최소 버전 요구 사항을 충족하지 않습니다. PostgreSQL의 리포지토리를 추가해야 합니다:

   ```shell
   sudo curl --fail --silent --show-error --output /etc/apt/keyrings/postgresql.asc \
             --url "https://www.postgresql.org/media/keys/ACCC4CF8.asc"
   echo "deb [ signed-by=/etc/apt/keyrings/postgresql.asc ] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" |
        sudo tee /etc/apt/sources.list.d/pgdg.list
   sudo apt-get update
   sudo apt-get -y install postgresql-16
   ```

1. 설치 중인 GitLab 버전에서 지원하는 PostgreSQL 버전을 확인합니다:

   ```shell
   psql --version
   ```

1. PostgreSQL 서비스를 시작하고 서비스가 실행 중임을 확인합니다:

   ```shell
   sudo service postgresql start
   sudo service postgresql status
   ```

1. GitLab용 데이터베이스 사용자를 만듭니다:

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE USER git CREATEDB;"
   ```

1. `pg_trgm` 확장을 만듭니다:

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
   ```

1. `btree_gist` 확장을 만듭니다:

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS btree_gist;"
   ```

1. `plpgsql` 확장을 만듭니다:

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS plpgsql;"
   ```

1. GitLab 프로덕션 데이터베이스를 만들고 데이터베이스의 모든 권한을 부여합니다:

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;"
   ```

1. 새 사용자로 새 데이터베이스에 연결을 시도합니다:

   ```shell
   sudo -u git -H psql -d gitlabhq_production
   ```

1. `pg_trgm` 확장이 활성화되어 있는지 확인합니다:

   ```sql
   SELECT true AS enabled
   FROM pg_available_extensions
   WHERE name = 'pg_trgm'
   AND installed_version IS NOT NULL;
   ```

   확장이 활성화되면 다음 출력이 생성됩니다:

   ```plaintext
   enabled
   ---------
    t
   (1 row)
   ```

1. `btree_gist` 확장이 활성화되어 있는지 확인합니다:

   ```sql
   SELECT true AS enabled
   FROM pg_available_extensions
   WHERE name = 'btree_gist'
   AND installed_version IS NOT NULL;
   ```

   확장이 활성화되면 다음 출력이 생성됩니다:

   ```plaintext
   enabled
   ---------
    t
   (1 row)
   ```

1. `plpgsql` 확장이 활성화되어 있는지 확인합니다:

   ```sql
   SELECT true AS enabled
   FROM pg_available_extensions
   WHERE name = 'plpgsql'
   AND installed_version IS NOT NULL;
   ```

   확장이 활성화되면 다음 출력이 생성됩니다:

   ```plaintext
   enabled
   ---------
    t
   (1 row)
   ```

1. 데이터베이스 세션을 종료합니다:

   ```shell
   gitlabhq_production> \q
   ```

## 8\. Redis {#8-redis}

[요구 사항 페이지](../requirements.md#redis-or-valkey)에서 최소 Redis 요구 사항을 확인하세요.

Redis를 설치합니다:

```shell
sudo apt-get install redis-server
```

완료되면 Redis를 구성할 수 있습니다:

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

### systemd를 사용하여 Redis 감시 {#supervise-redis-with-systemd}

배포판에서 systemd init를 사용하고 다음 명령의 출력이 `notify`이면 변경하면 안 됩니다:

```shell
systemctl show --value --property=Type redis-server.service
```

출력이 `notify`이 아니면 다음을 실행합니다:

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

### Redis를 감시하지 않은 상태로 두기 {#leave-redis-unsupervised}

시스템에서 SysV init을 사용하면 이 명령을 실행합니다:

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

## 9\. GitLab {#9-gitlab}

```shell
# We'll install GitLab into the home directory of the user "git"
cd /home/git
```

### 소스 복제 {#clone-the-source}

Community Edition을 복제합니다:

```shell
# Clone GitLab repository
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-foss.git -b <X-Y-stable> gitlab
```

Enterprise Edition을 복제합니다:

```shell
# Clone GitLab repository
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab.git -b <X-Y-stable-ee> gitlab
```

`<X-Y-stable>`을 설치하려는 버전과 일치하는 안정적인 브랜치로 바꿉니다. 예를 들어 11.8을 설치하려면 브랜치 이름 `11-8-stable`을 사용합니다.

> [!warning]
> `<X-Y-stable>`을 "출혈 가장자리" 버전을 원하면 `master`로 변경할 수 있지만 프로덕션 서버에 `master`를 설치하지 마세요!

### 구성 {#configure-it}

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

`gitlab.yml` 및 `puma.rb`을 편집하여 설정과 일치하도록 해야 합니다.

HTTPS를 사용하려면 [HTTPS 사용](#using-https)을 참조하여 추가 단계를 수행하세요.

### GitLab DB 설정 구성 {#configure-gitlab-db-settings}

> [!note]
> [GitLab 15.9](https://gitlab.com/gitlab-org/gitlab/-/issues/387898)부터 `database.yml`에는 `main:` 섹션만 포함되어 있으므로 더 이상 사용되지 않습니다. GitLab 17.0 이상에서는 `main:` 및 `ci:` 두 섹션이 `database.yml`에 있어야 합니다.

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

`database.yml`에는 `main:` 및 `ci:` 두 섹션이 있어야 합니다. `ci`: 연결은 [같은 데이터베이스여야 합니다](../../administration/postgresql/_index.md).

### Gem 설치 {#install-gems}

> [!note]
> Bundler 1.5.2부터 `bundle install -jN`을 호출할 수 있습니다(여기서 `N`은 프로세서 코어 수)이고 측정 가능한 완료 시간 차이(~60% 더 빠름)로 병렬 Gem 설치를 즐깁니다. `nproc`로 코어 수를 확인합니다. 자세한 내용은 이 [게시물](https://thoughtbot.com/blog/parallel-gem-installing-using-bundler)을 참조하세요.

`bundle`이 있는지 확인합니다(`bundle -v` 실행):

- `>= 1.5.2`, [이슈](https://devcenter.heroku.com/changelog-items/411)는 [1.5.2에서 수정](https://github.com/rubygems/bundler/pull/2817)되었기 때문입니다.
- `< 2.x`.

Gem을 설치합니다(Kerberos를 사용자 인증에 사용하려면 다음 명령에서 `--without` 옵션에서 `kerberos`을 생략합니다):

```shell
sudo -u git -H bundle config set --local deployment 'true'
sudo -u git -H bundle config set --local without 'development test kerberos'
sudo -u git -H bundle config path /home/git/gitlab/vendor/bundle
sudo -u git -H bundle install
```

### GitLab Shell 설치 {#install-gitlab-shell}

GitLab Shell은 GitLab용으로 특별히 개발된 SSH 액세스 및 리포지토리 관리 소프트웨어입니다.

```shell
# Run the installation task for gitlab-shell:
sudo -u git -H bundle exec rake gitlab:shell:install RAILS_ENV=production

# By default, the gitlab-shell config is generated from your main GitLab config.
# You can review (and modify) the gitlab-shell config as follows:
sudo -u git -H editor /home/git/gitlab-shell/config.yml
```

HTTPS를 사용하려면 [HTTPS 사용](#using-https)을 참조하여 추가 단계를 수행하세요.

호스트명이 `/etc/hosts`("127.0.0.1 hostname")에 추가 줄을 통해 적절한 DNS 레코드 또는 인 바이 머신 자체에서 확인할 수 있는지 확인하세요. 예를 들어 GitLab을 역방향 프록시 뒤에 설정한 경우 필요할 수 있습니다. 호스트명을 확인할 수 없으면 최종 설치 확인이 `Check GitLab API access: FAILED. code: 401`으로 실패하고 커밋을 푸시하면 `[remote rejected] master -> master (hook declined)`이 거부됩니다.

### GitLab Workhorse 설치 {#install-gitlab-workhorse}

GitLab-Workhorse는 [GNU Make](https://www.gnu.org/software/make/)를 사용합니다. 다음 명령줄은 `/home/git/gitlab-workhorse`에 GitLab-Workhorse를 설치하는데, 이것이 권장되는 위치입니다.

```shell
sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
```

추가 매개 변수로 제공하여 다른 Git 리포지토리를 지정할 수 있습니다:

```shell
sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse,https://example.com/gitlab-workhorse.git]" RAILS_ENV=production
```

### Enterprise Edition에 GitLab-Elasticsearch-인덱서 설치 {#install-gitlab-elasticsearch-indexer-on-enterprise-edition}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab-Elasticsearch-Indexer는 [GNU Make](https://www.gnu.org/software/make/)를 사용합니다. 다음 명령줄은 `/home/git/gitlab-elasticsearch-indexer`에 GitLab-Elasticsearch-Indexer를 설치하는데, 이것이 권장되는 위치입니다.

```shell
sudo -u git -H bundle exec rake "gitlab:indexer:install[/home/git/gitlab-elasticsearch-indexer]" RAILS_ENV=production
```

추가 매개 변수로 제공하여 다른 Git 리포지토리를 지정할 수 있습니다:

```shell
sudo -u git -H bundle exec rake "gitlab:indexer:install[/home/git/gitlab-elasticsearch-indexer,https://example.com/gitlab-elasticsearch-indexer.git]" RAILS_ENV=production
```

소스 코드는 먼저 첫 번째 매개 변수로 지정된 경로로 가져와집니다. 그런 다음 이진 파일이 해당 `bin` 디렉터리 아래에 빌드됩니다. 그런 다음 `gitlab.yml`의 `production -> elasticsearch -> indexer_path` 설정을 해당 이진 파일을 가리키도록 업데이트해야 합니다.

### GitLab Pages 설치 {#install-gitlab-pages}

GitLab Pages는 [GNU Make](https://www.gnu.org/software/make/)를 사용합니다. 이 단계는 선택 사항이며 GitLab 내에서 정적 사이트를 호스팅하려는 경우에만 필요합니다. 다음 명령은 `/home/git/gitlab-pages`에 GitLab Pages를 설치합니다. 추가 설정 단계는 GitLab Pages 데몬을 여러 가지 방식으로 실행할 수 있으므로 GitLab 버전의 [관리 가이드](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/pages/source.md)를 참조하세요.

```shell
cd /home/git
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
cd gitlab-pages
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
sudo -u git -H make
```

### Gitaly 설치 {#install-gitaly}

```shell
# Create and restrict access to the git repository data directory
sudo install -d -o git -m 0700 /home/git/repositories

# Fetch Gitaly source with Git and compile with Go
cd /home/git/gitlab
sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production
```

추가 매개 변수로 제공하여 다른 Git 리포지토리를 지정할 수 있습니다:

```shell
sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories,https://example.com/gitaly.git]" RAILS_ENV=production
```

다음으로 Gitaly가 구성되어 있는지 확인합니다:

```shell
# Restrict Gitaly socket access
sudo chmod 0700 /home/git/gitlab/tmp/sockets/private
sudo chown git /home/git/gitlab/tmp/sockets/private

# If you are using non-default settings, you need to update config.toml
cd /home/git/gitaly
sudo -u git -H editor config.toml
```

Gitaly를 구성하는 방법에 대한 자세한 내용은 [Gitaly 문서](../../administration/gitaly/_index.md)를 참조하세요.

### 서비스 설치 {#install-the-service}

GitLab은 항상 SysV 초기화 스크립트를 지원했으며, 이는 널리 지원되고 이식 가능하지만 이제 systemd는 서비스 감시의 표준이며 모든 주요 Linux 배포판에서 사용됩니다. 자동 다시 시작, 더 나은 샌드박싱 및 리소스 제어의 이점을 얻으려면 가능한 경우 기본 systemd 서비스를 사용해야 합니다.

#### systemd 단위 설치 {#install-systemd-units}

systemd를 init로 사용하는 경우 이 단계를 따르세요. 그렇지 않으면 [SysV 초기화 스크립트 단계](#install-sysv-init-script)를 따르세요.

서비스를 복사하고 `systemctl daemon-reload`을 실행하여 systemd가 선택하도록 합니다:

```shell
cd /home/git/gitlab
sudo mkdir -p /usr/local/lib/systemd/system
sudo cp lib/support/systemd/* /usr/local/lib/systemd/system/
sudo systemctl daemon-reload
```

GitLab에서 제공하는 단위는 Redis와 PostgreSQL을 실행 중인 위치에 대해 거의 가정하지 않습니다.

GitLab을 다른 디렉터리에 설치했거나 기본값이 아닌 사용자로 설치한 경우 단위에서 이 값도 변경해야 합니다.

예를 들어 GitLab과 같은 머신에서 Redis 및 PostgreSQL을 실행하는 경우 다음을 수행해야 합니다:

- Puma 서비스 편집:

  ```shell
  sudo systemctl edit gitlab-puma.service
  ```

  열리는 편집기에 다음을 추가하고 파일을 저장합니다:

  ```plaintext
  [Unit]
  Wants=redis-server.service postgresql.service
  After=redis-server.service postgresql.service
  ```

- Sidekiq 서비스 편집:

  ```shell
  sudo systemctl edit gitlab-sidekiq.service
  ```

  다음을 추가하고 파일을 저장합니다:

  ```plaintext
  [Unit]
  Wants=redis-server.service postgresql.service
  After=redis-server.service postgresql.service
  ```

`systemctl edit`은 `/etc/systemd/system/<name of the unit>.d/override.conf`에서 드롭인 구성 파일을 설치하므로 나중에 단위 파일을 업데이트할 때 로컬 구성이 덮어써지지 않습니다. 드롭인 구성 파일을 분할하려면 이전 스니펫을 `/etc/systemd/system/<name of the unit>.d/` 아래의 `.conf` 파일에 추가할 수 있습니다.

단위 파일을 수동으로 변경했거나 드롭인 구성 파일을 추가한 경우(`systemctl edit`를 사용하지 않음) 다음 명령을 실행하여 변경 사항을 적용합니다:

```shell
sudo systemctl daemon-reload
```

GitLab이 부팅 시 시작되도록 합니다:

```shell
sudo systemctl enable gitlab.target
```

#### SysV 초기화 스크립트 설치 {#install-sysv-init-script}

SysV 초기화 스크립트를 사용하는 경우 이 단계를 따르세요. systemd를 사용하는 경우 [systemd 단위 단계](#install-systemd-units)를 따르세요.

초기화 스크립트를 다운로드합니다(`/etc/init.d/gitlab`):

```shell
cd /home/git/gitlab
sudo cp lib/support/init.d/gitlab /etc/init.d/gitlab
```

비표준 폴더 또는 사용자로 설치하는 경우 기본값 파일을 복사하고 편집합니다:

```shell
sudo cp lib/support/init.d/gitlab.default.example /etc/default/gitlab
```

GitLab을 다른 디렉터리에 설치했거나 기본값이 아닌 사용자로 설치한 경우 `/etc/default/gitlab`에서 이 설정을 변경해야 합니다. 업그레이드할 때 변경되므로 `/etc/init.d/gitlab`을 편집하지 마세요.

GitLab이 부팅 시 시작되도록 합니다:

```shell
sudo update-rc.d gitlab defaults 21
# or if running this on a machine running systemd
sudo systemctl daemon-reload
sudo systemctl enable gitlab.service
```

### Logrotate 설정 {#set-up-logrotate}

```shell
sudo cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab
```

### Gitaly 시작 {#start-gitaly}

Gitaly는 다음 섹션에서 실행되어야 합니다.

- systemd를 사용하여 Gitaly를 시작하려면:

  ```shell
  sudo systemctl start gitlab-gitaly.service
  ```

- SysV에서 Gitaly를 수동으로 시작하려면:

  ```shell
  gitlab_path=/home/git/gitlab
  gitaly_path=/home/git/gitaly

  sudo -u git -H sh -c "$gitlab_path/bin/daemon_with_pidfile $gitlab_path/tmp/pids/gitaly.pid \
    $gitaly_path/_build/bin/gitaly $gitaly_path/config.toml >> $gitlab_path/log/gitaly.log 2>&1 &"
  ```

### 데이터베이스 초기화 및 고급 기능 활성화 {#initialize-database-and-activate-advanced-features}

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production
# Type 'yes' to create the database tables.

# or you can skip the question by adding force=yes
sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production force=yes

# When done, you see 'Administrator account created:'
```

환경 변수 `GITLAB_ROOT_PASSWORD` 및 `GITLAB_ROOT_EMAIL`를 제공하여 Administrator/root 비밀번호 및 이메일을 설정할 수 있습니다(다음 명령에서 보듯이). 비밀번호를 설정하지 않으면(기본값으로 설정된 경우) 설치가 완료되고 서버에 처음 로그인할 때까지 GitLab을 공개 인터넷에 노출하기를 기다립니다. 첫 번째 로그인 중에 기본 비밀번호를 변경하도록 강제됩니다. Enterprise Edition 구독은 `GITLAB_ACTIVATION_CODE` 환경 변수에 활성화 코드를 제공하여 이 시점에 활성화될 수도 있습니다.

```shell
sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production GITLAB_ROOT_PASSWORD=yourpassword GITLAB_ROOT_EMAIL=youremail GITLAB_ACTIVATION_CODE=yourcode
```

### `secrets.yml` 보안 {#secure-secretsyml}

`secrets.yml` 파일은 세션 및 보안 변수에 대한 암호화 키를 저장합니다. `secrets.yml`를 안전한 장소에 백업하되 데이터베이스 백업과 같은 장소에 저장하지 마세요. 그렇지 않으면 백업 중 하나가 손상되면 비밀번호가 노출됩니다.

### 애플리케이션 상태 확인 {#check-application-status}

GitLab 및 해당 환경이 올바르게 구성되었는지 확인합니다:

```shell
sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

### 자산 컴파일 {#compile-assets}

```shell
sudo -u git -H yarn install --production --pure-lockfile
sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production
```

`rake`이 `JavaScript heap out of memory` 오류로 실패하면 `NODE_OPTIONS`을 다음과 같이 설정하여 실행을 시도합니다.

```shell
sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=4096"
```

### GitLab 인스턴스 시작 {#start-your-gitlab-instance}

```shell
# For systems running systemd
sudo systemctl start gitlab.target

# For systems running SysV init
sudo service gitlab start
```

## 10\. NGINX {#10-nginx}

NGINX는 GitLab용 공식 지원 웹 서버입니다. NGINX를 웹 서버로 사용할 수 없거나 사용하지 않으려면 [GitLab 레시피](https://gitlab.com/gitlab-org/gitlab-recipes/)를 참조하세요.

### 설치 {#installation}

```shell
sudo apt-get install -y nginx
```

### 사이트 구성 {#site-configuration}

예제 사이트 구성을 복사합니다:

```shell
sudo cp lib/support/nginx/gitlab /etc/nginx/sites-available/gitlab
sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab
```

구성 파일을 편집하여 설정과 일치하도록 해야 합니다. 또한 특히 `git` 사용자가 아닌 사용자로 설치하는 경우 경로가 GitLab과 일치하는지 확인합니다:

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

GitLab Pages를 활성화하려면 사용해야 할 별도의 NGINX 구성이 있습니다. [GitLab Pages 관리 가이드](../../administration/pages/_index.md)에서 필요한 구성에 대해 읽어보세요.

HTTPS를 사용하려면 `gitlab` NGINX 구성을 `gitlab-ssl`로 바꿉니다. [HTTPS 사용](#using-https)을 참조하여 HTTPS 구성 세부 정보를 확인하세요.

NGINX가 GitLab-Workhorse 소켓을 읽을 수 있도록 하려면 `www-data` 사용자가 GitLab 사용자가 소유한 소켓을 읽을 수 있는지 확인해야 합니다. 이것은 예를 들어 권한이 `0755`인 경우 세계 읽기 가능하면 달성됩니다(기본값). `www-data`도 부모 디렉터리를 나열할 수 있어야 합니다.

### 구성 테스트 {#test-configuration}

`gitlab` 또는 `gitlab-ssl` NGINX 구성 파일을 다음 명령으로 검증합니다:

```shell
sudo nginx -t
```

`syntax is okay` 및 `test is successful` 메시지를 받아야 합니다. 오류 메시지가 나타나면 제공된 오류 메시지에 표시된 대로 `gitlab` 또는 `gitlab-ssl` NGINX 구성 파일의 오타를 확인합니다.

설치된 버전이 1.12.1보다 큰지 확인합니다:

```shell
nginx -v
```

더 낮으면 다음 오류가 나타날 수 있습니다:

```plaintext
nginx: [emerg] unknown "start$temp=[filtered]$rest" variable
nginx: configuration file /etc/nginx/nginx.conf test failed
```

### 다시 시작 {#restart}

```shell
# For systems running systemd
sudo systemctl restart nginx.service

# For systems running SysV init
sudo service nginx restart
```

## 설치 후 {#post-install}

### 애플리케이션 상태 다시 확인 {#double-check-application-status}

놓친 것이 없는지 확인하려면 더 철저한 검사를 실행합니다:

```shell
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

모든 항목이 녹색이면 GitLab 설치를 성공적으로 축하합니다!

> [!note]
> `gitlab:check`에서 `SANITIZE=true` 환경 변수를 제공하여 확인 명령의 출력에서 프로젝트 이름을 생략합니다.

### 초기 로그인 {#initial-login}

웹 브라우저에서 YOUR_SERVER를 방문하여 첫 번째 GitLab 로그인을 수행합니다.

[설정 중에 루트 비밀번호를 제공](#initialize-database-and-activate-advanced-features)하지 않으면 비밀번호 재설정 화면으로 리디렉션되어 초기 관리자 계정의 비밀번호를 제공합니다. 원하는 비밀번호를 입력하고 로그인 화면으로 다시 리디렉션됩니다.

기본 계정의 사용자명은 **root**입니다. 이전에 만든 비밀번호를 제공하고 로그인합니다. 로그인 후 원하면 사용자명을 변경할 수 있습니다.

**Enjoy!**

GitLab을 시작하고 중지할 때:

- systemd 단위: `sudo systemctl start gitlab.target` 또는 `sudo systemctl stop gitlab.target`을 사용합니다.
- SysV 초기화 스크립트: `sudo service gitlab start` 또는 `sudo service gitlab stop`을 사용합니다.

### 권장되는 다음 단계 {#recommended-next-steps}

설치를 완료한 후 [권장되는 다음 단계](../next_steps.md)를 수행하는 것을 고려하세요(인증 옵션 및 새 사용자 계정 제한 포함).

## 고급 설정 팁 {#advanced-setup-tips}

### 상대 URL 지원 {#relative-url-support}

[상대 URL 문서](../relative_url.md)를 참조하여 상대 URL로 GitLab을 구성하는 방법에 대해 자세히 알아보세요.

### HTTPS 사용 {#using-https}

HTTPS로 GitLab을 사용하려면:

1. `gitlab.yml`:
   1. `port` 옵션을 섹션 1에서 `443`로 설정합니다.
   1. `https` 옵션을 섹션 1에서 `true`로 설정합니다.
1. GitLab Shell의 `config.yml`:
   1. `gitlab_url` 옵션을 GitLab의 HTTPS 엔드포인트(예: `https://git.example.com`)로 설정합니다.
   1. `ca_file` 또는 `ca_path` 옵션 중 하나를 사용하여 인증서를 설정합니다.
1. `gitlab` 구성 대신 `gitlab-ssl` NGINX 예제 구성을 사용합니다.
   1. `YOUR_SERVER_FQDN`을 업데이트합니다.
   1. `ssl_certificate` 및 `ssl_certificate_key`을 업데이트합니다.
   1. 구성 파일을 검토하고 다른 보안 및 성능 강화 기능을 적용하는 것을 고려합니다.

자체 서명 인증서 사용은 권장되지 않습니다. 반드시 사용해야 하는 경우 표준 방향을 따르고 자체 서명 SSL 인증서를 생성합니다:

   ```shell
   mkdir -p /etc/nginx/ssl/
   cd /etc/nginx/ssl/
   sudo openssl req -newkey rsa:2048 -x509 -nodes -days 3560 -out gitlab.crt -keyout gitlab.key
   sudo chmod o-r gitlab.key
   ```

### 이메일로 회신 사용 {#enable-reply-by-email}

["이메일로 회신" 문서](../../administration/reply_by_email.md)를 참조하여 설정 방법에 대해 자세히 알아보세요.

### LDAP 인증 {#ldap-authentication}

`config/gitlab.yml`에서 LDAP 인증을 구성할 수 있습니다. 이 파일을 편집한 후 GitLab을 다시 시작합니다.

### 사용자 정의 OmniAuth 공급자 사용 {#using-custom-omniauth-providers}

[OmniAuth 통합 문서](../../integration/omniauth.md)를 참조하세요.

### 프로젝트 빌드 {#build-your-projects}

GitLab은 프로젝트를 빌드할 수 있습니다. 이 기능을 활성화하려면 러너가 필요합니다. [GitLab Runner 섹션](https://docs.gitlab.com/runner/)을 참조하여 설치하세요.

### 신뢰할 수 있는 프록시 추가 {#adding-your-trusted-proxies}

별도의 머신에서 역방향 프록시를 사용하는 경우 프록시를 신뢰할 수 있는 프록시 목록에 추가할 수 있습니다. 그렇지 않으면 사용자가 프록시의 IP 주소에서 로그인한 것으로 나타납니다.

`config/gitlab.yml`에서 신뢰할 수 있는 프록시를 추가할 수 있습니다. 섹션 1에서 `trusted_proxies` 옵션을 사용자 정의합니다. 파일을 저장하고 [GitLab을 다시 구성](../../administration/restart_gitlab.md)하여 변경 사항이 적용되도록 합니다.

URL에서 부정확하게 인코딩된 문자 문제가 발생하면 [오류: `404 Not Found` 역방향 프록시 사용](../../api/rest/troubleshooting.md#error-404-not-found-when-using-a-reverse-proxy)을 참조하세요.

### 사용자 정의 Redis 연결 {#custom-redis-connection}

비표준 포트 또는 다른 호스트에서 Redis 서버에 연결하려면 `config/resque.yml` 파일을 통해 연결 문자열을 구성할 수 있습니다.

```yaml
# example
production:
  url: redis://redis.example.tld:6379
```

Redis 서버를 소켓을 통해 연결하려면 `unix:` URL 체계를 사용하고 `config/resque.yml` 파일의 Redis 소켓 파일 경로를 사용합니다.

```yaml
# example
production:
  url: unix:/path/to/redis/socket
```

`config/resque.yml` 파일에서 환경 변수를 사용할 수 있습니다:

```yaml
# example
production:
  url: <%= ENV.fetch('GITLAB_REDIS_URL') %>
```

### 사용자 정의 SSH 연결 {#custom-ssh-connection}

비표준 포트에서 SSH를 실행 중인 경우 GitLab 사용자의 SSH 구성을 변경해야 합니다.

```plaintext
# Add to /home/git/.ssh/config
host localhost          # Give your setup a name (here: override localhost)
    user git            # Your remote git user
    port 2222           # Your port number
    hostname 127.0.0.1; # Your server name or IP
```

또한 `config/gitlab.yml` 파일에서 해당 옵션(예: `ssh_user`, `ssh_host`, `admin_uri`)을 변경해야 합니다.

### 추가 마크업 스타일 {#additional-markup-styles}

항상 지원되는 Markdown 스타일 외에도 GitLab이 표시할 수 있는 다른 리치 텍스트 파일이 있습니다. 그러나 이를 수행하려면 의존성을 설치해야 할 수 있습니다. [`github-markup` Gem README](https://github.com/gitlabhq/markup#markups)를 참조하여 자세한 내용을 알아보세요.

### Prometheus 서버 설정 {#prometheus-server-setup}

`config/gitlab.yml`에서 Prometheus 서버를 구성할 수 있습니다:

```yaml
# example
prometheus:
  enabled: true
  server_address: '10.1.2.3:9090'
```

## 문제 해결 {#troubleshooting}

### 메시지: `You appear to have cloned an empty repository.` {#message-you-appear-to-have-cloned-an-empty-repository}

GitLab에서 호스팅하는 리포지토리를 복제하려고 할 때 이 메시지가 표시되면 이전 NGINX 또는 Apache 구성이거나 누락되거나 잘못 구성된 GitLab Workhorse 인스턴스 때문일 가능성이 높습니다. [Go를 설치](#4-go)했으며 [GitLab Workhorse를 설치](#install-gitlab-workhorse)했고 [NGINX를 올바르게 구성](#site-configuration)했는지 확인합니다.

### `google-protobuf` 오류: `LoadError: /lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.14' not found` {#google-protobuf-error-loaderror-libx86_64-linux-gnulibcso6-version-glibc_214-not-found}

이것은 일부 플랫폼에서 `google-protobuf` Gem의 일부 버전에 대해 발생할 수 있습니다. 해결 방법은 이 Gem의 소스 전용 버전을 설치하는 것입니다.

먼저 GitLab 설치에 필요한 `google-protobuf`의 정확한 버전을 찾아야 합니다:

```shell
cd /home/git/gitlab

# Only one of the following two commands will print something. It
# will look like: * google-protobuf (3.2.0)
bundle list | grep google-protobuf
bundle check | grep google-protobuf
```

다음 명령에서 `3.2.0`이 예제로 사용됩니다. 이전에 찾은 버전 번호로 바꿉니다:

```shell
cd /home/git/gitlab
sudo -u git -H gem install google-protobuf --version 3.2.0 --platform ruby
```

마지막으로 `google-protobuf`이 올바르게 로드되는지 테스트할 수 있습니다. 다음은 `OK`을 인쇄해야 합니다.

```shell
sudo -u git -H bundle exec ruby -rgoogle/protobuf -e 'puts :OK'
```

`gem install` 명령이 실패하면 OS의 개발자 도구를 설치해야 할 수 있습니다.

Debian/Ubuntu:

```shell
sudo apt-get install build-essential libgmp-dev
```

RedHat/CentOS:

```shell
sudo yum groupinstall 'Development Tools'
```

### GitLab 자산 컴파일 오류 {#error-compiling-gitlab-assets}

자산을 컴파일하는 동안 다음 오류 메시지가 표시될 수 있습니다:

```plaintext
Killed
error Command failed with exit code 137.
```

이것은 Yarn이 메모리 부족 상태에서 실행되는 컨테이너를 종료할 때 발생할 수 있습니다. 이를 해결하려면:

1. 시스템 메모리를 최소 8GB로 늘립니다.
1. 다음 명령을 실행하여 자산을 정리합니다:

   ```shell
   sudo -u git -H bundle exec rake gitlab:assets:clean RAILS_ENV=production NODE_ENV=production
   ```

1. `yarn` 명령을 다시 실행하여 충돌을 해결합니다:

   ```shell
   sudo -u git -H yarn install --production --pure-lockfile
   ```

1. 자산을 다시 컴파일합니다:

   ```shell
   sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production
   ```

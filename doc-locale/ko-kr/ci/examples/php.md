---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PHP 프로젝트 테스트
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 가이드는 PHP 프로젝트의 기본 빌드 지침을 다룹니다.

Docker 실행기와 Shell 실행기를 사용하는 두 가지 테스트 시나리오를 다룹니다.

## Docker 실행기를 사용하여 PHP 프로젝트 테스트 {#test-php-projects-using-the-docker-executor}

PHP 앱을 모든 시스템에서 테스트할 수는 있지만 개발자의 수동 구성이 필요합니다. Docker Hub에서 찾을 수 있는 공식 [PHP Docker 이미지](https://hub.docker.com/_/php)를 사용하여 이를 해결할 수 있습니다.

이를 통해 다양한 PHP 버전에 대해 PHP 프로젝트를 테스트할 수 있습니다. 그러나 여전히 일부를 수동으로 구성해야 합니다.

모든 작업과 마찬가지로 빌드 환경을 설명하는 유효한 `.gitlab-ci.yml`를 만들어야 합니다.

먼저 작업 프로세스에 사용되는 PHP 이미지를 지정합니다. (러너의 용어로 이미지가 의미하는 바에 대해 [Docker 이미지 사용](../docker/using_docker_images.md#what-is-an-image)에 대해 읽을 수 있습니다.)

`.gitlab-ci.yml`에 이미지를 추가하여 시작하세요:

```yaml
image: php:5.6
```

공식 이미지는 훌륭하지만 몇 가지 테스트 도구가 부족합니다. 먼저 빌드 환경을 준비해야 합니다. 이를 위해 실제 테스트가 시작되기 전에 모든 필수 항목을 설치하는 스크립트를 만듭니다.

리포지토리의 루트 디렉터리에 `ci/docker_install.sh` 파일을 다음 내용으로 만듭니다:

```shell
#!/bin/bash

# You need to install dependencies only for Docker
[[ ! -e /.dockerenv ]] && exit 0

set -xe

# Install git (the php image doesn't have it) which is required by composer
apt-get update -yqq
apt-get install git -yqq

# Install phpunit, the tool that you will use for testing
curl --location --output /usr/local/bin/phpunit "https://phar.phpunit.de/phpunit.phar"
chmod +x /usr/local/bin/phpunit

# Install mysql driver
# Here you can install any other extension that you need
docker-php-ext-install pdo_mysql
```

`docker-php-ext-install`이 무엇인지 궁금할 수도 있습니다. 간단히 말해서, 공식 PHP Docker 이미지에서 제공하는 확장 프로그램을 설치하는 데 사용할 수 있는 스크립트입니다. 자세한 내용은 [설명서](https://hub.docker.com/_/php)를 읽으세요.

이제 빌드 환경에 대한 필수 항목을 포함하는 스크립트를 만들었으므로 `.gitlab-ci.yml`에 추가할 수 있습니다:

```yaml
before_script:
  - bash ci/docker_install.sh > /dev/null
```

마지막 단계로 `phpunit`를 사용하여 실제 테스트를 실행합니다:

```yaml
test:app:
  script:
    - phpunit --configuration phpunit_myapp.xml
```

마지막으로 파일을 커밋하고 GitLab으로 푸시하여 빌드가 성공하는지(또는 실패하는지) 확인합니다.

최종 `.gitlab-ci.yml`는 다음과 같이 표시되어야 합니다:

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

### Docker 빌드에서 다양한 PHP 버전에 대해 테스트 {#test-against-different-php-versions-in-docker-builds}

다양한 PHP 버전에 대해 테스트하는 것은 매우 쉽습니다. 다른 Docker 이미지 버전으로 다른 작업을 추가하면 러너가 나머지를 처리합니다:

```yaml
default:
  before_script:
    # Install dependencies
    - bash ci/docker_install.sh > /dev/null

# Test PHP5.6
test:5.6:
  image: php:5.6
  script:
    - phpunit --configuration phpunit_myapp.xml

# Test PHP7.0 (good luck with that)
test:7.0:
  image: php:7.0
  script:
    - phpunit --configuration phpunit_myapp.xml
```

### Docker 빌드에서 PHP 구성 커스터마이징 {#custom-php-configuration-in-docker-builds}

`.ini` 파일을 `/usr/local/etc/php/conf.d/`에 배치하여 PHP 환경을 커스터마이징해야 할 때가 있습니다. 이 목적을 위해 `before_script` 작업을 추가합니다:

```yaml
before_script:
  - cp my_php.ini /usr/local/etc/php/conf.d/test.ini
```

물론 `my_php.ini`는 리포지토리의 루트 디렉터리에 있어야 합니다.

## Shell 실행기를 사용하여 PHP 프로젝트 테스트 {#test-php-projects-using-the-shell-executor}

Shell 실행기는 서버의 터미널 세션에서 작업을 실행합니다. 프로젝트를 테스트하려면 먼저 모든 종속성이 설치되어 있는지 확인해야 합니다.

예를 들어 Debian 8을 실행하는 VM에서 먼저 캐시를 업데이트한 다음 `phpunit`과 `php5-mysql`를 설치합니다:

```shell
sudo apt-get update -y
sudo apt-get install -y phpunit php5-mysql
```

다음으로 다음 스니펫을 `.gitlab-ci.yml`에 추가합니다:

```yaml
test:app:
  script:
    - phpunit --configuration phpunit_myapp.xml
```

마지막으로 GitLab으로 푸시하고 테스트를 시작하세요!

### Shell 빌드에서 다양한 PHP 버전에 대해 테스트 {#test-against-different-php-versions-in-shell-builds}

[phpenv](https://github.com/phpenv/phpenv) 프로젝트는 각각의 자체 구성을 가진 다양한 PHP 버전을 관리할 수 있습니다. 이는 Shell 실행기로 PHP 프로젝트를 테스트할 때 특히 유용합니다.

빌드 머신의 `gitlab-runner` 사용자 아래에 설치해야 하고 [업스트림 설치 가이드](https://github.com/phpenv/phpenv#installation)를 따릅니다.

phpenv를 사용하면 다음을 사용하여 PHP 환경을 구성할 수도 있습니다:

```shell
phpenv config-add my_config.ini
```

**Important note**: `phpenv/phpenv` [는 중단된 것으로 보입니다](https://github.com/phpenv/phpenv/issues/57). [`madumlao/phpenv`](https://github.com/madumlao/phpenv)의 포크가 있으며, 이는 프로젝트를 다시 활성화하려고 시도합니다. [`CHH/phpenv`](https://github.com/CHH/phpenv)도 좋은 대안으로 보입니다. 언급된 도구 중 하나를 선택하면 기본 phpenv 명령과 작동합니다. 올바른 phpenv를 선택하도록 안내하는 것은 이 자습서의 범위를 벗어납니다.*

### 사용자 정의 확장 설치 {#install-custom-extensions}

이는 PHP 환경의 상당히 기본적인 설치이므로 빌드 머신에 현재 없는 일부 확장이 필요할 수 있습니다.

추가 확장을 설치하려면 다음을 실행합니다:

```shell
pecl install <extension>
```

`.gitlab-ci.yml`에 이를 추가하는 것은 권장되지 않습니다. 빌드 환경을 설정하기 위해 이 명령을 한 번만 실행해야 합니다.

## 테스트 확장 {#extend-your-tests}

### `atoum` 사용 {#using-atoum}

PHPUnit 대신 단위 테스트를 실행할 수 있는 다른 도구를 사용할 수 있습니다. 예를 들어 [`atoum`](https://github.com/atoum/atoum)를 사용할 수 있습니다:

```yaml
test:atoum:
  before_script:
    - wget http://downloads.atoum.org/nightly/mageekguy.atoum.phar
  script:
    - php mageekguy.atoum.phar
```

### Composer 사용 {#using-composer}

대부분의 PHP 프로젝트는 PHP 패키지를 관리하기 위해 Composer를 사용합니다. 테스트를 실행하기 전에 Composer를 실행하려면 다음을 `.gitlab-ci.yml`에 추가합니다:

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

## 비공개 패키지 또는 종속성에 액세스 {#access-private-packages-or-dependencies}

테스트 리포지토리가 비공개 리포지토리에 액세스해야 하는 경우 [SSH 키](../jobs/ssh_keys.md)를 구성하여 이를 복제할 수 있어야 합니다.

## 데이터베이스 또는 기타 서비스 사용 {#use-databases-or-other-services}

대부분의 경우 테스트가 실행될 수 있도록 실행 중인 데이터베이스가 필요합니다. Docker 실행기를 사용하는 경우 Docker를 활용하여 다른 컨테이너에 연결할 수 있습니다. GitLab 러너를 사용하면 `service`를 정의하여 이를 달성할 수 있습니다.

이 기능은 [CI 서비스](../services/_index.md) 설명서에서 다룹니다.

## 예제 프로젝트 {#example-project}

편의상 공개적으로 사용 가능한 [인스턴스 러너](../runners/_index.md)를 사용하여 [GitLab.com](https://gitlab.com)에서 실행되는 [예제 PHP 프로젝트](https://gitlab.com/gitlab-examples/php)가 있습니다.

이를 수정하고 싶으신가요? 이를 포크하고 커밋한 다음 변경 사항을 푸시합니다. 잠시 후 변경 사항이 공용 러너에 의해 선택되고 작업이 시작됩니다.

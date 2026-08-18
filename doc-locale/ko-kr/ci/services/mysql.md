---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: MySQL 사용
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

많은 애플리케이션이 MySQL을 데이터베이스로 사용하며, 테스트를 실행하기 위해 필요할 수 있습니다.

## Docker 실행기에서 MySQL 사용 {#use-mysql-with-the-docker-executor}

MySQL 컨테이너를 사용하려면 Docker 실행기와 함께 [러너](../runners/_index.md)를 사용할 수 있습니다.

이 예제에서는 GitLab이 MySQL 컨테이너에 액세스하기 위해 사용하는 사용자 이름과 암호를 설정하는 방법을 보여줍니다. 사용자 이름과 암호를 설정하지 않으면 `root`을(를) 사용해야 합니다.

> [!note]
> GitLab UI에서 설정한 변수는 서비스 컨테이너로 전달되지 않습니다. 자세한 내용은 [CI/CD 변수](../variables/_index.md)를 참조하세요.

1. MySQL 이미지를 지정하려면 `.gitlab-ci.yml` 파일에 다음을 추가하세요:

   ```yaml
   services:
     - mysql:latest
   ```

   - [Docker Hub](https://hub.docker.com/_/mysql/)에서 사용 가능한 모든 Docker 이미지를 사용할 수 있습니다. 예를 들어 MySQL 5.5를 사용하려면 `mysql:5.5`를 사용하세요.
   - `mysql` 이미지는 환경 변수를 수락할 수 있습니다. 자세한 내용은 [Docker Hub 문서](https://hub.docker.com/_/mysql/)를 참조하세요.

1. 데이터베이스 이름과 암호를 포함하려면 `.gitlab-ci.yml` 파일에 다음을 추가하세요:

   ```yaml
   variables:
     # Configure mysql environment variables (https://hub.docker.com/_/mysql/)
     MYSQL_DATABASE: $MYSQL_DB
     MYSQL_ROOT_PASSWORD: $MYSQL_PASS
   ```

   MySQL 컨테이너는 `MYSQL_DATABASE`과(와) `MYSQL_ROOT_PASSWORD`를 사용하여 데이터베이스에 연결합니다. [CI/CD 변수](../variables/_index.md)를 사용하여 이 값을 전달하세요(`$MYSQL_DB` 및 `$MYSQL_PASS`(위의 예제에서)), [직접 호출하는 대신](https://gitlab.com/gitlab-org/gitlab/-/issues/30178).

1. 예를 들어 데이터베이스를 사용하도록 애플리케이션을 구성합니다:

   ```yaml
   Host: mysql
   User: runner
   Password: <your_mysql_password>
   Database: <your_mysql_database>
   ```

   이 예제에서 사용자는 `runner`입니다. 데이터베이스에 액세스할 권한이 있는 사용자를 사용해야 합니다.

## Shell 실행기에서 MySQL 사용 {#use-mysql-with-the-shell-executor}

Shell 실행기와 함께 러너를 사용하는 수동으로 구성된 서버에서도 MySQL을 사용할 수 있습니다.

1. MySQL 서버를 설치합니다:

   ```shell
   sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev
   ```

1. MySQL 루트 암호를 선택하고 입력 시 두 번 입력합니다.

   > [!note]
   > 보안 조치로, `mysql_secure_installation`를 실행하여 익명 사용자를 제거하고, 테스트 데이터베이스를 삭제하고, 루트 사용자의 원격 로그인을 비활성화할 수 있습니다.

1. 루트로 MySQL에 로그인하여 사용자를 생성합니다:

   ```shell
   mysql -u root -p
   ```

1. 애플리케이션에서 사용하는 사용자를 생성합니다(이 경우 `runner`). 명령에서 `$password`를 강력한 암호로 변경합니다.

   `mysql>` 프롬프트에서 다음을 입력합니다:

   ```sql
   CREATE USER 'runner'@'localhost' IDENTIFIED BY '$password';
   ```

1. 데이터베이스를 생성합니다:

   ```sql
   CREATE DATABASE IF NOT EXISTS `<your_mysql_database>` DEFAULT CHARACTER SET `utf8` \
   COLLATE `utf8_unicode_ci`;
   ```

1. 데이터베이스에 필요한 권한을 부여합니다:

   ```sql
   GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER, LOCK TABLES ON `<your_mysql_database>`.* TO 'runner'@'localhost';
   ```

1. 모든 것이 잘 작동했다면 데이터베이스 세션을 종료할 수 있습니다:

   ```shell
   \q
   ```

1. 새로 생성된 데이터베이스에 연결하여 모든 것이 제대로 설정되어 있는지 확인합니다:

   ```shell
   mysql -u runner -p -D <your_mysql_database>
   ```

1. 예를 들어 데이터베이스를 사용하도록 애플리케이션을 구성합니다:

   ```shell
   Host: localhost
   User: runner
   Password: $password
   Database: <your_mysql_database>
   ```

## 예제 프로젝트 {#example-project}

MySQL 예제를 보려면 이 [포크](https://gitlab.com/gitlab-examples/mysql)를 생성합니다. 이 프로젝트는 [인스턴스 러너](../runners/_index.md)를 공개적으로 사용 가능하게 [GitLab.com](https://gitlab.com)에서 사용합니다. README.md 파일을 업데이트하고, 변경 사항을 커밋하고, CI/CD 파이프라인을 보고 실행 중인 것을 확인합니다.

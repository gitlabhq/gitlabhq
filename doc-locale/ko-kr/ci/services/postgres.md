---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL 사용하기
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

많은 애플리케이션이 PostgreSQL을 데이터베이스로 사용하므로, 테스트를 실행하기 위해 PostgreSQL을 사용해야 합니다.

## Docker 실행기에서 PostgreSQL 사용하기 {#use-postgresql-with-the-docker-executor}

GitLab UI에 설정한 변수를 서비스 컨테이너로 전달하려면 [변수를 정의](../variables/_index.md#define-a-cicd-variable-in-the-ui)해야 합니다. Group 또는 Project로 변수를 정의한 후, 다음 해결 방법에 나와 있는 대로 작업에서 변수를 호출해야 합니다.

Postgres 15.4 이상 버전에서는 따옴표("), 백슬래시(\\), 달러 기호($) 기호가 포함된 경우 확장 스크립트에 스키마나 소유자 이름을 대체하지 않습니다. CI/CD 변수가 구성되지 않으면, 값이 환경 변수 이름을 문자열로 사용합니다. 예를 들어 `POSTGRES_USER: $USER` 을(를) 사용하면 `POSTGRES_USER` 변수가 '$USER'로 설정되어 Postgres에서 다음 오류를 표시합니다:

```shell
Fatal: invalid character in extension
```

해결 방법은 [CI/CD 변수](../variables/_index.md)에 변수를 설정하거나 변수를 문자열 형식으로 설정하는 것입니다:

1. [GitLab에서 Postgres 변수 설정](../variables/_index.md#for-a-project). GitLab UI에 설정한 변수는 서비스 컨테이너로 전달되지 않습니다.
1. `.gitlab-ci.yml` 파일에서 Postgres 이미지를 지정합니다:

   ```yaml
   default:
      services:
        - postgres
   ```

1. `.gitlab-ci.yml` 파일에 정의한 변수를 추가합니다:

   ```yaml
   variables:
     POSTGRES_DB: $POSTGRES_DB
     POSTGRES_USER: $POSTGRES_USER
     POSTGRES_PASSWORD: $POSTGRES_PASSWORD
     POSTGRES_HOST_AUTH_METHOD: trust
   ```

   `postgres`을(를) `Host`에 사용하는 방법에 대한 자세한 내용은 [서비스가 작업에 연결되는 방식](_index.md#how-services-are-linked-to-the-job)을 참조하세요.

1. 애플리케이션을 데이터베이스를 사용하도록 구성합니다(예시):

   ```yaml
   Host: postgres
   User: $POSTGRES_USER
   Password: $POSTGRES_PASSWORD
   Database: $POSTGRES_DB
   ```

또는 `.gitlab-ci.yml` 파일에서 변수를 문자열로 설정할 수 있습니다:

```yaml
variables:
  POSTGRES_DB: DB_name
  POSTGRES_USER: username
  POSTGRES_PASSWORD: password
  POSTGRES_HOST_AUTH_METHOD: trust
```

[Docker Hub](https://hub.docker.com/_/postgres)에서 사용 가능한 다른 Docker 이미지를 사용할 수 있습니다. 예를 들어 PostgreSQL 16.10을 사용하려면 서비스가 `postgres:16.10`가 됩니다.

`postgres` 이미지는 일부 환경 변수를 허용합니다. 자세한 내용은 [Docker Hub](https://hub.docker.com/_/postgres)의 설명서를 참조하세요.

## Shell 실행기에서 PostgreSQL 사용하기 {#use-postgresql-with-the-shell-executor}

Shell 실행기를 사용하는 GitLab Runner를 사용하여 수동으로 구성한 서버에서도 PostgreSQL을 사용할 수 있습니다.

먼저 PostgreSQL 서버를 설치합니다:

```shell
sudo apt-get install -y postgresql postgresql-client libpq-dev
```

다음 단계는 사용자를 생성하므로 PostgreSQL에 로그인합니다:

```shell
sudo -u postgres psql -d template1
```

그 다음 애플리케이션에서 사용하는 사용자(이 경우 `runner`)를 생성합니다. 다음 명령에서 `$password`을(를) 강력한 비밀번호로 변경합니다.

> [!note]
> `template1=#`을(를) 다음 명령에 입력하지 마십시오. 이는 PostgreSQL 프롬프트의 일부입니다.

```shell
template1=# CREATE USER runner WITH PASSWORD '$password' CREATEDB;
```

생성된 사용자는 데이터베이스를 생성할 수 있는 권한(`CREATEDB`)을 가집니다. 다음 단계에서는 해당 사용자를 위해 데이터베이스를 명시적으로 생성하는 방법을 설명합니다. 권한을 사용하면 테스트 프레임워크에서 필요에 따라 데이터베이스를 생성하고 삭제할 수 있습니다.

데이터베이스를 생성하고 사용자 `runner`에 대한 모든 권한을 부여합니다:

```shell
template1=# CREATE DATABASE nice_marmot OWNER runner;
```

모든 것이 정상적으로 진행되었으면 이제 데이터베이스 세션을 종료할 수 있습니다:

```shell
template1=# \q
```

이제 사용자 `runner`을(를) 사용하여 새로 생성된 데이터베이스에 연결을 시도하여 모든 것이 제대로 설정되어 있는지 확인합니다.

```shell
psql -U runner -h localhost -d nice_marmot -W
```

이 명령은 명시적으로 `psql`을(를) localhost로 연결하여 md5 인증을 사용합니다. 이 단계를 생략하면 액세스가 거부됩니다.

마지막으로 애플리케이션을 데이터베이스를 사용하도록 구성합니다(예시):

```yaml
Host: localhost
User: runner
Password: $password
Database: nice_marmot
```

## 예제 프로젝트 {#example-project}

저희는 [예제 PostgreSQL 프로젝트](https://gitlab.com/gitlab-examples/postgres)를 준비했으며, 이는 공개적으로 사용 가능한 [인스턴스 러너](../runners/_index.md)를 사용하여 [GitLab.com](https://gitlab.com)에서 실행됩니다.

수정하고 싶으신가요? 포크하고, 커밋한 후, 변경 사항을 푸시합니다. 잠시 후 변경 사항이 공개 러너에 의해 선택되고 작업이 시작됩니다.

---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux 패키지 GitLab 인스턴스를 Docker로 마이그레이션
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

기존 Linux 패키지 GitLab 인스턴스를 Docker로 마이그레이션하려면 다음 두 가지 방법 중 하나를 사용합니다:

- **Reuse existing data directories**: 기존 데이터 디렉터리를 Docker 볼륨 경로로 이동합니다. 이 방법을 사용하면 전체 백업 및 복원 사이클 없이 데이터를 제자리에 유지할 수 있습니다.
- **Back up and restore**: Linux 패키지 인스턴스에서 GitLab 백업을 만들고 새로운 Docker 인스턴스를 설정한 후 복원합니다. 필요한 경우 롤백을 지원하는 깔끔한 마이그레이션을 위해 이 방법을 사용합니다.

## 전제 조건 {#prerequisites}

- Linux 패키지 인스턴스와 Docker 이미지의 GitLab 버전이 일치해야 합니다. 필요한 경우 Docker로 마이그레이션하기 전에 Linux 패키지 인스턴스를 업그레이드합니다.
- 대상 서버에 [Docker 설치](installation.md)되어 있어야 합니다.

## 기존 데이터 디렉터리 재사용 {#reuse-existing-data-directories}

기존 데이터 디렉터리를 재사용하여 Linux 패키지 GitLab 인스턴스를 Docker로 마이그레이션합니다.

### Linux 패키지 인스턴스 중지 {#stop-the-linux-package-instance}

모든 GitLab 서비스를 중지합니다:

```shell
sudo gitlab-ctl stop
```

### 볼륨 디렉터리 준비 {#prepare-the-volume-directories}

볼륨 디렉터리를 준비하는 방법은 Docker가 실행되는 위치에 따라 다릅니다:

- Docker가 Linux 패키지 인스턴스와 동일한 서버에서 실행되는 경우 복사 없이 기존 디렉터리를 직접 마운트할 수 있습니다. Docker Compose 파일의 볼륨 경로를 Linux 패키지 위치로 설정합니다:

  ```yaml
  volumes:
    - '/etc/gitlab:/etc/gitlab'
    - '/var/log/gitlab:/var/log/gitlab'
    - '/var/opt/gitlab:/var/opt/gitlab'
  ```

- 다른 서버로 이동하거나 Docker 볼륨을 Linux 패키지 경로와 별도로 유지하려면 먼저 디렉터리를 새 위치로 복사합니다.

  1. `$GITLAB_HOME`을(를) 대상 디렉터리로 설정합니다:

     ```shell
     export GITLAB_HOME=/srv/gitlab
     sudo mkdir -p $GITLAB_HOME
     ```

  1. 데이터, 로그 및 구성 디렉터리를 복사(또는 이동)합니다:

     ```shell
     sudo cp -a /var/opt/gitlab $GITLAB_HOME/data
     sudo cp -a /var/log/gitlab $GITLAB_HOME/logs
     sudo cp -a /etc/gitlab     $GITLAB_HOME/config
     ```

     복사 대신 이동하려면 `cp -a` 대신 `mv`을(를) 사용합니다.

> [!warning]
> 컨테이너를 시작하기 전에 호스트 디렉터리의 소유권을 `root:root`(으)로 변경하지 마세요. 이렇게 하면 컨테이너가 시작되지 않고 `update-permissions` 스크립트가 나중에 소유권을 수정할 수 없습니다.

리포지토리 디렉터리가 존재하고 깨진 심링크가 아닌 실제 디렉터리인지 확인합니다:

```shell
ls -la $GITLAB_HOME/data/git-data/repositories
```

디렉터리가 없거나 깨진 심링크인 경우 만듭니다:

```shell
sudo mkdir -p $GITLAB_HOME/data/git-data/repositories
```

### 사용자 및 그룹 식별자 정렬 {#align-user-and-group-identifiers}

GitLab Docker 이미지에는 `update-permissions`이라는 기본 제공 스크립트가 포함되어 있으며, 이 스크립트는 모든 GitLab 디렉터리에 올바른 소유권을 설정합니다. Linux 패키지 인스턴스가 Docker 이미지가 예상하는 것과 다른 UID를 사용한 경우(배포판에 따라 다른 OS 기본값 또는 [명시적으로 구성된 값](https://docs.gitlab.com/omnibus/settings/configuration/#specify-numeric-user-and-group-identifiers)), 컨테이너를 시작하기 전에 볼륨이 마운트된 임시 컨테이너에서 `update-permissions`을(를) 실행합니다. 이렇게 하면 첫 번째 시작 전에 소유권이 수정됩니다:

```shell
docker run --rm \
  -v <config_path>:/etc/gitlab \
  -v <logs_path>:/var/log/gitlab \
  -v <data_path>:/var/opt/gitlab \
  --entrypoint /bin/bash \
  gitlab/gitlab-ee:<version> \
  -c "update-permissions"
```

`<config_path>`, `<logs_path>` 및 `<data_path>`을(를) [볼륨 디렉터리 준비](#prepare-the-volume-directories)에서 식별한 호스트 경로로 바꿉니다.

### Docker에서 GitLab 시작 {#start-gitlab-in-docker}

[설치 지침](installation.md)을(를) 따라 Docker Compose 파일 또는 준비한 디렉터리를 마운트하는 Docker Engine 명령을 만듭니다:

```yaml
volumes:
  - '$GITLAB_HOME/config:/etc/gitlab'
  - '$GITLAB_HOME/logs:/var/log/gitlab'
  - '$GITLAB_HOME/data:/var/opt/gitlab'
```

컨테이너가 시작된 후 재구성을 실행합니다:

```shell
docker exec -it <container_name> gitlab-ctl reconfigure
```

설치를 확인합니다:

```shell
docker exec -it <container_name> gitlab-rake gitlab:check
```

## Linux 패키지 인스턴스를 백업하고 Docker 인스턴스로 복원 {#back-up-the-linux-package-instance-and-restore-to-the-docker-instance}

### Linux 패키지 인스턴스에서 백업 만들기 {#create-a-backup-on-the-linux-package-instance}

Linux 패키지 인스턴스를 중지하기 전에 백업을 만듭니다:

```shell
sudo gitlab-backup create
```

비밀 파일을 안전한 위치로 복사합니다:

```shell
sudo cp /etc/gitlab/gitlab-secrets.json /your/backup/location/
```

자세한 내용은 [GitLab 백업](../../administration/backup_restore/backup_gitlab.md)을(를) 참조하세요.

### Linux 패키지 인스턴스 중지 {#stop-the-linux-package-instance-1}

모든 GitLab 서비스를 중지합니다:

```shell
sudo gitlab-ctl stop
```

### Docker 인스턴스 설정 {#set-up-the-docker-instance}

[설치 지침](installation.md)을(를) 따라 새 Docker 인스턴스를 설정합니다. `$GITLAB_HOME`을(를) 볼륨을 위해 만드는 디렉터리로 설정합니다(예시):

```shell
export GITLAB_HOME=/srv/gitlab
```

컨테이너를 한 번 시작하여 볼륨 디렉터리를 초기화한 후 복원하기 전에 중지합니다:

```shell
docker compose up -d
docker compose stop
```

### 백업 복원 {#restore-the-backup}

1. 백업 아카이브를 Docker 데이터 볼륨으로 복사합니다:

   ```shell
   sudo cp <timestamp>_gitlab_backup.tar $GITLAB_HOME/data/backups/
   ```

1. 비밀 파일을 Docker 구성 볼륨으로 복사합니다:

   ```shell
   sudo cp gitlab-secrets.json $GITLAB_HOME/config/gitlab-secrets.json
   ```

1. 컨테이너를 시작하고 복원을 실행합니다:

   ```shell
   docker compose start
   docker exec -it <container_name> gitlab-backup restore BACKUP=<timestamp>
   ```

1. 복원이 완료된 후 재구성 및 재시작합니다:

   ```shell
   docker exec -it <container_name> gitlab-ctl reconfigure
   docker exec -it <container_name> gitlab-ctl restart
   ```

1. 설치를 확인합니다:

   ```shell
   docker exec -it <container_name> gitlab-rake gitlab:check
   ```

## 문제 해결 {#troubleshooting}

Linux 패키지 GitLab 인스턴스를 Docker로 마이그레이션할 때 다음과 같은 이슈가 발생할 수 있습니다.

### 시작 후 권한 오류 {#permission-errors-after-starting}

컨테이너가 시작되지만 권한 오류가 보고되면 다음을 실행합니다:

```shell
sudo docker exec <container_name> update-permissions
sudo docker restart <container_name>
```

이는 Linux 패키지 인스턴스가 Docker 이미지가 예상하는 것과 다른 시스템 계정 UID를 사용할 때 발생합니다. 이를 방지하려면 [사용자 및 그룹 식별자 정렬](#align-user-and-group-identifiers)에 설명된 대로 시작하기 전에 `update-permissions`을(를) 실행합니다.

### 다른 인스턴스의 데이터 재사용 시 오류 {#errors-when-reusing-data-from-another-instance}

다른 인스턴스에서 데이터를 다시 사용할 때 다음과 같은 이슈가 발생할 수 있습니다.

#### `stat: missing operand` 시작 시 오류 {#stat-missing-operand-error-on-startup}

이 오류는 컨테이너가 `git-data/repositories` 디렉터리를 찾을 수 없을 때 발생합니다:

```plaintext
stat: missing operand
Expected process to exit with [0], but received '1'
Ran stat --printf='%U' $(readlink -f /var/opt/gitlab/git-data/repositories) returned 1
```

호스트에서 누락된 디렉터리를 만든 후 컨테이너를 다시 시작합니다:

```shell
sudo mkdir -p $GITLAB_HOME/data/git-data/repositories
sudo docker restart <container_name>
```

#### 컨테이너가 즉시 종료되고 재시작 루프가 `docker exec`를 차단합니다 {#container-exits-immediately-and-restart-loop-blocks-docker-exec}

컨테이너가 시작된 직후 종료되면 `docker exec`을(를) 사용하여 조사하거나 `update-permissions`을(를) 실행할 수 없습니다. 대신 [사용자 및 그룹 식별자 정렬](#align-user-and-group-identifiers)의 동일한 명령을 사용하여 `update-permissions`을(를) 직접 실행합니다. 이 명령은 볼륨이 마운트된 임시 컨테이너를 시작하고 주 컨테이너를 실행할 필요 없이 소유권을 수정합니다.

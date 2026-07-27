---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Docker 컨테이너에서 실행되는 GitLab 문제 해결
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

Docker 컨테이너에 GitLab을 설치할 때 다음과 같은 문제가 발생할 수 있습니다.

## 잠재적 문제 진단 {#diagnose-potential-problems}

다음 명령은 Docker 컨테이너에서 GitLab 인스턴스를 문제 해결할 때 유용합니다:

컨테이너 로그 읽기:

```shell
sudo docker logs gitlab
```

실행 중인 컨테이너 시작:

```shell
sudo docker exec -it gitlab /bin/bash
```

Linux 패키지 설치를 관리하는 것처럼 컨테이너 내에서 GitLab 컨테이너를 관리할 수 있습니다. [Linux package installation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md)를 참조하세요.

## 500 내부 오류 {#500-internal-error}

Docker 이미지를 업데이트할 때 모든 경로에 `500` 페이지가 표시되는 이슈가 발생할 수 있습니다. 이 경우 컨테이너를 다시 시작합니다:

```shell
sudo docker restart gitlab
```

## 권한 문제 {#permission-problems}

이전 GitLab Docker 이미지에서 업데이트할 때 권한 문제가 발생할 수 있습니다. 이는 이전 이미지의 사용자 권한이 올바르게 유지되지 않을 때 발생합니다. 모든 파일의 권한을 수정하는 스크립트가 있습니다.

컨테이너를 수정하려면 `update-permissions`를 실행한 후 컨테이너를 다시 시작합니다:

```shell
sudo docker exec gitlab update-permissions
sudo docker restart gitlab
```

## `ruby_block` 리소스에서 작업 실행 오류 {#error-executing-action-run-on-resource-ruby_block}

이 오류는 Windows 또는 Mac에서 Oracle VirtualBox와 함께 Docker Toolbox를 사용하고 Docker 볼륨을 사용할 때 발생합니다:

```plaintext
Error executing action run on resource ruby_block[directory resource: /data/GitLab]
```

`/c/Users` 볼륨이 VirtualBox 공유 폴더로 마운트되어 있으며 모든 POSIX 파일 시스템 기능을 지원하지 않습니다. 디렉터리 소유권과 권한은 다시 마운트하지 않고는 변경할 수 없으며 GitLab이 실패합니다.

Docker Toolbox를 사용하는 대신 플랫폼에 맞게 기본 Docker 설치로 전환합니다.

기본 Docker 설치를 사용할 수 없는 경우(Windows 10 Home Edition 또는 Windows 7/8), Docker Toolbox Boot2docker에 대해 VirtualBox 공유 대신 NFS 마운트를 설정하는 것이 대안입니다.

## Linux ACL 이슈 {#linux-acl-issues}

Docker 호스트에서 파일 ACL을 사용하는 경우 GitLab이 작동하려면 `docker` 그룹이 볼륨에 대한 전체 액세스 권한이 필요합니다:

```shell
getfacl $GITLAB_HOME

# file: $GITLAB_HOME
# owner: XXXX
# group: XXXX
user::rwx
group::rwx
group:docker:rwx
mask::rwx
default:user::rwx
default:group::rwx
default:group:docker:rwx
default:mask::rwx
default:other::r-x
```

이러한 값이 올바르지 않으면 다음을 사용하여 설정합니다:

```shell
sudo setfacl -mR default:group:docker:rwx $GITLAB_HOME
```

기본 그룹의 이름은 `docker`입니다. 그룹 이름을 변경한 경우 명령을 조정해야 합니다.

## `/dev/shm` 마운트에 Docker 컨테이너에 공간이 부족합니다 {#devshm-mount-not-having-enough-space-in-docker-container}

GitLab은 `/-/metrics`에서 Prometheus 메트릭 엔드포인트를 제공하여 GitLab의 상태 및 성능에 대한 통계를 노출합니다. 이에 필요한 파일은 임시 파일 시스템(예: `/run` 또는 `/dev/shm`)에 기록됩니다.

기본적으로 Docker는 공유 메모리 디렉터리(`/dev/shm`에 마운트됨)에 64MB를 할당합니다. 이는 생성된 모든 Prometheus 메트릭 관련 파일을 보관하기에 불충분하며 다음과 같은 오류 로그가 생성됩니다:

```plaintext
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
```

**운영자** 영역에서 Prometheus 메트릭을 끌 수 있지만 이 문제를 해결하는 권장 솔루션은 공유 메모리가 최소 256MB 이상으로 설정된 상태로 [install](configuration.md#pre-configure-docker-container)하는 것입니다. `docker run`을(를) 사용하는 경우 `--shm-size 256m` 플래그를 전달할 수 있습니다. `docker-compose.yml` 파일을 사용하는 경우 `shm_size` 키를 설정할 수 있습니다.

## `json-file` 때문에 Docker 컨테이너의 공간 부족 {#docker-containers-exhausts-space-due-to-the-json-file}

Docker는 [`json-file` 기본 로깅 드라이버](https://docs.docker.com/config/containers/logging/configure/#configure-the-default-logging-driver)를 사용합니다. 이는 기본적으로 로그 순환을 수행하지 않습니다. 이로 인해 `json-file` 드라이버가 저장한 로그 파일은 많은 출력을 생성하는 컨테이너에 대해 상당한 양의 디스크 공간을 소비할 수 있습니다. 이로 인해 디스크 공간 부족이 발생할 수 있습니다. 이를 해결하려면 사용 가능한 경우 로깅 드라이버로 [`journald`](https://docs.docker.com/engine/logging/drivers/journald/)를 사용하거나, 기본 순환 지원이 있는 [another supported driver](https://docs.docker.com/config/containers/logging/configure/#supported-logging-drivers)를 사용합니다.

## Docker 시작 시 버퍼 오버플로우 오류 {#buffer-overflow-error-when-starting-docker}

이 버퍼 오버플로우 오류가 발생하면 `/var/log/gitlab`에서 오래된 로그 파일을 정리해야 합니다:

```plaintext
buffer overflow detected : terminated
xargs: tail: terminated by signal 6
```

오래된 로그 파일을 제거하면 오류 해결에 도움이 되며 인스턴스의 깔끔한 시작을 보장합니다.

## 이전 설치에서 데이터를 다시 사용할 때 발생하는 오류 {#errors-when-reusing-data-from-a-previous-installation}

다른 인스턴스에서 데이터를 다시 사용할 때 다음과 같은 이슈가 발생할 수 있습니다.

### `stat: missing operand` 시작 시 오류 {#stat-missing-operand-error-on-startup}

이 오류는 Linux 패키지 설치에서 마이그레이션할 때 `git-data/repositories` 디렉터리가 누락되었거나 호스트 볼륨의 끊어진 심볼릭 링크인 경우 발생합니다:

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

완전한 마이그레이션 가이드는 [Migrate a Linux package GitLab instance to Docker](migrate.md)를 참조하세요.

### 컨테이너가 즉시 종료되고 재시작 루프가 `docker exec`를 차단합니다 {#container-exits-immediately-and-restart-loop-blocks-docker-exec}

컨테이너가 시작되지 않고 계속 다시 시작되면 `docker exec`를 사용하여 조사할 수 없습니다. 대신 이미지에서 직접 셸을 시작합니다:

```shell
docker run --rm -it --entrypoint /bin/bash gitlab/gitlab-ee:<version>
```

이 셸을 사용하여 예상되는 디렉터리 구조를 검사하고 호스트에 마운트된 볼륨과 비교합니다.

## ThreadError 스레드를 만들 수 없음 작업이 허용되지 않음 {#threaderror-cant-create-thread-operation-not-permitted}

```plaintext
can't create Thread: Operation not permitted
```

이 오류는 [clone3 함수를 지원하지 않는 호스트](https://github.com/moby/moby/issues/42680)에서 최신 `glibc` 버전으로 빌드된 컨테이너를 실행할 때 발생합니다. GitLab 16.0 이상에서 컨테이너 이미지에는 최신 `glibc` 버전으로 빌드된 Ubuntu 22.04 Linux 패키지가 포함되어 있습니다.

이 문제는 [Docker 20.10.10](https://github.com/moby/moby/pull/42836)과 같은 최신 컨테이너 런타임 도구에서 발생하지 않습니다.

이 이슈를 해결하려면 Docker를 버전 20.10.10 이상으로 업데이트합니다.

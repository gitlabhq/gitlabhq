---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Docker 컨테이너에서 실행할 때 GitLab을 구성하는 방법입니다.
title: Docker 컨테이너에서 실행하는 GitLab 구성
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이 컨테이너는 공식 Linux 패키지를 사용하므로 `/etc/gitlab/gitlab.rb`을 사용하여 인스턴스를 구성할 수 있습니다.

## 구성 파일 편집 {#edit-the-configuration-file}

GitLab 구성 파일에 액세스하려면 실행 중인 컨테이너의 맥락에서 셸 세션을 시작할 수 있습니다.

1. 세션 시작:

   ```shell
   sudo docker exec -it gitlab /bin/bash
   ```

   또는 `/etc/gitlab/gitlab.rb`을 편집기에서 직접 열 수 있습니다:

   ```shell
   sudo docker exec -it gitlab editor /etc/gitlab/gitlab.rb
   ```

1. 원하는 텍스트 편집기에서 `/etc/gitlab/gitlab.rb`을 열고 다음 필드를 업데이트합니다:

   1. `external_url` 필드를 GitLab 인스턴스의 유효한 URL로 설정합니다.

   1. GitLab에서 이메일을 받으려면 [SMTP 설정](https://docs.gitlab.com/omnibus/settings/smtp/)을 구성합니다. GitLab Docker 이미지는 SMTP 서버가 사전 설치되어 있지 않습니다.

   1. 필요한 경우 [HTTPS 활성화](https://docs.gitlab.com/omnibus/settings/ssl/)합니다.

1. 파일을 저장하고 컨테이너를 다시 시작하여 GitLab을 재구성합니다:

   ```shell
   sudo docker restart gitlab
   ```

GitLab은 컨테이너가 시작될 때마다 자동으로 재구성됩니다. GitLab의 추가 구성 옵션은 [구성 설명서](https://docs.gitlab.com/omnibus/settings/configuration/)를 참조하세요.

## Docker 컨테이너 사전 구성 {#pre-configure-docker-container}

Docker run 명령에 환경 변수 `GITLAB_OMNIBUS_CONFIG`을 추가하여 GitLab Docker 이미지를 사전 구성할 수 있습니다. 이 변수는 모든 `gitlab.rb` 설정을 포함할 수 있으며 컨테이너의 `gitlab.rb` 파일이 로드되기 전에 평가됩니다. 이 동작으로 외부 GitLab URL을 구성하거나 데이터베이스 구성 또는 [Linux 패키지 템플릿](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)의 다른 모든 옵션을 설정할 수 있습니다. `GITLAB_OMNIBUS_CONFIG`에 포함된 설정은 `gitlab.rb` 구성 파일에 기록되지 않으며 로드 시 평가됩니다. 여러 설정을 제공하려면 콜론(`;`)으로 구분합니다.

다음 예제는 외부 URL을 설정하고, LFS를 활성화하며, [Prometheus에 필요한 최소 shm 크기](troubleshooting.md#devshm-mount-not-having-enough-space-in-docker-container)로 컨테이너를 시작합니다:

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'; gitlab_rails['lfs_enabled'] = true;" \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:<version>-ee.0
```

`docker run` 명령을 실행할 때마다 `GITLAB_OMNIBUS_CONFIG` 옵션을 제공해야 합니다. `GITLAB_OMNIBUS_CONFIG`의 내용은 _후속 실행 사이에 유지되지 않습니다._

### 공용 IP 주소에서 GitLab 실행 {#run-gitlab-on-a-public-ip-address}

`--publish` 플래그를 수정하여 Docker가 IP 주소를 사용하고 모든 트래픽을 GitLab 컨테이너로 전달하도록 할 수 있습니다.

GitLab을 IP `198.51.100.1`에 노출하려면:

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
  --publish 198.51.100.1:443:443 \
  --publish 198.51.100.1:80:80 \
  --publish 198.51.100.1:22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:<version>-ee.0
```

그러면 `http://198.51.100.1/`과(와) `https://198.51.100.1/`에서 GitLab 인스턴스에 액세스할 수 있습니다.

## 다른 포트에서 GitLab 노출 {#expose-gitlab-on-different-ports}

GitLab은 컨테이너 내에서 [특정 포트](../../administration/package_information/defaults.md)를 사용합니다.

기본 포트 `80`(HTTP), `443`(HTTPS) 또는 `22`(SSH)와 다른 호스트 포트를 사용하려면 `docker run` 명령에 별도의 `--publish` 지시문을 추가해야 합니다.

예를 들어 호스트의 포트 `8929`에서 웹 인터페이스를 노출하고 포트 `2424`에서 SSH 서비스를 노출하려면:

1. 다음 `docker run` 명령을 사용합니다:

   ```shell
   sudo docker run --detach \
     --hostname gitlab.example.com \
     --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com:8929'; gitlab_rails['gitlab_shell_ssh_port'] = 2424" \
     --publish 8929:8929 --publish 2424:22 \
     --name gitlab \
     --restart always \
     --volume $GITLAB_HOME/config:/etc/gitlab \
     --volume $GITLAB_HOME/logs:/var/log/gitlab \
     --volume $GITLAB_HOME/data:/var/opt/gitlab \
     --shm-size 256m \
     gitlab/gitlab-ee:<version>-ee.0
   ```

   > [!note]
   > 포트를 게시하는 형식은 `hostPort:containerPort`입니다. Docker 설명서에서 [들어오는 포트 노출](https://docs.docker.com/network/#published-ports)에 대해 자세히 읽어보세요.

1. 실행 중인 컨테이너 입력:

   ```shell
   sudo docker exec -it gitlab /bin/bash
   ```

1. `/etc/gitlab/gitlab.rb`을 편집기로 열고 `external_url`을 설정합니다:

   ```ruby
   # For HTTP
   external_url "http://gitlab.example.com:8929"

   or

   # For HTTPS (notice the https)
   external_url "https://gitlab.example.com:8929"
   ```

   이 URL에 지정된 포트는 Docker가 호스트에 게시한 포트와 일치해야 합니다. 또한 NGINX 수신 포트가 `nginx['listen_port']`에서 명시적으로 설정되지 않은 경우 `external_url`이 대신 사용됩니다. 자세한 내용은 [NGINX 설명서](https://docs.gitlab.com/omnibus/settings/nginx/)를 참조하세요.

1. SSH 포트 설정:

   ```ruby
   gitlab_rails['gitlab_shell_ssh_port'] = 2424
   ```

1. 마지막으로 GitLab을 재구성합니다:

   ```shell
   gitlab-ctl reconfigure
   ```

이전 예제를 따라 웹 브라우저에서 `<hostIP>:8929`에서 GitLab 인스턴스에 액세스할 수 있으며 포트 `2424`를 통해 SSH로 푸시할 수 있습니다.

`docker-compose.yml` 예제를 [Docker Compose](installation.md#install-gitlab-by-using-docker-compose) 섹션에서 다른 포트를 사용하는 것으로 볼 수 있습니다.

## 여러 데이터베이스 연결 구성 {#configure-multiple-database-connections}

[GitLab 16.0](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6850)부터 GitLab은 기본적으로 동일한 PostgreSQL 데이터베이스를 가리키는 두 개의 데이터베이스 연결을 사용합니다.

어떤 이유로든 단일 데이터베이스 연결로 돌아가려면:

1. 컨테이너 내의 `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```shell
   sudo docker exec -it gitlab editor /etc/gitlab/gitlab.rb
   ```

1. 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['databases']['ci']['enable'] = false
   ```

1. 컨테이너를 다시 시작합니다:

   ```shell
   sudo docker restart gitlab
   ```

## 다음 단계 {#next-steps}

설치를 구성한 후 인증 옵션 및 새 사용자 계정 제한을 포함하여 [권장 다음 단계](../next_steps.md)를 수행하는 것을 고려하세요.

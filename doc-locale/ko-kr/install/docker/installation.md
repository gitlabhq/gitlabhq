---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Docker 컨테이너에 GitLab을 설치하기 위한 필수 조건, 전략 및 단계에 대해 알아봅니다."
title: Docker 컨테이너에서 GitLab 설치
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Docker 컨테이너에 GitLab을 설치하려면 Docker Compose, Docker Engine 또는 Docker Swarm 모드를 사용합니다.

전제 조건:

- [Docker 설치](https://docs.docker.com/engine/install/#server)가 필요하며, Docker for Windows가 아니어야 합니다. Docker for Windows는 공식적으로 지원되지 않습니다. 이미지에 볼륨 권한 관련 알려진 호환성 이슈와 잠재적으로 다른 미지의 이슈가 있기 때문입니다. Docker for Windows에서 실행하려면 [도움말 페이지](https://about.gitlab.com/get-help/)를 참조하세요. 이 페이지에는 커뮤니티 리소스(IRC 또는 포럼 등)로의 링크가 포함되어 있으므로 다른 사용자에게 도움을 요청할 수 있습니다.
- 메일 전송 에이전트(MTA)(예: Postfix 또는 Sendmail)가 필요합니다. GitLab 이미지에는 MTA가 포함되지 않습니다. 별도의 컨테이너에 MTA를 설치할 수 있습니다. GitLab과 동일한 컨테이너에 MTA를 설치할 수 있지만, 매번 업그레이드하거나 다시 시작할 때마다 MTA를 다시 설치해야 할 수 있습니다.
- GitLab Docker 이미지를 Kubernetes에 배포할 계획은 없어야 합니다. 단일 장애점을 만들기 때문입니다. Kubernetes에 GitLab을 배포하려면 [GitLab Helm Chart](https://docs.gitlab.com/charts/) 또는 [GitLab Operator](https://docs.gitlab.com/operator/)를 대신 사용합니다.
- Docker 설치에 유효하고 외부에서 액세스 가능한 호스트명이 필요합니다. `localhost`을 사용하지 마세요.

## SSH 포트 구성 {#configure-the-ssh-port}

기본적으로 GitLab은 `22` 포트를 사용하여 SSH를 통해 Git과 상호 작용합니다. `22` 포트를 사용하려면 이 섹션을 건너뜁니다.

다른 포트를 사용하려면 다음 중 하나를 수행할 수 있습니다:

- 서버의 SSH 포트를 지금 변경합니다(권장). 그러면 SSH 클론 URL에는 새 포트 번호가 필요하지 않습니다:

  ```plaintext
  ssh://git@gitlab.example.com/user/project.git
  ```

- 설치 후 [GitLab Shell SSH 포트 변경](configuration.md#expose-gitlab-on-different-ports)을 수행합니다. 그러면 SSH 클론 URL에는 구성된 포트 번호가 포함됩니다:

  ```plaintext
  ssh://git@gitlab.example.com:<portNumber>/user/project.git
  ```

서버의 SSH 포트를 변경하려면:

1. `/etc/ssh/sshd_config`을 편집기로 열고 SSH 포트를 변경합니다:

   ```conf
   Port = 2424
   ```

1. 파일을 저장하고 SSH 서비스를 다시 시작합니다:

   ```shell
   sudo systemctl restart ssh
   ```

1. SSH를 통해 연결할 수 있는지 확인합니다. 새 터미널 세션을 열고 새 포트를 사용하여 서버에 SSH로 연결합니다.

## 볼륨용 디렉터리 만들기 {#create-a-directory-for-the-volumes}

> [!warning]
> Gitaly 데이터를 호스팅하는 볼륨에 대한 특정 권장 사항이 있습니다. NFS 기반 파일 시스템은 성능 이슈를 일으킬 수 있으므로 [EFS는 권장되지 않습니다](../aws/_index.md#elastic-file-system-efs).

구성 파일, 로그 및 데이터 파일용 디렉터리를 만듭니다. 디렉터리는 사용자의 홈 디렉터리에 있을 수 있습니다(예: `~/gitlab-docker`). 또는 `/srv/gitlab`와 같은 디렉터리에 있을 수 있습니다.

1. 디렉터리를 만듭니다:

   ```shell
   sudo mkdir -p /srv/gitlab
   ```

1. `root` 이외의 사용자로 Docker를 실행 중이면 새 디렉터리에 대해 사용자에게 적절한 권한을 부여합니다.

1. 생성한 디렉터리의 경로를 설정하는 새 환경 변수 `$GITLAB_HOME`을 구성합니다:

   ```shell
   export GITLAB_HOME=/srv/gitlab
   ```

1. 선택적으로 `GITLAB_HOME` 환경 변수를 셸의 프로필에 추가하여 모든 향후 터미널 세션에 적용할 수 있습니다:

   - Bash: `~/.bash_profile`
   - ZSH: `~/.zshrc`

GitLab 컨테이너는 호스트 마운트 볼륨을 사용하여 지속성 데이터를 저장합니다:

| 로컬 위치       | 컨테이너 위치 | 사용                                       |
|----------------------|--------------------|---------------------------------------------|
| `$GITLAB_HOME/data`  | `/var/opt/gitlab`  | 애플리케이션 데이터를 저장합니다.                    |
| `$GITLAB_HOME/logs`  | `/var/log/gitlab`  | 로그를 저장합니다.                                |
| `$GITLAB_HOME/config`| `/etc/gitlab`      | GitLab 구성 파일을 저장합니다.      |

## 사용할 GitLab 버전 및 에디션 찾기 {#find-the-gitlab-version-and-edition-to-use}

프로덕션 환경에서는 배포를 특정 GitLab 버전으로 고정해야 합니다. 사용 가능한 버전을 검토하고 Docker 태그 페이지에서 사용할 버전을 선택합니다:

- [GitLab Enterprise Edition 태그](https://hub.docker.com/r/gitlab/gitlab-ee/tags/)
- [GitLab Community Edition 태그](https://hub.docker.com/r/gitlab/gitlab-ce/tags/)

태그 이름은 다음으로 구성됩니다:

```plaintext
gitlab/gitlab-ee:<version>-ee.0
```

`<version>`은 GitLab 버전이며, 예를 들어 `16.5.3`입니다. 버전은 항상 `<major>.<minor>.<patch>`을 이름에 포함합니다.

테스트 목적으로 `latest` 태그(예: `gitlab/gitlab-ee:latest`)를 사용할 수 있으며, 이는 최신 안정 릴리스를 가리킵니다.

다음 예제는 안정적인 Enterprise Edition 버전을 사용합니다. 릴리스 후보(RC) 또는 야간 이미지를 사용하려면 `gitlab/gitlab-ee:rc` 또는 `gitlab/gitlab-ee:nightly`를 대신 사용합니다.

Community Edition을 설치하려면 `ee`을 `ce`로 바꿉니다.

## 설치 {#installation}

다음을 사용하여 GitLab Docker 이미지를 실행할 수 있습니다:

- [Docker Compose](#install-gitlab-by-using-docker-compose)(권장)
- [Docker Engine](#install-gitlab-by-using-docker-engine)
- [Docker Swarm 모드](#install-gitlab-by-using-docker-swarm-mode)

### Docker Compose를 사용하여 GitLab 설치 {#install-gitlab-by-using-docker-compose}

[Docker Compose](https://docs.docker.com/compose/)를 사용하면 Docker 기반 GitLab 설치를 구성, 설치 및 업그레이드할 수 있습니다:

1. [Docker Compose 설치](https://docs.docker.com/compose/install/linux/)
1. `docker-compose.yml` 파일을 만듭니다. 예를 들어:

   ```yaml
   services:
     gitlab:
       image: gitlab/gitlab-ee:<version>-ee.0
       container_name: gitlab
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           # Add any other gitlab.rb configuration here, each on its own line
           external_url 'https://gitlab.example.com'
       ports:
         - '80:80'
         - '443:443'
         - '22:22'
       volumes:
         - '$GITLAB_HOME/config:/etc/gitlab'
         - '$GITLAB_HOME/logs:/var/log/gitlab'
         - '$GITLAB_HOME/data:/var/opt/gitlab'
       shm_size: '256m'
   ```

   > [!note]
   > [Docker 컨테이너 사전 구성](configuration.md#pre-configure-docker-container) 섹션을 읽어 `GITLAB_OMNIBUS_CONFIG` 변수가 작동하는 방식을 확인합니다.

   다음은 GitLab이 사용자 지정 HTTP 및 SSH 포트에서 실행되는 또 다른 `docker-compose.yml` 예제입니다. `GITLAB_OMNIBUS_CONFIG` 변수가 `ports` 섹션과 일치함을 확인합니다:

   ```yaml
   services:
     gitlab:
       image: gitlab/gitlab-ee:<version>-ee.0
       container_name: gitlab
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           external_url 'http://gitlab.example.com:8929'
           gitlab_rails['gitlab_shell_ssh_port'] = 2424
       ports:
         - '8929:8929'
         - '443:443'
         - '2424:22'
       volumes:
         - '$GITLAB_HOME/config:/etc/gitlab'
         - '$GITLAB_HOME/logs:/var/log/gitlab'
         - '$GITLAB_HOME/data:/var/opt/gitlab'
       shm_size: '256m'
   ```

   이 구성은 `--publish 8929:8929 --publish 2424:22`을 사용하는 것과 동일합니다.

1. `docker-compose.yml`과 동일한 디렉터리에서 GitLab을 시작합니다:

   ```shell
   docker compose up -d
   ```

### Docker Engine을 사용하여 GitLab 설치 {#install-gitlab-by-using-docker-engine}

또는 Docker Engine을 사용하여 GitLab을 설치할 수 있습니다.

1. `GITLAB_HOME` 변수를 설정한 경우 디렉터리를 요구 사항에 맞게 조정하고 이미지를 실행합니다:

   - SELinux를 사용하지 않으면 이 명령을 실행합니다:

     ```shell
     sudo docker run --detach \
       --hostname gitlab.example.com \
       --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
       --publish 443:443 --publish 80:80 --publish 22:22 \
       --name gitlab \
       --restart always \
       --volume $GITLAB_HOME/config:/etc/gitlab \
       --volume $GITLAB_HOME/logs:/var/log/gitlab \
       --volume $GITLAB_HOME/data:/var/opt/gitlab \
       --shm-size 256m \
       gitlab/gitlab-ee:<version>-ee.0
     ```

     이 명령은 GitLab 컨테이너를 다운로드하여 시작하고 [포트를 게시합니다](https://docs.docker.com/network/#published-ports). SSH, HTTP 및 HTTPS에 액세스하는 데 필요합니다. 모든 GitLab 데이터는 `$GITLAB_HOME`의 하위 디렉터리로 저장됩니다. 시스템을 다시 부팅한 후 컨테이너가 자동으로 다시 시작됩니다.

   - SELinux를 사용 중이면 대신 다음을 실행합니다:

     ```shell
     sudo docker run --detach \
       --hostname gitlab.example.com \
       --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
       --publish 443:443 --publish 80:80 --publish 22:22 \
       --name gitlab \
       --restart always \
       --volume $GITLAB_HOME/config:/etc/gitlab:Z \
       --volume $GITLAB_HOME/logs:/var/log/gitlab:Z \
       --volume $GITLAB_HOME/data:/var/opt/gitlab:Z \
       --shm-size 256m \
       gitlab/gitlab-ee:<version>-ee.0
     ```

     이 명령은 Docker 프로세스가 마운트된 볼륨에서 구성 파일을 만들 수 있는 충분한 권한을 가지도록 합니다.

1. [Kerberos 통합](../../integration/kerberos.md)을 사용 중이면 Kerberos 포트(예: `--publish 8443:8443`)도 게시해야 합니다. 이렇게 하지 않으면 Kerberos를 통한 Git 작업을 방지합니다. 초기화 프로세스에 시간이 오래 걸릴 수 있습니다. 이 프로세스를 다음으로 추적할 수 있습니다:

   ```shell
   sudo docker logs -f gitlab
   ```

   컨테이너를 시작한 후 `gitlab.example.com`을 방문할 수 있습니다. Docker 컨테이너가 쿼리에 응답하기 시작하는 데 시간이 걸릴 수 있습니다.

1. GitLab URL을 방문하고 사용자명 `root`로 로그인하고 다음 명령에서 비밀번호를 입력합니다:

   ```shell
   sudo docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
   ```

> [!note]
> 비밀번호 파일은 24시간 후 첫 번째 컨테이너 다시 시작 시 자동으로 삭제됩니다.

### Docker Swarm 모드를 사용하여 GitLab 설치 {#install-gitlab-by-using-docker-swarm-mode}

[Docker Swarm 모드](https://docs.docker.com/engine/swarm/)를 사용하면 Swarm 클러스터에서 Docker를 사용하여 GitLab 설치를 구성하고 배포할 수 있습니다.

Swarm 모드에서는 [Docker 시크릿](https://docs.docker.com/engine/swarm/secrets/) 및 [Docker 구성](https://docs.docker.com/engine/swarm/configs/)을 활용하여 GitLab 인스턴스를 효율적으로 안전하게 배포할 수 있습니다. 시크릿을 사용하여 환경 변수로 노출되지 않도록 초기 루트 비밀번호를 안전하게 전달할 수 있습니다. 구성은 GitLab 이미지를 최대한 일반적으로 유지하는 데 도움이 됩니다.

다음은 [스택](https://docs.docker.com/get-started/swarm-deploy/#describe-apps-using-stack-files)으로 4개의 러너를 포함하여 GitLab을 배포하는 예입니다. 시크릿 및 구성을 사용합니다:

1. [Docker Swarm 설정](https://docs.docker.com/engine/swarm/swarm-tutorial/)
1. `docker-compose.yml` 파일을 만듭니다:

   ```yaml
   services:
     gitlab:
       image: gitlab/gitlab-ee:<version>-ee.0
       container_name: gitlab
       restart: always
       hostname: 'gitlab.example.com'
       ports:
         - "22:22"
         - "80:80"
         - "443:443"
       volumes:
         - $GITLAB_HOME/data:/var/opt/gitlab
         - $GITLAB_HOME/logs:/var/log/gitlab
         - $GITLAB_HOME/config:/etc/gitlab
       shm_size: '256m'
       environment:
         GITLAB_OMNIBUS_CONFIG: "from_file('/omnibus_config.rb')"
       configs:
         - source: gitlab
           target: /omnibus_config.rb
       secrets:
         - gitlab_root_password
     gitlab-runner:
       image: gitlab/gitlab-runner:alpine
       deploy:
         mode: replicated
         replicas: 4
   configs:
     gitlab:
       file: ./gitlab.rb
   secrets:
     gitlab_root_password:
       file: ./root_password.txt
   ```

   복잡성을 줄이기 위해 위의 예제에서는 `network` 구성을 제외합니다. 공식 [Compose 파일 참조](https://docs.docker.com/compose/compose-file/)에서 자세한 정보를 찾을 수 있습니다.

1. `gitlab.rb` 파일을 만듭니다:

   ```ruby
   external_url 'https://my.domain.com/'
   gitlab_rails['initial_root_password'] = File.read('/run/secrets/gitlab_root_password').gsub("\n", "")
   ```

1. `root_password.txt` 파일을 만들고 비밀번호를 포함합니다:

   ```plaintext
   MySuperSecretAndSecurePassw0rd!
   ```

1. `docker-compose.yml`과 동일한 디렉터리에 있는지 확인한 후 실행합니다:

   ```shell
   docker stack deploy --compose-file docker-compose.yml mystack
   ```

Docker를 설치한 후 [GitLab 인스턴스를 구성](configuration.md)해야 합니다.

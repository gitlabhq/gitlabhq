---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Docker 컨테이너에서 CI/CD 작업을 실행하는 방법을 알아봅니다. Docker 컨테이너는 전용 CI/CD 빌드 서버나 로컬 머신에 호스팅됩니다.
title: Docker 컨테이너에서 CI/CD 작업 실행
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD 작업을 Docker 컨테이너에서 실행할 수 있습니다. 이 컨테이너는 전용 CI/CD 빌드 서버나 로컬 머신에 호스팅됩니다.

Docker 컨테이너에서 CI/CD 작업을 실행하려면 다음을 수행해야 합니다:

1. [Docker 실행기](https://docs.gitlab.com/runner/executors/docker/)를 사용하도록 러너를 등록하고 구성합니다.
1. CI/CD 작업을 실행할 컨테이너 이미지를 `.gitlab-ci.yml` 파일에서 지정합니다.
1. 선택 사항. MySQL과 같은 다른 서비스를 컨테이너에서 실행합니다. `.gitlab-ci.yml` 파일에서 [서비스](../services/_index.md)를 지정하여 이를 수행합니다.

## Docker 실행기를 사용하는 러너 등록 {#register-a-runner-that-uses-the-docker-executor}

러너를 Docker와 함께 사용하려면 Docker 실행기를 사용하는 [러너](https://docs.gitlab.com/runner/register/)를 등록해야 합니다.

이 예제에서는 서비스를 제공할 임시 템플릿을 설정하는 방법을 보여줍니다:

```shell
cat > /tmp/test-config.template.toml << EOF
[[runners]]
[runners.docker]
[[runners.docker.services]]
name = "postgres:latest"
[[runners.docker.services]]
name = "mysql:latest"
EOF
```

이 템플릿을 사용하여 러너를 등록합니다:

```shell
sudo gitlab-runner register \
  --url "https://gitlab.example.com/" \
  --token "$RUNNER_TOKEN" \
  --description "docker-ruby:2.6" \
  --executor "docker" \
  --template-config /tmp/test-config.template.toml \
  --docker-image ruby:3.3
```

등록된 러너는 `ruby:2.6` Docker 이미지를 사용하고 `postgres:latest`와 `mysql:latest` 두 개의 서비스를 실행합니다. 이 두 서비스는 빌드 프로세스 중에 액세스할 수 있습니다.

## 이미지란 무엇인가 {#what-is-an-image}

`image` 키워드는 Docker 실행기가 CI/CD 작업을 실행하는 데 사용하는 Docker 이미지의 이름입니다.

기본적으로 실행기는 [Docker Hub](https://hub.docker.com/)에서 이미지를 가져옵니다. 하지만 `gitlab-runner/config.toml` 파일에서 레지스트리 위치를 구성할 수 있습니다. 예를 들어 [Docker pull 정책](https://docs.gitlab.com/runner/executors/docker/#how-pull-policies-work)을 설정하여 로컬 이미지를 사용할 수 있습니다.

이미지 및 Docker Hub에 대한 자세한 내용은 [Docker 개요](https://docs.docker.com/get-started/overview/)를 참조하세요.

## 이미지 요구사항 {#image-requirements}

CI/CD 작업을 실행하는 데 사용되는 모든 이미지에는 다음 애플리케이션이 설치되어 있어야 합니다:

- `sh` 또는 `bash`
- `grep`

## `.gitlab-ci.yml` 파일에서 `image`을(를) 정의 {#define-image-in-the-gitlab-ciyml-file}

모든 작업에 사용되는 이미지와 런타임 중에 사용하려는 서비스 목록을 정의할 수 있습니다:

```yaml
default:
  image: ruby:2.6
  services:
    - postgres:16.10
  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

이미지 이름은 다음 형식 중 하나여야 합니다:

- `image: <image-name>`(`<image-name>`을 `latest` 태그로 사용하는 것과 동일)
- `image: <image-name>:<tag>`
- `image: <image-name>@<digest>`

## 확장된 Docker 구성 옵션 {#extended-docker-configuration-options}

{{< history >}}

- GitLab 및 GitLab Runner 9.4에서 도입되었습니다.

{{< /history >}}

`image` 또는 `services` 항목에 문자열이나 맵을 사용할 수 있습니다:

- 문자열에는 전체 이미지 이름이 포함되어야 합니다(Docker Hub 이외의 레지스트리에서 이미지를 다운로드하려면 레지스트리 포함).
- 맵에는 최소한 `name` 옵션이 포함되어야 하며, 이는 문자열 설정에 사용되는 이미지 이름과 동일합니다.

예를 들어 다음 두 정의는 동일합니다:

- `image` 및 `services`의 문자열:

  ```yaml
  image: "registry.example.com/my/image:latest"

  services:
    - postgresql:16.10
    - redis:latest
  ```

- `image` 및 `services`의 맵 `image:name`이(가) 필수입니다:

  ```yaml
  image:
    name: "registry.example.com/my/image:latest"

  services:
    - name: postgresql:16.10
    - name: redis:latest
  ```

## 스크립트가 실행되는 위치 {#where-scripts-are-executed}

CI 작업이 Docker 컨테이너에서 실행되면 `before_script`, `script` 및 `after_script` 명령은 `/builds/<project-path>/` 디렉터리에서 실행됩니다. 이미지에 다른 기본값 `WORKDIR`이(가) 정의되어 있을 수 있습니다. `WORKDIR`로 이동하려면 `WORKDIR`을(를) 환경 변수로 저장하여 작업 실행 중에 컨테이너에서 이를 참조할 수 있도록 합니다.

### 이미지의 진입점 재정의 {#override-the-entrypoint-of-an-image}

{{< history >}}

- GitLab 및 GitLab Runner 9.4에서 도입되었습니다. [확장된 구성 옵션](using_docker_images.md#extended-docker-configuration-options)에 대해 자세히 알아보세요.

{{< /history >}}

사용 가능한 진입점 재정의 방법을 설명하기 전에 러너가 시작되는 방식을 설명하겠습니다. CI/CD 작업에 사용되는 컨테이너에 Docker 이미지를 사용합니다:

1. 러너는 정의된 진입점을 사용하여 Docker 컨테이너를 시작합니다. `.gitlab-ci.yml` 파일에서 재정의될 수 있는 `Dockerfile`의 기본값
1. 러너가 실행 중인 컨테이너에 자신을 연결합니다.
1. 러너가 스크립트를 준비합니다([`before_script`](../yaml/_index.md#before_script), [`script`](../yaml/_index.md#script) 및 [`after_script`](../yaml/_index.md#after_script)의 조합).
1. 러너는 스크립트를 컨테이너의 셸 `stdin`로 전송하고 출력을 받습니다.

Docker 이미지의 [진입점](https://docs.gitlab.com/runner/executors/docker/#configure-a-docker-entrypoint)을(를) 재정의하려면 `.gitlab-ci.yml` 파일에서 다음을 수행합니다:

- Docker 17.06 이상의 경우 `entrypoint`을(를) 빈 값으로 설정합니다.
- Docker 17.03 이하의 경우 `entrypoint`을(를) `/bin/sh -c`, `/bin/bash -c` 또는 이미지에서 사용 가능한 동등한 셸로 설정합니다.

`image:entrypoint`의 구문은 [Dockerfile `ENTRYPOINT`](https://docs.docker.com/reference/dockerfile/#entrypoint)과(와) 유사합니다.

`super/sql:experimental` 이미지가 있다고 가정해봅시다. 여기에 SQL 데이터베이스가 포함되어 있습니다. 이 데이터베이스 바이너리로 일부 테스트를 실행하려고 하기 때문에 작업의 기본 이미지로 사용하려고 합니다. 또한 이 이미지가 `/usr/bin/super-sql run`을(를) 진입점으로 구성되어 있다고 가정해봅시다. 컨테이너가 추가 옵션 없이 시작되면 데이터베이스 프로세스가 실행됩니다. 러너는 이미지에 진입점이 없거나 진입점이 셸 명령을 시작하도록 준비되어 있을 것으로 예상합니다.

확장된 Docker 구성 옵션을 사용하면 다음 대신:

- `super/sql:experimental`을(를) 기반으로 하는 자신의 이미지를 생성합니다.
- `ENTRYPOINT`을(를) 셸로 설정합니다.
- CI 작업에서 새 이미지를 사용합니다.

이제 `.gitlab-ci.yml` 파일에서 `entrypoint`을(를) 정의할 수 있습니다.

**For Docker 17.06 and later**:

```yaml
image:
  name: super/sql:experimental
  entrypoint: [""]
```

**For Docker 17.03 and earlier**:

```yaml
image:
  name: super/sql:experimental
  entrypoint: ["/bin/sh", "-c"]
```

## `config.toml`에서 이미지 및 서비스 정의 {#define-image-and-services-in-configtoml}

`config.toml` 파일에서 다음을 정의할 수 있습니다:

- [`[runners.docker]`](https://docs.gitlab.com/runner/configuration/advanced-configuration#the-runnersdocker-section) 섹션에서 CI/CD 작업을 실행하는 데 사용되는 컨테이너 이미지
- [`[[runners.docker.services]]`](https://docs.gitlab.com/runner/configuration/advanced-configuration#the-runnersdockerservices-section) 섹션에서 [services](../services/_index.md) 컨테이너

```toml
[runners.docker]
  image = "ruby:latest"
  services = ["mysql:latest", "postgres:latest"]
```

이러한 방식으로 정의된 이미지 및 서비스는 해당 러너에서 실행하는 모든 작업에 추가됩니다.

## 프라이빗 컨테이너 레지스트리에서 이미지 액세스 {#access-an-image-from-a-private-container-registry}

프라이빗 컨테이너 레지스트리에 액세스하려면 러너 프로세스에서 다음을 사용할 수 있습니다:

- [정적으로 정의된 자격증명](#use-statically-defined-credentials) 특정 레지스트리에 대한 사용자 이름 및 암호
- [자격증명 저장소](#use-a-credentials-store) 자세한 내용은 [관련 Docker 문서](https://docs.docker.com/reference/cli/docker/login/#credential-stores)를 참조하세요.
- [자격증명 도우미](#use-credential-helpers) 자세한 내용은 [관련 Docker 문서](https://docs.docker.com/reference/cli/docker/login/#credential-helpers)를 참조하세요.

동일한 GitLab 인스턴스에서 [GitLab Container Registry](../../user/packages/container_registry/_index.md)를 사용하는 경우 GitLab은 이 컨테이너 레지스트리에 대한 기본 자격증명을 제공합니다. 이 자격증명을 사용하면 `CI_JOB_TOKEN`이(가) 인증에 사용됩니다. 작업 토큰을 사용하려면 작업을 시작하는 사용자가 프라이빗 이미지가 호스팅되는 프로젝트에 대해 개발자, 유지 관리자 또는 소유자 역할을 가져야 합니다. 프라이빗 이미지를 호스팅하는 프로젝트는 다른 프로젝트가 작업 토큰으로 인증할 수 있도록 허용해야 합니다. 이 액세스는 기본적으로 사용하지 않도록 설정되어 있습니다. 자세한 내용은 [CI/CD 작업 토큰](../jobs/ci_job_token.md#control-job-token-access-to-your-project)을 참조하세요.

사용할 옵션을 정의하려면 러너 프로세스가 이 순서대로 구성을 읽습니다:

- `/root/.docker` 디렉터리에 있는 `config.json` 파일
- `DOCKER_AUTH_CONFIG` [CI/CD 변수](../variables/_index.md)
- 러너의 `config.toml` 파일에 설정된 `DOCKER_AUTH_CONFIG` 환경 변수
- 프로세스를 실행하는 사용자의 `$HOME/.docker` 디렉터리에 있는 `config.json` 파일 자식 프로세스를 권한이 없는 사용자로 실행하기 위해 `--user` 플래그를 제공하면 주 러너 프로세스 사용자의 홈 디렉터리가 사용됩니다.

### 요구사항 및 제한사항 {#requirements-and-limitations}

- [자격증명 저장소](#use-a-credentials-store) 및 [자격증명 도우미](#use-credential-helpers)에는 바이너리를 러너 `$PATH`에 추가해야 하며, 이를 수행할 액세스 권한이 필요합니다. 따라서 이러한 기능은 인스턴스 러너나 러너가 설치된 환경에 액세스할 수 없는 다른 러너에서는 사용할 수 없습니다.

### 정적으로 정의된 자격증명 사용 {#use-statically-defined-credentials}

두 가지 접근 방식을 사용하여 프라이빗 레지스트리에 액세스할 수 있습니다. 두 방식 모두 적절한 인증 정보로 CI/CD 변수 `DOCKER_AUTH_CONFIG`을(를) 설정해야 합니다.

1. 작업별: 한 작업이 프라이빗 레지스트리에 액세스하도록 구성하려면 `DOCKER_AUTH_CONFIG`을(를) [CI/CD 변수](../variables/_index.md)로 추가하세요.
1. 러너별: 러너의 모든 작업이 프라이빗 레지스트리에 액세스할 수 있도록 구성하려면 러너 구성에서 `DOCKER_AUTH_CONFIG`을(를) 환경 변수로 추가하세요.

각 예제는 다음 섹션을 참조하세요.

#### `DOCKER_AUTH_CONFIG` 데이터 결정 {#determine-your-docker_auth_config-data}

예를 들어 `registry.example.com:5000/private/image:latest` 이미지를 사용하고 싶다고 가정해봅시다. 이 이미지는 프라이빗이며 프라이빗 컨테이너 레지스트리에 로그인해야 합니다.

다음이 로그인 자격증명이라고 가정해봅시다:

| 키      | 값 |
|:---------|:------|
| 레지스트리 | `registry.example.com:5000` |
| 사용자 이름 | `my_username` |
| 암호 | `my_password` |

`DOCKER_AUTH_CONFIG`의 값을 결정하기 위해 다음 방법 중 하나를 사용합니다:

- 로컬 머신에서 `docker login`을(를) 수행합니다:

  ```shell
  docker login registry.example.com:5000 --username my_username --password my_password
  ```

  그런 다음 `~/.docker/config.json`의 내용을 복사합니다.

  컴퓨터에서 레지스트리에 액세스할 필요가 없으면 `docker logout`을(를) 수행할 수 있습니다:

  ```shell
  docker logout registry.example.com:5000
  ```

- 일부 설정에서는 Docker 클라이언트가 사용 가능한 시스템 키 저장소를 사용하여 `docker login`의 결과를 저장할 수 있습니다. 이 경우 `~/.docker/config.json`을(를) 읽을 수 없으므로 `${username}:${password}`의 필수 base64 인코딩 버전을 준비하고 Docker 구성 JSON을 수동으로 생성해야 합니다. 터미널을 열고 다음 명령을 실행합니다:

  ```shell
  # The use of printf (as opposed to echo) prevents encoding a newline in the password.
  printf "my_username:my_password" | openssl base64 -A

  # Example output to copy
  bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ=
  ```

  > [!note]
  > 사용자 이름에 `@` 같은 특수 문자가 포함되어 있으면 인증 문제를 방지하기 위해 백슬래시(` \ `)로 이스케이프해야 합니다.

  다음과 같이 Docker JSON 구성 내용을 생성합니다:

  ```json
  {
      "auths": {
          "registry.example.com:5000": {
              "auth": "(Base64 content from above)"
          }
      }
  }
  ```

#### 작업 구성 {#configure-a-job}

`registry.example.com:5000`에 대한 액세스 권한이 있는 단일 작업을 구성하려면 다음 단계를 따르세요:

1. [CI/CD 변수](../variables/_index.md) `DOCKER_AUTH_CONFIG`을(를) Docker 구성 파일의 내용을 값으로 하여 생성합니다:

   ```json
   {
       "auths": {
           "registry.example.com:5000": {
               "auth": "bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ="
           }
       }
   }
   ```

1. 이제 `registry.example.com:5000`에서 정의한 `image` 또는 `services`의 프라이빗 이미지를 `.gitlab-ci.yml` 파일에서 사용할 수 있습니다:

   ```yaml
   image: registry.example.com:5000/namespace/image:tag
   ```

   이전 예제에서 러너는 `registry.example.com:5000`에서 `namespace/image:tag` 이미지를 찾습니다.

원하는 만큼 많은 레지스트리에 대한 구성을 추가할 수 있으며, 이전에 설명한 대로 `"auths"` 해시에 더 많은 레지스트리를 추가할 수 있습니다.

러너가 `DOCKER_AUTH_CONFIG`과(와) 일치하려면 `hostname:port` 조합이 필요합니다. 예를 들어 `.gitlab-ci.yml` 파일에서 `registry.example.com:5000/namespace/image:tag`을(를) 지정한 경우 `DOCKER_AUTH_CONFIG`도 `registry.example.com:5000`을(를) 지정해야 합니다. `registry.example.com`만 지정하는 것은 작동하지 않습니다.

### 러너 구성 {#configuring-a-runner}

동일한 레지스트리에 액세스하는 많은 파이프라인이 있는 경우 러너 수준에서 레지스트리 액세스를 설정해야 합니다. 이를 통해 파이프라인 작성자는 적절한 러너에서 작업을 실행하기만 하면 프라이빗 레지스트리에 액세스할 수 있습니다. 또한 레지스트리 변경 및 자격증명 회전을 단순화할 수 있습니다.

이는 해당 러너의 모든 작업이 프로젝트 전체에서도 동일한 권한으로 레지스트리에 액세스할 수 있음을 의미합니다. 레지스트리에 대한 액세스를 제어해야 하는 경우 러너에 대한 액세스도 제어해야 합니다.

러너에 `DOCKER_AUTH_CONFIG`을(를) 추가하려면:

1. 러너의 `config.toml` 파일을 다음과 같이 수정합니다:

   ```toml
   [[runners]]
     environment = ["DOCKER_AUTH_CONFIG={\"auths\":{\"registry.example.com:5000\":{\"auth\":\"bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ=\"}}}"]
   ```

   - `DOCKER_AUTH_CONFIG` 데이터에 포함된 큰따옴표는 백슬래시로 이스케이프해야 합니다. 이는 TOML로 해석되지 않도록 방지합니다.
   - `environment` 옵션은 목록입니다. 러너에 기존 항목이 있을 수 있으므로 이를 목록에 추가해야 하며 바꾸면 안 됩니다.

1. 러너 서비스를 다시 시작합니다.

### 자격증명 저장소 사용 {#use-a-credentials-store}

자격증명 저장소를 구성하려면:

1. 자격증명 저장소를 사용하려면 특정 키체인이나 외부 저장소와 상호작용할 외부 도우미 프로그램이 필요합니다. 도우미 프로그램이 러너 `$PATH`에서 사용 가능한지 확인합니다.

1. 러너가 이를 사용하도록 합니다. 다음 옵션 중 하나를 사용하여 이를 수행할 수 있습니다:

   - [CI/CD 변수](../variables/_index.md) `DOCKER_AUTH_CONFIG`을(를) Docker 구성 파일의 내용을 값으로 하여 생성합니다:

     ```json
       {
         "credsStore": "osxkeychain"
       }
     ```

   - 또는 자체 관리 러너를 실행하는 경우 JSON을 `${GITLAB_RUNNER_HOME}/.docker/config.json`에 추가합니다. 러너는 이 구성 파일을 읽고 이 특정 리포지토리에 필요한 도우미를 사용합니다.

`credsStore`은(는) **전체** 컨테이너 레지스트리에 액세스하는 데 사용됩니다. 프라이빗 컨테이너 레지스트리의 이미지와 Docker Hub의 공개 이미지를 모두 사용하는 경우 Docker Hub에서 가져오기가 실패합니다. Docker 데몬은 **전체** 컨테이너 레지스트리에 대해 동일한 자격증명을 사용하려고 시도합니다.

### 자격증명 도우미 사용 {#use-credential-helpers}

예를 들어 `<aws_account_id>.dkr.ecr.<region>.amazonaws.com/private/image:latest` 이미지를 사용하고 싶다고 가정해봅시다. 이 이미지는 프라이빗이며 프라이빗 컨테이너 레지스트리에 로그인해야 합니다.

`<aws_account_id>.dkr.ecr.<region>.amazonaws.com`에 대한 액세스를 구성하려면 다음 단계를 따르세요:

1. [`docker-credential-ecr-login`](https://github.com/awslabs/amazon-ecr-credential-helper)이(가) 러너 `$PATH`에서 사용 가능한지 확인합니다.
1. 다음 중 하나의 [AWS 자격증명 설정](https://github.com/awslabs/amazon-ecr-credential-helper#aws-credentials)이 있습니다. GitLab Runner Manager는 자격증명을 획득하고 러너에 전달합니다. 러너가 자격증명에 액세스할 수 있는지 확인합니다.
1. 러너가 이를 사용하도록 합니다. 다음 옵션 중 하나를 사용하여 이를 수행할 수 있습니다:

   - [CI/CD 변수](../variables/_index.md) `DOCKER_AUTH_CONFIG`을(를) Docker 구성 파일의 내용을 값으로 하여 생성합니다:

     ```json
     {
       "credHelpers": {
         "<aws_account_id>.dkr.ecr.<region>.amazonaws.com": "ecr-login"
       }
     }
     ```

     이는 특정 레지스트리에 대해 자격증명 도우미를 사용하도록 Docker를 구성합니다.

     대신 모든 Amazon Elastic Container Registry(ECR) 레지스트리에 대해 자격증명 도우미를 사용하도록 Docker를 구성할 수 있습니다:

     ```json
     {
       "credsStore": "ecr-login"
     }
     ```

     > [!note]
     > `{"credsStore": "ecr-login"}`을(를) 사용하는 경우 AWS 공유 구성 파일(`~/.aws/config`)에서 리전을 명시적으로 설정합니다. ECR 자격증명 도우미가 인증 토큰을 검색할 때 리전을 지정해야 합니다.

   - 또는 자체 관리 러너를 실행하는 경우 이전 JSON을 `${GITLAB_RUNNER_HOME}/.docker/config.json`에 추가합니다. 러너는 이 구성 파일을 읽고 이 특정 리포지토리에 필요한 도우미를 사용합니다.

1. 이제 `<aws_account_id>.dkr.ecr.<region>.amazonaws.com`에서 정의한 `image` 및/또는 `services`의 프라이빗 이미지를 `.gitlab-ci.yml` 파일에서 사용할 수 있습니다:

   ```yaml
   image: <aws_account_id>.dkr.ecr.<region>.amazonaws.com/private/image:latest
   ```

   이 예제에서 러너는 `<aws_account_id>.dkr.ecr.<region>.amazonaws.com`에서 `private/image:latest` 이미지를 찾습니다.

원하는 만큼 많은 레지스트리에 대한 구성을 추가할 수 있으며, `"credHelpers"` 해시에 더 많은 레지스트리를 추가할 수 있습니다.

### 체크섬을 사용하여 이미지를 안전하게 유지 {#use-checksum-to-keep-your-image-secure}

작업 정의에서 이미지 체크섬을 `.gitlab-ci.yml` 파일에 사용하여 이미지의 무결성을 확인합니다. 이미지 무결성 확인이 실패하면 수정된 컨테이너를 사용할 수 없습니다.

이미지 체크섬을 사용하려면 체크섬을 끝에 추가해야 합니다:

```yaml
image: ruby:2.6.8@sha256:d1dbaf9665fe8b2175198e49438092fdbcf4d8934200942b94425301b17853c7
```

이미지 체크섬을 얻으려면 이미지 `TAG` 탭에서 `DIGEST` 열을 봅니다. 예를 들어 [Ruby 이미지](https://hub.docker.com/_/ruby?tab=tags)를 봅니다. 체크섬은 `6155f0235e95` 같은 임의의 문자열입니다.

시스템의 모든 이미지의 체크섬을 `docker images --digests` 명령으로 얻을 수도 있습니다:

```shell
❯ docker images --digests
REPOSITORY                                                        TAG       DIGEST                                                                    (...)
gitlab/gitlab-ee                                                  latest    sha256:723aa6edd8f122d50cae490b1743a616d54d4a910db892314d68470cc39dfb24   (...)
gitlab/gitlab-runner                                              latest    sha256:4a18a80f5be5df44cb7575f6b89d1fdda343297c6fd666c015c0e778b276e726   (...)
```

## 사용자 정의 GitLab Runner Docker 이미지 생성 {#creating-a-custom-gitlab-runner-docker-image}

AWS CLI 및 Amazon ECR 자격증명 도우미를 패키징하기 위해 사용자 정의 GitLab Runner Docker 이미지를 생성할 수 있습니다. 이 설정은 특히 컨테이너화된 애플리케이션을 위해 AWS 서비스와의 안전하고 간소화된 상호작용을 촉진합니다. 예를 들어 이 설정을 사용하여 Amazon ECR에서 Docker 이미지를 관리, 배포 및 업데이트합니다. 이 설정은 시간이 많이 걸리고 오류가 발생하기 쉬운 구성 및 수동 자격증명 관리를 피할 수 있습니다.

1. [GitLab을 AWS와 인증](../cloud_deployment/_index.md#authenticate-gitlab-with-aws)합니다.
1. `Dockerfile`을 다음 콘텐츠로 생성합니다:

   ```Dockerfile
   # Control package versions
   ARG GITLAB_RUNNER_VERSION=v17.3.0
   ARG AWS_CLI_VERSION=2.17.36

   # AWS CLI and Amazon ECR Credential Helper
   FROM amazonlinux as aws-tools
   RUN set -e \
       && yum update -y \
       && yum install -y --allowerasing git make gcc curl unzip \
       && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" --output "awscliv2.zip" \
       && unzip awscliv2.zip && ./aws/install -i /usr/local/bin \
       && yum clean all

   # Download and install ECR Credential Helper
   RUN curl --location --output  /usr/local/bin/docker-credential-ecr-login "https://github.com/awslabs/amazon-ecr-credential-helper/releases/latest/download/docker-credential-ecr-login-linux-amd64"
   RUN chmod +x /usr/local/bin/docker-credential-ecr-login

   # Configure the ECR Credential Helper
   RUN mkdir -p /root/.docker
   RUN echo '{ "credsStore": "ecr-login" }' > /root/.docker/config.json

   # Final image based on GitLab Runner
   FROM gitlab/gitlab-runner:${GITLAB_RUNNER_VERSION}

   # Install necessary packages
   RUN apt-get update \
       && apt-get install -y --no-install-recommends jq procps curl unzip groff libgcrypt20 tar gzip less openssh-client \
       && apt-get clean && rm -rf /var/lib/apt/lists/*

   # Copy AWS CLI and Amazon ECR Credential Helper binaries
   COPY --from=aws-tools /usr/local/bin/ /usr/local/bin/

   # Copy ECR Credential Helper Configuration
   COPY --from=aws-tools /root/.docker/config.json /root/.docker/config.json
   ```

1. `.gitlab-ci.yml`에서 사용자 정의 GitLab Runner Docker 이미지를 빌드하려면 다음 예제를 포함합니다:

   ```yaml
   variables:
     DOCKER_DRIVER: overlay2
     IMAGE_NAME: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_NAME
     GITLAB_RUNNER_VERSION: v17.3.0
     AWS_CLI_VERSION: 2.17.36

   stages:
     - build

   build-image:
     stage: build
     script:
       - echo "Logging into GitLab container registry..."
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
       - echo "Building Docker image..."
       - docker build --build-arg GITLAB_RUNNER_VERSION=${GITLAB_RUNNER_VERSION} --build-arg AWS_CLI_VERSION=${AWS_CLI_VERSION} -t ${IMAGE_NAME} .
       - echo "Pushing Docker image to GitLab container registry..."
       - docker push ${IMAGE_NAME}
     rules:
       - changes:
           - Dockerfile
   ```

1. [러너 등록](https://docs.gitlab.com/runner/register/#docker)합니다.

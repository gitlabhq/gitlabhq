---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Docker-in-Docker에서 레지스트리 인증
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Docker-in-Docker를 사용할 때 새로운 Docker 데몬이 서비스와 함께 시작되므로 [표준 인증 방법](using_docker_images.md#access-an-image-from-a-private-container-registry)은 작동하지 않습니다.

## 옵션 1: `docker login` 실행 {#option-1-run-docker-login}

[`before_script`](../yaml/_index.md#before_script)에서 `docker login`을 실행합니다:

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - docker:24.0.5-dind

variables:
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  before_script:
    - echo "$DOCKER_REGISTRY_PASS" | docker login $DOCKER_REGISTRY --username $DOCKER_REGISTRY_USER --password-stdin
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

Docker Hub에 로그인하려면 `$DOCKER_REGISTRY`을 비워 두거나 제거하세요.

## 옵션 2: 각 작업에 `~/.docker/config.json`을 마운트합니다 {#option-2-mount-dockerconfigjson-on-each-job}

GitLab 러너 관리자인 경우 인증 구성이 포함된 파일을 `~/.docker/config.json`에 마운트할 수 있습니다. 그러면 러너가 선택한 모든 작업이 이미 인증되어 있습니다. 공식 `docker:24.0.5` 이미지를 사용하는 경우 홈 디렉터리는 `/root`에 있습니다.

구성 파일을 마운트하면 `docker` 명령이 `~/.docker/config.json`를 수정하려고 할 때 실패합니다. 예를 들어 `docker login`은 파일이 읽기 전용으로 마운트되어 있으므로 실패합니다. 읽기 전용으로 변경하지 마세요. 이렇게 하면 문제가 발생합니다.

다음은 `/opt/.docker/config.json`의 예시입니다. [`DOCKER_AUTH_CONFIG`](using_docker_images.md#determine-your-docker_auth_config-data) 설명서를 따릅니다:

```json
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ="
        }
    }
}
```

### Docker {#docker}

[볼륨 마운트](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section)를 업데이트하여 파일을 포함하세요.

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    volumes = ["/opt/.docker/config.json:/root/.docker/config.json:ro"]
```

### Kubernetes {#kubernetes}

이 파일의 콘텐츠를 사용하여 [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/)을 생성합니다. 다음과 같은 명령으로 이를 수행할 수 있습니다:

```shell
kubectl create configmap docker-client-config --namespace gitlab-runner --from-file /opt/.docker/config.json
```

[볼륨 마운트](https://docs.gitlab.com/runner/executors/kubernetes/#custom-volume-mount)를 업데이트하여 파일을 포함하세요.

```toml
[[runners]]
  ...
  executor = "kubernetes"
  [runners.kubernetes]
    image = "alpine:3.12"
    privileged = true
    [[runners.kubernetes.volumes.config_map]]
      name = "docker-client-config"
      mount_path = "/root/.docker/config.json"
      sub_path = "config.json"
```

## 옵션 3: `DOCKER_AUTH_CONFIG` 사용 {#option-3-use-docker_auth_config}

[`DOCKER_AUTH_CONFIG`](using_docker_images.md#determine-your-docker_auth_config-data)을 이미 정의했다면 변수를 사용하여 `~/.docker/config.json`에 저장할 수 있습니다.

다음과 같은 여러 방법으로 이 인증을 정의할 수 있습니다:

- 러너 구성 파일의 [`pre_build_script`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)에서.
- [`before_script`](../yaml/_index.md#before_script)에서.
- [`script`](../yaml/_index.md#script)에서.

다음 예시에서 [`before_script`](../yaml/_index.md#before_script)를 보여 줍니다. 구현하는 모든 솔루션에 동일한 명령이 적용됩니다.

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - docker:24.0.5-dind

variables:
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  before_script:
    - mkdir -p $HOME/.docker
    - echo $DOCKER_AUTH_CONFIG > $HOME/.docker/config.json
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

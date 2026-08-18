---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: '튜토리얼: OpenShift에서 GitLab Runner Operator를 사용하여 루트 없는 컨테이너에서 Buildah 사용'
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 튜토리얼은 `buildah` 도구를 사용하여 이미지를 성공적으로 빌드하는 방법을 알려주며, [GitLab Runner Operator](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator)를 사용하여 배포된 GitLab 러너를 OpenShift 클러스터에서 사용합니다.

이 가이드는 GitLab Runner Operator를 위한 [루트 없는 OpenShift 컨테이너에서 Buildah를 사용하여 이미지 빌드](https://github.com/containers/buildah/blob/main/docs/tutorials/05-openshift-rootless-build.md) 문서의 개정본입니다.

이 튜토리얼을 완료하려면 다음을 수행합니다:

1. Buildah 이미지를 구성합니다.
1. 서비스 계정을 구성합니다.
1. 작업을 구성합니다.

## 시작하기 전에 {#before-you-begin}

이 튜토리얼을 완료하기 전에 다음이 있는지 확인합니다:

- 네임스페이스 `gitlab-runner`에 이미 배포된 러너입니다.

## Buildah 이미지 구성 {#configure-the-buildah-image}

`quay.io/buildah/stable:v1.23.1` 이미지를 기반으로 사용자 지정 이미지를 준비하여 시작합니다.

1. `Containerfile-buildah` 파일을 만듭니다:

   ```shell
   cat > Containerfile-buildah <<EOF
   FROM quay.io/buildah/stable:v1.23.1

   RUN touch /etc/subgid /etc/subuid \
   && chmod g=u /etc/subgid /etc/subuid /etc/passwd \
   && echo build:10000:65536 > /etc/subuid \
   && echo build:10000:65536 > /etc/subgid

   # Use chroot because the default runc does not work when running rootless
   RUN echo "export BUILDAH_ISOLATION=chroot" >> /home/build/.bashrc

   # Use VFS because fuse does not work
   RUN mkdir -p /home/build/.config/containers \
   && (echo '[storage]';echo 'driver = "vfs"') > /home/build/.config/containers/storage.conf

   # The buildah container will run as `build` user
   USER build
   WORKDIR /home/build
   EOF
   ```

1. Buildah 이미지를 컨테이너 레지스트리에 빌드하고 푸시합니다. [GitLab 컨테이너 레지스트리](../../user/packages/container_registry/_index.md)에 푸시합시다:

   ```shell
   docker build -f Containerfile-buildah -t registry.example.com/group/project/buildah:1.23.1 .
   docker push registry.example.com/group/project/buildah:1.23.1
   ```

## 서비스 계정 구성 {#configure-the-service-account}

이 단계에서는 OpenShift 클러스터에 연결된 터미널에서 명령을 실행해야 합니다.

1. 이 명령을 실행하여 `buildah-sa` 이름의 서비스 계정을 만듭니다:

   ```shell
   oc create -f - <<EOF
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: buildah-sa
     namespace: gitlab-runner
   EOF
   ```

1. 생성된 서비스 계정에 `anyuid` [SCC](https://docs.openshift.com/container-platform/4.3/authentication/managing-security-context-constraints.html)로 실행할 수 있는 권한을 부여합니다:

   ```shell
   oc adm policy add-scc-to-user anyuid -z buildah-sa -n gitlab-runner
   ```

1. [러너 구성 템플릿](https://docs.gitlab.com/runner/configuration/configuring_runner_operator/#customize-configtoml-with-a-configuration-template)을 사용하여 새 서비스 계정을 사용하도록 Operator를 구성합니다. 다음을 포함하는 `custom-config.toml` 파일을 만듭니다:

   ```toml
   [[runners]]
     [runners.kubernetes]
         service_account_overwrite_allowed = "buildah-*"
   ```

1. `ConfigMap` 이름의 `custom-config-toml`을 `custom-config.toml` 파일에서 만듭니다:

   ```shell
   oc create configmap custom-config-toml --from-file config.toml=custom-config.toml -n gitlab-runner
   ```

1. `config` 속성의 `Runner`을 [사용자 정의 리소스 정의(CRD) 파일](https://docs.gitlab.com/runner/install/operator/#install-gitlab-runner)을 업데이트하여 설정합니다:

   ```yaml
   apiVersion: apps.gitlab.com/v1beta2
   kind: Runner
   metadata:
     name: buildah-runner
   spec:
     gitlabUrl: https://gitlab.example.com
     token: gitlab-runner-secret
     config: custom-config-toml
   ```

## 작업 구성 {#configure-the-job}

마지막 단계는 프로젝트에 GitLab CI/CD 구성 파일을 설정하여 새 Buildah 이미지와 구성된 서비스 계정을 사용하는 것입니다:

```yaml
build:
  stage: build
  image: registry.example.com/group/project/buildah:1.23.1
  variables:
    STORAGE_DRIVER: vfs
    BUILDAH_FORMAT: docker
    BUILDAH_ISOLATION: chroot
    FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE/test"
    KUBERNETES_SERVICE_ACCOUNT_OVERWRITE: "buildah-sa"
  before_script:
    # Log in to the GitLab container registry
    - buildah login -u "$CI_REGISTRY_USER" --password $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - buildah images
    - buildah build -t $FQ_IMAGE_NAME
    - buildah images
    - buildah push $FQ_IMAGE_NAME
```

작업은 빌드한 이미지를 `image` 키워드의 값으로 사용해야 합니다.

`KUBERNETES_SERVICE_ACCOUNT_OVERWRITE` 변수는 생성한 서비스 계정 이름의 값을 가져야 합니다.

축하합니다. 루트 없는 컨테이너에서 Buildah를 사용하여 이미지를 성공적으로 빌드했습니다!

## 문제 해결 {#troubleshooting}

루트가 아닌 사용자로 실행할 때 [알려진 이슈](https://github.com/containers/buildah/issues/4049)가 있습니다. OpenShift 러너를 사용하는 경우 [해결 방법](https://docs.gitlab.com/runner/configuration/configuring_runner_operator/#configure-setfcap)을 사용해야 할 수 있습니다.

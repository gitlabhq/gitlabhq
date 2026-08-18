---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab을 마이크로서비스로 사용하기
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

많은 애플리케이션이 JSON API에 액세스해야 하므로 애플리케이션 테스트도 API에 액세스해야 할 수 있습니다. 다음 예시는 GitLab을 마이크로서비스로 사용하여 테스트에 GitLab API에 대한 액세스 권한을 제공하는 방법을 보여줍니다.

1. Docker 또는 Kubernetes 실행기로 [러너](../runners/_index.md)를 구성합니다.
1. `.gitlab-ci.yml`에 다음을 추가합니다:

   ```yaml
   services:
     - name: gitlab/gitlab-ce:latest
       alias: gitlab

   variables:
     GITLAB_HTTPS: "false"             # ensure that plain http works
     GITLAB_ROOT_PASSWORD: "password"  # to access the api with user root:password
   ```

> [!note]
> GitLab UI에서 설정한 변수는 서비스 컨테이너로 전달되지 않습니다. 자세한 내용은 [CI/CD 변수](../variables/_index.md)를 참조하세요.

그러면 `script` 섹션의 명령을 `.gitlab-ci.yml` 파일에서 `http://gitlab/api/v4`의 API에 액세스할 수 있습니다.

`gitlab`이 `Host`에 사용되는 이유에 대한 자세한 내용은 [서비스가 작업에 연결되는 방식](../docker/using_docker_images.md#extended-docker-configuration-options)을 참조하세요.

[Docker Hub](https://hub.docker.com/u/gitlab)에서 사용할 수 있는 다른 Docker 이미지도 사용할 수 있습니다.

`gitlab` 이미지는 환경 변수를 수락할 수 있습니다. 자세한 내용은 [Linux 패키지 설명서](../../install/_index.md)를 참조하세요.

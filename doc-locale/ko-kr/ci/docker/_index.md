---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Docker 통합
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Docker](https://www.docker.com)를 CI/CD 워크플로우에 두 가지 주요 방식으로 통합할 수 있습니다:

- [CI/CD 작업을 Docker 컨테이너에서 실행합니다](using_docker_images.md).

  Docker 컨테이너에서 실행되는 애플리케이션을 테스트, 빌드 또는 게시하는 작업을 생성합니다. 예를 들어 Docker Hub에서 Node 이미지를 사용하여 필요한 모든 Node 종속성을 포함하는 작업을 컨테이너에서 실행합니다.

- [Docker Build](using_docker_build.md) 또는 [BuildKit](using_buildkit.md)을 사용하여 Docker 이미지를 빌드합니다.

  Docker 이미지를 빌드하고 컨테이너 레지스트리에 게시하는 작업을 생성합니다. BuildKit은 루트리스 빌드를 포함한 여러 접근 방식을 제공합니다.

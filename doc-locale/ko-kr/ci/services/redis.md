---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Redis 사용
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

많은 애플리케이션이 Redis를 키-값 저장소로 사용하므로 테스트를 실행하려면 Redis를 사용해야 합니다.

## Docker 실행기에서 Redis 사용 {#use-redis-with-the-docker-executor}

[GitLab Runner](../runners/_index.md)를 Docker 실행기와 함께 사용 중이라면 기본적으로 모든 설정이 이미 완료된 상태입니다.

먼저 `.gitlab-ci.yml`에 다음을 추가하세요:

```yaml
services:
  - redis:latest
```

그 다음 애플리케이션을 구성하여 Redis 데이터베이스를 사용하도록 설정합니다. 예를 들면 다음과 같습니다:

```yaml
Host: redis
```

이제 완료되었습니다. Redis를 테스트 프레임워크에서 사용할 수 있습니다.

[Docker Hub](https://hub.docker.com/_/redis)에서 사용 가능한 다른 Docker 이미지를 사용할 수도 있습니다. 예를 들어 Redis 6.0을 사용하려면 서비스는 `redis:6.0`가 됩니다.

## Shell 실행기에서 Redis 사용 {#use-redis-with-the-shell-executor}

Redis는 Shell 실행기와 함께 GitLab Runner를 사용하는 수동으로 구성된 서버에서도 사용할 수 있습니다.

빌드 머신에 Redis 서버를 설치합니다:

```shell
sudo apt-get install redis-server
```

`gitlab-runner` 사용자와 함께 서버에 연결할 수 있는지 확인합니다:

```shell
# Try connecting the Redis server
sudo -u gitlab-runner -H redis-cli

# Quit the session
127.0.0.1:6379> quit
```

마지막으로 애플리케이션을 구성하여 데이터베이스를 사용하도록 설정합니다. 예를 들면 다음과 같습니다:

```yaml
Host: localhost
```

## 예제 프로젝트 {#example-project}

편의를 위해 [예제 Redis 프로젝트](https://gitlab.com/gitlab-examples/redis)를 설정했으며, 이는 공개적으로 사용 가능한 [인스턴스 러너](../runners/_index.md)를 사용하여 [GitLab.com](https://gitlab.com)에서 실행됩니다.

수정하고 싶으신가요? 포크한 후 변경 사항을 커밋하고 푸시합니다. 잠시 후 변경 사항이 공개 러너에 의해 선택되고 작업이 시작됩니다.

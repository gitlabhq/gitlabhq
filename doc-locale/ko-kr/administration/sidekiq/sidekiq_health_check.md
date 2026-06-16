---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sidekiq 상태 확인
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab은 서비스 상태와 Sidekiq 클러스터 도달 가능성을 나타내기 위한 활성 상태 및 준비 상태 프로브를 제공합니다. 이 엔드포인트는 [Kubernetes와 같은 스케줄러에 제공](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)할 수 있으며, 시스템이 준비될 때까지 트래픽을 유지하거나 필요에 따라 컨테이너를 다시 시작할 수 있습니다.

상태 확인 서버는 [Sidekiq 구성](_index.md) 시 설정할 수 있습니다.

## 준비 상태 {#readiness}

준비 상태 프로브는 Sidekiq 작업자가 작업을 처리할 준비가 되어 있는지 확인합니다.

```plaintext
GET /readiness
```

서버가 `localhost:8092`에 바인딩되어 있으면, 프로세스 클러스터의 준비 상태를 다음과 같이 프로브할 수 있습니다:

```shell
curl "http://localhost:8092/readiness"
```

성공하면 엔드포인트는 `200` HTTP 상태 코드와 다음과 같은 응답을 반환합니다:

```json
{
   "status": "ok"
}
```

## 활성 상태 {#liveness}

Sidekiq 클러스터가 실행 중인지 확인합니다.

```plaintext
GET /liveness
```

서버가 `localhost:8092`에 바인딩되어 있으면, 프로세스 클러스터의 활성 상태를 다음과 같이 프로브할 수 있습니다:

```shell
curl "http://localhost:8092/liveness"
```

성공하면 엔드포인트는 `200` HTTP 상태 코드와 다음과 같은 응답을 반환합니다:

```json
{
   "status": "ok"
}
```

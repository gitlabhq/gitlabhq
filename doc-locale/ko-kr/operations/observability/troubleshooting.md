---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: 애플리케이션 성능을 모니터링하고 성능 문제를 해결합니다.
ignore_in_report: true
title: 통합관찰 문제 해결
---


{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태: 실험적 기능

{{< /details >}}

통합관찰을 사용할 때 다음과 같은 이슈가 발생할 수 있습니다.

## GitLab Observability 인스턴스 이슈 {#gitlab-observability-instance-issues}

컨테이너 상태 확인:

```shell
docker ps
```

컨테이너 로그 보기:

```shell
docker logs [container_name]
```

## 메뉴가 나타나지 않음 {#menu-doesnt-appear}

1. 통합관찰 서비스 URL이 그룹에 대해 구성되었는지 확인합니다:

   ```ruby
   group = Group.find_by_path('your-group-name')
   group.observability_group_o11y_setting&.o11y_service_url
   ```

1. 경로가 올바르게 등록되었는지 확인합니다:

   ```ruby
   Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('observability') }.map(&:path)
   ```

## 성능 문제 {#performance-issues}

SSH 연결 이슈 또는 성능 저하를 경험하는 경우:

- 인스턴스 유형이 최소 요구 사항(2 vCPU, 8GB RAM)을 충족하는지 확인합니다.
- 더 큰 인스턴스 유형으로 크기 조정을 고려합니다.
- 디스크 공간을 확인하고 필요한 경우 증가합니다.

## 원격 분석이 표시되지 않음 {#telemetry-doesnt-show-up}

원격 분석 데이터가 GitLab Observability에 표시되지 않는 경우:

1. 보안 그룹에서 포트 4317과 4318이 열려 있는지 확인합니다.
1. 다음으로 연결성을 테스트합니다:

   ```shell
   nc -zv [your-o11y-instance-ip] 4317
   nc -zv [your-o11y-instance-ip] 4318
   ```

1. 오류가 있는지 컨테이너 로그를 확인합니다:

   ```shell
   docker logs otel-collector-standard
   docker logs o11y-otel-collector
   docker logs o11y
   ```

1. gRPC(4317) 대신 HTTP 엔드포인트(4318)를 사용해 봅니다.
1. OpenTelemetry 설정에 더 많은 디버깅 정보를 추가합니다.

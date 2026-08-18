---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: "GitLab Observability API에 액세스하여 추적, 메트릭 및 로그를 프로그래밍 방식으로 쿼리합니다."
ignore_in_report: true
title: 통합관찰 API 액세스
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태: 실험적 기능

{{< /details >}}

GitLab Observability API를 사용하여 추적, 메트릭 및 로그를 쿼리하고 대시보드 및 알림을 프로그래밍 방식으로 관리합니다.

## 전제 조건 {#prerequisites}

- 통합관찰을 그룹에 대해 활성화해야 합니다. 설정 지침은 [GitLab.com에서 통합관찰 설정](setup_gitlab_com.md) 또는 [GitLab Self-Managed에서 통합관찰 설정](setup_self_managed.md)을 참조하세요.
- 그룹에 대해 Developer, Maintainer 또는 Owner 역할이 필요합니다.

## API 키 가져오기 {#get-your-api-key}

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **통합관찰** > **API Keys**를 선택합니다.
1. API 키를 복사합니다.

API 요청을 할 때 `SIGNOZ-API-KEY` 헤더에서 이 키를 사용합니다.

## API 엔드포인트 {#api-endpoint}

API 엔드포인트는 GitLab 제공 서비스에 따라 다릅니다.

### GitLab.com {#gitlabcom}

API 기본 URL은 다음 패턴을 따릅니다:

```plaintext
https://<group_id>.gitlab-o11y.com
```

`<group_id>`을 GitLab 그룹 ID로 바꿉니다.

### GitLab Self-Managed {#gitlab-self-managed}

API 기본 URL은 그룹에 대해 `o11y_service_url`로 구성한 것과 동일한 URL입니다. 예를 들어:

```plaintext
http://<your-instance-ip>:8080
```

## API 요청 만들기 {#make-api-requests}

모든 요청과 함께 `SIGNOZ-API-KEY` 헤더에 API 키를 포함합니다.

다음 예제는 상태 확인 엔드포인트를 쿼리합니다:

```shell
curl --header "SIGNOZ-API-KEY: <your_api_key>" \
  https://<group_id>.gitlab-o11y.com/api/v1/health
```

`<your_api_key>`을 **API Keys** 페이지의 키로 바꾸고, `<group_id>`을 GitLab 그룹 ID(또는 자체 관리 인스턴스 URL)로 바꿉니다.

## 사용 가능한 API 엔드포인트 {#available-api-endpoints}

GitLab Observability은 SigNoz API를 사용합니다. 사용 가능한 엔드포인트, 요청 및 응답 형식, 사용 예제의 전체 목록은 [SigNoz API 참조](https://signoz.io/api-reference/)를 참조하세요.

## 관련 항목 {#related-topics}

- [GitLab Observability에 원격 측정 데이터 전송](send.md)
- [통합관찰 문제 해결](troubleshooting.md)

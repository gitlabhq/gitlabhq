---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 오프라인 구성
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

인터넷을 통한 외부 리소스에 대한 액세스가 제한되거나 간헐적인 환경의 인스턴스의 경우, 웹 API 퍼지 테스트 작업이 성공적으로 실행되려면 일부 조정이 필요합니다.

단계:

1. Docker 이미지를 로컬 컨테이너 레지스트리에 호스팅합니다.
1. `SECURE_ANALYZERS_PREFIX`을 로컬 컨테이너 레지스트리로 설정합니다.

API 퍼징용 Docker 이미지는 공개 레지스트리에서 가져오기(다운로드)한 후 로컬 레지스트리로 푸시(가져오기)해야 합니다. GitLab 컨테이너 레지스트리를 사용하여 Docker 이미지를 로컬로 호스팅할 수 있습니다. 이 프로세스는 특수 템플릿을 사용하여 수행할 수 있습니다. [오프라인 호스트에 Docker 이미지 로드](../../offline_deployments/_index.md#loading-docker-images-onto-your-offline-host)를 참조하여 지침을 확인합니다.

Docker 이미지가 로컬로 호스팅되면, `SECURE_ANALYZERS_PREFIX` 변수는 로컬 레지스트리의 위치로 설정됩니다. 변수는 `/api-security:2`를 연결하면 유효한 이미지 위치가 되도록 설정되어야 합니다.

예를 들어, 아래 줄은 `registry.gitlab.com/security-products/api-security:2` 이미지의 레지스트리를 설정합니다:

`SECURE_ANALYZERS_PREFIX: "registry.gitlab.com/security-products"`

> [!note]
> `SECURE_ANALYZERS_PREFIX`을 설정하면 모든 GitLab 보안 템플릿의 Docker 이미지 레지스트리 위치가 변경됩니다.

자세한 내용은 [오프라인 환경](../../offline_deployments/_index.md)을(를) 참조하세요.

---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 상대 URL에서 서브도메인으로 마이그레이션
description: GitLab 인스턴스를 상대 URL 대신 서브도메인을 사용하도록 재구성합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

상대 URL 구성에서 서브도메인 배포로 GitLab을 마이그레이션할 수 있습니다.

마이그레이션 중 다운타임은 배포 아키텍처 및 로드 밸런서 구성에 따라 달라집니다:

- GitLab 업그레이드 다운타임:  단일 노드 설치의 경우 GitLab을 재구성하려면 다운타임이 필요합니다. 부하 분산이 있는 다중 노드 설치의 경우 [무중단 업그레이드](../../update/zero_downtime.md) 프로세스를 따라 노드를 순차적으로 업데이트하여 다운타임을 최소화할 수 있습니다.
- URL 전환 중 사용자 대면 다운타임:  영향은 로드 밸런서 및 DNS 구성에 따라 달라집니다. GitLab 구성 변경을 적용하기 전에 로드 밸런서 또는 DNS를 구성하여 이전 URL과 새 URL을 동일한 백엔드로 라우팅하면 전환 중 사용자 대면 중단을 최소화할 수 있습니다.

> [!warning]
> GitLab은 사용할 실제 URL로 구성해야 합니다. GitLab이 API 응답, 이메일 및 UI 요소에 대해 내부적으로 절대 URL을 생성하기 때문에 하나의 URL에 대해 GitLab을 구성하고 로드 밸런서를 사용하여 사용자에게 다른 URL을 제시할 수 없습니다.

## 서브도메인으로 마이그레이션 {#migrate-to-a-subdomain}

상대 URL에서 서브도메인으로 마이그레이션하려면:

1. 설치 유형에 따라 상대 URL 구성을 비활성화하도록 GitLab 구성을 업데이트합니다.

   {{< tabs >}}

   {{< tab title="Linux 패키지(Omnibus)" >}}

      `/etc/gitlab/gitlab.rb`을 편집하고 `external_url`를 업데이트하여 새 서브도메인을 사용합니다:

      ```ruby
      external_url "https://gitlab.example.com"
      ```

   {{< /tab >}}

   {{< tab title="Helm 차트(Kubernetes)" >}}

      [`global.hosts`](https://docs.gitlab.com/charts/charts/globals/#configure-host-settings) 구성을 업데이트하여 새 서브도메인을 사용합니다.

   {{< /tab >}}

   {{< tab title="소스에서 직접 컴파일(source)" >}}

      [GitLab에서 상대 URL 비활성화](../../install/relative_url.md#disable-relative-url-in-gitlab)를 따릅니다.

   {{< /tab >}}

   {{< /tabs >}}

1. 새 서브도메인 구성을 적용하려면 설치 유형에 적용 가능한 [GitLab 인스턴스 업그레이드](../../update/_index.md) 프로세스를 따릅니다.
1. URL을 변경하면 모든 원격 URL이 변경되므로 GitLab 인스턴스를 가리키는 모든 로컬 리포지토리에서 수동으로 편집해야 합니다. 상대 URL을 사용하는 동안 복제된 모든 로컬 리포지토리는 이전 경로를 가리키는 원격 URL을 가지고 있으며 사용자가 수동으로 업데이트해야 합니다.
1. 전환 기간 동안 기존 링크를 유지해야 하는 경우 [로드 밸런서를 구성하여 리디렉션](#configure-load-balancer-redirects)하여 레거시 상대 URL을 새 서브도메인으로 리디렉션합니다.

## 로드 밸런서 리디렉션 구성 {#configure-load-balancer-redirects}

상대 URL에서 서브도메인으로 GitLab을 마이그레이션한 후 로드 밸런서를 구성하여 이전 상대 URL을 새 서브도메인으로 리디렉션합니다:

1. 로드 밸런서에 이전 도메인과 새 도메인 모두에 대한 SSL 인증서가 있는지 확인합니다.
1. 로드 밸런서로 두 도메인을 확인하도록 DNS를 구성합니다.
1. 다음을 수행하는 로드 밸런서 구성에 리디렉션 규칙을 추가합니다:
   - 상대 URL 접두사(예: `/gitlab/`)로 시작하는 경로가 있는 이전 도메인에 대한 요청을 감지합니다.
   - 301(영구 리디렉션) 상태로 요청을 새 서브도메인으로 리디렉션합니다.
   - 경로의 시작 부분에서 상대 URL 접두사를 제거하여 경로 및 쿼리 매개 변수를 유지합니다.
1. 별도의 URL 구성(예: 컨테이너 레지스트리 또는 Pages)이 있는 GitLab 구성 요소가 있는 경우 해당 경로에 유사한 리디렉션 규칙을 추가합니다.

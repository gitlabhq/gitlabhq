---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 세컨더리 사이트의 Geo 프록싱
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- 분리된 URL이 있는 세컨더리 사이트의 HTTP 프록싱이 GitLab 14.5에서 [플래그와 함께](../../feature_flags/_index.md) [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/346112)되었으며, 이름은 `geo_secondary_proxy_separate_urls`입니다. 기본적으로 비활성화됨.
- [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/346112)(GitLab 15.1)

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요. `geo_secondary_proxy_separate_urls` 기능 플래그는 향후 릴리스에서 더 이상 사용되지 않으며 제거될 예정입니다. 읽기 전용 Geo 세컨더리 사이트에 대한 지원이 [이슈 366810](https://gitlab.com/gitlab-org/gitlab/-/issues/366810)에서 제안됩니다.

세컨더리 사이트는 완전한 읽기-쓰기 GitLab 인스턴스로 작동합니다. 모든 작업을 프라이머리 사이트로 투명하게 프록싱합니다. [몇 가지 주목할 만한 예외](#features-accelerated-by-secondary-geo-sites)가 있습니다.

이 동작은 다음과 같은 사용 사례를 가능하게 합니다:

- 모든 Geo 사이트를 단일 URL 뒤에 배치하여 사용자가 도착하는 사이트에 관계없이 일관되고 원활하며 포괄적인 경험을 제공합니다. 사용자가 여러 GitLab URL을 전환할 필요가 없습니다.
- 쓰기 액세스에 대해 걱정하지 않고 트래픽을 지리적으로 부하 분산합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [세컨더리 사이트의 Geo 프록싱](https://www.youtube.com/watch?v=TALLy7__Na8)을 참조하세요.
<!-- Video published on 2022-01-26 -->

알려진 문제는 [Geo 문서의 프록싱 관련 항목](../_index.md#known-issues)을 참조하세요.

## Geo 사이트에 대한 통합 URL 설정 {#set-up-a-unified-url-for-geo-sites}

세컨더리 사이트는 읽기-쓰기 트래픽을 투명하게 제공할 수 있습니다. 따라서 단일 외부 URL을 사용하여 요청이 프라이머리 Geo 사이트 또는 모든 세컨더리 Geo 사이트에 도달할 수 있습니다. 사용자가 도착하는 사이트에 관계없이 일관되고 원활하며 포괄적인 경험을 제공합니다. 사용자가 여러 URL을 전환하거나 여러 사이트의 개념을 인식할 필요가 없습니다.

다음을 사용하여 Geo 사이트로 트래픽을 라우팅할 수 있습니다:

- 지역 인식 DNS. 프라이머리 또는 세컨더리인지 여부에 관계없이 가장 가까운 Geo 사이트로 트래픽을 라우팅합니다. 예를 들어 [위치 인식 DNS 구성](#configure-location-aware-dns)을 따릅니다.
- 라운드 로빈 DNS.
- 로드 밸런서. 인증 오류 및 크로스 사이트 요청 오류를 방지하려면 스티키 세션을 사용해야 합니다. DNS 라우팅은 기본적으로 스티키이므로 이 주의 사항을 공유하지 않습니다.

### 위치 인식 DNS 구성 {#configure-location-aware-dns}

이 예를 따라 프라이머리 또는 세컨더리인지 여부에 관계없이 가장 가까운 Geo 사이트로 트래픽을 라우팅합니다.

#### 필수 요구 사항 {#prerequisites}

이 예에서는 `gitlab.example.com` 서브도메인을 만들어 자동으로 요청을 지시합니다:

- 유럽에서는 **세컨더리** 사이트로 이동합니다.
- 다른 모든 위치에서는 **프라이머리** 사이트로 이동합니다.

이 예를 위해 필요한 항목:

- 작동하는 Geo **프라이머리** 사이트 및 **세컨더리** 사이트, [Geo 설정 지침](../setup/_index.md)을 참조하세요.
- 도메인을 관리하는 DNS 영역. 다음 지침에서 [AWS Route53](https://aws.amazon.com/route53/) 및 [GCP Cloud DNS](https://cloud.google.com/dns/) 를 사용하지만 [Cloudflare](https://www.cloudflare.com/)와 같은 다른 서비스도 사용할 수 있습니다.

#### AWS Route53 {#aws-route53}

이 예에서는 Route53 Hosted Zone을 사용하여 도메인을 관리하고 Route53 설정에 사용합니다.

Route53 Hosted Zone에서 트래픽 정책을 사용하여 다양한 라우팅 구성을 설정할 수 있습니다. 트래픽 정책을 생성하려면:

1. [Route53 대시보드](https://console.aws.amazon.com/route53/home)로 이동하여 **Traffic policies**를 선택합니다.
1. **Create traffic policy**를 선택합니다.
1. **정책 이름** 필드에 `Single Git Host`을(를) 입력하고 **다음**를 선택합니다.
1. **DNS type**을(를) `A: IP Address in IPv4 format`로 유지합니다.
1. **Connect to**를 선택한 다음 **Geolocation rule**을(를) 선택합니다.
1. 첫 번째 **위치**의 경우:
   1. `Default`로 유지합니다.
   1. **Connect to**를 선택한 다음 **New endpoint**을(를) 선택합니다.
   1. **유형** `value`을(를) 선택하고 `<your **primary** IP address>`으로 채웁니다.
1. 두 번째 **위치**의 경우:
   1. `Europe`을(를) 선택합니다.
   1. **Connect to**를 선택한 다음 **New endpoint**을(를) 선택합니다.
   1. **유형** `value`을(를) 선택하고 `<your **secondary** IP address>`으로 채웁니다.

   ![기본값과 유럽이라는 두 위치가 있는 지리적 규칙을 보여주는 Route53 트래픽 정책 편집기로, 각각 다른 IP 주소의 엔드포인트에 연결되어 있습니다](img/single_url_add_traffic_policy_endpoints_v14_5.png)

1. **Create traffic policy**를 선택합니다.
1. **Policy record DNS name**을(를) `gitlab`으로 채웁니다.

   ![트래픽 정책, 버전, 호스팅 영역 및 DNS 구성 설정 필드가 있는 DNS 정책 기록을 생성하기 위한 웹 양식](img/single_url_create_policy_records_with_traffic_policy_v14_5.png)

1. **Create policy records**를 선택합니다.

`gitlab.example.com`과(와) 같은 단일 호스트를 성공적으로 설정했으며, 이는 지리적 위치별로 Geo 사이트에 트래픽을 배포합니다.

#### GCP {#gcp}

이 예에서는 도메인을 관리하는 GCP Cloud DNS 영역을 만듭니다.

Geo 기반 레코드 세트를 만들 때 GCP는 트래픽 소스가 정책 항목과 정확히 일치하지 않을 때 소스 지역에 대한 가장 가까운 일치를 적용합니다. Geo 기반 레코드 세트를 만들려면:

1. **Network Services** > **Cloud DNS**를 선택합니다.
1. 도메인에 대해 구성된 영역을 선택합니다.
1. **Add Record Set**을(를) 선택합니다.
1. 위치 인식 공개 URL의 DNS 이름을 입력합니다. 예: `gitlab.example.com`.
1. **Routing Policy**를 선택합니다:  **Geo-Based**.
1. **Add Managed RRData**를 선택합니다.
   1. **Source Region**을(를) **us-central1**로 선택합니다.
   1. `<**primary** IP address>`을(를) 입력합니다.
   1. **완료**을(를) 선택합니다.
1. **Add Managed RRData**를 선택합니다.
   1. **Source Region**을(를) **europe-west1**로 선택합니다.
   1. `<**secondary** IP address>`을(를) 입력합니다.
   1. **완료**을(를) 선택합니다.
1. **생성**를 선택합니다.

`gitlab.example.com`과(와) 같은 단일 호스트를 성공적으로 설정했으며, 이는 위치 인식 URL을 사용하여 Geo 사이트에 트래픽을 배포합니다.

### 각 사이트를 동일한 외부 URL을 사용하도록 구성 {#configure-each-site-to-use-the-same-external-url}

단일 URL에서 모든 Geo 사이트로의 라우팅을 설정한 후 사이트에서 다른 URL을 사용하는 경우 다음 단계를 따릅니다:

1. 각 GitLab 사이트에서 Rails(Puma, Sidekiq, Log-Cursor)를 실행하는 **each** 노드에 SSH하고 `external_url`을(를) 단일 URL로 설정합니다:

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

1. 변경 사항을 적용하려면 업데이트된 노드를 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 세컨더리 Geo 사이트에서 설정된 새 외부 URL과 일치하려면 프라이머리 데이터베이스가 이 변경을 반영해야 합니다.

   **프라이머리** 사이트의 Geo 관리 페이지에서 세컨더리 프록싱을 사용하는 각 Geo 세컨더리를 편집하고 `URL` 필드를 단일 URL로 설정합니다. 프라이머리 사이트도 이 URL을 사용하고 있는지 확인합니다.

   사이트가 서로 통신할 수 있도록 [`Internal URL` 필드가 각 사이트에 대해 고유한지 확인](../../geo_sites.md#set-up-the-internal-urls)합니다.

Kubernetes에서는 [`global.hosts.domain`과(와) 동일한 도메인을 프라이머리 사이트에 사용할 수 있습니다](https://docs.gitlab.com/charts/advanced/geo/).

## 세컨더리 Geo 사이트에 대한 별도의 URL 설정 {#set-up-a-separate-url-for-a-secondary-geo-site}

사이트별로 다른 외부 URL을 사용할 수 있습니다. 이를 사용하여 특정 사이트를 특정 사용자 집합에 제공할 수 있습니다. 또는 사용자가 사용할 사이트를 제어할 수 있지만 선택의 의미를 이해해야 합니다.

> [!note]
> GitLab은 여러 외부 URL을 지원하지 않습니다. [이슈 21319](https://gitlab.com/gitlab-org/gitlab/-/issues/21319)를 참조하세요. 본질적인 문제는 사이트가 요청으로 인해 트리거되지 않은 이메일을 보낼 때와 같이 HTTP 요청의 컨텍스트 외부에서 절대 URL을 생성해야 하는 많은 경우가 있다는 것입니다.

### 세컨더리 Geo 사이트를 프라이머리 사이트와 다른 외부 URL로 구성 {#configure-a-secondary-geo-site-to-a-different-external-url-than-the-primary-site}

세컨더리 사이트가 프라이머리 사이트와 동일한 외부 URL을 사용하지만 다른 URL을 사용하도록 변경하려면:

1. 세컨더리 사이트에서 Rails(Puma, Sidekiq, Log-Cursor)를 실행하는 **each** 노드에 SSH하고 `external_url`을(를) 세컨더리 사이트의 원하는 URL로 설정합니다:

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

1. 변경 사항을 적용하려면 업데이트된 노드를 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 세컨더리 Geo 사이트에서 설정된 새 외부 URL과 일치하려면 프라이머리 데이터베이스가 이 변경을 반영해야 합니다.

   **프라이머리** 사이트의 Geo 관리 페이지에서 대상 세컨더리 사이트를 편집하고 `URL` 필드를 원하는 URL로 설정합니다.

   사이트가 서로 통신할 수 있도록 [`Internal URL` 필드가 각 사이트에 대해 고유한지 확인](../../geo_sites.md#set-up-the-internal-urls)합니다. 원하는 URL이 이 사이트에 고유한 경우 `Internal URL` 필드를 지울 수 있습니다. 저장 시 외부 URL로 기본 설정됩니다.

## 프라이머리 Geo 사이트가 다운될 때 세컨더리 사이트의 동작 {#behavior-of-secondary-sites-when-the-primary-geo-site-is-down}

웹 트래픽이 프라이머리로 프록싱되는 것을 고려하면 프라이머리 사이트에 액세스할 수 없을 때 세컨더리 사이트의 동작이 다릅니다:

- UI 및 API 트래픽은 프라이머리와 동일한 오류를 반환하거나 프라이머리에 전혀 액세스할 수 없으면 실패합니다. 프록싱되기 때문입니다.
- 액세스 중인 특정 세컨더리 사이트에서 완전히 최신 상태인 리포지토리의 경우 Git 읽기 작업은 HTTP(s) 또는 SSH를 통한 인증을 포함하여 예상대로 계속 작동합니다. 그러나 GitLab 러너가 수행한 Git 읽기는 실패합니다.
- 세컨더리 사이트로 복제되지 않은 리포지토리의 Git 작업은 프록싱되기 때문에 프라이머리 사이트와 동일한 오류를 반환합니다.
- 모든 Git 쓰기 작업은 프록싱되기 때문에 프라이머리 사이트와 동일한 오류를 반환합니다.

## 세컨더리 Geo 사이트로 가속화된 기능 {#features-accelerated-by-secondary-geo-sites}

세컨더리 Geo 사이트로 전송되는 대부분의 HTTP 트래픽은 프라이머리 Geo 사이트로 프록싱됩니다. 이 아키텍처를 사용하면 세컨더리 Geo 사이트는 쓰기 요청을 지원할 수 있으며 읽기 후 쓰기 문제를 피할 수 있습니다. 특정 **read** 요청은 세컨더리 사이트에서 로컬로 처리되어 지연 시간과 근처의 대역폭이 개선됩니다.

다음 표는 Geo 세컨더리 사이트 Workhorse 프록시를 통해 테스트된 구성 요소를 자세히 설명합니다. 모든 데이터 유형을 다루지는 않습니다.

이 컨텍스트에서 가속화된 읽기는 세컨더리 사이트에서 제공되는 읽기 요청을 의미하며, 세컨더리 사이트의 구성 요소에 대한 데이터가 최신 상태입니다. 세컨더리 사이트의 데이터가 오래된 것으로 결정되면 요청이 프라이머리 사이트로 전달됩니다. 아래 표에 나열되지 않은 구성 요소에 대한 읽기 요청은 항상 자동으로 프라이머리 사이트로 전달됩니다.

| 기능 / 구성 요소                                 | 가속화된 읽기?                   | 참고 |
|:----------------------------------------------------|:-------------------------------------|-------|
| Rails 정적 자산(JavaScript, CSS, 글꼴, 이미지) | {{< icon name="check-circle" >}} 예 | `/assets/` 아래의 자산은 Workhorse에 의해 프라이머리로 프록싱되지 않고 세컨더리 사이트의 로컬 파일 시스템에서 직접 제공됩니다. 이는 통합 URL을 사용하든 별도의 URL을 사용하든 모든 세컨더리 사이트에 적용됩니다. 초기 브라우저 요청 후 이러한 자산은 일반적으로 브라우저에 의해 캐시됩니다. |
| 프로젝트, 위키, 설계 리포지토리(웹 UI 사용) | {{< icon name="dotted-circle" >}} 아니요 |       |
| 프로젝트, 위키 리포지토리(Git 사용)                | {{< icon name="check-circle" >}} 예 | Git 읽기는 로컬 세컨더리에서 제공되며 푸시는 프라이머리로 프록싱됩니다. 리포지토리가 Geo 세컨더리에 로컬로 존재하지 않는 경우, 예를 들어 선택적 동기화로 인한 제외로 인해 요청이 프라이머리 사이트로 프록싱됩니다. |
| 프로젝트, 개인 스니펫(웹 UI 사용)        | {{< icon name="dotted-circle" >}} 아니요 |       |
| 프로젝트, 개인 스니펫(Git 사용)               | {{< icon name="check-circle" >}} 예 | Git 읽기는 로컬 세컨더리에서 제공되며 푸시는 프라이머리로 프록싱됩니다. 리포지토리가 Geo 세컨더리에 로컬로 존재하지 않는 경우, 예를 들어 선택적 동기화로 인한 제외로 인해 요청이 프라이머리 사이트로 프록싱됩니다. |
| 그룹 위키 리포지토리(웹 UI 사용)            | {{< icon name="dotted-circle" >}} 아니요 |       |
| 그룹 위키 리포지토리(Git 사용)                   | {{< icon name="check-circle" >}} 예 | Git 읽기는 로컬 세컨더리에서 제공되며 푸시는 프라이머리로 프록싱됩니다. 리포지토리가 Geo 세컨더리에 로컬로 존재하지 않는 경우, 예를 들어 선택적 동기화로 인한 제외로 인해 요청이 프라이머리 사이트로 프록싱됩니다. |
| 사용자 업로드                                        | {{< icon name="dotted-circle" >}} 아니요 |       |
| LFS 객체(웹 UI 사용)                      | {{< icon name="dotted-circle" >}} 아니요 |       |
| LFS 객체(Git 사용)                             | {{< icon name="check-circle" >}} 예 |       |
| 페이지                                               | {{< icon name="dotted-circle" >}} 아니요 | 페이지는 동일한 URL(액세스 제어 없음)을 사용할 수 있지만 별도로 구성해야 하며 프록싱되지 않습니다. |
| 고급 검색(웹 UI 사용)                  | {{< icon name="dotted-circle" >}} 아니요 |       |
| 컨테이너 레지스트리                                  | {{< icon name="dotted-circle" >}} 아니요 | 컨테이너 레지스트리는 재해 복구 시나리오에만 권장됩니다. 세컨더리 사이트의 컨테이너 레지스트리가 최신 상태가 아닌 경우 요청이 프라이머리 사이트로 전달되지 않으므로 읽기 요청이 이전 데이터로 제공됩니다. 컨테이너 레지스트리 가속은 계획 중이며, 관심을 표현하려면 [이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/365864)에 투표하거나 의견을 남기거나 GitLab 담당자에게 귀사를 대신하여 이를 수행하도록 요청하세요. |
| 종속성 프록시                                    | {{< icon name="dotted-circle" >}} 아니요 | Geo 세컨더리 사이트의 종속성 프록시에 대한 읽기 요청은 항상 프라이머리 사이트로 프록싱됩니다. |
| 기타 모든 데이터                                      | {{< icon name="dotted-circle" >}} 아니요 | 이 표에 나열되지 않은 구성 요소에 대한 읽기 요청은 항상 자동으로 프라이머리 사이트로 전달됩니다. |

기능의 가속을 요청하려면 [에픽 8239](https://gitlab.com/groups/gitlab-org/-/epics/8239)에 이미 이슈가 있는지 확인하고 관심을 표현하려면 투표하거나 의견을 남기거나 GitLab 담당자에게 귀사를 대신하여 이를 수행하도록 요청하세요. 적용 가능한 이슈가 없으면 이슈를 열고 에픽에서 언급합니다.

## 세컨더리 사이트 HTTP 프록싱 비활성화 {#disable-secondary-site-http-proxying}

세컨더리 사이트 HTTP 프록싱은 통합 URL을 사용할 때 세컨더리 사이트에서 기본적으로 활성화되며, 이는 프라이머리 사이트와 동일한 `external_url`로 구성됨을 의미합니다. 이 경우 프록싱을 비활성화하면 라우팅에 따라 동일한 URL에서 완전히 다른 동작이 제공되기 때문에 도움이 되지 않는 경향이 있습니다. 세컨더리 Geo 사이트에서 HTTP 프록싱을 비활성화하면 사이트는 읽기 전용 모드에서 작동하며 주의해야 할 몇 가지 중요한 제한 사항이 있습니다.

### 세컨더리 프록싱을 비활성화하면 어떻게 됩니까? {#what-happens-if-you-disable-secondary-proxying}

프록싱 기능 플래그를 비활성화하면 다음과 같은 일반적인 영향이 있습니다.

#### HTTP 및 Git 요청 {#http-and-git-requests}

- 세컨더리 사이트는 HTTP 요청을 프라이머리 사이트로 프록싱하지 않습니다. 대신 직접 제공하거나 실패합니다.
- Git 요청은 일반적으로 성공합니다. Git 푸시는 프라이머리 사이트로 리다이렉트되거나 프록싱됩니다.
- Git 요청 이외의 모든 HTTP 요청으로 데이터를 쓸 수 있으므로 실패합니다. 읽기 요청은 일반적으로 성공합니다.

| 기능 / 구성 요소                                 | 성공                                 | 참고 |
|:----------------------------------------------------|:----------------------------------------|-------|
| 프로젝트, 위키, 설계 리포지토리(웹 UI 사용) | {{< icon name="dotted-circle" >}} 아마도 | 읽기는 로컬에 저장된 데이터에서 제공됩니다. 쓰기로 인해 오류가 발생합니다. |
| 프로젝트, 위키 리포지토리(Git 사용)                | {{< icon name="check-circle" >}} 예    | Git 읽기는 로컬에 저장된 데이터에서 제공되며 푸시는 프라이머리로 프록싱됩니다. 리포지토리가 Geo 세컨더리에 로컬로 존재하지 않는 경우, 예를 들어 선택적 동기화로 인한 제외로 인해 "찾을 수 없음" 오류가 발생합니다. |
| 프로젝트, 개인 스니펫(웹 UI 사용)        | {{< icon name="dotted-circle" >}} 아마도 | 읽기는 로컬에 저장된 데이터에서 제공됩니다. 쓰기로 인해 오류가 발생합니다. |
| 프로젝트, 개인 스니펫(Git 사용)               | {{< icon name="check-circle" >}} 예    | Git 읽기는 로컬에 저장된 데이터에서 제공되며 푸시는 프라이머리로 프록싱됩니다. 리포지토리가 Geo 세컨더리에 로컬로 존재하지 않는 경우, 예를 들어 선택적 동기화로 인한 제외로 인해 "찾을 수 없음" 오류가 발생합니다. |
| 그룹 위키 리포지토리(웹 UI 사용)            | {{< icon name="dotted-circle" >}} 아마도 | 읽기는 로컬에 저장된 데이터에서 제공됩니다. 쓰기로 인해 오류가 발생합니다. |
| 그룹 위키 리포지토리(Git 사용)                   | {{< icon name="check-circle" >}} 예    | Git 읽기는 로컬에 저장된 데이터에서 제공되며 푸시는 프라이머리로 프록싱됩니다. 리포지토리가 Geo 세컨더리에 로컬로 존재하지 않는 경우, 예를 들어 선택적 동기화로 인한 제외로 인해 "찾을 수 없음" 오류가 발생합니다. |
| 사용자 업로드                                        | {{< icon name="dotted-circle" >}} 아마도 | 업로드 파일은 로컬에 저장된 데이터에서 제공됩니다. 세컨더리에서 파일을 업로드하려고 하면 오류가 발생합니다. |
| LFS 객체(웹 UI 사용)                      | {{< icon name="dotted-circle" >}} 아마도 | 읽기는 로컬에 저장된 데이터에서 제공됩니다. 쓰기로 인해 오류가 발생합니다. |
| LFS 객체(Git 사용)                             | {{< icon name="check-circle" >}} 예    | LFS 객체는 로컬에 저장된 데이터에서 제공되며 푸시는 프라이머리로 프록싱됩니다. LFS 객체가 Geo 세컨더리에 로컬로 존재하지 않는 경우, 예를 들어 선택적 동기화로 인한 제외로 인해 "찾을 수 없음" 오류가 발생합니다. |
| 페이지                                               | {{< icon name="dotted-circle" >}} 아마도 | 페이지는 동일한 URL(액세스 제어 없음)을 사용할 수 있지만 별도로 구성해야 하며 프록싱되지 않습니다. |
| 고급 검색(웹 UI 사용)                  | {{< icon name="dotted-circle" >}} 아니요    |       |
| 컨테이너 레지스트리                                  | {{< icon name="dotted-circle" >}} 아니요    | 컨테이너 레지스트리는 재해 복구 시나리오에만 권장됩니다. 세컨더리 사이트의 컨테이너 레지스트리가 최신 상태가 아닌 경우 요청이 프라이머리 사이트로 전달되지 않으므로 읽기 요청이 이전 데이터로 제공됩니다. 컨테이너 레지스트리 가속은 계획 중이며, 관심을 표현하려면 [이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/365864)에 투표하거나 의견을 남기거나 GitLab 담당자에게 귀사를 대신하여 이를 수행하도록 요청하세요. |
| 종속성 프록시                                    | {{< icon name="dotted-circle" >}} 아니요    |       |
| 기타 모든 데이터                                      | {{< icon name="dotted-circle" >}} 아마도 | 읽기는 로컬에 저장된 데이터에서 제공됩니다. 쓰기로 인해 오류가 발생합니다. |

`GEO_SECONDARY_PROXY` 환경 변수를 사용하는 것보다 기능 플래그를 사용해야 합니다.

HTTP 프록싱은 기본적으로 GitLab 15.1에서 세컨더리 사이트에서 활성화되며 통합 URL이 없어도 됩니다.

#### 서비스 약관 수락 {#terms-of-service-acceptance}

프록싱을 비활성화하면 세컨더리 사이트에만 액세스하는 사용자는 서비스 약관 또는 기타 법적 계약을 올바르게 수락할 수 없습니다. 이로 인해 다음 문제가 발생합니다:

- **No record of acceptance**:  직원이 세컨더리 사이트에만 로그인하면 약관 수락이 프라이머리 데이터베이스에 기록되지 않습니다. 세컨더리 프록싱이 비활성화되면 쓰기 작업(약관 수락 포함)이 프록싱되지 않기 때문입니다. 약관 메시지가 표시될 수 있습니다.
- **Legal compliance concerns**:  조직은 직원이 세컨더리 전용 액세스 패턴을 통해 GitLab 서비스를 사용하는 경우 적절한 법적 보장이 부족할 수 있습니다. 약관 및 조건에 대한 동의를 검증할 수 있는 기록이 없기 때문입니다.

해결 방법으로 서비스 약관을 올바르게 수락하려면 최소한 한 번 이상 프라이머리 사이트에 액세스해야 합니다. 프라이머리에서 수락된 후 이 정보는 일반적인 Geo 동기화를 통해 세컨더리 사이트로 복제됩니다.

> [!note]
> 이 제한 사항은 준수 또는 법적 목적을 위해 약관 및 조건의 문서화된 수락을 요구하는 조직에 영향을 줍니다. 사용자가 초기 약관 수락을 위해 프라이머리 사이트에 액세스할 수 있는지 확인합니다.

### 모든 세컨더리 사이트에서 프록시 비활성화 {#disable-proxy-on-all-secondary-sites}

모든 세컨더리 사이트에서 프록싱을 비활성화해야 하는 경우 기능 플래그를 비활성화하는 것이 가장 쉽습니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. 프라이머리 Geo 사이트에서 Puma 또는 Sidekiq을 실행 중인 노드에 SSH하고 다음을 실행합니다:

   ```shell
   sudo gitlab-rails runner "Feature.disable(:geo_secondary_proxy_separate_urls)"
   ```

1. 세컨더리 Geo 사이트에서 실행 중인 모든 노드에서 Puma를 다시 시작합니다:

   ```shell
   sudo gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. 프라이머리 Geo 사이트에서 Toolbox 팟에서 이 명령을 실행합니다:

   ```shell
   kubectl exec -it <toolbox-pod-name> -- gitlab-rails runner "Feature.disable(:geo_secondary_proxy_separate_urls)"
   ```

1. 세컨더리 Geo 사이트에서 Webservice 팟을 다시 시작합니다:

   ```shell
   kubectl rollout restart deployment -l app=webservice
   ```

{{< /tab >}}

{{< /tabs >}}

세컨더리 사이트 프록싱이 다시 활성화되도록 변경 사항을 되돌립니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. 프라이머리 Geo 사이트에서 Puma 또는 Sidekiq을 실행 중인 노드에 SSH하고 다음을 실행합니다:

   ```shell
   sudo gitlab-rails runner "Feature.enable(:geo_secondary_proxy_separate_urls)"
   ```

1. 세컨더리 Geo 사이트에서 실행 중인 모든 노드에서 Puma를 다시 시작합니다:

   ```shell
   sudo gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. 프라이머리 Geo 사이트에서 Toolbox 팟에서 이 명령을 실행합니다:

   ```shell
   kubectl exec -it <toolbox-pod-name> -- gitlab-rails runner "Feature.enable(:geo_secondary_proxy_separate_urls)"
   ```

1. 세컨더리 Geo 사이트에서 Webservice 팟을 다시 시작합니다:

   ```shell
   kubectl rollout restart deployment -l app=webservice
   ```

{{< /tab >}}

{{< /tabs >}}

### 사이트별 세컨더리 사이트 HTTP 프록싱 비활성화 {#disable-secondary-site-http-proxying-per-site}

여러 세컨더리 사이트가 있는 경우 다음 단계를 따르면 각 세컨더리 사이트에서 HTTP 프록싱을 별도로 비활성화할 수 있습니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. 세컨더리 Geo 사이트에서 각 애플리케이션 노드(사용자 트래픽을 직접 제공)에 SSH하고 다음 환경 변수를 추가합니다:

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

   ```ruby
   gitlab_workhorse['env'] = {
     "GEO_SECONDARY_PROXY" => "0"
   }
   ```

1. 변경 사항을 적용하려면 업데이트된 노드를 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

`--set gitlab.webservice.extraEnv.GEO_SECONDARY_PROXY="0"`을(를) 사용하거나 값 파일에서 다음을 지정할 수 있습니다:

```yaml
gitlab:
  webservice:
    extraEnv:
      GEO_SECONDARY_PROXY: "0"
```

{{< /tab >}}

{{< /tabs >}}

### 세컨더리 사이트 Git 프록싱 비활성화 {#disable-secondary-site-git-proxying}

다음을 비활성화할 수 없습니다:

- SSH를 통한 Git 푸시
- Git 리포지토리가 세컨더리 사이트에서 최신이 아닐 때 SSH를 통한 Git 풀
- HTTP를 통한 Git 푸시
- Git 리포지토리가 세컨더리 사이트에서 최신이 아닐 때 HTTP를 통한 Git 풀

---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 이벤트 데이터
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.11에서 [활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/510333)으로 전환되었습니다.
- 환경 변수 재정의가 GitLab 18.9에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/567724).

{{< /history >}}

## 이벤트 수준의 제품 사용 현황 추적 {#data-tracking-for-product-usage-at-event-level}

**Important**:  GitLab 18.0부터 Self-Managed 및 Dedicated 인스턴스는 이벤트 수준 데이터를 수집하여 제품 사용 현황에 대한 더욱 상세한 정보를 제공합니다. 이전에는 Self-Managed 인스턴스에서만 집계된 메트릭을 수집했습니다.

제품 사용 데이터 수집 변경 사항에 대한 자세한 내용은 블로그 게시물 [GitLab Self-Managed 및 Dedicated를 위한 더욱 세분화된 제품 사용 정보](https://about.gitlab.com/blog/more-granular-product-usage-insights-for-gitlab-self-managed-and-dedicated/)를 참조하세요.

### 이벤트 데이터 {#event-data}

이벤트 데이터는 GitLab 플랫폼 내에서의 상호 작용(또는 작업)을 추적합니다. 이러한 상호 작용이나 작업은 <CI/CD 파이프라인> 시작, <머지 리퀘스트> 병합, <웹후크> 트리거 또는 <이슈> 생성과 같이 사용자가 시작한 것일 수 있습니다. 작업은 예약된 성공과 같이 백그라운드 시스템 처리로 인해 발생할 수도 있습니다. 이벤트 데이터 수집의 초점은 사용자의 작업 및 해당 작업과 관련된 메타데이터입니다.

사용자 ID는 개인 정보 보호를 위해 익명화되며, GitLab은 메트릭을 개별 사용자와 재식별하거나 연결하기 위해 어떤 프로세스도 수행하지 않습니다. 이벤트 데이터는 소스 코드나 GitLab 내에 저장된 기타 고객 생성 콘텐츠를 포함하지 않습니다.

자세한 내용은 다음을 참조하세요:

- [메트릭 사전](https://metrics.gitlab.com/?status=active) \- 이벤트 및 메트릭 목록
- [고객 제품 사용 정보](https://handbook.gitlab.com/handbook/legal/privacy/customer-product-usage-information/)

### 이벤트 데이터의 이점 {#benefits-of-event-data}

이벤트 수준 데이터는 사용자를 식별하지 않으면서 더욱 세분화된 정보를 제공하여 Service Ping의 여러 이점을 향상시킵니다.

- 적극적인 지원:  세분화된 데이터를 통해 고객 성공 관리자(CSM) 및 지원 팀이 더욱 상세한 정보에 액세스할 수 있으며, 보다 일반적이고 집계된 메트릭에 의존하기보다는 조직의 고유한 필요에 맞춘 사용자 정의 메트릭을 작성하고 세부적으로 분석할 수 있습니다.
- 맞춤형 가이드:  이벤트 수준 데이터는 기능이 어떻게 사용되는지에 대한 심층적인 이해를 제공하여 최적화 및 개선 기회를 발견할 수 있도록 도움을 줍니다. 데이터의 깊이는 GitLab의 가치를 극대화하고 워크플로우를 개선하는 데 도움이 되는 더욱 정확하고 실행 가능한 권장 사항을 제공할 수 있게 해줍니다.
- 익명화된 벤치마킹 보고서:  세분화된 이벤트 데이터는 고수준의 집계된 데이터만 사용하기보다는 세부적인 사용 패턴에 초점을 맞춰 유사한 조직과의 더욱 정확하고 관련성 있는 성능 비교를 가능하게 합니다.

### 이벤트 수준 데이터 수집 활성화 또는 비활성화 {#enable-or-disable-event-level-data-collection}

> [!note]
> Snowplow 추적이 활성화되면 제품 사용 추적을 활성화할 때 자동으로 비활성화됩니다. 한 번에 활성화할 수 있는 데이터 수집 방법은 하나뿐입니다.

이벤트 수준 데이터 수집을 활성화 또는 비활성화하려면:

1. 관리자 액세스 권한이 있는 사용자로 로그인합니다.
1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **Metrics and Profiling**을 선택합니다.
1. **이벤트 추적**을 확장합니다.
1. 설정을 활성화하려면 **이벤트 추적 활성화** 체크박스를 선택합니다. 설정을 비활성화하려면 체크박스를 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

### 이벤트 수준 데이터 수집을 프로그래매틱으로 구성 {#programmatically-configure-event-level-data-collection}

다음 중 하나를 사용하여 이벤트 수준 데이터 수집을 프로그래매틱으로 구성할 수 있습니다:

- **Initial defaults**:  처음 설치할 때만 적용됩니다
- **Environment variable override**:  런타임에 적용되며 데이터베이스 설정보다 우선입니다

#### 초기 기본값(설치만 해당) {#initial-defaults-installation-only}

이러한 설정은 GitLab의 초기 설치 중에만 적용됩니다. 설치 후 이러한 설정을 변경해도 효과가 없습니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

`gitlab_rails['initial_gitlab_product_usage_data']`을(를) `false`(으)로 `/etc/gitlab/gitlab.rb`에 설정합니다:

```ruby
gitlab_rails['initial_gitlab_product_usage_data'] = false
```

그런 다음 GitLab을 다시 구성합니다:

```shell
sudo gitlab-ctl reconfigure
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

`global.appConfig.initialDefaults.gitlabProductUsageData`을(를) `false`(으)로 값 파일에 설정합니다:

```yaml
global:
  appConfig:
    initialDefaults:
      gitlabProductUsageData: false
```

또는 명령줄을 통해:

```shell
helm install gitlab gitlab/gitlab \
  --set global.appConfig.initialDefaults.gitlabProductUsageData=false
```

{{< /tab >}}

{{< /tabs >}}

#### 환경 변수 재정의(런타임) {#environment-variable-override-runtime}

> [!note]
> GitLab 18.9에서 도입되었습니다.

`GITLAB_PRODUCT_USAGE_DATA_ENABLED` 환경 변수를 사용하여 런타임에 이벤트 수준 데이터 수집을 제어할 수 있습니다. 설정할 때 이 환경 변수는:

- 데이터베이스 설정보다 우선합니다
- 관리 UI를 통해 변경할 수 없습니다(토글이 비활성화됨)
- 데이터베이스 마이그레이션을 수행할 필요 없이 즉시 적용됩니다

이는 다음의 경우에 유용합니다:

- 자동화된 구성이 필요한 에어갭 환경
- 업그레이드 전체에서 일관된 설정이 필요한 배포
- UI 액세스가 실용적이지 않은 자동화된 배포 워크플로우

유효한 값은 `true` 또는 `false`입니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

환경 변수를 `/etc/gitlab/gitlab.rb`에 설정합니다:

```ruby
gitlab_rails['env']['GITLAB_PRODUCT_USAGE_DATA_ENABLED'] = 'false'
```

그런 다음 GitLab을 다시 구성합니다:

```shell
sudo gitlab-ctl reconfigure
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

값 파일에서 `extraEnv`을(를) 사용하여 환경 변수를 설정합니다:

```yaml
gitlab:
  sidekiq:
    extraEnv:
      GITLAB_PRODUCT_USAGE_DATA_ENABLED: 'false'
  webservice:
    extraEnv:
      GITLAB_PRODUCT_USAGE_DATA_ENABLED: 'false'
```

또는 명령줄을 통해:

```shell
helm upgrade gitlab gitlab/gitlab \
  --set gitlab.sidekiq.extraEnv.GITLAB_PRODUCT_USAGE_DATA_ENABLED='false' \
  --set gitlab.webservice.extraEnv.GITLAB_PRODUCT_USAGE_DATA_ENABLED='false'
```

{{< /tab >}}

{{< tab title="Docker" >}}

컨테이너를 시작할 때 환경 변수를 전달합니다:

```shell
docker run --env GITLAB_PRODUCT_USAGE_DATA_ENABLED=false gitlab/gitlab-ee:latest
```

또는 Docker Compose 파일에서:

```yaml
services:
  gitlab:
    image: gitlab/gitlab-ee:latest
    environment:
      GITLAB_PRODUCT_USAGE_DATA_ENABLED: 'false'
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

GitLab을 시작하기 전에 환경 변수를 설정합니다:

```shell
export GITLAB_PRODUCT_USAGE_DATA_ENABLED=false
```

또는 systemd 서비스 파일이나 init 스크립트에 추가합니다.

{{< /tab >}}

{{< /tabs >}}

#### 현재 설정 소스 확인 {#check-the-current-setting-source}

환경 변수 재정의가 활성화되면 관리 UI에 설정이 환경 변수에 의해 제어되며 UI를 통해 변경할 수 없음을 나타내는 경고 배너가 표시됩니다.

API를 통해 설정 소스를 확인할 수도 있습니다:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/application/settings" | jq '.gitlab_product_usage_data_enabled, .gitlab_product_usage_data_source'
```

`gitlab_product_usage_data_source` 필드는 다음 중 하나를 반환합니다:

- `environment`:  설정이 `GITLAB_PRODUCT_USAGE_DATA_ENABLED` 환경 변수에 의해 제어됩니다
- `database`:  설정이 데이터베이스에 의해 제어됩니다(관리 UI를 통해 변경 가능)

### 이벤트 전달 타이밍 {#event-delivery-timing}

이벤트는 발생 직후 GitLab으로 전송됩니다. 시스템은 작은 배치로 이벤트를 수집하여 10개의 이벤트가 수집되면 데이터를 전송합니다. 이 방식은 효율적인 네트워크 사용을 유지하면서 거의 실시간에 가까운 전달을 제공합니다.

### 페이로드 크기 및 압축 {#payload-size-and-compression}

각 이벤트는 JSON 형식으로 약 10kB입니다. 10개 이벤트의 배치는 압축되지 않은 페이로드 크기가 약 100kB입니다. 전송 전에 페이로드는 데이터 전송 크기를 최소화하고 성능을 최적화하도록 압축됩니다.

### 이벤트 데이터 로그 {#event-data-logs}

이벤트 수준 추적 데이터는 `product_usage_data.log` 파일에 로깅됩니다. 이 로그는 추적된 제품 사용 이벤트의 JSON 형식 항목(페이로드 정보 및 컨텍스트 데이터 포함)을 포함합니다. 각 줄은 별도의 추적 이벤트 및 전송된 모든 데이터를 나타냅니다.

로그 파일은 다음 위치에 있습니다:

- `/var/log/gitlab/gitlab-rails/product_usage_data.log` - Linux 패키지 설치
- `/home/git/gitlab/log/product_usage_data.log` - 자체 컴파일 설치

이러한 로그는 기능 사용 분석보다는 보안 팀의 검사를 위해 특별히 설계되었지만 데이터 전송에 대한 철저한 가시성을 제공합니다. 로깅 시스템에 대한 자세한 내용은 [로그 시스템 설명서](../logs/_index.md#product-usage-data-log)를 참조하세요.

---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: 애플리케이션 성능을 모니터링하고 성능 문제를 해결합니다.
ignore_in_report: true
title: GitLab Observability에 원격 측정 데이터 전송
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태: 실험적 기능

{{< /details >}}

통합관찰을 구성한 후 GitLab으로 데이터 전송을 시작할 수 있습니다.

시작하려면 [CI/CD 파이프라인 데이터](ci_cd.md), [테스트 데이터 전송](#send-test-data), 또는 [템플릿 사용](#gitlab-observability-templates)을 확인하세요.

## 통합관찰 데이터 보기 {#view-observability-data}

GitLab Observability이 구성된 후:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **통합관찰** > **서비스**를 선택합니다.
1. 세부 정보를 확인할 서비스를 선택하세요.

![GitLab.com 통합관찰 대시보드](img/gitLab_o11y_gitlab_com_dashboard_v18_1.png "GitLab.com 통합관찰 대시보드")

## 애플리케이션 계측 {#instrument-your-application}

애플리케이션에 OpenTelemetry 계측을 추가하려면:

1. 사용 언어에 맞는 OpenTelemetry SDK를 추가합니다.
1. GitLab Observability 인스턴스를 가리키도록 OTLP 내보내기를 구성합니다.
1. 권장 리소스 속성을 구성합니다.
1. 작업 및 메타데이터를 추적하기 위해 스팬과 속성을 추가합니다.

언어별 가이드는 [OpenTelemetry 설명서](https://opentelemetry.io/docs/instrumentation/)를 참고하세요.

### 권장 리소스 속성 {#recommended-resource-attributes}

이러한 리소스 속성으로 OpenTelemetry SDK를 구성하여 원격 측정 데이터를 GitLab 프로젝트 및 코드로 다시 연결합니다. 이를 통해 커밋으로 추적을 연관시키고 예외에서 자동으로 이슈를 생성하는 등의 기능을 사용할 수 있습니다.

| 리소스 속성 | GitLab CI/CD 변수 | 설명 |
| --- | --- | --- |
| `gitlab.project.id` | `CI_PROJECT_ID` | 원격 측정을 GitLab 프로젝트에 연결합니다. GitLab Duo 통합에 필수입니다. |
| `gitlab.project.name` | `CI_PROJECT_NAME` | 대시보드에 표시할 사용자가 읽을 수 있는 프로젝트 이름입니다. |
| `service.version` | `CI_COMMIT_SHA` | 실행 중인 코드의 커밋 SHA입니다. 배포된 정확한 버전으로 추적 및 오류를 연관시킬 수 있습니다. |
| `deployment.environment.name` | `CI_ENVIRONMENT_NAME` | 코드가 실행 중인 환경입니다(예: `production` 또는 `staging`). |

`service.version` 및 `deployment.environment.name`는 [OpenTelemetry 의미론적 규약](https://opentelemetry.io/docs/specs/semconv/resource/)입니다. `gitlab.*` 속성은 GitLab 관련 컨텍스트에 공급업체 네임스페이스를 사용합니다.

4개 변수 모두 [GitLab CI/CD에서 미리 정의](../../ci/variables/predefined_variables.md)되며, 파이프라인에서 애플리케이션이 실행될 때 추가 구성이 필요하지 않습니다. 로컬 개발의 경우 이러한 환경 변수를 수동으로 설정하거나 빈 기본값을 수락합니다.

다음 Ruby 예제는 이러한 속성을 구성하는 방법을 보여줍니다:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.resource = OpenTelemetry::SDK::Resources::Resource.create(
    'gitlab.project.id'           => ENV.fetch('CI_PROJECT_ID', ''),
    'gitlab.project.name'         => ENV.fetch('CI_PROJECT_NAME', ''),
    'service.version'             => ENV.fetch('CI_COMMIT_SHA', ''),
    'deployment.environment.name' => ENV.fetch('CI_ENVIRONMENT_NAME', '')
  )

  c.use_all
end
```

다른 언어의 경우 언어의 OpenTelemetry SDK를 사용하여 동일한 리소스 속성을 설정합니다. 속성 이름과 환경 변수는 모든 언어에서 동일합니다.

## 테스트 데이터 전송 {#send-test-data}

OpenTelemetry SDK를 사용하여 샘플 원격 측정 데이터를 전송하여 GitLab Observability 설치를 테스트할 수 있습니다. 이 예제는 Ruby를 사용하지만 OpenTelemetry는 [많은 언어를 위한 SDK](https://opentelemetry.io/docs/instrumentation/)를 제공합니다.

### 전제 조건 {#prerequisites}

- 로컬 머신에 설치된 Ruby입니다.
- 필수 gem:

  ```shell
  gem install opentelemetry-sdk opentelemetry-exporter-otlp
  ```

### 기본 테스트 스크립트 생성 {#create-a-basic-test-script}

`test_o11y.rb` 이름의 파일을 다음 콘텐츠로 생성하세요:

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

OpenTelemetry::SDK.configure do |c|
  # Define service information
  resource = OpenTelemetry::SDK::Resources::Resource.create({
    'service.name' => 'test-service',
    'service.version' => '1.0.0',
    'deployment.environment.name' => 'production',
    'gitlab.project.id' => ENV.fetch('CI_PROJECT_ID', ''),
    'gitlab.project.name' => ENV.fetch('CI_PROJECT_NAME', '')
  })
  c.resource = resource

  # Configure OTLP exporter to send to GitLab Observability
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: 'http://[your-o11y-instance-ip]:4318/v1/traces'
      )
    )
  )
end

# Get tracer and create spans
tracer = OpenTelemetry.tracer_provider.tracer('basic-demo')

# Create parent span
tracer.in_span('parent-operation') do |parent|
  parent.set_attribute('custom.attribute', 'test-value')
  puts "Created parent span: #{parent.context.hex_span_id}"

  # Create child span
  tracer.in_span('child-operation') do |child|
    child.set_attribute('custom.child', 'child-value')
    puts "Created child span: #{child.context.hex_span_id}"
    sleep(1)
  end
end

puts "Waiting for export..."
sleep(5)
puts "Done!"
```

`[your-o11y-instance-ip]`을 GitLab Observability 인스턴스의 IP 주소 또는 호스트 이름으로 바꾸세요.

### 테스트 실행 {#run-the-test}

1. 스크립트를 실행하세요:

   ```shell
   ruby test_o11y.rb
   ```

1. **통합관찰** > **서비스**로 이동하세요. `test-service` 서비스를 선택하여 추적 및 스팬을 확인하세요.

## GitLab Observability 템플릿 {#gitlab-observability-templates}

GitLab은 통합관찰을 신속하게 시작하기 위해 미리 빌드된 대시보드 템플릿을 제공합니다. 이러한 템플릿은 [GitLab Observability 템플릿](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/)에서 사용할 수 있습니다.

### 사용 가능한 템플릿 {#available-templates}

**Standard OpenTelemetry dashboards**: 표준 OpenTelemetry 라이브러리로 애플리케이션을 계측하면 이러한 즉시 사용 가능한 대시보드 템플릿을 사용할 수 있습니다:

- 애플리케이션 성능 모니터링 대시보드
- 서비스 종속성 시각화
- 오류율 및 지연 시간 추적

**GitLab-specific dashboards**: GitLab OpenTelemetry 데이터를 GitLab Observability 인스턴스로 전송할 때 이러한 대시보드를 사용하여 즉시 통찰력을 얻습니다:

- GitLab 애플리케이션 성능 메트릭
- GitLab 서비스 상태 모니터링
- GitLab 관련 추적 분석

**CI/CD 통합관찰**: 리포지토리에는 GitLab Observability CI/CD 대시보드 템플릿 JSON 파일과 함께 작동하는 OpenTelemetry 계측을 포함한 GitLab CI/CD 파이프라인 예제가 포함되어 있습니다. 이를 통해 CI/CD 파이프라인 성능을 모니터링하고 병목 지점을 파악할 수 있습니다.

### 템플릿 사용 {#using-the-templates}

1. 리포지토리에서 템플릿을 복제하거나 다운로드합니다.
1. 예제 애플리케이션 대시보드의 서비스 이름을 서비스 이름과 일치하도록 업데이트합니다.
1. JSON 파일을 GitLab Observability 인스턴스로 가져옵니다.
1. [애플리케이션 계측](#instrument-your-application) 섹션에 설명된 대로 표준 OpenTelemetry 라이브러리를 사용하여 애플리케이션이 원격 측정 데이터를 전송하도록 구성합니다.
1. 대시보드는 이제 GitLab Observability에서 애플리케이션의 원격 측정 데이터와 함께 사용할 수 있습니다.

## 관련 항목 {#related-topics}

- [통합관찰 문제 해결](troubleshooting.md)

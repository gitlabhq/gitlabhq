---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Dedicated를 위한 사용 가능한 AWS 리전, 데이터 격리 및 고가용성입니다."
title: 데이터 거주지와 고가용성
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

GitLab Dedicated는 선택한 AWS 리전을 통해 데이터 거주지 제어 및 고가용성 기능을 제공합니다. 데이터가 저장되고 처리되는 위치를 제어하여 규정 요구 사항을 충족하면서 엔터프라이즈급 가동 시간을 유지할 수 있습니다.

GitLab Dedicated 환경은 전용 AWS 계정에서 실행되며 다른 테넌트 및 GitLab.com과 완전히 격리됩니다. 이 단일 테넌트 아키텍처는 데이터 위치에 대한 완전한 제어를 제공하며 GitLab은 기본 인프라를 관리하고 입증된 참조 아키텍처를 통해 고가용성을 보장합니다.

GitLab Dedicated는 고가용성을 갖춘 [Cloud Native Hybrid 참조 아키텍처](../../reference_architectures/_index.md#cloud-native-hybrid)의 수정된 버전을 사용합니다. 선택한 리전 내에서 GitLab은 중복성을 위해 여러 가용 영역에 걸쳐 인프라를 분산합니다. 온보딩 중에 GitLab이 가용 영역을 자동으로 선택하도록 허용(권장)하거나 기존 AWS 인프라와 일치하도록 사용자 지정 가용 영역 ID를 지정할 수 있습니다.

> [!note]
> GitLab Dedicated는 보안 및 안정성을 강화하기 위해 표준 참조 아키텍처 이상의 추가 클라우드 공급자 서비스를 사용합니다. 결과적으로 GitLab Dedicated의 비용은 표준 참조 아키텍처 비용과 다릅니다.

## 리전 선택 {#region-selection}

GitLab Dedicated 인스턴스를 만들 때 기본 배포, 재해 복구 및 백업을 위한 AWS 리전을 선택합니다. 리전 선택은 영구적이며 프로비저닝 후에는 변경할 수 없습니다. 데이터 거주지 요구 사항, 지연 시간 및 재해 복구 전략을 기반으로 리전을 선택하여 인스턴스가 규정 준수 요구 사항을 충족하고 리전 장애로부터 보호합니다.

기본 리전:  인스턴스가 실행되고 사용자가 GitLab에 액세스하는 주 배포입니다. 데이터가 저장되는 위치이며 데이터 거주지 요구 사항을 충족해야 합니다.

보조 리전:  Geo 기반 재해 복구를 위한 선택적 AWS 리전입니다. 기본 리전을 사용할 수 없게 되면 보조 리전으로 장애 조치할 수 있습니다.

백업 리전:  추가 중복성을 위해 백업을 복제하는 선택적 AWS 리전입니다. 기본 리전 또는 보조 리전과 동일하거나 중복성 증대를 위한 다른 리전일 수 있습니다.

리전을 선택할 때 다음 요소를 고려하세요:

- 데이터 거주지 및 규정 준수:  기본 리전은 데이터가 저장되는 위치입니다. 규정 요구 사항을 충족하는 리전을 선택하세요. 예를 들어 GDPR 규정 준수는 데이터가 EU에 남아있어야 할 수 있으며, HIPAA 규정 준수는 특정 AWS 리전을 요구할 수 있습니다.
- 고가용성 및 재해 복구:  리전 장애로부터 보호하기 위해 보조 및 백업 리전을 선택합니다. 기본 리전을 사용할 수 없게 되면 보조 리전으로 장애 조치할 수 있습니다.
- 기능 가용성:  ClickHouse Cloud 및 AWS SES와 같은 일부 GitLab Dedicated 기능은 특정 리전에서만 사용할 수 있습니다.
- 성능 및 지연 시간:  지연 시간을 최소화하고 성능을 개선하기 위해 사용자 및 인프라와 지리적으로 가까운 리전을 선택합니다.
- 지속 가능성:  조직이 지속 가능성 약속을 가지고 있다면 다양한 리전의 탄소 배출량을 고려할 수 있습니다. 저배출 리전 지침을 보려면 [비즈니스 요구 사항과 지속 가능성 목표를 모두 기반으로 리전을 선택하는 방법](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sus_sus_region_a2.html)을 참조하세요.

> [!note]
> 제한이 있는 리전은 명확하게 표시되며 선택 전에 관련 위험을 인정해야 합니다.

### 지원되는 리전 {#supported-regions}

다음 표는 GitLab Dedicated에서 지원하는 모든 AWS 리전을 보여줍니다. 이 표의 모든 리전을 기본, 보조 또는 백업 리전으로 사용할 수 있습니다.

> [!warning]
> US East (N. Virginia) 종속성 위험 AWS는 `us-east-1` 리전에서 글로벌 IAM(Identity and Access Management) 서비스를 호스팅합니다. `us-east-1`의 장애는 GitLab이 보조 리전으로의 장애 조치를 포함하여 테넌트에서 작업을 수행하지 못하게 합니다. `us-east-1`를 기본 리전으로 하는 테넌트는 장애 중에 GitLab이 완화할 수 없는 가동 중지 시간을 경험합니다. 이 위험을 줄이기 위해 다른 기본 리전을 선택하는 것을 고려하세요.

<!-- separator -->

> [!warning]
> 중동 리전 임시 사용 불가 `me-central-1` (UAE) 및 `me-south-1` (바레인)은 현재 심각한 인프라 중단으로 인해 사용할 수 없습니다. 이 리전의 인스턴스는 장시간 가동 중지 시간, 서비스 저하, 확장 실패 및 장애 조치 이슈를 경험할 수 있습니다. 자세한 내용은 [AWS Health Dashboard](https://health.aws.amazon.com/health/status)를 참조하세요. 액세스를 요청하거나 옵션을 논의하려면 [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)을 제출하세요.

다음 AWS 리전에 인스턴스를 배포할 수 있습니다:

| 리전                    | 코드             | ClickHouse Cloud                            | AWS SES                                     | 지속 가능성 등급 |
| ------------------------- | ---------------- | ------------------------------------------- | ------------------------------------------- | --------------------- |
| Africa (Cape Town)        | `af-south-1`     | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | F                     |
| Asia Pacific (Hong Kong)  | `ap-east-1`      | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | E                     |
| Asia Pacific (Hyderabad)  | `ap-south-2`     | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Asia Pacific (Jakarta)    | `ap-southeast-3` | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | F                     |
| Asia Pacific (Melbourne)  | `ap-southeast-4` | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | F                     |
| Asia Pacific (Mumbai)     | `ap-south-1`     | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Asia Pacific (Osaka)      | `ap-northeast-3` | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Asia Pacific (Seoul)      | `ap-northeast-2` | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Asia Pacific (Singapore)  | `ap-southeast-1` | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Asia Pacific (Sydney)     | `ap-southeast-2` | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Asia Pacific (Tokyo)      | `ap-northeast-1` | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Canada (Central)          | `ca-central-1`   | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | A+                    |
| Europe (Frankfurt)        | `eu-central-1`   | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | D                     |
| Europe (Ireland)          | `eu-west-1`      | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | D                     |
| Europe (London)           | `eu-west-2`      | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | B                     |
| Europe (Milan)            | `eu-south-1`     | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | C                     |
| Europe (Paris)            | `eu-west-3`      | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | A+                    |
| Europe (Spain)            | `eu-south-2`     | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | B                     |
| Europe (Stockholm)        | `eu-north-1`     | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | A+                    |
| Europe (Zurich)           | `eu-central-2`   | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | A+                    |
| Israel (Tel Aviv)         | `il-central-1`   | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Middle East (Bahrain)     | `me-south-1`     | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Middle East (UAE)         | `me-central-1`   | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | D                     |
| South America (São Paulo) | `sa-east-1`      | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | B                     |
| US East (N. Virginia)     | `us-east-1`      | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | D                     |
| US East (Ohio)            | `us-east-2`      | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | D                     |
| US West (N. California)   | `us-west-1`      | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | C                     |
| US West (Oregon)          | `us-west-2`      | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | C                     |

나열되지 않은 리전이 필요한 경우 계정 담당자 또는 [GitLab Support](https://about.gitlab.com/support/)에 문의하세요.

#### ClickHouse Cloud {#clickhouse-cloud}

[고급 분석 기능](../../../integration/clickhouse.md)은 ClickHouse Cloud를 지원하는 리전에서만 사용할 수 있습니다. ClickHouse 가용성에 대해 지원되는 리전 표를 확인하세요.

포함되는 사항:

- 테넌트의 기본 리전에 배포된 ClickHouse Cloud 데이터베이스
- AWS PrivateLink 연결(공개 액세스 불가)
- AES 256 키 및 투명 데이터 암호화를 사용하여 전송 중 및 저장 시 암호화된 데이터
- [아웃바운드 요청을 필터링](../../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)할 때 자동 엔드포인트 허용 목록 추가

제한 사항:

- [고객 관리 암호화 키](../encryption.md#customer-managed-encryption)는 지원되지 않습니다.
- SLA가 적용되지 않습니다. RTO(Recovery Time Objective) 및 RPO(Recovery Point Objective)는 최선의 노력입니다.

#### AWS SES {#aws-ses}

AWS Simple Email Service(SES)는 GitLab 인스턴스에서 이메일을 보내는 데 사용됩니다. 각 리전의 SES 가용성에 대해 지원되는 리전 표를 확인하세요.

AWS SES 지원이 없는 리전의 경우 [외부 SMTP 메일 서비스](../configure_instance/users_notifications.md#smtp-email-service)를 설정해야 합니다.

#### 지속 가능성 등급 {#sustainability-ratings}

> [!note]
> 지속 가능성 등급은 제3자 클라우드 지속 가능성 회사인 Greenpixie에서 제공합니다. 이 등급은 GitLab에서 수행한 평가를 반영하지 않습니다. 등급은 2026년 2월 4일에 마지막으로 업데이트된 데이터를 반영합니다.

지속 가능성 등급은 각 AWS 리전의 탄소 강도를 보여줍니다. 탄소 강도는 소비된 전기 단위당 배출되는 CO2의 양(gCO2/kWh)을 측정합니다. 이 등급을 사용하여 환경 책임이 있는 리전을 선택하세요.

등급 척도:

- A+:  가장 낮은 탄소 배출량
- A: A+보다 약 4배~5배 높은 배출량
- B: A+보다 약 5배~20배 높은 배출량
- C: A+보다 약 20배~25배 높은 배출량
- D: A+보다 약 25배~30배 높은 배출량
- E: A+보다 약 30배~50배 높은 배출량
- F: A+보다 약 50배~300배 높은 배출량

Greenpixie는 장기 지역 탄소 강도 평균을 사용하여 이 등급을 계산합니다. 등급은 지속 가능한 배포 결정을 내릴 수 있도록 도와주지만 실시간 조건을 반영하지는 않습니다.

## 관련 항목 {#related-topics}

- [GitLab Dedicated 인스턴스 생성](_index.md)
- [GitLab Dedicated를 위한 재해 복구](../disaster_recovery.md)

---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo 보안 검토 (Q&A)
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음의 Geo 기능 집합에 대한 보안 검토는 자체 GitLab 인스턴스를 운영하는 고객에게 적용되는 기능의 보안 측면에 중점을 두고 있습니다. 검토 질문은 부분적으로 [OWASP 애플리케이션 보안 검증 표준 프로젝트](https://owasp.org/www-project-application-security-verification-standard/) 와 [owasp.org](https://owasp.org/)를 기반으로 합니다.

## 비즈니스 모델 {#business-model}

### 애플리케이션이 서비스하는 지역은 어디입니까? {#what-geographic-areas-does-the-application-service}

- 고객마다 다릅니다. Geo를 통해 고객은 여러 지역에 배포할 수 있으며 위치를 선택할 수 있습니다.
- 지역 및 노드 선택은 완전히 수동입니다.

## 데이터 필수 요소 {#data-essentials}

### 애플리케이션이 수신, 생성 및 처리하는 데이터는 무엇입니까? {#what-data-does-the-application-receive-produce-and-process}

- Geo는 GitLab 인스턴스에서 보유한 거의 모든 데이터를 사이트 간에 스트리밍합니다. 여기에는 전체 데이터베이스 복제, 사용자가 업로드한 첨부 파일과 같은 대부분의 파일, 리포지토리 및 wiki 데이터가 포함됩니다. 일반적인 구성에서는 공개 인터넷을 통해 발생하며 TLS 암호화됩니다.
- PostgreSQL 복제는 TLS로 암호화됩니다.
- 참고: [TLSv1.2만 지원되어야 함](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2948)

### 데이터를 민감도에 따라 카테고리로 분류할 수 있는 방법은 무엇입니까? {#how-can-the-data-be-classified-into-categories-according-to-its-sensitivity}

- GitLab의 민감도 모델은 공개 대 내부 대 비공개 프로젝트를 중심으로 합니다. Geo는 모두를 무차별적으로 복제합니다. "선택적 동기화"는 파일 및 리포지토리에 대해 존재하지만 데이터베이스 콘텐츠는 존재하지 않으며, 원하는 경우 덜 민감한 프로젝트만 **세컨더리** 사이트로 복제될 수 있습니다.

### 애플리케이션에 대해 정의된 데이터 백업 및 보존 요구 사항은 무엇입니까? {#what-data-backup-and-retention-requirements-have-been-defined-for-the-application}

- Geo는 애플리케이션 데이터의 특정 부분 집합의 복제를 제공하도록 설계되었습니다. 문제의 일부가 아니라 해결책의 일부입니다.

## 최종 사용자 {#end-users}

### 애플리케이션의 최종 사용자는 누구입니까? {#who-are-the-applications-end-users}

- **세컨더리** 사이트는 주 GitLab 설치(즉, **프라이머리** 사이트)에서 인터넷 지연 측면에서 먼 지역에 생성됩니다. 이들은 일반적으로 **프라이머리** 사이트를 사용할 수 있는 모든 사람이 사용하기 위한 것이며, **세컨더리** 사이트가 자신들(인터넷 지연 측면에서)에 더 가깝다고 생각하는 사람이 사용하기 위한 것입니다.

### 최종 사용자는 애플리케이션과 어떻게 상호 작용합니까? {#how-do-the-end-users-interact-with-the-application}

- **세컨더리** 사이트는 **프라이머리** 사이트가 제공하는 모든 인터페이스를 제공하지만(특히 HTTP/HTTPS 웹 애플리케이션 및 HTTP/HTTPS 또는 SSH Git 리포지토리 액세스), 읽기 전용 활동으로 제한됩니다. 주요 사용 사례는 **세컨더리** 사이트보다 **프라이머리** 사이트에서 Git 리포지토리를 복제하는 것으로 예상되지만, 최종 사용자는 GitLab 웹 인터페이스를 사용하여 프로젝트, 이슈, 머지 리퀘스트, 스니펫과 같은 정보를 볼 수 있습니다.

### 최종 사용자는 어떤 보안 기대치를 가지고 있습니까? {#what-security-expectations-do-the-end-users-have}

- 복제 프로세스는 안전해야 합니다. 전체 데이터베이스 콘텐츠나 모든 파일 및 리포지토리를 공개 인터넷을 통해 평문으로 전송하는 것은 일반적으로 용인할 수 없습니다.
- **세컨더리** 사이트는 **프라이머리** 사이트와 동일한 콘텐츠에 대한 액세스 제어를 갖고 있어야 합니다. 인증되지 않은 사용자가 **프라이머리** 사이트의 권한이 있는 정보에 **세컨더리** 사이트를 쿼리하여 액세스할 수 없어야 합니다.
- 공격자가 **세컨더리** 사이트를 **프라이머리** 사이트로 가장하여 권한이 있는 정보에 액세스할 수 없어야 합니다.

## 관리자 {#administrators}

### 애플리케이션에서 관리 기능을 가진 사용자는 누구입니까? {#who-has-administrative-capabilities-in-the-application}

- Geo 관련 사항은 없습니다. 데이터베이스에 `admin: true`이(가) 설정된 사용자는 슈퍼 사용자 권한이 있는 관리자로 간주됩니다.
- 참고: [더 세분화된 액세스 제어](https://gitlab.com/gitlab-org/gitlab/-/issues/18242)(Geo 관련 사항 아님).
- Geo의 대부분의 통합(예를 들어 데이터베이스 복제)은 일반적으로 시스템 관리자에 의해 애플리케이션과 함께 구성되어야 합니다.

### 애플리케이션이 제공하는 관리 기능은 무엇입니까? {#what-administrative-capabilities-does-the-application-offer}

- **세컨더리** 사이트는 관리 액세스 권한이 있는 사용자가 추가, 수정 또는 제거할 수 있습니다.
- 복제 프로세스는 Sidekiq 관리 제어를 통해 제어(시작/중지)될 수 있습니다.

## 네트워크 {#network}

### 라우팅, 스위칭, 방화벽 및 로드 밸런싱에 관해 정의된 세부 사항은 무엇입니까? {#what-details-regarding-routing-switching-firewalling-and-load-balancing-have-been-defined}

- Geo는 **프라이머리** 사이트와 **세컨더리** 사이트가 TCP/IP 네트워크를 통해 서로 통신할 수 있어야 합니다. 특히 **세컨더리** 사이트는 **프라이머리** 사이트의 HTTP/HTTPS 및 PostgreSQL 서비스에 액세스할 수 있어야 합니다.

### 애플리케이션을 지원하는 핵심 네트워크 장치는 무엇입니까? {#what-core-network-devices-support-the-application}

- 고객마다 다릅니다.

### 어떤 네트워크 성능 요구 사항이 있습니까? {#what-network-performance-requirements-exist}

- **프라이머리** 사이트와 **세컨더리** 사이트 간의 최대 복제 속도는 사이트 간의 사용 가능한 대역폭에 의해 제한됩니다. 어려운 요구 사항이 없으며, 복제 완료 시간(그리고 **프라이머리** 사이트의 변경 사항을 따라가는 능력)은 데이터 집합의 크기, 지연 허용도 및 사용 가능한 네트워크 용량의 함수입니다.

### 애플리케이션을 지원하는 개인 및 공개 네트워크 링크는 무엇입니까? {#what-private-and-public-network-links-support-the-application}

- 고객은 자신의 네트워크를 선택합니다. 사이트는 지리적으로 분리되도록 의도되어 있으므로 일반적인 배포에서 복제 트래픽이 공개 인터넷을 통과할 것으로 예상되지만 이는 요구 사항이 아닙니다.

## 시스템 {#systems}

### 애플리케이션을 지원하는 운영 체제는 무엇입니까? {#what-operating-systems-support-the-application}

- Geo는 운영 체제에 추가 제한을 두지 않습니다(자세한 내용은 [GitLab 설치](https://about.gitlab.com/install/) 페이지 참조). 그러나 [Geo 설명서](../_index.md#requirements-for-running-geo)에 나열된 운영 체제를 사용할 것을 권장합니다.

### 필요한 OS 구성 요소 및 잠금 필요 사항과 관련하여 정의된 세부 사항은 무엇입니까? {#what-details-regarding-required-os-components-and-lock-down-needs-have-been-defined}

- 지원되는 Linux 패키지 설치 방법은 대부분의 구성 요소를 스스로 패키징합니다.
- 시스템 설치 OpenSSH 데몬(Geo는 사용자가 사용자 지정 인증 방법을 설정하도록 요구)과 Linux 패키지 제공 또는 시스템 제공 PostgreSQL 데몬(TCP에서 수신 대기하도록 구성되어야 하고, 추가 사용자 및 복제 슬롯을 추가해야 함 등)에 대한 중요한 종속성이 있습니다.
- 보안 업데이트를 처리하는 프로세스(예: OpenSSH 또는 기타 서비스에 중대한 취약성이 있고 고객이 OS에서 이러한 서비스를 패치하려는 경우)는 Geo가 아닌 상황과 동일합니다. OpenSSH에 대한 보안 업데이트는 일반적인 배포 채널을 통해 사용자에게 제공됩니다. Geo는 지연을 초래하지 않습니다.

## 인프라 모니터링 {#infrastructure-monitoring}

### 정의된 네트워크 및 시스템 성능 모니터링 요구 사항은 무엇입니까? {#what-network-and-system-performance-monitoring-requirements-have-been-defined}

- Geo 관련 사항은 없습니다.

### 악성 코드 또는 손상된 애플리케이션 구성 요소를 감지하기 위해 어떤 메커니즘이 존재합니까? {#what-mechanisms-exist-to-detect-malicious-code-or-compromised-application-components}

- Geo 관련 사항은 없습니다.

### 정의된 네트워크 및 시스템 보안 모니터링 요구 사항은 무엇입니까? {#what-network-and-system-security-monitoring-requirements-have-been-defined}

- Geo 관련 사항은 없습니다.

## 가상화 및 외부화 {#virtualization-and-externalization}

### 애플리케이션의 어떤 측면이 가상화에 적합합니까? {#what-aspects-of-the-application-lend-themselves-to-virtualization}

- 모두.

## 애플리케이션에 대해 정의된 가상화 요구 사항은 무엇입니까? {#what-virtualization-requirements-have-been-defined-for-the-application}

- Geo 관련 사항은 없지만 GitLab의 모든 것이 그러한 환경에서 완전한 기능을 갖고 있어야 합니다.

### 클라우드 컴퓨팅 모델을 통해 호스팅될 수 있거나 없을 수 있는 제품의 어떤 측면입니까? {#what-aspects-of-the-product-may-or-may-not-be-hosted-via-the-cloud-computing-model}

- GitLab은 "클라우드 네이티브"이며 이는 제품의 나머지 부분만큼 Geo에도 적용됩니다. 클라우드 배포는 일반적이고 지원되는 시나리오입니다.

## 해당하는 경우 클라우드 컴퓨팅에 대해 어떤 접근 방식을 취합니까? {#if-applicable-what-approaches-to-cloud-computing-are-taken}

- 이를 사용할지 여부는 운영 요구 사항에 따라 고객이 결정합니다:

  - 관리형 호스팅 대 "순수" 클라우드
  - AWS-ED2와 같은 "전체 머신" 접근 방식 대 AWS-RDS 및 Azure와 같은 "호스팅 데이터베이스" 접근 방식

## 환경 {#environment}

### 애플리케이션을 만드는 데 사용된 프레임워크 및 프로그래밍 언어는 무엇입니까? {#what-frameworks-and-programming-languages-have-been-used-to-create-the-application}

- Ruby on Rails, Ruby.

### 애플리케이션에 대해 정의된 프로세스, 코드 또는 인프라 종속성은 무엇입니까? {#what-process-code-or-infrastructure-dependencies-have-been-defined-for-the-application}

- Geo 관련 사항은 없습니다.

### 애플리케이션을 지원하는 데이터베이스 및 애플리케이션 서버는 무엇입니까? {#what-databases-and-application-servers-support-the-application}

- PostgreSQL >= 12, Redis, Sidekiq, Puma.

### 데이터베이스 연결 문자열, 암호화 키 및 기타 민감한 구성 요소를 보호하는 방법은 무엇입니까? {#how-to-protect-database-connection-strings-encryption-keys-and-other-sensitive-components}

- Geo 관련 값이 있습니다. 일부는 설정 시간에 **프라이머리** 사이트에서 **세컨더리** 사이트로 안전하게 전송해야 하는 공유 비밀입니다. 저희 설명서에서는 **프라이머리** 사이트에서 SSH를 통해 시스템 관리자에게 전송한 다음 같은 방식으로 **세컨더리** 사이트로 다시 전송할 것을 권장합니다. 특히 여기에는 PostgreSQL 복제 자격 증명과 데이터베이스의 특정 열을 복호화하는 데 사용되는 비밀 키(`db_key_base`)가 포함됩니다. `db_key_base` 비밀은 파일 시스템의 `/etc/gitlab/gitlab-secrets.json`에서 암호화되지 않은 상태로 저장되며 다른 여러 비밀과 함께 저장됩니다. 휴지 상태에서의 보호가 없습니다.

## 데이터 처리 {#data-processing}

### 애플리케이션이 지원하는 데이터 항목 경로는 무엇입니까? {#what-data-entry-paths-does-the-application-support}

- 데이터는 GitLab 자체에서 제공되는 웹 애플리케이션을 통해 입력됩니다. 일부 데이터는 GitLab 서버의 시스템 관리 명령을 사용하여 입력되기도 합니다(예: `gitlab-ctl set-primary-node`).
- **세컨더리** 사이트는 또한 **프라이머리** 사이트에서 PostgreSQL 스트리밍 복제를 통해 입력을 받습니다.

### 애플리케이션이 지원하는 데이터 출력 경로는 무엇입니까? {#what-data-output-paths-does-the-application-support}

- **프라이머리** 사이트는 PostgreSQL 스트리밍 복제를 통해 **세컨더리** 사이트로 출력됩니다. 그 외에는 주로 GitLab 자체에서 제공되는 웹 애플리케이션을 통해 그리고 최종 사용자가 시작한 SSH `git clone` 작업을 통해 출력됩니다.

### 데이터가 애플리케이션의 내부 구성 요소를 통해 어떻게 흐릅니까? {#how-does-data-flow-across-the-applications-internal-components}

- **세컨더리** 사이트와 **프라이머리** 사이트는 HTTP/HTTPS(JSON 웹 토큰으로 보호됨) 및 PostgreSQL 스트리밍 복제를 통해 상호 작용합니다.
- **프라이머리** 사이트 또는 **세컨더리** 사이트 내에서 SSOT는 파일 시스템과 데이터베이스입니다(**세컨더리** 사이트에 Geo 추적 데이터베이스 포함). 다양한 내부 구성 요소는 이러한 저장소에 변경을 수행하도록 오케스트레이션됩니다.

### 정의된 데이터 입력 유효성 검사 요구 사항은 무엇입니까? {#what-data-input-validation-requirements-have-been-defined}

- **세컨더리** 사이트는 **프라이머리** 사이트 데이터를 충실하게 복제해야 합니다.

### 애플리케이션이 저장하는 데이터와 그 방법은 무엇입니까? {#what-data-does-the-application-store-and-how}

- Git 리포지토리와 파일, 이들과 관련된 추적 정보, 그리고 GitLab 데이터베이스 콘텐츠.

### 어떤 데이터를 암호화해야 합니까? 정의된 키 관리 요구 사항은 무엇입니까? {#what-data-should-be-encrypted-what-key-management-requirements-are-defined}

- **프라이머리** 사이트도 **세컨더리** 사이트도 Git 리포지토리 또는 파일 시스템 데이터를 휴지 상태에서 암호화하지 않습니다. 데이터베이스 열의 일부는 `db_otp_key`을(를) 사용하여 휴지 상태에서 암호화됩니다.
- GitLab 배포의 모든 호스트에서 공유하는 정적 비밀입니다.
- 전송 중에는 데이터를 암호화해야 하지만 애플리케이션은 암호화되지 않은 통신을 계속할 수 있습니다. 두 가지 주요 전송은 **세컨더리** 사이트의 PostgreSQL 복제 프로세스이고 Git 리포지토리/파일입니다. 둘 다 TLS를 사용하여 보호되어야 하며, 키는 GitLab에 대한 최종 사용자 액세스를 위한 기존 구성에 따라 Linux 패키지에 의해 관리됩니다.

### 민감한 데이터의 누출을 감지하기 위해 어떤 기능이 존재합니까? {#what-capabilities-exist-to-detect-the-leakage-of-sensitive-data}

- GitLab 및 PostgreSQL에 대한 모든 연결을 추적하는 포괄적인 시스템 로그가 존재합니다.

### 전송 중 데이터에 대해 정의된 암호화 요구 사항은 무엇입니까? {#what-encryption-requirements-have-been-defined-for-data-in-transit}

- (여기에는 WAN, LAN, SecureFTP 또는 `http:` 및 `https:`와 같은 공개적으로 액세스 가능한 프로토콜을 통한 전송이 포함됩니다.)
- 데이터는 전송 중에 암호화될 수 있는 옵션을 가져야 하며 수동 및 능동 공격 모두에 대해 안전해야 합니다(예: MITM 공격이 가능해서는 안 됨).

## 액세스 {#access}

### 애플리케이션이 지원하는 사용자 권한 수준은 무엇입니까? {#what-user-privilege-levels-does-the-application-support}

- Geo는 한 가지 권한 유형을 추가합니다. **세컨더리** 사이트는 HTTP/HTTPS를 통해 파일을 다운로드하고 HTTP/HTTPS를 사용하여 리포지토리를 복제하기 위해 특수 Geo API에 액세스할 수 있습니다.

### 정의된 사용자 식별 및 인증 요구 사항은 무엇입니까? {#what-user-identification-and-authentication-requirements-have-been-defined}

- **세컨더리** 사이트는 공유 데이터베이스(HTTP 액세스) 또는 PostgreSQL 복제 사용자(데이터베이스 복제의 경우) 기반 OAuth 또는 JWT 인증을 통해 Geo **프라이머리** 사이트에 식별합니다. 데이터베이스 복제도 IP 기반 액세스 제어가 정의되어야 합니다.

### 정의된 사용자 권한 부여 요구 사항은 무엇입니까? {#what-user-authorization-requirements-have-been-defined}

- **세컨더리** 사이트는 데이터를 읽을 수만 있어야 합니다. **프라이머리** 사이트의 데이터를 변경할 수 없습니다.

### 정의된 세션 관리 요구 사항은 무엇입니까? {#what-session-management-requirements-have-been-defined}

- Geo JWT는 재생성이 필요하기 전에 2분 동안만 지속되도록 정의됩니다.
- Geo JWT는 다음의 특정 범위 중 하나에 대해 생성됩니다:
  - Geo API 액세스.
  - Git 액세스.
  - LFS 및 파일 ID.
  - 업로드 및 파일 ID.
  - 작업 아티팩트 및 파일 ID.

### URI 및 서비스 호출에 대해 정의된 액세스 요구 사항은 무엇입니까? {#what-access-requirements-have-been-defined-for-uri-and-service-calls}

- **세컨더리** 사이트는 **프라이머리** 사이트의 API에 많은 호출을 합니다. 이것이 파일 복제가 진행되는 방식입니다. 이 엔드포인트는 JWT 토큰으로만 액세스할 수 있습니다.
- **프라이머리** 사이트도 상태 정보를 얻기 위해 **세컨더리** 사이트에 호출합니다.

## 애플리케이션 모니터링 {#application-monitoring}

### 감사 및 디버그 로그에 액세스하고, 저장하고, 보호하는 방법은 무엇입니까? {#how-are-audit-and-debug-logs-accessed-stored-and-secured}

- 구조화된 JSON 로그는 파일 시스템에 기록되며 추가 분석을 위해 Kibana 설치로 수집할 수도 있습니다.

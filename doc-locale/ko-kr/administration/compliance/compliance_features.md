---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 관리자용 규정 준수 기능
description: "규정 준수 센터, 감사 이벤트, 보안 정책 및 규정 준수 프레임워크."
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

관리자용 GitLab 규정 준수 기능은 GitLab 인스턴스가 일반적인 규정 준수 표준을 충족하도록 합니다. 많은 기능을 그룹 및 프로젝트에서도 사용할 수 있습니다.

## 준수 워크플로우 자동화 {#compliant-workflow-automation}

준수 팀이 컨트롤과 요구사항을 올바르게 설정했는지, 그리고 설정 상태를 유지하고 있는지 확신할 수 있어야 합니다. 이를 수행하는 한 가지 방법은 설정을 정기적으로 수동으로 확인하는 것이지만, 이는 오류가 발생하기 쉽고 시간이 많이 걸립니다. 더 나은 방법은 단일 정보 소스 설정과 자동화를 사용하여 준수 팀이 구성한 모든 것이 구성 상태로 유지되고 올바르게 작동하도록 보장하는 것입니다. 다음 기능을 사용하여 준수를 자동화할 수 있습니다:

| 기능                                                                                                                                       | 인스턴스                             | 그룹                               | 프로젝트                              | 설명 |
|:----------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------|:-------------------------------------|:--------------------------------------|:------------|
| [머지 리퀘스트 승인 정책 승인 설정](../../user/application_security/policies/merge_request_approval_policies.md#approval_settings) | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | 머지 리퀘스트 승인 정책을(를) 시행하여 여러 승인자를 적용하고, GitLab 인스턴스 또는 그룹의 모든 시행된 그룹 또는 프로젝트에서 다양한 프로젝트 설정을 무시합니다. |

## 감시 관리 {#audit-management}

모든 준수 프로그램의 중요한 부분은 어떤 일이 발생했는지, 언제 발생했는지, 누가 책임이 있는지를 파악할 수 있어야 한다는 것입니다. 이 기능은 감사 상황뿐만 아니라 이슈 발생 시 근본 원인을 파악하는 데 사용할 수 있습니다.

낮은 수준의 원본 감사 데이터 목록과 높은 수준의 요약 감사 데이터 목록을 모두 보유하는 것이 도움이 됩니다. 이 두 가지 사이에서 준수 팀은 이슈가 있는지 빠르게 파악한 다음 그 이슈의 세부 사항을 자세히 살펴볼 수 있습니다. 다음 기능을 사용하여 GitLab에 대한 시야를 제공하고 발생하는 상황을 감시할 수 있습니다:

| 기능                                                  | 인스턴스                            | 그룹                               | 프로젝트                             | 설명 |
|:---------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [감시 이벤트](audit_event_reports.md)                   | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | 코드의 무결성을 유지하기 위해 감시 이벤트는 관리자에게 고급 감시 이벤트 시스템에서 GitLab 서버에 작성된 모든 수정 사항을 확인하고, 모든 변경사항을 제어, 분석, 추적할 수 있는 능력을 제공합니다. |
| [감시 보고서](audit_event_reports.md)                  | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | 발생한 감시 이벤트를 기반으로 보고서를 만들고 액세스합니다. 사전 구축된 GitLab 보고서 또는 API를 사용하여 자신만의 보고서를 만듭니다. |
| [감시 이벤트 스트리밍](audit_event_streaming.md) | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | GitLab 감시 이벤트를 HTTP 엔드포인트 또는 AWS S3나 GCP Logging과 같은 타사 서비스로 스트리밍합니다. |
| [감시자 사용자](../auditor_users.md)                        | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | 감시자 사용자는 GitLab 인스턴스의 모든 프로젝트, 그룹 및 기타 리소스에 대한 읽기 전용 액세스 권한이 부여된 사용자입니다. |

## 정책 관리 {#policy-management}

조직은 조직 표준 또는 규제 기관의 명령에 인해 고유한 정책 요구사항을 갖습니다. 다음 기능을 사용하면 워크플로우 요구사항, 업무 분리 및 안전한 공급망 모범 사례를 준수하도록 규칙과 정책을 정의할 수 있습니다:

| 기능                                                                       | 인스턴스                            | 그룹                               | 프로젝트                             | 설명 |
|:------------------------------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [자격증 인벤토리](../credentials_inventory.md)                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | GitLab 인스턴스의 모든 사용자가 사용하는 자격증을 추적합니다. |
| [세분화된 사용자 역할<br/>및 유연한 권한](../../user/permissions.md)    | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | 5가지 사용자 역할 및 외부 사용자 설정으로 액세스 및 권한을 관리합니다. 리포지토리에 대한 읽기 또는 쓰기 액세스 권한이 아닌 사람의 역할에 따라 권한을 설정합니다. 이슈 추적기에만 액세스할 필요가 있는 사람과 소스 코드를 공유하지 마세요. |
| [머지 리퀘스트 승인](../../user/project/merge_requests/approvals/_index.md) | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | 머지 리퀘스트에 필요한 승인을(를) 구성합니다. |
| [푸시 규칙](../../user/project/repository/push_rules.md)                        | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | 리포지토리로의 푸시를 제어합니다. |
| [보안 정책](../../user/application_security/policies/_index.md)          | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | 정책 규칙을 기반으로 머지 리퀘스트 승인을(를) 요구하거나 준수 요구사항을 위해 파이프라인에서 보안 스캐너를 실행하도록 강제하는 사용자 지정 가능한 정책을 구성합니다. 정책은 특정 프로젝트에 대해 세부적으로 적용하거나 그룹 또는 하위 그룹의 모든 프로젝트에 대해 적용할 수 있습니다. |

## 기타 준수 기능 {#other-compliance-features}

다음 기능도 준수 요구사항을 충족하는 데 도움이 될 수 있습니다:

| 기능                                                                                                                         | 인스턴스                            | 그룹                               | 프로젝트                             | 설명 |
|:--------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [프로젝트, 그룹 또는 전체 서버의 모든 사용자에게 이메일 발송<br/>](../email_from_gitlab.md)                                               | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | 프로젝트 또는 그룹 멤버십을 기반으로 사용자 그룹에 이메일을 발송하거나 GitLab 인스턴스를 사용하는 모든 사람에게 이메일을 발송합니다. 이러한 이메일은 예정된 유지보수 또는 업그레이드에 유용합니다. |
| [ToS 수락 강제](../settings/terms.md)                                                                                     | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | GitLab 트래픽을 차단하여 사용자가 새 서비스 약관을 수락하도록 강제합니다. |
| [사용자의 권한 수준에 대한 보고서 생성<br/>](../admin_area.md#user-permission-export)                                      | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | 인스턴스의 그룹 및 프로젝트에 대한 모든 사용자의 액세스 권한을 나열하는 보고서를 생성합니다. |
| [LDAP 그룹 동기화](../auth/ldap/ldap_synchronization.md#group-sync)                                                                 | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | 그룹을 자동으로 동기화하고 SSH 키, 권한 및 인증을 관리하여 도구를 구성하는 대신 제품을 구축하는 데 집중할 수 있습니다. |
| [LDAP 그룹 동기화 필터](../auth/ldap/ldap_synchronization.md#group-sync)                                                         | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | 필터를 기반으로 LDAP과 동기화할 수 있는 더 큰 유연성을 제공하므로 LDAP 특성을 활용하여 GitLab 권한을 매핑할 수 있습니다. |
| [Linux 패키지 설치 지원<br/>로그 전달](https://docs.gitlab.com/omnibus/settings/logs/#udp-log-forwarding) | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | 로그를 중앙 시스템으로 전달합니다. |
| [SSH 키 제한](../../security/ssh_keys_restrictions.md)                                                                       | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | GitLab에 액세스하는 데 사용되는 SSH 키의 기술 및 키 길이를 제어합니다. |

## 관련 항목 {#related-topics}

- [GitLab을 통한 소프트웨어 준수](https://about.gitlab.com/solutions/compliance/)
- [GitLab 보안](../../security/_index.md)
- [사용자용 준수 기능](../../user/compliance/_index.md)

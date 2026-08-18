---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 단일 중앙 집중식 위치에서 여러 그룹 및 프로젝트에 보안 정책을 적용하는 방법을 알아봅니다.
title: 규정 준수 및 보안 정책 그룹
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/7622)되었으며 [기능 플래그](../../../../administration/feature_flags/_index.md) `security_policies_csp`로 명명되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 18.3의 GitLab Self-Managed에서 [기본적으로 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/550318)되었습니다.
- GitLab 18.5에서 [정식 출시(GA)](https://gitlab.com/groups/gitlab-org/-/epics/17392). 기능 플래그 `security_policies_csp`이 제거되었습니다.

{{< /history >}}

중앙 집중식 보안 정책 관리를 통해 인스턴스 관리자는 규정 준수 및 보안 정책 그룹을 지정하여 단일 중앙 집중식 위치에서 여러 그룹 및 프로젝트에 보안 정책을 적용할 수 있습니다.

규정 준수 및 보안 정책 그룹에서 보안 정책을 만들거나 편집할 때 그룹의 범위를 지정하여 다음과 같은 항목에 정책을 적용할 수 있습니다:

- **Specific groups and subgroups**: 선택한 그룹 및 하위 그룹에만 정책을 적용합니다.
- **Specific projects**: 개별 프로젝트에 정책을 적용합니다.
- **All projects in the instance**: 전체 GitLab 인스턴스에 정책을 적용합니다.
- **All projects with exceptions**: 지정한 프로젝트를 제외한 모든 프로젝트에 적용합니다.

규정 준수 및 보안 정책 그룹을 중앙 집중식 정책 관리 허브로 지정하면 다음을 수행할 수 있습니다:

- 인스턴스 전체에 자동으로 적용되는 보안 정책을 만들고 구성합니다.
- 특정 그룹, 프로젝트 또는 전체 인스턴스로 정책의 범위를 지정합니다.
- 정책 범위를 확인하여 어떤 정책이 활성화되어 있고 어디서 활성화되어 있는지 이해합니다.
- 팀이 자신의 추가 정책을 만들 수 있도록 하면서 중앙 집중식 제어를 유지합니다.

## 전제 조건 {#prerequisites}

- GitLab Self-Managed입니다.
- GitLab 18.2 이상입니다.
- 인스턴스 관리자여야 합니다.
- 규정 준수 및 보안 정책 그룹으로 사용할 기존 최상위 그룹이 있어야 합니다.
- REST API를 사용하려면(선택 사항) 관리자 액세스 권한이 있는 토큰이 있어야 합니다.

## 중앙 집중식 보안 정책 관리 설정 {#set-up-centralized-security-policy-management}

중앙 집중식 보안 정책 관리를 설정하려면 규정 준수 및 보안 정책 그룹을 지정한 다음 그룹에서 정책을 만듭니다.

자세한 내용은 [인스턴스 전체 규정 준수 및 보안 정책 관리](../../../../security/compliance_security_policy_management.md)를 참조하세요.

### 전역 승인 그룹 활성화 {#enable-global-approval-groups}

인스턴스 전체에서 전역으로 승인 그룹을 지원하려면 다음을 수행해야 합니다:

- `security_policy_global_group_approvers_enabled`을(를) [GitLab 인스턴스 애플리케이션 설정](../../../../api/settings.md)에서 활성화합니다.

### 규정 준수 및 보안 정책 그룹에서 보안 정책 만들기 {#create-security-policies-in-the-compliance-and-security-policy-group}

정책을 만들려면:

1. 지정된 규정 준수 및 보안 정책 그룹으로 이동합니다.
1. **보안** > **정책**으로 이동합니다.
1. 일반적으로 하는 대로 하나 이상의 보안 정책을 만듭니다. 각 정책을 저장하기 전에:
   - **정책 범위** 섹션에서 정책을 적용할 범위를 선택합니다:
     - **그룹**: 특정 그룹 및 하위 그룹에 정책을 적용합니다.
     - **프로젝트**: 개별 프로젝트에 정책을 적용합니다.
     - **모든 프로젝트**: 전체 인스턴스에 적용합니다.
     - **All projects except**: 지정된 예외를 제외한 모든 프로젝트에 적용합니다.
1. 정책 구성을 저장합니다.

## 정책 스토리지 및 구성 {#policy-storage-and-configuration}

규정 준수 및 보안 정책 그룹의 정책은 지정된 규정 준수 및 보안 정책 그룹에 있는 `policy.yml` 파일에 저장되며, 그룹 정책이 관리되는 방식과 유사합니다. 규정 준수 및 보안 정책 그룹에서 만든 정책은 다른 그룹 및 프로젝트의 보안 정책과 동일한 구성 형식을 사용합니다.

## 정책 동기화 {#policy-synchronization}

- 범위 내의 그룹 및 프로젝트 수에 따라 정책 변경이 인스턴스 전체에 적용되는 데 시간이 걸릴 수 있습니다.
- 동기화 프로세스는 규정 준수 및 보안 정책 그룹을 지정하거나 정책을 만들거나 정책을 업데이트할 때 자동으로 큐에 추가되는 작업을 사용합니다.
- 인스턴스 관리자는 **운영자** > **모니터링** > **백그라운드 작업**에서 백그라운드 작업 처리를 모니터링할 수 있습니다.
- 정책이 대상 그룹 또는 프로젝트에 성공적으로 적용되었는지 확인하려면 그룹 또는 프로젝트에서 **보안** > **정책**으로 이동합니다.

### 성능 관리 {#managing-performance}

성능 이슈를 방지하려면 구성 수정 횟수를 최소화하도록 정책 관리 전략을 계획합니다:

- 변경 사항을 신중하게 계획합니다: 규정 준수 및 보안 정책 그룹 변경을 빠르게 연속해서 수행하지 마세요.
- 유지 관리 기간 중에 변경 사항을 예약합니다: 사용자에게 미치는 영향을 최소화하기 위해 사용률이 낮은 기간 중에 변경 사항을 수행합니다.
- 시스템 성능을 모니터링합니다: 동기화 중에 잠재적인 성능 저하에 대비합니다.
- 추가 시간을 허용합니다: 동기화 프로세스 완료 시간은 인스턴스 크기에 따라 다릅니다.

## 문제 해결 {#troubleshooting}

**Policy does not appear in the target group or project**

- 정책 범위에 대상 그룹 또는 프로젝트가 포함되어 있는지 확인합니다.
- 규정 준수 및 보안 정책 그룹이 관리 설정에서 올바르게 지정되어 있는지 확인합니다.
- 정책이 규정 준수 및 보안 정책 그룹에서 활성화되어 있는지 확인합니다.
- 정책 변경이 적용되는 데 시간이 걸릴 수 있습니다. [정책 동기화](#policy-synchronization)를 참조하여 자세한 내용을 확인하세요.

**Performance concerns**

- 정책 전파 시간을 모니터링하세요. 특히 범위가 큰 구성에서 주의하세요.
- 모든 프로젝트에 정책을 적용하는 대신 특정 그룹 또는 프로젝트로 정책의 범위를 지정하는 것을 고려합니다.
- 규정 준수 보안 정책 그룹을 수정할 때 성능 영향을 줄이려면 [성능 관리](#managing-performance)를 참조하세요.

## 피드백 및 지원 {#feedback-and-support}

이것은 베타 릴리스이므로 사용자 피드백을 권장합니다. 다음을 통해 경험, 제안 및 이슈를 공유하세요:

- [GitLab 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues).
- 정기적인 GitLab 지원 채널입니다.

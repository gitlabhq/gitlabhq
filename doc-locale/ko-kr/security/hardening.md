---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 강화 권장 사항
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 설명서는 전체 시스템을 일반적인 공격은 물론 드문 공격까지 '강화'할 수 있는 GitLab Self-Managed 인스턴스를 대상으로 합니다. 공격을 완전히 제거하도록 설계된 것이 아니며, 강력한 완화를 제공하여 전반적인 위험을 줄이기 위한 것입니다. 일부 기법은 GitLab.com 또는 GitLab Self-Managed와 같은 모든 GitLab 배포에 적용되지만, 다른 기법은 기본 OS에 적용됩니다.

이러한 기법들은 진행 중인 작업이며 대규모(예: 많은 사용자가 있는 큰 환경)로 테스트되지 않았습니다. Linux 패키지 설치를 실행하는 자체 관리형 단일 인스턴스에서 테스트되었으며, 많은 기법을 다른 배포 유형으로 전환할 수 있지만 모두 작동하거나 적용되지는 않을 수 있습니다.

나열된 권장 사항의 대부분은 일반 설명서를 기반으로 구체적인 권장 사항 또는 선택 참조를 제공합니다. 강화를 통해 사용자가 특히 원하거나 의존하는 특정 기능에 영향을 미칠 수 있으므로 사용자와 통신하고 강화 변경의 단계적 출시를 수행해야 합니다.

강화 지침은 더 쉬운 이해를 위해 5개 범주로 나뉩니다. 다음 섹션에 나와 있습니다.

## GitLab 강화 일반 개념 {#gitlab-hardening-general-concepts}

이는 보안에 대한 접근 방식으로서의 강화 및 더 큰 철학에 대한 정보를 자세히 설명합니다. 자세한 내용은 [강화 일반 개념](hardening_general_concepts.md)을 참조하세요.

## GitLab 애플리케이션 설정 {#gitlab-application-settings}

GitLab GUI를 사용하여 애플리케이션 자체에 대해 수행된 애플리케이션 설정입니다. 자세한 내용은 [애플리케이션 권장 사항](hardening_application_recommendations.md)을 참조하세요.

## GitLab CI/CD 설정 {#gitlab-cicd-settings}

CI/CD는 GitLab의 핵심 구성 요소이며, 보안 원칙의 적용은 필요에 따라 달라지지만 CI/CD를 더욱 안전하게 만들기 위해 수행할 수 있는 몇 가지 방법이 있습니다. 자세한 내용은 [CI/CD 권장 사항](hardening_cicd_recommendations.md)을 참조하세요.

## GitLab 구성 설정 {#gitlab-configuration-settings}

애플리케이션을 제어하고 구성하는 데 사용되는 구성 파일 설정(예: `gitlab.rb`) 은 별도로 문서화되어 있습니다. 자세한 내용은 [구성 권장 사항](hardening_configuration_recommendations.md)을 참조하세요.

## 운영 체제 설정 {#operating-system-settings}

기본 운영 체제를 조정하여 전반적인 보안을 높일 수 있습니다. 자세한 내용은 [운영 체제 권장 사항](hardening_operating_system_recommendations.md)을 참조하세요.

## NIST 800-53 준수 {#nist-800-53-compliance}

GitLab Self-Managed를 구성하여 NIST 800-53 보안 표준 준수를 강제할 수 있습니다. 자세한 내용은 [NIST 800-53 준수](hardening_nist_800_53.md)를 참조하세요.

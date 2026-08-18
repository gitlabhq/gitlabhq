---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 관리 개요입니다.
title: GitLab 관리 시작하기
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab 관리를 시작합니다. 조직과 인증을 구성한 다음 GitLab을 보호하고, 모니터링하고, 백업합니다.

## 인증 {#authentication}

인증은 설치를 보호하는 첫 번째 단계입니다.

- [모든 사용자에게 2단계 인증(2FA) 적용](../security/two_factor_authentication.md)합니다.
- 사용자는 다음을 수행합니다:
  - 강력하고 안전한 암호를 선택합니다. 가능하면 암호 관리 시스템에 저장합니다.
  - 모든 사용자에게 구성되지 않은 경우 계정에 대해 [2단계 인증(2FA)](../user/profile/account/two_factor_authentication.md)을 설정합니다. 이 일회성 비밀 코드는 암호가 있어도 침입자를 막아주는 추가 보안입니다.
  - 백업 이메일을 추가합니다. 계정에 대한 액세스를 잃으면 GitLab 지원팀이 더 빨리 도와줄 수 있습니다.
  - 복구 코드를 저장하거나 인쇄합니다. 인증 장치에 액세스할 수 없으면 이 복구 코드를 사용하여 GitLab 계정에 로그인할 수 있습니다.
  - 프로필에 [SSH 키](../user/ssh.md)를 추가합니다. SSH를 사용하여 필요에 따라 복구 코드를 생성할 수 있습니다.
  - [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을 생성합니다. 2FA를 사용할 때 이 토큰을 사용하여 GitLab API에 액세스할 수 있습니다.

## 프로젝트 및 그룹 {#projects-and-groups}

그룹과 프로젝트를 구성하여 환경을 조직합니다.

- [프로젝트](../user/project/working_with_projects.md):  파일과 코드를 위한 홈을 지정하거나 비즈니스 카테고리에서 이슈를 추적하고 정리합니다.
- [그룹](../user/group/_index.md):  사용자 또는 프로젝트 컬렉션을 구성합니다. 이 그룹을 사용하여 신속하게 사람과 프로젝트를 할당합니다.
- [역할](../user/permissions.md):  프로젝트 및 그룹에 대한 사용자 액세스 및 가시성을 정의합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> [그룹 및 프로젝트](https://www.youtube.com/watch?v=cqb2m41At6s) 개요를 시청합니다.

시작:

- [프로젝트](../user/project/_index.md)를 생성합니다.
- [그룹](../user/group/_index.md#create-a-group)을 생성합니다.
- 그룹에 [멤버 추가](../user/group/_index.md#add-users-to-a-group)합니다.
- [하위 그룹](../user/group/subgroups/_index.md#create-a-subgroup)을 생성합니다.
- 하위 그룹에 [멤버 추가](../user/group/subgroups/_index.md#subgroup-membership)합니다.
- [외부 인증 제어](settings/external_authorization.md#configuration)를 설정합니다.

**More resources**

- [여러 애자일 팀 실행](https://www.youtube.com/watch?v=VR2r1TJCDew)합니다.
- [LDAP를 사용하여 그룹 멤버십 동기화](auth/ldap/ldap_synchronization.md#group-sync)합니다.
- 상속된 권한으로 사용자 액세스를 관리합니다. 최대 20개 수준의 하위 그룹을 사용하여 팀과 프로젝트를 구성합니다.
  - [상속된 멤버십](../user/project/members/_index.md#membership-types).
  - [예시](../user/group/subgroups/_index.md).

## 프로젝트 가져오기 {#import-projects}

GitHub, Bitbucket 또는 다른 GitLab 인스턴스와 같은 외부 소스에서 프로젝트를 가져와야 할 수도 있습니다. 많은 외부 소스를 GitLab으로 가져올 수 있습니다.

- [GitLab 프로젝트 설명서](../user/project/_index.md)를 검토합니다.
- [리포지토리 미러링](../user/project/repository/mirror/_index.md) 을 고려하거나 [프로젝트 마이그레이션 대안](../ci/ci_cd_for_external_repos/_index.md)을 고려합니다.
- [GitLab로 가져오기 및 마이그레이션](../user/import/_index.md)을 확인하여 일반적인 마이그레이션 경로에 대한 설명서를 참조합니다.
- [가져오기/내보내기 API](../api/project_import_export.md#export-a-project)를 사용하여 프로젝트 내보내기를 예약합니다.

### 인기 있는 프로젝트 가져오기 {#popular-project-imports}

- [GitHub Enterprise에서 GitLab Self-Managed로](../integration/github.md)
- [Bitbucket Server](../user/import/bitbucket_server.md)

이러한 데이터 유형에 대한 도움을 받으려면 GitLab 계정 담당자 또는 GitLab 지원팀에 문의하여 저희 전문 마이그레이션 서비스에 대해 알아봅니다.

## GitLab 인스턴스 보안 {#gitlab-instance-security}

보안은 온보딩 프로세스의 중요한 부분입니다. 인스턴스를 보호하면 작업과 조직을 보호합니다.

이것이 완전한 목록은 아니지만 다음 단계를 따르면 인스턴스를 보호하기 위한 견고한 시작을 할 수 있습니다.

- 긴 루트 암호를 사용하여 금고에 저장합니다.
- 신뢰할 수 있는 SSL 인증서를 설치하고 갱신 및 철회를 위한 프로세스를 수립합니다.
- 조직의 지침에 따라 [SSH 키 제한을 구성](../security/ssh_keys_restrictions.md)합니다.
- [새 사용자 계정 생성을 끕니다](settings/sign_up_restrictions.md#disable-new-user-account-creation).
- 이메일 확인이 필요합니다.
- 암호 길이 제한을 설정하고 SSO 또는 SAML 사용자 관리를 구성합니다.
- 새 사용자가 계정을 생성하도록 허용하는 경우 이메일 도메인을 제한합니다.
- 2단계 인증(2FA)을 요구합니다.
- [Git over HTTPS의 암호 인증을 끕니다](settings/sign_in_restrictions.md#allow-password-authentication-for-git-over-https).
- [알 수 없는 로그인에 대한 이메일 알림을 설정](settings/sign_in_restrictions.md#email-notification-for-unknown-sign-ins)합니다.
- [사용자 및 IP 속도 제한](https://about.gitlab.com/blog/gitlab-instance-security-best-practices/#user-and-ip-rate-limits)을 구성합니다.
- [웹후크 로컬 액세스](https://about.gitlab.com/blog/gitlab-instance-security-best-practices/#webhooks)를 제한합니다.
- [보호된 경로에 대한 속도 제한](settings/protected_paths.md)을 설정합니다.
- 커뮤니케이션 환경설정 센터에서 [보안 경고](https://about.gitlab.com/company/preference-center/)를 구독합니다.
- [블로그 페이지](https://about.gitlab.com/blog/gitlab-instance-security-best-practices/)에서 보안 모범 사례를 추적합니다.

## GitLab 성능 모니터링 {#monitor-gitlab-performance}

기본 설정을 완료한 후 GitLab 모니터링 서비스를 검토할 준비가 됩니다. Prometheus는 저희의 핵심 성능 모니터링 도구입니다. 다른 모니터링 솔루션(예: Zabbix 또는 New Relic)과 달리 Prometheus는 GitLab과 긴밀하게 통합되어 있으며 광범위한 커뮤니티 지원을 받습니다.

- [Prometheus](monitoring/prometheus/_index.md) 는 [이러한 GitLab 메트릭](monitoring/prometheus/gitlab_metrics.md#metrics-available)을 캡처합니다.
- GitLab [번들 소프트웨어 메트릭](monitoring/prometheus/_index.md#bundled-software-metrics)에 대해 자세히 알아봅니다.
- Prometheus 및 해당 익스포터는 기본적으로 켜져 있습니다. 그러나 [서비스를 구성](monitoring/prometheus/_index.md#configuring-prometheus)해야 합니다.
- [애플리케이션 성능 메트릭](https://about.gitlab.com/blog/working-with-performance-metrics/)이 중요한 이유를 알아봅니다.
- Grafana를 통합하여 성능 메트릭을 기반으로 [시각적 대시보드를 구축](https://youtu.be/f4R7s0An1qE)합니다.

### 모니터링 구성 요소 {#components-of-monitoring}

- [웹 서버](monitoring/prometheus/gitlab_metrics.md#puma-metrics):  서버 요청을 처리하고 다른 백엔드 서비스 트랜잭션을 용이하게 합니다. CPU, 메모리 및 네트워크 IO 트래픽을 모니터링하여 이 노드의 상태를 추적합니다.
- [Workhorse](monitoring/prometheus/gitlab_metrics.md#metrics-available):  주 서버의 웹 트래픽 혼잡을 완화합니다. 지연 스파이크를 모니터링하여 이 노드의 상태를 추적합니다.
- [Sidekiq](monitoring/prometheus/gitlab_metrics.md#sidekiq-metrics):  GitLab이 원활하게 실행되도록 하는 백그라운드 작업을 처리합니다. 처리되지 않은 긴 작업 큐를 모니터링하여 이 노드의 상태를 추적합니다.

## GitLab 데이터 백업 {#back-up-your-gitlab-data}

GitLab은 데이터를 안전하게 유지하고 복구 가능하게 하기 위한 백업 방법을 제공합니다.

- 백업 전략을 결정합니다.
- 일일 백업을 하기 위해 cron 작업을 작성하는 것을 고려합니다.
- 구성 파일을 별도로 백업합니다.
- 백업에서 제외해야 할 사항을 결정합니다.
- 백업을 업로드할 위치를 결정합니다.
- 백업 수명을 제한합니다.
- 테스트 백업 및 복원을 실행합니다.
- 백업을 주기적으로 확인하는 방법을 설정합니다.

### 인스턴스 백업 {#back-up-an-instance}

Linux 패키지를 사용하여 배포했는지 또는 Helm 차트를 사용하여 배포했는지에 따라 루틴이 다릅니다.

Linux 패키지를 사용하는 단일 노드 설치를 백업하려면 단일 Rake 작업을 사용할 수 있습니다.

[Linux 패키지 또는 Helm 변형 백업](backup_restore/_index.md)에 대해 알아봅니다. 이 프로세스는 전체 인스턴스를 백업하지만 구성 파일은 백업하지 않습니다. 이러한 파일이 별도로 백업되었는지 확인합니다. 구성 파일과 백업 아카이브를 별도의 위치에 보관하여 암호화 키가 암호화된 데이터와 함께 보관되지 않도록 합니다.

#### 백업 복원 {#restore-a-backup}

백업을 생성된 GitLab의 정확한 동일 버전 및 유형(커뮤니티 에디션 또는 엔터프라이즈 에디션)으로만 복원할 수 있습니다.

- [Linux 패키지(Omnibus) 백업 및 복원 설명서](https://docs.gitlab.com/omnibus/settings/backups)를 검토합니다.
- [Helm Chart 백업 및 복원 설명서](https://docs.gitlab.com/charts/backup-restore/)를 검토합니다.

### 대체 백업 전략 {#alternative-backup-strategies}

경우에 따라 백업을 위한 Rake 작업이 최적의 솔루션이 아닐 수 있습니다. Rake 작업이 작동하지 않는 경우 고려해야 할 [대안](backup_restore/_index.md)들입니다.

#### 파일 시스템 스냅숏 {#file-system-snapshot}

GitLab 서버에 많은 Git 리포지토리 데이터가 포함되어 있으면 GitLab 백업 스크립트가 너무 느릴 수 있습니다. 오프사이트 위치로 백업할 때 특히 느릴 수 있습니다.

느림은 일반적으로 약 200GB의 Git 리포지토리 데이터 크기에서 시작됩니다. 이 경우 백업 전략의 일부로 파일 시스템 스냅숏을 사용하는 것을 고려할 수 있습니다. 예를 들어 다음 구성 요소가 있는 GitLab 서버를 고려합니다:

- Linux 패키지를 사용합니다.
- AWS에서 호스팅되며 `/var/opt/gitlab`에 마운트된 ext4 파일 시스템이 있는 EBS 드라이브를 포함합니다.

EC2 인스턴스는 EBS 스냅숏을 사용하여 애플리케이션 데이터 백업 요구 사항을 충족합니다. 백업에는 모든 리포지토리, 업로드 및 PostgreSQL 데이터가 포함됩니다.

가상화된 서버에서 GitLab을 실행하는 경우 전체 GitLab 서버의 VM 스냅숏을 생성할 수 있습니다. VM 스냅숏은 일반적으로 서버를 종료하도록 요구합니다.

#### GitLab Geo {#gitlab-geo}

{{< details >}}

- 티어:  Premium, Ultimate

{{< /details >}}

Geo는 GitLab 인스턴스의 로컬 읽기 전용 인스턴스를 제공합니다.

GitLab Geo는 로컬 GitLab 노드를 사용하여 원격 팀이 더 효율적으로 작동하도록 도와주지만 재해 복구 솔루션으로도 사용할 수 있습니다. [재해 복구 솔루션으로 Geo 사용](geo/disaster_recovery/_index.md)에 대해 자세히 알아봅니다.

Geo는 데이터베이스, Git 리포지토리 및 몇 가지 다른 자산을 복제합니다. [Geo가 복제하는 데이터 유형](geo/replication/datatypes.md#replicated-data-types)에 대해 자세히 알아봅니다.

## GitLab 지원으로 도움받기 {#get-help-with-gitlab-support}

GitLab은 다양한 채널을 통해 GitLab Self-Managed에 대한 지원을 제공합니다.

- 우선 지원:  [Premium 및 Ultimate](https://about.gitlab.com/pricing/) GitLab Self-Managed 고객은 계층화된 응답 시간을 통해 우선 지원을 받습니다. [우선 지원으로 업그레이드](https://about.gitlab.com/support/#upgrading-to-priority-support)에 대해 자세히 알아봅니다.
- 라이브 업그레이드 지원:  프로덕션 업그레이드 중에 일대일 전문가 지도를 받습니다. **priority support plan**을 사용하면 저희 지원팀 구성원과의 라이브 예약 화면 공유 세션에 적합합니다.

도움을 받으려면:

- 자체 서비스 지원을 위해 GitLab 설명서를 사용합니다.
- 커뮤니티 지원을 위해 [GitLab Forum](https://forum.gitlab.com/)에 가입합니다.
- 티켓을 제출하기 전에 [구독 정보](https://about.gitlab.com/support/#for-self-managed-users)를 수집합니다.
- [지원 티켓 제출](https://support.gitlab.com/hc/en-us/requests/new)합니다.

## API 및 속도 제한 {#api-and-rate-limits}

속도 제한은 서비스 거부 또는 무차별 대입 공격을 방지합니다. 대부분의 경우 단일 IP 주소에서의 요청 속도를 제한하여 애플리케이션 및 인프라의 부하를 줄일 수 있습니다.

속도 제한은 애플리케이션의 보안을 향상시킵니다.

### 속도 제한 구성 {#configure-rate-limits}

**운영자** 영역에서 기본 속도 제한을 변경할 수 있습니다. 구성에 대한 자세한 내용은 [**운영자** 영역 페이지](../security/rate_limits.md#configurable-limits)를 참조합니다.

- [이슈 속도 제한](settings/rate_limit_on_issues_creation.md)을 정의하여 분당 사용자당 최대 이슈 생성 요청 수를 설정합니다.
- 인증되지 않은 웹 요청에 대해 [사용자 및 IP 속도 제한](settings/user_and_ip_rate_limits.md)을 적용합니다.
- [원본 엔드포인트에 대한 속도 제한](settings/rate_limits_on_raw_endpoints.md)을 검토합니다. 기본 설정은 원본 파일 액세스의 경우 분당 300개 요청입니다.
- [가져오기/내보내기 속도 제한](settings/import_export_rate_limits.md)을 검토하여 6개의 활성 기본값을 확인합니다.

API 및 속도 제한에 대한 자세한 내용은 [API 페이지](../api/rest/_index.md)를 참조합니다.

## GitLab 교육 리소스 {#gitlab-training-resources}

GitLab 관리 방법에 대해 자세히 알아볼 수 있습니다.

- [GitLab Forum](https://forum.gitlab.com/)에 참여하여 재능 있는 커뮤니티와 팁을 공유합니다.
- [저희 블로그](https://about.gitlab.com/blog/)를 확인하여 다음에 대한 지속적인 업데이트를 받습니다:
  - 릴리스
  - 응용 프로그램
  - 기여도
  - 뉴스
  - 이벤트

### 유료 GitLab 교육 {#paid-gitlab-training}

- GitLab 교육 서비스:  [GitLab 및 DevOps 모범 사례](https://about.gitlab.com/services/education/)에 대해 자세히 알아봅니다. 전체 과정 카탈로그를 참조합니다.

### 무료 GitLab 교육 {#free-gitlab-training}

- GitLab 기본:  [Git 및 GitLab 기본](../tutorials/_index.md)에 대한 자체 서비스 가이드를 발견합니다.
- GitLab University:  [GitLab University](https://university.gitlab.com/learn/dashboard)에서 구조화된 과정으로 새로운 GitLab 기술을 배웁니다.

### 타사 교육 {#third-party-training}

- Udemy:  더 저렴하고 안내된 교육 옵션을 원하는 경우 [GitLab CI: Pipelines, CI/CD, and DevOps for Beginners](https://www.udemy.com/course/gitlab-ci-pipelines-ci-cd-and-devops-for-beginners/) on Udemy를 고려합니다.
- LinkedIn Learning:  LinkedIn Learning에서 [GitLab을 통한 지속적 전달](https://www.linkedin.com/learning/continuous-integration-and-continuous-delivery-with-gitlab?replacementOf=continuous-delivery-with-gitlab)을 확인하여 또 다른 저비용 안내 교육 옵션을 확인합니다.

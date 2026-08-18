---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 역할 및 권한
description: GitLab의 각 사용자 역할에서 사용할 수 있는 권한 및 기능을 이해합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

역할은 그룹 또는 프로젝트에서 사용자의 권한을 정의합니다.

[관리자 액세스](../administration/_index.md)권한이 있는 사용자는 모든 권한을 가지며 모든 작업을 수행할 수 있습니다.

## 역할 {#roles}

{{< history >}}

- 플래너 역할이 GitLab 17.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/482733)되었습니다.
- 보안 관리자 역할이 GitLab 18.11에서 [베타](../policy/development_stages_support.md#beta)로 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/20123)되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 18.11에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/work_items/594930)됨

{{< /history >}}

사용자를 그룹 또는 프로젝트에 추가할 때 역할을 할당합니다. 역할은 사용자의 권한을 결정합니다. [기본 역할](#default-roles) 또는 [사용자 지정 역할](custom_roles/_index.md)을 할당합니다.

사용자는 각 그룹 및 프로젝트에 대해 다른 역할을 가질 수 있습니다. 사용자는 항상 최고 역할의 권한을 유지합니다. 예를 들어 사용자가 다음을 가진 경우:

- 상위 그룹의 유지 관리자 역할
- 해당 그룹의 프로젝트에 대한 개발자 역할

사용자는 프로젝트에서 유지 관리자 역할의 권한을 상속합니다.

할당된 역할을 보려면 [그룹](group/_index.md#view-group-members) 또는 [프로젝트](project/members/_index.md#view-project-members)에 대한 **멤버** 페이지로 이동합니다.

### 기본 역할 {#default-roles}

다음 기본 역할을 사용할 수 있습니다:

| 역할             | 설명 |
| ---------------- | ----------- |
| 최소 액세스   | 프로젝트에 액세스하지 않고 제한된 그룹 정보를 봅니다. 자세한 내용은 [최소 액세스 권한이 있는 사용자](#users-with-minimal-access)를 참조합니다. |
| 게스트            | 이슈 및 에픽을 보고 댓글을 달 수 있습니다. 코드를 푸시하거나 리포지토리에 액세스할 수 없습니다. 이 역할은 [비공개 및 내부 프로젝트](public_access.md)에만 적용됩니다. |
| 플래너          | 이슈, 에픽, 마일스톤 및 반복을 생성하고 관리합니다. 프로젝트 계획 및 추적에 중점을 두고 코드 변경 사항을 보고 협업할 수 있습니다. |
| 리포터         | 코드를 보고 이슈를 생성하며 보고서를 생성합니다. 코드를 푸시하거나 보호 브랜치를 관리할 수 없습니다. |
| 보안 관리자 | 보안 취약성, 규정 준수 구성 및 감사 이벤트를 보고 관리합니다. 코드 푸시 액세스 없이 보안 운영에 중점을 둡니다. |
| 개발자        | 보호되지 않은 브랜치에 코드를 푸시하고, 머지 리퀘스트를 생성하며, CI/CD 파이프라인을 실행합니다. 프로젝트 설정을 관리할 수 없습니다. |
| 유지 관리자       | 브랜치, 머지 리퀘스트, CI/CD 설정 및 프로젝트 멤버를 관리합니다. 프로젝트를 삭제할 수 없습니다. |
| 소유자            | 삭제 및 가시성 설정을 포함한 프로젝트 또는 그룹에 대한 전체 제어. |

기본적으로 모든 사용자는 최상위 그룹을 생성하고 사용자 이름을 변경할 수 있습니다. [관리자 액세스](../administration/user_settings.md)권한이 있는 사용자는 이 동작을 변경할 수 있습니다.

<!--
Sort these permissions according the following rules in order:
1. By minimum role.
2. By the object being accessed (for example, issue, security dashboard, or pipeline)
3. By the action: view, create, change, edit, manage, run, delete, all others
4. Alphabetically.

List only one action (for example, view, create, or delete) per line.
It's okay to list multiple related objects per line (for example, "View pipelines and pipeline details").
-->

## 그룹 권한 {#group-permissions}

사용자는 자신이 유일한 소유자가 아닌 한 그룹에서 자신을 제거할 수 있습니다.

다음 표는 각 역할에 사용 가능한 그룹 권한을 나열합니다:

### 그룹 {#groups}

[그룹 기능](group/_index.md)에 대한 그룹 권한:

| 작업                                                                                      | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ------------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 그룹 탐색                                                                                |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 그룹에서 프로젝트 [검색](search/_index.md)                                                |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 그룹 [감사 이벤트](compliance/audit_events.md) <sup>1</sup> 보기                          |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| 그룹에서 프로젝트 생성 <sup>2</sup>                                                        |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 하위 그룹 생성 <sup>3</sup>                                                                |       |         |          |                  |           |     ✓      |   ✓   |
| [프로젝트 통합](project/integrations/_index.md)에 대한 사용자 지정 설정 변경           |       |         |          |                  |           |            |   ✓   |
| [에픽](group/epics/_index.md) 댓글 편집(모든 사용자가 게시함)                            |       |         |          |                  |           |     ✓      |   ✓   |
| 그룹으로 프로젝트 포크                                                                   |       |         |          |                  |           |     ✓      |   ✓   |
| [청구](../subscriptions/manage_subscription.md#view-subscription) <sup>4</sup> 보기      |       |         |          |                  |           |            |   ✓   |
| 그룹 [사용 할당량](storage_usage_quotas.md) 페이지 <sup>4</sup> 보기                        |       |         |          |                  |           |            |   ✓   |
| [그룹 마이그레이션](group/import/_index.md)                                                     |       |         |          |                  |           |            |   ✓   |
| 그룹 보관                                                                               |       |         |          |                  |           |            |   ✓   |
| 그룹 삭제                                                                                |       |         |          |                  |           |            |   ✓   |
| 그룹 전송                                                                              |       |         |          |                  |           |            |   ✓   |
| [구독, 스토리지 및 컴퓨팅 분](../subscriptions/manage_seats.md#gitlabcom-billing-and-usage) 관리 |       |         |          |                  |           |            |   ✓   |
| [그룹 액세스 토큰](group/settings/group_access_tokens.md) 관리                         |       |         |          |                  |           |            |   ✓   |
| 그룹 가시성 수준 변경                                                               |       |         |          |                  |           |            |   ✓   |
| 그룹 설정 편집                                                                         |       |         |          |                  |           |            |   ✓   |
| 프로젝트 템플릿 구성                                                                 |       |         |          |                  |           |            |   ✓   |
| [SAML SSO](group/saml_sso/_index.md) <sup>4</sup> 구성                                 |       |         |          |                  |           |            |   ✓   |
| 알림 이메일 비활성화                                                                 |       |         |          |                  |           |            |   ✓   |
| [프로젝트](project/settings/import_export.md) 가져오기                                         |       |         |          |                  |           |     ✓      |   ✓   |

**각주**:

1. 개발자 및 유지 관리자는 개별 작업에만 따라 이벤트를 볼 수 있습니다. 자세한 내용은 [필수 조건](compliance/audit_events.md#prerequisites)을 참조합니다.
1. 개발자, 유지 관리자 및 소유자: [인스턴스에 대해](../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects) 또는 [그룹에 대해](group/_index.md#specify-who-can-add-projects-to-a-group) 프로젝트 생성 역할이 설정된 경우만 해당합니다.
   <br>개발자: 개발자는 [기본 브랜치 보호](group/manage.md#change-the-default-branch-protection-of-a-group)가 "부분 보호됨" 또는 "보호되지 않음"으로 설정된 경우에만 새 프로젝트의 기본 브랜치에 커밋을 푸시할 수 있습니다.
1. 유지 관리자: 유지 관리자 역할의 사용자가 [하위 그룹을 생성할](group/subgroups/_index.md#change-who-can-create-subgroups) 수 있는 경우만 해당합니다.
1. 하위 그룹에는 적용되지 않습니다.

### 그룹 분석 {#group-analytics}

값 스트림, 제품 분석 및 인사이트를 포함한 [분석](analytics/_index.md) 기능에 대한 그룹 권한:

| 작업                                                             | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ------------------------------------------------------------------ | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| [GitLab Duo 및 SDLC 트렌드](analytics/duo_and_sdlc_trends.md) 보기                        |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [인사이트](project/insights/_index.md) 보기                        |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [인사이트](project/insights/_index.md) 차트 보기                 |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [이슈 분석](group/issues_analytics/_index.md) 보기           |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 기여도 분석 보기                                        |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 값 스트림 분석 보기                                        |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [생산성 분석](analytics/productivity_analytics.md) 보기 |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [그룹 DevOps 채택](group/devops_adoption/_index.md) 보기      |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 메트릭 대시보드 주석 보기                                 |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 메트릭 대시보드 주석 관리                               |       |         |          |                  |     ✓     |     ✓      |   ✓   |

### 그룹 애플리케이션 보안 {#group-application-security}

종속성 관리, 보안 분석기, 보안 정책 및 취약성 관리를 포함한 [애플리케이션 보안](application_security/secure_your_application.md) 기능에 대한 그룹 권한.

| 작업                                                                           | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| -------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| [종속성 목록](application_security/dependency_list/_index.md) 보기           |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [취약성 보고서](application_security/vulnerability_report/_index.md) 보기 |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [보안 대시보드](application_security/security_dashboard/_index.md) 보기     |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [보안 정책 프로젝트](application_security/policies/_index.md) 생성        |       |         |          |           ✓       |           |            |   ✓   |
| [보안 정책 프로젝트](application_security/policies/_index.md) 할당        |       |         |          |          ✓        |           |            |   ✓   |
| [Secrets Manager](../ci/secrets/secrets_manager/_index.md) 관리                |       |         |          |                  |           |            |   ✓   |

### 그룹 CI/CD {#group-cicd}

러너, 변수 및 보호 환경을 포함한 [CI/CD](../ci/_index.md) 기능에 대한 그룹 권한:

| 작업                                | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 인스턴스 러너 보기                  |   ✓   |    ✓    |     ✓    |        ✓         |     ✓     |     ✓      |   ✓   |
| 그룹 러너 보기                    |       |         |          |                  |           |     ✓      |   ✓   |
| 그룹 레벨 Kubernetes 클러스터 관리 |       |         |          |                  |           |     ✓      |   ✓   |
| 그룹 러너 관리                  |       |         |          |                  |           |            |   ✓   |
| 그룹 레벨 CI/CD 변수 관리    |       |         |          |                  |           |            |   ✓   |
| 그룹 보호 환경 관리   |       |         |          |                  |           |            |   ✓   |

### 그룹 규정 준수 {#group-compliance}

규정 준수 센터, 감사 이벤트, 규정 준수 프레임워크 및 라이선스를 포함한 [규정 준수](compliance/_index.md) 기능에 대한 그룹 권한.

| 작업                                                                                 | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| -------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| [감사 이벤트](compliance/audit_events.md) <sup>1</sup> 보기                           |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [종속성 목록](application_security/dependency_list/_index.md)에서 라이선스 보기     |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [규정 준수 센터](compliance/compliance_center/_index.md) 보기                       |       |         |          |        ✓         |           |            |   ✓   |
| [규정 준수 프레임워크](compliance/compliance_frameworks/_index.md) 관리             |       |         |          |        ✓         |           |            |   ✓   |
| [규정 준수 프레임워크](compliance/compliance_frameworks/_index.md)를 프로젝트에 할당 |       |         |          |        ✓         |           |            |   ✓   |
| [감사 스트림](compliance/audit_event_streaming.md) 관리                            |       |         |          |        ✓         |           |            |   ✓   |

**각주**:

1. 사용자는 개별 작업에만 따라 이벤트를 볼 수 있습니다. 자세한 내용은 [필수 조건](compliance/audit_events.md#prerequisites)을 참조합니다.

### 그룹 GitLab Duo {#group-gitlab-duo}

[GitLab Duo](gitlab_duo/_index.md)에 대한 그룹 권한:

| 작업                                                                                                     | 비회원 | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ---------------------------------------------------------------------------------------------------------- | :--------: | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| GitLab Duo 기능 사용 <sup>1</sup>                                                                       |            |   ✓   |     ✓   |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [GitLab Duo 기능 가용성](gitlab_duo/turn_on_off.md#for-a-group-or-subgroup) 구성             |            |       |         |          |                  |           |     ✓      |   ✓   |
| [GitLab Duo Self Hosted](../administration/gitlab_duo_self_hosted/configure_duo_features.md) 구성     |            |       |         |          |                  |           |            |   ✓   |
| [베타 및 실험 기능](gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) 활성화  |            |       |         |          |                  |           |            |   ✓   |
| [GitLab Duo 시트](../subscriptions/subscription-add-ons.md#purchase-additional-gitlab-duo-seats) 구매 |            |       |         |          |                  |           |            |   ✓   |

**각주**:

1. 사용자가 GitLab Duo Pro 또는 Enterprise를 가지고 있으면 [사용자는 해당 GitLab Duo 추가 기능에 액세스하기 위해 시트를 할당받아야](../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats) 합니다. 사용자가 GitLab Duo Core를 가지고 있으면 다른 요구사항은 없습니다.

### 그룹 패키지 및 레지스트리 {#group-packages-and-registries}

[패키지 및 컨테이너 레지스트리](packages/_index.md)에 대한 그룹 권한:

| 작업                                          | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ----------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 컨테이너 레지스트리 이미지 가져오기 <sup>1</sup>     |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 종속성 프록시로 컨테이너 이미지 가져오기 |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 컨테이너 레지스트리 이미지 삭제                |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 가상 레지스트리 구성                    |       |         |          |                  |           |     ✓      |   ✓   |
| 가상 레지스트리에서 아티팩트 가져오기        |   ✓   |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |

**각주**:

1. 게스트는 개별 작업에만 따라 이벤트를 볼 수 있습니다.

[패키지 레지스트리](packages/_index.md)에 대한 그룹 권한:

| 작업                                   | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ---------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 패키지 가져오기                            |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 패키지 게시                         |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 패키지 삭제                          |       |         |          |                  |           |     ✓      |   ✓   |
| 패키지 설정 관리                  |       |         |          |                  |           |            |   ✓   |
| 종속성 프록시 정리 정책 관리 |       |         |          |                  |           |            |   ✓   |
| 종속성 프록시 활성화                  |       |         |          |                  |           |            |   ✓   |
| 종속성 프록시 비활성화                 |       |         |          |                  |           |            |   ✓   |
| 그룹 종속성 프록시 제거         |       |         |          |                  |           |            |   ✓   |
| 패키지 요청 전달 활성화        |       |         |          |                  |           |            |   ✓   |
| 패키지 요청 전달 비활성화       |       |         |          |                  |           |            |   ✓   |

### 그룹 계획 {#group-planning}

| 작업                                                                              | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ----------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 에픽 보기                                                                           |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 에픽 [검색](search/_index.md) <sup>1</sup>                                       |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [에픽](group/epics/_index.md)에 이슈 추가 <sup>2</sup>                         |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [하위 에픽](work_items/child_items.md#work-with-multi-level-hierarchies) 추가 <sup>3</sup> |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 상위 에픽 추가 <sup>4</sup>                                                        |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 내부 메모 추가                                                                  |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 에픽 생성                                                                        |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 에픽 세부 정보 업데이트                                                                 |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [에픽 보드](group/epics/epic_boards.md) 관리                                    |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 에픽 삭제 <sup>5</sup>                                                           |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |

**각주**:

1. [에픽을 볼](group/epics/manage_epics.md#who-can-view-an-epic) 수 있는 권한이 있어야 합니다.
1. [에픽을 볼 수 있는](group/epics/manage_epics.md#who-can-view-an-epic) 권한이 있어야 하며 이슈를 편집할 수 있어야 합니다.
1. 상위 에픽과 하위 에픽을 [볼 수 있는](group/epics/manage_epics.md#who-can-view-an-epic) 권한이 있어야 합니다.
1. 상위 에픽을 [볼 수 있는](group/epics/manage_epics.md#who-can-view-an-epic) 권한이 있어야 합니다.
1. 플래너 또는 소유자 역할이 없는 사용자는 자신이 작성한 에픽만 삭제할 수 있습니다.

그룹 [위키](project/wiki/group.md) 권한:

| 작업                                              | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| --------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 그룹 위키 보기 <sup>1</sup>                        |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [검색](search/_index.md) 그룹 위키 <sup>2</sup> |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 그룹 위키 페이지 만들기                             |       |    ✓    |          |                  |     ✓     |     ✓      |   ✓   |
| 그룹 위키 페이지 편집                               |       |    ✓    |          |                  |     ✓     |     ✓      |   ✓   |
| 그룹 위키 페이지 삭제                             |       |    ✓    |          |                  |     ✓     |     ✓      |   ✓   |

**각주**:

1. 게스트: 또한 그룹이 공개 또는 내부인 경우 그룹을 볼 수 있는 모든 사용자가 그룹 위키 페이지도 볼 수 있습니다.
1. 게스트: 또한 그룹이 공개 또는 내부인 경우 그룹을 볼 수 있는 모든 사용자가 그룹 위키 페이지도 검색할 수 있습니다.

### 그룹 리포지토리 {#group-repositories}

머지 리퀘스트, 푸시 규칙 및 배포 토큰을 포함한 [리포지토리](project/repository/_index.md) 기능에 대한 그룹 권한입니다.

| 작업                                                                                 | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
|----------------------------------------------------------------------------------------|:-----:|:-------:|:--------:|:----------------:|:---------:|:----------:|:-----:|
| [배포 토큰](project/deploy_tokens/_index.md) 관리                                |       |         |          |                  |           |            |   ✓   |
| [머지 리퀘스트 설정](group/manage.md#group-merge-request-approval-settings) 관리 |       |         |          |                  |           |            |   ✓   |
| [푸시 규칙](project/repository/push_rules.md#group-push-rules) 관리         |       |         |          |                  |           |            |   ✓   |

### 그룹 사용자 관리 {#group-user-management}

사용자 관리를 위한 그룹 권한:

| 작업                          | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 구성원의 2FA 상태 보기      |       |         |          |                  |           |            |   ✓   |
| 2FA 상태로 구성원 필터링    |       |         |          |                  |           |            |   ✓   |
| 그룹 구성원 관리            |       |         |          |                  |           |            |   ✓   |
| 그룹 수준 사용자 지정 역할 관리 |       |         |          |                  |           |            |   ✓   |
| 그룹을 그룹에 공유(초대) |       |         |          |                  |           |            |   ✓   |

### 그룹 워크스페이스 {#group-workspaces}

워크스페이스에 대한 그룹 권한:

| 작업                                                    | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| --------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 그룹에 매핑된 워크스페이스 클러스터 에이전트 보기           |       |         |          |                  |           |     ✓      |   ✓   |
| 워크스페이스 클러스터 에이전트를 그룹에 매핑 또는 매핑 해제 |       |         |          |                  |           |            |   ✓   |

## 프로젝트 권한 {#project-permissions}

사용자의 역할은 프로젝트에 대한 권한을 결정합니다. 소유자 역할은 모든 권한을 제공하지만 다음의 경우에만 사용 가능합니다:

- 그룹 및 프로젝트 소유자의 경우.
- 관리자의 경우.

개인 [네임스페이스](namespace/_index.md) 소유자:

- 네임스페이스의 프로젝트에서 유지관리자 역할을 가진 것으로 표시되지만 소유자 역할을 가진 사용자와 동일한 권한을 가집니다.
- 네임스페이스의 새 프로젝트의 경우 소유자 역할을 가진 것으로 표시됩니다.

[보호된 브랜치 설정](project/repository/branches/protection_rules.md)을 구성할 때 역할을 선택하면 그 역할 이상의 모든 역할을 가진 사용자에게 액세스 권한을 부여합니다. 예를 들어 보호된 브랜치 설정에서 **유지관리자**를 선택하면 유지관리자 및 소유자 역할을 가진 사용자가 작업을 수행할 수 있습니다.

프로젝트 구성원을 관리하는 방법에 대한 자세한 내용은 [프로젝트의 구성원](project/members/_index.md)을 참조하세요.

다음 표에는 각 역할에 사용 가능한 프로젝트 권한이 나열되어 있습니다.

### 프로젝트 {#projects}

[프로젝트 기능](project/organize_work_with_projects.md)에 대한 프로젝트 권한:

| 작업                                                                                 | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| -------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 프로젝트 다운로드 <sup>1</sup>                                                          |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 댓글 남기기                                                                         |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 이미지의 댓글 위치 변경(모든 사용자가 게시) <sup>2</sup>                        |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [인사이트](project/insights/_index.md) 보기                                            |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [요구사항](project/requirements/_index.md) 보기                                    |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [시간 추적](project/time_tracking.md) 보고서 보기 <sup>1</sup>                    |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [스니펫](snippets.md) 보기                                                           |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [검색](search/_index.md) [스니펫](snippets.md) 및 댓글                        |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [프로젝트 트래픽 통계](../api/project_statistics.md) 보기                        |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [스니펫](snippets.md) 만들기                                                         |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [릴리스](project/releases/_index.md) 보기 <sup>3</sup>                               |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [릴리스](project/releases/_index.md) 관리 <sup>4</sup>                             |       |         |          |                  |           |     ✓      |   ✓   |
| [웹후크](project/integrations/webhooks.md) 구성                                 |       |         |          |                  |           |     ✓      |   ✓   |
| [프로젝트 액세스 토큰](project/settings/project_access_tokens.md) 관리 <sup>5</sup> |       |         |          |                  |           |     ✓      |   ✓   |
| [프로젝트 내보내기](project/settings/import_export.md)                                    |       |         |          |                  |           |     ✓      |   ✓   |
| 프로젝트 이름 바꾸기                                                                         |       |         |          |                  |           |     ✓      |   ✓   |
| 프로젝트 배지 편집                                                                    |       |         |          |                  |           |     ✓      |   ✓   |
| 프로젝트 설정 편집                                                                  |       |         |          |                  |           |     ✓      |   ✓   |
| [프로젝트 기능 가시성](public_access.md) 수준 변경 <sup>6</sup>              |       |         |          |                  |           |     ✓      |   ✓   |
| [프로젝트 통합](project/integrations/_index.md)에 대한 사용자 지정 설정 변경      |       |         |          |                  |           |     ✓      |   ✓   |
| 다른 사용자가 게시한 댓글 편집                                                    |       |         |          |                  |           |     ✓      |   ✓   |
| [배포 키](project/deploy_keys/_index.md) 추가                                       |       |         |          |                  |           |     ✓      |   ✓   |
| [프로젝트 운영](../operations/_index.md) 관리                                   |       |         |          |                  |           |     ✓      |   ✓   |
| [사용량 할당량](storage_usage_quotas.md) 페이지 보기                                      |       |         |          |                  |           |     ✓      |   ✓   |
| [스니펫](snippets.md) 전체 삭제                                                |       |         |          |                  |           |     ✓      |   ✓   |
| [스니펫](snippets.md) 전체 편집                                                  |       |         |          |                  |           |     ✓      |   ✓   |
| 프로젝트 아카이브                                                                        |       |         |          |                  |           |            |   ✓   |
| 프로젝트 가시성 수준 변경                                                        |       |         |          |                  |           |            |   ✓   |
| 프로젝트 삭제                                                                         |       |         |          |                  |           |            |   ✓   |
| 알림 이메일 비활성화                                                            |       |         |          |                  |           |            |   ✓   |
| 프로젝트 이전                                                                       |       |         |          |                  |           |            |   ✓   |

**각주**:

<!-- Disable ordered list rule <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix> -->
<!-- markdownlint-disable MD029 -->

1. GitLab Self-Managed에서 게스트 역할을 가진 사용자는 공개 및 내부 프로젝트에서만 이 작업을 수행할 수 있습니다(개인 프로젝트는 불가). [외부 사용자](../administration/external_users.md)는 프로젝트가 내부인 경우에도 명시적 액세스(최소 **리포터** 역할)가 필요합니다. GitLab.com의 게스트 역할을 가진 사용자는 공개 프로젝트에서만 이 작업을 수행할 수 있습니다. 내부 가시성을 사용할 수 없기 때문입니다.
2. [디자인 관리](project/issues/design_management.md) 디자인에 대한 댓글에만 적용됩니다.
3. 게스트 사용자는 자산을 다운로드하기 위해 GitLab [**릴리스**](project/releases/_index.md)에 액세스할 수 있지만 소스 코드를 다운로드하거나 [커밋 및 릴리스 증거와 같은 리포지토리 정보](project/releases/_index.md#view-a-release-and-download-assets)를 볼 수 없습니다.
4. [태그가 보호되면](project/protected_tags.md) 개발자와 유지관리자에게 부여된 액세스에 따라 달라집니다.
5. GitLab Self-Managed의 경우 프로젝트 액세스 토큰은 모든 티어에서 사용 가능합니다. GitLab.com의 경우 프로젝트 액세스 토큰은 Premium 및 Ultimate 티어에서 지원됩니다([시험 라이선스](https://about.gitlab.com/free-trial/) 제외).
6. 유지관리자 또는 소유자가 [프로젝트 가시성](public_access.md)이 비공개로 설정된 경우 프로젝트 기능 가시성 수준을 변경할 수 없습니다.

   <!-- markdownlint-enable MD029 -->

[GitLab Pages](project/pages/_index.md)에 대한 프로젝트 권한:

| 작업                                                                                 | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| -------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| [액세스 제어](project/pages/pages_access_control.md)로 보호된 GitLab Pages 보기 |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| GitLab Pages 관리                                                                    |       |         |          |                  |           |     ✓      |   ✓   |
| GitLab Pages 도메인 및 인증서 관리                                            |       |         |          |                  |           |     ✓      |   ✓   |
| GitLab Pages 제거                                                                    |       |         |          |                  |           |     ✓      |   ✓   |

### 프로젝트 분석 {#project-analytics}

값 흐름, 사용 추세, 제품 분석 및 인사이트를 포함한 [분석](analytics/_index.md) 기능에 대한 프로젝트 권한입니다.

| 작업                                                                                     | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ------------------------------------------------------------------------------------------ | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| [이슈 분석](group/issues_analytics/_index.md) 보기                                   |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [값 흐름 분석](group/value_stream_analytics/_index.md) 보기                      |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [CI/CD 분석](analytics/ci_cd_analytics.md) 보기                                       |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [코드 검토 분석](analytics/code_review_analytics.md) 보기                           |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [DORA 메트릭](analytics/ci_cd_analytics.md) 보기                                          |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [머지 리퀘스트 분석](analytics/merge_request_analytics.md) 보기                       |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [리포지토리 분석](analytics/repository_analytics.md) 보기                             |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [값 흐름 대시보드](analytics/value_streams_dashboard.md) 보기                       |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [GitLab Duo 및 SDLC 트렌드](analytics/duo_and_sdlc_trends.md) 보기                        |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |

### 프로젝트 애플리케이션 보안 {#project-application-security}

종속성 관리, 보안 분석기, 보안 정책 및 취약성 관리를 포함한 [애플리케이션 보안](application_security/secure_your_application.md) 기능에 대한 프로젝트 권한입니다.

| 작업                                                                                                                              | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ----------------------------------------------------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| [종속성 목록](application_security/dependency_list/_index.md) 보기                                                              |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [종속성 목록](application_security/dependency_list/_index.md)에서 라이선스 보기                                                  |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [보안 대시보드](application_security/security_dashboard/_index.md) 보기                                                        |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [취약성 보고서](application_security/vulnerability_report/_index.md) 보기                                                    |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [취약성 수동으로 만들기](application_security/vulnerability_report/_index.md#manually-add-a-vulnerability)                   |       |         |          |        ✓         |           |     ✓      |   ✓   |
| 취약성 조사로부터 [이슈](application_security/vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability) 만들기 |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [온디맨드 DAST 스캔](application_security/dast/on-demand_scan.md) 만들기                                                          |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [온디맨드 DAST 스캔](application_security/dast/on-demand_scan.md) 실행                                                             |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [개별 보안 정책](application_security/policies/_index.md) 만들기                                                      |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| [개별 보안 정책](application_security/policies/_index.md) 변경                                                      |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| [개별 보안 정책](application_security/policies/_index.md) 삭제                                                      |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| [CVE ID 요청](application_security/cve_id_request.md) 만들기                                                                     |       |         |          |                  |           |     ✓      |   ✓   |
| 취약성 상태 변경 <sup>1</sup>                                                                                            |       |         |          |        ✓         |           |     ✓      |   ✓   |
| [보안 정책 프로젝트](application_security/policies/_index.md) 생성                                                           |       |         |          |                  |           |            |   ✓   |
| [보안 정책 프로젝트](application_security/policies/_index.md) 할당                                                           |       |         |          |                  |           |            |   ✓   |
| [보안 구성](application_security/detect/security_configuration.md) 관리 <sup>2</sup>                               |       |         |          |        ✓         |           |     ✓      |   ✓   |
| [Secrets Manager](../ci/secrets/secrets_manager/_index.md) 관리                                                                   |       |         |          |                  |           |            |   ✓   |

**각주**:

1. 개발자 역할에서 GitLab 17.0의 `admin_vulnerability` 권한이 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/412693)되었습니다.
1. 보안 관리자는 UI(**보안 > 보안 구성**)를 통해서만 보안 구성을 관리할 수 있습니다.

### 프로젝트 CI/CD {#project-cicd}

[GitLab CI/CD](../ci/_index.md) 권한은 다음 설정으로 일부 역할에 대해 수정될 수 있습니다:

- [프로젝트 기반 파이프라인 가시성](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines): 공개로 설정하면 게스트 프로젝트 멤버에게 특정 CI/CD 기능에 대한 액세스 권한을 부여합니다.
- [파이프라인 가시성](../ci/pipelines/settings.md#change-pipeline-visibility-for-non-project-members-in-public-projects): **Everyone with Access**로 설정하면 비프로젝트 멤버에게 특정 CI/CD "보기" 기능에 대한 액세스 권한을 부여합니다.

프로젝트 소유자는 나열된 모든 작업을 수행할 수 있으며 파이프라인을 삭제할 수 있습니다:

| 작업                                                                                                      | 비회원 | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 |
| ----------------------------------------------------------------------------------------------------------- | :--------: | :---: | :-----: | :------: | :--------------: | :-------: | :--------: |
| 인스턴스 러너 보기                                                                                        |     ✓      |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |
| 기존 아티팩트 보기 <sup>1</sup>                                                                        |     ✓      |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |
| 작업 목록 보기 <sup>2</sup>                                                                              |     ✓      |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |
| 아티팩트 보기 <sup>3</sup>                                                                                 |     ✓      |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |
| 아티팩트 다운로드 <sup>3</sup>                                                                             |     ✓      |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |
| [환경](../ci/environments/_index.md) 보기 <sup>1</sup>                                              |     ✓      |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |
| 작업 로그 및 작업 세부 정보 페이지 보기 <sup>2</sup>                                                             |     ✓      |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |
| 파이프라인 및 파이프라인 세부 정보 페이지 보기 <sup>2</sup>                                                      |     ✓      |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |
| 머지 리퀘스트의 파이프라인 탭 보기 <sup>1</sup>                                                                       |     ✓      |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |
| [파이프라인의 취약점](application_security/detect/security_scanning_results.md) 보기 <sup>4</sup> |            |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |
| 보호 환경에 배포 작업 실행 <sup>5</sup>                                                 |            |       |         |    ✓     |                  |     ✓     |     ✓      |
| [Kubernetes 에이전트](clusters/agent/_index.md) 보기                                                      |            |       |         |          |                  |     ✓     |     ✓      |
| 프로젝트 [Secure Files](../api/secure_files.md) 보기                                                         |            |       |         |          |                  |     ✓     |     ✓      |
| 프로젝트 [Secure Files](../api/secure_files.md) 다운로드                                                     |            |       |         |          |                  |     ✓     |     ✓      |
| [디버그 로깅](../ci/variables/variables_troubleshooting.md#enable-debug-logging)을 사용하는 작업 보기          |            |       |         |          |                  |     ✓     |     ✓      |
| [환경](../ci/environments/_index.md) 생성                                                         |            |       |         |          |                  |     ✓     |     ✓      |
| [환경](../ci/environments/_index.md) 삭제                                                         |            |       |         |          |                  |     ✓     |     ✓      |
| [환경](../ci/environments/_index.md) 중지                                                           |            |       |         |          |                  |     ✓     |     ✓      |
| CI/CD 파이프라인 또는 작업 실행, 재실행 또는 재시도 <sup>14</sup>                                                    |            |       |         |          |        ✓         |     ✓     |     ✓      |
| 보호 브랜치에서 CI/CD 파이프라인 또는 작업 실행, 재실행 또는 재시도 <sup>6</sup>                              |            |       |         |          |                  |     ✓     |     ✓      |
| 작업 로그 또는 작업 아티팩트 삭제 <sup>7</sup>                                                               |            |       |         |          |                  |     ✓     |     ✓      |
| [검토 앱](../ci/review_apps/_index.md) 활성화                                                           |            |       |         |          |                  |     ✓     |     ✓      |
| 작업 취소 <sup>8</sup>                                                                                    |            |       |         |          |                  |     ✓     |     ✓      |
| [Terraform](infrastructure/_index.md) 상태 읽기                                                            |            |       |         |          |                  |     ✓     |     ✓      |
| [대화형 웹 터미널](../ci/interactive_web_terminal/_index.md) 실행                                   |            |       |         |          |                  |     ✓     |     ✓      |
| 파이프라인 편집기 사용                                                                                         |            |       |         |          |                  |     ✓     |     ✓      |
| 프로젝트 러너 보기 <sup>9</sup>                                                                           |            |       |         |          |        ✓         |           |     ✓      |
| 프로젝트 러너 관리 <sup>9</sup>                                                                         |            |       |         |          |                  |           |     ✓      |
| 프로젝트 러너 삭제 <sup>10</sup>                                                                        |            |       |         |          |                  |           |     ✓      |
| [Kubernetes 에이전트](clusters/agent/_index.md) 관리                                                    |            |       |         |          |                  |           |     ✓      |
| CI/CD 설정 관리                                                                                       |            |       |         |          |                  |           |     ✓      |
| 작업 트리거 관리                                                                                         |            |       |         |          |                  |           |     ✓      |
| 프로젝트 CI/CD 변수 관리                                                                              |            |       |         |          |                  |           |     ✓      |
| 프로젝트 보호 환경 관리                                                                       |            |       |         |          |                  |           |     ✓      |
| 프로젝트 [Secure Files](../api/secure_files.md) 관리                                                       |            |       |         |          |                  |           |     ✓      |
| [Terraform](infrastructure/_index.md) 상태 관리                                                          |            |       |         |          |                  |           |     ✓      |
| 프로젝트에 프로젝트 러너 추가 <sup>11</sup>                                                                |            |       |         |          |                  |           |     ✓      |
| 러너 캐시 수동으로 지우기                                                                                |            |       |         |          |                  |           |     ✓      |
| 프로젝트에서 인스턴스 러너 활성화                                                                          |            |       |         |          |                  |           |     ✓      |
| 파이프라인 일정 생성 <sup>12</sup>                                                                     |            |       |         |          |                  |     ✓     |     ✓      |
| 자신의 파이프라인 일정 편집 <sup>12</sup>                                                                   |            |       |         |          |                  |     ✓     |     ✓      |
| 자신의 파이프라인 일정 삭제                                                                               |            |       |         |          |                  |     ✓     |     ✓      |
| 파이프라인 일정 수동으로 실행 <sup>13</sup>                                                               |            |       |         |          |                  |     ✓     |     ✓      |
| 파이프라인 일정 소유권 가져오기                                                                        |            |       |         |          |                  |           |     ✓      |
| 다른 사용자의 파이프라인 일정 삭제                                                                           |            |       |         |          |                  |           |     ✓      |

**각주**:

<!-- Disable ordered list rule <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix> -->
<!-- markdownlint-disable MD029 -->

1. 비회원 및 게스트: 프로젝트가 공개인 경우에만 해당합니다.
2. 비회원: 프로젝트가 공개이고 **프로젝트 기반 파이프라인 공개범위**가 활성화된 경우에만 해당합니다.
   <br>게스트: **프로젝트 기반 파이프라인 공개범위**가 활성화된 경우에만 해당합니다.
3. 비회원: 프로젝트가 공개이고, **프로젝트 기반 파이프라인 공개범위**가 활성화되어 있으며, [`artifacts:public: false`](../ci/yaml/_index.md#artifactspublic)이(가) 작업에 설정되지 않은 경우에만 해당합니다.
   <br>게스트: **프로젝트 기반 파이프라인 공개범위**가 활성화되어 있고 `artifacts:public: false`이(가) 작업에 설정되지 않은 경우에만 해당합니다.<br>리포터: `artifacts:public: false`이(가) 작업에 설정되지 않은 경우에만 해당합니다.<br>`artifacts:public` 설정은 GitLab UI 및 API 접근에만 영향을 줍니다. CI/CD 작업 토큰은 여전히 러너 API로 작업 아티팩트에 접근할 수 있습니다.
4. 게스트: **프로젝트 기반 파이프라인 공개범위**가 활성화된 경우에만 해당합니다.
5. 리포터: 사용자가 [보호 환경에 접근할 수 있는 그룹의 일부](../ci/environments/protected_environments.md#deployment-only-access-to-protected-environments)인 경우에만 해당합니다.
   <br>개발자 및 유지보수자: 사용자가 [보호 환경에 배포할 수 있도록 허용](../ci/environments/protected_environments.md#protecting-environments)된 경우에만 해당합니다.
6. 개발자 및 유지보수자: 사용자가 [보호 브랜치로 병합하거나 푸시할 수 있도록 허용](../ci/pipelines/_index.md#pipeline-security-on-protected-branches)된 경우에만 해당합니다.
7. 개발자: 작업이 사용자에 의해 트리거되었고 보호되지 않은 브랜치에서 실행되는 경우에만 해당합니다.
8. 취소 권한은 [파이프라인 설정에서 제한](../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs)할 수 있습니다.
9. 유지 관리자: 러너와 연결된 프로젝트에 대한 유지보수자 역할이 있어야 합니다.
10. 유지 관리자: [소유자 프로젝트](../ci/runners/runners_scope.md#project-runner-ownership)(러너와 연결된 첫 번째 프로젝트)에 대한 유지보수자 역할이 있어야 합니다.
11. 유지 관리자: 추가되는 프로젝트 및 러너와 이미 연결된 프로젝트에 대한 유지보수자 역할이 있어야 합니다.
12. 개발자: 사용자가 병합 권한을 가진 브랜치에만 해당합니다. 보호 브랜치의 경우 대상 브랜치에 대한 병합 권한이 있어야 합니다. 보호 태그의 경우 사용자가 보호 태그를 생성할 수 있어야 합니다. 이 권한 요구 사항은 파이프라인 일정을 생성하거나 편집할 때 적용되며, 브랜치 보호 규칙이 시간이 지남에 따라 변경될 수 있으므로 동적으로 확인됩니다.
13. 수동으로 실행할 때 파이프라인은 파이프라인 일정 소유자의 권한 대신 트리거 사용자의 권한으로 실행됩니다.
14. 보안 관리자는 DAST 온디맨드 스캔 파이프라인만 실행할 수 있습니다.

<!-- markdownlint-enable MD029 -->

이 테이블은 특정 역할에 의해 트리거된 작업에 대해 부여된 권한을 보여줍니다.

프로젝트 소유자는 나열된 모든 작업을 수행할 수 있지만, 누구도 소스 및 LFS를 함께 푸시할 수 없습니다. 게스트 사용자 및 리포터 역할의 구성원은 이러한 작업을 수행할 수 없습니다.

| 작업                                                    | 개발자 | 유지 관리자 |
| --------------------------------------------------------- | :-------: | :--------: |
| 현재 프로젝트에서 소스 및 LFS 복제                 |     ✓     |     ✓      |
| 공개 프로젝트에서 소스 및 LFS 복제                 |     ✓     |     ✓      |
| 내부 프로젝트에서 소스 및 LFS 복제 <sup>1</sup>  |     ✓     |     ✓      |
| 비공개 프로젝트에서 소스 및 LFS 복제 <sup>2</sup>   |     ✓     |     ✓      |
| 현재 프로젝트에서 컨테이너 이미지 풀                |     ✓     |     ✓      |
| 공개 프로젝트에서 컨테이너 이미지 풀                |     ✓     |     ✓      |
| 내부 프로젝트에서 컨테이너 이미지 풀 <sup>1</sup> |     ✓     |     ✓      |
| 비공개 프로젝트에서 컨테이너 이미지 풀 <sup>2</sup>  |     ✓     |     ✓      |
| 현재 프로젝트로 컨테이너 이미지 푸시 <sup>3</sup>     |     ✓     |     ✓      |

**각주**:

1. 개발자 및 유지보수자: 트리거 사용자가 외부 사용자가 아닌 경우에만 해당합니다.
1. 트리거 사용자가 프로젝트의 구성원인 경우에만 해당합니다. [`if-not-present` 풀 정책을 사용하는 비공개 Docker 이미지의 사용](https://docs.gitlab.com/runner/security/#usage-of-private-docker-images-with-if-not-present-pull-policy)도 참조하세요.
1. 다른 프로젝트로 컨테이너 이미지를 푸시할 수 없습니다.

### 프로젝트 준수 {#project-compliance}

준수 센터, 감사 이벤트, 준수 프레임워크 및 라이선스를 포함한 [준수](compliance/_index.md) 기능에 대한 프로젝트 권한입니다.

| 작업                                                                                                          | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| --------------------------------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| [머지 리퀘스트에서 허용되고 거부된 라이선스](compliance/license_scanning_of_cyclonedx_files/_index.md) 보기 <sup>1</sup> |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [감사 이벤트](compliance/audit_events.md) 보기 <sup>2</sup>                                                    |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [종속성 목록](application_security/dependency_list/_index.md)에서 라이선스 보기                              |       |         |          |        ✓         |     ✓     |     ✓      |   ✓   |
| [규정 준수 센터](compliance/compliance_center/_index.md) 보기                                                |       |         |          |        ✓         |           |            |   ✓   |
| [감사 스트림](compliance/audit_event_streaming.md) 관리                                                     |       |         |          |                  |           |            |   ✓   |

**각주**:

1. GitLab Self-Managed에서 게스트 역할을 가진 사용자는 공개 및 내부 프로젝트에서만 이 작업을 수행할 수 있습니다(개인 프로젝트는 불가). [외부 사용자](../administration/external_users.md)는 프로젝트가 내부인 경우에도 리포터, 개발자, 유지보수자 또는 소유자 역할을 가져야 합니다. GitLab.com의 게스트 역할을 가진 사용자는 내부 공개범위를 사용할 수 없으므로 공개 프로젝트에서만 이 작업을 수행할 수 있습니다.
1. 사용자는 자신의 개별 작업을 기반으로만 이벤트를 볼 수 있습니다. 자세한 내용은 [필수 조건](compliance/audit_events.md#prerequisites)을 참조합니다.

### 프로젝트 GitLab Duo {#project-gitlab-duo}

[GitLab Duo](gitlab_duo/_index.md)에 대한 프로젝트 권한입니다:

| 작업                                                                               | 비회원 | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ------------------------------------------------------------------------------------ | :--------: | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| GitLab Duo 기능 사용 <sup>1</sup>                                                 |            |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [GitLab Duo 기능 가용성](gitlab_duo/turn_on_off.md#for-a-project) 구성 |            |       |         |          |                  |           |     ✓      |   ✓   |

**각주**:

1. Code Suggestions은 [GitLab Duo 추가 기능에 접근하기 위해 사용자가 할당된 사용자가 필요](../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats)합니다.

### 프로젝트 머지 리퀘스트 {#project-merge-requests}

[머지 리퀘스트](project/merge_requests/_index.md)에 대한 프로젝트 권한입니다:

| 작업                                                                                    | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ----------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| [머지 리퀘스트 보기](project/merge_requests/_index.md#view-merge-requests) <sup>1</sup> |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [머지 리퀘스트 및 댓글 검색](search/_index.md) <sup>1</sup><sup>2</sup>           |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [머지 리퀘스트 승인](project/merge_requests/approvals/_index.md) <sup>3</sup>         |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 내부 노트 추가                                                                         |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 댓글 달기 및 제안 추가                                                               |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [스니펫](snippets.md) 만들기                                                            |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [머지 리퀘스트](project/merge_requests/creating_merge_requests.md) 생성 <sup>4</sup>    |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 머지 리퀘스트 세부 정보 업데이트 <sup>5</sup>                                                 |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| [머지 리퀘스트 설정](project/merge_requests/approvals/settings.md) 관리             |       |         |          |                  |           |     ✓      |   ✓   |
| [머지 리퀘스트 승인 규칙](project/merge_requests/approvals/rules.md) 관리          |       |         |          |                  |           |     ✓      |   ✓   |
| 머지 리퀘스트 삭제                                                                      |       |         |          |                  |           |            |   ✓   |

**각주**:

1. GitLab Self-Managed에서 게스트 역할을 가진 사용자는 공개 및 내부 프로젝트에서만 이 작업을 수행할 수 있습니다(개인 프로젝트는 불가). [외부 사용자](../administration/external_users.md)는 프로젝트가 내부인 경우에도 명시적 액세스(최소 **리포터** 역할)가 필요합니다. GitLab.com의 게스트 역할을 가진 사용자는 공개 프로젝트에서만 이 작업을 수행할 수 있습니다. 내부 가시성을 사용할 수 없기 때문입니다.
1. 플래너 역할을 가진 사용자는 머지 리퀘스트 및 머지 리퀘스트의 댓글에 대한 고급 검색을 사용할 수 없습니다. 자세한 내용은 [에픽 &17674](https://gitlab.com/groups/gitlab-org/-/work_items/17674)를 참조하세요.
1. 승인은 플래너 및 리포터 역할에서만 [프로젝트에 대해 활성화](project/merge_requests/approvals/rules.md#enable-approval-permissions-for-additional-users)된 경우 사용 가능합니다.
1. 외부 구성원의 기여를 수락하는 프로젝트에서 사용자는 자신의 머지 리퀘스트를 생성, 편집 및 닫을 수 있습니다. **비공개** 프로젝트의 경우 이러한 사용자가 [비공개 프로젝트를 복제할 수 없으므로](public_access.md#private-projects-and-groups) 게스트 역할은 제외됩니다. **internal** 프로젝트의 경우 [내부 프로젝트를 복제할 수 있으므로](public_access.md#internal-projects-and-groups) 프로젝트에 대한 읽기 전용 접근이 있는 사용자가 포함됩니다.
1. 외부 구성원의 기여를 수락하는 프로젝트에서 사용자는 자신의 머지 리퀘스트를 생성, 편집 및 닫을 수 있습니다. 할당자, 검토자, 레이블 및 마일스톤과 같은 일부 필드는 편집할 수 없습니다.

### 프로젝트 모델 레지스트리 및 실험 {#project-model-registry-and-experiments}

[모델 레지스트리](project/ml/model_registry/_index.md) 및 [모델 실험](project/ml/experiment_tracking/_index.md)에 대한 프로젝트 권한입니다.

| 작업                                                                          | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| [모델 및 버전](project/ml/model_registry/_index.md) 보기 <sup>1</sup>    |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [모델 실험](project/ml/experiment_tracking/_index.md) 보기 <sup>2</sup> |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 모델, 버전 및 아티팩트 생성 <sup>3</sup>                             |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 모델, 버전 및 아티팩트 편집                                            |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 모델, 버전 및 아티팩트 삭제                                          |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 실험 및 후보 생성                                               |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 실험 및 후보 편집                                                 |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 실험 및 후보 삭제                                               |       |         |          |                  |     ✓     |     ✓      |   ✓   |

**각주**:

1. 비회원은 **Everyone with access** 공개범위의 공개 프로젝트에서만 모델 및 버전을 볼 수 있습니다. 비회원은 로그인한 경우에도 내부 프로젝트를 볼 수 없습니다.
1. 비회원은 **Everyone with access** 공개범위의 공개 프로젝트에서만 모델 실험을 볼 수 있습니다. 비회원은 로그인한 경우에도 내부 프로젝트를 볼 수 없습니다.
1. 패키지 레지스트리 API를 사용하여 아티팩트를 업로드하고 다운로드할 수 있으며, 이는 다른 권한 세트를 사용합니다.

### 프로젝트 모니터링 {#project-monitoring}

[오류 추적](../operations/error_tracking.md) 및 [인시던트 관리](../operations/incident_management/_index.md)를 포함한 모니터링에 대한 프로젝트 권한입니다:

| 작업                                                                                                              | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ------------------------------------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| [인시던트](../operations/incident_management/incidents.md) 보기                                                  |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [인시던트 관리](../operations/incident_management/_index.md) 경고 할당                                  |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [Incident Management](../operations/incident_management/_index.md)의 온콜 로테이션 참여              |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [경고](../operations/incident_management/alerts.md) 보기                                                          |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [오류 추적](../operations/error_tracking.md) 목록 보기                                                         |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [에스컬레이션 정책](../operations/incident_management/escalation_policies.md) 보기                                |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [온콜 일정](../operations/incident_management/oncall_schedules.md) 보기                                     |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [인시던트](../operations/incident_management/incidents.md) 생성                                                   |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [경고 상태](../operations/incident_management/alerts.md#change-an-alerts-status) 변경                          |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [인시던트 심각도](../operations/incident_management/manage_incidents.md#change-severity) 변경                   |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [인시던트 에스컬레이션 상태](../operations/incident_management/manage_incidents.md#change-status) 변경            |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| [인시던트 에스컬레이션 정책](../operations/incident_management/manage_incidents.md#change-escalation-policy) 변경 |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| [오류 추적](../operations/error_tracking.md) 관리                                                            |       |         |          |                  |           |     ✓      |   ✓   |
| [에스컬레이션 정책](../operations/incident_management/escalation_policies.md) 관리                              |       |         |          |                  |           |     ✓      |   ✓   |
| [온콜 일정](../operations/incident_management/oncall_schedules.md) 관리                                   |       |         |          |                  |           |     ✓      |   ✓   |

### 프로젝트 패키지 및 레지스트리 {#project-packages-and-registries}

[컨테이너 레지스트리](packages/_index.md)에 대한 프로젝트 권한입니다:

| 작업                                                                                           | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ------------------------------------------------------------------------------------------------ | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 컨테이너 레지스트리 이미지 가져오기 <sup>1</sup>                                                      |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 컨테이너 레지스트리 이미지 푸시                                                                   |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 컨테이너 레지스트리 이미지 삭제                                                                 |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 정리 정책 관리                                                                          |       |         |          |                  |           |     ✓      |   ✓   |
| [태그 보호](packages/container_registry/protected_container_tags.md) 규칙 생성           |       |         |          |                  |           |     ✓      |   ✓   |
| [변경 불가능한 태그 보호](packages/container_registry/immutable_container_tags.md) 규칙 생성 |       |         |          |                  |           |            |   ✓   |

**각주**:

1. [컨테이너 레지스트리 가시성 권한](packages/container_registry/_index.md#container-registry-visibility-permissions)에 따라 컨테이너 레지스트리를 보고 이미지를 가져오는 것이 제어됩니다. 게스트 역할은 비공개 프로젝트에서 보기 또는 가져오기 권한이 없습니다.

[패키지 레지스트리](packages/_index.md) 프로젝트 권한:

| 작업                                  | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| --------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 패키지 가져오기 <sup>1</sup>              |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 패키지 게시                        |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 패키지 삭제                         |       |         |          |                  |           |     ✓      |   ✓   |
| 패키지와 연결된 파일 삭제  |       |         |          |                  |           |     ✓      |   ✓   |

**각주**:

1. GitLab Self-Managed에서 게스트 역할을 가진 사용자는 공개 및 내부 프로젝트에서만 이 작업을 수행할 수 있습니다(개인 프로젝트는 불가). [외부 사용자](../administration/external_users.md)는 프로젝트가 내부인 경우에도 명시적 액세스(최소 **리포터** 역할)가 필요합니다. GitLab.com의 게스트 역할을 가진 사용자는 공개 프로젝트에서만 이 작업을 수행할 수 있습니다. 내부 가시성을 사용할 수 없기 때문입니다.

### 프로젝트 계획 {#project-planning}

[이슈](project/issues/_index.md) 프로젝트 권한:

| 작업                                                                            | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| --------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 이슈 보기                                                                       |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [이슈](search/_index.md) 및 댓글 검색                                    |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 이슈 생성                                                                     |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [기밀 이슈](project/issues/confidential_issues.md) 보기                 |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [기밀 이슈](search/_index.md) 및 댓글 검색 <sup>6</sup>          |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 메타데이터, 항목 잠금 및 스레드 해결 포함 이슈 편집 <sup>1</sup> |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 내부 메모 추가                                                                |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 이슈 닫기 및 다시 열기 <sup>2</sup>                                              |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [디자인 관리](project/issues/design_management.md) 파일 관리             |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [이슈 보드](project/issue_board.md) 관리                                     |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [마일스톤](project/milestones/_index.md) 관리                                 |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [마일스톤](search/_index.md) 검색 <sup>6</sup>                                |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [요구 사항](project/requirements/_index.md) 보관 또는 다시 열기 <sup>3</sup>     |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [요구 사항](project/requirements/_index.md) 생성 또는 편집 <sup>4</sup>        |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [요구 사항](project/requirements/_index.md) 가져오기 또는 내보내기                   |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [테스트 케이스](../ci/test_cases/_index.md) 보관                                  |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [테스트 케이스](../ci/test_cases/_index.md) 생성                                   |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [테스트 케이스](../ci/test_cases/_index.md) 이동                                     |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [테스트 케이스](../ci/test_cases/_index.md) 다시 열기                                   |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| CSV 파일에서 [이슈](project/issues/csv_import.md) 가져오기                     |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [이슈](project/issues/csv_export.md)를 CSV 파일로 내보내기                       |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 이슈 삭제 <sup>5</sup>                                                        |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [기능 플래그](../operations/feature_flags.md) 관리                            |       |         |          |                  |     ✓     |     ✓      |   ✓   |

**각주**:

1. 메타데이터에는 레이블, 담당자, 마일스톤, 에픽, 가중치, 기밀성, 시간 추적 등이 포함됩니다. 게스트 사용자는 이슈 생성 시에만 메타데이터를 설정할 수 있습니다. 기존 이슈의 메타데이터를 변경할 수 없습니다. 게스트 사용자는 자신이 작성했거나 할당된 이슈의 제목과 설명을 수정할 수 있습니다.
1. 게스트 사용자는 자신이 작성했거나 할당된 이슈를 닫고 다시 열 수 있습니다.
1. 게스트 사용자는 자신이 작성했거나 할당된 이슈를 보관하고 다시 열 수 있습니다.
1. 게스트 사용자는 자신이 작성했거나 할당된 제목과 설명을 수정할 수 있습니다.
1. 플래너 또는 소유자 역할이 없는 사용자는 자신이 작성한 이슈만 삭제할 수 있습니다.
1. 플래너 역할을 가진 사용자는 기밀 이슈의 마일스톤 또는 댓글에 대해 고급 검색을 사용할 수 없습니다. 자세한 내용은 [에픽 17674](https://gitlab.com/groups/gitlab-org/-/work_items/17674)를 참조하세요.

[작업](tasks.md) 프로젝트 권한:

| 작업                                                                           | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| -------------------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 작업 보기                                                                       |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [작업](search/_index.md) 검색                                                 |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 작업 생성                                                                     |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 메타데이터, 항목 잠금 및 스레드 해결 포함 작업 편집 <sup>1</sup> |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 연결된 항목 추가                                                                |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 다른 항목 유형으로 변환                                                     |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 이슈에서 제거                                                                |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 내부 노트 추가                                                                |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 작업 삭제 <sup>2</sup>                                                        |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |

**각주**:

1. 게스트 사용자는 자신이 작성했거나 할당된 제목과 설명을 수정할 수 있습니다.
1. 플래너 또는 소유자 역할이 없는 사용자는 자신이 작성한 작업만 삭제할 수 있습니다.

[OKR](okrs.md) 프로젝트 권한:

| 작업                                                             | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ------------------------------------------------------------------ | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| OKR 보기                                                          |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [OKR](search/_index.md) 검색                                    |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| OKR 생성                                                        |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 메타데이터, 항목 잠금 및 스레드 해결 포함 OKR 편집 |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 하위 OKR 추가                                                    |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 연결된 항목 추가                                                  |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 다른 항목 유형으로 변환                                       |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| OKR 편집                                                          |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| OKR의 기밀성 변경                                      |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 내부 노트 추가                                                  |       |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |

[위키](project/wiki/_index.md) 프로젝트 권한:

| 작업                           | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| -------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 위키 보기                        |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [위키](search/_index.md) 검색 |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 위키 페이지 생성                |       |    ✓    |          |                  |     ✓     |     ✓      |   ✓   |
| 위키 페이지 편집                  |       |    ✓    |          |                  |     ✓     |     ✓      |   ✓   |
| 위키 페이지 삭제                |       |    ✓    |          |                  |     ✓     |     ✓      |   ✓   |

### 프로젝트 리포지토리 {#project-repositories}

소스 코드, 브랜치, 푸시 규칙 등을 포함한 [리포지토리](project/repository/_index.md) 기능 프로젝트 권한:

| 작업                                                                | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| --------------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 프로젝트 코드 보기 <sup>1</sup>                                        |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [프로젝트 코드](search/_index.md) 검색 <sup>1</sup> <sup>2</sup>                  |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| [커밋](search/_index.md) 및 댓글 검색 <sup>1</sup> <sup>2</sup>          |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 프로젝트 코드 가져오기 <sup>3</sup>                                        |   ✓   |    ✓    |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 커밋 상태 보기                                                    |       |         |    ✓     |        ✓         |     ✓     |     ✓      |   ✓   |
| 커밋 상태 생성 <sup>4</sup>                                     |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 커밋 상태 업데이트 <sup>4</sup>                                     |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| [Git 태그](project/repository/tags/_index.md) 만들기                  |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| [Git 태그](project/repository/tags/_index.md) 삭제                  |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 새로운 [브랜치](project/repository/branches/_index.md) 만들기          |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 보호되지 않은 브랜치에 푸시                                        |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 보호되지 않은 브랜치에 강제 푸시                                  |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| 보호되지 않은 브랜치 삭제                                         |       |         |          |                  |     ✓     |     ✓      |   ✓   |
| [보호된 브랜치](project/repository/branches/protected.md) 관리 |       |         |          |                  |           |     ✓      |   ✓   |
| 보호된 브랜치에 푸시 <sup>4</sup>                               |       |         |          |                  |           |     ✓      |   ✓   |
| 보호된 브랜치 삭제                                             |       |         |          |                  |           |     ✓      |   ✓   |
| [보호된 태그](project/protected_tags.md) 관리                    |       |         |          |                  |           |     ✓      |   ✓   |
| [푸시 규칙](project/repository/push_rules.md) 관리                 |       |         |          |                  |           |     ✓      |   ✓   |
| 포크 관계 제거                                              |       |         |          |                  |           |            |   ✓   |
| 보호된 브랜치에 강제 푸시 <sup>5</sup>                         |       |         |          |                  |           |            |       |

**각주**:

<!-- Disable ordered list rule <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix> -->
<!-- markdownlint-disable MD029 -->

1. GitLab Self-Managed에서 게스트 역할을 가진 사용자는 공개 및 내부 프로젝트에서만 이 작업을 수행할 수 있습니다(개인 프로젝트는 불가). [외부 사용자](../administration/external_users.md)는 프로젝트가 내부인 경우에도 최소 **플래너** 역할의 명시적 액세스 권한이 필요합니다. GitLab.com의 게스트 역할을 가진 사용자는 공개 프로젝트에서만 이 작업을 수행할 수 있습니다. 내부 가시성을 사용할 수 없기 때문입니다. GitLab 15.9 이상에서 게스트 역할 및 Ultimate 라이선스를 가진 사용자는 관리자(GitLab Self-Managed 또는 GitLab Dedicated) 또는 그룹 소유자(GitLab.com)가 이러한 사용자에게 권한을 부여한 경우 개인 리포지토리 콘텐츠를 볼 수 있습니다. 관리자 또는 그룹 소유자는 [사용자 지정 역할](custom_roles/_index.md)을 API 또는 UI를 통해 만들 수 있으며 해당 역할을 사용자에게 할당할 수 있습니다. GitLab 18.7 이상에서 플래너 역할을 가진 사용자는 개인 리포지토리 콘텐츠를 볼 수 있습니다.
1. 플래너 역할을 가진 사용자는 개인 프로젝트에서 정확한 코드 검색 또는 코드, 커밋, 커밋 주석의 고급 검색을 사용할 수 없습니다. 자세한 내용은 [에픽 &17674](https://gitlab.com/groups/gitlab-org/-/work_items/17674)를 참조하세요.
1. [브랜치가 보호된](project/repository/branches/protected.md) 경우 이는 개발자 및 유지 관리자에게 부여된 액세스에 따라 달라집니다.
1. GitLab Self-Managed에서 게스트 역할을 가진 사용자는 공개 및 내부 프로젝트에서만 이 작업을 수행할 수 있습니다(개인 프로젝트는 불가). [외부 사용자](../administration/external_users.md)는 프로젝트가 내부인 경우에도 명시적 액세스(최소 **리포터** 역할)가 필요합니다. GitLab.com의 게스트 역할을 가진 사용자는 공개 프로젝트에서만 이 작업을 수행할 수 있습니다. 내부 가시성을 사용할 수 없기 때문입니다. GitLab 15.9 이상에서 게스트 역할 및 Ultimate 라이선스를 가진 사용자는 관리자(GitLab Self-Managed 또는 GitLab Dedicated) 또는 그룹 소유자(GitLab.com)가 이러한 사용자에게 권한을 부여한 경우 개인 리포지토리 콘텐츠를 볼 수 있습니다. 관리자 또는 그룹 소유자는 [사용자 지정 역할](custom_roles/_index.md)을 API 또는 UI를 통해 만들 수 있으며 해당 역할을 사용자에게 할당할 수 있습니다.
1. 게스트, 리포터, 개발자, 유지 관리자 또는 소유자는 허용되지 않습니다. [보호된 브랜치](project/repository/branches/protected.md#allow-force-push)를 참조하세요.

<!-- markdownlint-enable MD029 -->

### 프로젝트 사용자 관리 {#project-user-management}

[사용자 관리](project/members/_index.md)를 위한 프로젝트 권한입니다.

| 작업                                                           | 게스트 | 플래너 | 리포터 | 보안 관리자 | 개발자 | 유지 관리자 | 소유자 |
| ---------------------------------------------------------------- | :---: | :-----: | :------: | :--------------: | :-------: | :--------: | :---: |
| 구성원의 2FA 상태 보기                                       |       |         |          |                  |           |     ✓      |   ✓   |
| [프로젝트 멤버](project/members/_index.md) 관리 <sup>1</sup> |       |         |          |                  |           |     ✓      |   ✓   |
| 그룹과 프로젝트 공유(초대) <sup>2</sup>                 |       |         |          |                  |           |            |   ✓   |

**각주**:

1. 유지 관리자는 소유자를 만들거나, 강등하거나, 제거할 수 없으며 사용자를 소유자 역할로 승격할 수 없습니다. 또한 소유자 역할 액세스 요청을 승인할 수 없습니다.
1. [공유 그룹 잠금](project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups)이 활성화되면 프로젝트를 다른 그룹과 공유할 수 없습니다. 그룹과 그룹 공유는 영향을 받지 않습니다.

## 하위 그룹 권한 {#subgroup-permissions}

하위 그룹에 멤버를 추가하면 상위 그룹에서 멤버십 및 권한 수준을 상속합니다. 이 모델을 사용하면 부모 중 하나의 멤버십이 있는 경우 중첩된 그룹에 액세스할 수 있습니다.

자세한 내용은 [하위 그룹 멤버십](group/subgroups/_index.md#subgroup-membership)을 참조하세요.

## 최소 액세스 권한을 가진 사용자 {#users-with-minimal-access}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 최소 액세스 역할을 가진 사용자 초대 지원 [GitLab 15.9에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106438).
- 최소 액세스 사용자 [GitLab 18.9에서 청구 대상이 아닌 사용자로 변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216727).
- GitLab 18.11에서 최소 액세스 역할을 가진 사용자에 대한 [2단계 인증 요구 사항 적용](https://gitlab.com/gitlab-org/gitlab/-/work_items/534094).

{{< /history >}}

최소 액세스 역할을 가진 사용자는 다음을 수행하지 않습니다:

- 해당 최상위 그룹의 프로젝트 및 하위 그룹에 자동으로 액세스합니다. 소유자는 이러한 사용자를 특정 하위 그룹 및 프로젝트에 명시적으로 추가해야 합니다.
- 사용자가 인스턴스의 다른 곳이나 GitLab.com 네임스페이스에 다른 역할이 없는 경우 라이선스가 부여된 사용자로 계산되지 않습니다.

최소 액세스 역할을 가진 사용자에게 모든 프로젝트 또는 하위 그룹에서 [청구 대상 역할](../subscriptions/manage_seats.md#billable-users)을 부여한 경우 최상위 역할을 기반으로 라이선스 사용자를 사용합니다.

최소 액세스 역할을 [GitLab.com 그룹에 대한 SAML SSO](group/saml_sso/_index.md)와 함께 사용하여 그룹 계층의 그룹 및 프로젝트에 대한 액세스를 제어할 수 있습니다. SSO를 통해 최상위 그룹에 자동으로 추가되는 멤버의 기본 역할을 최소 액세스로 설정할 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **SAML SSO**를 선택합니다.
1. **멤버십 역할 기본값** 드롭다운 목록에서 **최소한의 액세스**를 선택합니다.
1. **변경사항 저장**을 선택합니다.

### 최소 액세스 사용자가 404 오류를 수신합니다 {#minimal-access-users-receive-404-errors}

[미해결 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/267996)로 인해 최소 액세스 역할을 가진 사용자가 다음을 수행할 때:

- 표준 웹 인증으로 로그인하면 부모 그룹에 액세스할 때 `404` 오류가 발생합니다.
- 그룹 SSO로 로그인하면 부모 그룹 페이지로 리디렉션되기 때문에 즉시 `404` 오류가 발생합니다.

이 문제를 해결하려면 이러한 사용자에게 부모 그룹의 모든 프로젝트 또는 하위 그룹에 대한 게스트, 플래너, 리포터, 보안 관리자, 개발자, 유지 관리자 또는 소유자 역할을 부여합니다. 게스트 사용자는 Premium 티어에서는 라이선스 사용자를 사용하지만 Ultimate 티어에서는 사용하지 않습니다.

## 관련 항목 {#related-topics}

- [리포지토리 보호](project/repository/protect.md)
- [사용자 지정 역할](custom_roles/_index.md)
- [멤버](project/members/_index.md)
- [보호된 브랜치](project/repository/branches/protected.md)에서 권한 사용자 지정
- [LDAP 사용자 권한](group/access_and_permissions.md#manage-group-memberships-with-ldap)
- [값 스트림 분석 권한](group/value_stream_analytics/_index.md#access-permissions)
- [프로젝트 별칭](project/working_with_projects.md#project-aliases)
- [감사자 사용자](../administration/auditor_users.md)
- [기밀 이슈](project/issues/confidential_issues.md)
- [컨테이너 레지스트리 권한](packages/container_registry/_index.md#container-registry-visibility-permissions)
- [릴리스 권한](project/releases/_index.md#release-permissions)
- [읽기 전용 네임스페이스](read_only_namespaces.md)

---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 내부 사용자
description: 내부 봇 사용자를 통해 GitLab 기능의 자동화된 시스템 작업을 활성화합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97584)된 봇은 사용자 목록에서 배지로 표시됩니다.

{{< /history >}}

GitLab은 내부 사용자(때로는 "봇"이라고 함)를 사용하여 일반 사용자에게 속성을 지정할 수 없는 작업 또는 함수를 수행합니다.

내부 사용자:

- GitLab에서 자동으로 생성되며 라이센스 한도에 포함되지 않습니다. 내부 사용자를 수동으로 생성할 수 없습니다.
- 기존 사용자 계정이 적용되지 않을 때 사용됩니다. 예를 들어 경고 또는 자동 리뷰 피드백을 생성할 때 사용됩니다.
- 제한된 액세스 권한과 매우 구체적인 목적이 있습니다. 인증 또는 API 요청과 같은 일반 사용자 작업에는 사용할 수 없습니다.
- 수행하는 모든 작업에 속성을 지정할 수 있는 이메일 주소와 이름이 있습니다.

내부 사용자는 기능 개발의 일부로 생성되기도 합니다. 예를 들어 GitLab Snippets에서 [마이그레이션](https://gitlab.com/gitlab-org/gitlab/-/issues/216120) 하기 위한 GitLab Migration Bot과 [Versioned Snippets](../user/snippets.md#versioned-snippets)가 있습니다. GitLab Migration Bot은 스니펫의 원래 작성자를 사용할 수 없을 때 스니펫의 작성자로 사용되었습니다. 예를 들어 사용자가 비활성화된 경우입니다.

내부 사용자의 다른 예:

- [GitLab Automation Bot](../user/group/iterations/_index.md#gitlab-automation-bot-user)
- [GitLab Security Bot](#gitlab-security-bot)
- [GitLab Security Policy Bot](#gitlab-security-policy-bot)
- [Alert Bot](../operations/incident_management/alerts.md#trigger-actions-from-alerts)
- [Ghost User](../user/profile/account/delete_account.md#associated-records)
- [Support Bot](../user/project/service_desk/configure.md#support-bot-user)
- [Placeholder User](../user/import/mapping/post_migration_mapping.md#placeholder-users) \- 가져오기 중에 생성됨
- Visual Review Bot
- [프로젝트 액세스 토큰](../user/project/settings/project_access_tokens.md) 및 [그룹 액세스 토큰](../user/group/settings/group_access_tokens.md)을 포함한 리소스 액세스 토큰으로, `project_{project_id}_bot_{random_string}` 및 `group_{group_id}_bot_{random_string}` 사용자와 `PersonalAccessToken`를 포함합니다.

## GitLab Admin Bot {#gitlab-admin-bot}

[GitLab Admin Bot](https://gitlab.com/gitlab-org/gitlab/-/blob/1d38cfdbed081f8b3fa14b69dd743440fe85081b/lib/users/internal.rb#L104)은 일반 사용자가 액세스하거나 수정할 수 없는 내부 사용자이며 다음을 포함한 많은 작업을 담당합니다:

- 프로젝트에 [기본 규정 준수 프레임워크](../user/compliance/compliance_frameworks/_index.md#default-compliance-frameworks)를 적용합니다.
- [휴면 사용자를 자동으로 비활성화](moderate_users.md#automatically-deactivate-dormant-users)합니다.
- [확인되지 않은 사용자를 자동으로 삭제](moderate_users.md#automatically-delete-unconfirmed-users)합니다.
- [휴면 프로젝트 삭제](dormant_project_deletion.md)합니다.
- [사용자를 잠금](../security/unlock_user.md)합니다.

## GitLab Security Bot {#gitlab-security-bot}

GitLab Security Bot은 [보안 정책](../user/application_security/policies/_index.md)을 위반하는 머지 리퀘스트에 댓글을 달기 위한 내부 사용자입니다.

## GitLab Security Policy Bot {#gitlab-security-policy-bot}

GitLab Security Policy Bot은 [보안 정책](../user/application_security/policies/_index.md#gitlab-security-policy-bot-user)에 정의된 예약된 파이프라인을 트리거하는 내부 사용자입니다. 이 계정은 보안 정책이 적용되는 모든 프로젝트에서 생성됩니다.

예약된 파이프라인 실행 정책의 경우 프로젝트 소유자가 명시적으로 액세스를 허용할 때 이 봇은 비공개 프로젝트에서 CI/CD 구성을 읽을 수 있습니다.

봇 액세스에는 다음과 같은 한도가 있습니다:

- 대상 프로젝트는 **Security policy bot access**를 활성화해야 합니다.
- 요청된 파일 경로는 프로젝트의 허용된 파일 패턴과 일치해야 합니다.
- 봇 프로젝트는 허용된 그룹 계층 구조에 있어야 합니다. 그룹이 구성되지 않은 경우 GitLab은 루트 상위 그룹을 사용합니다.

Security Policy Bot 액세스를 설정하려면 [예약된 파이프라인 실행 정책](../user/application_security/policies/scheduled_pipeline_execution_policies.md#option-2-allow-security-policy-bot-access-to-private-projects)을 참조하세요.

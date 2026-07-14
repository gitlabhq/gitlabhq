---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 이메일
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 인스턴스에서 전송되는 이메일의 일부 내용을 사용자 지정할 수 있습니다.

## 커스텀 로고 {#custom-logo}

일부 이메일 헤더의 로고를 사용자 지정할 수 있으며, [로고 사용자 지정 섹션](../appearance.md#customize-your-homepage-button)을 참조하세요.

## 이메일 알림 본문에 발신자 이름 포함 {#include-author-name-in-email-notification-email-body}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

기본적으로 GitLab은 알림 이메일의 이메일 주소를 이슈, 머지 리퀘스트 또는 댓글 작성자의 이메일 주소로 재정의합니다. 대신 이메일 본문에 작성자의 이메일 주소를 포함하려면 이 설정을 활성화합니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

이메일 본문에 작성자의 이메일 주소를 포함하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **이메일**을 확장합니다.
1. **Include author name in email notification email body** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 멀티파트 이메일 활성화 {#enable-multipart-email}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 멀티파트 형식(HTML 및 일반 텍스트) 또는 일반 텍스트만으로 이메일을 전송할 수 있습니다.

멀티파트 이메일을 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **이메일**을 확장합니다.
1. **Enable multipart email**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 개인 커밋 이메일을 위한 커스텀 호스트네임 {#custom-hostname-for-private-commit-emails}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 구성 옵션은 [개인 커밋 이메일](../../user/profile/_index.md#use-an-automatically-generated-private-commit-email)의 이메일 호스트네임을 설정합니다. 기본적으로 `users.noreply.YOUR_CONFIGURED_HOSTNAME`로 설정됩니다.

개인 커밋 이메일에 사용된 호스트네임을 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **이메일**을 확장합니다.
1. **커스텀 호스트네임 (개인 커밋 이메일용)** 필드에 원하는 호스트네임을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

> [!note]
> 호스트네임이 구성된 후 이전 호스트네임을 사용하는 모든 개인 커밋 이메일은 GitLab에서 인식되지 않습니다. 이는 [푸시 규칙](../../user/project/repository/push_rules.md)과 같은 특정 규칙(예: `Check whether author is a GitLab user` 및 `Check whether committer is the current authenticated user`)과 직접 충돌할 수 있습니다.

## 커스텀 추가 텍스트 {#custom-additional-text}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab이 전송하는 모든 이메일 하단에 추가 텍스트를 추가할 수 있습니다. 이 추가 텍스트는 법적, 감시 또는 규정 준수 이유로 사용할 수 있습니다.

이메일에 추가 텍스트를 추가하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **이메일**을 확장합니다.
1. **추가 텍스트** 필드에 텍스트를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 사용자 비활성화 이메일 {#user-deactivation-emails}

GitLab은 사용자의 계정이 비활성화된 경우 사용자에게 이메일 알림을 보냅니다.

이 알림을 비활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **이메일**을 확장합니다.
1. **사용자가 이메일 비활성화할 수 있도록 허용** 체크박스를 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

### 비활성화 이메일의 커스텀 추가 텍스트 {#custom-additional-text-in-deactivation-emails}

{{< history >}}

- GitLab 15.9에서 `deactivation_email_additional_text` [플래그](../feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/355964)되었습니다. 기본적으로 비활성화됨.
- [GitLab 15.9에서 GitLab Self-Managed에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111882).
- [GitLab 16.5에서 일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/392761). 기능 플래그 `deactivation_email_additional_text` 제거됨.

{{< /history >}}

GitLab이 사용자의 계정이 비활성화될 때 사용자에게 전송하는 이메일 하단에 추가 텍스트를 추가할 수 있습니다. 이 이메일 텍스트는 [커스텀 추가 텍스트](#custom-additional-text) 설정과는 별개입니다.

비활성화 이메일에 추가 텍스트를 추가하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **이메일**을 확장합니다.
1. **비활성화 이메일에 대한 추가 텍스트** 필드에 텍스트를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 상속된 멤버에 대한 그룹 및 프로젝트 액세스 토큰 만료 이메일 {#group-and-project-access-token-expiry-emails-to-inherited-members}

{{< history >}}

- 상속된 그룹 멤버에 대한 알림이 GitLab 17.7에서 `pat_expiry_inherited_members_notification` [플래그](../feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/463016)되었습니다. 기본적으로 비활성화됨.
- 기능 플래그 `pat_expiry_inherited_members_notification`이(가) GitLab 17.10에서 [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/393772).
- 기능 플래그 `pat_expiry_inherited_members_notification`이(가) GitLab `17.11`에서 제거됨

{{< /history >}}

GitLab 17.7 이상에서는 다음과 같은 상속된 그룹 및 프로젝트 액세스 토큰 멤버가 직접 그룹 및 프로젝트 액세스 토큰 멤버 외에도 곧 만료될 그룹 및 프로젝트 액세스 토큰 이메일을 받을 수 있습니다:

- 그룹의 경우 해당 그룹의 Owner 역할을 상속하는 멤버입니다.
- 프로젝트의 경우 해당 그룹에 속하는 프로젝트의 Maintainer 또는 Owner 역할을 상속하는 프로젝트 액세스 토큰 멤버입니다.

상속된 그룹 및 프로젝트 액세스 토큰 멤버에 토큰 만료 이메일을 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **이메일**을 확장합니다.
1. **Expiry notification emails about group and project access tokens should be sent to:** 아래에서 **그룹 또는 프로젝트의 모든 직접 및 상속된 멤버**를 선택합니다.
1. **Enforce this setting for all groups on this instance** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

토큰 만료 이메일에 대한 자세한 내용은 다음을 참조하세요:

- 그룹의 경우 [그룹 액세스 토큰 만료 이메일 설명서](../../user/group/settings/group_access_tokens.md#group-access-token-expiry-emails)를 참조하세요.
- 프로젝트의 경우 [프로젝트 액세스 토큰 만료 이메일 설명서](../../user/project/settings/project_access_tokens.md#project-access-token-expiry-emails)를 참조하세요.

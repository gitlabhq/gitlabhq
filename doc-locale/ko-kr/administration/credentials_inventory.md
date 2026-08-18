---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 인증 정보 인벤토리
description: 포괄적인 액세스 인벤토리를 통해 인증 정보를 모니터링합니다.
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 17.5에 GitLab.com에 소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/297441)
- [GitLab 17.7에 GitLab.com에 그룹 및 프로젝트 토큰 지원이 추가됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/498333)

{{< /history >}}

개인 액세스 토큰 인벤토리를 사용하여 조직에 대한 액세스를 모니터링하고 제어합니다.

- GitLab.com에서 인증 정보 인벤토리는 최상위 그룹의 엔터프라이즈 사용자 및 서비스 계정을 모니터링합니다.
- GitLab Self-Managed 및 GitLab Dedicated에서 인증 정보 인벤토리는 전체 인스턴스의 모든 사용자 및 서비스 계정을 모니터링합니다.

전제 조건:

- GitLab.com에서는 그룹의 Owner 역할이 필요합니다.
- GitLab Self-Managed 및 GitLab Dedicated에서는 관리자여야 합니다.

## 인증 정보 인벤토리 보기 {#view-the-credentials-inventory}

인증 정보 인벤토리를 사용하여 다음을 볼 수 있습니다:

- 개인 액세스 토큰입니다.
- 그룹 액세스 토큰입니다.
- 프로젝트 액세스 토큰입니다.
- SSH 키입니다.
- GPG 키(GitLab Self-Managed 및 GitLab Dedicated만 해당)입니다.

인증 정보 인벤토리를 보려면:

{{< tabs >}}

{{< tab title="인스턴스용" >}}

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **인증 정보**를 선택합니다.

{{< /tab >}}

{{< tab title="그룹용" >}}

1. 상단 바에서 **Search or go to**를 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안**을 선택합니다.
1. **인증 정보**를 선택합니다.

{{< /tab >}}

{{< /tabs >}}

인벤토리를 사용하여 다음을 포함한 인증 정보 세부 정보를 검토할 수 있습니다:

- 소유권입니다.
- 액세스 범위입니다.
- 사용 패턴입니다.
- 만료 날짜입니다.
- 해지 날짜입니다.

## 개인 액세스 토큰 해지 {#revoke-personal-access-tokens}

개인 액세스 토큰을 해지하려면:

{{< tabs >}}

{{< tab title="인스턴스용" >}}

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **인증 정보**를 선택합니다.
1. 개인 액세스 토큰 옆에서 **해지**를 선택합니다. 토큰이 이전에 만료되었거나 해지된 경우 관련 날짜가 표시됩니다.

액세스 토큰이 해지되고 사용자는 이메일로 알림을 받습니다.

{{< /tab >}}

{{< tab title="그룹용" >}}

1. 상단 바에서 **Search or go to**를 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안**을 선택합니다.
1. **인증 정보**를 선택합니다.
1. 개인 액세스 토큰 옆에서 **해지**를 선택합니다. 토큰이 이전에 만료되었거나 해지된 경우 관련 날짜가 표시됩니다.

액세스 토큰이 해지되고 사용자는 이메일로 알림을 받습니다.

{{< /tab >}}

{{< /tabs >}}

## 프로젝트 또는 그룹 액세스 토큰 해지 {#revoke-project-or-group-access-tokens}

프로젝트 또는 그룹 액세스 토큰을 해지하려면:

{{< tabs >}}

{{< tab title="인스턴스용" >}}

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **인증 정보**를 선택합니다.
1. **프로젝트 및 그룹 액세스 토큰** 탭을 선택합니다.
1. 프로젝트 액세스 토큰 옆에서 **해지**를 선택합니다.

{{< /tab >}}

{{< tab title="그룹용" >}}

1. 상단 바에서 **Search or go to**를 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안**을 선택합니다.
1. **인증 정보**를 선택합니다.
1. **프로젝트 및 그룹 액세스 토큰** 탭을 선택합니다.
1. 프로젝트 액세스 토큰 옆에서 **해지**를 선택합니다.

{{< /tab >}}

{{< /tabs >}}

## SSH 키 삭제 {#delete-ssh-keys}

SSH 키를 삭제하려면:

{{< tabs >}}

{{< tab title="인스턴스용" >}}

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **인증 정보**를 선택합니다.
1. **SSH 키** 탭을 선택합니다.
1. SSH 키 옆에서 **삭제**를 선택합니다.

SSH 키가 삭제되고 사용자는 알림을 받습니다.

{{< /tab >}}

{{< tab title="그룹용" >}}

1. 상단 바에서 **Search or go to**를 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안**을 선택합니다.
1. **인증 정보**를 선택합니다.
1. **SSH 키** 탭을 선택합니다.
1. SSH 키 옆에서 **삭제**를 선택합니다.

SSH 키가 삭제되고 사용자는 알림을 받습니다.

{{< /tab >}}

{{< /tabs >}}

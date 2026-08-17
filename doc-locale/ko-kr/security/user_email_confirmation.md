---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 새 사용자가 이메일을 확인하도록 요구
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 사용자가 가입할 때 사용자의 이메일 주소 확인을 요구하도록 구성할 수 있습니다. 이 설정이 활성화되면 사용자는 이메일 주소를 확인할 때까지 로그인할 수 없습니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **사용자 계정 생성 제한사항**을 확장하고 **이메일 확인 설정** 옵션을 찾습니다.

## 확인 토큰 만료 {#confirmation-token-expiry}

기본적으로 사용자는 확인 이메일이 전송된 후 24시간 이내에 계정을 확인할 수 있습니다. 24시간 후에는 확인 토큰이 유효하지 않게 됩니다.

## 확인되지 않은 사용자 자동 삭제 {#automatically-delete-unconfirmed-users}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이메일 확인이 활성화되면 관리자는 [확인되지 않은 사용자를 자동으로 삭제](../administration/moderate_users.md#automatically-delete-unconfirmed-users)하는 설정을 활성화할 수 있습니다.

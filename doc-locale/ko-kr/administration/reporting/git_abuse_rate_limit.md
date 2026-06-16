---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: GitLab 인스턴스에서 정의된 리포지토리 다운로드 제한을 초과하는 사용자를 자동으로 제한하고 계정정지하도록 Git 악용 비율 제한을 구성합니다
title: Git 악용 비율 제한 (관리)
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 15.2에서 소개](https://gitlab.com/groups/gitlab-org/-/epics/8066) 되었으며 [플래그](../feature_flags/_index.md)의 이름은 `git_abuse_rate_limit_feature_flag`입니다. 기본적으로 비활성화됨.
- GitLab 15.11에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/394996)합니다. 기능 플래그 `git_abuse_rate_limit_feature_flag` 제거됨.

{{< /history >}}

이것은 관리 문서입니다. 그룹의 Git 악용 비율 제한에 대한 정보는 [그룹 문서](../../user/group/reporting/git_abuse_rate_limit.md)를 참조하세요.

Git 악용 비율 제한은 인스턴스의 모든 프로젝트에서 지정된 수 이상의 리포지토리를 다운로드, 복제 또는 포크하는 사용자를 자동으로 [계정정지](../moderate_users.md#ban-and-unban-users)하는 기능입니다. 계정정지된 사용자는 인스턴스에 로그인할 수 없으며 HTTP 또는 SSH를 통해 공개되지 않은 그룹에 접근할 수 없습니다. 속도 제한은 [개인](../../user/profile/personal_access_tokens.md) 또는 [그룹 액세스 토큰](../../user/group/settings/group_access_tokens.md)으로 인증하는 사용자에게도 적용됩니다.

Git 악용 비율 제한은 인스턴스 관리자, [배포 토큰](../../user/project/deploy_tokens/_index.md) 또는 [배포 키](../../user/project/deploy_keys/_index.md)에는 적용되지 않습니다.

GitLab이 사용자의 속도 제한을 결정하는 방식은 개발 중입니다. GitLab 팀 멤버는 이 기밀 에픽에서 더 많은 정보를 볼 수 있습니다: `https://gitlab.com/groups/gitlab-org/modelops/anti-abuse/-/epics/14`.

## Git 악용 비율 제한 구성 {#configure-git-abuse-rate-limiting}

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **리포트**를 선택합니다.
1. **Git 악용 비율 제한**을 확장하세요.
1. Git 악용 비율 제한 설정을 업데이트합니다:
   1. **리포지토리 갯수** 필드에 `0` 이상 `10000` 이하의 숫자를 입력하세요. 이 숫자는 사용자가 계정정지되기 전에 지정된 기간 내에 다운로드할 수 있는 고유 리포지토리의 최대 개수를 지정합니다. `0`로 설정하면 Git 악용 비율 제한이 비활성화됩니다.
   1. **보고 주기 (초)** 필드에 `0` 이상 `864000` 이하의 숫자를 입력하세요 (10일). 이 숫자는 사용자가 계정정지되기 전에 최대 양의 리포지토리를 다운로드할 수 있는 초 단위의 시간을 지정합니다. `0`로 설정하면 Git 악용 비율 제한이 비활성화됩니다.
   1. 선택사항. `100`명의 사용자를 **제외된 사용자** 필드에 추가하여 제외하세요. 제외된 사용자는 자동으로 계정정지되지 않습니다.
   1. `100`명의 사용자를 **다음 사용자에게 알림 보내기** 필드에 추가하세요. 최소 1명의 사용자를 선택해야 합니다. 모든 애플리케이션 관리자는 기본적으로 선택됩니다.
   1. 선택사항. **Automatically ban users from this namespace when they exceed the specified limits** 토글을 켜서 자동 계정정지를 활성화하세요.
1. **변경 사항 저장**을 선택합니다.

## 자동 계정정지 알림 {#automatic-ban-notifications}

자동 계정정지가 비활성화되어 있으면 사용자가 제한을 초과해도 자동으로 계정정지되지 않습니다. 다만 **다음 사용자에게 알림 보내기**에 나열된 사용자들에게는 여전히 알림이 전송됩니다. 이 설정을 사용하여 자동 계정정지를 활성화하기 전에 속도 제한 설정의 올바른 값을 결정할 수 있습니다.

자동 계정정지가 활성화되어 있으면 사용자가 계정정지되려고 할 때 이메일 알림이 전송되며 사용자는 자동으로 GitLab 인스턴스에서 계정정지됩니다.

## 사용자 계정정지 해제 {#unban-a-user}

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택하세요.
1. **계정정지됨** 탭을 선택하고 계정정지를 해제할 계정을 검색하세요.
1. **사용자 관리** 드롭다운 목록에서 **사용자 계정정지 해제**를 선택하세요.
1. 확인 대화상자에서 **사용자 계정정지 해제**를 선택하세요.

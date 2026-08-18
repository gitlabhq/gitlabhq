---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 플래그가 지정된 사용자 활동을 모니터링하고 관리하며 스팸으로 간주되는 활동을 처리합니다.
gitlab_dedicated: yes
title: 스팸 로그 검토
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 사용자 활동을 추적하고 잠재적 스팸에 대해 특정 행동을 플래그로 표시합니다.

**운영자** 영역에서 GitLab 관리자는 스팸 로그를 조회하고 해결할 수 있습니다.

## 스팸 로그 관리 {#manage-spam-logs}

{{< history >}}

- **신뢰할 수 있는 사용자** [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131812) in GitLab 16.5.

{{< /history >}}

스팸 로그를 조회하고 해결하여 인스턴스에서 사용자 활동을 중재합니다.

스팸 로그를 조회하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **스팸 로그**를 선택합니다.
1. 선택사항. 스팸 로그를 해결하려면 **추가 작업** ({{< icon name="ellipsis_v" >}})을 선택한 후 **사용자 삭제**, **사용자 차단**, **로그 제거** 또는 **신뢰할 수 있는 사용자**를 선택합니다.

### 스팸 로그 해결 {#resolving-spam-logs}

스팸 로그를 다음 중 하나의 효과로 해결할 수 있습니다:

| 옵션 | 설명 |
|---------|-------------|
| **사용자 삭제** | 사용자는 인스턴스에서 [삭제](../user/profile/account/delete_account.md)됩니다. |
| **사용자 차단** | 사용자는 인스턴스에서 차단됩니다. 스팸 로그는 목록에 유지됩니다. |
| **로그 제거** | 스팸 로그가 목록에서 제거됩니다. |
| **신뢰할 수 있는 사용자** | 사용자를 신뢰할 수 있으며, 스팸으로 인해 차단되지 않고 이슈, 노트, 스니펫 및 머지 리퀘스트를 생성할 수 있습니다. 신뢰할 수 있는 사용자의 경우 스팸 로그가 생성되지 않습니다. |

## 관련 항목 {#related-topics}

- [사용자 중재 (관리자)](moderate_users.md)
- [학대 신고 검토](review_abuse_reports.md)

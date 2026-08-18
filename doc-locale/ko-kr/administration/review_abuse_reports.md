---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 사용자가 제출한 악용 리포트를 확인하고 해결합니다.
gitlab_dedicated: yes
title: 악용 리포트 검토
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 사용자로부터 제출된 악용 리포트를 확인하고 해결합니다.

GitLab 관리자는 **운영자** 영역에서 악용 리포트를 확인하고 [해결](#resolving-abuse-reports)할 수 있습니다.

## 이메일로 악용 리포트 알림 받기 {#receive-notification-of-abuse-reports-by-email}

새로운 악용 리포트를 이메일로 알림받으려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **리포트**를 선택합니다.
1. **악용 리포트** 섹션을 확장합니다.
1. 이메일 주소를 입력하고 **변경사항 저장**을 선택합니다.

알림 이메일 주소는 [API를 사용하여](../api/settings.md#available-settings) 설정하고 검색할 수도 있습니다.

## 악용 신고 {#reporting-abuse}

악용 신고에 대해 자세히 알아보려면 [악용 리포트 사용자 설명서](../user/report_abuse.md)를 참조하세요.

## 악용 리포트 해결 {#resolving-abuse-reports}

{{< history >}}

- **신뢰할 수 있는 사용자** [GitLab 16.4에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131102).

{{< /history >}}

악용 리포트에 액세스하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **악용 리포트**를 선택합니다.

악용 리포트를 해결하는 네 가지 방법이 있으며, 각 방법에 해당하는 버튼이 있습니다:

- 사용자 및 리포트 제거. 다음과 같은 작업을 수행합니다:
  - 인스턴스에서 [신고된 사용자를 삭제](../user/profile/account/delete_account.md)합니다.
  - 목록에서 악용 리포트를 제거합니다.
- [사용자 차단](#blocking-users).
- 리포트 제거. 다음과 같은 작업을 수행합니다:
  - 목록에서 악용 리포트를 제거합니다.
  - 신고된 사용자의 액세스 제한을 제거합니다.
- 사용자 신뢰. 다음과 같은 작업을 수행합니다:
  - 사용자가 스팸으로 차단되지 않고 이슈, 노트, 스니펫 및 머지 리퀘스트를 생성할 수 있도록 합니다.
  - 이 사용자에 대해 악용 리포트가 생성되는 것을 방지합니다.

다음은 **악용 리포트** 페이지의 예입니다:

![사용자에 대해 제출된 악용 리포트의 예를 보여주는 대시보드.](img/abuse_reports_page_v18_6.png)

### 사용자 차단 {#blocking-users}

차단된 사용자는 로그인하거나 리포지토리에 액세스할 수 없지만, 모든 데이터는 유지됩니다.

사용자를 차단하면:

- 악용 리포트 목록에 사용자가 남아 있습니다.
- **사용자 차단** 버튼이 비활성화된 **이미 차단됨** 버튼으로 변경됩니다.

사용자는 다음 메시지를 통해 알림을 받습니다:

```plaintext
Your account has been blocked. If you believe this is in error, contact a staff member.
```

차단 후에도 다음 작업을 수행할 수 있습니다:

- 필요한 경우 사용자 및 리포트를 제거합니다.
- 리포트를 제거합니다.

## 관련 항목 {#related-topics}

- [사용자 관리(관리)](moderate_users.md)
- [스팸 로그 검토](review_spam_logs.md)

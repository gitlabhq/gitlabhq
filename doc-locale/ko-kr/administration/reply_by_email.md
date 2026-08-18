---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 이메일로 회신하기
description: 이메일 회신을 통해 이슈 및 머지 리퀘스트의 댓글을 구성합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab은 사용자가 알림 이메일에 회신하여 이슈 및 머지 리퀘스트에 댓글을 달 수 있도록 설정할 수 있습니다.

## 필수 조건 {#prerequisite}

[수신 이메일](incoming_email.md)이 설정되어 있는지 확인합니다.

## 이메일 회신 작동 방식 {#how-replying-by-email-works}

이메일 회신은 3단계로 진행됩니다:

1. GitLab이 알림 이메일을 발송합니다.
1. 알림 이메일에 회신합니다.
1. GitLab이 회신을 수신합니다.

### GitLab이 알림 이메일을 발송합니다 {#gitlab-sends-a-notification-email}

GitLab이 알림 이메일을 발송할 때:

- `Reply-To` 헤더가 구성된 이메일 주소로 설정됩니다.
- 주소에 `%{key}` 플레이스홀더가 포함된 경우 특정 회신 키로 대체됩니다.
- 회신 키가 `References` 헤더에 추가됩니다.

### 알림 이메일에 회신합니다 {#you-reply-to-the-notification-email}

알림 이메일에 회신할 때 이메일 클라이언트가:

- 알림 이메일에서 가져온 `Reply-To` 주소로 이메일을 발송합니다.
- `In-Reply-To` 헤더를 알림 이메일의 `Message-ID` 헤더 값으로 설정합니다.
- `References` 헤더를 `Message-ID`의 값과 알림 이메일의 `References` 헤더의 값으로 설정합니다.

### GitLab이 회신을 수신합니다 {#gitlab-receives-your-reply-to-the-notification-email}

GitLab이 회신을 수신하면 [허용된 헤더 목록](incoming_email.md#accepted-headers)에서 회신 키를 검색합니다.

회신 키를 찾으면 회신이 관련 이슈, 머지 리퀘스트, 커밋 또는 알림을 트리거한 기타 항목에 댓글로 나타납니다.

`Message-ID`, `In-Reply-To`, 및 `References` 헤더에 대한 자세한 내용은 [RFC 5322](https://www.rfc-editor.org/rfc/rfc5322#section-3.6.4)를 참조합니다.

## 알림 보존 정책 {#retention-policy-for-notifications}

일부 수신 이메일 기능을 사용하려면 GitLab이 발송된 이메일 알림에 대한 메타데이터를 저장해야 합니다. 이 기록을 2년 동안 보존합니다. 이메일 알림이 2년보다 오래된 경우 해당 알림에 이메일로 회신할 수 없습니다. 여기에는 이슈 및 머지 리퀘스트 스레드에 이메일로 회신하는 것이 포함됩니다.

---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
description: 모든 사용자 또는 특정 그룹 및 프로젝트에 이메일 알림을 보냅니다.
gitlab_dedicated: yes
title: GitLab에서 이메일 보내기
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

관리자는 모든 사용자 또는 선택한 그룹이나 프로젝트의 사용자에게 이메일을 보낼 수 있습니다. 사용자는 주 이메일 주소로 이메일을 받습니다.

다음과 같은 목적으로 이 기능을 사용하여 사용자에게 알릴 수 있습니다:

- 새 프로젝트, 새 기능 또는 새 제품 출시에 대해.
- 새 배포 또는 예상되는 다운타임에 대해.

GitLab에서 발신되는 이메일 알림에 대한 정보는 [GitLab 알림 이메일](../user/profile/notifications.md)을 읽으세요.

## GitLab에서 사용자에게 이메일 보내기 {#sending-emails-to-users-from-gitlab}

모든 사용자 또는 특정 그룹이나 프로젝트의 사용자에게만 이메일 알림을 보낼 수 있습니다. 10분마다 한 번씩 이메일 알림을 보낼 수 있습니다.

이메일을 보내려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 오른쪽 위 모서리에서 **새 사용자** 버튼 옆의 **유저에게 이메일 보내기** ({{< icon name="mail" >}})를 선택합니다.
1. 필드를 완성하세요. 이메일 본문은 일반 텍스트만 지원하며 HTML, Markdown 또는 기타 리치 텍스트 형식을 지원하지 않습니다.
1. **그룹 또는 프로젝트 선택** 드롭다운 목록에서 수신자를 선택합니다.
1. **메시지 보내기**를 선택합니다.

## 이메일 구독 취소 {#unsubscribing-from-emails}

사용자는 이메일의 구독 취소 링크를 따라 GitLab에서 이메일 수신을 거부할 수 있습니다. 이 기능을 간단하게 유지하기 위해 구독 취소는 인증되지 않습니다.

구독 취소 시 사용자는 구독 취소가 발생했다는 이메일 알림을 받습니다. 구독 취소 옵션을 제공하는 엔드포인트는 속도 제한됩니다.

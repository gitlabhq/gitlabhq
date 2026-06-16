---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: IP 주소 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

IP 주소 제한을 통해 악의적인 사용자가 여러 IP 주소 뒤에서 자신의 활동을 숨기는 것을 방지합니다.

GitLab은 사용자가 지정된 기간 동안 요청을 만드는 데 사용하는 고유한 IP 주소의 목록을 유지합니다. 지정된 한도에 도달하면 사용자가 새 IP 주소에서 만든 모든 요청이 `403 Forbidden` 오류로 거부됩니다.

지정된 시간 기간 동안 사용자가 IP 주소에서 추가 요청을 하지 않으면 목록에서 IP 주소가 삭제됩니다.

> [!note]
> 러너가 특정 사용자로 작업을 실행하면 러너 IP 주소도 사용자의 고유한 IP 주소 목록에 저장됩니다. 따라서 사용자당 IP 주소 한도는 구성된 활성 러너의 수를 고려해야 합니다.

## IP 주소 제한 구성 {#configure-ip-address-restrictions}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **리포트**를 선택합니다.
1. **스팸 및 안티봇 보호**를 확장합니다.
1. IP 주소 제한 설정을 업데이트합니다:
   1. **여러 IP 주소에서 로그인 제한** 확인란을 선택하여 IP 주소 제한을 활성화합니다.
   1. **사용자당 IP 주소** 필드에 `1` 이상의 숫자를 입력합니다. 이 숫자는 사용자가 지정된 시간 기간 동안 GitLab에 접근할 수 있는 고유한 IP 주소의 최대 개수를 지정하며, 새 IP 주소에서의 요청은 이를 초과하면 거부됩니다.
   1. **IP 주소 만료 시간** 필드에 `0` 이상의 숫자를 입력합니다. 이 숫자는 마지막 요청 시간부터 계산하여 IP 주소가 사용자의 한도에 포함되는 시간(초)을 지정합니다.
1. **변경 사항 저장**을 선택합니다.

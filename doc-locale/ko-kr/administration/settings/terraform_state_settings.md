---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Terraform 상태 설정
description: Terraform 상태 암호화 및 저장소 한도를 구성합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

[Terraform 상태 파일](../terraform_state.md)에 대한 암호화 및 저장소 한도를 포함한 설정을 구성할 수 있습니다.

## Terraform 상태 암호화 {#terraform-state-encryption}

{{< history >}}

- [GitLab 18.8에 도입되었습니다.](https://gitlab.com/groups/gitlab-org/-/epics/19738)

{{< /history >}}

기본적으로 GitLab은 Terraform 상태 파일을 저장하기 전에 암호화합니다. 필요한 경우 암호화를 끌 수 있습니다.

암호화가 꺼져 있으면 Terraform 상태 파일은 암호화를 적용하지 않고 수신한 그대로 저장됩니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

Terraform 상태 암호화를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Terraform 상태**를 확장합니다.
1. **Terraform 상태 암호화를 켜기** 체크박스를 선택하거나 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

> [!warning]
> 암호화를 끄면 변경 사항이 새로운 Terraform 상태 파일에만 적용됩니다. 기존의 암호화된 파일은 암호화된 상태로 유지되며 예상대로 계속 작동합니다.

## Terraform 상태 저장소 한도 {#terraform-state-storage-limits}

{{< history >}}

- [GitLab 15.7에 도입되었습니다.](https://gitlab.com/gitlab-org/gitlab/-/issues/352951)

{{< /history >}}

[Terraform 상태 파일](../terraform_state.md)의 총 저장소를 제한할 수 있습니다. 한도는 각 개별 상태 파일 버전에 적용되며 새 버전이 생성될 때 확인됩니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

저장소 한도를 추가하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Terraform 상태**를 확장합니다.
1. **Terraform 상태 크기 제한 (바이트)** 필드에 바이트 단위의 크기 한도를 입력합니다. `0`로 설정하면 무제한 크기의 파일을 허용합니다.
1. **변경 사항 저장**을 선택합니다.

Terraform 상태 파일이 이 한도를 초과하면 GitLab은 파일을 저장하지 않으며 관련된 Terraform 작업을 거부합니다.

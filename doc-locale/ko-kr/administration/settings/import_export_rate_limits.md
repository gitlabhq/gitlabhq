---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 및 그룹의 가져오기 및 내보내기 속도 제한
description: "프로젝트 또는 그룹을 가져오거나 내보낼 때 GitLab 인스턴스의 속도 제한 설정을 구성합니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

프로젝트 및 그룹의 파일 가져오기 및 내보내기에 대한 속도 제한을 구성할 수 있습니다. 기본 속도 제한에 대한 정보는 [가져오기 및 내보내기 속도 제한](../instance_limits.md#import-and-export)을 참조하세요.

사용자가 속도 제한을 초과하면 `auth.log`에 기록됩니다.

## 가져오기 또는 내보내기 속도 제한 변경 {#change-an-import-or-export-rate-limit}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

속도 제한을 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택하세요.
1. **가져오기 및 내보내기 속도 제한**을 확장합니다.
1. 모든 속도 제한의 값을 변경합니다. 속도 제한은 IP 주소가 아닌 사용자당 분당입니다. 속도 제한을 비활성화하려면 `0`로 설정합니다.

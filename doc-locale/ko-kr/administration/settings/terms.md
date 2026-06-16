---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
gitlab_dedicated: yes
title: 서비스 약관 및 개인 정보 보호 정책
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

관리자는 서비스 약관 및 개인 정보 보호 정책의 수락을 강제할 수 있습니다. 이 옵션이 활성화되면 신규 및 기존 사용자는 약관에 동의해야 합니다.

활성화되면 인스턴스의 `-/users/terms` 페이지에서 서비스 약관을 볼 수 있습니다. 예를 들어 `https://gitlab.example.com/-/users/terms`입니다.

`Terms and privacy` 링크는 약관이 정의되면 도움말 메뉴에 표시됩니다.

## 서비스 약관 및 개인 정보 보호 정책 강제 {#enforce-a-terms-of-service-and-privacy-policy}

서비스 약관 및 개인 정보 보호 정책의 수락을 강제하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **서비스 약관 및 개인 정보 보호 정책** 섹션을 확장합니다.
1. **GitLab에 액세스하려면 모든 사용자가 서비스 약관 및 개인 정보 보호 정책에 동의해야 합니다.** 확인란을 선택합니다.
1. **서비스 약관 및 개인 정보 보호 정책**의 텍스트를 입력합니다. 이 텍스트 상자에서 [Markdown](../../user/markdown.md)을 사용할 수 있습니다.
1. **변경 사항 저장**을 선택합니다.

약관의 각 업데이트에 대해 새 버전이 저장됩니다. 사용자가 약관에 동의하거나 거부하면 GitLab은 해당 사용자가 동의하거나 거부한 버전을 기록합니다.

기존 사용자는 다음 GitLab 상호 작용에서 약관에 동의해야 합니다. 인증된 사용자가 약관을 거부하면 로그아웃됩니다.

활성화되면 신규 사용자의 가입 페이지에 필수 확인란이 추가됩니다:

![필수 약관 동의 확인란이 포함된 신규 계정 양식](img/sign_up_terms_v11_0.png)

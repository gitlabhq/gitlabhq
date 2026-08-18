---
stage: Growth
group: Engagement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: "로고, 파비콘, 로그인 페이지, 프로그레시브 웹 앱 설정, 시스템 메시지 및 색상 테마를 포함하여 GitLab 인스턴스 외관을 사용자 지정합니다."
title: GitLab 외관
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

인스턴스의 모양과 느낌을 변경하기 위해 설정을 업데이트할 수 있습니다.

## 전제 조건 {#prerequisites}

관리자 액세스 권한이 필요합니다.

## 외관 설정 액세스 {#access-appearance-settings}

**외관** 설정을 열려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **외관**을 선택합니다.

## 홈페이지 버튼 사용자 지정 {#customize-your-homepage-button}

홈페이지 버튼의 모양을 사용자 지정합니다.

홈페이지 버튼은 왼쪽 사이드바의 왼쪽 위 모서리에 있습니다. 기본 GitLab 로고 {{< icon name="tanuki" >}}를 임의의 이미지로 바꿉니다.

- 파일은 1 MB 미만이어야 합니다.
- 이미지는 24픽셀 높이여야 합니다. 24픽셀보다 높은 이미지는 자동으로 크기가 조정됩니다.

홈페이지 아이콘 이미지를 사용자 지정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **외관**을 선택합니다.
1. **네비게이션 바** 아래에서 **파일 선택**을 선택합니다.
1. 페이지 하단에서 **외관 설정 업데이트**를 선택합니다.

파이프라인 상태 메일도 사용자 지정 로고를 표시합니다. 그러나 일부 메일 응용 프로그램은 SVG 이미지를 지원하지 않습니다. 사용자 지정 이미지가 SVG 형식인 경우 파이프라인 메일은 기본 로고를 표시합니다.

## 파비콘 사용자 지정 {#customize-the-favicon}

파비콘의 모양을 사용자 지정합니다. 파비콘은 브라우저 탭에 표시되는 웹사이트의 아이콘입니다. GitLab 로고 {{< icon name="tanuki" >}}는 기본 브라우저 및 CI/CD 상태 파비콘입니다. 기본 아이콘을 `32 x 32` 픽셀이고 `.png` 또는 `.ico` 형식인 임의의 이미지로 바꿉니다.

파비콘을 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **외관**을 선택합니다.
1. **파비콘** 아래에서 **파일 선택**을 선택합니다.
1. 페이지 하단에서 **외관 설정 업데이트**를 선택합니다.

## 사이트 이름 사용자 지정 {#customize-the-site-name}

{{< history >}}

- GitLab 18.11에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228333).

{{< /history >}}

브라우저 탭의 페이지 제목에 사용자 지정 사이트 이름을 추가할 수 있습니다. 예를 들어, 사이트 이름이 `MyCompany`인 경우 홈페이지에서 브라우저 탭의 페이지 제목은 `Home · GitLab · MyCompany`로 표시됩니다.

사이트 이름의 최대 길이는 255자입니다.

사이트 이름을 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **외관**을 선택합니다.
1. **사이트 이름** 아래에 새 사이트 이름을 입력합니다.
1. 페이지 하단에서 **외관 설정 업데이트**를 선택합니다.

## 시스템 머리글 및 바닥글 메시지 추가 {#add-system-header-and-footer-messages}

{{< history >}}

- **메일 머리말 및 꼬리말 사용** 확인란은 GitLab 15.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/344819)되었습니다.

{{< /history >}}

GitLab 인스턴스의 인터페이스에 작은 머리글 메시지, 작은 바닥글 메시지 또는 둘 다를 추가합니다. 이 메시지는 로그인 및 가입 페이지와 같은 인스턴스의 모든 프로젝트 및 페이지에 표시됩니다.

- Markdown을 사용하여 메시지를 기울임, 굵게 또는 링크를 추가할 수 있습니다.
- 시스템 메시지는 한 줄이어야 하므로 Markdown 목록, 이미지 및 인용은 지원되지 않습니다.

시스템 머리글, 바닥글 메시지 또는 둘 다를 추가하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **외관**을 선택합니다.
1. **시스템 머리글 및 바닥글** 섹션으로 이동합니다.
1. 필드를 완성하세요.
1. 선택사항. **메일 머리말 및 꼬리말 사용** 확인란을 선택합니다. GitLab 인스턴스에서 보낸 모든 메일에 시스템 메시지를 추가합니다.
1. 페이지 하단에서 **외관 설정 업데이트**를 선택합니다.

기본적으로 시스템 머리글 및 바닥글 텍스트는 주황색 배경의 흰색 텍스트입니다. 메시지 색상을 사용자 지정하려면:

- **시스템 머리글 및 바닥글** 섹션으로 이동하고 **색상 커스터마이징**을 선택합니다.

## 로그인/가입 페이지 사용자 지정 {#customize-your-sign-in-and-register-pages}

<!-- vale gitlab_base.OxfordComma = NO -->
로그인 및 가입 페이지의 제목, 설명 및 로고를 사용자 지정합니다. 기본적으로 가입 페이지 로고는 제목과 설명 사이의 페이지 왼쪽에 위치합니다.
<!-- vale gitlab_base.OxfordComma = YES -->

로그인 및 가입 페이지 제목 또는 설명을 사용자 지정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **외관**을 선택합니다.
1. **로그인/가입 페이지** 섹션으로 이동합니다.
1. 필드를 완성하세요. 페이지 **제목** 및 **설명**을 Markdown으로 형식화할 수 있습니다.
1. 페이지 하단에서 **외관 설정 업데이트**를 선택합니다.

로그인 및 가입 페이지의 로고를 사용자 지정하려면:

- 파일은 1 MB 미만이어야 합니다.
- 이미지는 128픽셀 높이여야 합니다. 128픽셀보다 높은 이미지는 자동으로 크기가 조정됩니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **외관**을 선택합니다.
1. **로그인/가입 페이지** 섹션으로 이동합니다.
1. **로고** 아래에서 **파일 선택**을 선택합니다.
1. 페이지 하단에서 **외관 설정 업데이트**를 선택합니다.

로그인 메시지 아래에 [사용자 지정 도움말 메시지](settings/help_page.md) 를 추가하거나 [로그인 텍스트 메시지](settings/sign_in_restrictions.md#sign-in-information)를 추가할 수도 있습니다.

### 쿠키 기반 언어 선택기 비활성화 {#disable-cookie-based-language-selector}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144484)되었습니다.

{{< /history >}}

> [!flag]
> GitLab Self-Managed에서는 기본적으로 이 기능을 사용할 수 없습니다. 사용 가능하게 하려면 관리자가 [기능 플래그 활성화](feature_flags/_index.md)를 수행하면 되며, 이름은 `disable_preferred_language_cookie`입니다. GitLab.com 및 GitLab Dedicated에서는 이 기능을 사용할 수 없습니다.

`disable_preferred_language_cookie` 기능 플래그를 활성화하여 로그인 및 가입 페이지의 바닥글에서 쿠키 기반 언어 선택기를 제거할 수 있습니다.

## 프로그레시브 웹 앱 사용자 지정 {#customize-the-progressive-web-app}

{{< history >}}

- GitLab 15.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/375708)되었습니다.

{{< /history >}}

프로그레시브 웹 앱(PWA)의 아이콘, 표시 이름, 짧은 이름 및 설명을 사용자 지정합니다. 자세한 내용은 [프로그레시브 웹 앱](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)을 참조하세요.

프로그레시브 웹 앱 이름 및 짧은 이름을 추가하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **외관**을 선택합니다.
1. **프로그레시브 웹 앱 (PWA)** 섹션으로 이동합니다.
1. 필드를 완성하세요.
   - **이름**은 PWA의 표시 이름입니다.
   - **짧은 이름**은 모바일 디바이스 및 소형 화면에 표시됩니다.
1. 페이지 하단에서 **외관 설정 업데이트**를 선택합니다.

프로그레시브 웹 앱 설명을 추가하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **외관**을 선택합니다.
1. **프로그레시브 웹 앱 (PWA)** 섹션으로 이동합니다.
1. 필드를 완성하세요. **설명**을 Markdown으로 형식화할 수 있습니다.
1. 페이지 하단에서 **외관 설정 업데이트**를 선택합니다.

프로그레시브 웹 앱 아이콘을 사용자 지정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **외관**을 선택합니다.
1. **프로그레시브 웹 앱 (PWA)** 섹션으로 이동합니다.
1. **아이콘** 아래에서 **파일 선택**을 선택합니다.
1. 페이지 하단에서 **외관 설정 업데이트**를 선택합니다.

## 멤버 지침 {#member-guidelines}

GitLab의 그룹 및 프로젝트 멤버 페이지에 멤버 지침을 추가할 수 있습니다. 설명에 [Markdown](../user/markdown.md)을 사용할 수 있습니다.

멤버 지침은 다음 중 하나를 관리할 수 있는 [권한](../user/permissions.md)을 가진 사용자에게 표시됩니다:

- 그룹의 멤버입니다.
- 프로젝트의 멤버입니다.

다음 중 하나를 사용하여 그룹 및 프로젝트 멤버십을 관리하는 경우 멤버 지침을 추가해야 합니다:

- 개별 기준 대신 미리 정의된 그룹입니다.
- 외부 도구입니다.

## 새 프로젝트 페이지에 지침 추가 {#add-guidelines-to-the-new-project-page}

**새 프로젝트 페이지**에 지침 메시지를 추가합니다. Markdown을 사용하여 메시지 형식을 지정할 수 있습니다. 지침 메시지는 **새 프로젝트** 메시지 아래와 **새 프로젝트 페이지**의 왼쪽에 표시됩니다.

**새 프로젝트 페이지**에 지침 메시지를 추가하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **외관**을 선택합니다.
1. **새 프로젝트 페이지** 섹션으로 이동합니다.
1. 필드를 완성하세요. Markdown을 사용하여 지침 형식을 지정할 수 있습니다.

## 프로필 이미지 지침 추가 {#add-profile-image-guidelines}

프로필 이미지에 대한 지침을 추가합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **외관**을 선택합니다.
1. **Profile image guideline** 섹션으로 이동합니다.
1. 필드를 완성하세요. Markdown을 사용하여 텍스트 형식을 지정할 수 있습니다.

## Libravatar {#libravatar}

GitLab은 [Libravatar](https://www.libravatar.org)를 아바타 이미지용으로 지원하지만 GitLab 인스턴스에서 Libravatar 지원을 수동으로 활성화해야 합니다. 자세한 내용은 [Libravatar](libravatar.md)를 참조하여 서비스를 사용합니다.

## 모든 새 사용자의 색상 테마 변경 {#change-the-color-theme-for-all-new-users}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.8에서 도입: `gitlab_default_theme`는 기본 테마를 설정하기 위해 1에서 10까지의 값을 지정할 수 있습니다.
- 테마:  Light Indigo, Light Blue, Light Green 및 Light Red는 GitLab 18.4에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200475)되었습니다.

{{< /history >}}

모든 새 사용자의 [기본 네비게이션 테마를 변경](../user/profile/preferences.md#change-the-navigation-theme)하려면:

1. `gitlab_rails['gitlab_default_theme']`을 `/etc/gitlab/gitlab.rb`의 GitLab 구성 파일에 추가합니다:

   ```ruby
   gitlab_rails['gitlab_default_theme'] = 2
   ```

   사용 가능한 색상:
   <!-- The themes are defined in lib/gitlab/themes.rb -->

   | 값 | 색상  |
   | ----- | -----  |
   | 1     | Indigo |
   | 2     | Dark   |
   | 3     | Light  |
   | 4     | Blue   |
   | 5     | Green  |
   | 9     | Red    |

1. [GitLab 재구성 및 재시작](restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

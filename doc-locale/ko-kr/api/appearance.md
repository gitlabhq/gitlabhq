---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 애플리케이션 모양 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 GitLab 인스턴스의 모양을 제어합니다. 자세한 내용은 [GitLab Appearance](../administration/appearance.md)를 참조하세요.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

## 애플리케이션 모양 검색 {#retrieve-application-appearance}

이 GitLab 인스턴스의 모양 설정을 검색합니다.

```plaintext
GET /application/appearance
```

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/appearance"
```

응답 예시:

```json
{
  "title": "GitLab Test Instance",
  "description": "gitlab-test.example.com",
  "pwa_name": "GitLab PWA",
  "pwa_short_name": "GitLab",
  "pwa_description": "GitLab as PWA",
  "pwa_icon": "/uploads/-/system/appearance/pwa_icon/1/pwa_logo.png",
  "logo": "/uploads/-/system/appearance/logo/1/logo.png",
  "header_logo": "/uploads/-/system/appearance/header_logo/1/header.png",
  "favicon": "/uploads/-/system/appearance/favicon/1/favicon.png",
  "member_guidelines": "Custom member guidelines",
  "new_project_guidelines": "Please read the FAQs for help.",
  "profile_image_guidelines": "Custom profile image guidelines",
  "header_message": "",
  "footer_message": "",
  "message_background_color": "#e75e40",
  "message_font_color": "#ffffff",
  "email_header_and_footer_enabled": false,
  "site_name": "Production"
}
```

## 애플리케이션 모양 업데이트 {#update-application-appearance}

이 GitLab 인스턴스의 모양 설정을 업데이트합니다.

```plaintext
PUT /application/appearance
```

| 속성                         | 유형    | 필수 | 설명 |
|-----------------------------------|---------|----------|-------------|
| `title`                           | 문자열  | 아니요       | 로그인/회원가입 페이지의 인스턴스 제목 |
| `description`                     | 문자열  | 아니요       | 로그인/회원가입 페이지에 표시되는 마크다운 텍스트 |
| `pwa_name`                        | 문자열  | 아니요       | Progressive Web App의 전체 이름입니다. `name` 속성을 `manifest.json`에 사용합니다. [GitLab 15.8에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) |
| `pwa_short_name`                  | 문자열  | 아니요       | Progressive Web App의 약칭입니다. [GitLab 15.8에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) |
| `pwa_description`                 | 문자열  | 아니요       | Progressive Web App의 기능에 대한 설명입니다. `description` 속성을 `manifest.json`에 사용합니다. [GitLab 15.8에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) |
| `pwa_icon`                        | 혼합   | 아니요       | Progressive Web App에 사용되는 아이콘입니다. [애플리케이션 로고 업데이트](#update-application-logo)를 참조하세요. [GitLab 15.8에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) |
| `logo`                            | 혼합   | 아니요       | 로그인/회원가입 페이지에 사용되는 인스턴스 이미지입니다. [애플리케이션 로고 업데이트](#update-application-logo)를 참조하세요. |
| `header_logo`                     | 혼합   | 아니요       | 주 탐색 모음에 사용되는 인스턴스 이미지 |
| `favicon`                         | 혼합   | 아니요       | `.ico` 또는 `.png` 형식의 인스턴스 파비콘 |
| `member_guidelines`               | 문자열  | 아니요       | 멤버를 변경할 권한이 있는 사용자의 그룹 또는 프로젝트 멤버 페이지에 표시되는 마크다운 텍스트 |
| `new_project_guidelines`          | 문자열  | 아니요       | 새 프로젝트 페이지에 표시되는 마크다운 텍스트 |
| `profile_image_guidelines`        | 문자열  | 아니요       | 프로필 페이지의 공개 아바타 아래에 표시되는 마크다운 텍스트 |
| `header_message`                  | 문자열  | 아니요       | 시스템 헤더 막대의 메시지 |
| `footer_message`                  | 문자열  | 아니요       | 시스템 푸터 막대의 메시지 |
| `message_background_color`        | 문자열  | 아니요       | 시스템 헤더/푸터 막대의 배경색 |
| `message_font_color`              | 문자열  | 아니요       | 시스템 헤더/푸터 막대의 글자색 |
| `email_header_and_footer_enabled` | 부울 | 아니요       | 활성화된 경우 모든 발신 이메일에 헤더와 푸터를 추가합니다. |
| `site_name`                       | 문자열  | 아니요       | 페이지 제목 다음에 사이트 이름을 추가합니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/appearance?email_header_and_footer_enabled=true&header_message=test"
```

응답 예시:

```json
{
  "title": "GitLab Test Instance",
  "description": "gitlab-test.example.com",
  "pwa_name": "GitLab PWA",
  "pwa_short_name": "GitLab",
  "pwa_description": "GitLab as PWA",
  "pwa_icon": "/uploads/-/system/appearance/pwa_icon/1/pwa_logo.png",
  "logo": "/uploads/-/system/appearance/logo/1/logo.png",
  "header_logo": "/uploads/-/system/appearance/header_logo/1/header.png",
  "favicon": "/uploads/-/system/appearance/favicon/1/favicon.png",
  "member_guidelines": "Custom member guidelines",
  "new_project_guidelines": "Please read the FAQs for help.",
  "profile_image_guidelines": "Custom profile image guidelines",
  "header_message": "test",
  "footer_message": "",
  "message_background_color": "#e75e40",
  "message_font_color": "#ffffff",
  "email_header_and_footer_enabled": true,
  "site_name": ""
}
```

## 애플리케이션 로고 업데이트 {#update-application-logo}

포함된 이미지 파일을 사용하여 이 GitLab 인스턴스의 로고를 업데이트합니다.

로컬 파일 시스템에서 아바타를 업로드하려면 `--form` 인수를 사용하여 파일을 포함합니다. 이로 인해 cURL이 `Content-Type: multipart/form-data` 헤더를 사용하여 데이터를 게시합니다. `file=` 매개변수는 파일 시스템의 이미지 파일을 가리키고 `@`가 앞에 있어야 합니다.

```plaintext
PUT /application/appearance
```

| 속성  | 유형  | 필수 | 설명 |
|------------|-------|----------|-------------|
| `logo`     | 혼합 | 예      | 로고로 사용되는 이미지입니다. |
| `pwa_icon` | 혼합 | 예      | Progressive Web App에 사용되는 이미지입니다. [GitLab 15.8에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) |

요청 예시:

```shell
curl --location --request PUT \
  --url "https://gitlab.example.com/api/v4/application/appearance?data=image/png" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: multipart/form-data" \
  --form "logo=@/path/to/logo.png"
```

응답 예시:

```json
{
  "logo":"/uploads/-/system/appearance/logo/1/logo.png"
}
```

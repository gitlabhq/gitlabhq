---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: アプリケーションの外観API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、GitLabインスタンスの外観を制御します。詳細については、[GitLabの外観](../administration/appearance.md)を参照してください。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

## アプリケーションの外観を取得 {#retrieve-application-appearance}

このGitLabインスタンスの外観設定を取得します。

```plaintext
GET /application/appearance
```

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/appearance"
```

レスポンス例: 

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
  "email_header_and_footer_enabled": false
}
```

## アプリケーションの外観を更新 {#update-application-appearance}

このGitLabインスタンスの外観設定を更新します。

```plaintext
PUT /application/appearance
```

| 属性                         | 型    | 必須 | 説明 |
|-----------------------------------|---------|----------|-------------|
| `title`                           | 文字列  | いいえ       | サインイン/サインアップページ上のインスタンスタイトル |
| `description`                     | 文字列  | いいえ       | サインイン/サインアップページに表示されるMarkdownテキスト |
| `pwa_name`                        | 文字列  | いいえ       | プログレッシブウェブアプリの正式名称。`manifest.json`の`name`属性に使用されます。GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/375708)されました。 |
| `pwa_short_name`                  | 文字列  | いいえ       | プログレッシブウェブアプリの短い名前。GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/375708)されました。 |
| `pwa_description`                 | 文字列  | いいえ       | プログレッシブウェブアプリの機能の説明。`manifest.json`の`description`属性に使用されます。GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/375708)されました。 |
| `pwa_icon`                        | 混合   | いいえ       | プログレッシブウェブアプリに使用されるアイコン。[アプリケーションロゴの更新](#update-application-logo)を参照してください。GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/375708)されました。 |
| `logo`                            | 混合   | いいえ       | サインイン/サインアップページで使用されるインスタンス画像。[アプリケーションロゴの更新](#update-application-logo)を参照してください |
| `header_logo`                     | 混合   | いいえ       | メインナビゲーションバーに使用されるインスタンス画像 |
| `favicon`                         | 混合   | いいえ       | `.ico`または`.png`形式のインスタンスファビコン |
| `member_guidelines`               | 文字列  | いいえ       | メンバーを変更する権限を持つユーザー向けに、グループまたはプロジェクトのメンバーページに表示されるMarkdownテキスト |
| `new_project_guidelines`          | 文字列  | いいえ       | 新規プロジェクトページに表示されるMarkdownテキスト |
| `profile_image_guidelines`        | 文字列  | いいえ       | パブリックアバターの下のプロフィールページに表示されるMarkdownテキスト |
| `header_message`                  | 文字列  | いいえ       | システムヘッダーバーのメッセージ |
| `footer_message`                  | 文字列  | いいえ       | システムfooterバーのメッセージ |
| `message_background_color`        | 文字列  | いいえ       | システムヘッダー/footerバーの背景色 |
| `message_font_color`              | 文字列  | いいえ       | システムヘッダー/footerバーのフォントの色 |
| `email_header_and_footer_enabled` | ブール値 | いいえ       | 有効になっている場合、すべての送信メールにヘッダーとfooterを追加します |

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/appearance?email_header_and_footer_enabled=true&header_message=test"
```

レスポンス例: 

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
  "email_header_and_footer_enabled": true
}
```

## アプリケーションロゴの更新 {#update-application-logo}

このGitLabインスタンスのロゴを、含まれている画像ファイルで更新します。

ローカルのファイルシステムからアバターをアップロードするには、`--form`引数を使用してファイルを含めます。これにより、cURLはヘッダー`Content-Type: multipart/form-data`を使用してデータを送信します。`file=`パラメータは、ファイルシステムの画像ファイルを指しており、先頭に`@`を付ける必要があります。

```plaintext
PUT /application/appearance
```

| 属性  | 型  | 必須 | 説明 |
|------------|-------|----------|-------------|
| `logo`     | 混合 | はい      | ロゴとして使用される画像。 |
| `pwa_icon` | 混合 | はい      | プログレッシブウェブアプリに使用される画像。GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/375708)されました。 |

リクエスト例: 

```shell
curl --location --request PUT \
  --url "https://gitlab.example.com/api/v4/application/appearance?data=image/png" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: multipart/form-data" \
  --form "logo=@/path/to/logo.png"
```

レスポンス例: 

```json
{
  "logo":"/uploads/-/system/appearance/logo/1/logo.png"
}
```

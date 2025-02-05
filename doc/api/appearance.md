---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Application appearance API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Use this API to control the appearance of your GitLab instance. For more information, see [GitLab Appearance](../administration/appearance.md).

Prerequisites:

- You must have administrator access to the instance.

## Get details on current application appearance

Gets details on the current appearance configuration for this GitLab instance.

```plaintext
GET /application/appearance
```

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/appearance"
```

Example response:

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

## Update application appearance

Updates the current appearance configuration for this GitLab instance.

```plaintext
PUT /application/appearance
```

| Attribute                         | Type    | Required | Description |
|-----------------------------------|---------|----------|-------------|
| `title`                           | string  | no       | Instance title on the sign in / sign up page |
| `description`                     | string  | no       | Markdown text shown on the sign in / sign up page |
| `pwa_name`                        | string  | no       | Full name of the Progressive Web App. Used for the attribute `name` in `manifest.json`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) in GitLab 15.8. |
| `pwa_short_name`                  | string  | no       | Short name for Progressive Web App. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) in GitLab 15.8. |
| `pwa_description`                 | string  | no       | An explanation of what the Progressive Web App does. Used for the attribute `description` in `manifest.json`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) in GitLab 15.8. |
| `pwa_icon`                        | mixed   | no       | Icon used for Progressive Web App. See [Update application logo](#update-application-logo). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) in GitLab 15.8. |
| `logo`                            | mixed   | no       | Instance image used on the sign in / sign up page. See [Update application logo](#update-application-logo) |
| `header_logo`                     | mixed   | no       | Instance image used for the main navigation bar |
| `favicon`                         | mixed   | no       | Instance favicon in `.ico` or `.png` format |
| `member_guidelines`               | string  | no       | Markdown text shown on the group or project member page for users with permission to change members |
| `new_project_guidelines`          | string  | no       | Markdown text shown on the new project page |
| `profile_image_guidelines`        | string  | no       | Markdown text shown on the profile page below Public Avatar |
| `header_message`                  | string  | no       | Message in the system header bar |
| `footer_message`                  | string  | no       | Message in the system footer bar |
| `message_background_color`        | string  | no       | Background color for the system header / footer bar |
| `message_font_color`              | string  | no       | Font color for the system header / footer bar |
| `email_header_and_footer_enabled` | boolean | no       | Add header and footer to all outgoing emails if enabled |

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/appearance?email_header_and_footer_enabled=true&header_message=test"
```

Example response:

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

## Update application logo

Updates the current logo for this GitLab instance with an included image file.

To upload an avatar from your local file system, use the `--form` argument to include the file.
This causes cURL to post data using the header `Content-Type: multipart/form-data`.
The `file=` parameter must point to an image file on your file system and be
preceded by `@`.

```plaintext
PUT /application/appearance
```

| Attribute  | Type  | Required | Description |
|------------|-------|----------|-------------|
| `logo`     | mixed | Yes      | Image used as a logo. |
| `pwa_icon` | mixed | Yes      | Image used for the Progressive Web App. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) in GitLab 15.8. |

Example request:

```shell
curl --location --request PUT \
  --url "https://gitlab.example.com/api/v4/application/appearance?data=image/png" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: multipart/form-data" \
  --form "logo=@/path/to/logo.png"
```

Example response:

```json
{
  "logo":"/uploads/-/system/appearance/logo/1/logo.png"
}
```

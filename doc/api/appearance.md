---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Appearance API **(CORE ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16647) in GitLab 12.7.

Appearance API allows you to maintain GitLab's appearance as if using the GitLab UI at
`/admin/appearance`. The API requires administrator privileges.

## Get current appearance configuration

List the current appearance configuration of the GitLab instance.

```plaintext
GET /application/appearance
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/appearance"
```

Example response:

```json
{
  "title": "GitLab Test Instance",
  "description": "gitlab-test.example.com",
  "logo": "/uploads/-/system/appearance/logo/1/logo.png",
  "header_logo": "/uploads/-/system/appearance/header_logo/1/header.png",
  "favicon": "/uploads/-/system/appearance/favicon/1/favicon.png",
  "new_project_guidelines": "Please read the FAQs for help.",
  "profile_image_guidelines": "Custom profile image guidelines",
  "header_message": "",
  "footer_message": "",
  "message_background_color": "#e75e40",
  "message_font_color": "#ffffff",
  "email_header_and_footer_enabled": false
}
```

## Change appearance configuration

Use an API call to modify GitLab instance appearance configuration.

```plaintext
PUT /application/appearance
```

| Attribute                         | Type    | Required | Description |
| --------------------------------- | ------- | -------- | ----------- |
| `title`                           | string  | no       | Instance title on the sign in / sign up page
| `description`                     | string  | no       | Markdown text shown on the sign in / sign up page
| `logo`                            | mixed   | no       | Instance image used on the sign in / sign up page. See [Change logo](#change-logo)
| `header_logo`                     | mixed   | no       | Instance image used for the main navigation bar
| `favicon`                         | mixed   | no       | Instance favicon in `.ico` or `.png` format
| `new_project_guidelines`          | string  | no       | Markdown text shown on the new project page
| `profile_image_guidelines`        | string  | no       | Markdown text shown on the profile page below Public Avatar
| `header_message`                  | string  | no       | Message within the system header bar
| `footer_message`                  | string  | no       | Message within the system footer bar
| `message_background_color`        | string  | no       | Background color for the system header / footer bar
| `message_font_color`              | string  | no       | Font color for the system header / footer bar
| `email_header_and_footer_enabled` | boolean | no       | Add header and footer to all outgoing emails if enabled

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/appearance?email_header_and_footer_enabled=true&header_message=test"
```

Example response:

```json
{
  "title": "GitLab Test Instance",
  "description": "gitlab-test.example.com",
  "logo": "/uploads/-/system/appearance/logo/1/logo.png",
  "header_logo": "/uploads/-/system/appearance/header_logo/1/header.png",
  "favicon": "/uploads/-/system/appearance/favicon/1/favicon.png",
  "new_project_guidelines": "Please read the FAQs for help.",
  "profile_image_guidelines": "Custom profile image guidelines",
  "header_message": "test",
  "footer_message": "",
  "message_background_color": "#e75e40",
  "message_font_color": "#ffffff",
  "email_header_and_footer_enabled": true
}
```

## Change logo

Upload a logo to your GitLab instance.

To upload an avatar from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`. The
`file=` parameter must point to an image file on your file system and be 
preceded by `@`.

```plaintext
PUT /application/appearance
```

| Attribute | Type   | Required | Description    |
| --------- | ------ | -------- | -------------- |
| `logo`    | string | Yes      | File to upload |

Example request:

```shell
curl --location --request PUT "https://gitlab.example.com/api/v4/application/appearance?data=image/png" \
--header "Content-Type: multipart/form-data" \
--header "PRIVATE-TOKEN: <your_access_token>" \
--form "logo=@/path/to/logo.png"
```

Returned object:

```json
{
   "logo":"/uploads/-/system/appearance/logo/1/logo.png"
```

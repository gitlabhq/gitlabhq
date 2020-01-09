# Appearance API **(CORE ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/16647) in GitLab 12.7.

Appearance API allows you to maintain GitLab's appearance as if using the GitLab UI at
`/admin/appearance`. The API requires administrator privileges.

## Get current appearance configuration

List the current appearance configuration of the GitLab instance.

```
GET /application/appearance
```

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/application/appearance
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
  "header_message": "",
  "footer_message": "",
  "message_background_color": "#e75e40",
  "message_font_color": "#ffffff",
  "email_header_and_footer_enabled": false
}
```

## Change appearance configuration

Use an API call to modify GitLab instance appearance configuration.

```
PUT /application/appearance
```

| Attribute                         | Type    | Required | Description |
| --------------------------------- | ------- | -------- | ----------- |
| `title`                           | string  | no       | Instance title on the sign in / sign up page
| `description`                     | string  | no       | Markdown text shown on the sign in / sign up page
| `logo`                            | mixed   | no       | Instance image used on the sign in / sign up page
| `header_logo`                     | mixed   | no       | Instance image used for the main navigation bar
| `favicon`                         | mixed   | no       | Instance favicon in .ico/.png format
| `new_project_guidelines`          | string  | no       | Markdown text shown on the new project page
| `header_message`                  | string  | no       | Message within the system header bar
| `footer_message`                  | string  | no       | Message within the system footer bar
| `message_background_color`        | string  | no       | Background color for the system header / footer bar
| `message_font_color`              | string  | no       | Font color for the system header / footer bar
| `email_header_and_footer_enabled` | boolean | no       | Add header and footer to all outgoing emails if enabled

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/application/appearance?email_header_and_footer_enabled=true&header_message=test
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
  "header_message": "test",
  "footer_message": "",
  "message_background_color": "#e75e40",
  "message_font_color": "#ffffff",
  "email_header_and_footer_enabled": true
}
```

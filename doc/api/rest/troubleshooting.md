---
stage: Foundations
group: Import and Integrate
description: Programmatic interaction with GitLab.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: REST API troubleshooting
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When working with the REST API, you might encounter an issue.

To troubleshoot, refer to the REST API status codes. It might also help to include the HTTP response headers and exit code.

## Status codes

The GitLab REST API returns a status code with every response, according to context and action. The
status code returned by a request can be useful when troubleshooting.

The following table gives an overview of how the API functions generally behave.

| Request type            | Description |
|:------------------------|:------------|
| `GET`                   | Access one or more resources and return the result as JSON. |
| `POST`                  | Returns `201 Created` if the resource is successfully created and return the newly created resource as JSON. |
| `GET` / `PUT` / `PATCH` | Returns `200 OK` if the resource is accessed or modified successfully. The (modified) result is returned as JSON. |
| `DELETE`                | Returns `204 No Content` if the resource was deleted successfully or `202 Accepted` if the resource is scheduled to be deleted. |

The following table shows the possible return codes for API requests.

| Return values             | Description |
|:--------------------------|:------------|
| `200 OK`                  | The `GET`, `PUT`, `PATCH` or `DELETE` request was successful, and the resource itself is returned as JSON. |
| `201 Created`             | The `POST` request was successful, and the resource is returned as JSON. |
| `202 Accepted`            | The `GET`, `PUT` or `DELETE` request was successful, and the resource is scheduled for processing. |
| `204 No Content`          | The server has successfully fulfilled the request, and there is no additional content to send in the response payload body. |
| `301 Moved Permanently`   | The resource has been definitively moved to the URL given by the `Location` headers. |
| `304 Not Modified`        | The resource hasn't been modified since the last request. |
| `400 Bad Request`         | A required attribute of the API request is missing. For example, the title of an issue is not given. |
| `401 Unauthorized`        | The user isn't authenticated. A valid [user token](authentication.md) is necessary. |
| `403 Forbidden`           | The request isn't allowed. For example, the user isn't allowed to delete a project. |
| `404 Not Found`           | A resource couldn't be accessed. For example, an ID for a resource couldn't be found, or the user isn't authorized to access the resource. |
| `405 Method Not Allowed`  | The request isn't supported. |
| `409 Conflict`            | A conflicting resource already exists. For example, creating a project with a name that already exists. |
| `412 Precondition Failed` | The request was denied. This can happen if the `If-Unmodified-Since` header is provided when trying to delete a resource, which was modified in between. |
| `422 Unprocessable`       | The entity couldn't be processed. |
| `429 Too Many Requests`   | The user exceeded the [application rate limits](../../administration/instance_limits.md#rate-limits). |
| `500 Server Error`        | While handling the request, something went wrong on the server. |
| `503 Service Unavailable` | The server cannot handle the request because the server is temporarily overloaded. |

### Status code 400

When working with the API you may encounter validation errors, in which case
the API returns an HTTP `400` error.

Such errors appear in the following cases:

- A required attribute of the API request is missing (for example, the title of
  an issue isn't given).
- An attribute did not pass the validation (for example, the user bio is too
  long).

When an attribute is missing, you receive something like:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
{
    "message":"400 (Bad request) \"title\" not given"
}
```

When a validation error occurs, error messages are different. They hold
all details of validation errors:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
{
    "message": {
        "bio": [
            "is too long (maximum is 255 characters)"
        ]
    }
}
```

This makes error messages more machine-readable. The format can be described as
follows:

```json
{
    "message": {
        "<property-name>": [
            "<error-message>",
            "<error-message>",
            ...
        ],
        "<embed-entity>": {
            "<property-name>": [
                "<error-message>",
                "<error-message>",
                ...
            ],
        }
    }
}
```

## Include HTTP response headers

The HTTP response headers can provide extra information when troubleshooting.

To include HTTP response headers in the response, use the `--include` option:

```shell
curl --include "https://gitlab.example.com/api/v4/projects"
HTTP/2 200
...
```

## Include HTTP exit code

The HTTP exit code in the API response can provide extra information when troubleshooting.

To include the HTTP exit code, include the `--fail` option:

```shell
curl --fail "https://gitlab.example.com/api/v4/does-not-exist"
curl: (22) The requested URL returned error: 404
```

## Requests detected as spam

REST API requests can be detected as spam. If a request is detected as spam and:

- A CAPTCHA service is not configured, an error response is returned. For example:

  ```json
  {"message":{"error":"Your snippet has been recognized as spam and has been discarded."}}
  ```

- A CAPTCHA service is configured, you receive a response with:
  - `needs_captcha_response` set to `true`.
  - The `spam_log_id` and `captcha_site_key` fields set.

  For example:

  ```json
  {"needs_captcha_response":true,"spam_log_id":42,"captcha_site_key":"REDACTED","message":{"error":"Your snippet has been recognized as spam. Please, change the content or solve the reCAPTCHA to proceed."}}
  ```

  - Use the `captcha_site_key` to obtain a CAPTCHA response value using the appropriate CAPTCHA API.
    Only [Google reCAPTCHA v2](https://developers.google.com/recaptcha/docs/display) is supported.
  - Resubmit the request with the `X-GitLab-Captcha-Response` and `X-GitLab-Spam-Log-Id` headers set.

    ```shell
    export CAPTCHA_RESPONSE="<CAPTCHA response obtained from CAPTCHA service>"
    export SPAM_LOG_ID="<spam_log_id obtained from initial REST response>"
    curl --request POST --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" --header "X-GitLab-Captcha-
    Response: $CAPTCHA_RESPONSE" --header "X-GitLab-Spam-Log-Id: $SPAM_LOG_ID"
    "https://gitlab.example.com/api/v4/snippets?
    title=Title&file_name=FileName&content=Content&visibility=public"
    ```

## Error: `404 Not Found` when using a reverse proxy

If your GitLab instance uses a reverse proxy, you might see `404 Not Found` errors when
using a GitLab [editor extension](../../editor_extensions/_index.md), the GitLab CLI, or
API calls with URL-encoded parameters.

This problem occurs when your reverse proxy decodes characters like `/`, `?`, and `@`
before passing the parameters on to GitLab.

To resolve this problem, edit the configuration for your reverse proxy:

- In the `VirtualHost` section, add `AllowEncodedSlashes NoDecode`.
- In the `Location` section, edit `ProxyPass` and add the `nocanon` flag.

For example:

::Tabs

:::TabTitle Apache configuration

```plaintext
<VirtualHost *:443>
  ServerName git.example.com

  SSLEngine on
  SSLCertificateFile     /etc/letsencrypt/live/git.example.com/fullchain.pem
  SSLCertificateKeyFile  /etc/letsencrypt/live/git.example.com/privkey.pem
  SSLVerifyClient None

  ProxyRequests     Off
  ProxyPreserveHost On
  AllowEncodedSlashes NoDecode

  <Location />
     ProxyPass http://127.0.0.1:8080/ nocanon
     ProxyPassReverse http://127.0.0.1:8080/
     Order deny,allow
     Allow from all
  </Location>
</VirtualHost>
```

:::TabTitle NGINX configuration

```plaintext
server {
  listen       80;
  server_name  gitlab.example.com;
  location / {
     proxy_pass    http://ip:port;
     proxy_set_header        X-Forwarded-Proto $scheme;
     proxy_set_header        Host              $http_host;
     proxy_set_header        X-Real-IP         $remote_addr;
     proxy_set_header        X-Forwarded-For   $proxy_add_x_forwarded_for;
     proxy_read_timeout    300;
     proxy_connect_timeout 300;
  }
}
```

::EndTabs

For more information, see [issue 18775](https://gitlab.com/gitlab-org/gitlab/-/issues/18775).

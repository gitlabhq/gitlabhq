---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Exploratory testing of CAPTCHAs
---

You can reliably test CAPTCHA on review apps, and in your local development environment (GDK).
You can always:

- Force a reCAPTCHA to appear where it is supported.
- Force a checkbox to display, instead of street sign images to find and select.

To set up testing, follow the configuration on this page.

## Use appropriate test data

Make sure you are testing a scenario which has spam/CAPTCHA enabled. For example:
make sure you are editing a _public_ snippet, as only public snippets are checked for spam.

## Enable feature flags

Enable any relevant feature flag, if the spam/CAPTCHA support is behind a feature flag.

## Set up Akismet and reCAPTCHA

1. To set up reCAPTCHA:
   1. Review the [GitLab reCAPTCHA documentation](../../integration/recaptcha.md).
   1. Follow the instructions provided by Google to get the official [test reCAPTCHA credentials](https://developers.google.com/recaptcha/docs/faq#id-like-to-run-automated-tests-with-recaptcha.-what-should-i-do).
      1. For **Site key**, use: `6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI`
      1. For **Secret key**, use: `6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe`
   1. Go to **Admin -> Settings -> Reporting** settings: `http://gdk.test:3000/admin/application_settings/reporting#js-spam-settings`
   1. Expand the **Spam and Anti-bot Protection** section.
   1. Select **Enable reCAPTCHA**. Enabling for login is not required unless you are testing that feature.
   1. Enter the **Site key** and **Secret key**.
1. To set up Akismet:
   1. Review the [GitLab documentation on Akismet](../../integration/akismet.md).
   1. Get an Akismet API key. You can sign up for [a testing key from Akismet](https://akismet.com).
      You must enter your local host (such as`gdk.test`) and email when signing up.
   1. Go to GitLab Akismet settings page, for example:
      `http://gdk.test:3000/admin/application_settings/reporting#js-spam-settings`
   1. Enable Akismet and enter your Akismet **API key**.
1. To force an Akismet false-positive spam check, refer to the
   [Akismet API documentation](https://akismet.com/developers/detailed-docs/comment-check/) and
   [Akismet Getting Started documentation](https://akismet.com/support/getting-started/confirm/) for more details:
   1. You can use `akismet-guaranteed-spam@example.com` as the author email to force spam using the following steps:
      1. Go to user email settings: `http://gdk.test:3000/-/profile/emails`
      1. Add `akismet-guaranteed-spam@example.com` as a secondary email for the administrator user.
      1. Confirm it in the Rails console: `bin/rails c` -> `User.find_by_username('root').emails.last.confirm`
      1. Switch this verified email to be your primary email:
         1. Go to **Avatar dropdown list -> Edit Profile -> Main Settings**.
         1. For **Email**, enter `akismet-guaranteed-spam@example.com` to replace `admin@example.com`.
         1. Select **Update Profile Settings** to save your changes.

## Test in the web UI

After you have all the above configuration in place, you can test CAPTCHAs. Test
in an area of the application which already has CAPTCHA support, such as:

- Creating or editing an issue.
- Creating or editing a public snippet. Only **public** snippets are checked for spam.

## Test in a development environment

After you force Spam Flagging + CAPTCHA using the steps above, you can test the
behavior with any spam-protected model/controller action.

### Test with CAPTCHA enabled (CONDITIONAL_ALLOW verdict)

If CAPTCHA is enabled in these areas, you must solve the CAPTCHA popup modal before you can resubmit the form:

- **Admin -> Settings -> Reporting -> Spam**
- **Anti-bot Protection -> Enable reCAPTCHA**

<!-- vale gitlab_base.Substitutions = NO -->

### Testing with CAPTCHA disabled ("DISALLOW" verdict)

<!-- vale gitlab_base.Substitutions = YES -->

If CAPTCHA is disabled in **Admin -> Settings -> Reporting -> Spam** and **Anti-bot Protection -> Enable reCAPTCHA**,
no CAPTCHA popup displays. You are prevented from submitting the form at all.

### HTML page to render reCAPTCHA

NOTE:
If you use **the Google official test reCAPTCHA credentials** listed in
[Set up Akismet and reCAPTCHA](#set-up-akismet-and-recaptcha), the
CAPTCHA response string does not matter. It can be any string. If you use a
real, valid key pair, you must solve the CAPTCHA to obtain a
valid CAPTCHA response to use. You can do this once only, and only before it expires.

To directly test the GraphQL API via GraphQL Explorer (`http://gdk.test:3000/-/graphql-explorer`),
get a reCAPTCHA response string via this form: `public/recaptcha.html` (`http://gdk.test:3000/recaptcha.html`):

```html
<html>
<head>
  <title>reCAPTCHA demo: Explicit render after an onload callback</title>
  <script type="text/javascript">
  var onloadCallback = function() {
    grecaptcha.render('html_element', {
      'sitekey' : '6Ld05AsaAAAAAMsm1yTUp4qsdFARN15rQJPPqv6i'
    });
  };
  function onSubmit() {
    window.document.getElementById('recaptchaResponse').innerHTML = grecaptcha.getResponse();
    return false;
  }
  </script>
</head>
<body>
<form onsubmit="return onSubmit()">
  <div id="html_element"></div>
  <br>
  <input type="submit" value="Submit">
</form>
<div>
  <h1>recaptchaResponse:</h1>
  <div id="recaptchaResponse"></div>
</div>
<script src="https://www.google.com/recaptcha/api.js?onload=onloadCallback&render=explicit"
        async defer>
</script>
</body>
</html>
```

## Spam/CAPTCHA API exploratory testing examples

These sections describe the steps needed to perform manual exploratory testing of
various scenarios of the Spam and CAPTCHA behavior for the REST and GraphQL APIs.

For the prerequisites, you must:

1. Perform all the steps listed above to enable Spam and CAPTCHA in the development environment,
   and force form submissions to require a CAPTCHA.
1. Ensure you have created an HTML page to render CAPTCHA under the `/public` directory,
   with a page that contains a form to manually generate a valid CAPTCHA response string.
   If you use **Google's official test reCAPTCHA credentials** listed in
   [Set up Akismet and reCAPTCHA](#set-up-akismet-and-recaptcha), the contents of the
   CAPTCHA response string don't matter.
1. Go to **Admin -> Settings -> Reporting -> Spam and Anti-bot protection**.
1. Select or clear **Enable reCAPTCHA** and **Enable Akismet** according to your
   scenario's needs.

The following examples use snippet creation as an example. You could also use
snippet updates, issue creation, or issue updates. Issues and snippets are the
only models with full Spam and CAPTCHA support.

### Initial setup

1. Create an API token.
1. Export it in your terminal for the REST commands: `export PRIVATE_TOKEN=<your_api_token>`
1. Ensure you are signed into the GitLab development environment at `localhost:3000` before using GraphiQL explorer,
   because it uses your authenticated user as authorization for running GraphQL queries.
1. For the GraphQL examples, use the GraphiQL explorer at `http://localhost:3000/-/graphql-explorer`.
1. Use the `--include` (`-i`) option to `curl` to print the HTTP response headers, including the status code.

### Scenario: Akismet and CAPTCHA enabled

In this example, Akismet and CAPTCHA are enabled:

1. [Initial request](#initial-request).

#### Initial request

This initial request fails because no CAPTCHA response is provided.

REST request:

```shell
curl --request POST --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "http://localhost:3000/api/v4/snippets?title=Title&file_name=FileName&content=Content&visibility=public"
```

REST response:

```shell
{"needs_captcha_response":true,"spam_log_id":42,"captcha_site_key":"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX","message":{"error":"Your snippet has been recognized as spam. Please, change the content or solve the reCAPTCHA to proceed."}}
```

GraphQL request:

```graphql
mutation {
    createSnippet(input: {
        title: "Title"
        visibilityLevel: public
        blobActions: [
            {
                action: create
                filePath: "BlobPath"
                content: "BlobContent"
            }
        ]
    }) {
        snippet {
            id
            title
        }
        errors
    }
}
```

GraphQL response:

```json
{
  "data": {
    "createSnippet": null
  },
  "errors": [
    {
      "message": "Request denied. Solve CAPTCHA challenge and retry",
      "locations": [
        {
          "line": 22,
          "column": 5
        }
      ],
      "path": [
        "createSnippet"
      ],
      "extensions": {
        "needs_captcha_response": true,
        "spam_log_id": 140,
        "captcha_site_key": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
      }
    }
  ]
}
```

#### Second request

This request succeeds because a CAPTCHA response is provided.

REST request:

```shell
export CAPTCHA_RESPONSE="<CAPTCHA response obtained from HTML page to render CAPTCHA>"
export SPAM_LOG_ID="<spam_log_id obtained from initial REST response>"
curl --request POST --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" --header "X-GitLab-Captcha-Response: $CAPTCHA_RESPONSE" --header "X-GitLab-Spam-Log-Id: $SPAM_LOG_ID" "http://localhost:3000/api/v4/snippets?title=Title&file_name=FileName&content=Content&visibility=public"
```

REST response:

```shell
{"id":42,"title":"Title","description":null,"visibility":"public", "other_fields": "..."}
```

GraphQL request:

NOTE:
The GitLab GraphiQL implementation doesn't allow passing of headers, so we must write
this as a `curl` query. Here, `--data-binary` is used to properly handle escaped double quotes
in the JSON-embedded query.

```shell
export CAPTCHA_RESPONSE="<CAPTCHA response obtained from HTML page to render CAPTCHA>"
export SPAM_LOG_ID="<spam_log_id obtained from initial REST response>"
curl --include "http://localhost:3000/api/graphql" --header "Authorization: Bearer $PRIVATE_TOKEN" --header "Content-Type: application/json" --header "X-GitLab-Captcha-Response: $CAPTCHA_RESPONSE" --header "X-GitLab-Spam-Log-Id: $SPAM_LOG_ID" --request POST --data-binary '{"query": "mutation {createSnippet(input: {title: \"Title\" visibilityLevel: public blobActions: [ { action: create filePath: \"BlobPath\" content: \"BlobContent\" } ] }) { snippet { id title } errors }}"}'
```

GraphQL response:

```json
{"data":{"createSnippet":{"snippet":{"id":"gid://gitlab/PersonalSnippet/42","title":"Title"},"errors":[]}}}
```

### Scenario: Akismet enabled, CAPTCHA disabled

For this scenario, ensure you clear **Enable reCAPTCHA** in the **Admin** area settings as described above.
If CAPTCHA is not enabled, any request flagged as potential spam fails with no chance to resubmit,
even if it could otherwise be resubmitted if CAPTCHA were enabled and successfully solved.

The REST request is the same as if CAPTCHA was enabled:

```shell
curl --request POST --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "http://localhost:3000/api/v4/snippets?title=Title&file_name=FileName&content=Content&visibility=public"
```

REST response:

```shell
{"message":{"error":"Your snippet has been recognized as spam and has been discarded."}}
```

GraphQL request:

```graphql
mutation {
    createSnippet(input: {
        title: "Title"
        visibilityLevel: public
        blobActions: [
            {
                action: create
                filePath: "BlobPath"
                content: "BlobContent"
            }
        ]
    }) {
        snippet {
            id
            title
        }
        errors
    }
}
```

GraphQL response:

```json
{
  "data": {
    "createSnippet": null
  },
  "errors": [
    {
      "message": "Request denied. Spam detected",
      "locations": [
        {
          "line": 22,
          "column": 5
        }
      ],
      "path": [
        "createSnippet"
      ],
      "extensions": {
        "spam": true
      }
    }
  ]
}
```

### Scenario: `allow_possible_spam` application setting enabled

With the `allow_possible_spam` application setting enabled, the API returns a 200 response. Any
valid request is successful and no CAPTCHA is presented, even if the request is considered
spam.

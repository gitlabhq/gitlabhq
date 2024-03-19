---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

The [logs](#read-the-logs) provide insight into what DAST is doing and expecting during the authentication process. For more detailed
information, configure the [authentication report](#configure-the-authentication-report).

For more information about particular error messages or situations see [known problems](#known-problems).

The browser-based analyzer is used to authenticate the user. For advanced troubleshooting, see [browser-based troubleshooting](browser_based_troubleshooting.md).

## Read the logs

The console output of the DAST CI/CD job shows information about the authentication process using the `AUTH` log module.
For example, the following log shows failed authentication for a multi-step login form.
Authentication failed because a home page should be displayed after login. Instead, the login form was still present.

```plaintext
2022-11-16T13:43:02.000 INF AUTH  attempting to authenticate
2022-11-16T13:43:02.000 INF AUTH  loading login page LoginURL=https://example.com/login
2022-11-16T13:43:10.000 INF AUTH  multi-step authentication detected
2022-11-16T13:43:15.000 INF AUTH  verifying if user submit was successful true_when="HTTP status code < 400"
2022-11-16T13:43:15.000 INF AUTH  requirement is satisfied, no login HTTP message detected want="HTTP status code < 400"
2022-11-16T13:43:20.000 INF AUTH  verifying if login attempt was successful true_when="HTTP status code < 400 and has authentication token and no login form found (no element found when searching using selector css:[id=email] or css:[id=password] or css:[id=submit])"
2022-11-24T14:43:20.000 INF AUTH  requirement is satisfied, HTTP login request returned status code 200 url=https://example.com/user/login?error=invalid%20credentials want="HTTP status code < 400"
2022-11-16T13:43:21.000 INF AUTH  requirement is unsatisfied, login form was found want="no login form found (no element found when searching using selector css:[id=email] or css:[id=password] or css:[id=submit])"
2022-11-16T13:43:21.000 INF AUTH  login attempt failed error="authentication failed: failed to authenticate user"
```

## Configure the authentication report

WARNING:
The authentication report can contain sensitive information such as the credentials used to perform the login.

An authentication report can be saved as a CI/CD job artifact to assist with understanding the cause of an authentication failure.

The report contains steps performed during the login process, HTTP requests and responses, the Document Object Model (DOM) and screenshots.

![dast-auth-report](img/dast_auth_report.jpg)

An example configuration where the authentication debug report is exported may look like the following:

```yaml
dast:
  variables:
    DAST_WEBSITE: "https://example.com"
    DAST_AUTH_REPORT: "true"
  artifacts:
    paths: [gl-dast-debug-auth-report.html]
    when: always
```

## Known problems

### Login form not found

DAST failed to find a login form when loading the login page, often because the authentication URL could not be loaded.
The log reports a fatal error such as:

```plaintext
2022-12-07T12:44:02.838 INF AUTH  loading login page LoginURL=[authentication URL]
2022-12-07T12:44:11.119 FTL MAIN  authentication failed: login form not found
```

Suggested actions:

- Generate the [authentication report](#configure-the-authentication-report) to inspect HTTP response.
- Check the target application authentication is deployed and running.
- Check the `DAST_AUTH_URL` is correct.
- Check the GitLab Runner can access the `DAST_AUTH_URL`.
- Check the `DAST_BROWSER_PATH_TO_LOGIN_FORM` is valid if used.

### Scan doesn't crawl authenticated pages

If DAST captures the wrong [authentication tokens](authentication.md#authentication-tokens) during the authentication process then
the scan can't crawl authenticated pages. Names of cookies and storage authentication tokens are written to the log. For example:

```plaintext
2022-11-24T14:42:31.492 INF AUTH  authentication token cookies names=["sessionID"]
2022-11-24T14:42:31.492 INF AUTH  authentication token storage events keys=["token"]
```

Suggested actions:

- Generate the [authentication report](#configure-the-authentication-report) and look at the screenshot from the `Login submit` to verify that the login worked as expected.
- Verify the logged authentication tokens are those used by your application.
- If using cookies to store authentication tokens, set the names of the authentication token cookies using `DAST_AUTH_COOKIES`.

### Unable to find elements with selector

DAST failed to find the username, password, first submit button, or submit button elements. The log reports a fatal error such as:

```plaintext
2022-12-07T13:14:11.545 FTL MAIN  authentication failed: unable to find elements with selector: css:#username
```

Suggested actions:

- Generate the [authentication report](#configure-the-authentication-report) to use the screenshot from the `Login page` to verify that the page loaded correctly.
- Load the login page in a browser and verify the [selectors](authentication.md#finding-an-elements-selector) configured in `DAST_USERNAME_FIELD`, `DAST_PASSWORD_FIELD`, `DAST_FIRST_SUBMIT_FIELD`, and `DAST_SUBMIT_FIELD` are correct.

### Failed to authenticate user

DAST failed to authenticate due to a failed login verification check. The log reports a fatal error such as:

```plaintext
2022-12-07T06:39:49.483 INF AUTH  verifying if login attempt was successful true_when="HTTP status code < 400 and has authentication token and no login form found (no element found when searching using selector css:[name=username] or css:[name=password] or css:button[type=\"submit\"])"
2022-12-07T06:39:49.484 INF AUTH  requirement is satisfied, HTTP login request returned status code 303 url=http://auth-manual:8090/login want="HTTP status code < 400"
2022-12-07T06:39:49.513 INF AUTH  requirement is unsatisfied, login form was found want="no login form found (no element found when searching using selector css:[name=username] or css:[name=password] or css:button[type=\"submit\"])"
2022-12-07T06:39:49.589 INF AUTH  login attempt failed error="authentication failed: failed to authenticate user"
2022-12-07T06:39:53.626 FTL MAIN  authentication failed: failed to authenticate user
```

Suggested actions:

- Look in the log for the `requirement is unsatisfied`. Respond to the appropriate error.

### Requirement unsatisfied, login form was found

Applications typically display a dashboard when the user logs in and the login form with an error message when the
username or password is incorrect.

This error occurs when DAST detects the login form on the page displayed after authenticating the user,
indicating that the login attempt failed.

```plaintext
2022-12-07T06:39:49.513 INF AUTH  requirement is unsatisfied, login form was found want="no login form found (no element found when searching using selector css:[name=username] or css:[name=password] or css:button[type=\"submit\"])"
```

Suggested actions:

- Verify that the username and password/authentication credentials used are correct.
- Generate the [authentication report](#configure-the-authentication-report) and verify the `Request` for the `Login submit` is correct.
- It's possible that the authentication report `Login submit` request and response are empty. This occurs when there is no request that would result
  in a full page reload, such as a request made when submitting a HTML form. This occurs when using websockets or AJAX to submit the login form.
- If the page displayed following user authentication genuinely has elements matching the login form selectors, configure `DAST_AUTH_VERIFICATION_URL`
  or `DAST_AUTH_VERIFICATION_SELECTOR` to use an alternate method of verifying the login attempt.

### Requirement unsatisfied, selector returned no results

DAST cannot find an element matching the selector provided in `DAST_AUTH_VERIFICATION_SELECTOR` on the page displayed following user login.

```plaintext
2022-12-07T06:39:33.239 INF AUTH  requirement is unsatisfied, searching DOM using selector returned no results want="has element css:[name=welcome]"
```

Suggested actions:

- Generate the [authentication report](#configure-the-authentication-report) and look at the screenshot from the `Login submit` to verify that the expected page is displayed.
- Ensure the `DAST_AUTH_VERIFICATION_SELECTOR` [selector](authentication.md#finding-an-elements-selector) is correct.

### Requirement unsatisfied, browser not at URL

DAST detected that the page displayed following user login has a URL different to what was expected according to `DAST_AUTH_VERIFICATION_URL`.

```plaintext
2022-12-07T11:28:00.241 INF AUTH  requirement is unsatisfied, browser is not at URL browser_url="https://example.com/home" want="is at url https://example.com/user/dashboard"
```

Suggested actions:

- Generate the [authentication report](#configure-the-authentication-report) and look at the screenshot from the `Login submit` to verify that the expected page is displayed.
- Ensure the `DAST_AUTH_VERIFICATION_URL` is correct.

### Requirement unsatisfied, HTTP login request status code

The HTTP response when loading the login form or submitting the form had a status code of 400 (client error)
or 500 (server error).

```plaintext
2022-12-07T06:39:53.626 INF AUTH  requirement is unsatisfied, HTTP login request returned status code 502 url="https://example.com/user/login" want="HTTP status code < 400"
```

- Verify that the username and password/authentication credentials used are correct.
- Generate the [authentication report](#configure-the-authentication-report) and verify the `Request` for the `Login submit` is correct.
- Verify the target application works as expected.

### Requirement unsatisfied, no authentication token

DAST could not detect an [authentication token](authentication.md#authentication-tokens) created during the authentication process.

```plaintext
2022-12-07T11:25:29.010 INF AUTH  authentication token cookies names=[]
2022-12-07T11:25:29.010 INF AUTH  authentication token storage events keys=[]
2022-12-07T11:25:29.010 INF AUTH  requirement is unsatisfied, no basic authentication, cookie or storage event authentication token detected want="has authentication token"
```

Suggestion actions:

- Generate the [authentication report](#configure-the-authentication-report) and look at the screenshot from the `Login submit` to verify that the login worked as expected.
- Using the browser's developer tools, investigate the cookies and local/session storage objects created while logging in. Ensure there is an authentication token created with sufficiently random value.
- If using cookies to store authentication tokens, set the names of the authentication token cookies using `DAST_AUTH_COOKIES`.

---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference, howto
title: Authentication
---

For complete coverage, the DAST analyzer must authenticate with the application being tested. This
requires configuring the authentication credentials and authentication method in the DAST CI/CD job.

DAST requires authentication to:

- Simulate real-world attacks and identify vulnerabilities that might be exploited by
  attackers.
- Test user-specific features and custom behavior that may only be visible after authentication.

The DAST job authenticates itself to the application, most commonly by filling in and submitting a
login form on a browser. After the form is submitted, the DAST job confirms that authentication was
successful. If authentication was successful, the DAST job continues and also saves the credentials
for reuse when crawling the target application. If not, the DAST job stops.

Authentication methods supported by DAST include:

- Single-step login form
- Multi-step login form
- Authenticating to URLs outside the configured target URL

When choosing authentication credentials:

- **DO NOT** use credentials that are valid for production systems, production servers, or used to access production data.
- **DO NOT** run an authenticated scan against a production server. Authenticated scans may perform
  **any** function that the authenticated user can, including modifying or deleting data, submitting
  forms, and following links. Only run an authenticated scan against non-production systems or
  servers.
- Provide credentials that allow DAST to test the entire application.
- Note the credentials' expiry date, if any, for future reference. For example, with a password
  manager such as 1Password.

## Getting started

NOTE:
You should periodically confirming that the analyzer's authentication is still working, as this tends to break over
time due to changes to the application.

To run a DAST authenticated scan:

- Read the [prerequisite](#prerequisites) conditions for authentication.
- [Update your target website](#update-the-target-website) to a landing page of an authenticated user.
- If your login form has the username, password and submit button on a single page, use the [CI/CD variables](#available-cicd-variables) to configure [single-step](#configuration-for-a-single-step-login-form) login form authentication.
- If your login form has the username and password fields on different pages, use the [CI/CD variables](#available-cicd-variables) to configure [multi-step](#configuration-for-a-multi-step-login-form) login form authentication.
- Make sure the user isn't [logged out](#excluding-logout-urls) during the scan.

### Prerequisites

- You have the username and password of the user you would like to authenticate as during the scan.
- You have checked the [known issues](#known-issues) to ensure DAST can authenticate to your application.
- You have satisfied the prerequisites if you're using [form authentication](#form-authentication).
- You have thought about how you can [verify](#verifying-authentication-is-successful) whether or not authentication was successful.

#### Form authentication

- You know the URL of the login form of your application. Alternatively, you know how to go to the login form from the authentication URL (see [clicking to go to the login form](#clicking-to-go-to-the-login-form)).
- You know the [selectors](#finding-an-elements-selector) of the username and password HTML fields that DAST uses to input the respective values.
- You know the element's [selector](#finding-an-elements-selector) that submits the login form when selected.

### Available CI/CD variables

| CI/CD variable                       | Type                                        | Description                                                                                                                                                                                                                                                                         |
|:-------------------------------------|:--------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `DAST_AUTH_AFTER_LOGIN_ACTIONS`      | string                                      | A comma-separated list of actions to be run after login but before login verification. Currently supports "click" actions. Example: `click(on=id:change_to_bar_graph),click(on=css:input[name=username])`.                                                                          |
| `DAST_AUTH_BEFORE_LOGIN_ACTIONS`     | [selector](#finding-an-elements-selector)   | A comma-separated list of selectors representing elements to click on prior to entering the `DAST_AUTH_USERNAME` and `DAST_AUTH_PASSWORD` into the login form. Example: `"css:.navigation-menu,css:.login-menu-item"`.                                                              |
| `DAST_AUTH_CLEAR_INPUT_FIELDS`       | boolean                                     | Disables clearing of username and password fields before attempting manual login. Set to `false` by default.                                                                                                                                                                        |
| `DAST_AUTH_COOKIE_NAMES`             | string                                      | Set to a comma-separated list of cookie names to specify which cookies are used for authentication.                                                                                                                                                                                 |
| `DAST_AUTH_FIRST_SUBMIT_FIELD`       | [selector](#finding-an-elements-selector)   | A selector describing the element that is clicked on to submit the username form of a multi-page login process. Example, `css:button[type='user-submit']`.                                                                                                                          |
| `DAST_AUTH_PASSWORD_FIELD`           | [selector](#finding-an-elements-selector)   | A selector describing the element used to enter the password on the login form. Example: `id:password`                                                                                                                                                                              |
| `DAST_AUTH_PASSWORD`                 | string                                      | The password to authenticate to in the website. Example: `P@55w0rd!`.                                                                                                                                                                                                               |
| `DAST_AUTH_REPORT`                   | boolean                                     | Set to `true` to generate a report detailing steps taken during the authentication process. You must also define `gl-dast-debug-auth-report.html` as a CI job artifact to be able to access the generated report. The report's content aids when debugging authentication failures. |
| `DAST_AUTH_SUBMIT_FIELD`             | [selector](#finding-an-elements-selector)   | A selector describing the element clicked on to submit the login form for a single-page login form, or the password form for a multi-page login form. Example: `css:button[type='submit']`.                                                                                         |
| `DAST_AUTH_SUCCESS_IF_AT_URL`        | URL                                         | A URL that is compared to the URL in the browser to determine if authentication has succeeded after the login form is submitted. Example: `"https://example.com/loggedin_page"`.                                                                                                    |
| `DAST_AUTH_SUCCESS_IF_ELEMENT_FOUND` | [selector](#finding-an-elements-selector)   | A selector describing an element whose presence is used to determine if authentication has succeeded after the login form is submitted. Example: `css:.user-photo`.                                                                                                                 |
| `DAST_AUTH_SUCCESS_IF_NO_LOGIN_FORM` | boolean                                     | Verifies successful authentication by checking for the absence of a login form after the login form has been submitted.                                                                                                                                                             |
| `DAST_AUTH_TYPE`                     | string                                      | The authentication type to use. Example: `basic-digest`.                                                                                                                                                                                                                            |
| `DAST_AUTH_URL`                      | URL                                         | The URL of the page containing the login form on the target website. `DAST_AUTH_USERNAME` and `DAST_AUTH_PASSWORD` are submitted with the login form to create an authenticated scan. Example: `https://login.example.com`.                                                         |
| `DAST_AUTH_USERNAME_FIELD`           | [selector](#finding-an-elements-selector)   | A selector describing the element used to enter the username on the login form. Example: `name:username`.                                                                                                                                                                           |
| `DAST_AUTH_USERNAME`                 | string                                      | The username to authenticate to in the website. Example: `admin`.                                                                                                                                                                                                                   |
| `DAST_SCOPE_EXCLUDE_URLS`            | URLs                                        | The URLs to skip during the authenticated scan; comma-separated. Regular expression syntax can be used to match multiple URLs. For example, `.*` matches an arbitrary character sequence.                                                                                           |

### Update the target website

The target website, defined using the CI/CD variable `DAST_TARGET_URL`, is the URL DAST uses to begin crawling your application.

For best crawl results on an authenticated scan, the target website should be a URL accessible only after the user is authenticated.
Often, this is the URL of the page the user lands on after they're logged in.

For example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com/dashboard/welcome"
    DAST_AUTH_URL: "https://example.com/login"
```

### Configuration for HTTP authentication

To use an [HTTP authentication scheme](https://www.chromium.org/developers/design-documents/http-authentication/) such as Basic Authentication you can set the `DAST_AUTH_TYPE` value to `basic-digest`.
Other schemes such as Negotiate or NTLM may work but aren't officially supported due to current lack of automated test coverage.

Configuration requires the CI/CD variables `DAST_AUTH_TYPE`, `DAST_AUTH_URL`, `DAST_AUTH_USERNAME`, `DAST_AUTH_PASSWORD` to be defined for the DAST job. If you don't have a unique login URL, set `DAST_AUTH_URL` to the same URL as `DAST_TARGET_URL`.

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_TYPE: "basic-digest"
    DAST_AUTH_URL: "https://example.com"
```

Do **not** define `DAST_AUTH_USERNAME` and `DAST_AUTH_PASSWORD` in the YAML job definition file as this could present a security risk. Instead, create them as masked CI/CD variables using the GitLab UI.
See [Custom CI/CD variables](../../../../../ci/variables/_index.md#for-a-project) for more information.

### Configuration for a single-step login form

A single-step login form has all login form elements on a single page.
Configuration requires the CI/CD variables `DAST_AUTH_URL`, `DAST_AUTH_USERNAME`, `DAST_AUTH_USERNAME_FIELD`, `DAST_AUTH_PASSWORD`, `DAST_AUTH_PASSWORD_FIELD`, and `DAST_AUTH_SUBMIT_FIELD` to be defined for the DAST job.

You should set up the URL and selectors of fields in the job definition YAML, for example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_URL: "https://example.com/login"
    DAST_AUTH_USERNAME_FIELD: "css:[name=username]"
    DAST_AUTH_PASSWORD_FIELD: "css:[name=password]"
    DAST_AUTH_SUBMIT_FIELD: "css:button[type=submit]"
```

Do **not** define `DAST_AUTH_USERNAME` and `DAST_AUTH_PASSWORD` in the YAML job definition file as this could present a security risk. Instead, create them as masked CI/CD variables using the GitLab UI.
See [Custom CI/CD variables](../../../../../ci/variables/_index.md#for-a-project) for more information.

### Configuration for a multi-step login form

A multi-step login form has two pages. The first page has a form with the username and a next submit button.
If the username is valid, a second form on the subsequent page has the password and the form submit button.

Configuration requires the CI/CD variables to be defined for the DAST job:

- `DAST_AUTH_URL`
- `DAST_AUTH_USERNAME`
- `DAST_AUTH_USERNAME_FIELD`
- `DAST_AUTH_FIRST_SUBMIT_FIELD`
- `DAST_AUTH_PASSWORD`
- `DAST_AUTH_PASSWORD_FIELD`
- `DAST_AUTH_SUBMIT_FIELD`.

You should set up the URL and selectors of fields in the job definition YAML, for example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_URL: "https://example.com/login"
    DAST_AUTH_USERNAME_FIELD: "css:[name=username]"
    DAST_AUTH_FIRST_SUBMIT_FIELD: "css:button[name=next]"
    DAST_AUTH_PASSWORD_FIELD: "css:[name=password]"
    DAST_AUTH_SUBMIT_FIELD: "css:button[type=submit]"
```

Do **not** define `DAST_AUTH_USERNAME` and `DAST_AUTH_PASSWORD` in the YAML job definition file as this could present a security risk. Instead, create them as masked CI/CD variables using the GitLab UI.
See [Custom CI/CD variables](../../../../../ci/variables/_index.md#for-a-project) for more information.

### Configuration for Single Sign-On (SSO)

If a user can sign in to an application, then in most cases, DAST is also able to sign in.
Even when an application uses Single Sign-on. Applications using SSO solutions should configure DAST
authentication using the [single-step](#configuration-for-a-single-step-login-form) or [multi-step](#configuration-for-a-multi-step-login-form) login form configuration guides.

DAST supports authentication processes where a user is redirected to an external Identity Provider's site to sign in.
Check the [known issues](#known-issues) of DAST authentication to determine if your SSO authentication process is supported.

### Configuration for Windows integrated authentication (Kerberos)

Windows integrated authentication (Kerberos) is a common authentication mechanism for line of business (LOB) applications hosted inside a Windows domain. It provides promptless authentication using the user's computer login.

To configure this form of authentication perform the following steps:

1. Collect the necessary information with assistance from your IT/operations team.
1. Create or update the `dast` job definition in your `.gitlab-ci.yml` file.
1. Populate the example `krb5.conf` file using the information collected.
1. Set the necessary job variables.
1. Set the necessary secret variables by using the project **Settings** page.
1. Test and verify authentication is functioning.

Collect the following information with assistance from your IT/Operations department:

- Name of Windows domain or Kerberos Realm (must have a period in the name like `EXAMPLE.COM`)
- Hostname for Windows/Kerberos domain controller
- For Kerberos the auth server name. For Windows domains this is the domain controller.

Create the `krb5.conf` file:

```ini
[libdefaults]
  # Realm is another name for domain name
  default_realm = EXAMPLE.COM
  # These settings are not needed for Windows Domains
  # they support other Kerberos implementations
  kdc_timesync = 1
  ccache_type = 4
  forwardable = true
  proxiable = true
  rdns = false
  fcc-mit-ticketflags = true
[realms]
  EXAMPLE.COM = {
    # Domain controller or KDC
    kdc = kdc.example.com
    # Domain controller or admin server
    admin_server = kdc.example.com
  }
[domain_realm]
  # Mapping DNS domains to realms/Windows domain
  # DNS domains provided by DAST_AUTH_NEGOTIATE_DELEGATION
  # should also be represented here (but without the wildcard)
  .example.com = EXAMPLE.COM
  example.com = EXAMPLE.COM
```

This configuration makes use of the `DAST_AUTH_NEGOTIATE_DELEGATION` variable.
This variable sets the following Chromium policies needed to allow integrated authentication:

- [AuthServerAllowlist](https://chromeenterprise.google/policies/#AuthServerAllowlist)
- [AuthNegotiateDelegateAllowlist](https://chromeenterprise.google/policies/#AuthNegotiateDelegateAllowlist)

The settings for this variable are the DNS domains associated with your Windows domain or Kerberos realm.
You should provide them:

- In both lower case and also upper case.
- With a wildcard pattern and just the domain name.

For our example the Windows domain is `EXAMPLE.COM` and the DNS domain is `example.com`.
This gives us a value of `*.example.com,example.com,*.EXAMPLE.COM,EXAMPLE.COM` for `DAST_AUTH_NEGOTIATE_DELEGATION`.

Pull it all together into a job definition:

```yaml
# This job will extend the dast job defined in
# the DAST template which must also be included.
dast:
  image:
    name: "$SECURE_ANALYZERS_PREFIX/dast:$DAST_VERSION$DAST_IMAGE_SUFFIX"
    docker:
      user: root
  variables:
    DAST_TARGET_URL: https://target.example.com
    DAST_AUTH_URL: https://target.example.com
    DAST_AUTH_TYPE: basic-digest
    DAST_AUTH_NEGOTIATE_DELEGATION: *.example.com,example.com,*.EXAMPLE.COM,EXAMPLE.COM
    # Not shown -- DAST_AUTH_USERNAME, DAST_AUTH_PASSWORD set via Settings -> CI -> Variables
  before_script:
    - KRB5_CONF='
[libdefaults]
  default_realm = EXAMPLE.COM
  kdc_timesync = 1
  ccache_type = 4
  forwardable = true
  proxiable = true
  rdns = false
  fcc-mit-ticketflags = true
[realms]
  EXAMPLE.COM = {
    kdc = ad1.example.com
    admin_server = ad1.example.com
  }
[domain_realm]
  .example.com = EXAMPLE.COM
  example.com = EXAMPLE.COM
'
    - cat "$KRB5_CONF" > /etc/krb5.conf
    - echo '$DAST_AUTH_PASSWORD' | kinit $DAST_AUTH_USERNAME
    - klist
```

Expected output:

The job console output contains the output from the `before` script. It will look similar to the following if authentication was successful. The job should fail if it was unsuccessful without running a scan.

```plaintext
Password for mike@EXAMPLE.COM:
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: mike@EXAMPLE.COM

Valid starting       Expires              Service principal
11/11/2024 21:50:50  11/12/2024 07:50:50  krbtgt/EXAMPLE.COM@EXAMPLE.COM
        renew until 11/12/2024 21:50:50
```

The DAST scanner will also output the following, indicating success:

```log
2024-11-08T17:03:09.226 INF AUTH  attempting to authenticate find_auth_fields="basic-digest"
2024-11-08T17:03:09.226 INF AUTH  loading login page LoginURL="https://target.example.com"
2024-11-08T17:03:10.619 INF AUTH  verifying if login attempt was successful true_when="HTTP status code < 400 and has authentication token and no login form found (auto-detected)"
2024-11-08T17:03:10.619 INF AUTH  requirement is satisfied, HTTP login request returned status code 200 want="HTTP status code < 400" url="https://target.example.com/"
2024-11-08T17:03:10.623 INF AUTH  requirement is satisfied, did not detect a login form want="no login form found (auto-detected)"
2024-11-08T17:03:10.623 INF AUTH  authentication token cookies names=""
2024-11-08T17:03:10.623 INF AUTH  authentication token storage events keys=""
2024-11-08T17:03:10.623 INF AUTH  requirement is satisfied, basic authentication detected want="has authentication token"
2024-11-08T17:03:11.230 INF AUTH  login attempt succeeded
```

### Clicking to go to the login form

Define `DAST_AUTH_BEFORE_LOGIN_ACTIONS` to provide a path of elements to click on from the `DAST_AUTH_URL` so that DAST can access the
login form. This method is suitable for applications that show the login form in a pop-up (modal) window or when the login form does not
have a unique URL.

For example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_URL: "https://example.com/login"
    DAST_AUTH_BEFORE_LOGIN_ACTIONS: "css:.navigation-menu,css:.login-menu-item"
```

### Excluding logout URLs

If DAST crawls the logout URL while running an authenticated scan, the user is logged out, resulting in the remainder of the scan being unauthenticated.
It is therefore recommended to exclude logout URLs using the CI/CD variable `DAST_SCOPE_EXCLUDE_URLS`. DAST isn't accessing any excluded URLs, ensuring the user remains logged in.

Provided URLs can be either absolute URLs, or regular expressions of URL paths relative to the base path of the `DAST_TARGET_URL`. For example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com/welcome/home"
    DAST_SCOPE_EXCLUDE_URLS: "https://example.com/logout,/user/.*/logout"
```

### Finding an element's selector

Selectors are used by CI/CD variables to specify the location of an element displayed on a page in a browser.
Selectors have the format `type`:`search string`. DAST searches for the selector using the search string based on the type.

| Selector type | Example                            | Description                                                                                                                                                                                           |
|---------------|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `css`         | `css:.password-field`              | Searches for a HTML element having the supplied CSS selector. Selectors should be as specific as possible for performance reasons.                                                                    |
| `id`          | `id:element`                       | Searches for an HTML element with the provided element ID.                                                                                                                                            |
| `name`        | `name:element`                     | Searches for an HTML element with the provided element name.                                                                                                                                          |
| `xpath`       | `xpath://input[@id="my-button"]/a` | Searches for a HTML element with the provided XPath. XPath searches are expected to be less performant than other searches.                                                                           |

#### Find selectors with Google Chrome

Chrome DevTools element selector tool is an effective way to find a selector.

1. Open Chrome and go to the page where you would like to find a selector, for example, the login page for your site.
1. Open the `Elements` tab in Chrome DevTools with the keyboard shortcut `Command + Shift + c` in macOS or `Ctrl + Shift + c` in Windows or Linux.
1. Select the `Select an element in the page to select it` tool.
   ![search-elements](../img/dast_auth_browser_scan_search_elements_v16_9.png)
1. Select the field on your page that you would like to know the selector for.
1. After the tool is active, highlight a field you wish to view the details of.
   ![highlight](../img/dast_auth_browser_scan_highlight_v16_9.png)
1. Once highlighted, you can see the element's details, including attributes that would make a good candidate for a selector.

In this example, the `id="user_login"` appears to be a good candidate. You can use this as a selector as the DAST username field by setting
`DAST_AUTH_USERNAME_FIELD: "id:user_login"`.

#### Choose the right selector

Judicious choice of selector leads to a scan that is resilient to the application changing.

In order of preference, you should choose as selectors:

- `id` fields. These fields generally unique on a page, and rarely change.
- `name` fields. These fields generally unique on a page, and rarely change.
- `class` values specific to the field, such as the selector `"css:.username"` for the `username` class on the username field.
- Presence of field specific data attributes, such as the selector, `"css:[data-username]"` when the `data-username` field has any value on the username field.
- Multiple `class` hierarchy values, such as the selector `"css:.login-form .username"` when there are multiple elements with class `username` but only one nested inside the element with the class `login-form`.

When using selectors to locate specific fields you should avoid searching on:

- Any `id`, `name`, `attribute`, `class` or `value` that is dynamically generated.
- Generic class names, such as `column-10` and `dark-grey`.
- XPath searches as they are less performant than other selector searches.
- Unscoped searches, such as those beginning with `css:*` and `xpath://*`.

## Verifying authentication is successful

After DAST has submitted the login form, a verification process takes place
to determine if authentication succeeded. The scan halts with an error if authentication is unsuccessful.

Following the submission of the login form, authentication is determined to be unsuccessful when:

- The login submit HTTP response has a `400` or `500` series status code.
- Any [verification check](#verification-checks) fails.
- An [authentication token](#authentication-tokens) with a sufficiently random value is not set during the authentication process.

### Verification checks

Verification checks run checks on the state of the browser once authentication is complete
to determine further if authentication succeeded.

DAST tests for the absence of a login form if no verification checks are configured.

#### Verify based on the URL

Define `DAST_AUTH_SUCCESS_IF_AT_URL` as the URL displayed in the browser tab after the login form is successfully submitted.

DAST compares the verification URL to the URL in the browser after authentication.
If they are not the same, authentication is unsuccessful.

For example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_SUCCESS_IF_AT_URL: "https://example.com/user/welcome"
```

#### Verify based on presence of an element

Define `DAST_AUTH_SUCCESS_IF_ELEMENT_FOUND` as a [selector](#finding-an-elements-selector) that finds one or many elements on the page
displayed after the login form is successfully submitted. If no element is found, authentication is unsuccessful.
Searching for the selector on the page displayed when login fails should return no elements.

For example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_SUCCESS_IF_ELEMENT_FOUND: "css:.welcome-user"
```

#### Verify based on absence of a login form

Define `DAST_AUTH_SUCCESS_IF_NO_LOGIN_FORM` as `"true"` to indicate that DAST should search for the login form on the
page displayed after the login form is successfully submitted. If a login form is still present after logging in, authentication is unsuccessful.

For example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_SUCCESS_IF_NO_LOGIN_FORM: "true"
```

### Authentication tokens

DAST records authentication tokens set during the authentication process.
Authentication tokens are loaded into new browsers when DAST opens them so the user can remain logged in throughout the scan.

To record tokens, DAST takes a snapshot of cookies, local storage, and session storage values set by the application before
the authentication process. DAST does the same after authentication and uses the difference to determine which were created
by the authentication process.

DAST considers cookies, local storage and session storage values set with sufficiently "random" values to be authentication tokens.
For example, `sessionID=HVxzpS8GzMlPAc2e39uyIVzwACIuGe0H` would be viewed as an authentication token, while `ab_testing_group=A1` would not.

The CI/CD variable `DAST_AUTH_COOKIE_NAMES` can be used to specify the names of authentication cookies and bypass the randomness check used by DAST.
Not only can this make the authentication process more robust, but it can also increase vulnerability check accuracy for checks that
inspect authentication tokens.

For example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_COOKIE_NAMES: "sessionID,refreshToken"
```

## Known issues

- DAST cannot bypass a CAPTCHA if the authentication flow includes one. Turn these off in the testing environment for the application being scanned.
- DAST cannot handle multi-factor authentication like one-time passwords (OTP) by using SMS, biometrics, or authenticator apps. Turn these off in the testing environment for the application being scanned.
- DAST cannot authenticate to applications that do not set an [authentication token](#authentication-tokens) during login.
- DAST cannot authenticate to applications that require more than two inputs to be filled out. Two inputs must be supplied, username and password.

## Troubleshooting

The [logs](#read-the-logs) provide insight into what DAST is doing and expecting during the authentication process. For more detailed
information, configure the [authentication report](#configure-the-authentication-report).

For more information about particular error messages or situations see [known problems](#known-problems).

The browser-based analyzer is used to authenticate the user. For advanced troubleshooting, see [browser-based troubleshooting](../troubleshooting.md).

### Read the logs

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

### Configure the authentication report

WARNING:
The authentication report can contain sensitive information such as the credentials used to perform the login.

An authentication report can be saved as a CI/CD job artifact to assist with understanding the cause of an authentication failure.

The report contains steps performed during the login process, HTTP requests and responses, the Document Object Model (DOM) and screenshots.

![dast-auth-report](../img/dast_auth_report_v16_9.jpg)

An example configuration where the authentication debug report is exported may look like the following:

```yaml
dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_REPORT: "true"
```

### Known problems

#### Login form not found

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
- Check the `DAST_AUTH_BEFORE_LOGIN_ACTIONS` is valid if used.

#### Scan doesn't crawl authenticated pages

If DAST captures the wrong [authentication tokens](#authentication-tokens) during the authentication process then
the scan can't crawl authenticated pages. Names of cookies and storage authentication tokens are written to the log. For example:

```plaintext
2022-11-24T14:42:31.492 INF AUTH  authentication token cookies names=["sessionID"]
2022-11-24T14:42:31.492 INF AUTH  authentication token storage events keys=["token"]
```

Suggested actions:

- Generate the [authentication report](#configure-the-authentication-report) and look at the screenshot from the `Login submit` to verify that the login worked as expected.
- Verify the logged authentication tokens are those used by your application.
- If using cookies to store authentication tokens, set the names of the authentication token cookies using `DAST_AUTH_COOKIE_NAMES`.

#### Unable to find elements with selector

DAST failed to find the username, password, first submit button, or submit button elements. The log reports a fatal error such as:

```plaintext
2022-12-07T13:14:11.545 FTL MAIN  authentication failed: unable to find elements with selector: css:#username
```

Suggested actions:

- Generate the [authentication report](#configure-the-authentication-report) to use the screenshot from the `Login page` to verify that the page loaded correctly.
- Load the login page in a browser and verify the [selectors](#finding-an-elements-selector) configured in `DAST_AUTH_USERNAME_FIELD`, `DAST_AUTH_PASSWORD_FIELD`, `DAST_AUTH_FIRST_SUBMIT_FIELD`, and `DAST_AUTH_SUBMIT_FIELD` are correct.

#### Failed to authenticate user

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

#### Requirement unsatisfied, login form was found

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
- If the page displayed following user authentication genuinely has elements matching the login form selectors, configure `DAST_AUTH_SUCCESS_IF_AT_URL`
  or `DAST_AUTH_SUCCESS_IF_ELEMENT_FOUND` to use an alternate method of verifying the login attempt.

#### Requirement unsatisfied, selector returned no results

DAST cannot find an element matching the selector provided in `DAST_AUTH_SUCCESS_IF_ELEMENT_FOUND` on the page displayed following user login.

```plaintext
2022-12-07T06:39:33.239 INF AUTH  requirement is unsatisfied, searching DOM using selector returned no results want="has element css:[name=welcome]"
```

Suggested actions:

- Generate the [authentication report](#configure-the-authentication-report) and look at the screenshot from the `Login submit` to verify that the expected page is displayed.
- Ensure the `DAST_AUTH_SUCCESS_IF_ELEMENT_FOUND` [selector](#finding-an-elements-selector) is correct.

#### Requirement unsatisfied, browser not at URL

DAST detected that the page displayed following user login has a URL different to what was expected according to `DAST_AUTH_SUCCESS_IF_AT_URL`.

```plaintext
2022-12-07T11:28:00.241 INF AUTH  requirement is unsatisfied, browser is not at URL browser_url="https://example.com/home" want="is at url https://example.com/user/dashboard"
```

Suggested actions:

- Generate the [authentication report](#configure-the-authentication-report) and look at the screenshot from the `Login submit` to verify that the expected page is displayed.
- Ensure the `DAST_AUTH_SUCCESS_IF_AT_URL` is correct.

#### Requirement unsatisfied, HTTP login request status code

The HTTP response when loading the login form or submitting the form had a status code of 400 (client error)
or 500 (server error).

```plaintext
2022-12-07T06:39:53.626 INF AUTH  requirement is unsatisfied, HTTP login request returned status code 502 url="https://example.com/user/login" want="HTTP status code < 400"
```

- Verify that the username and password/authentication credentials used are correct.
- Generate the [authentication report](#configure-the-authentication-report) and verify the `Request` for the `Login submit` is correct.
- Verify the target application works as expected.

#### Requirement unsatisfied, no authentication token

DAST could not detect an [authentication token](#authentication-tokens) created during the authentication process.

```plaintext
2022-12-07T11:25:29.010 INF AUTH  authentication token cookies names=[]
2022-12-07T11:25:29.010 INF AUTH  authentication token storage events keys=[]
2022-12-07T11:25:29.010 INF AUTH  requirement is unsatisfied, no basic authentication, cookie or storage event authentication token detected want="has authentication token"
```

Suggestion actions:

- Generate the [authentication report](#configure-the-authentication-report) and look at the screenshot from the `Login submit` to verify that the login worked as expected.
- Using the browser's developer tools, investigate the cookies and local/session storage objects created while logging in. Ensure there is an authentication token created with sufficiently random value.
- If using cookies to store authentication tokens, set the names of the authentication token cookies using `DAST_AUTH_COOKIE_NAMES`.

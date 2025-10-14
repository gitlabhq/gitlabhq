---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Authentication scripts
---

DAST authentication scripts provide a flexible, JavaScript-based approach to handle authentication flows of varying complexity.
Automate sign-in processes using custom scripts that integrate seamlessly with DAST security scanning.

Authentication scripts use JavaScript with custom methods designed specifically for DAST operations.
These scripts can handle basic username and password authentication, as well as complex multi-factor authentication flows with support for time-based, one-time passwords (TOTP).

Authentication script integration includes:

- Support for authentication workflows of various complexities.
- JavaScript-based scripting using custom DAST methods.
- Seamless integration with existing DAST scanning processes.
- Built-in support for one-time passwords and TOTP generation.
- Access to environment variables for secure credential management.
- Support for all HTML form elements, including text inputs, radio buttons, checkboxes, and dropdown lists.
- Consistent selector syntax with other DAST variables.
- Comprehensive logging for debugging authentication flows.

Although the scripting language is JavaScript, scripts don't have access to the browser or common modules.

## Configure scripts

To use authentication scripts with DAST, configure the following variables:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://your-app.example.com"
    DAST_AUTH_SCRIPT: "auth_script.js"
```

The following configuration options are available:

| Variable | Description | Required |
|----------|-------------|----------|
| `DAST_AUTH_SCRIPT` | Path to your authentication script file (local file or URL) | Yes |

No other authentication variables are required when using `DAST_AUTH_SCRIPT`.
Existing success and failure variables are optional and work if specified.

## Example scripts

This basic authentication script signs into an application:

```javascript
// Navigate to the login page
doc.navigateURL("https://example.com/login")

// Fill in username and password from environment variables
doc.actionFormInput("id:username", process.env.USERNAME)
doc.actionFormInput("id:password", process.env.PASSWORD)

// Submit the login form
doc.actionLeftClick("css:button[type=\"submit\"]")

// Verify successful authentication
auth.successIfAtURL("https://example.com/dashboard")
```

For an application that requires two-factor authentication:

```javascript
// Initial login steps
doc.navigateURL("https://example.com/login")
doc.actionFormInput("id:email", process.env.USER_EMAIL)
doc.actionFormInput("id:password", process.env.USER_PASSWORD)
doc.actionLeftClick("id:login-button")

// Handle TOTP if required
const totpCode = otp.generateTOTP()
doc.actionFormInput("id:totp-code", totpCode)
doc.actionLeftClick("id:verify-button")

// Confirm successful authentication
auth.successIfAtURL("https://example.com/app/home")
```

To run a script, add the following to your CI/CD configuration:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_SCRIPT: "auth_script.js"
```

If you use the `otp.generateTOTP()` method, make sure to add the `DAST_AUTH_OTP_KEY` variable
to your CI/CD configuration as well.

## Document interaction methods

| Method | Description |
|--------|-------------|
| `doc.getURL()` | Get the current page URL. |
| `doc.navigateURL(url)` | Go to a specific URL. |
| `doc.actionFormInput(path, value)` | Enter text into form input fields. |
| `doc.actionFormSelectOption(optionPath)` | Select dropdown list option. |
| `doc.actionFormRadioButton(buttonPath)` | Select radio button. |
| `doc.actionFormCheckbox(checkboxPath)` | Toggle a checkbox. |
| `doc.actionFormSubmit(formPath)` | Submit a form. |
| `doc.actionLeftClick(onPath)` | Perform left-mouse click. |

### `doc.getURL()`

Returns the current page URL as a string.

Usage:

Retrieve the current browser location, which is helpful for conditional logic or debugging.

Example:

```javascript
// Navigate to login page
doc.navigateURL("https://example.com/login")

// Get current URL for logging or validation
const currentUrl = doc.getURL()
log.info("Currently at: " + currentUrl)

// Use current URL for conditional logic
if (currentUrl.includes("/login")) {
    log.info("On login page, proceeding with authentication")
    doc.actionFormInput("id:username", process.env.USERNAME)
}
```

### `doc.navigateURL(url)`

Navigates the browser to the specified URL.

Parameters:

- `url` (string): The target URL to go to.

Usage:

Direct the browser to specific pages during the authentication flow. This is typically the first action in most authentication scripts.

Example:

```javascript
// Navigate to the main login page
doc.navigateURL("https://app.example.com/auth/login")

// For multi-step authentication, navigate to different pages
doc.navigateURL("https://app.example.com/auth/two-factor")

// Navigate to a specific tenant or subdomain
doc.navigateURL("https://tenant1.example.com/login")
```

### `doc.actionFormInput(path, value)`

Enters text into form input fields such as text boxes, password fields, email fields, and text areas.

Parameters:

- `path` (string): Element selector path using DAST selector syntax.
- `value` (string): Text value to enter into the field.

Usage:

This is the primary method for filling out sign-in forms, search boxes, and other text-based input fields.

Example:

```javascript
// Basic login form inputs
doc.actionFormInput("id:username", process.env.USERNAME)
doc.actionFormInput("id:password", process.env.PASSWORD)

// Using different selector types
doc.actionFormInput("name:email", "user@example.com")
doc.actionFormInput("css:input[placeholder='Enter your API key']", process.env.API_KEY)
doc.actionFormInput("xpath://input[@data-testid='login-field']", "testuser")

// Multi-step authentication
doc.actionFormInput("id:verification-code", "123456")
doc.actionFormInput("css:.otp-input", otp.generateTOTP())

// Search or filter fields
doc.actionFormInput("css:input[type='search']", "product name")
```

### `doc.actionFormSelectOption(optionPath)`

Selects an option from dropdown lists.

Parameters:

- `optionPath` (string): Element selector path pointing to the option to select.

Usage:

Select a specific option from a dropdown list, like a language or tenant.

Example:

```javascript
// Select a specific tenant from dropdown
doc.actionFormSelectOption("css:option[value='tenant-prod']")

// Select by visible text content
doc.actionFormSelectOption("xpath://option[text()='Production Environment']")

// Select user role
doc.actionFormSelectOption("id:role-admin")

// Select from a country dropdown
doc.actionFormSelectOption("css:select[name='country'] option[value='US']")

// Language selection
doc.actionFormSelectOption("xpath://select[@id='language']//option[@value='en']")
```

### `doc.actionFormRadioButton(buttonPath)`

Selects a radio button from a radio button group.

Parameters:

- `buttonPath` (string): Element selector path pointing to the radio button to select.

Usage:

Select a radio button to make a choice. For example, to choose an authentication method or an account type.

Example:

```javascript
// Select authentication method
doc.actionFormRadioButton("id:auth-method-sso")
doc.actionFormRadioButton("css:input[value='ldap']")

// Account type selection
doc.actionFormRadioButton("name:account-type[value='business']")

// Select login flow
doc.actionFormRadioButton("xpath://input[@name='flow' and @value='standard']")

// Security question selection
doc.actionFormRadioButton("css:input[type='radio'][data-question='pet-name']")
```

### `doc.actionFormCheckbox(checkboxPath)`

Select or clear a checkbox.

Parameters:

- `checkboxPath` (string): Element selector path pointing to the checkbox to toggle.

Usage:

Toggle a checkbox. For example, to agree to terms and conditions or turn optional settings on and off.

Example:

```javascript
// Check "Remember me" option
doc.actionFormCheckbox("id:remember-me")

// Accept terms and conditions
doc.actionFormCheckbox("css:input[name='accept-terms']")

// Enable notifications
doc.actionFormCheckbox("xpath://input[@type='checkbox' and @name='notifications']")

// Select multiple options
doc.actionFormCheckbox("css:.feature-checkbox[data-feature='advanced-auth']")
doc.actionFormCheckbox("css:.feature-checkbox[data-feature='audit-logs']")

// Privacy settings
doc.actionFormCheckbox("id:privacy-analytics-opt-out")
```

### `doc.actionFormSubmit(formPath)`

Submits a form by targeting the form element directly.

Parameters:

- `formPath` (string): Element selector path pointing to the form to submit.

Usage:

Use this method as an alternative to selecting submit buttons, especially when forms are submitted using JavaScript or when the submit button is difficult to target.

Example:

```javascript
// Submit login form directly
doc.actionFormSubmit("id:login-form")

// Submit by form class
doc.actionFormSubmit("css:.authentication-form")

// Submit form by name attribute
doc.actionFormSubmit("name:user-login")

// Submit nested form
doc.actionFormSubmit("xpath://div[@class='auth-container']//form")

// Complete authentication flow
doc.actionFormInput("id:username", process.env.USERNAME)
doc.actionFormInput("id:password", process.env.PASSWORD)
doc.actionFormSubmit("css:form[action='/authenticate']")
```

### `doc.actionLeftClick(onPath)`

Performs a left-mouse click on any clickable element.

Parameters:

- `onPath` (string): Element selector path pointing to the element to click.

Usage:

Left-click buttons, links, tabs, and other interactive elements.

Example:

```javascript
// Click submit button
doc.actionLeftClick("css:button[type='submit']")

// Click login button by ID
doc.actionLeftClick("id:login-btn")

// Click link to navigate
doc.actionLeftClick("css:a[href='/dashboard']")

// Click tab or navigation element
doc.actionLeftClick("xpath://li[@data-tab='profile']")

// Click custom button
doc.actionLeftClick("css:.btn-primary[data-action='authenticate']")

// Handle multi-step flows
doc.actionLeftClick("id:next-step")
doc.actionLeftClick("css:button[data-step='verify']")

// Click modal or overlay buttons
doc.actionLeftClick("css:.modal button[data-dismiss='modal']")
```

## Authentication validation methods

You should make sure your scripts contain a success or failure method.
The configuration variables for success and failure also work with authentication scripts.

| Method | Description |
|--------|-------------|
| `auth.successIfAtURL(url)` | Mark authentication as successful if at specified URL. |
| `auth.successIfElementFound(path)` | Mark authentication as successful if element exists. |
| `auth.failedIfAtURL(url)` | Mark authentication as failed if at specified URL. |
| `auth.failedIfElementFound(path)` | Mark authentication as failed if element exists. |

### `auth.successIfElementFound(path)`

Marks authentication as successful if the specified element exists on the current page.

Parameters:

- `path` (string): Element selector path that should exist after successful authentication.

Usage:

Use this method when URL-based validation is insufficient, such as for single-page applications or when specific UI elements indicate authentication status.

Example:

```javascript
// Look for user profile menu
auth.successIfElementFound("css:.user-profile-dropdown")

// Check for logout button
auth.successIfElementFound("id:logout-button")

// Look for welcome message
auth.successIfElementFound("xpath://div[contains(text(), 'Welcome back')]")

// Check for authenticated navigation
auth.successIfElementFound("css:nav .authenticated-menu")

// Look for user avatar
auth.successIfElementFound("css:.header .user-avatar")

// Complete example with element-based validation
doc.navigateURL("https://spa.example.com")
doc.actionFormInput("id:username", process.env.USERNAME)
doc.actionFormInput("id:password", process.env.PASSWORD)
doc.actionLeftClick("css:button[type='submit']")
auth.successIfElementFound("css:.dashboard-welcome")
```

### `auth.failedIfAtURL(url)`

Marks authentication as failed if the browser is at the specified URL.

Parameters:

- `url` (string): The URL that indicates authentication failure.

Usage:

Detect authentication failures by checking for error pages, sign-in page redirects, or specific failure URLs.

Example:

```javascript
// Detect redirect back to login page
auth.failedIfAtURL("https://app.example.com/login")

// Check for error page
auth.failedIfAtURL("https://app.example.com/auth/error")

// Look for access denied page
auth.failedIfAtURL("https://app.example.com/access-denied")

// Account locked page
auth.failedIfAtURL("https://app.example.com/account-locked")

// Complete example with failure detection
doc.navigateURL("https://app.example.com/login")
doc.actionFormInput("id:username", process.env.USERNAME)
doc.actionFormInput("id:password", process.env.PASSWORD)
doc.actionLeftClick("css:button[type='submit']")
```

### `auth.failedIfElementFound(path)`

Marks authentication as failed if the specified element exists on the current page.

Parameters:

- `path` (string): Element selector path that indicates authentication failure.

Usage:

Detect error messages, warning banners, or other UI elements that indicate authentication problems.

Example:

```javascript
// Look for error message
auth.failedIfElementFound("css:.error-message")

// Check for invalid credentials message
auth.failedIfElementFound("xpath://div[contains(text(), 'Invalid username or password')]")

// Look for account locked warning
auth.failedIfElementFound("id:account-locked-alert")

// Comprehensive authentication with failure detection
doc.navigateURL("https://app.example.com/login")
doc.actionFormInput("id:email", process.env.USER_EMAIL)
doc.actionFormInput("id:password", process.env.USER_PASSWORD)
doc.actionLeftClick("id:submit-btn")
auth.failedIfElementFound("css:.error-message")

// Multiple failure conditions
auth.failedIfElementFound("css:.alert-danger")
auth.failedIfElementFound("xpath://div[@class='error' and contains(text(), 'Login failed')]")
auth.failedIfAtURL("https://app.example.com/login?error=1")
```

## One-time password methods

| Method | Description |
|--------|-------------|
| `otp.generateTOTP()` | Generate a time-based, one-time password. |

### `otp.generateTOTP()`

Generates a time-based, one-time password (TOTP) by using the configured secret.

Prerequisites:

- The TOTP secret must be base32 encoded and made available using `DAST_AUTH_OTP_KEY`.
- The application must accept standard TOTP codes (typically 6-digit codes that refresh every 30 seconds).

{{< alert type="warning" >}}
To prevent security risks, do not define `DAST_AUTH_OTP_KEY` in the YAML job definition file.
Instead, create it as a masked CI/CD variable using the GitLab UI.
For more information, see [custom CI/CD variables](../../../../../ci/variables/_index.md#for-a-project).
{{< /alert >}}

Usage:

Use this method for applications that require two-factor authentication with authenticator apps like Google Authenticator, Authy, or similar TOTP-based systems.

Returns:

- String containing the current TOTP code.

Example:

```javascript
// Basic TOTP authentication flow
doc.navigateURL("https://secure.example.com/login")
doc.actionFormInput("id:username", process.env.USERNAME)
doc.actionFormInput("id:password", process.env.PASSWORD)
doc.actionFormInput("id:totp-code", otp.generateTOTP())
doc.actionLeftClick("css:button[type='submit']")
auth.successIfAtURL("https://secure.example.com/dashboard")
```

```javascript
// Advanced TOTP with error handling
doc.navigateURL("https://enterprise.example.com/sso")
doc.actionFormInput("id:employee-id", process.env.EMPLOYEE_ID)
doc.actionFormInput("id:password", process.env.EMPLOYEE_PASSWORD)
doc.actionLeftClick("css:.login-submit")

// Check if TOTP is required
const currentUrl = doc.getURL()
if (currentUrl.includes("/mfa")) {
    log.info("MFA required, generating TOTP")
    const code = otp.generateTOTP()
    doc.actionFormInput("css:.mfa-input", code)
    doc.actionLeftClick("css:.mfa-submit")
}

auth.successIfElementFound("css:.employee-portal")
```

## Logging methods

Add messages to the authentication report. This can be useful when troubleshooting.

| Method | Description |
|--------|-------------|
| `log.info(msg)` | Log informational messages. |
| `log.debug(msg)` | Log debug messages. |
| `log.warn(msg)` | Log warning messages. |
| `log.trace(msg)` | Log trace messages. |
| `log.error(msg)` | Log error messages. |
| `log.errorWithException(ex, msg)` | Log errors with exception details. |

### `log.info(msg)`

Logs informational messages that provide general information about script execution.

Parameters:

- `msg` (string): The message to log.

Usage:

Log general script progress, successful operations, and important milestones in the authentication flow.

Example:

```javascript
log.info("Starting authentication process")
doc.navigateURL("https://app.example.com/login")

log.info("Filling login credentials")
doc.actionFormInput("id:username", process.env.USERNAME)
doc.actionFormInput("id:password", process.env.PASSWORD)

log.info("Submitting login form")
doc.actionLeftClick("css:button[type='submit']")

auth.successIfAtURL("https://app.example.com/dashboard")
log.info("Authentication completed successfully")
```

### `log.debug(msg)`

Logs detailed debugging information useful for troubleshooting script issues.

Parameters:

- `msg` (string): The debug message to log.

Usage:

Log detailed step-by-step information, variable values, and diagnostic information for script debugging.

Example:

```javascript
log.debug("Initializing authentication script")
log.debug("Target URL: https://app.example.com/login")

const username = process.env.USERNAME
log.debug("Username retrieved from environment: " + (username ? "✓" : "✗"))

doc.navigateURL("https://app.example.com/login")
log.debug("Navigation completed")

const currentUrl = doc.getURL()
log.debug("Current URL after navigation: " + currentUrl)

doc.actionFormInput("id:username", username)
log.debug("Username field populated")

doc.actionFormInput("id:password", process.env.PASSWORD)
log.debug("Password field populated")

doc.actionLeftClick("css:button[type='submit']")
log.debug("Login form submitted")
```

### `log.warn(msg)`

Logs warning messages for potentially problematic conditions that don't prevent execution.

Parameters:

- `msg` (string): The warning message to log.

Usage:

Log recoverable issues, fallback scenarios, or conditions that might indicate problems but don't stop the authentication flow.

Example:

```javascript
// Check for required environment variables
if (!process.env.USERNAME) {
    log.warn("USERNAME environment variable not set, using default")
    doc.actionFormInput("id:username", "defaultuser")
} else {
    doc.actionFormInput("id:username", process.env.USERNAME)
}

// Handle optional TOTP
const totpSecret = process.env.DAST_AUTH_OTP_KEY
if (!totpSecret) {
    log.warn("DAST_AUTH_OTP_KEY not configured, skipping two-factor authentication")
} else {
    const code = otp.generateTOTP()
    doc.actionFormInput("id:totp", code)
}

// Check for unexpected page content
const currentUrl = doc.getURL()
if (!currentUrl.includes("expected-domain.com")) {
    log.warn("Unexpected domain in URL: " + currentUrl)
}
```

### `log.trace(msg)`

Logs very detailed trace information for fine-grained debugging.

Parameters:

- `msg` (string): The trace message to log.

Usage:

Log detailed information, including every minor step and operation. Typically used for complex debugging scenarios.

Example:

```javascript
log.trace("Script execution starting")
log.trace("Checking environment variables")

log.trace("About to navigate to login page")
doc.navigateURL("https://complex-app.example.com/auth/login")
log.trace("Navigation call completed")

log.trace("Waiting for page load...")
const url = doc.getURL()
log.trace("Current URL: " + url)

log.trace("Locating username field")
doc.actionFormInput("css:input[data-testid='username']", process.env.USERNAME)
log.trace("Username field interaction completed")

log.trace("Locating password field")
doc.actionFormInput("css:input[data-testid='password']", process.env.PASSWORD)
log.trace("Password field interaction completed")

log.trace("Searching for submit button")
doc.actionLeftClick("css:button[data-testid='submit']")
log.trace("Submit button click completed")

log.trace("Authentication flow finished")
```

### `log.error(msg)`

Logs error messages for serious issues that may cause authentication to fail.

Parameters:

- `msg` (string): The error message to log.

Usage:

Log critical errors, authentication failures, or any condition that prevents successful script completion.

**Example:**

```javascript
// Validate required environment variables
if (!process.env.USERNAME || !process.env.PASSWORD) {
    log.error("Required environment variables USERNAME or PASSWORD not set")
    return
}

try {
  // Custom code that can throw exceptions
} catch (e) {
  log.error("Critical error during authentication: " + e.message)
}

doc.navigateURL("https://app.example.com/login")
doc.actionFormInput("id:username", process.env.USERNAME)
doc.actionFormInput("id:password", process.env.PASSWORD)
doc.actionLeftClick("css:button[type='submit']")

// Check for error conditions
const currentUrl = doc.getURL()
if (currentUrl.includes("/error")) {
    log.error("Authentication failed - redirected to error page")
    log.error("Error URL: " + currentUrl)
}

auth.successIfAtURL("https://app.example.com/dashboard")
```

### `log.errorWithException(ex, msg)`

Logs error messages along with exception details for comprehensive error reporting.

Parameters:

- `ex` (Exception): The exception object containing error details.
- `msg` (string): Additional context message about the error.

Usage:

Catch exceptions or handle complex error scenarios where both the error context and technical details are important.

Example:

```javascript
try {
  log.info("Starting complex authentication flow")

  // Multi-step authentication
  doc.navigateURL("https://enterprise.example.com/login")
  doc.actionFormInput("id:username", process.env.USERNAME)
  doc.actionFormInput("id:password", process.env.PASSWORD)
  doc.actionLeftClick("id:login-btn")

  // Handle TOTP if required
  if (doc.getURL().includes("/mfa")) {
    const totpCode = otp.generateTOTP()
    doc.actionFormInput("id:mfa-code", totpCode)
    doc.actionLeftClick("id:verify-btn")
  }

  auth.successIfAtURL("https://enterprise.example.com/portal")

} catch (authException) {
  log.errorWithException(authException, "Authentication flow failed during login process")

  // Additional error context
  const currentUrl = doc.getURL()
  log.error("Current URL at time of failure: " + currentUrl)

  throw authException
}

// Example with validation error handling
try {
  const username = process.env.USERNAME
  if (!username) {
    throw new Error("USERNAME environment variable is required")
  }

  doc.actionFormInput("id:username", username)
} catch (validationError) {
  log.errorWithException(validationError, "Failed to validate required authentication parameters")
}
```

## Element selectors

Authentication scripts use the same selector syntax as other DAST variables:

- ID selector: `id:element-id`
- CSS selector: `css:.class-name` or `css:button[type="submit"]`
- Name selector: `name:field-name`
- XPath selector: `xpath://input[@id='username']`

## Environment variables

Access sensitive authentication data through environment variables:

```javascript
// Use environment variables for credentials
doc.actionFormInput("id:username", process.env.DAST_AUTH_USERNAME)
doc.actionFormInput("id:password", process.env.DAST_AUTH_PASSWORD)
```

{{< alert type="warning" >}}
To prevent security risks, do not define sensitive information in the YAML job definition file.
Instead, create them as masked CI/CD variables using the GitLab UI.
For more information, see [custom CI/CD variables](../../../../../ci/variables/_index.md#for-a-project).
{{< /alert >}}

## Debugging

There are two ways to understand how your script is executing and what actions it performed:
the authentication report and the debug log. Both are attached to the DAST job as artifacts.

The authentication report includes each step of your authentication script with screenshots to help debug your scripts.
The report also includes HTTP requests and responses, and the Document Object Model (DOM).
The authentication report is generated for each DAST job and collected as a job artifact.
The filename of the artifact is `gl-dast-debug-auth-report.html`.

Additionally, authentication scripts provide comprehensive logging to help troubleshoot authentication issues.
Logging is made to the debug log attached as a job artifact with the name `gl-dast-scan.log`.
All script actions are automatically logged with debugging information showing:

- Environment variable assignments (with masked sensitive values)
- Script execution steps
- URL navigation actions
- Form input operations
- Click actions
- Authentication validation results

Example debug output:

```plaintext
DBG SCRIPT running user script script="auth_script.js"
DBG SCRIPT doc.navigateURL url="https://example.com/login"
DBG SCRIPT doc.actionFormInput onPath="id:username" value="********"
DBG SCRIPT doc.actionLeftClick onPath="css:button[type='submit']"
INF SCRIPT requirement is satisfied, browser URL matches pattern
```

Use the logging methods in your scripts to add custom debug information:

```javascript
log.info("Starting authentication process")
log.debug("Navigating to login page")
// ... authentication steps ...
log.info("Authentication completed successfully")
```

## Troubleshooting

When using authentication scripts, you might encounter the following issues.

### Script execution failures

Your script can fail to run because the JavaScript is malformed, or because there are missing environment variables.

To resolve:

- Verify your script syntax is valid JavaScript.
- Check that all required environment variables are set.
- Use `log.debug()` to add checkpoints in your authentication flow.

### Element selection issues

If your script has trouble selecting elements in the target application:

- Test your selectors in browser developer tools.
- Review the authentication report with the included DOM.

### Authentication validation failures

Your script might fail to authenticate to the target application.

To resolve:

- Ensure your success or failure conditions accurately reflect the authentication state.
- Check for redirects that might change the expected URL.
- Use element-based validation as an alternative to URL-based validation.

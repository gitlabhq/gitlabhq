---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 인증 스크립트
---

인증 스크립트는 다양한 복잡도의 인증 플로우를 처리하기 위한 유연한 JavaScript 기반 접근 방식을 제공합니다. 보안 스캔과 원활하게 통합되는 사용자 정의 스크립트를 사용하여 로그인 프로세스를 자동화합니다.

인증 스크립트는 작업용으로 특별히 설계된 사용자 정의 메서드를 포함한 JavaScript를 사용합니다. 이러한 스크립트는 기본 사용자 이름 및 암호 인증뿐만 아니라 시간 기반 일회용 암호(TOTP)를 지원하는 복잡한 플로우를 처리할 수 있습니다.

인증 스크립트 통합에는 다음이 포함됩니다:

- 다양한 복잡도의 인증 워크플로우 지원.
- 사용자 정의 메서드를 사용한 JavaScript 기반 스크립팅.
- 기존 스캔 프로세스와의 원활한 통합.
- 일회용 암호 및 TOTP 생성 지원.
- 보안 자격 증명 관리를 위한 환경 변수에 대한 액세스.
- 텍스트 입력, 라디오 버튼, 체크박스 및 드롭다운 목록을 포함한 모든 HTML 양식 요소에 대한 지원.
- 변수와의 일관된 선택자 구문.
- 인증 플로우 디버깅을 위한 포괄적인 로깅.

스크립팅 언어가 JavaScript이지만, 스크립트는 브라우저 또는 공통 모듈에 대한 액세스 권한이 없습니다.

## 스크립트 구성 {#configure-scripts}

에서 인증 스크립트를 사용하려면 다음 변수를 구성합니다:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://your-app.example.com"
    DAST_AUTH_SCRIPT: "auth_script.js"
```

다음 구성 옵션을 사용할 수 있습니다:

| 변수 | 설명 | 필수 |
|----------|-------------|----------|
| `DAST_AUTH_SCRIPT` | 인증 스크립트 파일의 경로(로컬 파일 또는 URL) | 예 |

`DAST_AUTH_SCRIPT`를 사용할 때는 다른 인증 변수가 필요하지 않습니다. 기존 성공 및 실패 변수는 선택 사항이며 지정된 경우 작동합니다.

## 예제 스크립트 {#example-scripts}

이 기본 인증 스크립트는 애플리케이션에 로그인합니다:

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

이 필요한 애플리케이션의 경우:

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

스크립트를 실행하려면 구성에 다음을 추가합니다:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_SCRIPT: "auth_script.js"
```

`otp.generateTOTP()` 메서드를 사용하는 경우 `DAST_AUTH_OTP_KEY` 변수도 구성에 추가해야 합니다.

## 문서 상호 작용 메서드 {#document-interaction-methods}

| 메서드 | 설명 |
|--------|-------------|
| `doc.getURL()` | 현재 페이지 URL을 가져옵니다. |
| `doc.navigateURL(url)` | 특정 URL로 이동합니다. |
| `doc.actionFormInput(path, value, dontClear)` | 양식 입력 필드에 텍스트를 입력합니다. |
| `doc.actionFormSelectOption(optionPath)` | 드롭다운 목록 옵션을 선택합니다. |
| `doc.actionFormRadioButton(buttonPath)` | 라디오 버튼을 선택합니다. |
| `doc.actionFormCheckbox(checkboxPath)` | 체크박스를 전환합니다. |
| `doc.actionFormSubmit(formPath)` | 양식을 제출합니다. |
| `doc.actionLeftClick(onPath)` | 마우스 왼쪽 클릭을 수행합니다. |

### `doc.getURL()` {#docgeturl}

현재 페이지 URL을 문자열로 반환합니다.

사용:

조건부 논리나 디버깅에 유용한 현재 브라우저 위치를 검색합니다.

예:

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

### `doc.navigateURL(url)` {#docnavigateurlurl}

브라우저를 지정된 URL로 이동시킵니다.

매개변수:

- `url` (문자열): 이동할 대상 URL입니다.

사용:

인증 플로우 중에 브라우저를 특정 페이지로 이동시킵니다. 이는 대부분의 인증 스크립트에서 일반적으로 첫 번째 작업입니다.

예:

```javascript
// Navigate to the main login page
doc.navigateURL("https://app.example.com/auth/login")

// For multi-step authentication, navigate to different pages
doc.navigateURL("https://app.example.com/auth/two-factor")

// Navigate to a specific tenant or subdomain
doc.navigateURL("https://tenant1.example.com/login")
```

### `doc.actionFormInput(path, value, dontClear)` {#docactionforminputpath-value-dontclear}

텍스트 상자, 암호 필드, 이메일 필드 및 텍스트 영역과 같은 양식 입력 필드에 텍스트를 입력합니다.

기본적으로 이 메서드는 새 텍스트를 입력하기 전에 필드의 기존 콘텐츠를 지웁니다. 다음이 필요한 경우 `dontClear: true`를 설정합니다:

- 기존 필드 콘텐츠를 보존하거나 추가합니다.
- 입력을 방해하는 clearing 프로세스가 있는 auto-focus 동작이 있는 필드로 작업합니다.
- 개별 숫자 입력 간에 자동으로 포커스를 이동하는 OTP 필드와 같은 다중 부분 입력을 처리합니다.

매개변수:

- `path` (문자열): 선택자 구문을 사용하는 요소 선택자 경로입니다.
- `value` (문자열): 필드에 입력할 텍스트 값입니다.
- `dontClear` (부울, 선택 사항): `true`인 경우 메서드는 텍스트를 입력하기 전에 필드를 지우지 않습니다. 기본값: `false`.

사용:

이는 로그인 양식, 검색 상자 및 기타 텍스트 기반 입력 필드를 채우는 주요 메서드입니다.

예:

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

// Skip clearing - useful for fields with auto-focus behavior
doc.actionFormInput("css:.ap-otp-inputs[data-index='0']", 1, true)
doc.actionFormInput("css:.ap-otp-inputs[data-index='1']", 2, true)
doc.actionFormInput("css:.ap-otp-inputs[data-index='2']", 3, true)

// Search or filter fields
doc.actionFormInput("css:input[type='search']", "product name")
```

### `doc.actionFormSelectOption(optionPath)` {#docactionformselectoptionoptionpath}

드롭다운 목록에서 옵션을 선택합니다.

매개변수:

- `optionPath` (문자열): 선택할 옵션을 가리키는 요소 선택자 경로입니다.

사용:

언어나 테넌트와 같은 드롭다운 목록에서 특정 옵션을 선택합니다.

예:

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

### `doc.actionFormRadioButton(buttonPath)` {#docactionformradiobuttonbuttonpath}

라디오 버튼 그룹에서 라디오 버튼을 선택합니다.

매개변수:

- `buttonPath` (문자열): 선택할 라디오 버튼을 가리키는 요소 선택자 경로입니다.

사용:

선택을 하기 위해 라디오 버튼을 선택합니다. 예를 들어, 인증 방법이나 계정 유형을 선택합니다.

예:

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

### `doc.actionFormCheckbox(checkboxPath)` {#docactionformcheckboxcheckboxpath}

체크박스를 선택하거나 선택 해제합니다.

매개변수:

- `checkboxPath` (문자열): 전환할 체크박스를 가리키는 요소 선택자 경로입니다.

사용:

체크박스를 전환합니다. 예를 들어, 약관에 동의하거나 선택적 설정을 켜고 끕니다.

예:

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

### `doc.actionFormSubmit(formPath)` {#docactionformsubmitformpath}

양식 요소를 직접 대상으로 하여 양식을 제출합니다.

매개변수:

- `formPath` (문자열): 제출할 양식을 가리키는 요소 선택자 경로입니다.

사용:

이 메서드를 제출 버튼 선택의 대안으로 사용하십시오. 특히 JavaScript를 사용하여 양식을 제출하거나 제출 버튼을 대상으로 지정하기 어려운 경우에 유용합니다.

예:

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

### `doc.actionLeftClick(onPath)` {#docactionleftclickonpath}

클릭 가능한 요소에 마우스 왼쪽 클릭을 수행합니다.

매개변수:

- `onPath` (문자열): 클릭할 요소를 가리키는 요소 선택자 경로입니다.

사용:

버튼, 링크, 탭 및 기타 대화형 요소를 마우스 왼쪽 클릭합니다.

예:

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

## 인증 검증 메서드 {#authentication-validation-methods}

스크립트에 성공 또는 실패 메서드가 포함되어 있는지 확인해야 합니다. 성공 및 실패를 위한 구성 변수는 인증 스크립트와도 작동합니다.

| 메서드 | 설명 |
|--------|-------------|
| `auth.successIfAtURL(url)` | 지정된 URL에 있으면 인증을 성공으로 표시합니다. |
| `auth.successIfElementFound(path)` | 요소가 있으면 인증을 성공으로 표시합니다. |
| `auth.failedIfAtURL(url)` | 지정된 URL에 있으면 인증을 실패로 표시합니다. |
| `auth.failedIfElementFound(path)` | 요소가 있으면 인증을 실패로 표시합니다. |

### `auth.successIfElementFound(path)` {#authsuccessifelementfoundpath}

현재 페이지에 지정된 요소가 있으면 인증을 성공으로 표시합니다.

매개변수:

- `path` (문자열): 성공적인 인증 후에 존재해야 하는 요소 선택자 경로입니다.

사용:

URL 기반 검증이 부족한 경우(예: 단일 페이지 애플리케이션) 또는 특정 UI 요소가 인증 상태를 나타낼 때 이 메서드를 사용합니다.

예:

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

### `auth.failedIfAtURL(url)` {#authfailedifaturlurl}

브라우저가 지정된 URL에 있으면 인증을 실패로 표시합니다.

매개변수:

- `url` (문자열): 인증 실패를 나타내는 URL입니다.

사용:

오류 페이지, 로그인 페이지 리디렉션 또는 특정 실패 URL을 확인하여 인증 실패를 감지합니다.

예:

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

### `auth.failedIfElementFound(path)` {#authfailedifelementfoundpath}

현재 페이지에 지정된 요소가 있으면 인증을 실패로 표시합니다.

매개변수:

- `path` (문자열): 인증 실패를 나타내는 요소 선택자 경로입니다.

사용:

오류 메시지, 경고 배너 또는 인증 문제를 나타내는 기타 UI 요소를 감지합니다.

예:

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

## 일회용 암호 메서드 {#one-time-password-methods}

| 메서드 | 설명 |
|--------|-------------|
| `otp.generateTOTP()` | 시간 기반 일회용 암호를 생성합니다. |

### `otp.generateTOTP()` {#otpgeneratetotp}

구성된 보안 정보를 사용하여 시간 기반 일회용 암호(TOTP)를 생성합니다.

전제 조건:

- TOTP 보안 정보는 base32로 인코딩되어야 하며 `DAST_AUTH_OTP_KEY`를 사용하여 사용할 수 있어야 합니다.
- 애플리케이션은 표준 TOTP 코드(일반적으로 30초마다 새로 고쳐지는 6자리 코드)를 수락해야 합니다.

> [!warning]
> 보안 위험을 방지하려면 YAML 정의 파일에 `DAST_AUTH_OTP_KEY`를 정의하지 마십시오. 대신 GitLab UI를 사용하여 마스크된 로 생성합니다. 자세한 내용은 [사용자 정의](../../../../../ci/variables/_index.md#for-a-project)를 참조하세요.

사용:

Google Authenticator, Authy 또는 유사한 TOTP 기반 시스템과 같은 인증기 앱이 필요한 애플리케이션에 이 메서드를 사용합니다.

반환:

- 현재 TOTP 코드를 포함하는 문자열입니다.

예:

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

## 로깅 메서드 {#logging-methods}

인증 보고서에 메시지를 추가합니다. 이는 문제를 해결할 때 유용할 수 있습니다.

| 메서드 | 설명 |
|--------|-------------|
| `log.info(msg)` | 정보 메시지를 기록합니다. |
| `log.debug(msg)` | 디버그 메시지를 기록합니다. |
| `log.warn(msg)` | 경고 메시지를 기록합니다. |
| `log.trace(msg)` | 추적 메시지를 기록합니다. |
| `log.error(msg)` | 오류 메시지를 기록합니다. |
| `log.errorWithException(ex, msg)` | 예외 세부 정보와 함께 오류를 기록합니다. |

### `log.info(msg)` {#loginfomsg}

스크립트 실행에 대한 일반 정보를 제공하는 정보 메시지를 기록합니다.

매개변수:

- `msg` (문자열): 기록할 메시지입니다.

사용:

일반 스크립트 진행 상황, 성공적인 작업 및 인증 플로우의 중요한 마일스톤을 기록합니다.

예:

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

### `log.debug(msg)` {#logdebugmsg}

스크립트 문제를 해결하는 데 유용한 자세한 디버깅 정보를 기록합니다.

매개변수:

- `msg` (문자열): 기록할 디버그 메시지입니다.

사용:

스크립트 디버깅을 위해 자세한 단계별 정보, 변수 값 및 진단 정보를 기록합니다.

예:

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

### `log.warn(msg)` {#logwarnmsg}

실행을 방지하지 않는 잠재적으로 문제가 있는 조건에 대한 경고 메시지를 기록합니다.

매개변수:

- `msg` (문자열): 기록할 경고 메시지입니다.

사용:

복구 가능한 문제, 폴백 시나리오 또는 인증 플로우를 중지하지는 않지만 문제를 나타낼 수 있는 조건을 기록합니다.

예:

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

### `log.trace(msg)` {#logtracemsg}

미세한 디버깅을 위한 매우 자세한 추적 정보를 기록합니다.

매개변수:

- `msg` (문자열): 기록할 추적 메시지입니다.

사용:

모든 사소한 단계 및 작업을 포함한 자세한 정보를 기록합니다. 일반적으로 복잡한 디버깅 시나리오에 사용됩니다.

예:

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

### `log.error(msg)` {#logerrormsg}

인증 실패를 야기할 수 있는 심각한 문제에 대한 오류 메시지를 기록합니다.

매개변수:

- `msg` (문자열): 기록할 오류 메시지입니다.

사용:

중요한 오류, 인증 실패 또는 성공적인 스크립트 완료를 방지하는 모든 조건을 기록합니다.

**예:**

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

### `log.errorWithException(ex, msg)` {#logerrorwithexceptionex-msg}

예외 세부 정보와 함께 오류 메시지를 기록하여 포괄적인 오류 보고를 수행합니다.

매개변수:

- `ex` (예외): 오류 세부 정보를 포함하는 예외 개체입니다.
- `msg` (문자열): 오류에 대한 추가 컨텍스트 메시지입니다.

사용:

예외를 catch하거나 오류 컨텍스트와 기술 세부 정보가 모두 중요한 복잡한 오류 시나리오를 처리합니다.

예:

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

## 요소 선택자 {#element-selectors}

인증 스크립트는 다른 변수와 동일한 선택자 구문을 사용합니다:

- ID 선택자: `id:element-id`
- CSS 선택자: `css:.class-name` 또는 `css:button[type="submit"]`
- 이름 선택자: `name:field-name`
- XPath 선택자: `xpath://input[@id='username']`

## 환경 변수 {#environment-variables}

환경 변수를 통해 중요한 인증 데이터에 액세스합니다:

```javascript
// Use environment variables for credentials
doc.actionFormInput("id:username", process.env.DAST_AUTH_USERNAME)
doc.actionFormInput("id:password", process.env.DAST_AUTH_PASSWORD)
```

> [!warning]
> 보안 위험을 방지하려면 YAML 정의 파일에 중요한 정보를 정의하지 마십시오. 대신 GitLab UI를 사용하여 마스크된 로 생성합니다. 자세한 내용은 [사용자 정의](../../../../../ci/variables/_index.md#for-a-project)를 참조하세요.

## 디버깅 {#debugging}

스크립트가 실행되는 방식과 수행된 작업을 이해하는 두 가지 방법이 있습니다: 인증 보고서와 디버그 로그입니다. 둘 다 아티팩트로 첨부됩니다.

인증 보고서에는 스크립트를 디버깅하는 데 도움이 되는 스크린샷과 함께 인증 스크립트의 각 단계가 포함됩니다. 보고서에는 HTTP 요청 및 응답과 문서 개체 모델(DOM)도 포함됩니다. 인증 보고서는 각 에 대해 생성되고 아티팩트로 수집됩니다. 아티팩트의 파일 이름은 `gl-dast-debug-auth-report.html`입니다.

또한 인증 스크립트는 인증 문제를 해결하는 데 도움이 되는 포괄적인 로깅을 제공합니다. 로깅은 이름이 `gl-dast-scan.log`인 아티팩트로 첨부된 디버그 로그로 작성됩니다. 모든 스크립트 작업은 다음을 보여주는 디버깅 정보와 함께 자동으로 기록됩니다:

- 환경 변수 할당(마스크된 중요한 값 포함)
- 스크립트 실행 단계
- URL 이동 작업
- 양식 입력 작업
- 클릭 작업
- 인증 검증 결과

예제 디버그 출력:

```plaintext
DBG SCRIPT running user script script="auth_script.js"
DBG SCRIPT doc.navigateURL url="https://example.com/login"
DBG SCRIPT doc.actionFormInput onPath="id:username" value="********"
DBG SCRIPT doc.actionLeftClick onPath="css:button[type='submit']"
INF SCRIPT requirement is satisfied, browser URL matches pattern
```

스크립트의 로깅 메서드를 사용하여 사용자 정의 디버그 정보를 추가합니다:

```javascript
log.info("Starting authentication process")
log.debug("Navigating to login page")
// ... authentication steps ...
log.info("Authentication completed successfully")
```

## 문제 해결 {#troubleshooting}

인증 스크립트를 사용할 때 다음과 같은 문제가 발생할 수 있습니다.

### 스크립트 실행 실패 {#script-execution-failures}

스크립트는 JavaScript가 형식이 잘못되었거나 환경 변수가 누락되어 실행에 실패할 수 있습니다.

해결하려면:

- 스크립트 구문이 유효한 JavaScript인지 확인합니다.
- 필요한 모든 환경 변수가 설정되었는지 확인합니다.
- `log.debug()`를 사용하여 인증 플로우에 체크포인트를 추가합니다.

### 요소 선택 문제 {#element-selection-issues}

스크립트가 대상 애플리케이션에서 요소를 선택하는 데 문제가 있는 경우:

- 브라우저 개발자 도구에서 선택자를 테스트합니다.
- 포함된 DOM과 함께 인증 보고서를 검토합니다.

### 인증 검증 실패 {#authentication-validation-failures}

스크립트가 대상 애플리케이션에 인증하지 못할 수 있습니다.

해결하려면:

- 성공 또는 실패 조건이 인증 상태를 정확하게 반영하는지 확인합니다.
- 예상 URL을 변경할 수 있는 리디렉션을 확인합니다.
- URL 기반 검증의 대안으로 요소 기반 검증을 사용합니다.

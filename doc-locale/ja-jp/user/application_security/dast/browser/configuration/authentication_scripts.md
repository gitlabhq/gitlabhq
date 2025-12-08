---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 認証スクリプト
---

DAST認証スクリプトは、さまざまな複雑さの認証フローを処理するための、柔軟なJavaScriptベースのアプローチを提供します。DASTセキュリティスキャンとシームレスに統合するカスタムスクリプトを使用して、サインインプロセスを自動化します。

認証スクリプトは、DAST操作のために特別に設計されたカスタムメソッドでJavaScriptを使用します。これらのスクリプトは、基本的なユーザー名とパスワード認証、および時間ベースのワンタイムパスワード（TOTP）をサポートする複雑な多要素認証フローを処理できます。

認証スクリプトの統合には、以下が含まれます:

- さまざまな複雑さの認証ワークフローのサポート。
- カスタムDASTメソッドを使用したJavaScriptベースのスクリプト。
- 既存のDASTスキャンプロセスとのシームレスな統合。
- ワンタイムパスワードとTOTP生成の組み込みサポート。
- 安全な認証情報管理のための環境変数へのアクセス。
- テキスト入力、ラジオボタン、チェックボックス、ドロップダウンリストなど、すべてのHTMLフォーム要素のサポート。
- 他のDAST変数との一貫したセレクター構文。
- 認証フローのデバッグのための包括的なロギング。

スクリプト言語はJavaScriptですが、スクリプトはブラウザーまたは共通モジュールにアクセスできません。

## スクリプトの設定 {#configure-scripts}

認証スクリプトをDASTで使用するには、次の変数を設定します:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://your-app.example.com"
    DAST_AUTH_SCRIPT: "auth_script.js"
```

次の設定オプションを使用できます:

| 変数 | 説明 | 必須 |
|----------|-------------|----------|
| `DAST_AUTH_SCRIPT` | お使いの認証スクリプトファイル（ローカルファイルまたはURL）へのパス | はい |

`DAST_AUTH_SCRIPT`を使用する場合、他の認証変数は必要ありません。既存の成功および失敗変数はオプションであり、指定されている場合は機能します。

## スクリプトの例 {#example-scripts}

この基本的な認証スクリプトは、アプリケーションにサインインします:

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

2要素認証を必要とするアプリケーションの場合:

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

スクリプトを実行するには、次の内容をCI/CD設定に追加します:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_SCRIPT: "auth_script.js"
```

`otp.generateTOTP()`メソッドを使用する場合は、CI/CD設定に`DAST_AUTH_OTP_KEY`変数も追加してください。

## ドキュメント対話メソッド {#document-interaction-methods}

| メソッド | 説明 |
|--------|-------------|
| `doc.getURL()` | 現在のページURLを取得します。 |
| `doc.navigateURL(url)` | 特定のURLに移動します。 |
| `doc.actionFormInput(path, value)` | フォーム入力フィールドにテキストを入力します。 |
| `doc.actionFormSelectOption(optionPath)` | ドロップダウンリストオプションを選択します。 |
| `doc.actionFormRadioButton(buttonPath)` | ラジオボタンを選択します。 |
| `doc.actionFormCheckbox(checkboxPath)` | チェックボックスを切り替えます。 |
| `doc.actionFormSubmit(formPath)` | フォームを送信します。 |
| `doc.actionLeftClick(onPath)` | 左マウスクリックを実行します。 |

### `doc.getURL()` {#docgeturl}

現在のページURLを文字列として返します。

使用方法:

現在のブラウザの場所を取得するます。これは、条件ロジックまたはデバッグに役立ちます。

例: 

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

ブラウザを指定されたURLにナビゲートします。

パラメータは以下のとおりです:

- `url`（文字列）: 移動先のターゲットURL。

使用方法:

認証フロー中に、ブラウザを特定のページに誘導します。これは通常、ほとんどの認証スクリプトの最初のアクションです。

例: 

```javascript
// Navigate to the main login page
doc.navigateURL("https://app.example.com/auth/login")

// For multi-step authentication, navigate to different pages
doc.navigateURL("https://app.example.com/auth/two-factor")

// Navigate to a specific tenant or subdomain
doc.navigateURL("https://tenant1.example.com/login")
```

### `doc.actionFormInput(path, value)` {#docactionforminputpath-value}

テキストボックス、パスワードフィールド、メールフィールド、テキストエリアなどのフォーム入力フィールドにテキストを入力します。

パラメータは以下のとおりです:

- `path`（文字列）: DASTセレクター構文を使用した要素セレクターパス。
- `value`（文字列）: フィールドに入力するテキスト値。

使用方法:

これは、サインインフォーム、検索ボックス、およびその他のテキストベースの入力フィールドに入力するための主要なメソッドです。

例: 

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

### `doc.actionFormSelectOption(optionPath)` {#docactionformselectoptionoptionpath}

ドロップダウンリストからオプションを選択します。

パラメータは以下のとおりです:

- `optionPath`（文字列）: 選択するオプションを指す要素セレクターパス。

使用方法:

言語やテナントなど、ドロップダウンリストから特定のオプションを選択します。

例: 

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

ラジオボタンのグループからラジオボタンを選択します。

パラメータは以下のとおりです:

- `buttonPath`（文字列）: 選択するラジオボタンを指す要素セレクターパス。

使用方法:

ラジオボタンを選択して選択します。たとえば、認証方法またはアカウントタイプを選択します。

例: 

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

チェックボックスを選択またはクリアします。

パラメータは以下のとおりです:

- `checkboxPath`（文字列）: 切り替えるチェックボックスを指す要素セレクターパス。

使用方法:

チェックボックスを切り替えます。たとえば、契約条件に同意したり、オプションの設定をオンまたはオフにしたりします。

例: 

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

フォーム要素を直接ターゲットにして、フォームを送信します。

パラメータは以下のとおりです:

- `formPath`（文字列）: 送信するフォームを指す要素セレクターパス。

使用方法:

特に、JavaScriptを使用してフォームが送信される場合や、送信ボタンのターゲット設定が難しい場合は、このメソッドを送信ボタンを選択する代わりに使用します。

例: 

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

クリック可能な要素に対して左マウスクリックを実行します。

パラメータは以下のとおりです:

- `onPath`（文字列）: クリックする要素を指す要素セレクターパス。

使用方法:

左クリックボタン、リンク、タブ、およびその他のインタラクティブな要素。

例: 

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

## 認証検証メソッド {#authentication-validation-methods}

スクリプトに成功または失敗メソッドが含まれていることを確認する必要があります。成功と失敗のための設定変数は、認証スクリプトでも機能します。

| メソッド | 説明 |
|--------|-------------|
| `auth.successIfAtURL(url)` | 指定されたURLにある場合、認証が成功したとマークします。 |
| `auth.successIfElementFound(path)` | 要素が存在する場合、認証が成功したとマークします。 |
| `auth.failedIfAtURL(url)` | 指定されたURLにある場合、認証が失敗したとマークします。 |
| `auth.failedIfElementFound(path)` | 要素が存在する場合、認証が失敗したとマークします。 |

### `auth.successIfElementFound(path)` {#authsuccessifelementfoundpath}

指定された要素が現在のページに存在する場合、認証が成功したとマークします。

パラメータは以下のとおりです:

- `path`（文字列）: 成功した認証後に存在するはずの要素セレクターパス。

使用方法:

シングルページアプリケーションの場合や、特定のUI要素が認証ステータスを示す場合など、URLベースの検証が不十分な場合は、このメソッドを使用します。

例: 

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

ブラウザが指定されたURLにある場合、認証が失敗したとマークします。

パラメータは以下のとおりです:

- `url`（文字列）: 認証の失敗を示すURL。

使用方法:

エラーページ、サインインページのリダイレクト、または特定の失敗URLを確認して、認証の失敗を検出します。

例: 

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

指定された要素が現在のページに存在する場合、認証が失敗したとマークします。

パラメータは以下のとおりです:

- `path`（文字列）: 認証の失敗を示す要素セレクターパス。

使用方法:

エラーメッセージ、警告バナー、または認証の問題を示すその他のUI要素を検出します。

例: 

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

## ワンタイムパスワードメソッド {#one-time-password-methods}

| メソッド | 説明 |
|--------|-------------|
| `otp.generateTOTP()` | 時間ベースのワンタイムパスワードを生成します。 |

### `otp.generateTOTP()` {#otpgeneratetotp}

構成されたシークレットを使用して、時間ベースのワンタイムパスワード（TOTP）を生成します。

前提要件: 

- TOTPシークレットは、base32でエンコードされ、`DAST_AUTH_OTP_KEY`を使用して利用できるようにする必要があります。
- アプリケーションは、標準のTOTPコード（通常、30秒ごとに更新される6桁のコード）を受け入れる必要があります。

{{< alert type="warning" >}}セキュリティリスクを防ぐために、YAMLジョブ定義ファイルで`DAST_AUTH_OTP_KEY`を定義しないでください。代わりに、GitLabUIを使用して、マスクされたCI/CD変数として作成します。詳細については、[カスタムCI/CD変数](../../../../../ci/variables/_index.md#for-a-project)を参照してください。{{< /alert >}}

使用方法:

Google Authenticator、Authy、または同様のTOTPベースのシステムのような認証アプリで2要素認証を必要とするアプリケーションには、このメソッドを使用します。

戻り値:

- 現在のTOTPコードを含む文字列。

例: 

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

## ロギングメソッド {#logging-methods}

認証レポートにメッセージを追加します。これは、トラブルシューティングを行う場合に役立ちます。

| メソッド | 説明 |
|--------|-------------|
| `log.info(msg)` | 情報メッセージを記録します。 |
| `log.debug(msg)` | デバッグメッセージを記録します。 |
| `log.warn(msg)` | 警告メッセージを記録します。 |
| `log.trace(msg)` | トレースメッセージを記録します。 |
| `log.error(msg)` | エラーメッセージを記録します。 |
| `log.errorWithException(ex, msg)` | 例外の詳細とともにエラーを記録します。 |

### `log.info(msg)` {#loginfomsg}

スクリプトの実行に関する一般的な情報を提供する情報メッセージを記録します。

パラメータは以下のとおりです:

- `msg`（文字列）: ログに記録するメッセージ。

使用方法:

一般的なスクリプトの進行状況、成功した操作、および認証フローにおける重要なマイルストーンを記録します。

例: 

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

スクリプトのイシューのトラブルシューティングに役立つ詳細なデバッグ情報を記録します。

パラメータは以下のとおりです:

- `msg`（文字列）: ログに記録するデバッグメッセージ。

使用方法:

スクリプトのデバッグのための詳細なステップバイステップ情報、変数の値、および診断情報を記録します。

例: 

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

実行を妨げない可能性のある問題のある状態の警告メッセージを記録します。

パラメータは以下のとおりです:

- `msg`（文字列）: ログに記録する警告メッセージ。

使用方法:

取得可能なイシュー、フォールバックシナリオ、または問題を示す可能性のある条件を記録しますが、認証フローを停止しません。

例: 

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

詳細なデバッグのための非常に詳細なトレース情報を記録します。

パラメータは以下のとおりです:

- `msg`（文字列）: ログに記録するトレースメッセージ。

使用方法:

すべての小さなステップと操作を含む詳細な情報を記録します。通常、複雑なデバッグシナリオで使用されます。

例: 

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

認証が失敗する可能性のある重大なイシューのエラーメッセージを記録します。

パラメータは以下のとおりです:

- `msg`（文字列）: ログに記録するエラーメッセージ。

使用方法:

重大なエラー、認証の失敗、またはスクリプトの正常な完了を妨げる状態を記録します。

**例:**

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

包括的なエラーレポートのために、例外の詳細とともにエラーメッセージを記録します。

パラメータは以下のとおりです:

- `ex`（例外）: エラーの詳細を含む例外オブジェクト。
- `msg`（文字列）: エラーに関する追加のコンテキストメッセージ。

使用方法:

エラーコンテキストと技術的な詳細の両方が重要な例外をキャッチするか、複雑なエラーシナリオを処理します。

例: 

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

## 要素セレクター {#element-selectors}

認証スクリプトは、他のDAST変数と同じセレクター構文を使用します:

- IDセレクター: `id:element-id`
- CSSセレクター: `css:.class-name`または`css:button[type="submit"]`
- 名前セレクター: `name:field-name`
- XPathセレクター: `xpath://input[@id='username']`

## 環境変数 {#environment-variables}

環境変数を介して機密情報への認証データにアクセスします:

```javascript
// Use environment variables for credentials
doc.actionFormInput("id:username", process.env.DAST_AUTH_USERNAME)
doc.actionFormInput("id:password", process.env.DAST_AUTH_PASSWORD)
```

{{< alert type="warning" >}}セキュリティリスクを防ぐために、YAMLジョブ定義ファイルで機密情報を定義しないでください。代わりに、GitLabUIを使用して、マスクされたCI/CD変数として作成します。詳細については、[カスタムCI/CD変数](../../../../../ci/variables/_index.md#for-a-project)を参照してください。{{< /alert >}}

## デバッグ {#debugging}

スクリプトの実行方法と実行したアクションを理解する方法は2つあります。認証レポートとデバッグログです。どちらも、DASTジョブにアーティファクトとして添付されています。

認証レポートには、スクリプトのデバッグに役立つスクリーンショットを含む認証スクリプトの各ステップが含まれています。また、レポートにはHTTPリクエストとレスポンス、およびDocument Objet Model（DOM）も含まれています。認証レポートは、各DASTジョブに対して生成され、ジョブアーティファクトとして収集されます。アーティファクトのファイル名は`gl-dast-debug-auth-report.html`です。

さらに、認証スクリプトは、認証のイシューをトラブルシューティングするのに役立つ包括的なロギングを提供します。ロギングは、名前`gl-dast-scan.log`のジョブアーティファクトとして添付されたデバッグログに対して行われます。すべてのスクリプトアクションは、デバッグ情報とともに自動的に記録されます:

- 環境変数の割り当て（マスクされた機密情報の値を含む）
- スクリプトの実行手順
- URLナビゲーションアクション
- フォーム入力操作
- クリックアクション
- 認証検証結果

デバッグの出力例:

```plaintext
DBG SCRIPT running user script script="auth_script.js"
DBG SCRIPT doc.navigateURL url="https://example.com/login"
DBG SCRIPT doc.actionFormInput onPath="id:username" value="********"
DBG SCRIPT doc.actionLeftClick onPath="css:button[type='submit']"
INF SCRIPT requirement is satisfied, browser URL matches pattern
```

スクリプトでロギングメソッドを使用して、カスタムデバッグ情報を追加します:

```javascript
log.info("Starting authentication process")
log.debug("Navigating to login page")
// ... authentication steps ...
log.info("Authentication completed successfully")
```

## トラブルシューティング {#troubleshooting}

認証スクリプトを使用する場合、次のイシューが発生する可能性があります。

### スクリプト実行の失敗 {#script-execution-failures}

JavaScriptが不正な形式であるか、環境変数が不足しているため、スクリプトの実行に失敗する可能性があります。

解決するには、次のようにします:

- スクリプトの構文が有効なJavaScriptであることを確認します。
- 必要なすべての環境変数が設定されていることを確認します。
- `log.debug()`を使用して、認証フローにチェックポイントを追加します。

### 要素選択のイシュー {#element-selection-issues}

スクリプトがターゲットアプリケーションで要素を選択するのに問題がある場合:

- ブラウザデベロッパーツールでセレクターをテストします。
- 含まれているDOMで認証レポートを確認します。

### 認証検証の失敗 {#authentication-validation-failures}

スクリプトがターゲットアプリケーションへの認証に失敗する可能性があります。

解決するには、次のようにします:

- 成功または失敗の条件が認証状態を正確に反映していることを確認します。
- 予期されるURLを変更する可能性のあるリダイレクトを確認します。
- URLベースの検証の代替として、要素ベースの検証を使用します。

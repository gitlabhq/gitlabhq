---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Scripts d'authentification"
---

Les scripts d'authentification DAST offrent une approche flexible, basée sur JavaScript, pour gérer des flux d'authentification de complexité variable. Automatisez les processus de connexion à l'aide de scripts personnalisés qui s'intègrent de façon transparente avec l'analyse de sécurité DAST.

Les scripts d'authentification utilisent JavaScript avec des méthodes personnalisées conçues spécifiquement pour les opérations DAST. Ces scripts peuvent gérer l'authentification de base par nom d'utilisateur et mot de passe, ainsi que des flux d'authentification à deux facteurs complexes avec prise en charge des mots de passe à usage unique basés sur le temps (TOTP).

L'intégration des scripts d'authentification inclut :

- Prise en charge des workflows d'authentification de complexités variées
- Script basé sur JavaScript utilisant des méthodes DAST personnalisées
- Intégration transparente avec les processus d'analyse DAST existants
- Prise en charge native des mots de passe à usage unique et de la génération TOTP
- Accès aux variables CI/CD d'environnement pour la gestion sécurisée des identifiants
- Prise en charge de tous les éléments de formulaire HTML, notamment les champs de texte, les boutons radio, les cases à cocher et les listes déroulantes
- Syntaxe de sélecteurs cohérente avec les autres variables CI/CD DAST
- Journalisation complète pour le débogage des flux d'authentification

Bien que le langage de script soit JavaScript, les scripts n'ont pas accès au navigateur ni aux modules courants.

## Configurer les scripts {#configure-scripts}

Pour utiliser des scripts d'authentification avec DAST, configurez les variables suivantes :

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://your-app.example.com"
    DAST_AUTH_SCRIPT: "auth_script.js"
```

Les options de configuration suivantes sont disponibles :

| Variable | Description | Obligatoire |
|----------|-------------|----------|
| `DAST_AUTH_SCRIPT` | Chemin vers votre fichier de script d'authentification (fichier local ou URL) | Oui |

Aucune autre variable d'authentification n'est requise lors de l'utilisation de `DAST_AUTH_SCRIPT`. Les variables de succès et d'échec existantes sont facultatives et fonctionnent si elles sont spécifiées.

## Exemples de scripts {#example-scripts}

Ce script d'authentification de base se connecte à une application :

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

Pour une application qui nécessite une authentification à deux facteurs :

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

Pour exécuter un script, ajoutez ce qui suit à votre configuration CI/CD :

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_SCRIPT: "auth_script.js"
```

Si vous utilisez la méthode `otp.generateTOTP()`, assurez-vous d'ajouter également la variable CI/CD `DAST_AUTH_OTP_KEY` à votre configuration CI/CD.

## Méthodes d'interaction avec le document {#document-interaction-methods}

| Méthode | Description |
|--------|-------------|
| `doc.getURL()` | Obtenir l'URL de la page actuelle. |
| `doc.navigateURL(url)` | Accéder à une URL spécifique. |
| `doc.actionFormInput(path, value, dontClear)` | Saisir du texte dans les champs de saisie d'un formulaire. |
| `doc.actionFormSelectOption(optionPath)` | Sélectionner une option dans une liste déroulante. |
| `doc.actionFormRadioButton(buttonPath)` | Sélectionner un bouton radio. |
| `doc.actionFormCheckbox(checkboxPath)` | Activer ou désactiver une case à cocher. |
| `doc.actionFormSubmit(formPath)` | Soumettre un formulaire. |
| `doc.actionLeftClick(onPath)` | Effectuer un clic gauche de la souris. |

### `doc.getURL()` {#docgeturl}

Retourne l'URL de la page actuelle sous forme de chaîne de caractères.

Utilisation :

Récupère l'emplacement actuel du navigateur, ce qui est utile pour la logique conditionnelle ou le débogage.

Exemple :

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

Navigue le navigateur vers l'URL spécifiée.

Paramètres :

- `url` (string) : l'URL cible vers laquelle accéder

Utilisation :

Dirigez le navigateur vers des pages spécifiques pendant le flux d'authentification. Il s'agit généralement de la première action dans la plupart des scripts d'authentification.

Exemple :

```javascript
// Navigate to the main login page
doc.navigateURL("https://app.example.com/auth/login")

// For multi-step authentication, navigate to different pages
doc.navigateURL("https://app.example.com/auth/two-factor")

// Navigate to a specific tenant or subdomain
doc.navigateURL("https://tenant1.example.com/login")
```

### `doc.actionFormInput(path, value, dontClear)` {#docactionforminputpath-value-dontclear}

Saisit du texte dans des champs de saisie de formulaire tels que des zones de texte, des champs de mot de passe, des champs d'e-mail et des zones de texte multiligne.

Par défaut, cette méthode efface tout contenu existant dans le champ avant que le nouveau texte ne soit saisi. Définissez `dontClear: true` lorsque vous avez besoin de :

- Conserver ou ajouter du contenu à un champ existant.
- Travailler avec des champs dont le comportement de mise au point automatique interfère avec l'effacement lors de la saisie.
- Gérer des saisies en plusieurs parties, comme les champs OTP qui déplacent automatiquement le focus entre les champs de chiffres individuels.

Paramètres :

- `path` (string) : chemin du sélecteur d'élément utilisant la syntaxe de sélecteur DAST.
- `value` (string) : valeur de texte à saisir dans le champ.
- `dontClear` (boolean, facultatif) : lorsque `true`, la méthode n'efface pas le champ avant la saisie du texte Par défaut : `false`.

Utilisation :

Il s'agit de la méthode principale pour remplir les formulaires de connexion, les zones de recherche et autres champs de saisie basés sur du texte.

Exemple :

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

Sélectionne une option dans des listes déroulantes.

Paramètres :

- `optionPath` (string) : chemin du sélecteur d'élément pointant vers l'option à sélectionner.

Utilisation :

Sélectionnez une option spécifique dans une liste déroulante, comme une langue ou un locataire.

Exemple :

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

Sélectionne un bouton radio dans un groupe de boutons radio.

Paramètres :

- `buttonPath` (string) : chemin du sélecteur d'élément pointant vers le bouton radio à sélectionner.

Utilisation :

Sélectionnez un bouton radio pour faire un choix. Par exemple, pour choisir une méthode d'authentification ou un type de compte.

Exemple :

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

Cocher ou décocher une case à cocher.

Paramètres :

- `checkboxPath` (string) : chemin du sélecteur d'élément pointant vers la case à cocher à activer ou désactiver.

Utilisation :

Activer ou désactiver une case à cocher. Par exemple, pour accepter les conditions générales ou activer et désactiver des paramètres facultatifs.

Exemple :

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

Soumet un formulaire en ciblant directement l'élément de formulaire.

Paramètres :

- `formPath` (string) : chemin du sélecteur d'élément pointant vers le formulaire à soumettre.

Utilisation :

Utilisez cette méthode comme alternative à la sélection des boutons de soumission, notamment lorsque les formulaires sont soumis via JavaScript ou lorsque le bouton de soumission est difficile à cibler.

Exemple :

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

Effectue un clic gauche de la souris sur n'importe quel élément cliquable.

Paramètres :

- `onPath` (string) : chemin du sélecteur d'élément pointant vers l'élément sur lequel cliquer.

Utilisation :

Cliquez avec le bouton gauche sur des boutons, des liens, des onglets et d'autres éléments interactifs.

Exemple :

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

## Méthodes de validation de l'authentification {#authentication-validation-methods}

Assurez-vous que vos scripts contiennent une méthode de succès ou d'échec. Les variables CI/CD de configuration pour le succès et l'échec fonctionnent également avec les scripts d'authentification.

| Méthode | Description |
|--------|-------------|
| `auth.successIfAtURL(url)` | Marquer l'authentification comme réussie si l'URL spécifiée est atteinte. |
| `auth.successIfElementFound(path)` | Marquer l'authentification comme réussie si l'élément existe. |
| `auth.failedIfAtURL(url)` | Marquer l'authentification comme échouée si l'URL spécifiée est atteinte. |
| `auth.failedIfElementFound(path)` | Marquer l'authentification comme échouée si l'élément existe. |

### `auth.successIfElementFound(path)` {#authsuccessifelementfoundpath}

Marque l'authentification comme réussie si l'élément spécifié existe sur la page actuelle.

Paramètres :

- `path` (string) : chemin du sélecteur d'élément qui doit exister après une authentification réussie.

Utilisation :

Utilisez cette méthode lorsque la validation basée sur l'URL est insuffisante, par exemple pour les applications monopages ou lorsque des éléments d'interface spécifiques indiquent le statut d'authentification.

Exemple :

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

Marque l'authentification comme échouée si le navigateur se trouve à l'URL spécifiée.

Paramètres :

- `url` (string) : l'URL qui indique un échec d'authentification.

Utilisation :

Détectez les échecs d'authentification en vérifiant les pages d'erreur, les redirections vers la page de connexion ou des URL d'échec spécifiques.

Exemple :

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

Marque l'authentification comme échouée si l'élément spécifié existe sur la page actuelle.

Paramètres :

- `path` (string) : chemin du sélecteur d'élément qui indique un échec d'authentification.

Utilisation :

Détectez les messages d'erreur, les bannières d'avertissement ou d'autres éléments d'interface indiquant des problèmes d'authentification.

Exemple :

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

## Méthodes de mot de passe à usage unique {#one-time-password-methods}

| Méthode | Description |
|--------|-------------|
| `otp.generateTOTP()` | Générer un mot de passe à usage unique basé sur le temps. |

### `otp.generateTOTP()` {#otpgeneratetotp}

Génère un mot de passe à usage unique basé sur le temps (TOTP) en utilisant le secret configuré.

Prérequis :

- Le secret TOTP doit être encodé en base32 et rendu disponible via `DAST_AUTH_OTP_KEY`.
- L'application doit accepter les codes TOTP standard (généralement des codes à 6 chiffres qui se renouvellent toutes les 30 secondes).

> [!warning]
> Pour prévenir les risques de sécurité, ne définissez pas `DAST_AUTH_OTP_KEY` dans le fichier de définition du job YAML. Créez-la plutôt en tant que variable CI/CD masquée via l'interface utilisateur GitLab. Pour plus d'informations, consultez [les variables CI/CD personnalisées](../../../../../ci/variables/_index.md#for-a-project).

Utilisation :

Utilisez cette méthode pour les applications qui nécessitent une authentification à deux facteurs avec des applications d'authentification comme Google Authenticator, Authy ou des systèmes similaires basés sur TOTP.

Retourne :

- Chaîne de caractères contenant le code TOTP actuel.

Exemple :

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

## Méthodes de journalisation {#logging-methods}

Ajoutez des messages au rapport d'authentification. Cela peut être utile lors du dépannage.

| Méthode | Description |
|--------|-------------|
| `log.info(msg)` | Consigner des messages d'information. |
| `log.debug(msg)` | Consigner des messages de débogage. |
| `log.warn(msg)` | Consigner des messages d'avertissement. |
| `log.trace(msg)` | Consigner des messages de trace. |
| `log.error(msg)` | Consigner des messages d'erreur. |
| `log.errorWithException(ex, msg)` | Consigner des erreurs avec les détails des exceptions. |

### `log.info(msg)` {#loginfomsg}

Consigne des messages d'information fournissant des renseignements généraux sur l'exécution du script.

Paramètres :

- `msg` (string) : le message à consigner.

Utilisation :

Consignez la progression générale du script, les opérations réussies et les jalons importants dans le flux d'authentification.

Exemple :

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

Consigne des informations de débogage détaillées utiles pour résoudre les problèmes liés aux scripts.

Paramètres :

- `msg` (string) : le message de débogage à consigner.

Utilisation :

Consignez des informations étape par étape, les valeurs des variables et les informations de diagnostic pour le débogage du script.

Exemple :

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

Consigne des messages d'avertissement pour des conditions potentiellement problématiques qui n'empêchent pas l'exécution.

Paramètres :

- `msg` (string) : le message d'avertissement à consigner.

Utilisation :

Consignez les problèmes récupérables, les scénarios de repli ou les conditions pouvant indiquer des problèmes sans interrompre le flux d'authentification.

Exemple :

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

Consigne des informations de trace très détaillées pour un débogage fin.

Paramètres :

- `msg` (string) : le message de trace à consigner.

Utilisation :

Consignez des informations détaillées, y compris chaque étape et opération mineure. Généralement utilisé pour des scénarios de débogage complexes.

Exemple :

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

Consigne des messages d'erreur pour les problèmes graves pouvant entraîner l'échec de l'authentification.

Paramètres :

- `msg` (string) : le message d'erreur à consigner.

Utilisation :

Consignez les erreurs critiques, les échecs d'authentification ou toute condition empêchant la réussite de l'exécution du script.

**Exemple :**

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

Consigne des messages d'erreur accompagnés des détails des exceptions pour un rapport d'erreurs complet.

Paramètres :

- `ex` (Exception) : l'objet exception contenant les détails de l'erreur.
- `msg` (string) : message de contexte supplémentaire sur l'erreur.

Utilisation :

Interceptez les exceptions ou gérez des scénarios d'erreur complexes où le contexte de l'erreur et les détails techniques sont tous deux importants.

Exemple :

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

## Sélecteurs d'éléments {#element-selectors}

Les scripts d'authentification utilisent la même syntaxe de sélecteurs que les autres variables CI/CD DAST :

- Sélecteur ID : `id:element-id`
- Sélecteur CSS : `css:.class-name` ou `css:button[type="submit"]`
- Sélecteur Name : `name:field-name`
- Sélecteur XPath : `xpath://input[@id='username']`

## Variables d'environnement {#environment-variables}

Accédez aux données d'authentification sensibles via les variables d'environnement :

```javascript
// Use environment variables for credentials
doc.actionFormInput("id:username", process.env.DAST_AUTH_USERNAME)
doc.actionFormInput("id:password", process.env.DAST_AUTH_PASSWORD)
```

> [!warning]
> Pour prévenir les risques de sécurité, ne définissez pas d'informations sensibles dans le fichier de définition du job YAML. Créez-les plutôt en tant que variables CI/CD masquées via l'interface utilisateur GitLab. Pour plus d'informations, consultez [les variables CI/CD personnalisées](../../../../../ci/variables/_index.md#for-a-project).

## Débogage {#debugging}

Il existe deux façons de comprendre comment votre script s'exécute et quelles actions il a effectuées : le rapport d'authentification et le journal de débogage. Les deux sont joints au job DAST en tant qu'artefacts de job.

Le rapport d'authentification inclut chaque étape de votre script d'authentification avec des captures d'écran pour vous aider à déboguer vos scripts. Le rapport inclut également les requêtes et réponses HTTP, ainsi que le modèle objet de document (DOM). Le rapport d'authentification est généré pour chaque job DAST et collecté en tant qu'artefact de job. Le nom de fichier de l'artefact est `gl-dast-debug-auth-report.html`.

De plus, les scripts d'authentification fournissent une journalisation complète pour vous aider à résoudre les problèmes d'authentification. La journalisation est effectuée dans le journal de débogage joint en tant qu'artefact de job avec le nom `gl-dast-scan.log`. Toutes les actions du script sont automatiquement journalisées avec des informations de débogage indiquant :

- Les affectations de variables d'environnement (avec les valeurs sensibles masquées)
- Les étapes d'exécution du script
- Les actions de navigation par URL
- Les opérations de saisie dans les formulaires
- Les actions de clic
- Les résultats de validation de l'authentification

Exemple de sortie de débogage :

```plaintext
DBG SCRIPT running user script script="auth_script.js"
DBG SCRIPT doc.navigateURL url="https://example.com/login"
DBG SCRIPT doc.actionFormInput onPath="id:username" value="********"
DBG SCRIPT doc.actionLeftClick onPath="css:button[type='submit']"
INF SCRIPT requirement is satisfied, browser URL matches pattern
```

Utilisez les méthodes de journalisation dans vos scripts pour ajouter des informations de débogage personnalisées :

```javascript
log.info("Starting authentication process")
log.debug("Navigating to login page")
// ... authentication steps ...
log.info("Authentication completed successfully")
```

## Dépannage {#troubleshooting}

Lors de l'utilisation de scripts d'authentification, vous pourriez rencontrer les problèmes suivants.

### Échecs d'exécution du script {#script-execution-failures}

Votre script peut échouer à s'exécuter parce que le JavaScript est malformé ou parce que des variables d'environnement sont manquantes.

Pour résoudre :

- Vérifiez que la syntaxe de votre script est du JavaScript valide.
- Vérifiez que toutes les variables d'environnement requises sont définies.
- Utilisez `log.debug()` pour ajouter des points de contrôle dans votre flux d'authentification.

### Problèmes de sélection d'éléments {#element-selection-issues}

Si votre script rencontre des difficultés pour sélectionner des éléments dans l'application cible :

- Testez vos sélecteurs dans les outils de développement du navigateur.
- Consultez le rapport d'authentification avec le DOM inclus.

### Échecs de validation de l'authentification {#authentication-validation-failures}

Votre script pourrait échouer à s'authentifier auprès de l'application cible.

Pour résoudre :

- Assurez-vous que vos conditions de succès ou d'échec reflètent fidèlement l'état de l'authentification.
- Vérifiez les redirections qui pourraient modifier l'URL attendue.
- Utilisez la validation basée sur les éléments comme alternative à la validation basée sur l'URL.

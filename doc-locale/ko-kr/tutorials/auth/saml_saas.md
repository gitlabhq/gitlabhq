---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: '튜토리얼: GitLab.com 그룹에 대한 SAML SSO 설정'
---

이 튜토리얼에서는 Okta 또는 Microsoft Entra ID와 같은 자격증명 공급자(IdP)를 사용하여 GitLab.com 그룹에 대한 SAML 통합 인증(SSO)을 설정하는 방법을 안내합니다. 완료하면 그룹의 구성원이 IdP를 통해 GitLab에 로그인할 수 있습니다.

이 튜토리얼에서 수행할 작업:

1. IdP 애플리케이션을 통해 SAML을 구성합니다.
1. GitLab 그룹에서 SAML SSO를 구성합니다.
1. SAML 연결을 테스트합니다.
1. 사용자 계정을 연결하여 설정을 확인합니다.

## 시작하기 전 {#before-you-begin}

전제 조건:

- GitLab.com의 GitLab Premium 또는 Ultimate 그룹에 대한 소유자 역할이 필요합니다.
- IdP에 대한 관리자 액세스 권한이 필요합니다.
- IdP에 최소 하나의 테스트 사용자 계정이 필요합니다.
- 통합 인증(SSO) 개념에 익숙해야 합니다.

완료 시간: 20-30분

## 1단계:  GitLab 정보 수집 {#step-1-gather-gitlab-information}

IdP에서 무엇을 설정하기 전에 IdP가 GitLab 그룹과 통신하는 방법을 알려주는 GitLab에서 일부 연결 세부 정보를 가져와야 합니다.

GitLab 정보를 수집하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **SAML SSO**를 선택합니다.
1. 다음 값을 참고하세요:
   - **식별자**
   - **어셔션 컨슈머 서비스 (Assertion Consumer Service) URL**
   - **GitLab 통합 인증(SSO) URL**

## 2단계:  IdP 애플리케이션 생성 {#step-2-create-an-idp-application}

이제 GitLab 세부 정보가 준비되었으므로 IdP에서 애플리케이션을 생성합니다. 이 애플리케이션은 GitLab 정보를 IdP에 매핑하고 두 시스템 간의 사용자 정보 플로우를 구성합니다.

IdP 애플리케이션을 생성하려면:

{{< tabs >}}

{{< tab title="Okta" >}}

1. Okta에 관리자로 로그인합니다.
1. Admin Console에서 **응용 프로그램** > **응용 프로그램**을 선택합니다.
1. **Create App Integration**을 선택합니다.
1. **Sign-in method** 섹션에서 **SAML 2.0**을 선택합니다.
1. **다음**을 선택합니다.
1. **일반 설정** 탭에서 애플리케이션의 이름을 입력합니다. 예를 들어, `GitLab SAML`입니다.
1. **다음**을 선택합니다.
1. **Configure SAML** 탭에서 1단계의 값으로 필드를 작성합니다:
   - **Single sign-on URL**: **어셔션 컨슈머 서비스 (Assertion Consumer Service) URL**을 입력합니다.
   - **Use this for Recipient URL and Destination URL** 확인란을 선택합니다.
   - **Audience URI (SP Entity ID)**: **식별자**를 입력합니다.
1. 이름 식별자를 구성합니다:
   - **Application username (NameID)**: **커스텀**을 선택하고 `user.getInternalProperty("id")`을 입력합니다.
   - **Name ID Format**: **Persistent**을 선택합니다.
1. **Attribute Statements (optional)** 섹션에서 이 속성을 추가합니다:
   - **이름**: `email`
   - **값**: `user.email`
1. **Application Login Page** 설정까지 아래로 스크롤합니다:
   - **Login page URL**: **GitLab 통합 인증(SSO) URL**을 입력합니다.
1. **다음**을 선택합니다.
1. **Feedback** 탭에서 사용 사례에 적절한 옵션을 선택합니다.
1. **Finish**을 선택합니다.

SAML 애플리케이션이 Okta에서 생성됩니다.

> [!note]
> SAML 속성 및 고급 구성 옵션에 대한 자세한 내용은 [SAML SSO 설명서](../../user/group/saml_sso/_index.md#okta)를 참조하세요.

{{< /tab >}}

{{< tab title="Entra ID" >}}

1. [Microsoft Entra 관리 센터](https://entra.microsoft.com/)에 로그인합니다.
1. **ID** > **응용 프로그램** > **Enterprise applications**을 선택합니다.
1. **New application**을 선택합니다.
1. **Create your own application**을 선택합니다.
1. 대화 상자에서 필드를 작성합니다:
   - **Name (이름)**: 애플리케이션의 이름을 입력합니다. 이 튜토리얼의 경우 `GitLab SAML`를 사용합니다.
   - **Integrate any other application you don't find in the gallery (Non-gallery)**을 선택합니다.
1. **생성**을 선택합니다.

엔터프라이즈 애플리케이션이 Microsoft Entra ID에서 생성됩니다.

1. 엔터프라이즈 애플리케이션에서 왼쪽 사이드바의 **Single sign-on**을 선택합니다.
1. 통합 인증(SSO) 방법으로 **SAML**을 선택합니다.
1. **Basic SAML Configuration** 섹션에서 **편집**을 선택합니다.
1. 1단계의 값으로 필드를 작성합니다:
   - **Identifier (Entity ID)**: **식별자**를 입력합니다.
   - **Reply URL (Assertion Consumer Service URL)**: **어셔션 컨슈머 서비스 (Assertion Consumer Service) URL**을 입력합니다.
   - **Sign on URL**: **GitLab 통합 인증(SSO) URL**을 입력합니다.
1. **Save**를 선택합니다.
1. **User Attributes & Claims** 섹션에서 **편집**을 선택합니다.
1. **Add new claim**를 선택하고 필드를 작성합니다:
   - **Name (이름)**: `email`을 입력합니다.
   - **Source attribute**: `user.mail`를 선택합니다.
1. **Save**를 선택합니다.
1. **Unique User Identifier (Name ID)** 클레임을 편집합니다:
   - 기존 **Unique User Identifier** 클레임을 선택합니다.
   - **Source attribute**: `user.objectid`를 선택합니다.
   - **Name identifier format**: **Persistent**을 선택합니다.
1. **Save**를 선택합니다.

> [!note]
> SAML 속성 및 고급 구성 옵션에 대한 자세한 내용은 [SAML SSO 설명서](../../user/group/saml_sso/_index.md#azure)를 참조하세요.

{{< /tab >}}

{{< tab title="Google Workspace" >}}

1. [Google 관리 콘솔](https://admin.google.com/)에 로그인합니다.
1. **Apps** > **Web and mobile apps**을 선택합니다.
1. **Add App** > **Add custom SAML app**를 선택합니다.
1. **App Details** 페이지에서 애플리케이션의 이름을 입력합니다. 예를 들어, `GitLab SAML`입니다.
1. **계속**을 선택합니다.
1. **Google Identity Provider details** 페이지에서 이 페이지를 열린 상태로 둡니다. 3단계에서 이 값들이 필요합니다.
1. **계속**을 선택합니다.
1. **Service provider details** 페이지에서 1단계의 값으로 필드를 작성합니다:
   - **ACS URL**: **어셔션 컨슈머 서비스 (Assertion Consumer Service) URL**을 입력합니다.
   - **엔터티 ID**: **식별자**를 입력합니다.
   - **Start URL**: **GitLab 통합 인증(SSO) URL**을 입력합니다.
   - **Name ID format**: **EMAIL**을 선택합니다.
   - **Name ID**: **기본 정보** > **기본 이메일**을 선택합니다.
1. **계속**을 선택합니다.
1. **Attribute mapping** 페이지에서 이 속성들을 추가합니다:
   - **Google Directory attribute**: `Primary email`, **App attribute**: `email`
   - **Google Directory attribute**: `First name`, **App attribute**: `first_name`
   - **Google Directory attribute**: `Last name`, **App attribute**: `last_name`
1. **Finish**을 선택합니다. SAML 애플리케이션이 Google Workspace에서 생성됩니다.
1. 사용자를 위해 애플리케이션을 켭니다:
   - **User access** 섹션에서 **ON for everyone**를 선택합니다.
   - **Save**를 선택합니다.

SAML 속성 및 고급 구성 옵션에 대한 자세한 내용은 [SAML SSO 설명서](../../user/group/saml_sso/_index.md#google-workspace)를 참조하세요.

{{< /tab >}}

{{< tab title="OneLogin" >}}

1. OneLogin에 관리자로 로그인합니다.
1. **Administration** > **응용 프로그램**을 선택합니다.
1. **Add App**를 선택합니다.
1. **SAML Test Connector (Advanced)**를 검색하여 선택합니다.
1. **Display Name** 필드에 애플리케이션의 이름을 입력합니다. 예를 들어, `GitLab SAML`입니다.
1. **Save**를 선택합니다.
1. **구성** 탭을 선택합니다.
1. 1단계의 값으로 필드를 작성합니다:
   - **Audience (EntityID)**: **식별자**를 입력합니다.
   - **Recipient**: **어셔션 컨슈머 서비스 (Assertion Consumer Service) URL**을 입력합니다.
   - **ACS (Consumer) URL Validator**: **어셔션 컨슈머 서비스 (Assertion Consumer Service) URL**을 정규 표현식으로 입력합니다. 예를 들어, `https://gitlab\.com/groups/your-group/-/saml/callback`입니다.
   - **ACS (Consumer) URL**: **어셔션 컨슈머 서비스 (Assertion Consumer Service) URL**을 입력합니다.
   - **Login URL**: **GitLab 통합 인증(SSO) URL**을 입력합니다.
1. **Save**를 선택합니다.
1. **파라매터** 탭을 선택합니다.
1. **Add parameter**를 선택하여 필수 속성을 추가합니다:
   - **Field name**: `email`, **값**: 이메일
1. **NameID**의 경우 값 필드에서 **OneLogin ID**를 선택합니다.
1. **Save**를 선택합니다.
1. **액세스** 탭을 선택하여 애플리케이션에 사용자 또는 역할을 할당합니다.

SAML 애플리케이션이 OneLogin에서 생성됩니다.

SAML 속성 및 고급 구성 옵션에 대한 자세한 내용은 [SAML SSO 설명서](../../user/group/saml_sso/_index.md#onelogin)를 참조하세요.

{{< /tab >}}

{{< tab title="Keycloak" >}}

1. Keycloak에 관리자로 로그인합니다.
1. **클라이언트**로 이동하여 **Create client**을 선택합니다.
1. **일반 설정** 페이지에서 **SAML**을 **Client type**으로 선택합니다.
1. 1단계의 값으로 필드를 작성합니다:
   - **클라이언트 ID**: **식별자**를 입력합니다.
   - **Valid redirect URIs**: **어셔션 컨슈머 서비스 (Assertion Consumer Service) URL**을 입력합니다.
   - **Assertion Consumer Service POST Binding URL**: **어셔션 컨슈머 서비스 (Assertion Consumer Service) URL**을 입력합니다.
   - **Home URL**: **GitLab 통합 인증(SSO) URL**을 입력합니다.
1. **Save**를 선택합니다.
1. **설정** 탭의 **SAML capabilities** 섹션에서:
   - **Name ID format**: `persistent`를 선택합니다.
   - **Force name ID format** 토글을 켭니다.
   - **Force POST binding** 토글을 켭니다.
   - **Include AuthnStatement** 토글을 켭니다.
1. **Signature and Encryption** 섹션에서 **Sign documents** 토글을 켭니다.
1. **키** 탭에서 모든 섹션이 비활성화되어 있는지 확인합니다.
1. **Client scopes** 탭에서:
   - GitLab의 클라이언트 범위를 선택합니다.
   - **Configure a new mapper**을 선택하고 열리는 창에서 **User Attribute**을 선택합니다.
   - **Add mapper** 페이지에서 **이름**, **User Attribute** 및 **SAML Attribute Name** 필드를 `email`으로 설정합니다.
   - **Save**를 선택합니다.

SAML 클라이언트가 Keycloak에서 생성됩니다.

> [!note]
> SAML 속성 및 고급 구성 옵션에 대한 자세한 내용은 [SAML SSO 설명서](../../user/group/saml_sso/_index.md#keycloak)를 참조하세요.

{{< /tab >}}

{{< tab title="AWS IAM Identity Center" >}}

1. AWS IAM Identity Center 콘솔에 로그인합니다.
1. **응용 프로그램**을 선택한 다음 **Add application**를 선택합니다.
1. **I have an application I want to set up**를 선택합니다.
1. 애플리케이션 유형으로 **SAML 2.0**을 선택합니다.
1. **다음**을 선택합니다.
1. **Configure application** 페이지에서 애플리케이션의 표시 이름을 입력합니다. 예를 들어, `GitLab SAML`입니다.
1. 1단계의 값으로 필드를 작성합니다:
   - **Application ACS URL**: **어셔션 컨슈머 서비스 (Assertion Consumer Service) URL**을 입력합니다.
   - **Application SAML audience**: **식별자**를 입력합니다.
   - **Application start URL**: **GitLab 통합 인증(SSO) URL**을 입력합니다.
1. **Attribute mappings** 아래에서 이 속성들을 구성합니다:
   - **제목**: `${user:email}`, **포맷**: `unspecified`
   - **email**: `${user:email}`, **포맷**: `unspecified`
   - **first_name**: `${user:givenName}`, **포맷**: `unspecified`
   - **last_name**: `${user:familyName}`, **포맷**: `unspecified`

   > [!warning]
   > 기존 GitLab 사용자의 인증 오류를 방지하려면 형식을 `persistent` 또는 `transient`로 설정하지 마세요.

1. **제출**을 선택합니다. SAML 애플리케이션이 AWS IAM Identity Center에서 생성됩니다.
1. GitLab 애플리케이션에 사용자를 할당합니다.

SAML 속성 및 고급 구성 옵션에 대한 자세한 내용은 [SAML SSO 설명서](../../user/group/saml_sso/_index.md#aws-iam-identity-center)를 참조하세요.

> [!note]
> AWS IAM Identity Center는 기본적으로 IdP 시작 로그인으로 설정됩니다. 기존 GitLab 계정을 연결하려면 사용자는 **GitLab 통합 인증(SSO) URL** 또는 **Application start URL**에서 로그인해야 합니다.

{{< /tab >}}

{{< /tabs >}}

## 3단계:  연결 세부 정보 수집 {#step-3-gather-the-connection-details}

이제 GitLab이 IdP에 인증 요청을 보내기 위해 필요한 정보를 검색합니다.

연결 세부 정보를 수집하려면:

{{< tabs >}}

{{< tab title="Okta" >}}

1. Okta SAML 앱에서 **Sign On** 탭을 선택합니다.
1. 오른쪽에서 **View SAML setup instructions**를 선택합니다.
1. **Identity Provider Single Sign-On URL**을 참고하세요.
1. 인증서 핑거프린트를 생성합니다:
   1. **X.509 Certificate** 필드에서 텍스트를 복사하고 로컬에 저장합니다.
   1. 터미널을 열고 인증서 파일을 저장한 디렉터리로 이동합니다.
   1. 인증서 핑거프린트를 생성하려면 이 명령을 실행합니다:

   ```shell
      # Replace `<certificate_filename>` with the actual filename of your downloaded certificate.
      # You might need to install OpenSSL or use an alternative method to generate the fingerprint.
       openssl x509 -noout -fingerprint -sha256 -in <certificate_filename>.crt
   ```

1. `SHA256 Fingerprint=` 뒤의 핑거프린트 값을 복사합니다. 핑거프린트는 `A1:B2:C3:D4:E5:F6:...` 형태입니다.

{{< /tab >}}

{{< tab title="Entra ID" >}}

1. Entra ID 엔터프라이즈 애플리케이션에서 **Single sign-on**을 선택합니다.
1. **Set up GitLab SAML** 섹션에서 **Login URL**을 참고하세요. 이 섹션의 이름은 엔터프라이즈 애플리케이션의 이름을 기반으로 합니다.
1. **SAML Signing Certificate** 섹션에서 **Thumbprint** 값을 참고하세요. 지문은 `A1B2C3D4E5F6...` 형태입니다.

{{< /tab >}}

{{< tab title="Google Workspace" >}}

1. Google Workspace SAML 앱에서 앱 세부 정보 페이지로 이동합니다.
1. **SSO URL** 값을 참고하세요.
1. 인증서에 대해 표시된 **SHA-256 fingerprint** 값을 참고하세요. 핑거프린트는 `A1:B2:C3:D4:E5:F6:...` 형태입니다.

{{< /tab >}}

{{< tab title="OneLogin" >}}

1. OneLogin SAML 앱에서 **SSO** 탭을 선택합니다.
1. **SAML 2.0 Endpoint (HTTP)** URL을 참고하세요.
1. **X.509 Certificate** 섹션에서 **View Details**를 선택합니다.
1. **SHA-256 Fingerprint** 값을 참고하세요. 핑거프린트는 `A1:B2:C3:D4:E5:F6:...` 형태입니다.

{{< /tab >}}

{{< tab title="Keycloak" >}}

1. Keycloak SAML 클라이언트의 **조치** 드롭다운 목록에서 **Download adapter config**를 선택합니다.
1. **Download adapter config** 대화 상자에서 드롭다운 목록에서 **mod-auth-mellon**을 선택합니다.
1. **다운로드**를 선택합니다.
1. 다운로드한 아카이브를 추출하고 `idp-metadata.xml`을 엽니다.
1. `<md:SingleSignOnService>` 태그를 찾고 `Location` 속성의 값을 참고하세요.
1. 인증서 핑거프린트를 생성합니다:
   1. `<ds:X509Certificate>` 태그를 찾고 값을 별도의 파일에 복사합니다.
   1. 값을 PEM 형식으로 변환합니다. 파일의 시작 부분에 `-----BEGIN CERTIFICATE-----`을 추가하고 파일의 끝에 `-----END CERTIFICATE-----`을 새 줄로 추가합니다.

{{< /tab >}}

{{< tab title="AWS IAM Identity Center" >}}

1. AWS IAM Identity Center SAML 앱에서 생성한 애플리케이션을 선택합니다.
1. **IAM Identity Center SAML metadata** 섹션에서 **IAM Identity Center sign-in URL**을 참고하세요.
1. 인증서를 다운로드합니다.
1. 인증서 핑거프린트를 생성합니다:
   1. 터미널을 열고 인증서 파일을 저장한 디렉터리로 이동합니다.
   1. 인증서 핑거프린트를 생성하려면 이 명령을 실행합니다:

   ```shell
   # Replace `<certificate_filename>` with the actual filename of your downloaded certificate.
   # You might need to install OpenSSL or use an alternative method to generate the fingerprint.
   openssl x509 -noout -fingerprint -sha256 -in <certificate_filename>.pem
   ```

1. `SHA1 Fingerprint=` 뒤의 핑거프린트 값을 복사합니다. 핑거프린트는 `A1:B2:C3:D4:E5:F6:...` 형태입니다.

> [!note]
> AWS IAM Identity Center에는 SHA1 핑거프린트가 필요합니다. 자세한 내용은 [SAML SSO 설명서](../../user/group/saml_sso/_index.md#aws-iam-identity-center)를 참조하세요.

{{< /tab >}}

{{< /tabs >}}

## 4단계:  GitLab에서 SAML SSO 구성 {#step-4-configure-saml-sso-in-gitlab}

연결을 완료하는 데 필요한 모든 것을 갖추었습니다. GitLab으로 돌아가서 연결 세부 정보를 입력하여 그룹에 대한 SAML 인증을 활성화합니다.

SAML을 구성하려면:

1. GitLab 그룹으로 돌아갑니다.
1. **설정** > **SAML SSO**를 선택합니다.
1. **구성** 섹션에서 필드를 작성합니다:
   - **자격증명 공급자 통합 인증(SSO)**: 3단계의 URL을 입력합니다.
   - **인증서 핑거프린트**: 3단계의 핑거프린트를 입력합니다.
1. **이 그룹에 SAML 인증 활성화** 확인란을 선택합니다.
1. **멤버십 역할 기본값** 드롭다운 목록에서 **최소 액세스**를 선택합니다.
1. **변경사항 저장**을 선택합니다.

기본 SAML 연결이 이제 구성되었습니다.

> [!note]
> 기본 멤버십 역할을 어떤 역할로든 설정할 수 있습니다. 모든 새로운 사용자는 SAML을 통해 처음 로그인할 때 이 역할이 할당됩니다. 기본값을 [**최소 액세스**](../../user/permissions.md#users-with-minimal-access)로 설정하고 나중에 사용자를 승격시키면 사용자가 너무 많은 액세스 권한을 가질 위험을 줄입니다.

## 5단계:  SAML 구성 테스트 {#step-5-test-the-saml-configuration}

팀을 초대하기 전에 연결이 제대로 작동하는지 확인합니다.

SAML 구성을 테스트하려면:

1. **설정** > **SAML SSO** 페이지에서 **SAML 구성 확인**을 선택합니다. GitLab이 IdP로 리디렉션합니다.
1. IdP 자격증명으로 로그인합니다.
1. IdP가 GitLab으로 리디렉션되는지 확인합니다.

오류가 표시되면 [문제 해결 가이드](../../user/group/saml_sso/troubleshooting.md)를 참조하세요.

## 6단계:  사용자 계정을 연결하여 전체 플로우 테스트 {#step-6-link-a-user-account-to-test-the-full-flow}

구성이 양호합니다. 이제 팀 구성원이 처음 IdP를 통해 GitLab에 연결할 때처럼 테스트 계정을 연결하여 사용자 관점에서 환경을 테스트합니다.

사용자 계정 연결을 테스트하려면:

1. GitLab에서 로그아웃합니다.
1. 다른 브라우저 또는 시크릿 창에서 테스트 GitLab 계정에 로그인합니다.
1. 1단계에서 참고한 GitLab 통합 인증(SSO) URL로 이동합니다.
1. **권한 부여**를 선택합니다.
1. 메시지가 표시되면 IdP 자격증명으로 로그인합니다.
1. GitLab 그룹으로 리디렉션되는지 확인합니다.

축하합니다! SAML 자격증명을 GitLab 계정에 성공적으로 연결했습니다.

## 7단계:  선택 사항:  SSO 적용 활성화 {#step-7-optional-turn-on-sso-enforcement}

작동하는 SAML 설정이 있습니다. 선택 사항으로 마지막 단계로 SSO 적용을 활성화할 수 있습니다. SSO 적용을 사용하면 모든 그룹 구성원이 IdP를 통해 인증해야 하므로 보안이 강화됩니다. 그러나 다른 인증 방법을 통한 액세스를 방지합니다.

SSO 적용을 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **SAML SSO**를 선택합니다.
1. **이 그룹에 대한 웹 활동에 SSO 전용 인증 강제 적용**을 선택합니다.
1. **변경사항 저장**을 선택합니다.

적용을 활성화한 후 모든 그룹 구성원은 그룹 리소스에 액세스하기 전에 IdP를 통해 로그인해야 합니다.

## 다음 단계 {#next-steps}

GitLab 그룹에 대한 SAML SSO 설정을 완료했습니다! 다음으로 수행할 수 있는 작업은 다음과 같습니다:

- [SCIM 프로비저닝 설정](../../user/group/saml_sso/scim_setup.md)으로 사용자를 자동으로 동기화합니다.
- [그룹 동기화 구성](../../user/group/saml_sso/group_sync.md)으로 IdP 그룹을 기반으로 GitLab 그룹 멤버십을 관리합니다.
- 도메인을 확인하여 새 사용자를 위한 [사용자 이메일 확인 우회](../../user/group/saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains)합니다.
- 고급 보안 옵션을 위해 [SSO 적용 설명서](../../user/group/saml_sso/_index.md#sso-enforcement)를 검토합니다.

## 문제 해결 {#troubleshooting}

이 튜토리얼 중에 이슈가 발생하면 다음 리소스를 참조하세요:

- [일반적인 SAML 오류 및 솔루션](../../user/group/saml_sso/troubleshooting.md)
- [계정 연결 해제 및 다시 연결하는 방법](../../user/group/saml_sso/_index.md#unlink-accounts)
- [지원 리소스](https://support.gitlab.com/)

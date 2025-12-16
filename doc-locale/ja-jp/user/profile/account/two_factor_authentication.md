---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 2要素認証
description: アカウント保護を強化するために、多要素認証を有効にします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

2要素認証（2FA）を使用すると、GitLabアカウントのセキュリティがさらに強化されます。あなたのアカウントに他のユーザーがアクセスするには、ユーザー名とパスワードに加えて、2番目の認証要素へのアクセスが必要になります。

GitLabでは、2番目の認証要素として以下をサポートしています:

- ワンタイムパスワード認証アプリ（[OTP](https://datatracker.ietf.org/doc/html/rfc6238)）。有効にすると、サインイン時にコードの入力を求められます。コードは、OTP認証アプリ（お使いのデバイスのパスワードマネージャーなど）で生成されます。
- WebAuthnデバイス。サインインするためにユーザー名とパスワードを入力すると、WebAuthnデバイスをアクティブにする（通常はデバイスのボタンを押す）ように求められます。これにより、お客様に代わって安全な認証が実行されます。

デバイスを設定する場合は、OTPも設定して、デバイスを紛失した場合でもアカウントにアクセスできるようにしてください。

## 2要素認証にパーソナルアクセストークンを使用する {#use-personal-access-tokens-with-two-factor-authentication}

2FAが有効になっている場合、HTTPS経由のGitまたは[GitLab API](../../../api/rest/_index.md)でパスワードを使用して認証することはできません。代わりに[パーソナルアクセストークン](../personal_access_tokens.md)を使用できます。

## OAuth認証情報ヘルパー {#oauth-credential-helpers}

次のGit認証情報ヘルパーは、OAuthを使用してGitLabに対して認証を行います。これは2要素認証に対応しています。初回認証時に、ヘルパーがWebブラウザを開き、GitLabがアプリを承認するように求めます。2回目以降の認証に操作は必要ありません。

### Git Credential Manager {#git-credential-manager}

[Git Credential Manager](https://github.com/GitCredentialManager/git-credential-manager)（GCM）では、OAuthがデフォルトで認証に使用されます。手動で設定しなくてもGCMはGitLab.comをサポートします。GitLab Self-ManagedでGCMを使用するには、[GitLabサポート](https://github.com/GitCredentialManager/git-credential-manager/blob/main/docs/gitlab.md)を参照してください。

プッシュのたびに再認証する必要がないように、GCMはキャッシュと、セッション間で永続化するさまざまなプラットフォーム固有の認証情報ストアをサポートしています。この機能は、パーソナルアクセストークンを使用するかOAuthを使用するかにかかわらず役立ちます。

Git for WindowsにはGit Credential Managerが含まれています。

Git Credential Managerは、主にGitHub, Inc.によって開発されています。これはオープンソースプロジェクトであり、コミュニティによってサポートされています。

### git-credential-oauth {#git-credential-oauth}

[git-credential-oauth](https://github.com/hickford/git-credential-oauth)は、手動設定なしでGitLab.comといくつかの一般的なパブリックホストをサポートします。GitLab Self-Managedで使用するには、[git-credential-oauthカスタムホストのドキュメント](https://github.com/hickford/git-credential-oauth#custom-hosts)を参照してください。

多くのLinuxディストリビューションには、git-credential-oauthがパッケージとして含まれています。

git-credential-oauthはオープンソースプロジェクトで、コミュニティによってサポートされています。

## 2要素認証を有効にする {#enable-two-factor-authentication}

2FAは、次のいずれかを使用して有効にできます:

- OTP認証アプリ。2FAを有効にした後、[リカバリーコード](#recovery-codes)をバックアップしてください。
- WebAuthnデバイス。

2FAを有効にするには、アカウントのメールアドレスを確認する必要があります。

### ワンタイムパスワード認証アプリを有効にする {#enable-a-one-time-password-authenticator}

OTP認証アプリで2FAを有効にするには、次の手順を実行します:

1. **GitLab全体で**:
   1. [**ユーザー設定**](../_index.md#access-your-user-settings)にアクセスします。
   1. **アカウント**を選択します。
   1. **Enable Two-factor Authentication**（2要素認証を有効にする）を選択します。
1. **On your device (usually your phone)**（デバイス（通常はお使いの携帯電話）の場合）:
   1. 互換性のあるアプリケーションをインストールします。次に例を示します:
      - クラウドベース（ハードウェアデバイスを紛失した場合にアクセスを復元できるため推奨されています）:
        - [Authy](https://authy.com/)。
        - [Cisco Duo](https://duo.com/)。
      - その他（プロプライエタリ）:
        - [Google Authenticator](https://support.google.com/accounts/answer/1066447?hl=en)。
        - [Microsoft Authenticator](https://www.microsoft.com/en-us/security/mobile-authenticator-app)。
      - その他（無料ソフトウェア）
        - [Aegis Authenticator](https://getaegis.app/)。
        - [FreeOTP](https://freeotp.github.io/)。
   1. アプリケーションで、次のいずれかの方法を使って新しいエントリを追加します:
      - GitLabに表示されたコードをデバイスのカメラでスキャンして、エントリを自動的に追加します。
      - 提供された詳細を入力して、エントリを手動で追加します。
1. **GitLab全体で**:
   1. デバイスのエントリからの6桁のピン番号を**Pin code**に入力します。
   1. 現在のパスワードを入力します。
   1. **送信**を選択します。

正しいピンを入力すると、[リカバリーコード](#recovery-codes)のリストが表示されます。それらをダウンロードして、安全な場所に保管してください。

### FortiAuthenticatorを使用してワンタイムパスワード認証アプリを有効にする {#enable-a-one-time-password-authenticator-using-fortiauthenticator}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`forti_authenticator`という名前の[機能フラグを有効にする](../../../administration/feature_flags/_index.md)と、ユーザーごとにこの機能を使用できるようになります。GitLab.comとGitLab Dedicatedでは、この機能は使用できません。

{{< /alert >}}

GitLabでFortiAuthenticatorをOTPプロバイダーとして使用できます。ユーザーは次の条件を満たしている必要があります:

- FortiAuthenticatorとGitLabの両方に、同じユーザー名で存在すること。
- FortiAuthenticatorでFortiTokenが設定されていること。

FortiAuthenticatorのユーザー名とアクセストークンが必要です。以下に示す`access_token`は、FortiAuthenticatorのアクセスキーです。トークンを取得するには、[Fortinetドキュメントライブラリ](https://docs.fortinet.com/document/fortiauthenticator/6.2.0/rest-api-solution-guide/158294/the-fortiauthenticator-api)にあるREST APIソリューションガイドを参照してください。FortiAuthenticatorバージョン6.2.0でテスト済み。

GitLabでFortiAuthenticatorを設定します。GitLabサーバーで:

1. 設定ファイルを開きます。

   Linuxパッケージインストールの場合:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   自己コンパイルインストールの場合:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. プロバイダー設定を追加します。

   Linuxパッケージインストールの場合:

   ```ruby
   gitlab_rails['forti_authenticator_enabled'] = true
   gitlab_rails['forti_authenticator_host'] = 'forti_authenticator.example.com'
   gitlab_rails['forti_authenticator_port'] = 443
   gitlab_rails['forti_authenticator_username'] = '<some_username>'
   gitlab_rails['forti_authenticator_access_token'] = 's3cr3t'
   ```

   自己コンパイルインストールの場合:

   ```yaml
   forti_authenticator:
     enabled: true
     host: forti_authenticator.example.com
     port: 443
     username: <some_username>
     access_token: s3cr3t
   ```

1. 設定ファイルを保存します。
1. [再設定](../../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) （Linuxパッケージインストール）または[再起動](../../../administration/restart_gitlab.md#self-compiled-installations)（自己コンパイルインストール）を行います。

### Cisco Duoを使用してワンタイムパスワード認証アプリを有効にする {#enable-a-one-time-password-authenticator-using-cisco-duo}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/15760)されました。

{{< /history >}}

GitLabでCisco DuoをOTPプロバイダーとして使用できます。

DUO®は、米国およびその他の特定の国におけるCisco Systems, Inc.、および/またはその関連会社の登録商標です。

#### 前提要件 {#prerequisites}

Cisco DuoをOTPプロバイダーとして使用するには:

- アカウントがCisco DuoとGitLabの両方に存在し、両方のアプリケーションで同じユーザー名が使用されている必要があります。
- [Cisco Duoが設定済み](https://admin.duosecurity.com/)で、統合キー、シークレットキー、およびAPIホスト名が必要です。

詳細については、[Cisco Duo APIドキュメント](https://duo.com/docs/authapi)を参照してください。

GitLab 15.10は、Cisco DuoバージョンD261.14でテスト済みです。

#### GitLabでCisco Duoを設定する {#configure-cisco-duo-in-gitlab}

GitLabサーバーで:

1. 設定ファイルを開きます。

   Linuxパッケージインストールの場合:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   自己コンパイルインストールの場合:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. プロバイダー設定を追加します。

   Linuxパッケージインストールの場合:

   ```ruby
    gitlab_rails['duo_auth_enabled'] = false
    gitlab_rails['duo_auth_integration_key'] = '<duo_integration_key_value>'
    gitlab_rails['duo_auth_secret_key'] = '<duo_secret_key_value>'
    gitlab_rails['duo_auth_hostname'] = '<duo_api_hostname>'
   ```

   自己コンパイルインストールの場合:

   ```yaml
   duo_auth:
     enabled: true
     hostname: <duo_api_hostname>
     integration_key: <duo_integration_key_value>
     secret_key: <duo_secret_key_value>
   ```

1. 設定ファイルを保存します。
1. Linuxパッケージインストールの場合、[GitLabを再設定](../../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)します。自己コンパイルインストールの場合、[GitLabを再起動](../../../administration/restart_gitlab.md#self-compiled-installations)します。

### FortiToken Cloudを使用してワンタイムパスワード認証アプリを有効にする {#enable-a-one-time-password-authenticator-using-fortitoken-cloud}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`forti_token_cloud`という名前の[機能フラグを有効にする](../../../administration/feature_flags/_index.md)と、ユーザーごとにこの機能を使用できるようになります。GitLab.comとGitLab Dedicatedでは、この機能は使用できません。この機能は本番環境での使用には対応していません。

{{< /alert >}}

GitLabでFortiToken CloudをOTPプロバイダーとして使用できます。ユーザーは次の条件を満たしている必要があります:

- FortiToken CloudとGitLabの両方に、同じユーザー名で存在すること。
- FortiToken CloudでFortiTokenが設定されていること。

FortiToken Cloudを設定するには、`client_id`と`client_secret`が必要です。これらを取得するには、[Fortinetドキュメントライブラリ](https://docs.fortinet.com/document/fortitoken-cloud/latest/rest-api/456035/overview)にあるREST APIガイドを参照してください。

GitLabでFortiToken Cloudを設定します。GitLabサーバーで:

1. 設定ファイルを開きます。

   Linuxパッケージインストールの場合:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   自己コンパイルインストールの場合:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. プロバイダー設定を追加します。

   Linuxパッケージインストールの場合:

   ```ruby
   gitlab_rails['forti_token_cloud_enabled'] = true
   gitlab_rails['forti_token_cloud_client_id'] = '<your_fortinet_cloud_client_id>'
   gitlab_rails['forti_token_cloud_client_secret'] = '<your_fortinet_cloud_client_secret>'
   ```

   自己コンパイルインストールの場合:

   ```yaml
   forti_token_cloud:
     enabled: true
     client_id: YOUR_FORTI_TOKEN_CLOUD_CLIENT_ID
     client_secret: YOUR_FORTI_TOKEN_CLOUD_CLIENT_SECRET
   ```

1. 設定ファイルを保存します。
1. [再設定](../../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) （Linuxパッケージインストール）または[再起動](../../../administration/restart_gitlab.md#self-compiled-installations)（自己コンパイルインストール）を行います。

### WebAuthnデバイスをセットアップする {#set-up-a-webauthn-device}

{{< history >}}

- WebAuthnデバイスのオプションのワンタイムパスワード認証は、GitLab 15.10で`webauthn_without_totp`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/378844)されました。
- GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/396931)になりました。機能フラグ`webauthn_without_totp`は削除されました。

{{< /history >}}

WebAuthnは以下で[サポートされています](https://caniuse.com/#search=webauthn):

- デスクトップブラウザ:
  - Chrome
  - Edge
  - Firefox
  - Opera
  - Safari
- モバイルブラウザ:
  - Chrome for Android
  - Firefox for Android
  - iOS Safari（iOS 13.3以降）

WebAuthn互換デバイスで2FAを設定するには:

1. （オプション）[OTP認証アプリを設定します](#enable-a-one-time-password-authenticator)。
1. [**ユーザー設定**](../_index.md#access-your-user-settings)にアクセスします。
1. **アカウント**を選択します。
1. **Enable Two-Factor Authentication**（2要素認証を有効にする）を選択します。
1. WebAuthnデバイスを接続します。
1. デバイス名とGitLabアカウントのパスワードを入力します（GitLab 15.10以降）。Identity Provider経由でサインインしている場合は、このパスワードの入力は不要になることがあります。
1. **Set up New WebAuthn Device**（新しいWebAuthnデバイスのセットアップ）を選択します。
1. デバイスによっては、ボタンを押したり、センサーに触れたりする必要があるかもしれません。

デバイスが正常にセットアップされたことを示すメッセージが表示されます。

WebAuthn互換デバイスで2FAをセットアップすると、そのデバイスは特定のコンピューター上の特定のブラウザーにリンクされます。ブラウザとWebAuthnデバイスによっては、別のブラウザまたはコンピューターでWebAuthnデバイスを使用するように設定できる場合があります。

今回初めて2FAを設定する場合は、アクセスを失った場合にアカウントへのアクセスを回復できるように、[リカバリーコード](#recovery-codes)をダウンロードする必要があります。

{{< alert type="warning" >}}

ブラウザデータをクリアすると、アカウントへのアクセスを失う可能性があります。

{{< /alert >}}

## リカバリーコード {#recovery-codes}

OTP認証アプリで2FAを有効にするとすぐに、生成された一連のリカバリーコードをダウンロードするように求めるプロンプトが表示されます。OTP認証アプリへのアクセスを失った場合、これらのリカバリーコードのいずれかを使用してアカウントにサインインできます。

{{< alert type="warning" >}}

各コードをアカウントへのサインインに使用できるのは1回のみです。

{{< /alert >}}

コードをコピーして印刷するか、**コードをダウンロード**して安全な場所に保存することをお勧めします。ダウンロードを選択した場合、ファイル名は`gitlab-recovery-codes.txt`です。

{{< alert type="note" >}}

- リカバリーコードは、WebAuthnデバイスでは生成されません。
- `gitlab-sshd`はリカバリーコードの再生成には適していません。

{{< /alert >}}

リカバリーコードを紛失した場合、または新しいコードを生成する場合は、次のいずれかを使用できます:

- [2FAアカウント設定](#regenerate-two-factor-authentication-recovery-codes)ページ。
- [SSH](two_factor_authentication_troubleshooting.md#generate-new-recovery-codes-using-ssh)。

### 2要素認証リカバリーコードを再生成する {#regenerate-two-factor-authentication-recovery-codes}

2FAリカバリーコードを再生成するには、デスクトップブラウザへのアクセスが必要です:

1. [**ユーザー設定**](../_index.md#access-your-user-settings)にアクセスします。
1. **アカウント** > **Two-Factor Authentication (2FA)**（2要素認証（2FA））を選択します。
1. 2FAをすでに設定している場合は、**2要素認証の管理**を選択します。
1. **二要素認証の無効化**セクションで、**リカバリコードの再発行**を選択します。
1. ダイアログで現在のパスワードを入力し、**リカバリコードの再発行**を選択します。

{{< alert type="note" >}}

2FAリカバリーコードを再生成する場合は、保存してください。以前に作成した2FAコードは使用できません。

{{< /alert >}}

## 2要素認証が有効になっている状態でサインインする {#sign-in-with-two-factor-authentication-enabled}

2FAを有効にしたサインインは、一般的なサインインプロセスとわずかに異なります。ユーザー名とパスワードを入力すると、有効にした2FAの種類に応じて、2番目のプロンプトが表示されます。

### ワンタイムパスワード認証アプリを使用してサインインする {#sign-in-using-a-one-time-password-authenticator}

求められた時点で、OTP認証アプリからのピンコードまたはリカバリーコードを入力してサインインします。

### WebAuthnデバイスを使用してサインインする {#sign-in-using-a-webauthn-device}

サポートされているブラウザでは、認証情報を入力した後、WebAuthnデバイスをアクティブにする（たとえば、ボタンに触れたり押したりする）ように求めるプロンプトが自動的に表示されます。

デバイスが認証リクエストに応答したことを示すメッセージが表示され、自動的にサインインされます。

## 2要素認証を無効にする {#disable-two-factor-authentication}

{{< history >}}

- OTP認証アプリとWebAuthnデバイスを個別または同時に無効にする機能は、GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393419)されました。

{{< /history >}}

OTP認証アプリとWebAuthnデバイスは、個別にも同時にも無効にできます。同時に無効にするには:

1. [**ユーザー設定**](../_index.md#access-your-user-settings)にアクセスします。
1. **アカウント**を選択します。
1. **2要素認証の管理**を選択します。
1. **二要素認証の無効化**セクションで、**二要素認証の無効化**を選択します。
1. ダイアログで現在のパスワードを入力し、**二要素認証の無効化**を選択します。

これにより、モバイルアプリケーションやWebAuthnデバイスなど、すべての2FA登録がクリアされます。

## GitLab管理者向けの情報 {#information-for-gitlab-administrators}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

- [GitLabバックアップの復元](../../../administration/backup_restore/_index.md)後も2FAが動作し続けるように注意してください。
- 2FAがOTPサーバーで正しく認証されるようにするには、NTPなどのサービスを使用してGitLabサーバーの時刻を同期します。そうしないと、時刻のずれが原因で認証が常に失敗する可能性があります。
- GitLabインスタンスに複数のホスト名またはFQDNからアクセスする場合、GitLab WebAuthnの実装は正常に機能しません。各WebAuthn登録は、登録時の現在のホスト名にリンクされており、他のホスト名またはFQDNには使用できません。

  たとえば、ユーザーが`first.host.xyz`と`second.host.xyz`からGitLabインスタンスにアクセスしようとしている場合:

  - ユーザーは`first.host.xyz`を使用してサインインし、WebAuthnキーを登録します。
  - ユーザーはサインアウトし、`first.host.xyz`を使用してサインインを試みます。WebAuthn認証は成功します。
  - ユーザーはサインアウトし、`second.host.xyz`を使用してサインインを試みます。WebAuthnキーは`first.host.xyz`にのみ登録されているため、WebAuthn認証は失敗します。

- システムまたはグループレベルで2FAを強制するには、[2要素認証の強制](../../../security/two_factor_authentication.md)を参照してください。

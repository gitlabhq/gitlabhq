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

GitLabは、次の2要素認証方式をサポートしています:

- ワンタイムパスワード（[OTP](https://datatracker.ietf.org/doc/html/rfc6238)）認証システム。サインイン時に、GitLabからOTP認証システムで生成されたコードの入力を求められます。
- WebAuthnデバイス。サインイン時に、GitLabからWebAuthnデバイスの所有権の証明を求められます。これは通常、YubiKey、スマートフォン、ラップトップのような物理デバイスです。
- メールOTP。サインイン時に、GitLabからメールアドレスに送信されたコードの入力を求められます。

デバイスを設定する場合は、OTPも設定して、デバイスを紛失した場合でもアカウントにアクセスできるようにしてください。

## 2要素認証を有効にする {#enable-two-factor-authentication}

2要素認証を有効にするには、メールアドレスを確認し、OTP認証システム、WebAuthnデバイス、またはメールOTPを登録します。

### OTP認証システムの登録 {#register-an-otp-authenticator}

> [!warning] OTP認証システムへのアクセスを失うと、アカウントからロックアウトされる可能性があります。
> 
> このリスクを最小限に抑えるには、次の手順を実行します:
> 
> - 認証システムアプリでクラウドバックアップを有効にします。
> - リカバリーパスワード、シークレットキー、またはリカバリー認証情報を安全な場所に保存します。
> - 特定のOTP認証システムのドキュメントを確認します。

OTP認証システムを登録するには、次の手順を実行します:

1. GitLabを設定します。
   1. 右上隅でアバターを選択します。
   1. **プロファイルを編集**を選択します。
   1. 左側のサイドバーで、**アカウント**を選択します。
   1. **2要素認証を有効にする**を選択します。
   1. **ワンタイムパスワード認証システム**セクションで、**認証システムを登録**を選択します。QRコードとOTPの詳細が表示されます。
1. デバイスを設定します。
   1. 互換性のあるOTPアプリケーションをデバイスにインストールします。例: 
      - クラウドベース（ハードウェアデバイスを紛失した場合にアクセスを復元できるため推奨されています）:
        - [Authy](https://authy.com/)。
        - [Cisco Duo](https://duo.com/)。
      - その他（プロプライエタリ）:
        - [Google Authenticator](https://support.google.com/accounts/answer/1066447?hl=en)。
        - [Microsoft Authenticator](https://www.microsoft.com/en-us/security/mobile-authenticator-app)。
      - その他（無料ソフトウェア）
        - [Aegis Authenticator](https://getaegis.app/)。
        - [FreeOTP](https://freeotp.github.io/)。
   1. アプリケーションで、次のいずれかの方法を使って新しいエントリを追加します。
      - GitLabに表示されたコードをデバイスのカメラでスキャンして、エントリを自動的に追加します。
      - 提供された詳細を入力して、エントリを手動で追加します。
1. 登録を完了します:
   1. 現在のパスワードを入力します。
   1. 認証システムから生成された6桁のPINを入力します。
   1. **2要素認証アプリで登録**を選択します。

正しいピンを入力すると、[リカバリーコード](#recovery-codes)のリストが表示されます。それらをダウンロードして、安全な場所に保管してください。

OTP認証システムがクラウドバックアップをサポートしている場合は、今すぐ機能を設定することを検討してください。詳細については、特定の認証システムのドキュメントを参照してください。

### WebAuthnデバイスの登録 {#register-a-webauthn-device}

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

WebAuthn互換デバイスを登録するには、次の手順を実行します:

1. 物理デバイスを使用している場合は、コンピューターに接続します。
1. 右上隅でアバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで、**アカウント**を選択します。
1. **2要素認証を有効にする**を選択します。
1. **WebAuthnデバイス**セクションで、**デバイスを登録する**を選択します。
1. **新しいデバイスをセットアップする**を選択します。
1. ブラウザウィンドウの指示に従います。
1. デバイスによっては、ボタンを押したり、センサーに触れたりする必要があるかもしれません。
1. GitLabアカウントのパスワードとデバイス名を入力します。Identity Provider経由でサインインしている場合は、このパスワードの入力は不要になることがあります。
1. **デバイスを登録する**を選択します。

デバイスが正常にセットアップされたことを示すメッセージが表示されます。

WebAuthn互換デバイスで2FAをセットアップすると、そのデバイスは特定のコンピューター上の特定のブラウザーにリンクされます。ブラウザとWebAuthnデバイスによっては、別のブラウザまたはコンピューターでWebAuthnデバイスを使用するように設定できる場合があります。

今回初めて2FAを設定する場合は、アクセスを失った場合にアカウントへのアクセスを回復できるように、[リカバリーコード](#recovery-codes)をダウンロードする必要があります。

> [!warning]ブラウザデータをクリアすると、アカウントへのアクセスを失う可能性があります。

### メールOTPの有効化 {#enable-email-otp}

{{< history >}}

- GitLab 18.7で、`email_based_mfa`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)で導入されました。デフォルトでは無効になっています。
- GitLab 18.7のGitLab.comで有効になり、2026年を通してすべてのユーザーに段階的にロールアウトされます。

{{< /history >}}

> [!flag] この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

メールOTPを使用すると、6桁の認証コードをメールアドレスに送信して、本人確認を行うことができます。

> [!note]次の場合、メールOTPを使用できないことがあります:
> 
> - グループポリシーで、他の2要素認証方式の使用が要求されている。
> - アカウントが外部IDプロバイダを使用している。
> - アカウントが将来の特定の日付に自動的にイネーブルメントされるようにスケジュールされている。

アカウントでメールOTPを有効にするには、次の手順を実行します:

1. 右上隅でアバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで、**アカウント**を選択します。
1. **2要素認証の管理**を選択します。
1. **メールによるワンタイムパスコードを有効にする**を選択します。
1. 現在のパスワードを入力し、**メールによるワンタイムパスコード設定の更新**を選択します。

### Cisco Duo認証システムの追加 {#add-a-cisco-duo-authenticator}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/15760)されました。

{{< /history >}}

GitLabでCisco DuoをOTPプロバイダーとして使用できます。

DUO®は、米国およびその他の特定の国におけるCisco Systems, Inc.、および/またはその関連会社の登録商標です。

前提条件: 

- アカウントがCisco DuoとGitLabの両方に存在し、両方のアプリケーションで同じユーザー名が使用されている必要があります。
- [Cisco Duoが設定済み](https://admin.duosecurity.com/)で、統合キー、シークレットキー、およびAPIホスト名が必要です。

詳細については、[Cisco Duo APIドキュメント](https://duo.com/docs/authapi)を参照してください。

1. GitLab設定ファイルを開きます。

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

### FortiAuthenticator認証システムの追加 {#add-a-fortiauthenticator-authenticator}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

> [!flag] GitLab Self-Managedでは、デフォルトでこの機能は利用できません。管理者が`forti_authenticator`という名前の[機能フラグを有効にする](../../../administration/feature_flags/_index.md)と、ユーザーごとにこの機能を使用できるようになります。GitLab.comとGitLab Dedicatedでは、この機能は使用できません。

GitLabでFortiAuthenticatorをOTPプロバイダーとして使用できます。ユーザーは次の条件を満たしている必要があります。

- FortiAuthenticatorとGitLabの両方に、同じユーザー名で存在すること。
- FortiAuthenticatorでFortiTokenが設定されていること。

FortiAuthenticatorのユーザー名とアクセストークンが必要です。以下に示す`access_token`は、FortiAuthenticatorアクセスキーです。トークンを取得するには、[Fortinetドキュメントライブラリ](https://docs.fortinet.com/document/fortiauthenticator/6.2.0/rest-api-solution-guide/158294/the-fortiauthenticator-api)にあるREST APIソリューションガイドを参照してください。FortiAuthenticatorバージョン6.2.0でテスト済み。

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
1. [再設定](../../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)（Linuxパッケージインストール）または[再起動](../../../administration/restart_gitlab.md#self-compiled-installations)（自己コンパイルインストール）を行います。

### FortiToken Cloud認証システムの追加 {#add-a-fortitoken-cloud-authenticator}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

> [!flag] GitLab Self-Managedでは、デフォルトでこの機能は利用できません。管理者が`forti_token_cloud`という名前の[機能フラグを有効にする](../../../administration/feature_flags/_index.md)と、ユーザーごとにこの機能を使用できるようになります。GitLab.comとGitLab Dedicatedでは、この機能は使用できません。この機能は本番環境での使用には対応していません。

GitLabでFortiToken CloudをOTPプロバイダーとして使用できます。ユーザーは次の条件を満たしている必要があります。

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
1. [再設定](../../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)（Linuxパッケージインストール）または[再起動](../../../administration/restart_gitlab.md#self-compiled-installations)（自己コンパイルインストール）を行います。

## リカバリーコード {#recovery-codes}

OTP認証アプリで2FAを有効にするとすぐに、生成された一連のリカバリーコードをダウンロードするように求めるプロンプトが表示されます。OTP認証アプリへのアクセスを失った場合、これらのリカバリーコードのいずれかを使用してアカウントにサインインできます。

コードをコピーして印刷するか、**コードをダウンロード**して安全な場所に保存することをお勧めします。ダウンロードを選択した場合、ファイル名は`gitlab-recovery-codes.txt`です。

> [!note]
>
> - 各リカバリーコードは、アカウントへのサインインに1回のみ使用できます。
> - リカバリーコードは、WebAuthnデバイスでは生成されません。

リカバリーコードの再生成または復元については、[リカバリーオプションと2要素認証のリセット](two_factor_authentication_troubleshooting.md#recovery-options-and-2fa-reset)を参照してください。

## 2要素認証でのサインイン {#sign-in-with-two-factor-authentication}

2要素認証が有効になっている場合は、ユーザー名とパスワードを入力してから、2番目の認証方式を使用して本人確認を行います。サインインプロセスは、登録した2要素認証方式によって若干異なります。

### OTP認証システムでのサインイン {#sign-in-with-an-otp-authenticator}

プロンプトが表示されたら、OTP認証システムまたはリカバリーコードからPINを入力してサインインします。

### WebAuthnデバイスでのサインイン {#sign-in-with-a-webauthn-device}

サポートされているブラウザでは、認証情報を入力した後、WebAuthnデバイスをアクティブにする（たとえば、ボタンに触れたり押したりする）ように求めるプロンプトが自動的に表示されます。

デバイスが認証リクエストに応答したことを示すメッセージが表示され、自動的にサインインされます。

### メールOTPでのサインイン {#sign-in-with-email-otp}

プロンプトが表示されたら、メールに送信される6桁の認証コードを入力します。このコードは60分間有効です。

アクセスコードを使用できない場合は、次の操作を実行できます:

- 新しいコードをリクエストします。サインインページで、**コードを再送信**を選択します。
- 別の確認済みのメールアドレスにコードを送信します。サインインページで、**Send a code to another address associated with this account**を選択します。
- [メールOTPトラブルシューティング](two_factor_authentication_troubleshooting.md#email-otp-troubleshooting)を参照してください。

### パーソナルアクセストークンでのサインイン {#sign-in-with-a-personal-access-token}

2要素認証が有効になっている場合、パスワードを使用してHTTPS経由でGitまたは[GitLab API](../../../api/rest/_index.md)で認証することはできません。代わりに[パーソナルアクセストークン](../personal_access_tokens.md)を使用する必要があります。

## 2要素認証を無効にする {#disable-two-factor-authentication}

{{< history >}}

- OTP認証アプリとWebAuthnデバイスを個別または同時に無効にする機能は、GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393419)されました。

{{< /history >}}

OTP認証アプリとWebAuthnデバイスは、個別にも同時にも無効にできます。同時に無効にするには:

1. 右上隅でアバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで、**アカウント**を選択します。
1. **2要素認証の管理**を選択します。
1. **2要素認証を無効にする**を選択します。
1. ダイアログで、現在のパスワードを入力し、**2要素認証を無効にする**を選択します。

これにより、モバイルアプリケーションやWebAuthnデバイスなど、すべての2FA登録がクリアされます。

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

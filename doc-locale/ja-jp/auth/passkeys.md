---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: パスキー
description: パスキーを使用したパスワード不要の認証と2FA
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.6で`passkeys`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206407)されました。GitLab Self-Managedでは、デフォルトで無効になっています。
- GitLab 18.9で一般提供になりました。機能フラグはデフォルトで有効になっています。

{{< /history >}}

パスキーは、パスワードを使用せずにGitLabアカウントにサインインするための安全で便利な方法です。パスキーは、フィッシングに強いサインインを提供するとともに、脆弱なパスワードの脆弱性や認証情報の漏洩からユーザーを保護します。

## パスキーの仕組み {#how-passkeys-work}

パスキーは、公開キーの暗号学的技術を使用してGitLabに安全に認証します。パスキーを作成すると:

- お使いのデバイスは、一意の暗号学的キーペアを生成します。
- 秘密キーはデバイスに安全に保管され、共有されることはありません。
- GitLabは公開キーのみを保存し、その公開キーを使用してユーザーになりすますことはできません。
- サインイン時、お使いのデバイスは生体認証またはPINを使用して秘密キーのロックを解除し、身元を証明します。

このアプローチにより、GitLabサーバーが侵害された場合でも、攻撃者があなたのパスキーを使用してアカウントにアクセスすることはできません。

### セキュリティに関する考慮事項 {#security-considerations}

- バックアップ認証方法を維持: リカバリーコードやその他の2FA方法など、アカウントにアクセスするための代替手段を常に維持してください。
- デバイスのセキュリティを維持: デバイスが強力なPIN、パスワード、または生体認証ロックで保護されていることを確認してください。
- 定期的にレビュー: 登録されているパスキーを定期的にレビューし、使用しなくなったデバイスのパスキーは削除してください。
- 共有デバイスを使用しない: 共有デバイスや公共デバイスにパスキーを設定しないでください。

## あなたのパスキーを表示 {#view-your-passkeys}

登録されているパスキーに関する情報（パスキー名、デバイスの種類、使用状況の詳細など）を表示するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで、**アクセス** > **Password and authentication**を選択します。
1. **Passkey sign-in**セクションで、あなたのパスキーを表示します。

## パスキーを追加 {#add-a-passkey}

前提条件: 

- WebAuthn標準をサポートするデバイスが必要です。
  - デスクトップブラウザ: Chrome、Firefox、Safari、Edge。
  - モバイルデバイス: iOS 16以降、およびAndroid 9以降で、生体認証またはデバイスPINがオンになっているもの。
  - セキュリティキー: FIDO2またはWebAuthnをサポートするハードウェアセキュリティキー。
- パスキーサインインは、[グループ](../user/group/saml_sso/_index.md#disable-password-and-passkey-authentication-for-enterprise-users)または[インスタンス](../administration/settings/sign_in_restrictions.md#password-and-passkey-authentication)で無効にされていないこと。

パスキーを追加するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで、**アクセス** > **Password and authentication**を選択します。
1. **Passkey sign-in**セクションで、**パスキーを追加**を選択します。
1. デバイスまたはブラウザのプロンプトに従ってください。
1. 現在のパスワードを入力して、身元を確認します。
1. あなたのパスキーに名前を入力します。
1. **パスキーを追加**を選択します。

## パスキーでサインイン {#sign-in-with-a-passkey}

パスワードの代わりにパスキーを使用してGitLabにサインインするには:

1. GitLabサインインページにアクセスします。

   - GitLab.comでは、`https://gitlab.com/users/sign_in`にアクセスします。
   - GitLab Self-Managedでは、あなたのインスタンスドメインを使用します。例: `https://gitlab.example.com/users/sign_in`。

1. 追加のサインインオプションで、**パスキー**を選択します。
1. 生体認証、顔認識、またはデバイスPINを使用して認証するために、デバイスのプロンプトに従ってください。

## 2要素認証にパスキーを使用する {#use-a-passkey-for-two-factor-authentication}

アカウントの[2要素認証](../user/profile/account/two_factor_authentication.md)（2FA）を有効にしている場合、パスキーは追加のデフォルト2FAオプションとして利用可能になります。

パスキーを2FA方法として使用するには:

1. GitLabサインインページにアクセスします。

   - GitLab.comでは、`https://gitlab.com/users/sign_in`にアクセスします。
   - GitLab Self-Managedでは、あなたのインスタンスドメインを使用します。例: `https://gitlab.example.com/users/sign_in`。

1. あなたのユーザー名とパスワードを入力します。
1. プロンプトが表示されたら、パスキーで認証します。
1. 生体認証、顔認識、またはデバイスPINを使用して認証するために、デバイスのプロンプトに従ってください。

> [!note]
> 現在のデバイスでパスキーが利用できない場合は、代わりにバックアップ2FA方式を使用してください。

## パスキーを削除 {#delete-a-passkey}

デバイスを使用しなくなった場合、または新しいパスキーに置き換えたい場合は、パスキーを削除します。唯一のパスキーを削除すると、GitLabはあなたのアカウントのパスキーサインインも無効にします。

パスキーを削除するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで、**アクセス** > **Password and authentication**を選択します。
1. **Passkey sign-in**セクションで、削除したいパスキーを見つけます。
1. パスキーの横にある**削除** ({{< icon name="remove" >}}) を選択します。
1. 確認ダイアログで、削除を確認します。

   - 複数のパスキーがある場合は、**パスキーを削除**を選択します。
   - 単一のパスキーがある場合は、**パスキーでのサインインを無効にする**を選択します。

> [!warning]
> 削除されたパスキーはリカバリーできません。再度そのデバイスで認証したい場合は、新しいパスキーを追加する必要があります。

## トラブルシューティング {#troubleshooting}

### パスキーの追加に関する問題 {#problems-adding-a-passkey}

パスキーを追加できない場合:

- お使いのデバイスとブラウザがWebAuthnおよび生体認証をサポートしていることを確認してください。
- ブラウザが最新であることを確認してください。
- デバイスにデバイスPIN、フィンガープリント、または顔認識が設定されていることを確認してください。
- 別のブラウザまたはデバイスを使用してみてください。
- デバイスがWebAuthn 2要素認証方法としてすでに登録されているか確認してください。
  - デバイスがWebAuthn 2要素認証方法としてすでに登録されている場合:

    1. 2FA方法からWebAuthnデバイスを削除します。
    1. それをパスキーとして登録します。
    1. 再度2FAを有効にする場合は、バックアップ2FA方式（Authenticatorアプリなど）を設定します。GitLabは、あなたのパスキーをデフォルト2要素認証として自動的に追加します。

### パスキーでサインインできない {#cannot-sign-in-with-passkey}

パスキーを使用してサインインできない場合:

- パスキーの作成に使用したデバイスと同じデバイスを使用していることを確認してください。
- 生体認証またはデバイスPINが機能していることを確認してください。
- ブラウザのキャッシュとCookieをクリアします。
- あなたのバックアップ2FA方式またはパスワードを使用してサインインし、その後にパスキーの設定を確認してください。

### デバイスを紛失または交換した場合 {#lost-or-replaced-device}

デバイスを紛失したり、新しいデバイスを入手したりした場合は、パスワードでサインインし、新しいパスキーを設定してください。

新しいデバイスにパスキーを設定するには:

1. パスワードを使用してGitLabにサインインします。
1. パスキーを2FA方法として使用している場合は、バックアップ方法でサインインします。
1. アカウントの設定から古いパスキーを削除します。
1. 新しいデバイスに新しいパスキーを設定します。

## 関連トピック {#related-topics}

- [2要素認証](../user/profile/account/two_factor_authentication.md)
- [ユーザーパスワード](../user/profile/user_passwords.md)

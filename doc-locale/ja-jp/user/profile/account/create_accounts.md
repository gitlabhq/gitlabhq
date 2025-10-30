---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabでユーザーアカウントを作成します。
title: ユーザーを作成する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザーアカウントは、GitLabにおけるコラボレーションの基盤を形成します。GitLabプロジェクトにアクセスする必要があるすべての人に、アカウントが必要です。ユーザーアカウントは、アクセス権限を制御し、コントリビュートを追跡し、インスタンス全体のセキュリティを維持します。

GitLabでは、さまざまな方法でユーザーアカウントを作成できます:

- 自己登録（自律性を重視するチーム向け）
- 管理者が作成（オンボーディングを管理可能）
- 認証インテグレーション（エンタープライズ環境向け）
- コンソールアクセス（自動化と一括操作に対応）

[ユーザーAPIエンドポイント](../../../api/users.md#create-a-user)を使用して、ユーザーを自動的に作成することもできます。

組織の規模、セキュリティ要件、GitLabワークフローに応じて、適切な方法を選択してください。

## サインインページでユーザーを作成 {#create-a-user-on-the-sign-in-page}

デフォルトでは、GitLabインスタンスにアクセスするすべてのユーザーがアカウントを登録できます。以前に[この設定を無効にしている](../../../administration/settings/sign_up_restrictions.md#disable-new-sign-ups)場合は、再度有効にする必要があります。

ユーザーは次のいずれかの方法で自分のアカウントを作成できます:

- サインインページの**今すぐ登録**リンクを選択する。
- GitLabインスタンスのサインアップリンクに移動する（例: `https://gitlab.example.com/users/sign_up`）。

## 管理者エリアでユーザーを作成 {#create-a-user-in-the-admin-area}

前提要件: 

- インスタンスの管理者である。

ユーザーを作成するには、:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. **新規ユーザー**を選択します。
1. **アカウント**セクションで、必要なアカウント情報を入力します。
1. オプション。**アクセス**セクションで、プロジェクトの制限またはユーザータイプ設定を構成します。
1. **ユーザーの作成**を選択します。

GitLabは、サインインリンクが記載されたメールをユーザーに送信し、ユーザーは最初のサインイン時にパスワードを作成する必要があります。ユーザーの[パスワードを設定](../../../security/reset_user_password.md#use-the-ui)することもできます。

## 認証インテグレーションでユーザーを作成 {#create-a-user-with-an-authentication-integration}

GitLabは、認証インテグレーションを通じてユーザーアカウントを自動的に作成できます。ユーザーは、次のタイミングで作成されます:

- Identity Providerの[SCIM](../../group/saml_sso/scim_setup.md)を通じてプロビジョニングされたとき
- 次の方法で初めてサインインしたとき:
  - [LDAP](../../../administration/auth/ldap/_index.md)
  - [グループSAML](../../group/saml_sso/_index.md)
  - `allow_single_sign_on`設定がオンになっている[OmniAuthプロバイダー](../../../integration/omniauth.md)

## Railsコンソールを使用してユーザーを作成する {#create-a-user-through-the-rails-console}

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

Railsコンソールを使用してユーザーを作成するには、次の手順に従います:

1. [Railsコンソールセッション](../../../administration/operations/rails_console.md#starting-a-rails-console-session)を開始します。
1. GitLabのバージョンに応じてコマンドを実行します:

  {{< tabs >}}

  {{< tab title="16.10以前" >}}

  ```ruby
  u = User.new(username: 'test_user', email: 'test@example.com', name: 'Test User', password: 'password', password_confirmation: 'password')
  # u.assign_personal_namespace
  u.skip_confirmation! # Use only if you want the user to be automatically confirmed. If you do not use this, the user receives a confirmation email.
  u.save!
  ```

  {{< /tab >}}

  {{< tab title="16.11 – 17.6" >}}

  ```ruby
  u = User.new(username: 'test_user', email: 'test@example.com', name: 'Test User', password: 'password', password_confirmation: 'password')
  u.assign_personal_namespace(Organizations::Organization.default_organization)
  u.skip_confirmation! # Use only if you want the user to be automatically confirmed. If you do not use this, the user receives a confirmation email.
  u.save!
  ```

  {{< /tab >}}

  {{< tab title="17.7以降" >}}

  ```ruby
  u = Users::CreateService.new(nil,
    username: 'test_user',
    email: 'test@example.com',
    name: 'Test User',
    password: '123password',
    password_confirmation: '123password',
    organization_id: Organizations::Organization.first.id,
    skip_confirmation: true
  ).execute
  ```

  {{< /tab >}}

  {{< /tabs >}}

---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Create user accounts in GitLab.
title: ユーザーを作成する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザーアカウントは、GitLabにおけるコラボレーションの基盤を形成します。GitLabプロジェクトにアクセスする必要があるすべての人に、アカウントが必要です。ユーザーアカウントは、アクセス権限を制御し、コントリビュートを追跡し、インスタンス全体のセキュリティを維持します。

GitLabでは、さまざまな方法でユーザーアカウントを作成できます。

- 自己登録（自律性を重視するチーム向け）
- 管理者が作成（オンボーディングを管理可能）
- 認証インテグレーション（エンタープライズ環境向け）
- コンソールアクセス（自動化と一括操作に対応）

[Users APIエンドポイント](../../../api/users.md#create-a-user)を使用して、ユーザーを自動的に作成することもできます。

組織の規模、セキュリティ要件、ワークフローに応じて、適切な方法を選択してください。

## サインインページでユーザーを作成する

デフォルトでは、GitLabインスタンスにアクセスするすべてのユーザーがアカウントを登録できます。以前に[この設定を無効にしている](../../../administration/settings/sign_up_restrictions.md#disable-new-sign-ups)場合は、再度有効にする必要があります。

ユーザーは次のいずれかの方法で自分のアカウントを作成できます。

- サインインページの**今すぐ登録する**リンクを選択する。
- GitLabインスタンスのサインアップリンクに移動する（例: `https://gitlab.example.com/users/sign_up`）。

## 管理者エリアでユーザーを作成する

前提要件:

- インスタンスへの管理者アクセス権が必要です。

ユーザーを手動で作成するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要 > ユーザー**を選択します。
1. **新しいユーザー**を選択します。
1. 名前、ユーザー名、メールアドレスなどの必須フィールドに入力します。
1. **ユーザーの作成**を選択します。

リセットリンクがユーザーのメールアドレスに送信されます。ユーザーは、最初にサインインする際にパスワードを設定する必要があります。

### ユーザーパスワードを設定する

確認メールを使用せずにユーザーパスワードを設定するには、ユーザーを作成した後に次の手順に従います。

1. ユーザーを選択します。
1. **編集**を選択します。
1. パスワードフィールドとパスワードの確認フィールドに入力します。
1. **変更の保存**を選択します。

これで、ユーザーは新しいユーザー名とパスワードでサインインできるようになります。ただし、管理者が設定したパスワードは、サインイン時にユーザーが変更する必要があります。

## 認証インテグレーションを通じてユーザーを作成する

GitLabは、認証インテグレーションを通じてユーザーアカウントを自動的に作成できます。ユーザーは、次のタイミングで作成されます。

- 次の方法で初めてサインインしたとき
  - [LDAP](../../../administration/auth/ldap/_index.md)
  - [グループSAML](../../group/saml_sso/_index.md)
  - `allow_single_sign_on`設定がオンになっている[OmniAuthプロバイダー](../../../integration/omniauth.md)
- Identity Providerの[SCIM](../../group/saml_sso/scim_setup.md)を通じてプロビジョニングされたとき

## Railsコンソールを使用してユーザーを作成する

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかったり、適切な条件下で実行されなかったりすると、システムに損害を与える可能性があります。必ず最初にテスト環境でコマンドを実行し、復元可能なバックアップインスタンスを準備しておいてください。

{{< /alert >}}

Railsコンソールを使用してユーザーを作成するには、次の手順に従います。

1. [Railsコンソールセッションを開始](../../../administration/operations/rails_console.md#starting-a-rails-console-session)します。
1. GitLabのバージョンに応じてコマンドを実行します。

  {{< tabs >}}

  {{< tab title="16.10以前" >}}

  ```ruby
  u = User.new(username: 'test_user', email: 'test@example.com', name: 'Test User', password: 'password', password_confirmation: 'password')
  # u.assign_personal_namespace
  u.skip_confirmation! # Use only if you want the user to be automatically confirmed. If you do not use this, the user receives a confirmation email.
  u.save!
  ```

  {{< /tab >}}

  {{< tab title="16.11 - 17.6" >}}

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

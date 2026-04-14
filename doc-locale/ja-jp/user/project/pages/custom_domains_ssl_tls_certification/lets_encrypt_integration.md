---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Pages用のLet's Encrypt SSL証明書の自動化。"
title: "GitLab Pages Let's Encrypt証明書"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

GitLab PagesとLet's Encrypt (LE) とのインテグレーションにより、PagesウェブサイトでカスタムドメインのLE証明書を自分で発行更新する手間をかけずに利用できます。GitLabがすぐに利用可能な状態でこれを提供します。

[Let's Encrypt](https://letsencrypt.org)は、無料で自動化されたオープンソースの認証局です。

> [!warning]
> この機能は**custom domains**の証明書のみを対象としており、[Pagesデーモン](../../../../administration/pages/_index.md)の実行に必要なワイルドカード証明書 (GitLab Self-Managed、Free、Premium、Ultimateのみ) は対象外です。ワイルドカード証明書の生成は[このイシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3342)で追跡するされています。

## 前提条件 {#prerequisites}

ドメインのSSL証明書の自動プロビジョニングを有効にする前に、以下を確認してください:

- ウェブサイトのソースコードを含む[プロジェクト](../_index.md#getting-started)をGitLabで作成しました。
- ドメイン（`example.com`）を取得し、Pagesウェブサイトを指す[DNSエントリ](_index.md)を追加しました。トップレベルドメイン（`.com`）は[Public Suffix](https://publicsuffix.org/)である必要があります。
- [あなたのドメインをPagesプロジェクトに追加](_index.md#step-1-add-a-custom-domain)し、その所有権を確認しました。
- あなたのウェブサイトが稼働しており、カスタムドメイン経由でアクセス可能であることを確認しました。

GitLabとLet's Encryptのインテグレーションは、GitLab.comで有効化され、利用可能です。**GitLab Self-Managed**インスタンスの場合は、管理者が[それを有効にしている](../../../../administration/pages/_index.md#lets-encrypt-integration)ことを確認してください。

## カスタムドメインにLet's Encryptインテグレーションを有効にする {#enabling-lets-encrypt-integration-for-your-custom-domain}

要件を満たしたら、Let's Encryptインテグレーションを有効にします:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**編集** ({{< icon name="pencil" >}}) を選択します。
1. **Let's Encryptを用いた自動証明書管理**切替をオンにします。

   ![Enable Let's Encrypt](img/lets_encrypt_integration_v12_1.png)

1. **変更を保存**を選択します。

有効にすると、GitLabはLE証明書を取得し、関連付けられたPagesドメインに追加します。GitLabは自動的に更新も行います。

> [!note]
> 証明書の発行とPagesの設定更新には**can take up to an hour**。ドメイン設定に既にSSL証明書がある場合、Let's Encrypt証明書に置き換えられるまで機能し続けます。

## トラブルシューティング {#troubleshooting}

### Let's Encrypt証明書の取得中に問題が発生しました {#something-went-wrong-while-obtaining-the-lets-encrypt-certificate}

**Something went wrong while obtaining the Let's Encrypt certificate**というエラーが表示されることがあります。

このイシューは、Let's Encryptがあなたのドメインに到達または検証することができない場合に発生します。

この問題を解決するには、次の手順に従います:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般** > **表示レベル**を選択し、**Pages**が**全員**に設定されていることを確認します。
1. **デプロイ** > **Pages** > **ドメインと設定**を選択します。
1. ドメイン名の横にある**編集** ({{< icon name="pencil" >}}) を選択します。
1. **検証ステータス**で、**検証を再試行する**（{{< icon name="retry" >}}）を選択します。

同じエラーが発生した場合は、以下を確認してください:

- ドメインに`CNAME`または`A` DNSレコードを1つだけ設定していることを確認してください。
- ドメインに`AAAA` DNSレコードがないことを確認してください。
- ドメインまたは上位レベルのドメインに`CAA` DNSレコードがある場合は、[`letsencrypt.org`が含まれている](https://letsencrypt.org/docs/caa/)ことを確認してください。
- [ドメインが検証されている](_index.md#step-1-add-a-custom-domain)ことを確認してください。
- [並行デプロイ](../parallel_deployments.md)を使用している場合は、プライマリデプロイに空の`path_prefix`があることを確認してください。空でない`path_prefix`（例: `latest`）の場合、`/.well-known/acme-challenge`パスが提供されません。

**デプロイ** > **Pages**設定に戻り、検証を再試行してください。

### 証明書の取得が1時間以上停止する {#obtaining-a-certificate-hangs-for-more-than-an-hour}

Let's Encryptインテグレーションを有効にしているにもかかわらず、1時間経っても証明書が表示されず、次のメッセージが表示される場合:

```plaintext
GitLab is obtaining a Let's Encrypt SSL certificate for this domain.
This process can take some time. Please try again later.
```

以下の手順に従って、GitLab Pagesのドメインを再度削除して追加してください:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**削除**を選択します。
1. [ドメインを再度追加し、検証する](_index.md#step-1-add-a-custom-domain)。
1. [ドメインのLet's Encryptインテグレーションを有効にする](#enabling-lets-encrypt-integration-for-your-custom-domain)。
1. まだ同じエラーが発生する場合は:
   1. ドメインに`CNAME`または`A` DNSレコードを1つだけ適切に設定していることを確認してください。
   1. ドメインに**doesn't have**`AAAA` DNSレコードがないことを確認してください。
   1. ドメインまたは上位レベルのドメインに`CAA` DNSレコードがある場合は、[`letsencrypt.org`が含まれている](https://letsencrypt.org/docs/caa/)ことを確認してください。
   1. ステップ1に進んでください。

<!-- Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example, `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

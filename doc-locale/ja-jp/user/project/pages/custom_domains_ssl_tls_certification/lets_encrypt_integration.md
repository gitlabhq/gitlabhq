---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Pages用のLet's EncryptSSL証明書を自動で取得します。"
title: "GitLab PagesLet's Encrypt証明書"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

Let's Encrypt（LE）とのGitLab Pagesインテグレーションにより、PagesウェブサイトでカスタムドメインにLE証明書を使用する際に、ユーザー自身で証明書を発行したり更新したりする手間を省き、GitLabがすぐに自動で行います。

[Let's Encrypt](https://letsencrypt.org)は、無料かつ自動化されたオープンソースの認証局です。

> [!warning]
> この機能は、**custom domains**の証明書のみを対象としており、[Pages daemon](../../../../administration/pages/_index.md)を実行するために必要なワイルドカード証明書ではありません（GitLab Self-Managed、Free、Premium、Ultimateのみ）。ワイルドカード証明書の生成は、[このイシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3342)で追跡されています。

## 前提条件 {#prerequisites}

ドメインのSSL証明書の自動プロビジョニングを有効にする前に、以下を確認してください:

- GitLabでウェブサイトのコードを含む[プロジェクト](../_index.md#getting-started)を作成しました。
- ドメイン（`example.com`）を取得し、Pagesウェブサイトを指す[DNSレコード](_index.md)を追加しました。トップレベルドメイン（`.com`）は[Public Suffix](https://publicsuffix.org/)である必要があります。
- Pagesプロジェクトに[ドメインを追加](_index.md#step-1-add-a-custom-domain)し、所有権を確認しました。
- カスタムドメインを介してウェブサイトが稼働しており、アクセス可能であることを確認しました。

Let's EncryptとのGitLabインテグレーションはGitLab.comで有効になっており、利用可能です。**GitLab Self-Managed**インスタンスの場合、管理者が[有効にしている](../../../../administration/pages/_index.md#lets-encrypt-integration)ことを確認してください。

## カスタムドメインのLet's Encryptインテグレーションを有効にする {#enabling-lets-encrypt-integration-for-your-custom-domain}

要件を満たしたら、Let's Encryptインテグレーションを有効にします:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**編集**（{{< icon name="pencil" >}}）を選択します。
1. **Let's Encryptを用いた自動証明書管理**切替をオンにします。

   ![Enable Let's Encrypt](img/lets_encrypt_integration_v12_1.png)

1. **変更を保存**を選択します。

有効にすると、GitLabはLE証明書を取得し、関連するPagesドメインに追加します。GitLabは、それも自動的に更新します。

> [!note]
> 証明書の発行とPages設定の更新には**can take up to an hour**かかる場合があります。ドメイン設定にSSL証明書がすでにある場合、それはLet's Encrypt証明書に置き換えられるまで機能し続けます。

## トラブルシューティング {#troubleshooting}

### Let's Encrypt証明書の取得中に問題が発生しました {#something-went-wrong-while-obtaining-the-lets-encrypt-certificate}

エラー**Something went wrong while obtaining the Let's Encrypt certificate**が発生した場合は、まずプロジェクトの**設定** > **一般** > **表示レベル**でPagesサイトが「Everyone」に設定されていることを確認してください。これにより、Let's EncryptサーバーがPagesサイトにアクセスできるようになります。これが確認されたら、次の手順に従って証明書を再度取得できます:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**編集**（{{< icon name="pencil" >}}）を選択します。
1. **検証ステータス**で、**検証を再試行する**（{{< icon name="retry" >}}）を選択します。
1. 同じエラーが引き続き発生する場合は、:
   1. ドメインに`CNAME`または`A`のDNSレコードが1つだけ適切に設定されていることを確認してください。
   1. ドメインに**doesn't have** `AAAA` DNSレコードがないことを確認してください。
   1. ドメインまたは上位レベルのドメインに`CAA` DNSレコードがある場合は、[それに`letsencrypt.org`が含まれている](https://letsencrypt.org/docs/caa/)ことを確認してください。
   1. [ドメインが検証されている](_index.md#step-1-add-a-custom-domain)ことを確認してください。
   1. ステップ1に進みます。

### 証明書の取得に1時間以上かかる {#obtaining-a-certificate-hangs-for-more-than-an-hour}

Let's Encryptインテグレーションを有効にしているにもかかわらず、1時間経っても証明書が発行されず、以下のメッセージが表示される場合:

```plaintext
GitLab is obtaining a Let's Encrypt SSL certificate for this domain.
This process can take some time. Please try again later.
```

GitLab Pagesのドメインを、次の手順に従って再度削除し追加してください:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**削除**を選択します。
1. [ドメインを再度追加して検証](_index.md#step-1-add-a-custom-domain)します。
1. ドメインの[Let's Encryptインテグレーションを有効](#enabling-lets-encrypt-integration-for-your-custom-domain)にします。
1. 同じエラーが引き続き発生する場合は、:
   1. ドメインに`CNAME`または`A`のDNSレコードが1つだけ適切に設定されていることを確認してください。
   1. ドメインに**doesn't have** `AAAA` DNSレコードがないことを確認してください。
   1. ドメインまたは上位レベルのドメインに`CAA` DNSレコードがある場合は、[それに`letsencrypt.org`が含まれている](https://letsencrypt.org/docs/caa/)ことを確認してください。
   1. ステップ1に進みます。

<!-- Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example, `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

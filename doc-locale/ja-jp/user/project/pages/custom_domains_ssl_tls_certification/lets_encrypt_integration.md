---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "GitLab Pages用のLet's Encrypt SSL自動証明書。"
title: "GitLab Pages Let's Encrypt証明書"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

GitLab PagesとLet's Encrypt（LE）のインテグレーションにより、カスタムドメインを持つPages Webサイトで、LE証明書を発行および更新する手間をかけずに使用できます。GitLabがすぐに使用できるようにします。

[Let's Encrypt](https://letsencrypt.org)は、無料で自動化されたオープンソースの認証局です。

{{< alert type="warning" >}}

この機能は、**custom domains**（カスタムドメイン） の証明書のみを対象としており、[Pagesデーモン](../../../../administration/pages/_index.md)の実行に必要なワイルドカード証明書は対象外です（GitLab Self-Managed、Free、Premium、およびUltimateのみ）。ワイルドカード証明書の生成は、[このイシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3342)で追跡されます。

{{< /alert >}}

## 前提要件 {#prerequisites}

ドメインのSSL証明書の自動プロビジョニングを有効にする前に、以下を確認してください:

- Webサイトのソースコードを含むGitLabで[プロジェクト](../_index.md#getting-started)を作成しました。
- ドメイン（`example.com`）を取得し、それをPages Webサイトに向ける[DNSエントリ](_index.md)を追加しました。トップレベルドメイン（`.com`）は、[Public Suffix](https://publicsuffix.org/)である必要があります。
- [Pagesプロジェクトにドメインを追加](_index.md#1-add-a-custom-domain)し、所有権を確認しました。
- カスタムドメインからアクセスできるWebサイトが起動し、実行されていることを確認しました。

Let's EncryptとのGitLabインテグレーションが有効になり、GitLab.comで使用できるようになりました。**GitLab Self-Managed**インスタンスの場合は、管理者が[それを有効にしている](../../../../administration/pages/_index.md#lets-encrypt-integration)ことを確認してください。

## カスタムドメインのLet's Encryptインテグレーションの有効化 {#enabling-lets-encrypt-integration-for-your-custom-domain}

要件を満たしたら、Let's Encryptインテグレーションを有効にします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**編集** ({{< icon name="pencil" >}}) を選択します。
1. **Let's Encryptを用いた自動証明書管理**切替をオンにします。

   ![Let's Encrypt](img/lets_encrypt_integration_v12_1.png)を有効にします

1. **変更を保存**を選択します。

有効にすると、GitLabはLE証明書を取得し、それインテグレーションを関連するPagesドメインに追加します。GitLabは、それも自動的に更新します。

{{< alert type="note" >}}

証明書の発行とPagesの設定の更新には、**can take up to an hour**（最大1時間かかることがあります）。ドメイン設定にSSL証明書が既にある場合、Let's Encrypt証明書に置き換えられるまで、その証明書は引き続き機能します。

{{< /alert >}}

## トラブルシューティング {#troubleshooting}

### Let's Encrypt証明書の取得中に問題が発生しました {#something-went-wrong-while-obtaining-the-lets-encrypt-certificate}

エラー**Something went wrong while obtaining the Let's Encrypt certificate**（Let's Encrypt証明書の取得中に問題が発生しました） が表示された場合は、まず、プロジェクトの**設定** > **一般** > **表示レベル**で、ページサイトが「全員」に設定されていることを確認します。これにより、Let's Encryptサーバーがページサイトにアクセスできるようになります。これが確認されたら、以下の手順に従って、証明書の取得を再度試みることができます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**編集** ({{< icon name="pencil" >}}) を選択します。
1. **検証ステータス**で、**検証を再試行する**（{{< icon name="retry" >}}）を選択します。
1. それでも同じエラーが発生する場合は、次の手順を実行します:
   1. ドメインに対して`CNAME`または`A` DNSレコードが1つだけ正しく設定されていることを確認してください。
   1. ドメインに**doesn't have**（AAAA） `AAAA` DNSレコードがないことを確認してください。
   1. ドメインまたは上位レベルのドメインに`CAA` DNSレコードがある場合は、[`letsencrypt.org`が含まれていることを確認してください](https://letsencrypt.org/docs/caa/)。
   1. [ドメインが検証されている](_index.md#1-add-a-custom-domain)ことを確認します。
   1. ステップ1に進みます。

### 証明書の取得が1時間以上ハングする {#obtaining-a-certificate-hangs-for-more-than-an-hour}

Let's Encryptインテグレーションを有効にしたにもかかわらず、1時間経過しても証明書が表示されず、次のメッセージが表示される場合:

```plaintext
GitLab is obtaining a Let's Encrypt SSL certificate for this domain.
This process can take some time. Please try again later.
```

以下の手順に従って、GitLab Pagesのドメインを削除して再度追加します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**削除**を選択します。
1. [ドメインを再度追加し、検証します](_index.md#1-add-a-custom-domain)。
1. [ドメインのLet's Encryptインテグレーションを有効にします](#enabling-lets-encrypt-integration-for-your-custom-domain)。
1. それでも同じエラーが発生する場合は、次の手順を実行します:
   1. ドメインに対して`CNAME`または`A` DNSレコードが1つだけ正しく設定されていることを確認してください。
   1. ドメインに**doesn't have**（AAAA） `AAAA` DNSレコードがないことを確認してください。
   1. ドメインまたは上位レベルのドメインに`CAA` DNSレコードがある場合は、[`letsencrypt.org`が含まれていることを確認してください](https://letsencrypt.org/docs/caa/)。
   1. ステップ1に進みます。

<!-- Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example, `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

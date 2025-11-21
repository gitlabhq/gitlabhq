---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: LDAP、OmniAuth、SAML、SCIM、OIDC、OAuthなどの認証方法
title: ユーザーアイデンティティ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、数多くのサードパーティ製のツールやプロトコルとインテグレーションし、認証と認可をより良くサポートします。

GitLabを組織の既存のIDプロバイダインフラストラクチャに接続して、ユーザー管理を一元化し、セキュリティポリシーを強化します。LDAP、SAML、OAuth、またはSCIMIDプロバイダと認証および認可のためのディレクトリサービスとインテグレーションできます。

GitLab Self-ManagedおよびGitLab Dedicatedでは、管理者は、Active Directory、Google Workspace、またはAzure ADなどのIDプロバイダとインテグレーションして、ユーザーのプロビジョニング、グループメンバーシップの同期、シングルサインオンを自動的に行うことができます。GitLab.comグループは、集中認証とユーザープロビジョニングのためにSAMLIDプロバイダとインテグレーションすることもできます。

組織のニーズに基づいて、複数のインテグレーション方法から選択してください:

- ディレクトリ同期のためのLDAP
- シングルサインオンのためのSAML
- サードパーティ認証のためのOAuth
- 自動化されたユーザープロビジョニングおよびデプロビジョニングのためのSCIM

## コアコンセプト {#core-concepts}

{{< cards >}}

- [LDAP](ldap/_index.md)
- [OmniAuth](../../integration/omniauth.md)
- [SAML](../../integration/saml.md)
- [SAMLグループ同期](../../user/group/saml_sso/group_sync.md)
- [SCIM](../../administration/settings/scim_setup.md)

{{< /cards >}}

## GitLab.comとGitLab Self-Managedの比較 {#gitlabcom-compared-to-gitlab-self-managed}

外部認証および認可プロバイダーは、次の機能をサポートしている場合があります。詳細については、このページに記載されている各外部プロバイダーへのリンクを参照してください。

| 機能                                      | GitLab.com                              | GitLab Self-Managed                       |
|-------------------------------------------------|-----------------------------------------|------------------------------------|
| **User Provisioning**（ユーザープロビジョニング）                           | SCIM<br>SAML <sup>1</sup> | LDAP <sup>1</sup><br>SAML <sup>1</sup><br>[OmniAuthプロバイダー](../../integration/omniauth.md#supported-providers) <sup>1</sup><br>SCIM  |
| **User Detail Updating**（グループ管理を除く） | 利用不可                           | LDAP同期                          |
| **認証**                              | トップレベルグループでのSAML（1プロバイダーのみ）    | LDAP（複数のプロバイダー）<br>汎用OAuth 2.0<br>SAML（同一プロバイダーにつき1つのみ許可）<br>Kerberos<br>JWT<br>スマートカード<br>[OmniAuthプロバイダー](../../integration/omniauth.md#supported-providers)（同一プロバイダーにつき1つのみ許可） |
| **Provider-to-GitLab Role Sync**（プロバイダーからGitLabへのロール同期）                | SAMLグループ同期                         | LDAPグループ同期<br>SAMLグループ同期（[GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/285150)以降） |
| **User Removal**（ユーザーの削除）                                | SCIM（トップレベルグループからユーザーを削除） | LDAP（グループからユーザーを削除し、インスタンスへのアクセスをブロック）<br>SCIM |

**Footnotes**（脚注）:

1. Just-In-Time（JIT）プロビジョニングを使用すると、ユーザーが初めてサインインしたときにユーザーアカウントが作成されます。

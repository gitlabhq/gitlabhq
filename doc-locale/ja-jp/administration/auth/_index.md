---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: サードパーティの認証プロバイダー。
title: GitLabの認証と認可
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは多数の[OmniAuthプロバイダー](../../integration/omniauth.md#supported-providers)のほか、次の外部認証および認可プロバイダーと連携します。

- [LDAP](ldap/_index.md): Active Directory、Apple Open Directory、OpenLDAP、および389 Serverが含まれます。
  - [Google Secure LDAP](ldap/google_secure_ldap.md)
- [GitLab.comグループのSAML](../../user/group/saml_sso/_index.md)
- [スマートカード](smartcard.md)

{{< alert type="note" >}}

UltraAuthは、OmniAuthインテグレーションをサポートするソフトウェアを削除しました。そのため、UltraAuthインテグレーションに関するすべての記述を削除しました。

{{< /alert >}}

## GitLab.comとGitLab Self-Managedの比較 {#gitlabcom-compared-to-gitlab-self-managed}

外部認証および認可プロバイダーは、次の機能をサポートしている場合があります。詳細については、このページに記載されている各外部プロバイダーへのリンクを参照してください。

| 機能                                      | GitLab.com                              | GitLab Self-Managed                       |
|-------------------------------------------------|-----------------------------------------|------------------------------------|
| **ユーザープロビジョニング**                           | SCIM<br>SAML <sup>1</sup> | LDAP <sup>1</sup><br>SAML <sup>1</sup><br>[OmniAuthプロバイダー](../../integration/omniauth.md#supported-providers) <sup>1</sup><br>SCIM  |
| **ユーザー詳細の更新**（グループ管理を除く） | 利用不可                           | LDAP同期                          |
| **認証**                              | トップレベルグループでのSAML（1プロバイダーのみ）    | LDAP（複数のプロバイダー）<br>汎用OAuth 2.0<br>SAML（同一プロバイダーにつき1つのみ許可）<br>Kerberos<br>JWT<br>スマートカード<br>[OmniAuthプロバイダー](../../integration/omniauth.md#supported-providers)（同一プロバイダーにつき1つのみ許可） |
| **プロバイダーからGitLabへのロール同期**                | SAMLグループ同期                         | LDAPグループ同期<br>SAMLグループ同期（[GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/285150)以降） |
| **ユーザーの削除**                                | SCIM（トップレベルグループからユーザーを削除） | LDAP（グループからユーザーを削除し、インスタンスへのアクセスをブロック）<br>SCIM |

**脚注**:

1. Just-In-Time（JIT）プロビジョニングを使用すると、ユーザーが初めてサインインしたときにユーザーアカウントが作成されます。

## GitLabでOIDC/OAuthをテストする {#test-oidcoauth-in-gitlab}

クライアントアプリケーションを使用してGitLabインスタンスでOIDC/OAuth認証をテストする方法については、[GitLabでOIDC/OAuthをテストする](test_oidc_oauth.md)を参照してください。

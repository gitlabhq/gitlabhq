---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 外部シークレットをCI/CDで使用する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CDジョブでは、作業を完了するために機密情報（シークレットと呼びます）が必要になる場合があります。この機密情報には、APIトークン、データベース認証情報、秘密キーなどが含まれることがあります。シークレットはシークレット提供元から取得されます。

CI/CD変数がジョブで常に利用できるのとは異なり、シークレットはジョブによって明示的に要求される必要があります。

GitLabは、以下を含むいくつかのシークレット管理プロバイダーをサポートしています:

1. [HashiCorp Vault](hashicorp_vault.md)
1. [Google Cloud Secret Manager](gcp_secret_manager.md)
1. [Azure Key Vault](azure_key_vault.md)
1. [AWS Secrets Manager](aws_secrets_manager.md)

これらのインテグレーションは、[IDトークン](id_token_authentication.md)を認証に使用します。IDトークンを使用して、OIDC認証をJSON Webトークン（JWT）でサポートするあらゆるシークレットプロバイダーで手動で認証することもできます。

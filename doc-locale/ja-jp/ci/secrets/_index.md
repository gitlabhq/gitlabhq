---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDでの外部シークレットの使用
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CDジョブは、作業を完了するために、シークレットと呼ばれる機密情報を必要とする場合があります。この機密情報には、APIトークン、データベース認証情報、またはプライベートキーなどのアイテムがあります。シークレットは、シークレットプロバイダーから提供されます。

常にジョブで使用可能なCI/CD変数とは異なり、シークレットはジョブによって明示的にリクエストされる必要があります。

GitLabは、以下を含む、いくつかのシークレット管理プロバイダーをサポートしています:

1. [HashiCorp Vault](hashicorp_vault.md)
1. [Google Cloud Secret Manager](gcp_secret_manager.md)
1. [Azure Key Vault](azure_key_vault.md)
1. [AWS Secrets Manager](aws_secrets_manager.md)

これらのインテグレーションは、認証に[IDトークン](id_token_authentication.md)を使用します。IDトークンを使用して、JSON Webトークン（JWT）によるOIDC認証をサポートするシークレット管理プロバイダーで手動で認証することもできます。

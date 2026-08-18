---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser des secrets externes dans CI/CD
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les jobs CI/CD peuvent nécessiter des informations sensibles, appelées secrets, pour effectuer leur travail. Ces informations sensibles peuvent être des éléments tels que des jetons API, des identifiants de base de données ou des clés privées. Les secrets proviennent d'un fournisseur de secrets.

Contrairement aux variables CI/CD qui sont toujours disponibles dans les jobs, les secrets doivent être explicitement demandés par un job.

GitLab prend en charge plusieurs fournisseurs de gestion des secrets, notamment :

1. [HashiCorp Vault](hashicorp_vault.md)
1. [Google Cloud Secret Manager](gcp_secret_manager.md)
1. [Azure Key Vault](azure_key_vault.md)
1. [AWS Secrets Manager](aws_secrets_manager.md)

Ces intégrations utilisent les [jetons ID](id_token_authentication.md) pour l'authentification. Vous pouvez également utiliser des jetons ID pour vous authentifier manuellement auprès de tout fournisseur de secrets prenant en charge l'authentification OIDC avec des jetons web JSON (JWT).

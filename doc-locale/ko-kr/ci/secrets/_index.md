---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD에서 외부 비밀 사용
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD 작업을 완료하기 위해 비밀이라고 하는 민감한 정보가 필요할 수 있습니다. 이 민감한 정보는 API 토큰, 데이터베이스 자격증명 또는 개인 키와 같은 항목일 수 있습니다. 비밀은 비밀 공급자로부터 가져옵니다.

CI/CD 변수는 항상 작업에서 사용 가능하지만, 비밀은 작업에서 명시적으로 요청해야 합니다.

GitLab은 다음을 포함한 여러 비밀 관리 공급자를 지원합니다:

1. [HashiCorp Vault](hashicorp_vault.md)
1. [Google Cloud Secret Manager](gcp_secret_manager.md)
1. [Azure Key Vault](azure_key_vault.md)
1. [AWS Secrets Manager](aws_secrets_manager.md)

이 통합은 인증을 위해 [ID 토큰](id_token_authentication.md)을 사용합니다. ID 토큰을 사용하여 OIDC 인증을 지원하는 모든 비밀 공급자(JSON 웹 토큰(JWT))로 수동으로 인증할 수도 있습니다.

---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab CI/CD에서 AWS Secrets Manager 보안 정보 사용
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/17822) 되었으며 [플래그](../../administration/feature_flags/_index.md) `ci_aws_secrets_manager`라는 이름입니다. 기본적으로 비활성화되어 있습니다.
- GitLab 18.3에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/553970)되었습니다.

{{< /history >}}

[AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)에 저장된 보안 정보를 GitLab CI/CD 파이프라인에서 사용할 수 있습니다.

전제 조건:

- AWS 계정에서 AWS Secrets Manager에 액세스할 수 있어야 합니다.
- 다음 방법 중 하나를 사용하여 인증을 구성합니다:
  - **IAM Role**: 러너 인스턴스에 할당된 IAM 역할을 사용합니다.
  - **OpenID Connect**: [AWS에서 OpenID Connect 구성](../cloud_services/aws/_index.md)하여 임시 자격 증명을 검색합니다.
- [프로젝트에 CI/CD 변수 추가](../variables/_index.md#for-a-project)하여 AWS 구성에 대한 세부 정보를 제공합니다:
  - `AWS_REGION`: 보안 정보가 저장된 AWS 리전입니다.
  - `AWS_ROLE_ARN`: 가정할 AWS IAM 역할의 ARN입니다(OpenID Connect를 사용할 때 필수).
  - `AWS_ROLE_SESSION_NAME`: 선택 사항. 가정한 역할의 사용자 지정 세션 이름입니다.

## CI/CD 작업에서 AWS Secrets Manager 보안 정보 사용 {#use-aws-secrets-manager-secrets-in-a-cicd-job}

### IAM Role 인증 사용 {#with-iam-role-authentication}

`aws_secrets_manager` 키워드를 사용하여 AWS Secrets Manager에 저장된 보안 정보를 작업에서 사용할 수 있습니다.

이 방법은 러너 인스턴스에 할당된 IAM 역할을 사용합니다. [Kubernetes 실행기](https://docs.gitlab.com/runner/executors/kubernetes/) 또는 [자동 크기 조정](https://docs.gitlab.com/runner/runner_autoscale/)을 사용할 때 IAM 역할이 러너 관리자에 적용되었는지 확인합니다.

전제 조건:

- GitLab Runner 18.3 이상입니다.

예를 들어:

```yaml
variables:
  AWS_REGION: us-east-1

database-migration:
  secrets:
    DATABASE_PASSWORD:
      aws_secrets_manager:
        secret_id: app-secrets/database
        field: 'password'
      file: false
  stage: deploy
  script:
    - echo "Running database migration..."
    - mysql -h $DB_HOST -u $DB_USER -p$DATABASE_PASSWORD < migration.sql
    - echo "Migration completed successfully."
```

### OpenID Connect 인증 사용 {#with-openid-connect-authentication}

보안 강화를 위해 OpenID Connect를 사용하여 AWS로 인증하고 특정 IAM 역할을 가정할 수 있습니다. 기본적으로 러너는 `AWS_ID_TOKEN`라는 ID 토큰을 찾습니다. 예를 들어:

```yaml
variables:
  AWS_REGION: us-east-1
  AWS_ROLE_ARN: 'arn:aws:iam::123456789012:role/gitlab-secrets-role'

database-migration:
  id_tokens:
    AWS_ID_TOKEN:
      aud: 'sts.amazonaws.com'
  secrets:
    DATABASE_PASSWORD:
      aws_secrets_manager:
        secret_id: app-secrets/database
        field: 'password'
      file: false
  stage: deploy
  script:
    - echo "Connecting to production database..."
    - psql postgresql://$DB_USER:$DATABASE_PASSWORD@$DB_HOST:5432/$DB_NAME -c "SELECT version();"
    - echo "Database connection successful."
```

`token` 옵션을 사용하여 사용자 지정 토큰을 지정할 수도 있습니다. 예를 들어:

```yaml
variables:
  AWS_REGION: us-east-1
  AWS_ROLE_ARN: 'arn:aws:iam::123456789012:role/gitlab-secrets-role'

database-migration:
  id_tokens:
    CUSTOM_AWS_TOKEN:
      aud: 'sts.amazonaws.com'
  secrets:
    DATABASE_PASSWORD:
      aws_secrets_manager:
        secret_id: app-secrets/database
        field: 'password'
      token: $CUSTOM_AWS_TOKEN
      file: false
  stage: deploy
  script:
    - echo "Connecting to production database with custom token..."
    - psql postgresql://$DB_USER:$DATABASE_PASSWORD@$DB_HOST:5432/$DB_NAME -c "SELECT version();"
    - echo "Database connection successful."
```

### 단축형 구문 {#short-form-syntax}

보안 정보 ID를 문자열로 지정하여 단순화된 구문을 사용할 수 있습니다. `#` 문자로 분리하여 선택적으로 필드를 지정할 수 있습니다. 예를 들어:

```yaml
variables:
  AWS_REGION: us-east-1

api-deployment:
  secrets:
    API_KEY:
      aws_secrets_manager: 'app-secrets/api#api_key'
      file: false
    FULL_SECRET:
      aws_secrets_manager: 'app-secrets/api'
      file: false
  stage: deploy
  script:
    - echo "Deploying API with specific field..."
    - curl --header "Authorization: Bearer $API_KEY" https://api.example.com/deploy
    - echo "Using full secret..."
    - curl --header "Authorization: Bearer $(cat $FULL_SECRET | jq --raw-output '.api_key')" https://api.example.com/status
```

## 보안 정보 버전 관리 {#secret-versioning}

AWS Secrets Manager는 여러 보안 정보 버전을 지원합니다. `version_id` 또는 `version_stage`을 사용하여 특정 버전을 지정할 수 있습니다. 예를 들어:

```yaml
variables:
  AWS_REGION: us-east-1

production-deployment:
  secrets:
    DATABASE_PASSWORD:
      aws_secrets_manager:
        secret_id: prod-app-secrets/database
        field: 'password'
        version_stage: 'AWSCURRENT'
      file: false
    STAGING_DATABASE_PASSWORD:
      aws_secrets_manager:
        secret_id: prod-app-secrets/database
        field: 'password'
        version_id: '01234567-89ab-cdef-0123-456789abcdef'
      file: false
  stage: deploy
  script:
    - echo "Deploying to production with current secret version..."
    - deploy-prod.sh --db-password $DATABASE_PASSWORD
    - echo "Testing with specific secret version..."
    - test-with-version.sh --db-password $STAGING_DATABASE_PASSWORD
```

## 교차 계정 보안 정보 액세스 {#cross-account-secret-access}

다른 AWS 계정에서 보안 정보를 검색하려면 전체 ARN을 사용해야 합니다. 예를 들어:

```yaml
variables:
  AWS_REGION: us-east-1
  AWS_ROLE_ARN: 'arn:aws:iam::123456789012:role/cross-account-secrets-role'

cross-account-deployment:
  id_tokens:
    AWS_ID_TOKEN:
      aud: 'sts.amazonaws.com'
  secrets:
    SHARED_API_KEY:
      aws_secrets_manager:
        secret_id: 'arn:aws:secretsmanager:us-east-1:987654321098:secret:shared-api-keys-AbCdEf'
        field: 'production_key'
      file: false
  stage: deploy
  script:
    - echo "Accessing shared secret from another account..."
    - curl --header "Authorization: Bearer $SHARED_API_KEY" https://shared-api.example.com/deploy
```

## 보안 정보별 구성 재정의 {#per-secret-configuration-overrides}

보안 정보별 기준으로 글로벌 AWS 설정을 재정의할 수 있습니다. 예를 들어:

```yaml
variables:
  AWS_REGION: us-east-1
  AWS_ROLE_ARN: 'arn:aws:iam::123456789012:role/default-role'

multi-region-deployment:
  id_tokens:
    AWS_ID_TOKEN:
      aud: 'sts.amazonaws.com'
    EU_AWS_TOKEN:
      aud: 'sts.amazonaws.com'
  secrets:
    EU_DATABASE_PASSWORD:
      aws_secrets_manager:
        secret_id: eu-app-secrets/database
        field: 'password'
        region: 'eu-west-1'
        role_arn: 'arn:aws:iam::123456789012:role/eu-deployment-role'
        role_session_name: 'gitlab-eu-deployment'
      token: $EU_AWS_TOKEN
      file: false
    US_DATABASE_PASSWORD:
      aws_secrets_manager:
        secret_id: us-app-secrets/database
        field: 'password'
      file: false
  stage: deploy
  script:
    - echo "Deploying to EU region..."
    - deploy-to-eu.sh --db-password $EU_DATABASE_PASSWORD
    - echo "Deploying to US region..."
    - deploy-to-us.sh --db-password $US_DATABASE_PASSWORD
```

다음 예에서:

- `aud`: [페더레이션 ID 자격 증명을 생성](../cloud_services/aws/_index.md)할 때 사용된 대상과 일치해야 하는 대상입니다.
- `secret_id`: AWS Secrets Manager에 있는 보안 정보의 이름 또는 ARN입니다. 다른 계정에서 보안 정보를 검색하려면 ARN을 사용해야 합니다.
- `field`: 검색할 JSON 보안 정보의 특정 키입니다. 지정하지 않으면 전체 보안 정보를 검색합니다. 필드 액세스는 플랫 JSON 보안 정보(최상위 키만)에서만 지원되며 문자열, 숫자 및 부울 값을 지원합니다. 예를 들어:
  - `password`: `password` 필드에 액세스합니다.
  - `api_key`: `api_key` 필드에 액세스합니다.
  - `token`: 인증에 사용할 ID 토큰을 지정합니다. 지정하지 않으면 러너는 `AWS_ID_TOKEN`라는 토큰을 찾습니다.
- `version_id`: 보안 정보의 특정 버전의 고유 식별자입니다. `version_id` 또는 `version_stage`을 지정하지 않으면 AWS Secrets Manager는 `AWSCURRENT` 버전을 반환합니다.
- `version_stage`: 검색할 보안 정보 버전의 스테이징 레이블입니다(`AWSCURRENT` 또는 `AWSPENDING` 등). 동일한 보안 정보에 대해 `version_id`과 `version_stage`을 모두 지정할 수 없습니다.
- `region`: 이 특정 보안 정보에 대해 글로벌 `AWS_REGION`을 재정의합니다.
- `role_arn`: 이 특정 보안 정보에 대해 글로벌 `AWS_ROLE_ARN`을 재정의합니다.
- `role_session_name`: 이 특정 보안 정보에 대해 글로벌 `AWS_ROLE_SESSION_NAME`을 재정의합니다.
- GitLab은 AWS Secrets Manager에서 보안 정보를 가져오고 값을 임시 파일에 저장합니다. 이 파일의 경로는 [파일 유형 CI/CD 변수](../variables/_index.md#use-file-type-cicd-variables)와 유사하게 CI/CD 변수에 저장됩니다.

## 문제 해결 {#troubleshooting}

AWS로 OIDC를 설정할 때 일반적인 문제는 [AWS 문제 해결을 위한 OIDC](../cloud_services/aws/_index.md#troubleshooting)를 참조하십시오.

### 오류: `no EC2 IMDS role found` {#error-no-ec2-imds-role-found}

다음 두 조건이 모두 참인 경우 다음 오류가 발생할 수 있습니다:

- CI/CD 작업은 [IAM role 인증 사용](#with-iam-role-authentication)으로 구성됩니다.
- 작업은 AWS EKS에 호스팅된 [Kubernetes 실행기](https://docs.gitlab.com/runner/executors/kubernetes/)가 있는 러너에 의해 실행됩니다.

```plaintext
Resolving secrets
Resolving secret "MY_AWS_SECRET"...
Using "aws_secrets_manager" secret resolver...
ERROR: Job failed (system failure): resolving secrets: operation error Secrets Manager: GetSecretValue, get identity: get credentials: failed to refresh cached credentials, no EC2 IMDS role found, operation error ec2imds: GetMetadata, canceled, context deadline exceeded
```

`Resolving secrets` 단계는 러너 관리자에 의해 처리됩니다. 이 단계는 [EC2 IMDS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)에 캐시된 IAM 자격 증명에 액세스합니다. IAM 역할이 러너 관리자에 적용되지 않았으면 `Resolving secrets` 단계가 실패합니다.

이 오류를 해결하려면 올바른 IAM 역할을 러너 관리자에 적용합니다.

러너 관리자에 의해 생성되고 관리되는 러너 포드에 IAM 역할을 적용하면 이 이슈가 해결되지 않습니다.

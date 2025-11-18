---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use AWS Secrets Manager secrets in GitLab CI/CD
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17822) in GitLab 18.2 [with a flag](../../administration/feature_flags/_index.md) named `ci_aws_secrets_manager`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/553970) in GitLab 18.3.

{{< /history >}}

You can use secrets stored in [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
in your GitLab CI/CD pipelines.

Prerequisites:

- Have access to AWS Secrets Manager in your AWS account.
- Configure authentication using one of the following methods:
  - **IAM Role**: Use the IAM role assigned to your GitLab Runner instance.
  - **OpenID Connect**: [Configure OpenID Connect in AWS](../cloud_services/aws/_index.md) to retrieve temporary credentials.
- Add [CI/CD variables to your project](../variables/_index.md#for-a-project) to provide details about your AWS configuration:
  - `AWS_REGION`: The AWS region where your secrets are stored.
  - `AWS_ROLE_ARN`: The ARN of the AWS IAM role to assume (required when using OpenID Connect).
  - `AWS_ROLE_SESSION_NAME`: Optional. Custom session name for the assumed role.

## Use AWS Secrets Manager secrets in a CI/CD job

### With IAM Role authentication

You can use a secret stored in AWS Secrets Manager in a job by defining it with the
`aws_secrets_manager` keyword.

This method uses the IAM role assigned to your GitLab Runner instance. When using the
[Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/) or [autoscaling](https://docs.gitlab.com/runner/runner_autoscale/),
make sure the IAM role is applied to your runner manager.

Prerequisites:

- GitLab Runner 18.3 or later.

For example:

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

### With OpenID Connect authentication

For enhanced security, you can use OpenID Connect to authenticate with AWS and assume a specific IAM role.
By default, the runner looks for an ID token named `AWS_ID_TOKEN`. For example:

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

You can also specify a custom token using the `token` option. For example:

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

### Short form syntax

You can use a simplified syntax by specifying the secret ID as a string.
You can optionally specify a field by separating it with a `#` character.
For example:

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

## Secret versioning

AWS Secrets Manager supports multiple versions of secrets. You can specify a particular version
using either `version_id` or `version_stage`. For example:

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

## Cross-account secret access

To retrieve secrets from another AWS account, you must use the full ARN.
For example:

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

## Per-secret configuration overrides

You can override global AWS settings on a per-secret basis. For example:

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

In these examples:

- `aud`: The audience, which must match the audience used when [creating the federated identity credentials](../cloud_services/aws/_index.md).
- `secret_id`: The name or ARN of the secret in AWS Secrets Manager. To retrieve a secret from another account, you must use an ARN.
- `field`: Is the specific key in the JSON secret to retrieve. If not specified, the entire secret is retrieved.
  Field access is only supported for flat JSON secrets (top-level keys only) and supports string, number, and boolean values.
  For example:
  - `password`: Accesses the `password` field.
  - `api_key`: Accesses the `api_key` field.
  `token`: Specifies which ID token to use for authentication. If not specified, the runner looks for a token named `AWS_ID_TOKEN`.
- `version_id`: Is the unique identifier of a specific version of the secret.
  If you don't specify either `version_id` or `version_stage`, AWS Secrets Manager returns the `AWSCURRENT` version.
- `version_stage`: The staging label of the version of the secret to retrieve (such as `AWSCURRENT` or `AWSPENDING`).
  You cannot specify both `version_id` and `version_stage` for the same secret.
- `region`: Overrides the global `AWS_REGION` for this specific secret.
- `role_arn`: Overrides the global `AWS_ROLE_ARN` for this specific secret.
- `role_session_name`: Overrides the global `AWS_ROLE_SESSION_NAME` for this specific secret.
- GitLab fetches the secret from AWS Secrets Manager and stores the value in a temporary file.
  The path to this file is stored in a CI/CD variable, similar to
  [file type CI/CD variables](../variables/_index.md#use-file-type-cicd-variables).

## Troubleshooting

Refer to [OIDC for AWS troubleshooting](../cloud_services/aws/_index.md#troubleshooting) for general
problems when setting up OIDC with AWS.

### Error: `no EC2 IMDS role found`

The following error might happen if both of these conditions are true:

- The CI/CD job is configured to [use IAM role authentication](#with-iam-role-authentication).
- The job is executed by a runner with the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/) hosted on AWS EKS.

```plaintext
Resolving secrets
Resolving secret "MY_AWS_SECRET"...
Using "aws_secrets_manager" secret resolver...
ERROR: Job failed (system failure): resolving secrets: operation error Secrets Manager: GetSecretValue, get identity: get credentials: failed to refresh cached credentials, no EC2 IMDS role found, operation error ec2imds: GetMetadata, canceled, context deadline exceeded
```

The `Resolving secrets` step is handled by the runner manager. This step accesses IAM credentials
cached in [EC2 IMDS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html).
If the IAM role has not been applied to the runner manager, the `Resolving secrets` step fails.

To address this error, apply the correct IAM role to the runner manager.

Applying the IAM role to the runner pods that are spawned and managed by the runner manager does not resolve this issue.

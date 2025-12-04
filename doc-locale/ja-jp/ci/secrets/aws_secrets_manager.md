---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDでAWS Secrets Managerシークレットを使用する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.2で`ci_aws_secrets_manager`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17822)されました。デフォルトでは無効になっています。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/553970)になりました。

{{< /history >}}

GitLab継続的インテグレーションとデリバリーパイプラインで、[AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)に保存されているシークレットを使用できます。

前提要件: 

- AWSアカウントのAWS Secrets Managerにアクセスできる必要があります。
- 次のいずれかの方法で認証を設定します:
  - **IAM Role**（IAMロール）: GitLab Runnerインスタンスに割り当てられたIAMロールを使用します。
  - **OpenID Connect**: 一時的な認証情報を取得するには、AWSで[OpenID Connect](../cloud_services/aws/_index.md)を設定します。
- AWSの設定に関する詳細を提供するには、[プロジェクトにCI/CD変数を追加](../variables/_index.md#for-a-project)します:
  - `AWS_REGION`: シークレットが保存されているAWSリージョン。
  - `AWS_ROLE_ARN`: OpenID Connectを使用する場合に必要となる、引き受けるAWS IAMロールのAmazonリソースネーム。
  - `AWS_ROLE_SESSION_NAME`: オプション。引き受けられたロールのカスタムセッション名。

## CI/CDジョブでAWS Secrets Managerシークレットを使用する {#use-aws-secrets-manager-secrets-in-a-cicd-job}

### IAMロール認証を使用 {#with-iam-role-authentication}

`aws_secrets_manager`キーワードで定義することにより、ジョブでAWS Secrets Managerに保存されているシークレットを使用できます。この方法では、GitLab Runnerインスタンスに割り当てられたIAMロールを使用します。

前提要件: 

- GitLab Runner 18.3バージョン以降。

例: 

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

### OpenID Connect認証を使用 {#with-openid-connect-authentication}

セキュリティを強化するために、OpenID Connectを使用してAWSで認証を行い、特定のIAMロールを引き受けることができます。デフォルトでは、Runnerは`AWS_ID_TOKEN`という名前のIDトークンを検索します。例: 

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

`token`オプションを使用して、カスタムトークンを指定することもできます。例: 

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

### 短い形式の構文 {#short-form-syntax}

シークレットIDを文字列として指定することにより、簡略化された構文を使用できます。オプションで、`#`文字で区切ってフィールドを指定できます。例: 

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

## シークレットのバージョニング {#secret-versioning}

AWS Secrets Managerは、シークレットの複数のバージョンをサポートしています。`version_id`または`version_stage`のいずれかを使用して、特定のバージョンを指定できます。例: 

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

## クロスアカウントシークレットアクセス {#cross-account-secret-access}

別のAWSアカウントからシークレットを取得するには、完全なAmazonリソースネームを使用する必要があります。例: 

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

## シークレットごとの設定のオーバーライド {#per-secret-configuration-overrides}

シークレットごとに、グローバルなAWS設定をオーバーライドできます。例: 

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

これらの例では:

- `aud`: オーディエンス。[フェデレーションアイデンティティおよびアクセス管理 () 認証情報の作成](../cloud_services/aws/_index.md)時に使用するオーディエンスと一致する必要があります。
- `secret_id`: AWS Secrets Manager内のシークレットの名前またはAmazonリソースネーム。別のアカウントからシークレットを取得するには、Amazonリソースネームを使用する必要があります。
- `field`: 取得するJSONシークレット内の特定のキーです。指定されていない場合、シークレット全体が取得されます。フィールドアクセスは、フラットなJSONシークレット（トップレベルのキーのみ）でのみサポートされており、文字列、数値、およびブール値をサポートしています。例: 
  - `password`: `password`フィールドにアクセスします。
  - `api_key`: `api_key`フィールドにアクセスします。`token`: 認証に使用するIDトークンを指定します。指定しない場合、Runnerは`AWS_ID_TOKEN`という名前のトークンを検索します。
- `version_id`: シークレットの特定のバージョンの固有識別子です。`version_id`または`version_stage`のいずれかを指定しない場合、AWS Secrets Managerは`AWSCURRENT`バージョンを返します。
- `version_stage`: 取得するシークレットのバージョンのステージングラベル（`AWSCURRENT`や`AWSPENDING`など）。同じシークレットに対して`version_id`と`version_stage`の両方を指定することはできません。
- `region`: この特定のシークレットのグローバルな`AWS_REGION`をオーバーライドします。
- `role_arn`: この特定のシークレットのグローバルな`AWS_ROLE_ARN`をオーバーライドします。
- `role_session_name`: この特定のシークレットのグローバルな`AWS_ROLE_SESSION_NAME`をオーバーライドします。
- GitLabは、AWS Secrets Managerからシークレットをフェッチし、一時ファイルに値を格納します。このファイルへのパスは、[ファイルタイプCI/CD変数](../variables/_index.md#use-file-type-cicd-variables)と同様に、CI/CD変数に格納されます。

## トラブルシューティング {#troubleshooting}

AWSでOIDCをセットアップする際の一般的な問題については、[AWSのOIDCのトラブルシューティング](../cloud_services/aws/_index.md#troubleshooting)を参照してください。

---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser les secrets AWS Secrets Manager dans GitLab CI/CD
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/17822) dans GitLab 18.2 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `ci_aws_secrets_manager`. Désactivé par défaut.
- [Disponible généralement](https://gitlab.com/gitlab-org/gitlab/-/issues/553970) dans GitLab 18.3.

{{< /history >}}

Vous pouvez utiliser des secrets stockés dans [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) dans vos pipelines CI/CD GitLab.

Prérequis :

- Avoir accès à AWS Secrets Manager dans votre compte AWS.
- Configurer l'authentification à l'aide de l'une des méthodes suivantes :
  - **IAM Role** : Utiliser le rôle IAM assigné à votre instance GitLab Runner.
  - **OpenID Connect** : [Configurer OpenID Connect dans AWS](../cloud_services/aws/_index.md) pour récupérer des identifiants temporaires.
- Ajouter des [variables CI/CD à votre projet](../variables/_index.md#for-a-project) pour fournir des détails sur votre configuration AWS :
  - `AWS_REGION` : La région AWS dans laquelle vos secrets sont stockés.
  - `AWS_ROLE_ARN` : L'ARN du rôle IAM AWS à assumer (requis lors de l'utilisation d'OpenID Connect).
  - `AWS_ROLE_SESSION_NAME` : Facultatif. Nom de session personnalisé pour le rôle assumé.

## Utiliser les secrets AWS Secrets Manager dans un job CI/CD {#use-aws-secrets-manager-secrets-in-a-cicd-job}

### Avec l'authentification par rôle IAM {#with-iam-role-authentication}

Vous pouvez utiliser un secret stocké dans AWS Secrets Manager dans un job en le définissant avec le mot-clé `aws_secrets_manager`.

Cette méthode utilise le rôle IAM assigné à votre instance GitLab Runner. Lors de l'utilisation de l'[exécuteur Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/) ou de la [mise à l'échelle automatique](https://docs.gitlab.com/runner/runner_autoscale/), assurez-vous que le rôle IAM est appliqué à votre gestionnaire de runner.

Prérequis :

- GitLab Runner 18.3 ou version ultérieure.

Par exemple :

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

### Avec l'authentification OpenID Connect {#with-openid-connect-authentication}

Pour une sécurité renforcée, vous pouvez utiliser OpenID Connect pour vous authentifier auprès d'AWS et assumer un rôle IAM spécifique. Par défaut, le runner recherche un jeton d'ID nommé `AWS_ID_TOKEN`. Par exemple :

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

Vous pouvez également spécifier un jeton personnalisé à l'aide de l'option `token`. Par exemple :

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

### Syntaxe abrégée {#short-form-syntax}

Vous pouvez utiliser une syntaxe simplifiée en spécifiant l'ID du secret sous forme de chaîne. Vous pouvez éventuellement spécifier un champ en le séparant par un caractère `#`. Par exemple :

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

## Gestion des versions des secrets {#secret-versioning}

AWS Secrets Manager prend en charge plusieurs versions de secrets. Vous pouvez spécifier une version particulière en utilisant `version_id` ou `version_stage`. Par exemple :

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

## Accès aux secrets entre comptes {#cross-account-secret-access}

Pour récupérer des secrets depuis un autre compte AWS, vous devez utiliser l'ARN complet. Par exemple :

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

## Remplacements de configuration par secret {#per-secret-configuration-overrides}

Vous pouvez remplacer les paramètres AWS globaux pour chaque secret individuellement. Par exemple :

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

Dans ces exemples :

- `aud` : L'audience, qui doit correspondre à l'audience utilisée lors de la [création des identifiants d'identité fédérée](../cloud_services/aws/_index.md).
- `secret_id` : Le nom ou l'ARN du secret dans AWS Secrets Manager. Pour récupérer un secret depuis un autre compte, vous devez utiliser un ARN.
- `field` : Est la clé spécifique dans le secret JSON à récupérer. Si non spécifié, l'intégralité du secret est récupérée. L'accès aux champs est uniquement pris en charge pour les secrets JSON plats (clés de premier niveau uniquement) et prend en charge les valeurs de type chaîne, nombre et booléen. Par exemple :
  - `password` : Accède au champ `password`.
  - `api_key` : Accède au champ `api_key`.
  - `token` : Spécifie le jeton d'ID à utiliser pour l'authentification. Si non spécifié, le runner recherche un jeton nommé `AWS_ID_TOKEN`.
- `version_id` : Est l'identifiant unique d'une version spécifique du secret. Si vous ne spécifiez ni `version_id` ni `version_stage`, AWS Secrets Manager retourne la version `AWSCURRENT`.
- `version_stage` : Le label de staging de la version du secret à récupérer (tel que `AWSCURRENT` ou `AWSPENDING`). Vous ne pouvez pas spécifier à la fois `version_id` et `version_stage` pour le même secret.
- `region` : Remplace la valeur globale `AWS_REGION` pour ce secret spécifique.
- `role_arn` : Remplace la valeur globale `AWS_ROLE_ARN` pour ce secret spécifique.
- `role_session_name` : Remplace la valeur globale `AWS_ROLE_SESSION_NAME` pour ce secret spécifique.
- GitLab récupère le secret depuis AWS Secrets Manager et stocke la valeur dans un fichier temporaire. Le chemin vers ce fichier est stocké dans une variable CI/CD, de manière similaire aux [variables CI/CD de type fichier](../variables/_index.md#use-file-type-cicd-variables).

## Dépannage {#troubleshooting}

Consultez la [résolution des problèmes OIDC pour AWS](../cloud_services/aws/_index.md#troubleshooting) pour les problèmes généraux lors de la configuration d'OIDC avec AWS.

### Erreur : `no EC2 IMDS role found` {#error-no-ec2-imds-role-found}

L'erreur suivante peut se produire si ces deux conditions sont réunies :

- Le job CI/CD est configuré pour [utiliser l'authentification par rôle IAM](#with-iam-role-authentication).
- Le job est exécuté par un runner avec l'[exécuteur Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/) hébergé sur AWS EKS.

```plaintext
Resolving secrets
Resolving secret "MY_AWS_SECRET"...
Using "aws_secrets_manager" secret resolver...
ERROR: Job failed (system failure): resolving secrets: operation error Secrets Manager: GetSecretValue, get identity: get credentials: failed to refresh cached credentials, no EC2 IMDS role found, operation error ec2imds: GetMetadata, canceled, context deadline exceeded
```

L'étape `Resolving secrets` est gérée par le gestionnaire de runner. Cette étape accède aux identifiants IAM mis en cache dans [EC2 IMDS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html). Si le rôle IAM n'a pas été appliqué au gestionnaire de runner, l'étape `Resolving secrets` échoue.

Pour résoudre cette erreur, appliquez le rôle IAM approprié au gestionnaire de runner.

L'application du rôle IAM aux pods de runner créés et gérés par le gestionnaire de runner ne résout pas ce problème.

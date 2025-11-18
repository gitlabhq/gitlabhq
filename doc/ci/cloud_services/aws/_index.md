---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure OpenID Connect in AWS to retrieve temporary credentials
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

`CI_JOB_JWT_V2` was [deprecated in GitLab 15.9](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated)
and is scheduled to be removed in GitLab 17.0. Use [ID tokens](../../secrets/id_token_authentication.md) instead.

{{< /alert >}}

This tutorial shows you how to use a GitLab CI/CD job with a JSON web token (JWT) to retrieve temporary credentials from AWS without storing secrets.
To do this, you must configure OpenID Connect (OIDC) for ID federation between GitLab and AWS. For background and requirements for integrating GitLab using OIDC, see [Connect to cloud services](../_index.md).

To complete this tutorial:

1. [Add the identity provider](#add-the-identity-provider)
1. [Configure the role and trust](#configure-a-role-and-trust)
1. [Retrieve a temporary credential](#retrieve-temporary-credentials)

## Add the identity provider

Create GitLab as a IAM OIDC provider in AWS following these [instructions](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html).

Include the following information:

- **Provider URL**: The address of your GitLab instance, such as `https://gitlab.com` or `http://gitlab.example.com`.
  This address must be publicly accessible. If this is not publicly available, see how to
  [configure a non-public GitLab instance](#configure-a-non-public-gitlab-instance)
- **Audience**: The logical name of the target service you intend to use the requested security token with.
  - In AWS OIDC integrations, this typically matches the audience value configured in your IAM OIDC identity provider (often `sts.amazonaws.com` or your GitLab instance URL).
  - This value is validated by AWS to ensure the token was intended for your specific identity provider.

  {{< alert type="note" >}}

  Using `https://gitlab.com` or your GitLab instance URL might work if the AWS identity provider reference matches it, but this is semantically misleading.
  The audience should represent the service that validates and accepts the token.

  {{< /alert >}}

## Configure a role and trust

After you create the identity provider, configure a [web identity role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html) with conditions for limiting access to GitLab resources. Temporary credentials are obtained using [AWS Security Token Service](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html), so set the `Action` to [`sts:AssumeRoleWithWebIdentity`](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html).

You can create a [custom trust policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-custom.html)
for the role to limit authorization to a specific group, project, branch, or tag.
For the full list of supported filtering types, see [Connect to cloud services](../_index.md#configure-a-conditional-role-with-oidc-claims).

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::AWS_ACCOUNT:oidc-provider/gitlab.example.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "gitlab.example.com:sub": "project_path:mygroup/myproject:ref_type:branch:ref:main"
        }
      }
    }
  ]
}
```

After the role is created, attach a policy defining permissions to an AWS service (S3, EC2, Secrets Manager).

## Retrieve temporary credentials

After you configure the OIDC and role, the GitLab CI/CD job can retrieve a temporary credential from [AWS Security Token Service (STS)](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html).

```yaml
assume role:
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.example.com
  script:
    # this is split out for correct exit code handling
    - >
      aws_sts_output=$(aws sts assume-role-with-web-identity
      --role-arn ${ROLE_ARN}
      --role-session-name "GitLabRunner-${CI_PROJECT_ID}-${CI_PIPELINE_ID}"
      --web-identity-token ${GITLAB_OIDC_TOKEN}
      --duration-seconds 3600
      --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]'
      --output text)
    - export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" $aws_sts_output)
    - aws sts get-caller-identity
```

- `ROLE_ARN`: The role ARN defined in this [step](#configure-a-role-and-trust).
- `GITLAB_OIDC_TOKEN`: An OIDC [ID token](../../secrets/id_token_authentication.md).

## Working examples

- See this [reference project](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws) for provisioning OIDC in AWS using Terraform and a sample script to retrieve temporary credentials.
- [OIDC and Multi-Account Deployment with GitLab and ECS](https://gitlab.com/guided-explorations/aws/oidc-and-multi-account-deployment-with-ecs).
- AWS Partner (APN) Blog: [Setting up OpenID Connect with GitLab CI/CD](https://aws.amazon.com/blogs/apn/setting-up-openid-connect-with-gitlab-ci-cd-to-provide-secure-access-to-environments-in-aws-accounts/).
- [GitLab at AWS re:Inforce 2023: Secure GitLab CD pipelines to AWS w/ OpenID and JWT](https://www.youtube.com/watch?v=xWQGADDVn8g).

## Configure a non-public GitLab instance

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391928) in GitLab 18.1

{{< /history >}}

{{< alert type="warning" >}}

This workaround is an advanced configuration option with security considerations to understand.
You must be careful to correctly sync the OpenID configuration and the public keys from your private
GitLab Self-Managed instance to a publicly available location such as an S3 bucket.
You must also ensure that the S3 bucket and files inside are properly secured.
Failing to properly secure the S3 bucket could lead to the takeover of any cloud accounts
associated with this OpenID Connect identity.

{{< /alert >}}

If your GitLab instance is not publicly accessible, configuring OpenID Connect in AWS
is not possible by default. You can use a workaround to make some specific configuration publicly
accessible, enabling OpenID Connect configuration for the instance:

1. Store authentication details for your GitLab instance at a publicly available location,
   for example in S3 files:

   - Host the OpenID configuration for your instance in an S3 file. The configuration is available at
     `/.well-known/openid-configuration`, like `http://gitlab.example.com/.well-known/openid-configuration`.
     Update the `issuer:` and `jwks_uri:` values in the configuration file to point to the publicly available locations.
   - Host the public keys for your instance URL in an S3 file. The keys are available at available at
     `/oauth/discovery/keys`, like `http://gitlab.example.com/oauth/discovery/keys`.

   For example:

   - OpenID configuration file: `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com/.well-known/openid-configuration`.
   - JWKS (JSON Web Key Sets): `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com/oauth/discovery/keys`.
   - The issuer claim `iss:` in the ID Tokens and the `issuer:` value in the OpenID configuration would be:
     `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com`

1. Optional. Use an OpenID configuration validator like the [OpenID Configuration Endpoint Validator](https://www.oauth2.dev/tools/openid-configuration-validator)
   to validate your publicly available OpenID configuration.
1. Configure a custom issuer claim for your ID tokens. By default, GitLab ID tokens
   have the issuer claim `iss:` set as the address of your GitLab instance, for example: `http://gitlab.example.com`.

1. Update the issuer URL:

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   1. Edit `/etc/gitlab/gitlab.rb`:

      ```ruby
      gitlab_rails['ci_id_tokens_issuer_url'] = 'public_url_with_openid_configuration_and_keys'
      ```

   1. Save the file and [reconfigure GitLab](../../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

   {{< /tab >}}

   {{< tab title="Helm chart (Kubernetes)" >}}

   1. Export the Helm values:

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. Edit `gitlab_values.yaml`:

      ```yaml
      global:
        appConfig:
          ciIdTokens:
            issuerUrl: 'public_url_with_openid_configuration_and_keys'
      ```

   1. Save the file and apply the new values:

      ```shell
      helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
      ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   1. Edit `docker-compose.yml`:

      ```yaml
      version: "3.6"
      services:
        gitlab:
          environment:
            GITLAB_OMNIBUS_CONFIG: |
              gitlab_rails['ci_id_tokens_issuer_url'] = 'public_url_with_openid_configuration_and_keys'
      ```

   1. Save the file and restart GitLab:

      ```shell
      docker compose up -d
      ```

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

   1. Edit `/home/git/gitlab/config/gitlab.yml`:

      ```yaml
       production: &base
         ci_id_tokens:
           issuer_url: 'public_url_with_openid_configuration_and_keys'
      ```

   1. Save the file and [reconfigure GitLab](../../../administration/restart_gitlab.md#self-compiled-installations)
      for the changes to take effect.

   {{< /tab >}}

   {{< /tabs >}}

1. Run the [`ci:validate_id_token_configuration` Rake task](../../../administration/raketasks/tokens/_index.md#validate-custom-issuer-url-configuration-for-cicd-id-tokens)
   to validate the CI/CD ID token configuration.

## Troubleshooting

### Error: `Not authorized to perform sts:AssumeRoleWithWebIdentity`

If you see this error:

```plaintext
An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation:
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

It can occur for multiple reasons:

- The cloud administrator has not configured the project to use OIDC with GitLab.
- The role is restricted from being run on the branch or tag. See [configure a conditional role](../_index.md).
- `StringEquals` is used instead of `StringLike` when using a wildcard condition. See [related issue](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws/-/issues/2#note_852901934).

### `Could not connect to openid configuration of provider` error

After adding the Identity Provider in AWS IAM, you might get the following error:

```plaintext
Your request has a problem. Please see the following details.
  - Could not connect to openid configuration of provider: `https://gitlab.example.com`
```

This error occurs when the OIDC identity provider's issuer presents a certificate chain
that's out of order, or includes duplicate or additional certificates.

Verify your GitLab instance's certificate chain. The chain must start with the domain or issuer URL,
then the intermediate certificate, and end with the root certificate. Use this command to
review the certificate chain, replacing `gitlab.example.com` with your GitLab hostname:

```shell
echo | /opt/gitlab/embedded/bin/openssl s_client -connect gitlab.example.com:443
```

### `Couldn't retrieve verification key from your identity provider` error

You might receive an error similar to:

- `An error occurred (InvalidIdentityToken) when calling the AssumeRoleWithWebIdentity operation: Couldn't retrieve verification key from your identity provider, please reference AssumeRoleWithWebIdentity documentation for requirements`

This error might be because:

- The `.well_known` URL and `jwks_uri` of the identity provider (IdP) are inaccessible from the public internet.
- A custom firewall is blocking the requests.
- There's latency of more than 5 seconds in API requests from the IdP to reach the AWS STS endpoint.
- STS is making too many requests to your `.well_known` URL or the `jwks_uri` of the IdP.

As documented in the [AWS Knowledge Center article for this error](https://repost.aws/knowledge-center/iam-sts-invalididentitytoken),
your GitLab instance needs to be publicly accessible so that the `.well_known` URL and `jwks_uri` can be resolved.
If this is not possible, for example if your GitLab instance is in an offline environment,
see how to [configure a non-public GitLab instance](#configure-a-non-public-gitlab-instance)

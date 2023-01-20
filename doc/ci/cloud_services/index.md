---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Connect to cloud services

> - `CI_JOB_JWT` variable for reading secrets from Vault [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207125) in GitLab 12.10.
> - `CI_JOB_JWT_V2` variable to support additional OIDC providers [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/346737) in GitLab 14.7.
> - [ID tokens](../yaml/index.md) to support any OIDC provider, including HashiCorp Vault, [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356986) in GitLab 15.7.

GitLab CI/CD supports [OpenID Connect (OIDC)](https://openid.net/connect/faq/) to
give your build and deployment jobs access to cloud credentials and services.
Historically, teams stored secrets in projects or applied permissions on the GitLab Runner
instance to build and deploy. OIDC capable [ID tokens](../yaml/index.md#id_tokens) are configurable
in the CI/CD job allowing you to follow a scalable and least-privilege security approach.

In GitLab 15.6 and earlier, you must use `CI_JOB_JWT_V2` instead of an ID token,
but it is not customizable. In GitLab 14.6 an earlier you must use the `CI_JOB_JWT`, which has limited support.

## Requirements

- Account on GitLab.
- Access to a cloud provider that supports OIDC to configure authorization and create roles.

ID tokens and `CI_JOB_JWT_V2` support cloud providers with OIDC, including:

- AWS
- Azure
- GCP
- HashiCorp Vault

The `CI_JOB_JWT` only supports the [HashiCorp Vault integration](../examples/authenticating-with-hashicorp-vault/index.md).

NOTE:
Configuring OIDC enables JWT token access to the target environments for all pipelines.
When you configure OIDC for a pipeline, you should complete a software supply chain security
review for the pipeline, focusing on the additional access. You can use the [software supply chain security awareness assessment](https://about.gitlab.com/quiz/software-supply-chain-security/)
as a starting point, and for more information about supply chain attacks, see
[How a DevOps Platform helps protect against supply chain attacks](https://about.gitlab.com/blog/2021/04/28/devops-platform-supply-chain-attacks/).

## Use cases

- Removes the need to store secrets in your GitLab group or project. Temporary credentials can be retrieved from your cloud provider through OIDC.
- Provides temporary access to cloud resources with granular GitLab conditionals including a group, project, branch, or tag.
- Enables you to define separation of duties in the CI/CD job with conditional access to environments. Historically, apps may have been deployed with a designated GitLab Runner that had only access to staging or production environments. This led to Runner sprawl as each machine had dedicated permissions.
- Allows shared runners to securely access multiple cloud accounts. The access is determined by the JWT token, which is specific to the user running the pipeline.
- Removes the need to create logic to rotate secrets by retrieving temporary credentials by default.

## How it works

Each job can be configured with ID tokens, which are provided as a CI/CD variable. These JWTs can be used to authenticate with the OIDC-supported cloud provider such as AWS, Azure, GCP, or Vault.

The following fields are included in the JWT:

| Field                   | When   | Description |
| ----------------------- | ------ | ----------- |
| `aud`                   | Always | Specified in the [ID tokens](../yaml/index.md#id_tokens) configuration |
| `jti`                   | Always | Unique identifier for this token |
| `iss`                   | Always | Issuer, the domain of your GitLab instance |
| `iat`                   | Always | Issued at |
| `nbf`                   | Always | Not valid before |
| `exp`                   | Always | Expires at |
| `sub`                   | Always |`project_path:{group}/{project}:ref_type:{type}:ref:{branch_name}` |
| `namespace_id`          | Always | Use this to scope to group or user level namespace by ID |
| `namespace_path`        | Always | Use this to scope to group or user level namespace by path |
| `project_id`            | Always | Use this to scope to project by ID |
| `project_path`          | Always | Use this to scope to project by path |
| `user_id`               | Always | ID of the user executing the job |
| `user_login`            | Always | Username of the user executing the job |
| `user_email`            | Always | Email of the user executing the job |
| `pipeline_id`           | Always | ID of this pipeline |
| `pipeline_source`       | Always | [Pipeline source](../jobs/job_control.md#common-if-clauses-for-rules) |
| `job_id`                | Always | ID of this job |
| `ref`                   | Always | Git ref for this job |
| `ref_type`              | Always | Git ref type, either `branch` or `tag` |
| `ref_protected`         | Always | `true` if this Git ref is protected, `false` otherwise |
| `environment`           | Job is creating a deployment | Environment this job deploys to ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/294440) in GitLab 13.9) |
| `environment_protected` | Job is creating a deployment |`true` if deployed environment is protected, `false` otherwise ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/294440) in GitLab 13.9) |

```json
{
  "jti": "c82eeb0c-5c6f-4a33-abf5-4c474b92b558",
  "iss": "https://gitlab.example.com",
  "aud": "https://vault.example.com",
  "iat": 1585710286,
  "nbf": 1585798372,
  "exp": 1585713886,
  "sub": "project_path:mygroup/myproject:ref_type:branch:ref:main",
  "namespace_id": "1",
  "namespace_path": "mygroup",
  "project_id": "22",
  "project_path": "mygroup/myproject",
  "user_id": "42",
  "user_login": "myuser",
  "user_email": "myuser@example.com",
  "pipeline_id": "1212",
  "pipeline_source": "web",
  "job_id": "1212",
  "ref": "auto-deploy-2020-04-01",
  "ref_type": "branch",
  "ref_protected": "true",
  "environment": "production",
  "environment_protected": "true"
}
```

### Authorization workflow

```mermaid
sequenceDiagram
    participant GitLab
    Note right of Cloud: Create OIDC identity provider
    Note right of Cloud: Create role with conditionals
    Note left of GitLab: CI/CD job with ID token
    GitLab->>+Cloud: Call cloud API with ID token
    Note right of Cloud: Decode & verify JWT with public key (https://gitlab/-/jwks)
    Note right of Cloud: Validate audience defined in OIDC
    Note right of Cloud: Validate conditional (sub, aud) role
    Note right of Cloud: Generate credential or fetch secret
    Cloud->>GitLab: Return temporary credential
    Note left of GitLab: Perform operation

```

1. Create an OIDC identity provider in the cloud (for example, AWS, Azure, GCP, Vault).
1. Create a conditional role in the cloud service that filters to a group, project, branch, or tag.
1. The CI/CD job includes an ID token which is a JWT token. You can use this token for authorization with your cloud API.
1. The cloud verifies the token, validates the conditional role from the payload, and returns a temporary credential.

## Configure a conditional role with OIDC claims

To configure the trust between GitLab and OIDC, you must create a conditional role in the cloud provider that checks against the JWT.
The condition is validated against the JWT to create a trust specifically against two claims, the audience and subject.

- Audience or `aud`: Configured as part of the ID token:

  ```yaml
  job_needing_oidc_auth:
    id_tokens:
      OIDC_TOKEN:
        aud: https://oidc.provider.com
    script:
      - echo $OIDC_TOKEN
  ```

- Subject or `sub`: A concatenation of metadata describing the GitLab CI/CD workflow including the group, project, branch, and tag. The `sub` field is in the following format:
  - `project_path:{group}/{project}:ref_type:{type}:ref:{branch_name}`

| Filter type                          | Example                                                      |
| ------------------------------------ | ------------------------------------------------------------ |
| Filter to main branch                | `project_path:mygroup/myproject:ref_type:branch:ref:main`   |
| Filter to any branch                 | Wildcard supported. `project_path:mygroup/myproject:ref_type:branch:ref:*` |
| Filter to specific project           | `project_path:mygroup/myproject:ref_type:branch:ref:main` |
| Filter to all projects under a group | Wildcard supported. `project_path:mygroup/*:ref_type:branch:ref:main` |
| Filter to a Git tag                  | Wildcard supported. `project_path:mygroup/*:ref_type:tag:ref:1.0` |

## OIDC authorization with your cloud provider

To connect with your cloud provider, see the following tutorials:

- [Configure OpenID Connect in AWS](aws/index.md)
- [Configure OpenID Connect in Azure](azure/index.md)
- [Configure OpenID Connect in Google Cloud](google_cloud/index.md)

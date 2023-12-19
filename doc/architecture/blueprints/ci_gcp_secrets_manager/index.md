---
status: proposed
creation-date: "2023-11-29"
authors: [ "@alberts-gitlab" ]
coach: "@grzesiek"
approvers: [ "@jocelynjane", "@shampton" ]
owning-stage: "~devops::verify"
participating-stages: []
---

<!-- Blueprints often contain forward-looking statements -->
<!-- vale gitlab.FutureTense = NO -->

# Support GCP Secrets Manager for CI External Secrets

## Summary

This blueprint describes the architecture to add GCP Secrets Manager as one of the
sources for CI External Secrets.

## Motivation

GitLab CI allows users to pull secrets from external sources into GitLab CI jobs.
Prior to this, the supported secret managers are HashiCorp Vault and Azure Key Vault.
GCP Secrets Manager is another major secret manager product and there has been
multiple requests and feedback to add GCP Secrets Manager to the list of
supported secret managers.

### Goals

The goal of this feature is to allow GitLab CI users to use secrets stored in
GCP Secrets Manager in their CI jobs.

### Non-Goals

This feature does not cover the following:

- Using secrets from GCP Secrets Manager in other GitLab workloads.
- Managing secrets in GCP Secrets Manager or other secret managers through GitLab.

## Proposal

This feature requires a tight integration between GCP Secrets Manager, GitLab Rails and GitLab Runner.

The solution to this feature involves three main parts:

1. Authentication with GCP Secrets Manager
1. CI configuration on GitLab Rails
1. Secrets access by GitLab Runner

### Authentication with GCP Secrets Manager

GCP Secrets Manager needs to authenticate secret access requests coming from GitLab Runner.
Since GitLab Runner can operate in many modes (GitLab.com SaaS runners, SaaS with self-managed runner, GitLab Self-Managed, etc),
there is no direct correlation between the Runner instance and any GCP identities that can have access to the secrets.

To solve this, we would use OIDC and GCP's Workload Identity Federation mechanism to authorize the requests.

CI jobs already have support for OIDC through CI variables containing ID tokens issued by the GitLab instance.
These ID tokens already carry `claim`s that describe the context of the CI job.
For example, it includes details such as `group_id`, `group_path`, `project_id`, and `project_path`.

On the GCP side, Workload Identity Federation allows the use of OIDC to grant GCP IAM roles to the external identities
represented by the ID tokens. Through Workload Identity Federation, the GCP user can grant specific IAM roles to
specific principals identified through the OIDC `claim`. For example, a particular `group_id` claim can be given an IAM role
to access a particular set of secrets in GCP Secrets Manager. This would allow the GCP user to grant granular
access to the secrets in GCP Secrets Manager.

### CI configuration on GitLab Rails

GitLab Rails will be the interface where users configure the CI jobs. For the GCP Secrets Manager integration,
there needs to be additional configuration to specify GCP Secrets Manager as a source for external secrets as well as
GCP specific information in order to enable authentication between GitLab Runner and GCP Secrets Manager.

The proposed CI keyword would be the following:

```yaml
job_name:
  id_tokens:
    GCP_SM_ID_TOKEN:
      aud: my-GCP-workload-identity-federation-audience
  secrets:
    DATABASE_PASSWORD:
      gcp_sm:
        name: my-project-secret  # This is the name of the secret defined in GCP Secrets Manager
        version: 1               # optional: default to `latest`.
      token: GCP_SM_ID_TOKEN
```

In addition, GitLab Runner needs to know the following in order to perform the authentication and access the secret.
These should be included as CI variables in the job.

- GCP Project Number `GCP_PROJECT_NUMBER`
- GCP Workload Federation Pool ID `GCP_WORKLOAD_FEDERATION_POOL_ID`
- GCP Workload Federation Provider ID `GCP_WORKLOAD_FEDERATION_PROVIDER_ID`

### Secrets access by GitLab Runner

Based on the job specification defined above, GitLab Runner needs to implement the following:

1. OIDC authentication with GCP Secure Token Service to obtain an access token.
1. Secret access requests to GCP Secrets Manager to obtain the payload of the desired secret version.
1. Adding the secrets to the build.

## Alternative Solutions

N/A.

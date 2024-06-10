---
stage: Systems
group: Cloud Connector
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Cloud Connector: Configuration

A GitLab Rails instance accesses backend services uses a [Cloud Connector Service Access Token](architecture.md#access-control):

- This token is synced to a GitLab instance from CustomersDot daily and stored in the instance's local database.
- For GitLab.com, we do not require this step; instead, we issue short-lived tokens for each request.

The Cloud Connector **JWT** Service token contains a custom claim, which represents the list of access scopes that define which features, or unit primitives, this token is valid for.

## Configuration structure

The information about how paid features are bundled into GitLab tiers and add-ons is configured and stored in a YAML file:

```yaml
services:
  code_suggestions:
    backend: 'gitlab-ai-gateway'
    cut_off_date: 2024-02-15 00:00:00 UTC
    min_gitlab_version: '16.8'
    bundled_with:
      duo_pro:
        unit_primitives:
          - code_suggestions
  duo_chat:
    backend: 'gitlab-ai-gateway'
    min_gitlab_version_for_beta: '16.8'
    min_gitlab_version: '16.9'
    bundled_with:
      duo_pro:
        unit_primitives:
          - duo_chat
          - documentation_search
```

### Terms

The configuration contains the following information:

- `unit_primitives`: Each unit primitive represents the smallest logical feature that a permission/access scope can govern.
  It represents the actual feature,
  and the value of this attribute is used as a scope when Service Access token is being issued.

  The recommended naming convention for the new `unit_primitive` should be `$VERB_$NOUN`. Example: `explain_vulnerability`
- `service`: The feature, or UP, can be delivered as part of the existing service (Duo Chat) or as a stand-alone service.
  Example: The **documentation_search** represent an unit primitive that is delivered as part of the Duo Chat service.
- `bundled_with`: Represents the list of add-ons. Each unit primitive is bundled with add-on.
  Example: Code Suggestions and Duo Chat were two features sold together under the `DUO PRO` add-on.
  Same unit primitive can be bundled with multiple add-ons.
  Example: Code Suggestions could be available with both the `DUO PRO` and `DUO ENTERPRISE` add-ons.
- `cut_off_date`: Represents the cut-off date when the feature is no longer available for free (Experimental).
  If it's not set, the feature is available for free by default.
- `min_gitlab_version`: Represents the minimum required GitLab version to use the feature.
  If it's not set, the feature is available for all GitLab versions.
- `min_gitlab_version_for_free_access`: Represents the minimum required GitLab version to use the service during the free access period.
  If it's not set, the service is available for all GitLab versions.
- `backend`: The name of the backend serving this feature. The name is used as a token audience claim.
  Example: `gitlab-ai-gateway`.

## CustomersDot configuration

For GitLab Dedicated and self-managed GitLab instances we are delegating trust to the CustomersDot, the access token issuer.

The configuration is located in [`cloud_connector.yml`](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/main/config/cloud_connector.yml),
and represents an almost exact copy of the GitLab.com configuration.

## GitLab.com configuration

Because the GitLab.com deployment enjoys special trust, it has the advantage of being able to [self-sign and create service tokens](architecture.md#gitlabcom) for every request to a Cloud Connector feature.

To issue tokens with the proper scopes, GitLab.com needs access to the configuration.
The configuration is located in [`access_data.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/cloud_connector/access_data.yml),
and it's an almost exact copy of the [CustomersDot configuration](#customersdot-configuration).

---
stage: Systems
group: Cloud Connector
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: 'Cloud Connector: Configuration'
---

A GitLab Rails instance accesses backend services uses a [Cloud Connector Service Access Token](architecture.md#access-control):

- This token is synced to a GitLab instance from CustomersDot daily and stored in the instance's local database.
- For GitLab.com, we do not require this step; instead, we issue short-lived tokens for each request.

The Cloud Connector **JWT** contains a custom claim, which represents the list of access scopes that define which features, or unit primitives, this token is valid for.

## Unit Primitives and Configuration

As per the [Architecture Decision Record (ADR) 003](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cloud_connector/decisions/003_unit_primitives/),
we have decided to extract the configuration of unit primitives to an external library called [`gitlab-cloud-connector`](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector).
This library serves as the Single Source of Truth (SSoT) for all Cloud Connector configurations and is available as both a Ruby gem and a Python package.

### Configuration format and structure

The configuration in `gitlab-cloud-connector` follows this structure:

```shell
config
  ├─ unit_primitives/
  │  ├─ duo_chat.yml
  │  └─ ...
  ├─ backend_services/
  │  ├─ ai_gateway.yml
  │  └─ ...
  ├─ add_ons/
  │  ├─ duo_pro.yml
  │  └─ ...
  ├─ services/
  │  ├─ duo_chat.yml
  │  └─ ...
  └─ license_types/
     ├─ premium.yml
     └─ ...
```

#### Unit primitive configuration

We have a YAML file per unit primitive. It contains information on how this unit primitive is bundled with add-ons and license types, and other metadata.
The configuration for each unit primitive adhere to the following schema.

##### Required Fields

| Field | Type | Description                                                                                                                                            |
|-------|------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name` | string | Unit primitive name in `snake_case` format (lowercase letters, numbers, underscores). Should follow `$VERB_$NOUN` pattern (for example, `explain_vulnerability`). |
| `description` | string | Description of the unit primitive's purpose and functionality.                                                                                          |
| `group` | string | Engineering group that owns the unit primitive (for example, "group::cloud connector").                                                                         |
| `feature_category` | string | Feature category classification (see [categories](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/categories.yml)).                          |
| `documentation_url` | string | URL to the unit primitive's documentation.                                                                                                              |

##### Optional Fields

| Field | Type | Description                                          |
|-------|------|------------------------------------------------------|
| `milestone` | string | GitLab milestone that introduced the unit primitive.  |
| `introduced_by_url` | string | Merge request URL that introduced the unit primitive. |
| `unit_primitive_issue_url` | string | Issue URL proposing the unit primitive introduction.  |
| `deprecated_by_url` | string | Merge request URL that deprecated the unit primitive. |
| `deprecation_message` | string | Explanation of deprecation context and reasons.       |
| `cut_off_date` | datetime | UTC timestamp when free access ends (if applicable).  |
| `min_gitlab_version` | string | Minimum required GitLab version (for example, `17.8`).          |
| `min_gitlab_version_for_free_access` | string | Minimum version for free access period (for example, `17.8`).   |

##### Access Control Fields

| Field | Type | Description                                                             |
|-------|------|-------------------------------------------------------------------------|
| `license_types` | array[string] | GitLab license types that can access this primitive. Possible values must match the name field in corresponding files under `config/license_types` (for example, `premium`).|
| `backend_services` | array[string] | Backend services hosting this primitive. Possible values must match the name field in corresponding files under `config/backend_services` (for example, `ai_gateway`).|
| `add_ons` | array[string] | Add-on products including this primitive. Possible values must match the name field in corresponding files under `config/add_ons` (for example, `duo_pro`). |

Example unit primitive configuration:

```yaml
# config/unit_primitives/new_feature.yml
---
name: new_feature
description: Description of the new feature
cut_off_date: 2024-10-17T00:00:00+00:00  # Optional, set if not free
min_gitlab_version: '16.9'
min_gitlab_version_for_free_access: '16.8'
group: group::your_group
feature_category: your_category
documentation_url: https://docs.gitlab.com/ee/path/to/docs
backend_services:
  - ai_gateway
add_ons:
  - duo_pro
  - duo_enterprise
license_types:
  - premium
  - ultimate
```

#### Related Configurations

##### Backend Services

Each backend service must have its own YAML configuration under `config/backend_services`. For example:

```yaml
# config/backend_services/ai_gateway.yml
---
name: ai_gateway
project_url: https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist
group: group::ai framework
jwt_aud: gitlab-ai-gateway
```

##### Add-ons

Each add-on must have its own YAML configuration under `config/add_ons`. For example:

```yaml
# config/add_ons/duo_pro.yml
---
name: duo_pro
```

##### License Types

Each license type must have its own YAML configuration under `config/license_types`. For example:

```yaml
# config/license_types/premium.yml
---
name: premium
```

### Backward compatibility

To support backward compatibility for customers running older GitLab versions and with the old [legacy structure](#legacy-structure), we provide a mapping from the new to old format,
and soon to be deprecated "service" abstraction.

#### Service configuration

| Field | Type | Description                                                                                                                                                                                                                                               |
|-------|------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name` | string | The unique name of the service, consisting of lowercase alphanumeric characters and underscores.                                                                                                                                                          |
| `basic_unit_primitive` | string | The most fundamental unit primitive representing key configuration values like `cut_off_date` and `min_gitlab_version`. If not set, the first unit primitive in the `unit_primitives` list is used. Used to derive these shared properties across the service.  |
| `gitlab_realm` | array[string] | An array of environments where the service is available. Possible values: `gitlab-com`, `self-managed`.                                                                                                                                                   |
| `description` | string | A brief description of the service.                                                                                                                                                                                                                       |
| `unit_primitives` | array[string] | An array of unit primitives associated with the service.                                                                                                                                                                                                  |

Example of a new service mapping configuration:

```yaml
# config/services/duo_chat.yml
---
name: duo_chat
basic_unit_primitive: duo_chat
gitlab_realm:
  - gitlab-com
  - self-managed
unit_primitives:
  - ask_build
  - ask_commit
  - ask_epic
  - ask_issue
  - ask_merge_request
  - documentation_search
  - duo_chat
  - explain_code
  - fix_code
  - include_dependency_context
  - include_file_context
  - include_issue_context
  - include_local_git_context
  - include_merge_request_context
  - include_snippet_context
  - refactor_code
  - write_tests
```

### Legacy structure

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

| Field | Type | Description                                                                                                                                        |
|-------|------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| `unit_primitives` | array[string] | The smallest logical features that a permission or access scope can govern. Should follow `$VERB_$NOUN` naming pattern (for example, `explain_vulnerability`). |
| `service` | string | The service name that delivers the feature. Can be standalone or part of an existing service (for example, `duo_chat`).                                          |
| `bundled_with` | object | Map of add-ons that include this feature. A feature can be bundled with multiple add-ons (for example, `duo_pro`, `duo_enterprise`).                            |
| `cut_off_date` | datetime | UTC timestamp when free access ends. If not set, feature remains free.                                                                              |
| `min_gitlab_version` | string | Minimum required GitLab version (for example, `17.8`). If not set, available for all versions.                                                                |
| `min_gitlab_version_for_free_access` | string | Minimum version for free access period (for example, `17.8`). If not set, available for all versions.                                                         |
| `backend` | string | Name of the backend service hosting this feature, used as token audience claim (for example, `gitlab-ai-gateway`).                                          |

#### GitLab.com configuration

Because the GitLab.com deployment enjoys special trust, it can [self-sign and create Instance JSON Web Tokens (IJWTs)](architecture.md#gitlabcom) for every request to a Cloud Connector feature.

To issue tokens with the proper scopes, GitLab.com needs access to the configuration.

Configuration is stored in the `gitlab-cloud-connector` gem using a [unit primitive configuration format and structure](#configuration-format-and-structure).
GitLab.com still uses the [legacy `available_services` structure](#legacy-structure).
The `Gitlab::CloudConnector::AvailableServicesGenerator` generates legacy structure for compatibility.

To add a new unit primitive, follow [Register new feature for Self-Managed, Dedicated and GitLab.com customers](_index.md#register-new-feature-for-self-managed-dedicated-and-gitlabcom-customers)

#### CustomersDot configuration

For GitLab Dedicated and GitLab Self-Managed we are delegating trust to the CustomersDot, the access token issuer.

The configuration is located in [`cloud_connector.yml`](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/main/config/cloud_connector.yml),
and represents an almost exact copy of the GitLab.com configuration.

We are in the process of removing `cloud_connector.yml` as part of our effort to use the `gitlab-cloud-connector` gem as the Single Source of Truth (SSoT) for unit primitive configuration.
To add a new unit primitive during this transition period, follow the [Transition period from old configuration process](_index.md#transition-from-old-configuration).

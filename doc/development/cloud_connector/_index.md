---
stage: Systems
group: Cloud Connector
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Cloud Connector
---

[GitLab Cloud Connector](https://about.gitlab.com/direction/cloud-connector/) is a way to access services common to
multiple GitLab deployments, instances, and cells. As of now, Cloud Connector is not a
dedicated service itself, but rather a collection of APIs and code that standardizes the approach to authentication and
other items when integrating Cloud based services with the GitLab instance. This page aims to explain how to use
Cloud Connector to link GitLab Rails to a service.

See the [architecture page](architecture.md) for more information about Cloud Connector. See [terms](architecture.md#terms)
for a list of terms used throughout the document. Also see [configuration](configuration.md) for the information
on how paid features are bundled into GitLab tiers and add-ons.

## Tutorial: Connect a new feature using Cloud Connector

The following sections will cover the following use cases:

- [The new feature is introduced through the existing backend service](#the-new-feature-is-introduced-through-the-existing-backend-service) that is already connected to Cloud Connector (that is, the **AiGateway**).
- [The new feature is introduced through new backend service](#the-new-feature-is-introduced-via-new-backend-service) that needs to be connected to Cloud Connector.

### The new feature is introduced through the existing backend service

The **Ai Gateway** is currently the only backend service that is connected with the CloudConnector.
To add new feature to the existing backend service (**Ai Gateway**):

1. [Register new feature in the JWT issuer](#register-the-new-feature-in-the-jwt-issuer).
1. [Implement permission checks in GitLab Rails](#implement-permission-checks-in-gitlab-rails).
1. [Implement authorization checks in backend service](#implement-authorization-checks-in-backend-service).

**Optional:** If the backend service the token is used for requires additional claims to be embedded in the
service access token, contact [#g_cloud_connector](https://gitlab.enterprise.slack.com/archives/CGN8BUCKC) (Slack, internal only)
because we do not currently have interfaces in place to self-service this.

#### Register the new feature in the JWT issuer

- For GitLab Dedicated and GitLab Self-Managed, the CustomersDot is the **JWT issuer**.
- For GitLab.com deployment, GitLab.com is the **JWT issuer**, because it's able to [self-sign and create JWTs](architecture.md#gitlabcom) for every request to a Cloud Connector feature.

#### Register new feature for Self-Managed, Dedicated and GitLab.com customers

You must register the new feature as a unit primitive in the [`gitlab-cloud-connector`](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector) repository.
This repository serves as the Single Source of Truth (SSoT) for all Cloud Connector configurations.

To register a new feature:

1. Create a new YAML file in the `config/unit_primitives/` directory of the `gitlab-cloud-connector` repository.
1. Define the unit primitive configuration, and ensure you follow the [schema](configuration.md#unit-primitive-configuration).

For example, to add a new feature called `new_feature`:

```yaml
# config/unit_primitives/new_feature.yml
---
name: new_feature
description: Description of the new feature
cut_off_date: 2024-10-17T00:00:00+00:00  # Optional, set if not free
min_gitlab_version: '16.9'
min_gitlab_version_for_free_access: '16.8' # Optional
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

##### Backward Compatibility

For backward compatibility where instances are still using the old [legacy structure](configuration.md#legacy-structure), consider adding your unit primitive to the [service configuration](configuration.md#service-configuration) as well.

- If the unit primitive is a stand-alone feature, no further changes are needed, and the service with the same name is generated automatically.
- If the unit primitive is delivered as part of existing service like `duo_chat`, `self_hosted_models` or `vertex_ai_proxy`, add the unit primitive to the desired service in the [`config/services`](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector/-/tree/main/config/services) directory.

##### Deployment process

Follow our [release checklist](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector/-/blob/main/.gitlab/merge_request_templates/Release.md#checklist) for publishing the new version of the library and using it in GitLab project.

#### Transition from old configuration

We are transitioning away from separate [CustomersDot](configuration.md#customersdot-configuration) and [GitLab.com](configuration.md#gitlabcom-configuration) configurations, as outlined in our [ADR-003 Migration Path](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cloud_connector/decisions/003_unit_primitives/).

##### Current state and ongoing changes

- New features are added as **unit primitives** in the [`gitlab-cloud-connector` configuration](configuration.md#configuration-format-and-structure).
- Migration to the `gitlab-cloud-connector` gem as the Single Source of Truth (SSoT) is in progress in [epic 15949](https://gitlab.com/groups/gitlab-org/-/epics/15949).

  - `access_data.yml` was removed in [issue 507518](https://gitlab.com/gitlab-org/gitlab/-/issues/507518).
  - `cloud_connector.yml` file is slated for deprecation and removal, as detailed in [issue 11268](https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/11268).

##### Transition period guidelines

- Maintain both [new](configuration.md#configuration-format-and-structure) and [CustomersDot configuration](configuration.md#customersdot-configuration) configurations.

##### Register new features

###### Process

After adding a [new unit primitive to `gitlab-cloud-connector`](#register-new-feature-for-self-managed-dedicated-and-gitlabcom-customers),
open a separate merge request to update [CustomersDot configuration](configuration.md#customersdot-configuration) for GitLab Dedicated and self-managed instances.

1. Make sure that merge request for adding [new unit primitive to `gitlab-cloud-connector`](#register-new-feature-for-self-managed-dedicated-and-gitlabcom-customers) has been merged.
1. Download the latest generated [`cloud-connector.yml` file](https://gitlab.com/api/v4/projects/58733651/jobs/artifacts/main/raw/config/cloud_connector.yml?job=generate_cloud_connector_yml)
1. Replace the [`cloud-connector.yml` file](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/main/config/cloud_connector.yml)
1. Ensure that the generated file reflects the changes you have made. Additionally, carefully verify that no changes have been inadvertently removed in the file.

#### Implement Permission checks in GitLab Rails

##### New feature is delivered as stand-alone service

###### Access Token

As an example, the feature is delivered as a stand-alone service called `new_feature`.

1. Call `CloudConnector::AvailableServices.find_by_name(:new_feature).access_token(user_or_namespace)`
   and include this token in the `Authorization` HTTP header field.

   - On GitLab.com, it will self-issue a token with scopes that depend on the provided resource:
     - For a user: scopes will be based on the user's seat assignment
     - For a namespace: scopes will be based on purchased add-ons for this namespace
       - If a service can be accessed for free, the token will include all available scopes for that service.
       - For Duo Chat, the **JWT** would include the `documentation_search` and `duo_chat` scopes.
   - On self-managed, it will always return `::CloudConnector::ServiceAccessToken` **JWT** token.
     - Provided parameters such as user, namespace or extra claims would be ignored for Self managed instances.
       Refer to [this section](#the-new-feature-is-introduced-through-the-existing-backend-service) to see how custom claims are handled for self-managed instances.

   The **backend service** (AI gateway) must validate this token and any scopes it carries when receiving the request.

1. If you need to embed additional claims in the token specific to your use case, you can pass these
   in the `extra_claims` argument.

1. Ensure your request sends the required headers to the [backend service](#implement-authorization-checks-in-backend-service).

   These headers can be found in the `gitlab-cloud-connector` [README](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector/-/tree/main/src/python#authentication).

   Some of these headers can be injected by merging the result of the `::CloudConnector#headers` method to your payload.
   For AI uses cases and requests targeting the AI gateway, use `::CloudConnector#ai_headers` instead.

###### Permission checks

To decide if the service is available or visible to the end user, we need to:

- Optional. On GitLab Self-Managed, if the new feature is introduced as a new [enterprise feature](../ee_features.md#implement-a-new-ee-feature),
  check to determine if user has access to the feature by following the [EE feature guideline](../ee_features.md#guard-your-ee-feature).

  ```ruby
    next true if ::Gitlab::Saas.feature_available?(:new_feature_on_saas)

    ::License.feature_available?(:new_feature)
  ```

- On GitLab Self-Managed, check if the customer is using an [online cloud license](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#what-is-cloud-licensing)
  - Cloud connector currently only support online cloud license for self-managed customers.
  - Trials or legacy licenses are not supported.
  - GitLab.com is using a legacy license.

  ```ruby
    ::License.current&.online_cloud_license?
  ```

- On GitLab.com and GitLab Self-Managed, check if the service has free access.
  - The feature is considered free, if the [cut-off date](configuration.md) is not set, or it is set in the future.

  ```ruby
    # Returns whether the service is free to access (no addon purchases is required)
    CloudConnector::AvailableServices.find_by_name(:new_feature).free_access?
   ```

- Optional. If the service has free access, this usually means that the experimental features are subject to the [Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
  - For GitLab Duo features, the customer needs to enable [experimental toggle](../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) in order to use experimental features for free.

- On GitLab.com and GitLab Self-Managed, if the service is not accessible for free, check if the add-on bundled with this service has been purchased by the customer (for the group/namespace)

  ```ruby
    # Returns true if at least one add-on that is bundled with the service is purchased.
    #
    # - For provided namespace, it will check if add-on is purchased for the provided group/project or its ancestors.
    # - For SM, it would ignore namespace as AddOns are not purchased per namespace for self managed customers.
    CloudConnector::AvailableServices.find_by_name(:new_feature).purchased?(namespace)
  ```

- On GitLab.com and GitLab Self-Managed, check if the customer's end-user has been assigned to the proper seat.

  ```ruby
    # Returns true if service is allowed to be used.
    #
    # For provided user, it will check if user is assigned to a proper seat.
    current_user.allowed_to_use?(:new_feature)
  ```

###### Example

The following example is for a request to the service called `:new_feature`.
Here we assume your backend service is called `foo` and is already reachable at `https://cloud.gitlab.com/foo`.
We also assume that the backend service exposes the service using a `/new_feature_endpoint` endpoint.
This allows clients to access the service at `https://cloud.gitlab.com/foo/new_feature_endpoint`.

Add a new policy rule in [ee/global_policy.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/policies/ee/global_policy.rb):

```ruby
  condition(:new_feature_licensed) do
    next true if ::Gitlab::Saas.feature_available?(:new_feature_on_saas)
    next false unless ::License.current.online_cloud_license?

    ::License.feature_available?(:new_feature)
  end

  condition(:user_allowed_to_use_new_feature) do
    @user.allowed_to_use?(:new_feature)
  end

  rule { new_feature_licensed & user_allowed_to_use_new_feature }.enable :access_new_feature
```

The request

```ruby
include API::Helpers::CloudConnector

# Check if the service is available for the given user based on seat assignment, add-on purchases
return unauthorized! unless current_user.can?(:access_new_feature)

# For Gitlab.com it will self-issue a token with scopes based on provided resource:
# - For provided user, it will self-issue a token with scopes based on user assigment permissions
# - For provided namespace, it will self-issue a token with scopes based on add-on purchased permissions
# - If service has free_access?, it will self-issue a token with all available scopes
#
# For SM, it will return :CloudConnector::ServiceAccessToken instance token, ignoring provided user, namespace and extra claims
token = ::CloudConnector::AvailableServices.find_by_name(:new_feature).access_token(current_user)

Gitlab::HTTP.post(
  "https://cloud.gitlab.com/foo/new_feature_endpoint",
  headers: {
      'Authorization' => "Bearer #{token}",
    }.merge(cloud_connector_headers(current_user))
)
```

The introduced policy can be used to control if the front-end is visible. Add a `new_feature_helper.rb`:

```ruby
  def show_new_feature?
      current_user.can?(:access_new_feature)
  end
```

##### New feature is delivered as part of the existing service (Duo Chat)

###### Access Token

If the feature is delivered as part of the existing service, like `Duo Chat`,
calling `CloudConnector::AvailableServices.find_by_name(:duo_chat).access_token(user_or_namespace)` would return an **IJWT** with
access scopes including all authorized features (**unit primitives**).

The **backend service** (AI gateway) would prevent access to the specific feature (**unit primitive**) if the token scope is not included in the **JWT**.

###### Permission checks

If the feature is delivered as part of the existing service, like `Duo Chat`, no additional permission checks are needed.

We can rely on existing global policy rule `user.can?(:access_duo_chat)`.
If end-user has access to at least one feature (**unit primitive**), end-user can access the service.
Access to the individual feature (**unit primitive**), is governed by the **IJWT** scopes, that will be validated by the **backend service** (Ai Gateway).
See [access token](#access-token-1)

#### Implement authorization checks in backend service

GitLab Rails calls a backend service to deliver functionality that would otherwise be unavailable to Self-managed and
Dedicated instances. For GitLab Rails to be able to call this, there has to be an endpoint exposed.
The backend service must verify each JWT sent by GitLab Rails in the Authorization header.

For more information and examples on the AI gateway authorization process, check the [Authorization in AI gateway documentation](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/auth.md?ref_type=heads#authorization-in-ai-gateway).

### The new feature is introduced via new backend service

To integrate a new backend service that isn't already accessible by Cloud Connector features:

1. [Set up JWT validation](#set-up-jwt-validation).
1. [Make it available at `cloud.gitlab.com`](#add-a-new-cloud-connector-route).

#### Set up JWT validation

As mentioned in the [Implement authorization checks in backend service](#implement-authorization-checks-in-backend-service) for services
that already use Cloud Connector, each service must verify that the JWT sent by a GitLab instance is legitimate.

To accomplish this, a backend service must:

1. [Maintain a JSON Web Key Set (JWKS)](#maintain-jwks-for-token-validation).
1. [Validate JWTs with keys in this set](#validate-jwts-with-jwks).

For a detailed explanation of the mechanism behind this, refer to
[Architecture: Access control](architecture.md#access-control).

We strongly suggest to use existing software libraries to handle JWKS and JWT authentication.
Examples include:

- [`go-jwt`](https://github.com/golang-jwt/)
- [`ruby-jwt`](https://github.com/jwt/ruby-jwt)
- [`python-jose`](https://github.com/mpdavis/python-jose)

##### Maintain JWKS for token validation

JWTs are cryptographically signed by the token authority when first issued.
GitLab instances then attach the JWTs in requests made to backend services.

To validate JWT service access tokens, the backend service must first obtain the JWKS
containing the public validation key that corresponds to the private signing key used
to sign the token. Because both GitLab.com and CustomersDot issue tokens,
the backend service must fetch the JWKS from both.

To fetch the JWKS, use the OIDC discovery endpoints exposed by GitLab.com and CustomersDot.
For each of these token authorities:

1. `GET /.well-known/openid-configuration`

   Example response:

   ```json
   {
     "issuer": "https://customers.gitlab.com/",
     "jwks_uri": "https://customers.gitlab.com/oauth/discovery/keys",
     "id_token_signing_alg_values_supported": [
       "RS256"
     ]
   }
   ```

1. `GET <jwks_uri>`

   Example response:

   ```json
   {
     "keys": [
       {
         "kty": "RSA",
         "n": "sGy_cbsSmZ_Y4XV80eK_ICmz46XkyWVf6O667-mhDcN5FcSfPW7gqhyn7s052fWrZYmJJZ4PPyh6ZzZ_gZAaQM7Oe2VrpbFdCeJW0duR51MZj52FwShLfi-NOBz2GH9XuUsRBKnXt7wwKQTabH4WW7XL23Hi0eDjc9dyQmsr2-AbH05yVsrgvEYSsWiCGEgobPgNc51DwBoIcsJ-kFN591aO_qAkbpf1j7yAuAVG7TUxaditQhyZKkourPXXyx1R-u0Lx9UJyAV8ySqFxq3XDE_pg6ZuJ7M0zS0XnGI82g3Js5zAughrQyJMhKd8j5c8UfSGxhRBQh58QNl3UwoMjQ",
         "e": "AQAB",
         "kid": "ZoObkdsnUfqW_C_EfXp9DM6LUdzl0R-eXj6Hrb2lrNU",
         "use": "sig",
         "alg": "RS256"
       }
     ]
   }
   ```

1. Cache the response. We suggest to let the cache expire once a day.

The keys obtained this way can be used to validate JWTs issued by the respective token authority.
Exactly how this works depends on the programming language and libraries used. General instructions
can be found in [Locate JSON Web Key Sets](https://auth0.com/docs/secure/tokens/json-web-tokens/locate-json-web-key-sets).
Backend services may merge responses from both token authorities into a single cached result set.

##### Validate JWTs with JWKS

To validate a JWT:

1. Read the token string from the HTTP `Authorization` header.
1. Validate it using a JWT library object and the JWKS [obtained previously](#maintain-jwks-for-token-validation).

When validating a token, ensure that:

1. The token signature is correct.
1. The `aud` claim equals or contains the backend service (this field can be a string or an array).
1. The `iss` claim matches the issuer URL of the key used to validate it.
1. The `scopes` claim covers the functionality exposed by the requested endpoint (see [Implement authorization checks in backend service](#implement-authorization-checks-in-backend-service)).

#### Add a new Cloud Connector route

All Cloud Connector features must be accessed through `cloud.gitlab.com`, a global load-balancer that
routes requests into backend services based on paths prefixes. For example, AI features must be requested
from `cloud.gitlab.com/ai/<AI-specific-path>`. The load-balancer then routes `<AI-specific-path>` to the AI gateway.

To connect a new backend service to Cloud Connector, you must claim a new path-prefix to route requests to your
service. For example, if you connect `foo-service`, a new route must be added that routes `cloud.gitlab.com/foo`
to `foo-service`.

Adding new routes requires access to production infrastructure configuration. If you require a new route to be
added, open an issue in the [`gitlab-org/gitlab` issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues/new)
and assign it to the Cloud Connector group.

## Testing

An example for how to set up an end-to-end integration with the AI gateway as the backend service can be found [here](../ai_features/_index.md#required-install-ai-gateway).

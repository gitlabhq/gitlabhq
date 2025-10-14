---
stage: Fulfillment
group: Fulfillment
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Cloud Connector
---

GitLab Cloud Connector is a way to access services common to
multiple GitLab deployments, instances, and cells. As of now, Cloud Connector is not a
dedicated service itself, but rather a collection of APIs and code that standardizes the approach to authentication and
other items when integrating Cloud based services with the GitLab instance. This page aims to explain how to use
Cloud Connector to link GitLab Rails to a service.

## Ownership

Cloud Connector has shared ownership.
If you have a request or a question, please refer to the [handbook](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cloud_connector)
and get in touch with the appropriate team.

## Architecture

See the [architecture page](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cloud_connector/authentication/architecture/) in handbook for more information about Cloud Connector.
See [terms](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cloud_connector/authentication/architecture/#terms)
for a list of terms used throughout the document.

## "Cloud Connected" backends

The **AI gateway** is the primary backend service connected with the CloudConnector.
In the context of AI feature development, we expect that the new or existing feature will be served from the **AI gateway**.

## Tutorial: Connect a new feature using Cloud Connector

Check [unit primitives and configuration](unit_primitives.md) for the information on how paid features are bundled into GitLab tiers and add-ons.
Decide whether your feature needs a new Unit Primitive. In that case, follow the steps:

1. [Register new feature in the JWT issuer](#register-the-new-feature-in-the-jwt-issuer).
1. [Implement permission checks in GitLab Rails](#implement-permission-checks-in-gitlab-rails).
1. [Implement authorization checks in backend service](#implement-authorization-checks-in-backend-service).

### Register the new feature in the JWT issuer

- For GitLab Dedicated and GitLab Self-Managed, the CustomersDot is the **JWT issuer**.
- For GitLab.com deployment, GitLab.com is the **JWT issuer**, because it's able to [self-sign and create JWTs](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cloud_connector/authentication/architecture/#gitlabcom) for every request to a Cloud Connector feature.

You must register the new feature as a unit primitive in the [`gitlab-cloud-connector`](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector) repository.
This repository serves as the Single Source of Truth (SSoT) for all Cloud Connector configurations.

To register a new feature:

1. Create a new YAML file in the `config/unit_primitives/` directory of the `gitlab-cloud-connector` repository.
1. Define the unit primitive configuration, and ensure you follow the [schema](unit_primitives.md#unit-primitive-configuration).
1. Follow our [release checklist](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector/-/blob/main/.gitlab/merge_request_templates/Release.md#checklist) for publishing the new version of the library and using it in GitLab project.

### Implement Permission checks in GitLab Rails

#### Authentication

As an example, the feature is delivered as new Unit Primitive called `new_feature`.

Call to `Gitlab::AiGateway.headers(user: user, unit_primitive_name: :new_feature, ai_feature_name: ai_feature_name_from_catalog)`
will give you a set of headers you need to attach to every request to **AI gateway**.
Refer to [AiFeaturesCatalogue](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/llm/utils/ai_features_catalogue.rb) to
pick the appropriate value of `ai_feature_name_from_catalog`.

The headers set has everything needed to authenticate your AI request with the **AI gateway**.
In particular, it includes access token in the `Authorization` field:

- On GitLab.com, it will self-issue a token with scopes that depend on the provided resource:
  - For a user: scopes will be based on the user's seat assignment
  - For a namespace: scopes will be based on purchased add-ons for this namespace
- On GitLab Self-Managed, it will always include `::CloudConnector::ServiceAccessToken` **JWT** token stored in the database.

The **backend service** (**AI gateway**) must validate this token and any scopes it carries when receiving the request.

You can merge any additional custom headers into the result of `Gitlab::AiGateway.headers`.

#### Permission checks

Permission checks in GitLab Rails are not mandatory but serve as an early gate to improve user experience by rejecting requests before they reach the **AI gateway**.
**AI gateway** will enforce all necessary authorization regardless of these frontend checks.

These optional checks can be useful for:

- Providing immediate feedback to users about feature availability
- Reducing unnecessary network requests to backend services
- Improving overall application performance and perceived performance

Implementation approaches:

- **For experimental/free features**: If the feature has free access, this usually means that the experimental features are subject to the [Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
  - For GitLab Duo features, the customer needs to enable [experimental toggle](../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) in order to use experimental features for free.

- **For paid features on GitLab.com and GitLab Self-Managed**: Check if the user is entitled to use the feature before making the backend request.

```ruby
# For provided user, it will check if user is entitled to use the feature.
current_user.allowed_to_use?(:new_feature)
```

#### Example

The following example is for a request to the service called `:new_feature`.

Add a new policy rule in [ee/global_policy.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/policies/ee/global_policy.rb):

```ruby
  condition(:new_feature_licensed) do
    next true if ::Gitlab::Saas.feature_available?(:new_feature_on_saas)
    ::License.feature_available?(:new_feature)
  end

  condition(:user_allowed_to_use_new_feature) do
    @user.allowed_to_use?(:new_feature)
  end

  rule { new_feature_licensed & user_allowed_to_use_new_feature }.enable :access_new_feature
```

Send the request

```ruby
# Check if the feature is available for the given user based on seat assignment, add-on purchases
return unauthorized! unless current_user.can?(:access_new_feature)

Gitlab::HTTP.post(
  "#{ai_gateway_base_url}#{feature_endpoint}",
  headers: Gitlab::AiGateway.headers(user: user, unit_primitive_name: :new_feature, ai_feature_name: <CORRESPONDING ENTRY FROM AiFeaturesCatalogue>),
  body: <REQUEST BODY>,
)
```

### Implement authorization checks in backend service

GitLab Rails calls the **backend service** (**AI gateway**) to deliver functionality that would otherwise be unavailable to GitLab Self-Managed and
Dedicated instances. For GitLab Rails to be able to call this, there has to be an endpoint exposed.
The backend service must verify each JWT sent by GitLab Rails in the Authorization header.

For more information and examples on the **AI gateway** authorization process, check the [Authorization in AI gateway documentation](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/auth.md?ref_type=heads#authorization-in-ai-gateway).

## Testing

An example for how to set up an end-to-end integration with the **AI gateway** as the backend service
can be found in [install AI gateway](_index.md#install-ai-gateway).

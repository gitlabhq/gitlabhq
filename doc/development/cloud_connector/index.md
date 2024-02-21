---
stage: Systems
group: Cloud Connector
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Cloud Connector

[GitLab Cloud Connector](https://about.gitlab.com/direction/cloud-connector) is a way to access services common to
multiple GitLab deployments, instances, and cells. As of now, Cloud Connector is not a
dedicated service itself, but rather a collection of APIs and code that standardizes the approach to authentication and
other items when integrating Cloud based services with the GitLab instance. This page aims to explain how to use
Cloud Connector to link GitLab Rails to a service.

See the [architecture page](architecture.md) for more information about Cloud Connector. Also see [terms](architecture.md#terms)
for a list of terms used throughout the document.

## Tutorial: Connect a feature using Cloud Connector

A GitLab Rails instance accesses backend services by means of a Cloud Connector Service Access Token.
This is a token provided by the GitLab Rails application and holds information about which backend services and features in these services it can access.

To connect a feature using Cloud Connector:

1. [Complete the steps in GitLab Rails](#gitlab-rails)
1. [Complete the steps in CustomersDot](#customersdot)
1. [Complete the steps in the backend service](#backend-service)

### Connect a feature to an existing service

#### GitLab Rails

1. Ensure your request sends the required headers to the [backend service](#backend-service).

   These headers are:

   - `X-Gitlab-Instance-Id`: A globally unique instance ID string.
   - `X-Gitlab-Global-User-Id`: A globally unique anonymous user ID string.
   - `X-Gitlab-Realm`: One of `saas`, `self-managed`.
   - `Authorization`: Contains the Base64-encoded JWT as a `Bearer` token.

   Some of these headers can be injected by merging the result of the `API::Helpers::CloudConnector#cloud_connector_headers`
   method to your payload.

The following example is for a request that includes the `new_feature_scope` scope.
Here we assume your backend service is called `foo` and is already reachable at `https://cloud.gitlab.com/foo`.
We also assume that the backend service exposes the feature using a `/new_feature_endpoint` endpoint.
This allows clients to access the feature at `https://cloud.gitlab.com/foo/new_feature_endpoint`.
Call `CloudConnector::AccessService.access_token` with the list of scopes your feature requires and include
this token in the `Authorization` HTTP header field.
The backend service must validate this token and any scopes it carries when receiving the request.

```ruby
include API::Helpers::CloudConnector

token = ::CloudConnector::AccessService.new.access_token([:new_feature_scope], gitlab_realm)

Gitlab::HTTP.post(
  "https://cloud.gitlab.com/foo/new_feature_endpoint",
  headers: {
      'Authorization' => "Bearer #{token}",
    }.merge(cloud_connector_headers(current_user))
)
```

#### CustomersDot

This step is necessary for your feature to work for Self-Managed and GitLab Dedicated deployments.

CustomersDot is the authority on which instance has which access rights. It stores this information in the instance's
service token.

To add a new feature bound to a scope:

1. Update [`cloud_connector.yml`](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/main/config/cloud_connector.yml)
    by adding the new service under `services`. We start with the feature name, which would be included in the service
    token as a scope.

    <!-- markdownlint-disable proper-names -->

    `service_start_time` is the cut-off date after which payment for this feature is required.

    `min_gitlab_version` is the minimum required GitLab version the instance needs to receive access, before the cut-off date.

    `min_gitlab_version_for_beta` is the minimum required GitLab version the instance needs to receive access, before the cut-off date.

    `bundled_with` is the add-on bundle that is required to gain access to the service.

    <!-- markdownlint-enable proper-names -->

    For example:

    ```yaml
   defaults: &defaults
        services:
            new_feature_scope:
                service_start_time: 2024-02-15 00:00:00 UTC
                min_gitlab_version: '16.8'
                bundled_with: 'duo_pro'
    ```

#### Backend service

GitLab Rails calls a backend service to deliver functionality that would otherwise be unavailable to Self-managed and
Dedicated instances. For GitLab Rails to be able to call this, there has to be an endpoint exposed.
The backend service must verify each JWT sent by GitLab Rails in the Authorization header.

The examples in this section will be based on the [AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)
and the [FastAPI](https://fastapi.tiangolo.com/) framework.

1. Create an endpoint in your service:

   ```python
   @router.post("/new_feature_endpoint")
   async def feature_name(
       request: Request,
       payload: CompletionRequest
   ):
       return Response(
        id="id",
        created=int(time()),
        extra="Feature"
    )
   ```

1. Ensure the endpoint checks whether the caller has the correct scope access:

    ```python
   @router.post("/new_feature_endpoint")
   @requires("new_feature_scope")
   async def feature_name(
   ...
   ```

##### Testing

An example for how to set up an end-to-end integration with the AI gateway as the backend service can be found [here](../ai_features/index.md#setup).

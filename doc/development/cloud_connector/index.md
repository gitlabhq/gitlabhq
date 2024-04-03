---
stage: Systems
group: Cloud Connector
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Cloud Connector

[GitLab Cloud Connector](https://about.gitlab.com/direction/cloud-connector/) is a way to access services common to
multiple GitLab deployments, instances, and cells. As of now, Cloud Connector is not a
dedicated service itself, but rather a collection of APIs and code that standardizes the approach to authentication and
other items when integrating Cloud based services with the GitLab instance. This page aims to explain how to use
Cloud Connector to link GitLab Rails to a service.

See the [architecture page](architecture.md) for more information about Cloud Connector. Also see [terms](architecture.md#terms)
for a list of terms used throughout the document.

## Tutorial: Connect a feature using Cloud Connector

A GitLab Rails instance accesses backend services by means of a Cloud Connector Service Access Token.
This is a token provided by the GitLab Rails application and holds information about which backend services and features in these services it can access.

The following sections cover the necessary steps to expose features both from existing and newly built
backend services through Cloud Connector.

### Connect a feature to an existing service

To connect a feature in an existing backend service to Cloud Connector:

1. [Complete the steps in GitLab Rails](#gitlab-rails)
1. [Complete the steps in CustomersDot](#customersdot)
1. [Complete the steps in the backend service](#backend-service)

#### GitLab Rails

1. Call `CloudConnector::AccessService.new.access_token(scopes: [...])` with the list of scopes your feature requires and include
this token in the `Authorization` HTTP header field.
Note that this can return `nil` if there is no valid token available. If there is no token, the call to Cloud Connector will
not pass authorization, so it is recommended to return early.
The backend service must validate this token and any scopes it carries when receiving the request.
If you need to embed additional claims in the token specific to your use case, you can pass these
in the `extra_claims` argument. **Scopes and other claims passed here will only be included in self-issued tokens on GitLab.com.**
Refer to [CustomersDot](#customersdot) to see how custom claims are handled for self-managed instances.
1. Ensure your request sends the required headers to the [backend service](#backend-service).

   These headers are:

   - `X-Gitlab-Instance-Id`: A globally unique instance ID string.
   - `X-Gitlab-Global-User-Id`: A globally unique anonymous user ID string.
   - `X-Gitlab-Realm`: One of `saas`, `self-managed`.
   - `Authorization`: Contains the Base64-encoded JWT as a `Bearer` token obtained from the `access_token` method in step 1.

   Some of these headers can be injected by merging the result of the `API::Helpers::CloudConnector#cloud_connector_headers`
   method to your payload.

The following example is for a request that includes the `new_feature_scope` scope.
Here we assume your backend service is called `foo` and is already reachable at `https://cloud.gitlab.com/foo`.
We also assume that the backend service exposes the feature using a `/new_feature_endpoint` endpoint.
This allows clients to access the feature at `https://cloud.gitlab.com/foo/new_feature_endpoint`.

Here, the parameters you pass to `access_token` have the following meaning:

- `audience`: The name of the backend service. The token is bound to this backend
  using the JWT `aud` claim.
- `scopes`: The list of access scopes carried in this token. They should map to access points
  in your backend, which could be HTTP endpoints or RPC calls.

```ruby
include API::Helpers::CloudConnector

token = ::CloudConnector::AccessService.new.access_token(
  audience: 'foo',
  scopes: [:new_feature_scope]
)
return unauthorized! if token.nil?

Gitlab::HTTP.post(
  "https://cloud.gitlab.com/foo/new_feature_endpoint",
  headers: {
      'Authorization' => "Bearer #{token}",
    }.merge(cloud_connector_headers(current_user))
)
```

NOTE:
Any arguments you pass to `access_token` that configure the token returned only take hold for
tokens issued on GitLab.com. For self-managed GitLab instances the token is read as-is from
the database and never modified.

#### CustomersDot

This step is necessary for your feature to work for Self-Managed and GitLab Dedicated deployments.

CustomersDot is the authority on which instance has which access rights. It stores this information in the instance's
service token.

To add a new feature bound to a scope:

1. Update [`cloud_connector.yml`](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/main/config/cloud_connector.yml)
    by adding the new service under `services`. We start with the feature name, which would be included in the service
    token as a scope.

    <!-- markdownlint-disable proper-names -->
    `backend` is the targeted backend service and will become the token audience.

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

1. **Optional:** If the backend service the token is used for requires additional claims to be embedded in the
   service access token, contact [#g_cloud_connector](https://gitlab.enterprise.slack.com/archives/CGN8BUCKC) (Slack, internal only)
   since we do not currently have interfaces in place to self-service this.

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

### Connect a new backend service to Cloud Connector

To integrate a new backend service that isn't already accessible by Cloud Connector features:

1. [Set up JWT validation](#set-up-jwt-validation).
1. [Make it available at `cloud.gitlab.com`](#add-a-new-cloud-connector-route).

#### Set up JWT validation

As mentioned in the [backend service section](#backend-service) for services that already use
Cloud Connector, each service must verify that the JWT sent by a GitLab instance is legitimate.

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
1. The `scopes` claim covers the functionality exposed by the requested endpoint (see [Backend service](#backend-service)).

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

An example for how to set up an end-to-end integration with the AI gateway as the backend service can be found [here](../ai_features/index.md#local-setup).

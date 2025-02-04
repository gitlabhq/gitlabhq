---
stage: Systems
group: Cloud Connector
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: 'Cloud Connector: Architecture'
---

[GitLab Cloud Connector](https://about.gitlab.com/direction/cloud-connector/) is a way to access services common to
multiple GitLab deployments, instances, and cells. As of now, Cloud Connector is not a
dedicated service itself, but rather a collection of APIs and code that standardizes the approach to authentication and
other items when integrating Cloud based services with a GitLab instance.

This page covers the general architecture of Cloud Connector and is meant to be read as a supplemental
resource to the main developer documentation.

## Terms

When talking about Cloud Connector's constituents and mechanics, we use the following
terms:

- **GitLab Rails:** The main GitLab application.
- **GitLab.com:** The multi-tenant GitLab SaaS deployment operated by GitLab Inc.
- **Dedicated:** A single-tenant GitLab SaaS deployment operated by GitLab Inc.
- **Self-managed:** Any GitLab instance operated by a customer, potentially deployed to a private cloud.
- **GitLab instance:** Any of the above.
- **Backend service:** A GitLab-operated web service invoked by a GitLab instance to deliver functionality
  that's part of the Cloud Connector set of features. The AI gateway is one example.
- **CustomersDot:** The [GitLab Customers Portal](https://gitlab.com/gitlab-org/customers-gitlab-com),
  used by customers to manage their GitLab subscriptions.
- **OIDC:** [OpenID Connect](https://auth0.com/docs/authenticate/protocols/openid-connect-protocol),
  an open standard for implementing identity providers and authN/authZ. JWT
  issuers provide OIDC compliant discovery endpoints to publish keys for JWT validators.
- **JWT:** [JSON Web Token](https://auth0.com/docs/secure/tokens/json-web-tokens), an open standard to encode and transmit identity data in the form of a
  cryptographically signed token. This token is used to authorize requests between a GitLab instance or user and a
  backend service. It can be scoped to either a GitLab instance or a user.
- **JWT issuer:** A GitLab-operated web service providing endpoints to issue JWTs. The OAuth specification refers to this as an `Authorization Server`.
  and/or endpoints to provide the public keys necessary to validate such a token.
  GitLab.com, CustomersDot and AI gateway are all JWT issuers.
- **JWT validator:** A backend service that validates GitLab instance requests carrying a JWT. The OAuth specification refers to this as a `Resource Server`.
  using public keys obtained from a JWT issuer. The AI gateway is one example of a JWT validator.
- **IJWT:** An Instance JSON Web Token, a JWT created for a GitLab instance.
- **UJWT:** A User JSON Web Token, a JWT created for a GitLab user with a shorter lifespan and less permissions than a IJWT.
- **JWKS:** [JSON Web Key Set](https://auth0.com/docs/secure/tokens/json-web-tokens/json-web-key-sets),
  an open standard to encode cryptographic keys to validate JWTs.
- **Unit primitives:** The logical feature that a permission/access scope can govern.
- **Add-On** The group of unit primitives that are bundled and sold together.
  Example: `code_suggestions` and `duo_chat` are 2 UPs sold together under the `DUO_PRO` add-on.

## Problem to solve

Most GitLab features can be delivered directly from a GitLab instance, regardless of where it is deployed.
Some features, however, require 3rd party vendor integration or are difficult to operate outside of the
GitLab.com. This presents self-managed and Dedicated customers with a problem since they are not easily
able to access those features.

Cloud Connector solves this problem by:

- Moving functionality out of GitLab Rails and into GitLab-operated services to save customers
  the hassle of manually configuring and operating them.
- Providing a single global entry point into Cloud Connector features at `cloud.gitlab.com` to
  access backend services.
- Connects instance license and billing data to access grants,
  enabling a GitLab instance to consume features hosted in backend services operated by GitLab Inc.

## Cloud Connector components

Technically, Cloud Connector consists of the following pieces:

1. **A global load-balancer.** Hosted at `cloud.gitlab.com` through Cloudflare, all traffic inbound
   to Cloud Connector features such as AI must go through this host. The load balancer makes
   routing decisions based on path prefixes. For example:
   1. Load balancer maps `/prefix` to a backend service.
   1. Client requests `cloud.gitlab.com/prefix/path`.
   1. Load balancer strips out `/prefix` and routes `/path` to the backend service.
1. **Electing GitLab.com and CustomersDot as IJWT issuers.** We configure these
   deployments with private keys only GitLab Inc. has access to. We use these keys to issue cryptographically
   signed IJWT a GitLab Rails instance can use to make requests upstream to a connected service
   backend. The public validation keys are published using OIDC discovery API endpoints.
1. **Electing AI gateway as a UJWT issuer and validator.** Similar to the above mentioned IJWT issuers,
   except with the purpose of issuing tokens for users only. The AI gateway is its own validator, so the validation
   keys are not published on OIDC discovery API endpoints.
1. **Electing backend services as IJWT validators.** Backend services synchronize regularly
   with GitLab.com or CustomersDot to obtain the public keys used to validate the signature of a service
   token attached to a request. The backend service can then decide whether to accept or reject the
   request, based on both signature validity and any claims the token may carry in its body.
1. **Programming APIs to integrate with the above.** We aim to provide the necessary interfaces in
   Ruby to make it easier to implement communication between the GitLab Rails application
   and a backend service. This is a moving target and we file issues into the
   [Cloud Connector abstractions epic](https://gitlab.com/groups/gitlab-org/-/epics/12376) to improve this.

The following diagram outlines how these components interact:

```plantuml
@startuml

node "Cloudflare" {
  [cloud.gitlab.com] as LB #yellow
}

node "GitLab SaaS" {
  package "Backend service deployments" as BACK {
    [Backend 1] as BE1
    [Backend 2] as BE2
  }

  package "OIDC providers" as OIDC {
    [GitLab.com] as DOTCOM
    [Customers Portal] as CDOT
  }

  package "GitLab Dedicated" as DED {
     [GitLab instance 1]
     [GitLab instance 2]
  }
}

node "Customer deployments" {
  [GitLab instance] as SM
}

BACK -down-> OIDC : "OIDC discovery"

DOTCOM -right-> LB : "request /prefix"
LB -left-> BACK: " route /prefix to backend"

SM -up-> LB : " request /prefix"
SM <-up-> CDOT : "sync access data"
DED <-up-> CDOT : "sync access data"

@enduml
```

## Access control

There are two levels of access control when making requests into backend services:

1. **Instance access.** Granting a particular SM/Dedicated instance access is done by issuing a IJWT bound
   to a customer's cloud license billing status. This token is synced to a GitLab instance from CustomersDot
   daily and stored in the instance's local database. For GitLab.com, we do not require this step; instead,
   we issue short-lived tokens for each request. These tokens are implemented as JWTs and are
   cryptographically signed by the issuer.
1. **User access.** We currently expect all end-user requests to go through the respective GitLab instance
   first at least once. For certain requests (e.g. code completions) we allow users to make requests to
   a backend service directly using a backend-scoped UJWT.
   This token has a more limited lifespan and access than an instance token. To get a user token
   the user will first have to go through the respective GitLab instance to request the token.
   Therefore, user-level authentication and authorization is handled as with any REST or GraphQL API request, that is,
   either using OAuth or personal access tokens.

The JWT issued for instance access carries the following claims (not exhaustive, subject to change):

- `aud`: The audience. This is the name of the backend service (for example, `gitlab-ai-gateway`).
- `sub`: The subject. This is the UUID of the GitLab instance the token was issued for (e.g.: `8f6e4253-58ce-42b9-869c-97f5c2287ad2`).
- `iss`: The issuer URL. Either `https://gitlab.com` or `https://customers.gitlab.com`.
- `exp`: The expiration time of the token (UNIX timestamp). Currently 1 hour for GitLab.com and 3 days
  for SM/Dedicated.
- `nbf`: The time this token can not be used before (UNIX timestamp), this is set to 5 seconds before the time the token was issued.
- `iat`: The time this token was issued at (UNIX timestamp), this is set to the time the token was issued.
- `jti`: The JWT ID, set to a randomly created UUID (e.g.: `0099dd6c-b66e-4787-8ae2-c451d86025ae`).
- `gitlab_realm`: A string to differentiate between requests from self-managed and GitLab.com.
  This is `self-managed` when issued by the Customers Portal and `saas` when issued by GitLab.com.
- `scopes`: A list of access scopes that define which features this token is valid for. We obtain these
  based on decisions such as how paid features are bundled into GitLab tiers and add-ons.

The JWT issues for user access carries the following claims (not exhaustive, subject to change):

- `aud`: The audience. This is the name of the backend service (`gitlab-ai-gateway`).
- `sub`: The subject. This is a globally unique anonymous user ID hash of the GitLab user the token was issued for (e.g.: `W2HPShrOch8RMah8ZWsjrXtAXo+stqKsNX0exQ1rsQQ=`).
- `iss`: The issuer (`gitlab-ai-gateway`).
- `exp`: The expiration time of the token (UNIX timestamp). Currently 1 hour after the issued at time.
- `nbf`: The time this token can not be used before (UNIX timestamp), this is set to the time the token was issued.
- `iat`: The time this token was issued at (UNIX timestamp), this is set to the time the token was issued.
- `jti`: The JWT ID, set to a randomly created UUID (e.g.: `0099dd6c-b66e-4787-8ae2-c451d86025ae`).
- `gitlab_realm`: A string to differentiate between requests from self-managed and GitLab.com. Either `self-managed` or `saas`.
- `scopes`: A list of access scopes that define which features this token is valid for. We obtain these
  based on decisions such as how paid features are bundled into GitLab tiers and add-ons as well as what features
  are allowed to be accessed with a user token.

A JWKS contains the public keys used by token validators to verify a token's signature. All backend
services are currently required to:

- Regularly refresh the JWKS from GitLab.com and CustomersDot so key rotation can happen easily and regularly
  without service disruption.
- Perform signature verification of JWTs and access scope checks for each request.

The following flow charts should help to understand what happens when a user consumes a Cloud Connector feature,
such as talking to an AI chat bot, for both GitLab.com and Dedicated/self-managed deployments.

### GitLab.com

Because the GitLab.com deployment enjoys special trust, it has the advantage of being able to self-sign
and create IJWTs for every request to a Cloud Connector feature, which greatly simplifies the
flow:

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant GL as GitLab.com
    participant SB as Backend service

    Note over U,SB: End-user flow
    U->>GL: Authorize with GitLab instance
    GL-->>U: PAT or Cookie
    U->>GL: Use Cloud Connector feature
    GL->>GL: Perform authN/authZ with Cookie or PAT
    GL->>GL: Verify user allowed to use feature
    GL->>GL: Create signed IJWT
    GL->>SB: Request feature with IJWT
    SB->>GL: Fetch public signing keys, if needed
    GL-->>SB: JWKS
    SB->>SB: Validate IJWT with keys
    SB-->>GL: Feature payload
```

### GitLab Dedicated/Self-Managed

For Dedicated and self-managed instances the key problem is one of trust delegation:
we cannot trust any individual self-managed instance and let them issue tokens, but
we can delegate trust by letting an instance regularly authorize itself with CustomersDot,
which is controlled by GitLab Inc. While we do control GitLab Dedicated instances, for simplicity
we currently consider them "self-managed" from a Cloud Connector standpoint.

The main difference to GitLab.com is the addition of the CustomersDot actor, with which customer instances
synchronize regularly to fetch and persist data necessary to access GitLab backend services.

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant GL as SM/Dedicated GitLab
    participant CD as CustomersDot
    participant SB as Backend service

    Note over GL,CD: Background: synchronize access data
    loop cron job
        GL->>CD: Send license key
        CD->>CD: Verify customer subscription with license key
        CD->>CD: Create and sign IJWT
        CD-->>GL: Cloud Connector access data + IJWT
        GL->>GL: Store access data + IJWT in DB
    end
    Note over U,SB: End-user flow
    U->>GL: Authorize with GitLab instance
    GL-->>U: PAT or Cookie
    U->>GL: Use Cloud Connector feature
    GL->>GL: Perform authN/authZ with Cookie or PAT
    GL->>GL: Verify user allowed to use feature
    GL->>GL: Load IJWT from DB
    GL->>SB: Request feature with IJWT
    SB->>CD: Fetch public signing keys, if needed
    CD-->>SB: JWKS
    SB->>SB: Validate IJWT with keys
    SB-->>GL: Feature payload
```

Cloud Connector access data is structured JSON data that is stored in the instance's local database.
On top of the IJWT, it contains additional information about the services made available
such as whether the service is considered fully launched or in beta stage. This information is particularly
useful for self-managed instances whose upgrade cadence we do not control, because it allows us to
sync in data that are subject to change and control access to some GitLab features remotely.

### AI gateway

AI gateway is able to issue UJWTs which are meant for users to directly communicate with the AI gateway,
that is not having to make a call to a GitLab instance first. This is in addition to using a IJWT.
Only GitLab instances can request a UJWT, which is done by making a request with the IJWT.
AI gateway will then return a short-lived UJWT that the instance can pass over to the user.
The client can use this UJWT to directly communicate with the AI gateway.

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant GL as SM/Dedicated GitLab or GitLab.com
    participant AIGW as AI gateway

    U->>GL: Authorize with GitLab instance
    GL-->>U: PAT or Cookie

    loop Initial request, this will be done hourly, only when the UJWT is expired.
        U->>GL: Request UJWT
        GL->>GL: Perform authN/authZ with Cookie or PAT
        GL->>GL: Verify user allowed to use feature
        Note over GL: Step 6 differs between SM/Dedicated GitLab and GitLab.com
        GL->>GL: SM/Dedicated GitLab: Load IJWT from DB<br/>GitLab.com: Create signed IJWT
        GL->>AIGW: Request UJWT with IJWT
        AIGW->>AIGW: Validate IJWT with keys
        AIGW->>AIGW: Create UJWT
        AIGW-->>GL: UJWT
        GL-->>U: UJWT
    end
    U->>AIGW: Request feature with UJWT
    AIGW->>U: Feature payload
```

## References

- [Cloud Connector design documents and ADRs](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cloud_connector/)

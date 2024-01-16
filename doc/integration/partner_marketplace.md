---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Marketplace partners

GitLab supports automation for selected distribution marketplaces to process sales of GitLab products to authorized
channel partners. Marketplace partners can use the GitLab Marketplace APIs to integrate their systems with GitLab to
sell GitLab subscriptions on their site.

This document's target audience is third-party developers for Marketplace partners.

## How the Marketplace APIs work

The Marketplace APIs are hosted in the [Customers Portal](https://customers.gitlab.com/). The Customers Portal allows
individual customers to purchase and manage GitLab subscriptions and supports APIs for partners
to make sales on behalf of their customers. The Customers Portal integrates with other GitLab services, including
Zuora and Salesforce, to provide a task-oriented interface for users.

The following example shows a typical purchase flow of request and response between the following components:

- Customer
- Marketplace partner system
- Customers Portal
- Zuora
- Salesforce

```mermaid
sequenceDiagram
    participant Customer
    participant Marketplace partner system
    participant Customers Portal
    participant Zuora
    participant Salesforce
    Customer ->> Marketplace partner system: Place order to purchase GitLab subscription
    Marketplace partner system ->> Customers Portal: Get OAuth token
    Customers Portal ->> Marketplace partner system: Access token
    Marketplace partner system ->> Customers Portal: Place order
    Customers Portal ->> Zuora: Create Zuora subscription
    Customers Portal ->> Salesforce: Create Salesforce objects
    Zuora ->> Customers Portal: Success response with Zuora subscription data
    Customers Portal ->> Marketplace partner system: Success response with order ID
    Zuora ->> Customers Portal: Zuora callout event
    Customers Portal ->> Customer: send license notification
    Marketplace partner system ->> Customers Portal: Poll order status
    Customers Portal ->> Marketplace partner system: Success response with order status
```

## Marketplace API Specification

OpenAPI specs for the Marketplace APIs are available at [Marketplace interactive API documentation](https://customers.staging.gitlab.com/openapi_docs/marketplace).

## Access the Marketplace API

To access the Marketplace API you need to:

- Request access from GitLab.
- Retrieve an OAuth access token.

Marketplace API endpoints are secured with [OAuth 2.0](https://oauth.net/2/). OAuth is an authorization framework
that grants 3rd party or client applications, like a Marketplace partner application, limited access to resources on an
HTTP service, like the Customers Portal.

OAuth 2.0 uses _grant types_ (or _flows_) that describe how a client application gets authorization in
the form of an _access token_. An access token is a string that the client application uses to make authorized requests to
the resource server.

The Marketplace API uses the `client_credentials` grant type. The client application uses the access token to access its
own resources, instead of accessing resources on behalf of a user.

### Step 1: Request access

Before you can use the Marketplace API, you must contact your Marketplace partner Manager or email [`partnerorderops`](mailto:partnerorderops@gitlab.com)
to request access. After you request access, GitLab configures the following accounts and credentials for you:

1. Client credentials. Marketplace APIs are secured with OAuth 2.0. The client credentials include the client ID and client secret
   that you need to retrieve the OAuth access token.
1. Invoice owner account in Zuora system. Required for invoice processing.
1. Distributor account in Salesforce system.
1. Trading partner account in Salesforce system. GitLab adds the Trading Partner ID to a permitted list to pass the validations.

### Step 2: Retrieve an access token

To retrieve an access token,

- Make a POST request to the [`/oauth/token`](https://customers.staging.gitlab.com/openapi_docs/marketplace#/marketplace/post_oauth_token) endpoint with the following required parameters:

| Parameter       | Type   | Required |Description                                                                                                                         |
|-----------------|--------|----------|------------------------------------------------------------------------------------------------------------------------------------|
| `client_id`     | string | yes      |ID of your client application record on the Customers Portal. Received from GitLab.                                                 |
| `client_secret` | string | yes      |Secret of your client application record on the Customers Portal. Received from GitLab.                                             |
| `grant_type`    | string | yes      |Specifies the type of credential flow. Use `client_credentials`.                                                                    |
| `scope`         | string | yes      |Specifies the level of access. Use `marketplace.order:read` for read-only access. Use `marketplace.order:create` for create access. |

If the request is successful, the response body includes the access token that you can use in subsequent requests. For an example of a successful
response, see the [Marketplace interactive API documentation](https://customers.staging.gitlab.com/openapi_docs/marketplace)

If the request is unsuccessful, the response body includes an error and error description. The errors can be:

| Status | Description                                                                                                                                  |
|--------|----------------------------------------------------------------------------------------------------------------------------------------------|
| 400    | Invalid scope. Ensure the `scope` is `marketplace.order:read` or `marketplace.order:create`.                                                 |
| 401    | Invalid client. Ensure that there are no typos or extra spaces on the client specific credentials. Incorrect `client_id` or `client_secret`  |

### Step 3: Use the access token

To use the access token from a client application:

1. Set the `Authorization` header of the request to `Bearer <your_access_token>`.
1. Set parameters or data needed for the endpoint and send the request.

Example request:

```shell
curl \
  --url "https://customers.staging.gitlab.com/api/v1/marketplace/subscriptions/:external_subscription_id" \
  --header "Authorization: Bearer NHb_VhZhPOnBTSNfBSzmCmt28lLDWb2xtwr_c3DL148"
```

## Create a new customer subscription

To create a new customer subscription from a Marketplace partner client application,

- Make an authorized POST request to the
  [`/api/v1/marketplace/subscriptions`](https://customers.staging.gitlab.com/openapi_docs/marketplace#/marketplace/post_api_v1_marketplace_subscriptions)
  endpoint in the Customers Portal with the following parameters in JSON format:

| Parameter                | Type   | Required | Description                                                                                                                                          |
|--------------------------|--------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| `externalSubscriptionId` | string | yes      | ID of the subscription on the Marketplace partner system.                                                                                            |
| `tradingPartnerId`       | string | yes      | ID of the Trading Partner account in Salesforce. Received from GitLab.                                                                               |
| `customer`               | object | yes      | Information about the customer. Must include company name. Contact must include `firstName`, `lastName` and `email`. Address must include `country`. |
| `orderLines`             | array  | yes      | Specifies the product purchased. Must include `quantity` and `productId`.                                                                            |

If the request is successful, the response body includes the newly created subscription number. For an example of a full request body,
see the [Marketplace interactive API documentation](https://customers.staging.gitlab.com/openapi_docs/marketplace).

If the subscription creation is unsuccessful, the response body includes an error message with details about the cause of the error.

## Check the status of a subscription

To get the status of a given subscription,

- Make an authorized GET request to the
  [`/api/v1/marketplace/subscriptions/{external_subscription_id}`](https://customers.staging.gitlab.com/openapi_docs/marketplace#/marketplace/get_api_v1_marketplace_subscriptions__external_subscription_id_)
  endpoint in the Customers Portal.

The request must include the Marketplace partner system ID of the subscription to fetch the status for.

If the request is successful, the response body contains the status of the subscription provision. The status can be:

- Creating
- Created
- Failed
- Provisioned

If the subscription cannot be found using the passed `external_subscription_id`, the response has
a 404 Not Found status.

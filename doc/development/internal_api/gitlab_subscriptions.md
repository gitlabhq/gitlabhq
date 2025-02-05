---
stage: Fulfillment
group: Provision
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: GitLab Subscriptions Internal API
---

The GitLab Subscriptions internal API is used by the CustomersDot application,
it cannot be used by other consumers. This documentation is intended for people
working on the GitLab and CustomersDot codebases.

## Add new endpoints

API endpoints should be externally accessible by default, with proper authentication and authorization.
Before adding a new internal endpoint, consider if the API would benefit the wider GitLab community and
can be made externally accessible.

For the GitLab Subscription portal, we might chose to use an internal API when we need to make updates
to GitLab without the context of a user. This means we don't have access to a user's access token, and
instead make updates as the CustomersDot application in general.

## Authentication

### CustomersDot JWT

These endpoints are all authenticated using JWT authentication from CustomersDot.

To authenticate using the JWT, clients:

1. Read the contents of the signing key from the credentials.
1. Use the signing key to generate a JSON Web Token (`JWT`).
1. Pass the JWT in the `X-CUSTOMERS-DOT-INTERNAL-TOKEN` header.

### Admin personal access token (PAT)

This authentication method is deprecated as it is not supported in the Cells architecture. It will be
[removed in a future milestone](https://gitlab.com/gitlab-org/gitlab/-/issues/473625). Please use JWT authentication instead.

To authenticate as an administrator, generate a personal access token for an administrator with the
`api` and `admin_mode` scopes. This token can then be supplied in the `PRIVATE-TOKEN` header.

## Internal Endpoints

### Namespaces

#### Fetch group owners

Use a GET command to get direct owners of the namespace. CustomersDot uses this endpoint to find users to notify about
billing events.

```plaintext
GET /internal/gitlab_subscriptions/namespaces/:id/owners
```

Example request:

```shell
curl --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/internal/gitlab_subscriptions/namespaces/1234/owners"
```

Example response:

```json
[
  {
    "user": {
      "id": 1,
      "username": "john_smith",
      "name": "John Smith"
    },
    "access_level": 50,
    "notification_email": "name@example.com"
  }
]
```

#### Fetch a namespace by ID

Used to fetch information about a namespace.

```plaintext
GET /internal/gitlab_subscriptions/namespaces/:id
```

Parameters:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | ID or [URL-encoded path of the namespace](../../api/rest/_index.md#namespaced-paths) |

Example request:

```shell
curl --request GET --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/internal/gitlab_subscriptions/namespaces/1"
```

Example response:

```json
{
  "id": 1,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/group1",
  "members_count_with_descendants": 2,
  "billable_members_count": 2,
  "max_seats_used": 0,
  "seats_in_use": 0,
  "plan": "default",
  "end_date": null,
  "trial_ends_on": null,
  "trial": false,
  "root_repository_size": 100,
  "projects_count": 3
}
```

#### Update a namespace

Use a PUT command to update an existing namespace.

```plaintext
PUT /internal/gitlab_subscriptions/namespaces/:id
```

Parameters:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | ID or [URL-encoded path of the namespace](../../api/rest/_index.md#namespaced-paths) |
| `shared_runners_minutes_limit` | integer | no | Compute minutes quota |
| `extra_shared_runners_minutes_limit` |  integer | no | Extra compute minutes |
| `additional_purchased_storage_size` |  integer | no | Additional storage size |
| `additional_purchased_storage_ends_on` |  date | no | Additional purchased storage Ends on |
| `gitlab_subscription_attributes` |  hash | no |  Hash object containing GitLab Subscription attributes. Accepts `seats`,`max_seats_used`,`plan_code`,`end_date`,`auto_renew`,`trial`,`trial_ends_on`,`trial_starts_on`,`trial_extension_type` |

Example request:

```shell
curl --request PUT --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/internal/gitlab_subscriptions/namespaces/1 --data '{"shared_runners_minutes_limit":1000}'"
```

Example response:

```json
{
  "id": 1,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/group1",
  "members_count_with_descendants": 2,
  "billable_members_count": 2,
  "max_seats_used": 0,
  "seats_in_use": 0,
  "plan": "default",
  "end_date": null,
  "trial_ends_on": null,
  "trial": false,
  "root_repository_size": 100,
  "projects_count": 3
}
```

### Subscriptions

The subscription endpoints are used by
[CustomersDot](https://gitlab.com/gitlab-org/customers-gitlab-com) (`customers.gitlab.com`) to
apply subscriptions (including trials, and add-on purchases) to personal namespaces, or top-level
groups on GitLab.com.

#### Fetch a subscription

Use a GET command to view an existing subscription.

```plaintext
GET /internal/gitlab_subscriptions/namespaces/:id/gitlab_subscription
```

Example request:

```shell
curl --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/internal/gitlab_subscriptions/namespaces/1234/gitlab_subscription"
```

Example response:

```json
{
  "plan": {
    "code": "premium",
    "name": "premium",
    "trial": false,
    "auto_renew": null,
    "upgradable": false,
    "exclude_guests": false
  },
  "usage": {
    "seats_in_subscription": 80,
    "seats_in_use": 82,
    "max_seats_used": 82,
    "seats_owed": 2
  },
  "billing": {
    "subscription_start_date": "2020-07-15",
    "subscription_end_date": "2021-07-15",
    "trial_ends_on": null
  }
}
```

#### Create a subscription

Use a POST command to create a subscription.

```plaintext
POST /internal/gitlab_subscriptions/namespaces/:id/gitlab_subscription
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `start_date` | date   | yes      | Start date of subscription |
| `end_date`  | date    | no       | End date of subscription |
| `plan_code` | string  | no       | Subscription tier code |
| `seats`     | integer | no       | Number of seats in subscription |
| `max_seats_used` | integer | no  | Highest number of billable users in the current subscription term |
| `auto_renew` | boolean | no      | Whether subscription auto-renews on end date |
| `trial`     | boolean | no       | Whether subscription is a trial |
| `trial_starts_on` | date | no    | Start date of trial |
| `trial_ends_on` | date | no      | End date of trial |

Example request:

```shell
curl --request POST --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/internal/gitlab_subscriptions/namespaces/1234/gitlab_subscription?start_date="2020-07-15"&plan="premium"&seats=10"
```

Example response:

```json
{
  "plan": {
    "code":"premium",
    "name":"premium",
    "trial":false,
    "auto_renew":null,
    "upgradable":false
  },
  "usage": {
    "seats_in_subscription":10,
    "seats_in_use":1,
    "max_seats_used":0,
    "seats_owed":0
  },
  "billing": {
    "subscription_start_date":"2020-07-15",
    "subscription_end_date":null,
    "trial_ends_on":null
  }
}
```

#### Update a subscription

Use a PUT command to update an existing subscription.

```plaintext
PUT /internal/gitlab_subscriptions/namespaces/:id/gitlab_subscription
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `start_date` | date   | no       | Start date of subscription |
| `end_date`  | date    | no       | End date of subscription |
| `plan_code` | string  | no       | Subscription tier code |
| `seats`     | integer | no       | Number of seats in subscription |
| `max_seats_used` | integer | no  | Highest number of billable users in the current subscription term |
| `auto_renew` | boolean | no      | Whether subscription auto-renews on end date |
| `trial`     | boolean | no       | Whether subscription is a trial |
| `trial_starts_on` | date | no    | Start date of trial. Required if trial is true. |
| `trial_ends_on` | date | no      | End date of trial |

Example request:

```shell
curl --request PUT --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/internal/gitlab_subscriptions/namespaces/1234/gitlab_subscription?max_seats_used=0"
```

Example response:

```json
{
  "plan": {
    "code":"premium",
    "name":"premium",
    "trial":false,
    "auto_renew":null,
    "upgradable":false
  },
  "usage": {
    "seats_in_subscription":80,
    "seats_in_use":82,
    "max_seats_used":0,
    "seats_owed":2
  },
  "billing": {
    "subscription_start_date":"2020-07-15",
    "subscription_end_date":"2021-07-15",
    "trial_ends_on":null
  }
}
```

### Upcoming Reconciliations

The `upcoming_reconciliations` endpoint is used by [CustomersDot](https://gitlab.com/gitlab-org/customers-gitlab-com) (`customers.gitlab.com`)
to update upcoming reconciliations for namespaces.

#### Update an upcoming reconciliation

```plaintext
PUT /internal/gitlab_subscriptions/namespaces/:namespace_id/upcoming_reconciliations
```

| Attribute                  | Type | Required | Description                                             |
|:---------------------------|:-----|:---------|:--------------------------------------------------------|
| `namespace_id`             | ID   | yes      | ID of the namespace with the upcoming reconciliation    |
| `next_reconciliation_date` | date | yes      | Date the reconciliation will occur on                   |
| `display_alert_from`       | date | yes      | Date to start display the upcoming reconciliation alert |

Example request:

```shell
curl --request PUT --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" --header "Content-Type: application/json" \
     --data '{"upcoming_reconciliations": [{"next_reconciliation_date": "12 Jun 2021", "display_alert_from": "05 Jun 2021"}]}' \
     "https://gitlab.com/api/v4/internal/gitlab_subscriptions/129/upcoming_reconciliations"
```

Example response:

```plaintext
200
```

#### Delete an upcoming reconciliation

Use a DELETE command to delete an `upcoming_reconciliation`.

```plaintext
DELETE /internal/gitlab_subscriptions/namespaces/:namespace_id/upcoming_reconciliations
```

Example request:

```shell
curl --request DELETE \
  --url "http://localhost:3000/api/v4/internal/gitlab_subscriptions/namespaces/22/upcoming_reconciliations" \
  --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>"
```

Example response:

```plaintext
204
```

### Users

#### Retrieve a user

Use a GET command to get the User object based on user ID.

```plaintext
GET /internal/gitlab_subscriptions/users/:id
```

Example request:

```shell
curl --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/internal/gitlab_subscriptions/users/:id"
```

Example response:

```json
{
  "id": 1,
  "username": "john_smith",
  "name": "John Smith",
  "web_url": "http://localhost:3000/john_smith"
}
```

#### Fetch user permissions in a namespace

Use a GET command to fetch the permissions a user has in a namespace.

```plaintext
GET /internal/gitlab_subscriptions/namespaces/:namespace_id/user_permissions/:user_id
```

Example request:

```shell
curl --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/internal/gitlab_subscriptions/namespaces/:namespace_id/user_permissions/:user_id"
```

Example response:

```json
{
  "edit_billing": true
}
```

#### Update credit card validation

Use a PUT command to update the User's credit card validation

```plaintext
PUT /internal/gitlab_subscriptions/users/:user_id/credit_card_validation
```

Example request:

```shell
curl --request PUT --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" \
     --data '{"credit_card_validated_at": "2020-01-01 00:00:00 UTC", "credit_card_expiration_year": "2010", "credit_card_expiration_month": "12", "credit_card_holder_name": "John Smith", "credit_card_type": "American Express", "credit_card_mask_number": "1111", "zuora_payment_method_xid": "abc123", "stripe_setup_intent_xid": "seti_abc123", "stripe_payment_method_xid": "pm_abc123", "stripe_card_fingerprint": "card123"}' \
     "https://gitlab.com/api/v4/internal/gitlab_subscriptions/users/:user_id/credit_card_validation"
```

Example response:

```json
{
  "success": {}
}
```

### Add-On Purchases

This API is used by CustomersDot to manage add-on purchases, excluding Compute Minutes
and Storage packs.

#### Create multiple subscription add-on purchases (Internal)

Use a POST command to create, update, and deprovision multiple subscription add-on purchases. Possible add-on types are `duo_pro`, `duo_enterprise`, and `product_analytics`.

```plaintext
POST /internal/gitlab_subscriptions/namespaces/:id/subscription_add_on_purchases
```

Supported attributes:

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `quantity` | integer | No | Amount of units in the subscription add-on purchase. Must be a non-negative integer. (Example: Number of seats for Duo Pro add-on)  |
| `started_on` | date | Yes | Date the subscription add-on purchase became available |
| `expires_on` | date | Yes | Expiration date of the subscription add-on purchase |
| `purchase_xid` | string | No | Identifier for the subscription add-on purchase (Example: Subscription name for a Code Suggestions add-on) |
| `trial` | boolean | No | Whether the add-on is a trial |

If successful, returns [`201`](../../api/rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute       | Type    | Description |
|:----------------|:--------|:------------|
| `namespace_id`  | integer | Unique identifier for the namespace associated with the purchase |
| `namespace_name`| string  | Name of the namespace linked to the purchase |
| `add_on`        | integer | Type of add-on related to the purchase. Possible add-on types are `Code Suggestions` alias Duo Pro, `Duo Enterprise` and `Product Analytics`  |
| `quantity`      | integer | Number of units purchased for the subscription add-on |
| `started_on`    | date    | Date the subscription add-on became active |
| `expires_on`    | date    | Date the subscription add-on will expire |
| `purchase_xid`  | string  | Unique identifier for the subscription add-on purchase |
| `trial`         | boolean | Indicates whether the add-on is part of a trial |

Example request for create/update:

```shell
curl --request POST \
--header --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" \
--header "Content-Type: application/json" \
--data '{ "add_on_purchases": { "duo_pro": [{ "quantity": 1, "started_on": "<YYYY-MM-DD>", "expires_on": "<YYYY-MM-DD>", "purchase_xid": "C-00123456", "trial": false }] } }' \
"https://gitlab.com/api/v4/internal/gitlab_subscriptions/namespaces/1234/subscription_add_on_purchases"
```

Example request for deprovision:

```shell
curl --request POST \
--header --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" \
--header "Content-Type: application/json" \
--data '{ "add_on_purchases": { "duo_pro": [{ "started_on": "<YYYY-MM-DD>", "expires_on": "<YYYY-MM-DD>" }] } }' \
"https://gitlab.com/api/v4/internal/gitlab_subscriptions/namespaces/1234/subscription_add_on_purchases"
```

The dates should reflect the day prior to the request (that is, yesterday).

Example response:

```json
[
  {
    "namespace_id": 1234,
    "namespace_name": "namespace-name",
    "add_on": "Code Suggestions",
    "quantity": 1,
    "started_on": "2024-01-01",
    "expires_on": "2024-12-31",
    "purchase_xid": "C-00123456",
    "trial": false
  }
]
```

#### Fetch a subscription add-on purchases

Use a GET command to view an existing subscription add-on purchase.

```plaintext
GET /internal/gitlab_subscriptions/namespaces/:id/subscription_add_on_purchases/:add_on_name
```

Example request:

```shell
curl --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/internal/gitlab_subscriptions/namespaces/1234/subscription_add_on_purchases/code_suggestions"
```

Example response:

```json
{
  "namespace_id":1234,
  "namespace_name":"A Namespace Name",
  "add_on":"Code Suggestions",
  "quantity":15,
  "started_on":"2024-06-15",
  "expires_on":"2024-07-15",
  "purchase_xid":"C-00123456",
  "trial":true
}
```

### Compute Minutes provisioning

The compute minutes endpoints are used by [CustomersDot](https://gitlab.com/gitlab-org/customers-gitlab-com) (`customers.gitlab.com`)
to apply additional packs of compute minutes, for personal namespaces or top-level groups in GitLab.com.

#### Create an additional pack

Use a POST command to create additional packs.

```plaintext
POST /internal/gitlab_subscriptions/namespaces/:id/minutes
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `packs`     | array   | yes      | An array of purchased compute packs |
| `packs[expires_at]` | date   | yes      | Expiry date of the purchased pack|
| `packs[number_of_minutes]`  | integer    | yes       | Number of additional compute minutes |
| `packs[purchase_xid]` | string  | yes       | The unique ID of the purchase |

Example request:

```shell
curl --request POST \
  --url "http://localhost:3000/api/v4/internal/gitlab_subscriptions/namespaces/123/minutes" \
  --header 'Content-Type: application/json' \
  --header 'X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>' \
  --data '{
    "packs": [
      {
        "number_of_minutes": 10000,
        "expires_at": "2022-01-01",
        "purchase_xid": "C-00123456"
      }
    ]
  }'
```

Example response:

```json
[
  {
    "namespace_id": 123,
    "expires_at": "2022-01-01",
    "number_of_minutes": 10000,
    "purchase_xid": "C-00123456"
  }
]
```

#### Move additional packs

Use a `PATCH` command to move additional packs from one namespace to another.

```plaintext
PATCH /internal/gitlab_subscriptions/namespaces/:id/minutes/move/:target_id
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `id` | string | yes | The ID of the namespace to transfer packs from |
| `target_id`  | string | yes | The ID of the target namespace to transfer the packs to |

Example request:

```shell
curl --request PATCH \
  --url "http://localhost:3000/api/v4/internal/gitlab_subscriptions/namespaces/123/minutes/move/321" \
  --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>"
```

Example response:

```json
{
  "message": "202 Accepted"
}
```

## Deprecated Endpoints

These endpoints have been [migrated to internal endpoints](https://gitlab.com/gitlab-org/gitlab/-/issues/463741). Now, they are
deprecated and will be [removed in a future milestone](https://gitlab.com/gitlab-org/gitlab/-/issues/473625).

### Add-On Purchases (deprecated)

This API is used by CustomersDot to manage add-on purchases, excluding Compute Minutes
and Storage packs.

#### Create a subscription add-on purchase (deprecated)

Use a POST command to create a subscription add-on purchase.

```plaintext
POST /namespaces/:id/subscription_add_on_purchase/:add_on_name
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `quantity` | integer | yes | Amount of units in the subscription add-on purchase (Example: Number of seats for a Code Suggestions add-on) |
| `started_on` | date | yes | Date the subscription add-on purchase became available |
| `expires_on` | date | yes | Expiration date of the subscription add-on purchase |
| `purchase_xid` | string | yes | Identifier for the subscription add-on purchase (Example: Subscription name for a Code Suggestions add-on) |
| `trial` | boolean | no | Whether the add-on is a trial |

Example request:

```shell
curl --request POST --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/namespaces/1234/subscription_add_on_purchase/code_suggestions?&quantity=10&started_on="2024-06-15"&expires_on="2024-07-15"&purchase_xid="C-00123456"&trial=true"
```

Example response:

```json
{
  "namespace_id":1234,
  "namespace_name":"A Namespace Name",
  "add_on":"Code Suggestions",
  "quantity":10,
  "started_on":"2024-06-15",
  "expires_on":"2024-07-15",
  "purchase_xid":"C-00123456",
  "trial":true
}
```

#### Update a subscription add-on purchase (deprecated)

Use a PUT command to update an existing subscription add-on purchase.

```plaintext
PUT /namespaces/:id/subscription_add_on_purchase/:add_on_name
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `quantity` | integer | no | Amount of units in the subscription add-on purchase (Example: Number of seats for a Code Suggestions add-on) |
| `started_on` | date | yes | Date the subscription add-on purchase became available |
| `expires_on` | date | yes | Expiration date of the subscription add-on purchase |
| `purchase_xid` | string | no | Identifier for the subscription add-on purchase (Example: Subscription name for a Code Suggestions add-on) |
| `trial` | boolean | no | Whether the add-on is a trial |

Example request:

```shell
curl --request PUT --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/namespaces/1234/subscription_add_on_purchase/code_suggestions?&quantity=15&started_on="2024-06-15"&expires_on="2024-07-15"&purchase_xid="C-00123456"&trial=true"
```

Example response:

```json
{
  "namespace_id":1234,
  "namespace_name":"A Namespace Name",
  "add_on":"Code Suggestions",
  "quantity":15,
  "started_on":"2024-06-15",
  "expires_on":"2024-07-15",
  "purchase_xid":"C-00123456",
  "trial":true
}
```

#### Fetch a subscription add-on purchases (deprecated)

Use a GET command to view an existing subscription add-on purchase.

```plaintext
GET /namespaces/:id/subscription_add_on_purchase/:add_on_name
```

Example request:

```shell
curl --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/namespaces/1234/subscription_add_on_purchase/code_suggestions"
```

Example response:

```json
{
  "namespace_id":1234,
  "namespace_name":"A Namespace Name",
  "add_on":"Code Suggestions",
  "quantity":15,
  "started_on":"2024-06-15",
  "expires_on":"2024-07-15",
  "purchase_xid":"C-00123456",
  "trial":true
}
```

### Compute quota provisioning (deprecated)

> - [Renamed](https://gitlab.com/groups/gitlab-com/-/epics/2150) from "CI/CD minutes" to "compute quota" and "compute minutes" in GitLab 16.1.

The compute quota endpoints are used by [CustomersDot](https://gitlab.com/gitlab-org/customers-gitlab-com) (`customers.gitlab.com`)
to apply additional packs of compute minutes, for personal namespaces or top-level groups in GitLab.com.

#### Create an additional pack (deprecated)

Use a POST command to create additional packs.

```plaintext
POST /namespaces/:id/minutes
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `packs`     | array   | yes      | An array of purchased compute packs |
| `packs[expires_at]` | date   | yes      | Expiry date of the purchased pack|
| `packs[number_of_minutes]`  | integer    | yes       | Number of additional compute minutes |
| `packs[purchase_xid]` | string  | yes       | The unique ID of the purchase |

Example request:

```shell
curl --request POST \
  --url "http://localhost:3000/api/v4/namespaces/123/minutes" \
  --header 'Content-Type: application/json' \
  --header 'X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>' \
  --data '{
    "packs": [
      {
        "number_of_minutes": 10000,
        "expires_at": "2022-01-01",
        "purchase_xid": "C-00123456"
      }
    ]
  }'
```

Example response:

```json
[
  {
    "namespace_id": 123,
    "expires_at": "2022-01-01",
    "number_of_minutes": 10000,
    "purchase_xid": "C-00123456"
  }
]
```

#### Move additional packs (deprecated)

Use a `PATCH` command to move additional packs from one namespace to another.

```plaintext
PATCH /namespaces/:id/minutes/move/:target_id
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `id` | string | yes | The ID of the namespace to transfer packs from |
| `target_id`  | string | yes | The ID of the target namespace to transfer the packs to |

Example request:

```shell
curl --request PATCH \
  --url "http://localhost:3000/api/v4/namespaces/123/minutes/move/321" \
  --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>"
```

Example response:

```json
{
  "message": "202 Accepted"
}
```

### Subscriptions (deprecated)

The subscription endpoints are used by
[CustomersDot](https://gitlab.com/gitlab-org/customers-gitlab-com) (`customers.gitlab.com`) to
apply subscriptions (including trials) to personal namespaces, or top-level groups on GitLab.com.

#### Create a subscription (deprecated)

Use a POST command to create a subscription.

```plaintext
POST /namespaces/:id/gitlab_subscription
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `start_date` | date   | yes      | Start date of subscription |
| `end_date`  | date    | no       | End date of subscription |
| `plan_code` | string  | no       | Subscription tier code |
| `seats`     | integer | no       | Number of seats in subscription |
| `max_seats_used` | integer | no  | Highest number of active users in the last month |
| `auto_renew` | boolean | no      | Whether subscription auto-renews on end date |
| `trial`     | boolean | no       | Whether subscription is a trial |
| `trial_starts_on` | date | no    | Start date of trial |
| `trial_ends_on` | date | no      | End date of trial |

Example request:

```shell
curl --request POST --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/namespaces/1234/gitlab_subscription?start_date="2020-07-15"&plan="premium"&seats=10"
```

Example response:

```json
{
  "plan": {
    "code":"premium",
    "name":"premium",
    "trial":false,
    "auto_renew":null,
    "upgradable":false
  },
  "usage": {
    "seats_in_subscription":10,
    "seats_in_use":1,
    "max_seats_used":0,
    "seats_owed":0
  },
  "billing": {
    "subscription_start_date":"2020-07-15",
    "subscription_end_date":null,
    "trial_ends_on":null
  }
}
```

#### Update a subscription (deprecated)

Use a PUT command to update an existing subscription.

```plaintext
PUT /namespaces/:id/gitlab_subscription
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `start_date` | date   | no       | Start date of subscription |
| `end_date`  | date    | no       | End date of subscription |
| `plan_code` | string  | no       | Subscription tier code |
| `seats`     | integer | no       | Number of seats in subscription |
| `max_seats_used` | integer | no  | Highest number of active users in the last month |
| `auto_renew` | boolean | no      | Whether subscription auto-renews on end date |
| `trial`     | boolean | no       | Whether subscription is a trial |
| `trial_starts_on` | date | no    | Start date of trial. Required if trial is true. |
| `trial_ends_on` | date | no      | End date of trial |

Example request:

```shell
curl --request PUT --header "X-CUSTOMERS-DOT-INTERNAL-TOKEN: <json-web-token>" "https://gitlab.com/api/v4/namespaces/1234/gitlab_subscription?max_seats_used=0"
```

Example response:

```json
{
  "plan": {
    "code":"premium",
    "name":"premium",
    "trial":false,
    "auto_renew":null,
    "upgradable":false
  },
  "usage": {
    "seats_in_subscription":80,
    "seats_in_use":82,
    "max_seats_used":0,
    "seats_owed":2
  },
  "billing": {
    "subscription_start_date":"2020-07-15",
    "subscription_end_date":"2021-07-15",
    "trial_ends_on":null
  }
}
```

#### Fetch a subscription (deprecated)

Use a GET command to view an existing subscription.

```plaintext
GET /namespaces/:id/gitlab_subscription
```

Example request:

```shell
curl --header "TOKEN: <admin_access_token>" "https://gitlab.com/api/v4/namespaces/1234/gitlab_subscription"
```

Example response:

```json
{
  "plan": {
    "code":"premium",
    "name":"premium",
    "trial":false,
    "auto_renew":null,
    "upgradable":false,
    "exclude_guests":false
  },
  "usage": {
    "seats_in_subscription":80,
    "seats_in_use":82,
    "max_seats_used":82,
    "seats_owed":2
  },
  "billing": {
    "subscription_start_date":"2020-07-15",
    "subscription_end_date":"2021-07-15",
    "trial_ends_on":null
  }
}
```

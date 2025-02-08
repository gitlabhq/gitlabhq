---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Feature flags
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

With feature flags, you can deploy your application's new features to production in smaller batches.
You can toggle a feature on and off to subsets of users, helping you achieve Continuous Delivery.
Feature flags help reduce risk, allowing you to do controlled testing, and separate feature
delivery from customer launch.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an example of feature flags in action, see [Eliminating risk with feature flags](https://www.youtube.com/watch?v=U9WqoK9froI).
<!-- Video published on 2024-02-01 -->

For a click-through demo, see [Feature Flags](https://tech-marketing.gitlab.io/static-demos/feature-flags/feature-flags-html.html).
<!-- Demo published on 2023-07-13 -->

NOTE:
To contribute to the development of the GitLab product, view
[this feature flag content](../development/feature_flags/_index.md) instead.

## How it works

GitLab offers an [Unleash](https://github.com/Unleash/unleash)-compatible API for feature flags.

By enabling or disabling a flag in GitLab, your application
can determine which features to enable or disable.

You can create feature flags in GitLab and use the API from your application
to get the list of feature flags and their statuses. The application must be configured to communicate
with GitLab, so it's up to developers to use a compatible client library and
[integrate the feature flags in your app](#integrate-feature-flags-with-your-application).

## Create a feature flag

To create and enable a feature flag:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Feature flags**.
1. Select **New feature flag**.
1. Enter a name that starts with a letter and contains only lowercase letters, digits, underscores (`_`),
   or dashes (`-`), and does not end with a dash (`-`) or underscore (`_`).
1. Optional. Enter a description (255 characters maximum).
1. Add feature flag [**Strategies**](#feature-flag-strategies) to define how the flag should be applied. For each strategy, include the **Type** (defaults to [**All users**](#all-users))
   and **Environments** (defaults to all environments).
1. Select **Create feature flag**.

To change these settings, select **Edit** (**{pencil}**)
next to any feature flag in the list.

## Maximum number of feature flags

The maximum number of feature flags per project on GitLab Self-Managed
is 200. For GitLab.com, the maximum number is determined by [tier](https://about.gitlab.com/pricing/):

| Tier     | Feature flags per project (GitLab.com) | Feature flags per project (GitLab Self-Managed) |
|----------|----------------------------------|------------------------------------------|
| Free     | 50                               | 200                                      |
| Premium  | 150                              | 200                                      |
| Ultimate | 200                              | 200                                      |

## Feature flag strategies

You can apply a feature flag strategy across multiple environments, without defining
the strategy multiple times.

GitLab feature flags are based on [Unleash](https://docs.getunleash.io/). In Unleash, there are
[strategies](https://docs.getunleash.io/reference/activation-strategies) for granular feature
flag controls. GitLab feature flags can have multiple strategies, and the supported strategies are:

- [All users](#all-users)
- [Percent of Users](#percent-of-users)
- [User IDs](#user-ids)
- [User List](#user-list)

Strategies can be added to feature flags when [creating a feature flag](#create-a-feature-flag),
or by editing an existing feature flag after creation by navigating to **Deploy > Feature flags**
and selecting **Edit** (**{pencil}**).

### All users

Enables the feature for all users. It uses the Standard (`default`) Unleash activation [strategy](https://docs.getunleash.io/reference/activation-strategies#standard).

### Percent Rollout

Enables the feature for a percentage of page views, with configurable consistency
of behavior. This consistency is also known as stickiness. It uses the
Gradual Rollout (`flexibleRollout`) Unleash activation [strategy](https://docs.getunleash.io/reference/activation-strategies#gradual-rollout).

You can configure the consistency to be based on:

- **User IDs**: Each user ID has a consistent behavior, ignoring session IDs.
- **Session IDs**: Each session ID has a consistent behavior, ignoring user IDs.
- **Random**: Consistent behavior is not guaranteed. The feature is enabled for the
  selected percentage of page views randomly. User IDs and session IDs are ignored.
- **Available ID**: Consistent behavior is attempted based on the status of the user:
  - If the user is logged in, make behavior consistent based on user ID.
  - If the user is anonymous, make the behavior consistent based on the session ID.
  - If there is no user ID or session ID, then the feature is enabled for the selected
    percentage of page view randomly.

For example, set a value of 15% based on **Available ID** to enable the feature for 15% of page views. For
authenticated users this is based on their user ID. For anonymous users with a session ID it would be based on their
session ID instead as they do not have a user ID. Then if no session ID is provided, it falls back to random.

The rollout percentage can be from 0% to 100%.

Selecting a consistency based on User IDs functions the same as the [percent of Users](#percent-of-users) rollout.

WARNING:
Selecting **Random** provides inconsistent application behavior for individual users.

### Percent of Users

Enables the feature for a percentage of authenticated users. It uses the Unleash activation strategy
[`gradualRolloutUserId`](https://docs.getunleash.io/reference/activation-strategies#gradual-rollout).

For example, set a value of 15% to enable the feature for 15% of authenticated users.

The rollout percentage can be from 0% to 100%.

Stickiness (consistent application behavior for the same user) is guaranteed for authenticated users,
but not anonymous users.

[Percent rollout](#percent-rollout) with a consistency based on **User IDs** has the same
behavior. We recommend using percent rollout because it's more flexible than percent of users

WARNING:
If the percent of users strategy is selected, then the Unleash client **must** be given a user
ID for the feature to be enabled. See the [Ruby example](#ruby-application-example) below.

### User IDs

Enables the feature for a list of target users. It is implemented
using the Unleash UserIDs (`userWithId`) activation [strategy](https://docs.getunleash.io/reference/activation-strategies#userids).

Enter user IDs as a comma-separated list of values (for example,
`user@example.com, user2@example.com`, or `username1,username2,username3`, and so on).
User IDs are identifiers for your application users. They do not need to be GitLab users.

WARNING:
The Unleash client **must** be given a user ID for the feature to be enabled for
target users. See the [Ruby example](#ruby-application-example) below.

### User List

Enables the feature for lists of users created [in the feature flags UI](#create-a-user-list), or with the [feature flag user list API](../api/feature_flag_user_lists.md).
Similar to [User IDs](#user-ids), it uses the Unleash UsersIDs (`userWithId`) activation [strategy](https://docs.getunleash.io/reference/activation-strategies#userids).

You can't disable a specific feature for a user, but you can achieve similar results by enabling it for a user list.

For example:

- `Full-user-list` = `User1A, User1B, User2A, User2B, User3A, User3B, ...`
- `Full-user-list-excluding-B-users` = `User1A, User2A, User3A, ...`

#### Create a user list

To create a user list:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Feature flags**.
1. Select **View user lists**
1. Select **New user list**.
1. Enter a name for the list.
1. Select **Create**.

You can view a list's User IDs by selecting **Edit** (**{pencil}**) next to it.
When viewing a list, you can rename it by selecting **Edit** (**{pencil}**).

#### Add users to a user list

To add users to a user list:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Feature flags**.
1. Select **Edit** (**{pencil}**) next to the list you want to add users to.
1. Select **Add Users**.
1. Enter the user IDs as a comma-separated list of values. For example,
   `user@example.com, user2@example.com`, or `username1,username2,username3`, and so on.
1. Select **Add**.

#### Remove users from a user list

To remove users from a user list:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Feature flags**.
1. Select **Edit** (**{pencil}**) next to the list you want to change.
1. Select **Remove** (**{remove}**) next to the ID you want to remove.

## Search for Code References

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To remove the feature flag from the code during cleanup, find any project references to it.

To search for code references of a feature flag:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Feature flags**.
1. Edit the feature flag you want to remove.
1. Select **More actions** (**{ellipsis_v}**).
1. Select **Search code references**.

## Disable a feature flag for a specific environment

To disable a feature flag for a specific environment:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Feature flags**.
1. For the feature flag you want to disable, select **Edit** (**{pencil}**).
1. To disable the flag:
   - For each strategy it applies to, under **Environments**, delete the environment.
1. Select **Save changes**.

## Disable a feature flag for all environments

To disable a feature flag for all environments:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Feature flags**.
1. For the feature flag you want to disable, slide the Status toggle to **Disabled**.

The feature flag is displayed on the **Disabled** tab.

## Integrate feature flags with your application

To use feature flags with your application, get access credentials from GitLab.
Then prepare your application with a client library.

### Get access credentials

To get the access credentials that your application needs to communicate with GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Feature flags**.
1. Select **Configure** to view the following:
   - **API URL**: URL where the client (application) connects to get a list of feature flags.
   - **Instance ID**: Unique token that authorizes the retrieval of the feature flags.
   - **Application name**: The name of the *environment* the application runs in
     (not the name of the application itself).

     For example, if the application runs for a production server, the **Application name**
     could be `production` or similar. This value is used for the environment spec evaluation.

The meaning of these fields might change over time. For example, we're not sure if
**Instance ID** is a single token or multiple tokens, assigned to the **Environment**. Also,
**Application name** could describe the application version instead of the running environment.

### Choose a client library

GitLab implements a single backend that is compatible with Unleash clients.

With the Unleash client, developers can define, in the application code, the default values for flags.
Each feature flag evaluation can express the desired outcome if the flag isn't present in the
provided configuration file.

Unleash currently [offers many SDKs for various languages and frameworks](https://github.com/Unleash/unleash#client-implementations).

### Feature flags API information

For API content, see:

- [Feature flags API](../api/feature_flags.md)
- [Feature flag user lists API](../api/feature_flag_user_lists.md)

### Go application example

Here's an example of how to integrate feature flags in a Go application:

```go
package main

import (
    "io"
    "log"
    "net/http"

    "github.com/Unleash/unleash-client-go/v3"
)

type metricsInterface struct {
}

func init() {
    unleash.Initialize(
        unleash.WithUrl("https://gitlab.com/api/v4/feature_flags/unleash/42"),
        unleash.WithInstanceId("29QmjsW6KngPR5JNPMWx"),
        unleash.WithAppName("production"), // Set to the running environment of your application
        unleash.WithListener(&metricsInterface{}),
    )
}

func helloServer(w http.ResponseWriter, req *http.Request) {
    if unleash.IsEnabled("my_feature_name") {
        io.WriteString(w, "Feature enabled\n")
    } else {
        io.WriteString(w, "hello, world!\n")
    }
}

func main() {
    http.HandleFunc("/", helloServer)
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

### Ruby application example

Here's an example of how to integrate feature flags in a Ruby application.

The Unleash client is given a user ID for use with a **Percent rollout (logged in users)** rollout strategy or a list of **Target Users**.

```ruby
#!/usr/bin/env ruby

require 'unleash'
require 'unleash/context'

unleash = Unleash::Client.new({
  url: 'http://gitlab.com/api/v4/feature_flags/unleash/42',
  app_name: 'production', # Set to the running environment of your application
  instance_id: '29QmjsW6KngPR5JNPMWx'
})

unleash_context = Unleash::Context.new
# Replace "123" with the ID of an authenticated user.
# Note that the context's user ID must be a string:
# https://unleash.github.io/docs/unleash_context
unleash_context.user_id = "123"

if unleash.is_enabled?("my_feature_name", unleash_context)
  puts "Feature enabled"
else
  puts "hello, world!"
end
```

### Unleash Proxy example

As of [Unleash Proxy](https://docs.getunleash.io/reference/unleash-proxy) version
0.2, the proxy is compatible with feature flags.

You should use Unleash Proxy for production on GitLab.com. See the [performance note](#maximum-supported-clients-in-application-nodes) for details.

To run a Docker container to
connect to your project's feature flags, run the following command:

```shell
docker run \
  -e UNLEASH_PROXY_SECRETS=<secret> \
  -e UNLEASH_URL=<project feature flags URL> \
  -e UNLEASH_INSTANCE_ID=<project feature flags instance ID> \
  -e UNLEASH_APP_NAME=<project environment> \
  -e UNLEASH_API_TOKEN=<tokenNotUsed> \
  -p 3000:3000 \
  unleashorg/unleash-proxy
```

| Variable                    | Value                                                                                                                                |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `UNLEASH_PROXY_SECRETS`      | Shared secret used to configure an [Unleash Proxy client](https://docs.getunleash.io/reference/unleash-proxy#how-to-connect-to-the-proxy). |
| `UNLEASH_URL`         | Your project's API URL. For more details, read [Get access credentials](#get-access-credentials). |
| `UNLEASH_INSTANCE_ID` | Your project's Instance ID. For more details, read [Get access credentials](#get-access-credentials). |
| `UNLEASH_APP_NAME`    | The name of the environment the application runs in. For more details, read [Get access credentials](#get-access-credentials). |
| `UNLEASH_API_TOKEN`   | Required to start the Unleash Proxy, but not used to connect to GitLab. Can be set to any value. |

There is a limitation when using the Unleash Proxy where each proxy instance can request flags only for the environment named in `UNLEASH_APP_NAME`. The Proxy sends
this to GitLab on behalf of the client, which means the client can't override it.

## Feature flag related issues

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can link related issues to a feature flag. In the feature flag **Linked issues** section,
select the `+` button and input the issue reference number or the full URL of the issue.
The issues then appear in the related feature flag and the other way round.

This feature is similar to the [linked issues](../user/project/issues/related_issues.md) feature.

## Performance factors

GitLab feature flags can be used in any application. Large applications might require advance configuration.
This section explains the performance factors to help your organization to identify
what's needed to be done before using the feature.
Read [How it works](#how-it-works) section before diving into the details.

### Maximum supported clients in application nodes

GitLab accepts as many client requests as possible until it hits the [rate limit](../security/rate_limits.md).
The feature flag API is considered **Unauthenticated traffic (from a given IP address)**. For GitLab.com, see the [GitLab.com specific limits](../user/gitlab_com/_index.md).

The polling rate is configurable in SDKs. Provided that all clients are requesting from the same IP:

- Request once per minute ... 500 clients can be supported.
- Request once per 15 sec ... 125 clients can be supported.

For applications looking for more scalable solution, you should use [Unleash Proxy](#unleash-proxy-example).
On GitLab.com, you should use Unleash Proxy to reduce the chance of being rate limited across endpoints.
This proxy server sits between the server and clients. It makes requests to the server on behalf of the client groups,
so the number of outbound requests can be greatly reduced. If you still get `429` responses, increase the `UNLEASH_FETCH_INTERVAL` value in the Unleash Proxy.

There is also an [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/295472) to give more
capacity to the current rate limit.

### Recovering from network errors

In general, [Unleash clients](https://github.com/Unleash/unleash#unleash-sdks) have
a fall-back mechanism when the server returns an error code.
For example, `unleash-ruby-client` reads flag data from the local backup so that
application can keep running in the current state.

Read the documentation in a SDK project for more information.

### GitLab Self-Managed

Functionality-wise, there are no differences. Both GitLab.com and GitLab Self-Managed behave the same.

In terms of scalability, it's up to the spec of the GitLab instance.
For example, GitLab.com uses HA architecture so it can handle many concurrent requests. However, GitLab Self-Managed instances on underpowered machines won't deliver comparable performance.
See [Reference architectures](../administration/reference_architectures/_index.md)
for more information.

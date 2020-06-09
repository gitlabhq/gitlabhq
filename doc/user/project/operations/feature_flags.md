---
stage: Release
group: Progressive Delivery
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Feature Flags **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/7433) in GitLab 11.4.

With Feature Flags, you can deploy your application's new features to production in smaller batches.
You can toggle a feature on and off to subsets of users, helping you achieve Continuous Delivery.
Feature flags help reduce risk, allowing you to do controlled testing, and separate feature
delivery from customer launch.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an example of feature flags in action, see [GitLab for Deploys, Feature Flags, and Error Tracking](https://www.youtube.com/embed/5tw2p6lwXxo).

## How it works

GitLab uses [Unleash](https://github.com/Unleash/unleash), a feature
toggle service.

By enabling or disabling a flag in GitLab, your application
can determine which features to enable or disable.

You can create feature flags in GitLab and use the API from your application
to get the list of feature flags and their statuses. The application must be configured to communicate
with GitLab, so it's up to developers to use a compatible client library and
[integrate the feature flags in your app](#integrate-feature-flags-with-your-application).

## Create a feature flag

To create and enable a feature flag:

1. Navigate to your project's **Operations > Feature Flags**.
1. Click the **New feature flag** button.
1. Enter a name that starts with a letter and contains only lowercase letters, digits, underscores (`_`)
   and dashes (`-`), and does not end with a dash (`-`) or underscore (`_`).
1. Enter a description (optional, 255 characters max).
1. Enter details about how the flag should be applied:
   - In GitLab 13.0 and earlier: Enter an environment spec,
     enable or disable the flag in this environment, and select a rollout strategy.
   - In GitLab 13.1 and later (when [this feature flag](#feature-flag-behavior-change-in-130) is enabled): Select a strategy and then
     the environments to apply the strategy to.
1. Click **Create feature flag**.

The feature flag is displayed in the list. It is enabled by default.

## Disable a feature flag for a specific environment

In [GitLab 13.0 and earlier](https://gitlab.com/gitlab-org/gitlab/-/issues/8621),
to disable a feature flag for a specific environment:

1. Navigate to your project's **Operations > Feature Flags**.
1. For the feature flag you want to disable, click the Pencil icon.
1. To disable the flag:
   - In GitLab 13.0 and earlier: Slide the Status toggle for the environment. Or, to delete the
     environment spec, on the right, click the **Remove (X)** icon.
   - In GitLab 13.1 and later (when [this feature flag](#feature-flag-behavior-change-in-130) is
     enabled): For each strategy it applies to, under **Environments**, delete the environment.
1. Click **Save changes**.

## Disable a feature flag for all environments

To disable a feature flag for all environments:

1. Navigate to your project's **Operations > Feature Flags**.
1. For the feature flag you want to disable, slide the Status toggle to **Disabled**.

The feature flag is displayed on the **Disabled** tab.

## Feature flag behavior change in 13.0

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/35555) in GitLab 13.0.

Starting in GitLab 13.0, you can apply a feature flag strategy across multiple environments,
without defining the strategy multiple times.

This feature is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can enable it for your instance.

To enable it:

```ruby
Feature.enable(:feature_flags_new_version)
```

To disable it:

```ruby
Feature.disable(:feature_flags_new_version)
```

## Feature flag strategies

GitLab Feature Flag uses [Unleash](https://unleash.github.io)
as the feature flag engine. In Unleash, there is a concept of rulesets for granular feature flag controls,
called [strategies](https://unleash.github.io/docs/activation_strategy).
Supported strategies for GitLab Feature Flags are described below.

### Rollout strategy

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/8240) in GitLab 12.2.

The selected rollout strategy affects which users will experience the feature as enabled.

The status of an environment spec ultimately determines whether or not a feature is enabled at all.
For instance, a feature will always be disabled for every user if the matching environment spec has a disabled status, regardless of the chosen rollout strategy.
However, a feature will be enabled for 50% of logged-in users if the matching environment spec has an enabled status along with a **Percent rollout (logged in users)** strategy set to 50%.

#### All users

Enables the feature for all users. It is implemented using the Unleash
[`default`](https://unleash.github.io/docs/activation_strategy#default)
activation strategy.

#### Percent rollout (logged in users)

Enables the feature for a percentage of authenticated users. It is
implemented using the Unleash
[`gradualRolloutUserId`](https://unleash.github.io/docs/activation_strategy#gradualrolloutuserid)
activation strategy.

Set a value of 15%, for example, to enable the feature for 15% of authenticated users.

A rollout percentage may be between 0% and 100%.

CAUTION: **Caution:**
If this strategy is selected, then the Unleash client **must** be given a user
ID for the feature to be enabled. See the [Ruby example](#ruby-application-example) below.

#### User IDs

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/8240) in GitLab 12.2. [Updated](https://gitlab.com/gitlab-org/gitlab/-/issues/34363) to be defined per environment in GitLab 12.6.

A feature flag may be enabled for a list of target users. It is implemented
using the Unleash [`userWithId`](https://unleash.github.io/docs/activation_strategy#userwithid)
activation strategy.

User IDs should be a comma-separated list of values. For example, `user@example.com, user2@example.com`, or `username1,username2,username3`, etc.

CAUTION: **Caution:**
The Unleash client **must** be given a user ID for the feature to be enabled for
target users. See the [Ruby example](#ruby-application-example) below.

## Integrate feature flags with your application

To use feature flags with your application, get access credentials from GitLab.
Then prepare your application with a client library.

### Get access credentials

To get the access credentials that your application needs to communicate with GitLab:

1. Navigate to your project's **Operations > Feature Flags**.
1. Click the **Configure** button to view the following:
   - **API URL**: URL where the client (application) connects to get a list of feature flags.
   - **Instance ID**: Unique token that authorizes the retrieval of the feature flags.
   - **Application name**: The name of the running environment. For instance,
     if the application runs for a production server, the application name would be
     `production` or similar. This value is used for the environment spec evaluation.

NOTE: **Note:**
The meaning of these fields might change over time. For example, we are not sure
if **Instance ID** will be single token or multiple tokens, assigned to the
**Environment**. Also, **Application name** could describe the version of
application instead of the running environment.

### Choose a client library

GitLab implements a single backend that is compatible with Unleash clients.

With the Unleash client, developers can define, in the application code, the default values for flags.
Each feature flag evaluation can express the desired outcome if the flag isn't present in the
provided configuration file.

Unleash currently [offers many SDKs for various languages and frameworks](https://github.com/Unleash/unleash#client-implementations).

### Feature flags API information

For API content, see:

- [Feature Flags API](../../../api/feature_flags.md)
- [Feature Flag Specs API](../../../api/feature_flag_specs.md) (Deprecated and [scheduled for removal in GitLab 14.0](https://gitlab.com/gitlab-org/gitlab/-/issues/213369).)
- [Feature Flag User Lists API](../../../api/feature_flag_user_lists.md)
- [Legacy Feature Flags API](../../../api/feature_flags_legacy.md)

### Golang application example

Here's an example of how to integrate feature flags in a Golang application:

```golang
package main

import (
    "io"
    "log"
    "net/http"

    "github.com/Unleash/unleash-client-go"
)

type metricsInterface struct {
}

func init() {
    unleash.Initialize(
        unleash.WithUrl("https://gitlab.com/api/v4/feature_flags/unleash/42"),
        unleash.WithInstanceId("29QmjsW6KngPR5JNPMWx"),
        unleash.WithAppName("production"),
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
  app_name: 'production',
  instance_id: '29QmjsW6KngPR5JNPMWx'
})

unleash_context = Unleash::Context.new
# Replace "123" with the id of an authenticated user.
# Note that the context's user id must be a string:
# https://unleash.github.io/docs/unleash_context
unleash_context.user_id = "123"

if unleash.is_enabled?("my_feature_name", unleash_context)
  puts "Feature enabled"
else
  puts "hello, world!"
end
```

# Feature Flags **[PREMIUM]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/11845) in GitLab 11.4.

CAUTION: **Warning:**
This an _alpha_ feature and is subject to change at any time without
prior notice.

Feature flags allow you to ship a project in different flavors by
dynamically toggling certain functionality.

## Overview

Feature Flags offer a feature toggle system for your application. They enable teams
to achieve Continuous Delivery by deploying new features to production at smaller
batches for controlled testing, separating feature delivery from customer launch.
This helps reducing risk and allows you to easily manage which features to enable.

GitLab offers a Feature Flags interface that allows you to create, toggle and
remove feature flags.

## How it works

Underneath, GitLab uses [unleash](https://github.com/Unleash/unleash), a feature
toggle service. GitLab provides an API where your application can talk to and get the
list of feature flags you set in GitLab.

The application must be configured to talk to GitLab, so that's up to the
developers to use a compatible [client library](#client-libraries) and
integrate it in their app.

By setting a flag active or inactive via GitLab, your application will automatically
know which features to enable or disable respectively.

## Adding a new feature flag

To add a new feature flag:

1. Navigate to your project's **Operations > Feature Flags**.
1. Click on the **New Feature Flag** button.
1. Give it a name.

    NOTE: **Note:**
    A name can contain only lowercase letters, digits, underscores (`_`)
    and dashes (`-`), must start with a letter, and cannot end with a dash (`-`)
    or an underscore (`_`).

1. Give it a description (optional, 255 characters max).
1. If you want to activate it, click on the "Active" checkbox.
1. Click **Create feature flag**.

Once a feature flag is created, the list of existing feature flags will be presented
with ability to edit or remove them.

To make a feature flag active or inactive, click the pencil icon to edit it,
and toggle the "Active" checkbox.

![Feature flags list](img/feature_flags_list.png)

## Integrating with your application

In order to use Feature Flags, you need to first
[get the access credentials](#configuring-feature-flags) from GitLab and then
prepare your application and hook it with a [client library](#client-libraries).

### Configuring Feature Flags

To get the access credentials that your application will need to talk to GitLab:

1. Navigate to your project's **Operations > Feature Flags**.
1. Click on the **Configure** button to see the values:
    - **API URL**: URL where the client (application) connects to get a list of feature flags.
    - **Instance ID**: Unique token that authorizes the retrieval of the feature flags.
    - **Application name**: The name of the running environment. By default this is
      set to `production`, but you can use whatever you want in your application
      (e.g.,`staging`, `review/feature`).

NOTE: **Note:**
The meaning of these fields might change over time. For example, we are not sure
if **Instance ID** will be single token or multiple tokens, assigned to the
**Environment**. Also, **Application name** could describe the version of
application instead of the running environment.

### Client libraries

GitLab currently implements a single backend that is compatible with
[Unleash](https://github.com/Unleash/unleash#client-implementations) clients.

Unleash clients allow the developers to define in the app's code the default
values for flags. Each feature flag evaluation can express the desired
outcome in case the flag isn't present on the provided configuration file.

Unleash currently offers a number of official SDKs for various frameworks and
a number of community contributed libraries.

Official clients:

- [unleash/unleash-client-java](https://github.com/unleash/unleash-client-java)
- [unleash/unleash-client-node](https://github.com/unleash/unleash-client-node)
- [unleash/unleash-client-go](https://github.com/unleash/unleash-client-go)
- [unleash/unleash-client-ruby](https://github.com/unleash/unleash-client-ruby)

Community contributed clients:

- [stiano/unleash-client-dotnet](https://github.com/stiano/unleash-client-dotnet) (.Net Core)
- [onybo/unleash-client-core](https://github.com/onybo/unleash-client-core) (.Net Core)
- [aes/unleash-client-python](https://github.com/aes/unleash-client-python) (Python 3)

### Golang application example

Here's an example of how to integrate the feature flags in a Golang application:

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

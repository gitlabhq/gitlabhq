---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maven virtual registry
description: Use the Maven virtual registry to configure and manage multiple private and public upstream registries.
---

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14137) in GitLab 18.0 [with a flag](../../../../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available in [beta](../../../../policy/development_stages_support.md#beta).
Review the documentation carefully before you use this feature.

{{< /alert >}}

The Maven virtual registry uses a single, well-known URL to manage and distribute
packages from multiple external registries in GitLab.

Use the Maven virtual registry to:

- Create a virtual registry.
- Connect the virtual registry to public and private upstream registries.
- Configure Maven clients to pull packages from configured upstreams.
- Manage cache entries for available upstreams.

This approach provides better package performance over time,
and makes it easier to manage your Maven packages.

For general information about managing virtual registries and upstream registries, see
[Virtual registry](../../virtual_registry/_index.md).

## Prerequisites

Before you can use the Maven virtual registry:

- Review the [prerequisites](../_index.md#prerequisites) to use the virtual registry.

When using the Maven virtual registry, remember the following restrictions:

- You can create up to `20` Maven virtual registries per top-level group.
- You can set only `20` upstreams to a given Maven virtual registry.
- For technical reasons, the `proxy_download` setting is force enabled, no matter what the value in the [object storage configuration](../../../../administration/object_storage.md#proxy-download) is configured to.
- Geo support is not implemented. You can follow its development in [issue 473033](https://gitlab.com/gitlab-org/gitlab/-/issues/473033).

## Manage virtual registries

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/15090) in GitLab 18.5 [with a flag](../../../../administration/feature_flags/_index.md) named `ui_for_virtual_registries`. Enabled by default.

{{< /history >}}

Manage virtual registries for your group.

You can also [use the API](../../../../api/maven_virtual_registries.md#manage-virtual-registries).

### View the virtual registry

To view the virtual registry:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar. This group must be at the top level.
1. Select **Deploy** > **Virtual registry**.

### Create a Maven virtual registry

To create a Maven virtual registry:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar. This group must be at the top level.
1. Select **Deploy** > **Virtual registry**.
1. Select **Create registry**.
1. Enter a **Name** and optional **Description**.
1. Select **Create Maven registry**.

### Edit a virtual registry

To edit an existing virtual registry:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar. This group must be at the top level.
1. Select **Deploy** > **Virtual registry**.
1. Under **Registry types**, select **View registries**.
1. In the row of the registry you want to edit, select **Edit** ({{< icon name="pencil" >}}).
1. Make your changes and select **Save changes**.

### Delete a virtual registry

To delete a virtual registry:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar. This group must be at the top level.
1. Select **Deploy** > **Virtual registry**.
1. Under **Registry types**, select **View registries**.
1. Under the **Registries** tab, in the row of the registry you want to delete, select **Edit** ({{< icon name="pencil" >}}).
1. Select **Delete registry**.
1. On the confirmation dialog, select **Delete**.

## Manage upstream registries

Manage upstream registries in a virtual registry.

### View upstream registries

To view upstream registries:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar. This group must be at the top level.
1. Select **Deploy** > **Virtual registry**.
1. Under **Registry types**, select **View registries**.
1. Select the **Upstreams** tab to view all available upstreams.

### Create a Maven upstream registry

Create a Maven upstream registry to connect to the virtual registry.

Prerequisites:

- You must have a virtual registry. For more information, see [Create a virtual registry](#create-a-maven-virtual-registry).

To create a Maven upstream registry:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar. This group must be at the top level.
1. Select **Deploy** > **Virtual registry**.
1. Under **Registry types**, select **View registries**.
1. Under the **Registries** tab, select a registry.
1. Select **Add upstream**. If the virtual registry has existing upstreams, from the dropdown list, select either:
   - **Create new upstream** to configure the upstream.
   - **Link existing upstream** > **Select existing upstream**.
     1. From the dropdown list, select an upstream.
1. Configure the Maven upstream registry:
   - Enter a **Name**.
   - Enter the **Upstream URL**.
   - Optional. Enter a **Description**.
   - Optional. Enter a **Username** and **Password**. You must include both a username and password, or neither. If not set, a public (anonymous) request is used to access the upstream.
1. Set the **Artifact caching period** and **Metadata caching period**.
   - The artifact and metadata caching periods default to 24 hours. Set to `0` to disable cache entry checks.
1. Select **Create upstream**.

If you connect the upstream to Maven Central:

- For **Upstream URL**, enter the following URL:

  ```plaintext
  https://repo1.maven.org/maven2
  ```

- For **Artifact caching period** and **Metadata caching period**, set the time to `0`. Maven Central files are immutable.

For more information about cache validity settings, see [Set the cache validity period](../../virtual_registry/_index.md#set-the-cache-validity-period).

### Edit an upstream registry

To edit an upstream registry:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar. This group must be at the top level.
1. Select **Deploy** > **Virtual registry**.
1. Under **Registry types**, select **View registries**.
1. Select the **Upstreams** tab.
1. In the row of the upstream you want to edit, select **Edit** ({{< icon name="pencil" >}}).
1. Make your changes and select **Save changes**.

### Reorder upstream registries

The order of upstream registries determines the priority in which they are queried for packages.
The virtual registry searches upstreams from top to bottom until it finds the requested package.

To change the order of upstream registries:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar. This group must be at the top level.
1. Select **Deploy** > **Virtual registries**.
1. Under **Registry types**, select a registry.
1. Under the **Registries** tab, select a registry.
1. Under **Upstreams**, select **Move upstream up** or **Move upstream down** to reorder upstreams.

Best practices for upstream ordering:

- Position private registries before public ones to prioritize internal packages.
- Place faster or more reliable registries higher in the list.
- Put public registries last as fallbacks for public dependencies.

For more information about the order of upstreams, see [Upstream prioritization](../../virtual_registry/_index.md#upstream-prioritization).

### View cached packages

To view packages that have been cached from upstream registries:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar. This group must be at the top level.
1. Select **Deploy** > **Virtual registry**.
1. Under **Registry types**, select a registry.
1. Under the **Upstreams** tab, select an upstream.
1. View the cache metadata for cached packages.

### Delete cache entries

To delete cache entries:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar. This group must be at the top level.
1. Select **Deploy** > **Virtual registry**.
1. Under **Registry types**, select a registry.
1. Under the **Registries** tab, select a registry.
1. Next to **Upstreams**, select **Clear all caches**.
   - To delete a specific cache entry, next to an upstream, select **Clear cache**.

When you delete a cache entry, the next time the virtual registry receives a request for that file, it walks the list of upstreams again to find an upstream that can fulfill the request.

For more information about cache entries, see [Caching system](../../virtual_registry/_index.md#caching-system).

## Use the Maven virtual registry

After you create a virtual registry, you must configure Maven clients to pull dependencies through the virtual registry.

### Authentication with Maven clients

The virtual registry endpoint can be used by any of following tokens:

- A [personal access token](../../../profile/personal_access_tokens.md).
- A [group deploy token](../../../project/deploy_tokens/_index.md) for the top-level group hosting the considered virtual registry.
- A [group access token](../../../group/settings/group_access_tokens.md) for the top-level group hosting the considered virtual registry.
- A [CI job token](../../../../ci/jobs/ci_job_token.md).

Tokens need one of the following scopes:

- `api`
- `read_virtual_registry`

Access tokens and the CI job token are resolved to users. The resolved user must be either:

- A direct member of the top-level group with the minimal access level of `guest`.
- A GitLab instance administrator.
- A direct member of one of the projects included in the top-level group.

### Configure Maven clients

The Maven virtual registry supports the following Maven clients:

- [`mvn`](https://maven.apache.org/index.html)
- [`gradle`](https://gradle.org/)
- [`sbt`](https://www.scala-sbt.org/)

You must declare virtual registries in the Maven client configuration.

All clients must be authenticated. For the client authentication, you can use a custom HTTP header or Basic Auth.
You should use one of the configurations below for each client.

{{< tabs >}}

{{< tab title="mvn" >}}

| Token type            | Name must be    | Token                                                                   |
| --------------------- | --------------- | ----------------------------------------------------------------------- |
| Personal access token | `Private-Token` | Paste token as-is, or define an environment variable to hold the token. |
| Group deploy token    | `Deploy-Token`  | Paste token as-is, or define an environment variable to hold the token. |
| Group access token    | `Private-Token` | Paste token as-is, or define an environment variable to hold the token. |
| CI Job token          | `Job-Token`     | `${CI_JOB_TOKEN}`                                                       |

Add the following section to your
[`settings.xml`](https://maven.apache.org/settings.html) file.

```xml
<settings>
  <servers>
    <server>
      <id>gitlab-maven</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>REPLACE_WITH_NAME</name>
            <value>REPLACE_WITH_TOKEN</value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
</settings>
```

You can configure the virtual registry in `mvn` applications in one of two ways:

- As an additional registry on top of the default registry (Maven central). In this configuration, you can pull the project dependencies that are present in both the virtual registry and the default registry from any of the declared registries.
- As a replacement of the default registry (Maven central). With this configuration, dependencies are pulled through the virtual registry. You should configure Maven central as the last upstream of the virtual registry to avoid missing required public dependencies.

To configure a Maven virtual registry as an additional registry, in the `pom.xml` file, add a `repository` element:

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/virtual_registries/packages/maven/<registry_id></url>
  </repository>
</repositories>
```

- `<id>`: The same ID of the `<server>` used in the `settings.xml`.
- `<registry_id>`: The ID of the Maven virtual registry.

To configure a Maven virtual registry as a replacement of the default registry, in the `settings.xml`, add a `mirrors` element:

```xml
<settings>
  <servers>
    ...
  </servers>
  <mirrors>
    <mirror>
      <id>central-proxy</id>
      <name>GitLab proxy of central repo</name>
      <url>https://gitlab.example.com/api/v4/virtual_registries/packages/maven/<registry_id></url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
```

- `<registry_id>`: The ID of the Maven virtual registry.

{{< /tab >}}

{{< tab title="gradle" >}}

| Token type            | Name must be    | Token                                                                   |
| --------------------- | --------------- | ----------------------------------------------------------------------- |
| Personal access token | `Private-Token` | Paste token as-is, or define an environment variable to hold the token. |
| Group deploy token    | `Deploy-Token`  | Paste token as-is, or define an environment variable to hold the token. |
| Group access token    | `Private-Token` | Paste token as-is, or define an environment variable to hold the token. |
| CI Job token          | `Job-Token`     | `${CI_JOB_TOKEN}`                                                       |

In [your `GRADLE_USER_HOME` directory](https://docs.gradle.org/current/userguide/directory_layout.html#dir:gradle_user_home),
create a file `gradle.properties` with the following content:

```properties
gitLabPrivateToken=REPLACE_WITH_YOUR_TOKEN
```

Add a `repositories` section to your
[`build.gradle`](https://docs.gradle.org/current/userguide/tutorial_using_tasks.html).

- In Groovy DSL:

  ```groovy
  repositories {
      maven {
          url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/<registry_id>"
          name "GitLab"
          credentials(HttpHeaderCredentials) {
              name = 'REPLACE_WITH_NAME'
              value = gitLabPrivateToken
          }
          authentication {
              header(HttpHeaderAuthentication)
          }
      }
  }
  ```

- In Kotlin DSL:

  ```kotlin
  repositories {
      maven {
          url = uri("https://gitlab.example.com/api/v4/virtual_registries/packages/maven/<registry_id>")
          name = "GitLab"
          credentials(HttpHeaderCredentials::class) {
              name = "REPLACE_WITH_NAME"
              value = findProperty("gitLabPrivateToken") as String?
          }
          authentication {
              create("header", HttpHeaderAuthentication::class)
          }
      }
  }
  ```

- `<registry_id>`: The ID of the Maven virtual registry.

{{< /tab >}}

{{< tab title="sbt" >}}

| Token type            | Username must be                                        | Token                                                                   |
| --------------------- | ------------------------------------------------------- | ----------------------------------------------------------------------- |
| Personal access token | The username of the user                                | Paste token as-is, or define an environment variable to hold the token. |
| Group deploy token    | The username of deploy token                            | Paste token as-is, or define an environment variable to hold the token. |
| Group access token    | The username of the user linked to the access token     | Paste token as-is, or define an environment variable to hold the token. |
| CI Job token          | `gitlab-ci-token`                                       | `sys.env.get("CI_JOB_TOKEN").get`                                       |

Authentication for [SBT](https://www.scala-sbt.org/index.html) is based on
[basic HTTP Authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication).
You must provide a name and a password.

In your [`build.sbt`](https://www.scala-sbt.org/1.x/docs/Directories.html#sbt+build+definition+files), add the following lines:

```scala
resolvers += ("gitlab" at "<endpoint_url>")

credentials += Credentials("GitLab Virtual Registry", "<host>", "<username>", "<token>")
```

- `<endpoint_url>`: The Maven virtual registry URL.
  For example, `https://gitlab.example.com/api/v4/virtual_registries/packages/maven/<registry_id>`, where `<registry_id>` is the ID of the Maven virtual registry.
- `<host>`: The host present in the `<endpoint_url>` without the protocol scheme or the port. For example, `gitlab.example.com`.
- `<username>`: The username.
- `<token>`: The configured token.

Make sure that the first argument of `Credentials` is `"GitLab Virtual Registry"`. This realm name must exactly match the [Basic Auth realm](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Authentication#www-authenticate_and_proxy-authenticate_headers) sent by the Maven virtual registry.

{{< /tab >}}

{{< /tabs >}}

---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maven virtual registry
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14137) in GitLab 18.0 [with a flag](../../../../administration/feature_flags.md) named `virtual_registry_maven`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available in [experiment](../../../../policy/development_stages_support.md#experiment).
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

## Prerequisites

Before you can use the Maven virtual registry:

- Review the [prerequisites](../_index.md#prerequisites) to use the virtual registry.

When using the Maven virtual registry, remember the following restrictions:

- You can create only one Maven virtual registry per top-level group.
- You can set only `20` upstreams to a given Maven virtual registry.
- For technical reasons, the `proxy_download` setting is force enabled, no matter what the value in the [object storage configuration](../../../../administration/object_storage.md#proxy-download) is configured to.
- Geo support is not implemented. You can follow its development in [issue 473033](https://gitlab.com/gitlab-org/gitlab/-/issues/473033).

## Manage the virtual registry

Manage the virtual registry with the [Maven virtual registry API](../../../../api/maven_virtual_registries.md#manage-virtual-registries).

You cannot configure the virtual registry in the UI, but [epic 15090](https://gitlab.com/groups/gitlab-org/-/epics/15090) proposes the implementation of a virtual registry UI.

### Authenticate to the virtual registry API

The virtual registry API uses [REST API authentication](../../../../api/rest/authentication.md) methods. You must authenticate to the API to manage virtual registry objects.

Read operations are available to users that can [use the virtual registry](#use-the-virtual-registry).

Write operations, such as [creating a new registry](#create-and-manage-a-virtual-registry) or [adding upstreams](#manage-upstream-registries), are restricted to
direct maintainers of the top-level group of the virtual registry.

### Create and manage a virtual registry

To create a Maven virtual registry, use the following command:

```shell
curl --fail-with-body \
     --request POST \
     --header "<header>" \
     --data '{"name": "<registry_name>"}' \
     --url "https://gitlab.example.com/api/v4/groups/<group_id>/-/virtual_registries/packages/maven/registries"
```

- `<header>`: The [authentication header](../../../../api/rest/authentication.md).
- `<group_id>`: The top-level group ID.
- `<registry_name>`: The registry name.

For more information about other endpoints and examples related to Maven virtual registries, see the [API](../../../../api/maven_virtual_registries.md#manage-virtual-registries).

### Manage upstream registries

Prerequisites:

- You must have a valid Maven virtual registry ID.

When you create an upstream registry to an existing virtual registry, the upstream registry is added to the end of the list of available upstreams.

To create an upstream to an existing virtual registry, use the following command:

```shell
curl --fail-with-body \
     --request POST \
     --header "<header>" \
     --data '{ "name": "<upstream_name>", "url": "<upstream_url>", "username": "<upstream_username>", "password": "<upstream_password>", "cache_validity_hours": <upstream_cache_validity_hours> }' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/<registry_id>/upstreams"
```

- `<header>`: The [authentication header](../../../../api/rest/authentication.md).
- `<registry_id>`: The Maven virtual registry ID.
- `<upstream_name>`: The upstream registry name.
- `<upstream_url>`: The Maven upstream URL.
- `<upstream_username>`: The username to use with the Maven upstream. Required if an `<upstream_password>` is set.
- `<upstream_password>`: The password to use with the Maven upstream. Required if an `<upstream_username>` is set.
- `<upstream_cache_validity_hours>`: (optional) The [cache validity period](../_index.md#cache-validity-period) in hours. The default value is `24`. To turn off cache entry checks, set to `0`.
  - if the `<upstream_url>` is set to Maven central:
    - You must use the following URL: `https://repo1.maven.org/maven2`
    - The validity period is set to `0` by default. All files on Maven central are immutable.

`<upstream_username>` and `<upstream_password>` are optional. If not set, a public (anonymous) request is used to access the upstream.

For more information about other endpoints and examples, like updating the upstream registry position in the list, see the [API](../../../../api/maven_virtual_registries.md#manage-upstream-registries).

### Manage cache entries

If necessary, cache entries can be inspected or destroyed.

The next time the virtual registry receives a request for the file that was referenced by the destroyed cache entry, the list of upstreams is [walked again](../_index.md#caching-system) to find an upstream that can fulfill this request.

To learn more about managing cache entries, see the [API](../../../../api/maven_virtual_registries.md#manage-cache-entries).

## Use the virtual registry

After you [create](#create-and-manage-a-virtual-registry) a virtual registry, you must configure Maven clients to pull dependencies through the virtual registry.

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

{{< tab title="`mvn`" >}}

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

{{< tab title="`gradle`" >}}

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

{{< tab title="`sbt`" >}}

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

Make sure that the first argument of `Credentials` is `"GitLab Virtual Registry"`. This realm name must _exactly match_ the [Basic Auth realm](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Authentication#www-authenticate_and_proxy-authenticate_headers) sent by the Maven virtual registry.

{{< /tab >}}

{{< /tabs >}}

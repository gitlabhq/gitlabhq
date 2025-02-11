---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dependency proxy for packages
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3610) in GitLab 16.6 [with a flag](../../../../administration/feature_flags.md) named `packages_dependency_proxy_maven`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/415218) in GitLab 16.8. Feature flag `packages_dependency_proxy_maven` removed.

WARNING:
The dependency proxy is in [beta](../../../../policy/development_stages_support.md#beta). Review the documentation carefully before you use this feature.

The GitLab dependency proxy for packages is a local proxy for frequently pulled packages.
It is implemented as a pull-through cache that works at the project level.

Packages are pulled from the upstream package registry and automatically published to the
project's package registry. Subsequent identical requests are fulfilled with the project's
package registry. You can use the dependency proxy for packages to reduce unnecessary traffic
to the upstream registry.

## Enable the dependency proxy

To use the dependency proxy for packages, ensure your project is configured properly,
and that users who pull from the cache have the necessary authentication:

1. In the global configuration, if the following features are disabled, enable them:
   - The [`package` feature](../../../../administration/packages/_index.md#enable-or-disable-the-package-registry). Enabled by default.
   - The [`dependency_proxy` feature](../../../../administration/packages/dependency_proxy.md#turn-on-the-dependency-proxy). Enabled by default.
1. In the project settings, if the [`package` feature](../_index.md#disable-the-package-registry)
   is disabled, enable it. It is enabled by default.
1. [Add an authentication method](#configure-a-client). The dependency proxy supports the same [authentication methods](../_index.md#authenticate-with-the-registry) as the package registry:
   - [Personal access token](../../../profile/personal_access_tokens.md)
   - [Project deploy token](../../../project/deploy_tokens/_index.md)
   - [Group deploy token](../../../project/deploy_tokens/_index.md)
   - [Job token](../../../../ci/jobs/ci_job_token.md)

## Advanced caching

When possible, the dependency proxy for packages uses advanced caching to store packages in the project's package registry.

Advanced caching verifies the coherence between the project's package registry
and the upstream package registry. If the upstream registry has updated files,
the dependency proxy uses them to update the cached files.

When advanced caching is not supported, the dependency proxy falls back to the default behavior:

- If the requested file is found in the project's package registry, it is returned.
- If the file is not found, it is fetched from the upstream package registry.

Advanced caching support depends on how the upstream package registry
responds to dependency proxy requests, and on
which package format you use.

::Tabs

:::TabTitle Maven

| Package registry                                                                                                                         | Advanced caching supported? |
|------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|
| [GitLab](../../maven_repository/_index.md)                                                                                                | **{check-circle}** Yes      |
| [Maven Central](https://mvnrepository.com/repos/central)                                                                                 | **{check-circle}** Yes      |
| [Artifactory](https://jfrog.com/integration/maven-repository/)                                                                           | **{check-circle}** Yes      |
| [Sonatype Nexus](https://help.sonatype.com/en/maven-repositories.html)                                                                   | **{check-circle}** Yes      |
| [GitHub Packages](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-apache-maven-registry)    | **{dotted-circle}** No      |

::EndTabs

### Permissions

When the dependency proxy pulls a file, the following occurs:

1. The dependency proxy searches for a file in the project's package registry.
   This is a read operation.
1. The dependency proxy might publish a package file to the project's package registry.
   This is a write operation.

Whether both steps are executed depends on user permissions.
The dependency proxy uses the [same permissions as the package registry](../_index.md#package-registry-visibility-permissions).

| Project visibility | Minimum [role](../../../permissions.md#roles) | Can read package files? | Can write package files? | Behavior |
|--------------------|-------------------------------------------------------|-------------------------|--------------------------|----------|
| Public             | Anonymous                                             | **{dotted-circle}** No  | **{dotted-circle}** No   | Request rejected. |
| Public             | Guest                                                 | **{check-circle}** Yes  | **{dotted-circle}** No   | Package file returned from either the cache or the remote registry. |
| Public             | Developer                                             | **{check-circle}** Yes  | **{check-circle}** Yes   | Package file returned from either the cache or the remote registry. The file is published to the cache. |
| Internal           | Anonymous                                             | **{dotted-circle}** No  | **{dotted-circle}** No   | Request rejected |
| Internal           | Guest                                                 | **{check-circle}** Yes  | **{dotted-circle}** No   | Package file returned from either the cache or the remote registry. |
| Internal           | Developer                                             | **{check-circle}** Yes  | **{check-circle}** Yes   | Package file returned from either the cache or the remote registry. The file is published to the cache. |
| Private            | Anonymous                                             | **{dotted-circle}** No  | **{dotted-circle}** No   | Request rejected |
| Private            | Reporter                                              | **{check-circle}** Yes  | **{dotted-circle}** No   | Package file returned from either the cache or the remote registry. |
| Private           | Developer                                             | **{check-circle}** Yes  | **{check-circle}** Yes   | Package file returned from either the cache or the remote registry. The file is published to the cache. |

At a minimum, any user who can use the dependency proxy can also use the project's package registry.

To ensure the cache is properly filled over time, you should make sure a user with at least the Developer role pulls packages with the dependency proxy.

## Configure a client

Configuring a client for the dependency proxy is similar to configuring a client for the [package registry](../supported_functionality.md#pulling-packages).

### For Maven packages

For Maven packages, [all clients supported by the package registry](../../maven_repository/_index.md) are supported by the dependency proxy:

- `mvn`
- `gradle`
- `sbt`

For authentication, you can use all methods accepted by the [Maven package registry](../../maven_repository/_index.md#edit-the-client-configuration).
You should use the [Basic HTTP authentication](../../maven_repository/_index.md#basic-http-authentication) method as it is less complex.

To configure the client:

1. Follow the instructions in [Basic HTTP authentication](../../maven_repository/_index.md#basic-http-authentication).

   Make sure you use the endpoint URL `https://gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven`.

1. Complete the configuration for your client:

::Tabs

:::TabTitle mvn

[Basic HTTP authentication](../../maven_repository/_index.md#basic-http-authentication) is accepted.
However, you should use the [custom HTTP header authentication](../../maven_repository/_index.md#custom-http-header),
so that `mvn` uses fewer network requests.

In the `pom.xml` file add a `repository` element:

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven</url>
  </repository>
</repositories>
```

Where:

- `<project_id>` is the ID of the project to be used as a dependency proxy.
- `<id>` contains the name of the `<server>` used in the [authentication configuration](../../maven_repository/_index.md#basic-http-authentication).

By default, Maven Central is checked first through the [Super POM](https://maven.apache.org/guides/introduction/introduction-to-the-pom.html#Super_POM).
However, you might want to force `mvn` to check the GitLab endpoint first. To do this, follow the instructions from the [request forward](../../maven_repository/_index.md#additional-configuration-for-mvn).

:::TabTitle gradle

Add a `repositories` section to your [`build.gradle`](https://docs.gradle.org/current/userguide/tutorial_using_tasks.html) file.

- In Groovy DSL:

  ```groovy
  repositories {
      maven {
          url "https://gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven"
          name "GitLab"
          credentials(PasswordCredentials) {
              username = 'REPLACE_WITH_NAME'
              password = gitLabPrivateToken
          }
          authentication {
              basic(BasicAuthentication)
          }
      }
  }
  ```

- In Kotlin DSL:

  ```kotlin
  repositories {
      maven {
          url = uri("https://gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven")
          name = "GitLab"
          credentials(BasicAuthentication::class) {
              username = "REPLACE_WITH_NAME"
              password = findProperty("gitLabPrivateToken") as String?
          }
          authentication {
              create("basic", BasicAuthentication::class)
          }
      }
  }
  ```

In this example:

- `<project_id>` is the ID of the project to be used as a dependency proxy.
- `REPLACE_WITH_NAME` is explained in the [Basic HTTP authentication](../../maven_repository/_index.md#basic-http-authentication) section.

:::TabTitle sbt

In your [`build.sbt`](https://www.scala-sbt.org/1.x/docs/Directories.html#sbt+build+definition+files), add the following lines:

```scala
resolvers += ("gitlab" at "https://gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven")

credentials += Credentials("GitLab Packages Registry", "<host>", "<name>", "<token>")
```

In this example:

- `<project_id>` is the ID of the project to be used as a dependency proxy.
- `<host>` is the host present in the `<endpoint url>` without the protocol scheme or the port. Example: `gitlab.example.com`.
- `<name>` and `<token>` are explained in the [Basic HTTP authentication](../../maven_repository/_index.md#basic-http-authentication) section.

::EndTabs

## Configure the remote registry

The dependency proxy must be configured with:

- The URL of the remote package registry.
- Optional. The required credentials.

To set those parameters:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Packages and registries**.
1. Expand **Package registry**.
1. Under **Dependency Proxy**, complete the form for your package format:

::Tabs

:::TabTitle Maven

Any Maven package registry can be connected to the dependency proxy. You can
authorize the connection with the Maven package registry username and password.

To set or update the remote Maven package registry, update the following fields
in the form:

- `URL` - The URL of the remote registry.
- `Username` - Optional. The username to use with the remote registry.
- `Password` - Optional. The password to use with the remote registry.

You must either set both the username and password, or leave both fields empty.

::EndTabs

## Troubleshooting

### Manual file pull errors

You can pull files manually with cURL.
However, you might encounter one of the following responses:

- `404 Not Found` - The dependency proxy setting object was not found because it doesn't exist, or because the [requirements](#enable-the-dependency-proxy) were not fulfilled.
- `401 Unauthorized` - The user was properly authenticated but did not have the proper permissions to access the dependency proxy object.
- `403 Forbidden` - There was an issue with the [GitLab license level](#enable-the-dependency-proxy).
- `502 Bad Gateway` - The remote package registry could not fulfill the file request. Verify the [dependency proxy settings](#configure-the-remote-registry).
- `504 Gateway Timeout` - The remote package registry timed out. Verify the [dependency proxy settings](#configure-the-remote-registry).

::Tabs

:::TabTitle Maven

```shell
curl --fail-with-body --verbose "https://<username>:<personal access token>@gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven/<group id and artifact id>/<version>/<file_name>"
```

- `<username>` and `<personal access token>` are the credentials to access the dependency proxy of the GitLab instance.
- `<project_id>` is the project ID.
- `<group id and artifact id>` are the [Maven package group ID and artifact ID](https://maven.apache.org/pom.html#Maven_Coordinates) joined with a forward slash.
- `<version>` is the package version.
- `file_name` is the exact name of the file.

For example, given a package with:

- group ID: `com.my_company`.
- artifact ID: `my_package`.
- version: `1.2.3`.

The request to manually pull a package is:

```shell
curl --fail-with-body --verbose "https://<username>:<personal access token>@gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven/com/my_company/my_package/1.2.3/my_package-1.2.3.pom"
```

::EndTabs

---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Maven packages in the Package Registry **(FREE)**

Publish [Maven](https://maven.apache.org) artifacts in your project's Package Registry using Gradle.
Then, install the packages whenever you need to use them as a dependency.

For documentation of the specific API endpoints that the Maven package manager
client uses, see the [Maven API documentation](../../../api/packages/maven.md).

Learn how to build a [Gradle](../workflows/build_packages.md#gradle) package.

## Publish to the GitLab Package Registry

### Tokens

You need a token to publish a package. Different tokens are available depending on what you're trying to
achieve. For more information, review the [guidance on tokens](../package_registry/index.md#authenticate-with-the-registry).

- If your organization uses two-factor authentication (2FA), you must use a personal access token with the scope set to `api`.
- If you publish a package via CI/CD pipelines, you must use a CI job token.

Create a token and save it to use later in the process.

## Authenticate to the Package Registry with Gradle

### Authenticate with a personal access token or deploy token in Gradle

In [your `GRADLE_USER_HOME` directory](https://docs.gradle.org/current/userguide/directory_layout.html#dir:gradle_user_home),
create a file `gradle.properties` with the following content:

```properties
gitLabPrivateToken=REPLACE_WITH_YOUR_TOKEN
```

Your token name depends on which token you use.

| Token type            | Token name      |
| --------------------- | --------------- |
| Personal access token | `Private-Token` |
| Deploy token          | `Deploy-Token`  |

Add a `repositories` section to your
[`build.gradle`](https://docs.gradle.org/current/userguide/tutorial_using_tasks.html)
file:

```groovy
repositories {
    maven {
        url "https://gitlab.example.com/api/v4/groups/<group>/-/packages/maven"
        name "GitLab"
        credentials(HttpHeaderCredentials) {
            name = 'REPLACE_WITH_TOKEN_NAME'
            value = gitLabPrivateToken
        }
        authentication {
            header(HttpHeaderAuthentication)
        }
    }
}
```

Or add it to your `build.gradle.kts` file if you are using Kotlin DSL:

```kotlin
repositories {
    maven {
        url = uri("https://gitlab.example.com/api/v4/groups/<group>/-/packages/maven")
        name = "GitLab"
        credentials(HttpHeaderCredentials::class) {
            name = "REPLACE_WITH_TOKEN_NAME"
            value = findProperty("gitLabPrivateToken") as String?
        }
        authentication {
            create("header", HttpHeaderAuthentication::class)
        }
    }
}
```

### Authenticate with a CI job token in Gradle

To authenticate with a CI job token, add a `repositories` section to your
[`build.gradle`](https://docs.gradle.org/current/userguide/tutorial_using_tasks.html)
file:

```groovy
repositories {
    maven {
        url "${CI_API_V4_URL}/groups/<group>/-/packages/maven"
        name "GitLab"
        credentials(HttpHeaderCredentials) {
            name = 'Job-Token'
            value = System.getenv("CI_JOB_TOKEN")
        }
        authentication {
            header(HttpHeaderAuthentication)
        }
    }
}
```

Or add it to your `build.gradle.kts` file if you are using Kotlin DSL:

```kotlin
repositories {
    maven {
        url = uri("$CI_API_V4_URL/groups/<group>/-/packages/maven")
        name = "GitLab"
        credentials(HttpHeaderCredentials::class) {
            name = "Job-Token"
            value = System.getenv("CI_JOB_TOKEN")
        }
        authentication {
            create("header", HttpHeaderAuthentication::class)
        }
    }
}
```

### Naming convention

You can use one of three API endpoints to install a Maven package. You must publish a package to a project, but note which endpoint
you use to install the package. The option you choose determines the settings you add to your `pom.xml` file for publishing.

The three endpoints are:

- **Project-level**: Use when you have a few Maven packages that are not in the same GitLab group.
- **Group-level**: Use when installing packages from many different projects in the same GitLab group. GitLab does not guarantee the uniqueness of package names in the group. You can have two projects with the same package name and package version. As a result, GitLab serves whichever one is more recent.
- **Instance-level**: Use when installing many packages from different GitLab groups or in their own namespace.

**Only packages with the same path as the project** are exposed by the instance-level endpoint.

| Project             | Package                          | Instance-level endpoint available |
| ------------------- | -------------------------------- | --------------------------------- |
| `foo/bar`           | `foo/bar/1.0-SNAPSHOT`           | Yes                               |
| `gitlab-org/gitlab` | `foo/bar/1.0-SNAPSHOT`           | No                                |
| `gitlab-org/gitlab` | `gitlab-org/gitlab/1.0-SNAPSHOT` | Yes                               |

#### Endpoint URLs

| Endpoint | Endpoint URL                                                             | Additional information                                                                                                             |
| -------- | ------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| Project  | `https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven` | Replace `gitlab.example.com` with your domain name. Replace `<project_id>` with your project ID found on your project's homepage. |
| Group    | `https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/maven`   | Replace `gitlab.example.com` with your domain name. Replace `<group_id>` with your group ID found on your group's homepage.        |
| Instance | `https:///gitlab.example.com/api/v4/packages/maven`                      | Replace `gitlab.example.com` with your domain name.                                                                                |

In all cases, to publish a package, you need:

- A project-specific URL in the `distributionManagement` section.
- A `repository` and `distributionManagement` section.

### Edit the Groovy DSL or Kotlin DSL

The Gradle Groovy DSL `repositories` section should look like this:

```groovy
repositories {
    maven {
        url "<your_endpoint_url>"
        name "GitLab"
    }
}
```

In Kotlin DSL:

```kotlin
repositories {
    maven {
        url = uri("<your_endpoint_url>")
        name = "GitLab"
    }
}
```

- Replace `<your_endpoint_url>` with the [endpoint](#endpoint-urls) you chose.

## Publish using Gradle

Your token name depends on which token you use.

| Token type            | Token name      |
| --------------------- | --------------- |
| Personal access token | `Private-Token` |
| Deploy token          | `Deploy-Token`  |

To publish a package by using Gradle:

1. Add the Gradle plugin [`maven-publish`](https://docs.gradle.org/current/userguide/publishing_maven.html) to the plugins section:

   In Groovy DSL:

   ```groovy
   plugins {
       id 'java'
       id 'maven-publish'
   }
   ```

   In Kotlin DSL:

   ```kotlin
   plugins {
       java
       `maven-publish`
   }
   ```

1. Add a `publishing` section:

   In Groovy DSL:

   ```groovy
   publishing {
       publications {
           library(MavenPublication) {
               from components.java
           }
       }
       repositories {
           maven {
               url "https://gitlab.example.com/api/v4/projects/<PROJECT_ID>/packages/maven"
               credentials(HttpHeaderCredentials) {
                   name = "REPLACE_WITH_TOKEN_NAME"
                   value = gitLabPrivateToken // the variable resides in $GRADLE_USER_HOME/gradle.properties
               }
               authentication {
                   header(HttpHeaderAuthentication)
               }
           }
       }
   }
   ```

   In Kotlin DSL:

   ```kotlin
   publishing {
       publications {
           create<MavenPublication>("library") {
               from(components["java"])
           }
       }
       repositories {
           maven {
               url = uri("https://gitlab.example.com/api/v4/projects/<PROJECT_ID>/packages/maven")
               credentials(HttpHeaderCredentials::class) {
                   name = "REPLACE_WITH_TOKEN_NAME"
                   value =
                       findProperty("gitLabPrivateToken") as String? // the variable resides in $GRADLE_USER_HOME/gradle.properties
               }
               authentication {
                   create("header", HttpHeaderAuthentication::class)
               }
           }
       }
   }
   ```

1. Replace `PROJECT_ID` with your project ID, which you can find on your project's home page.

1. Run the publish task:

   ```shell
   gradle publish
   ```

Go to your project's **Packages and registries** page and view the published packages.

## Install a package

To install a package from the GitLab Package Registry, you must configure
the [remote and authenticate](#authenticate-to-the-package-registry-with-gradle).
After configuring the remote and authenticate, you can install a package from a project, group, or namespace.

If multiple packages have the same name and version, when you install
a package, the most recently-published package is retrieved.

Add a [dependency](https://docs.gradle.org/current/userguide/declaring_dependencies.html) to `build.gradle` in the dependencies section:

```groovy
dependencies {
    implementation 'com.mycompany.mydepartment:my-project:1.0-SNAPSHOT'
}
```

Or to `build.gradle.kts` if you are using Kotlin DSL:

```kotlin
dependencies {
    implementation("com.mycompany.mydepartment:my-project:1.0-SNAPSHOT")
}
```

## Helpful hints

For the complete list of helpful hints, see the [Maven documentation](../maven_repository/index.md#helpful-hints).

### Create Maven packages with GitLab CI/CD by using Gradle

You can create a package each time the `main` branch
is updated.

1. Authenticate with [a CI job token in Gradle](#authenticate-with-a-ci-job-token-in-gradle).

1. Add a `deploy` job to your `.gitlab-ci.yml` file:

   ```yaml
   deploy:
     image: gradle:6.5-jdk11
     script:
       - 'gradle publish'
     only:
       - main
   ```

1. Commit files to your repository.

When the pipeline is successful, the Maven package is created.

### Publishing a package with the same name or version

When you publish a package with the same name and version as an existing package, the new package
files are added to the existing package. You can still use the UI or API to access and view the
existing package's older assets.

Consider using the Packages API or the UI to delete older package versions.

### Do not allow duplicate Maven packages

To prevent users from publishing duplicate Maven packages, you can use the [GraphQl API](../../../api/graphql/reference/index.md#packagesettings) or the UI.

In the UI:

1. For your group, go to **Settings > Packages and registries**.
1. Expand the **Package Registry** section.
1. Turn on the **Do not allow duplicates** toggle.
1. Optional. To allow some duplicate packages, in the **Exceptions** box, enter a regex pattern that matches the names and/or versions of packages you want to allow.

Your changes are automatically saved.

### Request forwarding to Maven Central

FLAG:
By default, this feature is not available for self-managed. To make it available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `maven_central_request_forwarding`.
This feature is not available for SaaS users.

When a Maven package is not found in the Package Registry, the request is forwarded
to [Maven Central](https://search.maven.org/).

When the feature flag is enabled, administrators can disable this behavior in the
[Continuous Integration settings](../../admin_area/settings/continuous_integration.md).

There are many ways to configure your Maven project to request packages
in Maven Central from GitLab. Maven repositories are queried in a
[specific order](https://maven.apache.org/guides/mini/guide-multiple-repositories.html#repository-order).
By default, maven-central is usually checked first through the
[Super POM](https://maven.apache.org/guides/introduction/introduction-to-the-pom.html#Super_POM), so
GitLab needs to be configured to be queried before maven-central.

[Using GitLab as a mirror of the central proxy](../maven_repository/index.md#setting-gitlab-as-a-mirror-for-the-central-proxy) is one
way to force GitLab to be queried in place of maven-central.

Maven forwarding is restricted to only the project level and
group level [endpoints](#naming-convention). The instance-level endpoint
has naming restrictions that prevent it from being used for packages that don't follow that convention and also
introduces too much security risk for supply-chain style attacks.

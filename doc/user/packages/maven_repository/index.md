---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Maven packages in the Package Repository **(FREE)**

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) from GitLab Premium to GitLab Free in 13.3.

Publish [Maven](https://maven.apache.org) artifacts in your project's Package Registry.
Then, install the packages whenever you need to use them as a dependency.

For documentation of the specific API endpoints that the Maven package manager
client uses, see the [Maven API documentation](../../../api/packages/maven.md).

Learn how to build a [Maven](../workflows/build_packages.md#maven) or [Gradle](../workflows/build_packages.md#gradle) package.

## Authenticate to the Package Registry with Maven

To authenticate to the Package Registry, you need one of the following:

- A [personal access token](../../../user/profile/personal_access_tokens.md) with the scope set to `api`.
- A [deploy token](../../project/deploy_tokens/index.md) with the scope set to `read_package_registry`, `write_package_registry`, or both.
- A [CI_JOB_TOKEN](#authenticate-with-a-ci-job-token-in-maven).

### Authenticate with a personal access token in Maven

To use a personal access token, add this section to your
[`settings.xml`](https://maven.apache.org/settings.html) file.

The `name` must be `Private-Token`.

```xml
<settings>
  <servers>
    <server>
      <id>gitlab-maven</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>Private-Token</name>
            <value>REPLACE_WITH_YOUR_PERSONAL_ACCESS_TOKEN</value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
</settings>
```

### Authenticate with a deploy token in Maven

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213566) deploy token authentication in GitLab 13.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) from GitLab Premium to GitLab Free in 13.3.

To use a deploy token, add this section to your
[`settings.xml`](https://maven.apache.org/settings.html) file.

The `name` must be `Deploy-Token`.

```xml
<settings>
  <servers>
    <server>
      <id>gitlab-maven</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>Deploy-Token</name>
            <value>REPLACE_WITH_YOUR_DEPLOY_TOKEN</value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
</settings>
```

### Authenticate with a CI job token in Maven

To authenticate with a CI job token, add this section to your
[`settings.xml`](https://maven.apache.org/settings.html) file.

The `name` must be `Job-Token`.

```xml
<settings>
  <servers>
    <server>
      <id>gitlab-maven</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>Job-Token</name>
            <value>${CI_JOB_TOKEN}</value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
</settings>
```

Read more about [how to create Maven packages using GitLab CI/CD](#create-maven-packages-with-gitlab-cicd).

## Authenticate to the Package Registry with Gradle

To authenticate to the Package Registry, you need either a personal access token or deploy token.

- If you use a [personal access token](../../../user/profile/personal_access_tokens.md), set the scope to `api`.
- If you use a [deploy token](../../project/deploy_tokens/index.md), set the scope to `read_package_registry`, `write_package_registry`, or both.

### Authenticate with a personal access token in Gradle

In [your `GRADLE_USER_HOME` directory](https://docs.gradle.org/current/userguide/directory_layout.html#dir:gradle_user_home),
create a file `gradle.properties` with the following content:

```properties
gitLabPrivateToken=REPLACE_WITH_YOUR_PERSONAL_ACCESS_TOKEN
```

Add a `repositories` section to your
[`build.gradle`](https://docs.gradle.org/current/userguide/tutorial_using_tasks.html)
file:

```groovy
repositories {
    maven {
        url "https://gitlab.example.com/api/v4/groups/<group>/-/packages/maven"
        name "GitLab"
        credentials(HttpHeaderCredentials) {
            name = 'Private-Token'
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
            name = "Private-Token"
            value = findProperty("gitLabPrivateToken") as String?
        }
        authentication {
            create("header", HttpHeaderAuthentication::class)
        }
    }
}
```

### Authenticate with a deploy token in Gradle

To authenticate with a deploy token, add a `repositories` section to your
[`build.gradle`](https://docs.gradle.org/current/userguide/tutorial_using_tasks.html)
file:

```groovy
repositories {
    maven {
        url "https://gitlab.example.com/api/v4/groups/<group>/-/packages/maven"
        name "GitLab"
        credentials(HttpHeaderCredentials) {
            name = 'Deploy-Token'
            value = '<deploy-token>'
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
            name = "Deploy-Token"
            value = "<deploy-token>"
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

## Use the GitLab endpoint for Maven packages

To use the GitLab endpoint for Maven packages, choose an option:

- **Project-level**: To publish Maven packages to a project, use a project-level endpoint.
  To install Maven packages, use a project-level endpoint when you have few Maven packages
  and they are not in the same GitLab group.
- **Group-level**: Use a group-level endpoint when you want to install packages from
  many different projects in the same GitLab group.
- **Instance-level**: Use an instance-level endpoint when you want to install many
  packages from different GitLab groups or in their own namespace.

The option you choose determines the settings you add to your `pom.xml` file.

In all cases, to publish a package, you need:

- A project-specific URL in the `distributionManagement` section.
- A `repository` and `distributionManagement` section.

### Project-level Maven endpoint

The relevant `repository` section of your `pom.xml`
in Maven should look like this:

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </repository>
</repositories>
<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </repository>
  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </snapshotRepository>
</distributionManagement>
```

The corresponding section in Gradle Groovy DSL would be:

```groovy
repositories {
    maven {
        url "https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven"
        name "GitLab"
    }
}
```

In Kotlin DSL:

```kotlin
repositories {
    maven {
        url = uri("https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven")
        name = "GitLab"
    }
}
```

- The `id` is what you [defined in `settings.xml`](#authenticate-to-the-package-registry-with-maven).
- The `PROJECT_ID` is your project ID, which you can view on your project's home page.
- Replace `gitlab.example.com` with your domain name.
- For retrieving artifacts, use either the
  [URL-encoded](../../../api/index.md#namespaced-path-encoding) path of the project
  (like `group%2Fproject`) or the project's ID (like `42`). However, only the
  project's ID can be used for publishing.

### Group-level Maven endpoint

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) from GitLab Premium to GitLab Free in 13.3.

If you rely on many packages, it might be inefficient to include the `repository` section
with a unique URL for each package. Instead, you can use the group-level endpoint for
all the Maven packages stored within one GitLab group. Only packages you have access to
are available for download.

The group-level endpoint works with any package names, so you
have more flexibility in naming, compared to the [instance-level endpoint](#instance-level-maven-endpoint).
However, GitLab does not guarantee the uniqueness of package names within
the group. You can have two projects with the same package name and package
version. As a result, GitLab serves whichever one is more recent.

This example shows the relevant `repository` section of your `pom.xml` file.
You still need a project-specific URL for publishing a package in
the `distributionManagement` section:

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/groups/GROUP_ID/-/packages/maven</url>
  </repository>
</repositories>
<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </repository>
  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </snapshotRepository>
</distributionManagement>
```

For Gradle, the corresponding `repositories` section in Groovy DSL would look like:

```groovy
repositories {
    maven {
        url "https://gitlab.example.com/api/v4/groups/GROUP_ID/-/packages/maven"
        name "GitLab"
    }
}
```

In Kotlin DSL:

```kotlin
repositories {
    maven {
        url = uri("https://gitlab.example.com/api/v4/groups/GROUP_ID/-/packages/maven")
        name = "GitLab"
    }
}
```

- For the `id`, use what you [defined in `settings.xml`](#authenticate-to-the-package-registry-with-maven).
- For `GROUP_ID`, use your group ID, which you can view on your group's home page.
- For `PROJECT_ID`, use your project ID, which you can view on your project's home page.
- Replace `gitlab.example.com` with your domain name.
- For retrieving artifacts, use either the
  [URL-encoded](../../../api/index.md#namespaced-path-encoding) path of the group
  (like `group%2Fsubgroup`) or the group's ID (like `12`).

### Instance-level Maven endpoint

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) from GitLab Premium to GitLab Free in 13.3.

If you rely on many packages, it might be inefficient to include the `repository` section
with a unique URL for each package. Instead, you can use the instance-level endpoint for
all Maven packages stored in GitLab. All packages you have access to are available
for download.

**Only packages that have the same path as the project** are exposed by
the instance-level endpoint.

| Project             | Package                          | Instance-level endpoint available |
| ------------------- | -------------------------------- | --------------------------------- |
| `foo/bar`           | `foo/bar/1.0-SNAPSHOT`           | Yes                               |
| `gitlab-org/gitlab` | `foo/bar/1.0-SNAPSHOT`           | No                                |
| `gitlab-org/gitlab` | `gitlab-org/gitlab/1.0-SNAPSHOT` | Yes                               |

This example shows how relevant `repository` section of your `pom.xml`.
You still need a project-specific URL in the `distributionManagement` section.

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/packages/maven</url>
  </repository>
</repositories>
<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </repository>
  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </snapshotRepository>
</distributionManagement>
```

The corresponding repositories section in Gradle Groovy DSL would look like:

```groovy
repositories {
    maven {
        url "https://gitlab.example.com/api/v4/packages/maven"
        name "GitLab"
    }
}
```

In Kotlin DSL:

```kotlin
repositories {
    maven {
        url = uri("https://gitlab.example.com/api/v4/packages/maven")
        name = "GitLab"
    }
}
```

- The `id` is what you [defined in `settings.xml`](#authenticate-to-the-package-registry-with-maven).
- The `PROJECT_ID` is your project ID, which you can view on your project's home page.
- Replace `gitlab.example.com` with your domain name.
- For retrieving artifacts, use either the
  [URL-encoded](../../../api/index.md#namespaced-path-encoding) path of the project
  (like `group%2Fproject`) or the project's ID (like `42`). However, only the
  project's ID can be used for publishing.

## Publish a package

After you have set up the [remote and authentication](#authenticate-to-the-package-registry-with-maven)
and [configured your project](#use-the-gitlab-endpoint-for-maven-packages),
publish a Maven package to your project.

### Publish by using Maven

To publish a package by using Maven:

```shell
mvn deploy
```

If the deploy is successful, the build success message should be displayed:

```shell
...
[INFO] BUILD SUCCESS
...
```

The message should also show that the package was published to the correct location:

```shell
Uploading to gitlab-maven: https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/mydepartment/my-project/1.0-SNAPSHOT/my-project-1.0-20200128.120857-1.jar
```

### Publish by using Gradle

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
                   name = "Private-Token"
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
                   name = "Private-Token"
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

1. Replace `PROJECT_ID` with your project ID, which can be found on your project's home page.

1. Run the publish task:

   ```shell
   gradle publish
   ```

Now navigate to your project's **Packages and registries** page and view the published artifacts.

### Publishing a package with the same name or version

When you publish a package with the same name and version as an existing package, the new package
files are added to the existing package. You can still use the UI or API to access and view the
existing package's older files.

To delete these older package versions, consider using the Packages API or the UI.

#### Do not allow duplicate Maven packages

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/296895) in GitLab 13.9.
> - [Required permissions](https://gitlab.com/gitlab-org/gitlab/-/issues/350682) changed from developer to maintainer in GitLab 15.0.

To prevent users from publishing duplicate Maven packages, you can use the [GraphQl API](../../../api/graphql/reference/index.md#packagesettings) or the UI.

In the UI:

1. For your group, go to **Settings > Packages and registries**.
1. Expand the **Package Registry** section.
1. Turn on the **Reject duplicates** toggle.
1. Optional. To allow some duplicate packages, in the **Exceptions** box, enter a regex pattern that matches the names and/or versions of packages you want to allow.

Your changes are automatically saved.

## Install a package

To install a package from the GitLab Package Registry, you must configure
the [remote and authenticate](#authenticate-to-the-package-registry-with-maven).
When this is completed, you can install a package from a project,
group, or namespace.

If multiple packages have the same name and version, when you install
a package, the most recently-published package is retrieved.

### Use Maven with `mvn install`

To install a package by using `mvn install`:

1. Add the dependency manually to your project `pom.xml` file.
   To add the example created earlier, the XML would be:

   ```xml
   <dependency>
     <groupId>com.mycompany.mydepartment</groupId>
     <artifactId>my-project</artifactId>
     <version>1.0-SNAPSHOT</version>
   </dependency>
   ```

1. In your project, run the following:

   ```shell
   mvn install
   ```

The message should show that the package is downloading from the Package Registry:

```shell
Downloading from gitlab-maven: http://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/mydepartment/my-project/1.0-SNAPSHOT/my-project-1.0-20200128.120857-1.pom
```

### Use Maven with `mvn dependency:get`

You can install packages by using the Maven `dependency:get` [command](https://maven.apache.org/plugins/maven-dependency-plugin/get-mojo.html) directly.

1. In your project directory, run:

   ```shell
   mvn dependency:get -Dartifact=com.nickkipling.app:nick-test-app:1.1-SNAPSHOT -DremoteRepositories=gitlab-maven::::<gitlab endpoint url>  -s <path to settings.xml>
   ```

   - `<gitlab endpoint url>` is the URL of the GitLab [endpoint](#use-the-gitlab-endpoint-for-maven-packages).
   - `<path to settings.xml>` is the path to the `settings.xml` file that contains the [authentication details](#authenticate-to-the-package-registry-with-maven).

NOTE:
The repository IDs in the command(`gitlab-maven`) and the `settings.xml` file must match.

The message should show that the package is downloading from the Package Registry:

```shell
Downloading from gitlab-maven: http://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/mydepartment/my-project/1.0-SNAPSHOT/my-project-1.0-20200128.120857-1.pom
```

NOTE:
In the GitLab UI, on the Package Registry page for Maven, you can view and copy these commands.

### Use Gradle

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

### Request forwarding to Maven Central

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362657) behind a [feature flag](../../feature_flags.md), disabled by default in GitLab 15.4

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `maven_central_request_forwarding`.
On GitLab.com, this feature is not available.

When a Maven package is not found in the Package Registry, the request is forwarded
to [Maven Central](https://search.maven.org/).

When the feature flag is enabled, administrators can disable this behavior in the
[Continuous Integration settings](../../admin_area/settings/continuous_integration.md).

There are many ways to configure your Maven project so that it will request packages
in Maven Central from GitLab. Maven repositories are queried in a
[specific order](https://maven.apache.org/guides/mini/guide-multiple-repositories.html#repository-order).
By default, maven-central is usually checked first through the
[Super POM](https://maven.apache.org/guides/introduction/introduction-to-the-pom.html#Super_POM), so
GitLab needs to be configured to be queried before maven-central.

[Using GitLab as a mirror of the central proxy](#setting-gitlab-as-a-mirror-for-the-central-proxy) is one
way to force GitLab to be queried in place of maven-central.

Maven forwarding is restricted to only the [project level](#project-level-maven-endpoint) and
[group level](#group-level-maven-endpoint) endpoints. The [instance level endpoint](#instance-level-maven-endpoint)
has naming restrictions that prevent it from being used for packages that don't follow that convention and also
introduces too much security risk for supply-chain style attacks.

#### Setting GitLab as a mirror for the central proxy

To ensure all package requests are sent to GitLab instead of Maven Central,
you can override Maven Central as the central repository by adding a `<mirror>`
section to your `settings.xml`:

```xml
<settings>
  <servers>
    <server>
      <id>central-proxy</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>Private-Token</name>
            <value>{personal_access_token}</value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
  <mirrors>
    <mirror>
      <id>central-proxy</id>
      <name>GitLab proxy of central repo</name>
      <url>https://gitlab.example.com/api/v4/projects/{project_id}/packages/maven</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
```

## Remove a package

For your project, go to **Packages and registries > Package Registry**.

To remove a package, select the red trash icon or, from the package details, the **Delete** button.

## Create Maven packages with GitLab CI/CD

After you have configured your repository to use the Package Repository for Maven,
you can configure GitLab CI/CD to build new packages automatically.

### Create Maven packages with GitLab CI/CD by using Maven

You can create a new package each time the `main` branch is updated.

1. Create a `ci_settings.xml` file that serves as Maven's `settings.xml` file.

1. Add the `server` section with the same ID you defined in your `pom.xml` file.
   For example, use `gitlab-maven` as the ID:

   ```xml
   <settings xmlns="http://maven.apache.org/SETTINGS/1.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">
     <servers>
       <server>
         <id>gitlab-maven</id>
         <configuration>
           <httpHeaders>
             <property>
               <name>Job-Token</name>
               <value>${CI_JOB_TOKEN}</value>
             </property>
           </httpHeaders>
         </configuration>
       </server>
     </servers>
   </settings>
   ```

1. Make sure your `pom.xml` file includes the following.
   You can either let Maven use the [predefined CI/CD variables](../../../ci/variables/predefined_variables.md), as shown in this example,
   or you can hard code your server's hostname and project's ID.

   ```xml
   <repositories>
     <repository>
       <id>gitlab-maven</id>
       <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
     </repository>
   </repositories>
   <distributionManagement>
     <repository>
       <id>gitlab-maven</id>
       <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
     </repository>
     <snapshotRepository>
       <id>gitlab-maven</id>
       <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
     </snapshotRepository>
   </distributionManagement>
   ```

1. Add a `deploy` job to your `.gitlab-ci.yml` file:

   ```yaml
   deploy:
     image: maven:3.6-jdk-11
     script:
       - 'mvn deploy -s ci_settings.xml'
     only:
       - main
   ```

1. Push those files to your repository.

The next time the `deploy` job runs, it copies `ci_settings.xml` to the
user's home location. In this example:

- The user is `root`, because the job runs in a Docker container.
- Maven uses the configured CI/CD variables.

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

When the pipeline is successful, the package is created.

### Version validation

The version string is validated by using the following regex.

```ruby
\A(?!.*\.\.)[\w+.-]+\z
```

You can play around with the regex and try your version strings on [this regular expression editor](https://rubular.com/r/rrLQqUXjfKEoL6).

## Troubleshooting

To improve performance, Maven caches files related to a package. If you encounter issues, clear
the cache with these commands:

```shell
rm -rf ~/.m2/repository
```

If you're using Gradle, run this command to clear the cache:

```shell
rm -rf ~/.gradle/caches # Or replace ~/.gradle with your custom GRADLE_USER_HOME
```

### Review network trace logs

If you are having issues with the Maven Repository, you may want to review network trace logs.

For example, try to run `mvn deploy` locally with a PAT token and use these options:

```shell
mvn deploy \
-Dorg.slf4j.simpleLogger.log.org.apache.maven.wagon.providers.http.httpclient=trace \
-Dorg.slf4j.simpleLogger.log.org.apache.maven.wagon.providers.http.httpclient.wire=trace
```

WARNING:
When you set these options, all network requests are logged and a large amount of output is generated.

### Useful Maven command-line options

There are some [Maven command-line options](https://maven.apache.org/ref/current/maven-embedder/cli.html)
that you can use when performing tasks with GitLab CI/CD.

- File transfer progress can make the CI logs hard to read.
  Option `-ntp,--no-transfer-progress` was added in
  [3.6.1](https://maven.apache.org/docs/3.6.1/release-notes.html#User_visible_Changes).
  Alternatively, look at `-B,--batch-mode`
  [or lower level logging changes.](https://stackoverflow.com/questions/21638697/disable-maven-download-progress-indication)

- Specify where to find the `pom.xml` file (`-f,--file`):

  ```yaml
  package:
    script:
      - 'mvn --no-transfer-progress -f helloworld/pom.xml package'
  ```

- Specify where to find the user settings (`-s,--settings`) instead of
  [the default location](https://maven.apache.org/settings.html). There's also a `-gs,--global-settings` option:

  ```yaml
  package:
    script:
      - 'mvn -s settings/ci.xml package'
  ```

### Verify your Maven settings

If you encounter issues within CI/CD that relate to the `settings.xml` file, try adding
an additional script task or job to [verify the effective settings](https://maven.apache.org/plugins/maven-help-plugin/effective-settings-mojo.html).

The help plugin can also provide
[system properties](https://maven.apache.org/plugins/maven-help-plugin/system-mojo.html), including environment variables:

```yaml
mvn-settings:
  script:
    - 'mvn help:effective-settings'

package:
  script:
    - 'mvn help:system'
    - 'mvn package'
```

## Supported CLI commands

The GitLab Maven repository supports the following Maven CLI commands:

- `mvn deploy`: Publish your package to the Package Registry.
- `mvn install`: Install packages specified in your Maven project.
- `mvn dependency:get`: Install a specific package.

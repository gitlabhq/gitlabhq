---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maven packages in the package registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Publish [Maven](https://maven.apache.org) artifacts in your project's package registry.
Then, install the packages whenever you need to use them as a dependency.

For documentation of the specific API endpoints that the Maven package manager
client uses, see the [Maven API documentation](../../../api/packages/maven.md).

Supported clients:

- `mvn`. Learn how to build a [Maven](../workflows/build_packages.md#maven) package.
- `gradle`. Learn how to build a [Gradle](../workflows/build_packages.md#gradle) package.
- `sbt`.

## Publish to the GitLab package registry

### Authenticate to the package registry

You need a token to publish a package. There are different tokens available depending on what you're trying to achieve. For more information, review the [guidance on tokens](../package_registry/_index.md#authenticate-with-the-registry).

Create a token and save it to use later in the process.

Do not use authentication methods other than the methods documented here. Undocumented authentication methods might be removed in the future.

#### Edit the client configuration

Update your configuration to authenticate to the Maven repository with HTTP.

##### Custom HTTP header

You must add the authentication details to the configuration file
for your client.

::Tabs

:::TabTitle `mvn`

| Token type            | Name must be    | Token                                                                  |
| --------------------- | --------------- | ---------------------------------------------------------------------- |
| Personal access token | `Private-Token` | Paste token as-is, or define an environment variable to hold the token |
| Deploy token          | `Deploy-Token`  | Paste token as-is, or define an environment variable to hold the token |
| CI Job token          | `Job-Token`     | `${CI_JOB_TOKEN}`                                                      |

NOTE:
The `<name>` field must be named to match the token you chose.

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

:::TabTitle `gradle`

| Token type            | Name must be    | Token                                                                  |
| --------------------- | --------------- | ---------------------------------------------------------------------- |
| Personal access token | `Private-Token` | Paste token as-is, or define an environment variable to hold the token |
| Deploy token          | `Deploy-Token`  | Paste token as-is, or define an environment variable to hold the token |
| CI Job token          | `Job-Token`     | `System.getenv("CI_JOB_TOKEN")`                                        |

NOTE:
The `<name>` field must be named to match the token you chose.

In [your `GRADLE_USER_HOME` directory](https://docs.gradle.org/current/userguide/directory_layout.html#dir:gradle_user_home),
create a file `gradle.properties` with the following content:

```properties
gitLabPrivateToken=REPLACE_WITH_YOUR_TOKEN
```

Add a `repositories` section to your
[`build.gradle`](https://docs.gradle.org/current/userguide/tutorial_using_tasks.html)
file:

- In Groovy DSL:

  ```groovy
  repositories {
      maven {
          url "https://gitlab.example.com/api/v4/groups/<group>/-/packages/maven"
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
          url = uri("https://gitlab.example.com/api/v4/groups/<group>/-/packages/maven")
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

::EndTabs

##### Basic HTTP Authentication

You can also use basic HTTP authentication to authenticate to the Maven package registry.

::Tabs

:::TabTitle `mvn`

| Token type            | Name must be                 | Token                                                                  |
| --------------------- | ---------------------------- | ---------------------------------------------------------------------- |
| Personal access token | The username of the user     | Paste token as-is, or define an environment variable to hold the token |
| Deploy token          | The username of deploy token | Paste token as-is, or define an environment variable to hold the token |
| CI Job token          | `gitlab-ci-token`            | `${CI_JOB_TOKEN}`                                                      |

Add the following section to your
[`settings.xml`](https://maven.apache.org/settings.html) file.

```xml
<settings>
  <servers>
    <server>
      <id>gitlab-maven</id>
      <username>REPLACE_WITH_NAME</username>
      <password>REPLACE_WITH_TOKEN</password>
      <configuration>
        <authenticationInfo>
          <userName>REPLACE_WITH_NAME</userName>
          <password>REPLACE_WITH_TOKEN</password>
        </authenticationInfo>
      </configuration>
    </server>
  </servers>
</settings>
```

:::TabTitle `gradle`

| Token type            | Name must be                 | Token                                                                  |
| --------------------- | ---------------------------- | ---------------------------------------------------------------------- |
| Personal access token | The username of the user     | Paste token as-is, or define an environment variable to hold the token |
| Deploy token          | The username of deploy token | Paste token as-is, or define an environment variable to hold the token |
| CI Job token          | `gitlab-ci-token`            | `System.getenv("CI_JOB_TOKEN")`                                        |

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
          url "https://gitlab.example.com/api/v4/groups/<group>/-/packages/maven"
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
          url = uri("https://gitlab.example.com/api/v4/groups/<group>/-/packages/maven")
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

:::TabTitle `sbt`

| Token type            | Name must be                 | Token                                                                  |
|-----------------------|------------------------------|------------------------------------------------------------------------|
| Personal access token | The username of the user     | Paste token as-is, or define an environment variable to hold the token |
| Deploy token          | The username of deploy token | Paste token as-is, or define an environment variable to hold the token |
| CI Job token          | `gitlab-ci-token`            | `sys.env.get("CI_JOB_TOKEN").get`                                      |

Authentication for [SBT](https://www.scala-sbt.org/index.html) is based on
[basic HTTP Authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication).
You must to provide a name and a password.

NOTE:
The name field must be named to match the token you chose.

To install a package from the Maven GitLab package registry by using `sbt`, you must configure
a [Maven resolver](https://www.scala-sbt.org/1.x/docs/Resolvers.html#Maven+resolvers).
If you're accessing a private or an internal project or group, you need to set up
[credentials](https://www.scala-sbt.org/1.x/docs/Publishing.html#Credentials).
After configuring the resolver and authentication, you can install a package
from a project, group, or namespace.

In your [`build.sbt`](https://www.scala-sbt.org/1.x/docs/Directories.html#sbt+build+definition+files), add the following lines:

```scala
resolvers += ("gitlab" at "<endpoint url>")

credentials += Credentials("GitLab Packages Registry", "<host>", "<name>", "<token>")
```

In this example:

- `<endpoint url>` is the [endpoint URL](#endpoint-urls).
  Example: `https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven`.
- `<host>` is the host present in the `<endpoint url>` without the protocol
  scheme or the port. Example: `gitlab.example.com`.
- `<name>` and `<token>` are explained in the table above.

::EndTabs

### Naming convention

You can use one of three endpoints to install a Maven package. You must publish a package to a project, but the endpoint you choose determines the settings you add to your `pom.xml` file for publishing.

The three endpoints are:

- **Project-level**: Use when you have a few Maven packages and they are not in the same GitLab group.
- **Group-level**: Use when you want to install packages from many different projects in the same GitLab group. GitLab does not guarantee the uniqueness of package names within the group. You can have two projects with the same package name and package version. As a result, GitLab serves whichever one is more recent.
- **Instance-level**: Use when you have many packages in different GitLab groups or in their own namespace.

For the instance-level endpoint, ensure the relevant section of your `pom.xml` in Maven looks like this:

```xml
  <groupId>group-slug.subgroup-slug</groupId>
  <artifactId>project-slug</artifactId>
```

**Only packages that have the same path as the project** are exposed by the instance-level endpoint.

| Project             | Package                          | Instance-level endpoint available |
| ------------------- | -------------------------------- | --------------------------------- |
| `foo/bar`           | `foo/bar/1.0-SNAPSHOT`           | Yes                               |
| `gitlab-org/gitlab` | `foo/bar/1.0-SNAPSHOT`           | No                                |
| `gitlab-org/gitlab` | `gitlab-org/gitlab/1.0-SNAPSHOT` | Yes                               |

#### Endpoint URLs

| Endpoint | Endpoint URL for `pom.xml`                                               | Additional information |
|----------|--------------------------------------------------------------------------|------------------------|
| Project  | `https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven` | Replace `gitlab.example.com` with your domain name. Replace `<project_id>` with your project ID, found on your [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id). |
| Group    | `https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/maven`   | Replace `gitlab.example.com` with your domain name. Replace `<group_id>` with your group ID, found on your group's homepage. |
| Instance | `https://gitlab.example.com/api/v4/packages/maven`                       | Replace `gitlab.example.com` with your domain name. |

### Edit the configuration file for publishing

You must add publishing details to the configuration file for your client.

::Tabs

:::TabTitle `mvn`

No matter which endpoint you choose, you must have:

- A project-specific URL in the `distributionManagement` section.
- A `repository` and `distributionManagement` section.

The relevant `repository` section of your `pom.xml` in Maven should look like this:

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url><your_endpoint_url></url>
  </repository>
</repositories>
<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven</url>
  </repository>
  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven</url>
  </snapshotRepository>
</distributionManagement>
```

- The `id` is what you [defined in `settings.xml`](#edit-the-client-configuration).
- The `<your_endpoint_url>` depends on which [endpoint](#endpoint-urls) you choose.
- Replace `gitlab.example.com` with your domain name.

:::TabTitle `gradle`

To publish a package by using Gradle:

1. Add the Gradle plugin [`maven-publish`](https://docs.gradle.org/current/userguide/publishing_maven.html) to the plugins section:

   - In Groovy DSL:

     ```groovy
     plugins {
         id 'java'
         id 'maven-publish'
     }
     ```

   - In Kotlin DSL:

     ```kotlin
     plugins {
         java
         `maven-publish`
     }
     ```

1. Add a `publishing` section:

   - In Groovy DSL:

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

   - In Kotlin DSL:

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

::EndTabs

## Publish a package

WARNING:
Using the `DeployAtEnd` option can cause an upload to be rejected with `400 bad request {"message":"Validation failed: Name has already been taken"}`. For more details,
see [issue 424238](https://gitlab.com/gitlab-org/gitlab/-/issues/424238).

After you have set up the [authentication](#authenticate-to-the-package-registry)
and [chosen an endpoint for publishing](#naming-convention),
publish a Maven package to your project.

::Tabs

:::TabTitle `mvn`

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
Uploading to gitlab-maven: https://example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/mydepartment/my-project/1.0-SNAPSHOT/my-project-1.0-20200128.120857-1.jar
```

:::TabTitle `gradle`

Run the publish task:

```shell
gradle publish
```

Go to your project's **Packages and registries** page and view the published packages.

:::TabTitle `sbt`

Configure the `publishTo` setting in your `build.sbt` file:

```scala
publishTo := Some("gitlab" at "<endpoint url>")
```

Ensure the credentials are referenced correctly. See the [`sbt` documentation](https://www.scala-sbt.org/1.x/docs/Publishing.html#Credentials) for more information.

To publish a package using `sbt`:

```shell
sbt publish
```

If the deploy is successful, the build success message is displayed:

```shell
[success] Total time: 1 s, completed Jan 28, 2020 12:08:57 PM
```

Check the success message to ensure the package was published to the
correct location:

```shell
[info]  published my-project_2.12 to https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/my-project_2.12/0.1.1-SNAPSHOT/my-project_2.12-0.1.1-SNAPSHOT.pom
```

::EndTabs

## Install a package

To install a package from the GitLab package registry, you must configure
the [remote and authenticate](#authenticate-to-the-package-registry).
When this is completed, you can install a package from a project,
group, or namespace.

If multiple packages have the same name and version, when you install
a package, the most recently-published package is retrieved.

In case there are not enough permissions to read the most recently-published
package than `403 Forbidden` is returning.

::Tabs

:::TabTitle `mvn`

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

The message should show that the package is downloading from the package registry:

```shell
Downloading from gitlab-maven: http://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/mydepartment/my-project/1.0-SNAPSHOT/my-project-1.0-20200128.120857-1.pom
```

You can also install packages by using the Maven [`dependency:get` command](https://maven.apache.org/plugins/maven-dependency-plugin/get-mojo.html) directly.

1. In your project directory, run:

   ```shell
   mvn dependency:get -Dartifact=com.nickkipling.app:nick-test-app:1.1-SNAPSHOT -DremoteRepositories=gitlab-maven::::<gitlab endpoint url>  -s <path to settings.xml>
   ```

   - `<gitlab endpoint url>` is the URL of the GitLab [endpoint](#endpoint-urls).
   - `<path to settings.xml>` is the path to the `settings.xml` file that contains the [authentication details](#edit-the-client-configuration).

NOTE:
The repository IDs in the command(`gitlab-maven`) and the `settings.xml` file must match.

The message should show that the package is downloading from the package registry:

```shell
Downloading from gitlab-maven: http://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/mydepartment/my-project/1.0-SNAPSHOT/my-project-1.0-20200128.120857-1.pom
```

:::TabTitle `gradle`

To install a package by using `gradle`:

1. Add a [dependency](https://docs.gradle.org/current/userguide/declaring_dependencies.html) to `build.gradle` in the dependencies section:

   - In Groovy DSL:

     ```groovy
     dependencies {
         implementation 'com.mycompany.mydepartment:my-project:1.0-SNAPSHOT'
     }
     ```

   - In Kotlin DSL:

     ```kotlin
     dependencies {
         implementation("com.mycompany.mydepartment:my-project:1.0-SNAPSHOT")
     }
     ```

1. In your project, run the following:

   ```shell
   gradle install
   ```

:::TabTitle `sbt`

To install a package by using `sbt`:

1. Add an [inline dependency](https://www.scala-sbt.org/1.x/docs/Library-Management.html#Dependencies) to `build.sbt`:

   ```scala
   libraryDependencies += "com.mycompany.mydepartment" % "my-project" % "8.4"
   ```

1. In your project, run the following:

   ```shell
   sbt update
   ```

::EndTabs

### Proxy downloads for Maven packages

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/507768) in GitLab 17.8.

The GitLab Maven package registry uses [remote included checksums](https://maven.apache.org/resolver/expected-checksums.html#remote-included-checksums).
When you download a file, the registry proxies the file and sends both the file and its related checksums to Maven clients in a single request.

Using remote included checksums with recent Maven clients:

- Reduces the number of web requests from the clients to the GitLab Maven package registry.
- Decreases the load on your GitLab instance.
- Improves the client command execution time.

Due to technical constraints, when you use object storage, the Maven package registry ignores the [proxy download](../../../administration/object_storage.md#proxy-download)
setting in the object storage configuration for `packages`.
Instead, proxy download is always enabled for Maven package registry downloads.

NOTE:
If you don't use object storage, this behavior has no impact on your instance.

## CI/CD integration for Maven packages

You can use CI/CD to automatically build, test, and publish Maven packages.
The examples in this section cover scenarios like:

- Multi-module projects
- Versioned releases
- Conditional publishing
- Integration with code quality and security scans

You can adapt and combine these examples to suit your specific project needs.

Remember to adjust the Maven version, Java version, and other specifics according to your project requirements. Also, make sure you properly configured the necessary credentials and settings for publishing to the GitLab package registry.

### Basic Maven package build and publish

This example configures a pipeline that builds and publishes a Maven package:

```yaml
default:
  image: maven:3.8.5-openjdk-17
  cache:
    paths:
      - .m2/repository/
      - target/

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

stages:
  - build
  - test
  - publish

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile

test:
  stage: test
  script:
    - mvn $MAVEN_CLI_OPTS test

publish:
  stage: publish
  script:
    - mvn $MAVEN_CLI_OPTS deploy
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### Multi-module Maven project with parallel jobs

For larger projects with multiple modules, you can use parallel jobs to speed up the build process:

```yaml
default:
  image: maven:3.8.5-openjdk-17
  cache:
    paths:
      - .m2/repository/
      - target/

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

stages:
  - build
  - test
  - publish

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile

test:
  stage: test
  parallel:
    matrix:
      - MODULE: [module1, module2, module3]
  script:
    - mvn $MAVEN_CLI_OPTS test -pl $MODULE

publish:
  stage: publish
  script:
    - mvn $MAVEN_CLI_OPTS deploy
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### Versioned releases with tags

This example creates versioned releases when a tag is pushed:

```yaml
default:
  image: maven:3.8.5-openjdk-17
  cache:
    paths:
      - .m2/repository/
      - target/

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

stages:
  - build
  - test
  - publish
  - release

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile

test:
  stage: test
  script:
    - mvn $MAVEN_CLI_OPTS test

publish:
  stage: publish
  script:
    - mvn $MAVEN_CLI_OPTS deploy
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

release:
  stage: release
  script:
    - mvn versions:set -DnewVersion=${CI_COMMIT_TAG}
    - mvn $MAVEN_CLI_OPTS deploy
  rules:
    - if: $CI_COMMIT_TAG
```

### Conditional publishing based on changes

This example publishes packages only when certain files are changed:

```yaml
default:
  image: maven:3.8.5-openjdk-17
  cache:
    paths:
      - .m2/repository/
      - target/

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

stages:
  - build
  - test
  - publish

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile

test:
  stage: test
  script:
    - mvn $MAVEN_CLI_OPTS test

publish:
  stage: publish
  script:
    - mvn $MAVEN_CLI_OPTS deploy
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      changes:
        - pom.xml
        - src/**/*
```

### Integration with code quality and security scans

This example integrates code quality checks and security scans into the pipeline:

```yaml
default:
  image: maven:3.8.5-openjdk-17
  cache:
    paths:
      - .m2/repository/
      - target/

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Code-Quality.gitlab-ci.yml

stages:
  - build
  - test
  - quality
  - publish

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile

test:
  stage: test
  script:
    - mvn $MAVEN_CLI_OPTS test

code_quality:
  stage: quality

sast:
  stage: quality

publish:
  stage: publish
  script:
    - mvn $MAVEN_CLI_OPTS deploy
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

## Helpful hints

### Publishing a package with the same name or version

When you publish a package with the same name and version as an existing package, the new package
files are added to the existing package. You can still use the UI or API to access and view the
existing package's older assets.

To delete older package versions, consider using the Packages API or the UI.

### Do not allow duplicate Maven packages

> - Required role [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/350682) from Developer to Maintainer in GitLab 15.0.
> - Required role [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/370471) from Maintainer to Owner in GitLab 17.0.

To prevent users from publishing duplicate Maven packages, you can use the [GraphQl API](../../../api/graphql/reference/_index.md#packagesettings) or the UI.

In the UI:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Packages and registries**.
1. In the **Maven** row of the **Duplicate packages** table, turn off the **Allow duplicates** toggle.
1. Optional. In the **Exceptions** text box, enter a regular expression that matches the names and versions of packages to allow.

NOTE:
If **Allow duplicates** is turned on, you can specify package names and versions that should not have duplicates in the **Exceptions** text box.

Your changes are automatically saved.

### Request forwarding to Maven Central

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85299) in GitLab 15.4 [with a flag](../../../administration/feature_flags.md) named `maven_central_request_forwarding`. Disabled by default.
> - Required role [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/370471) from Maintainer to Owner in GitLab 17.0.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

When a Maven package is not found in the package registry, the request is forwarded
to [Maven Central](https://search.maven.org/).

When the feature flag is enabled, administrators can disable this behavior in the
[Continuous Integration settings](../../../administration/settings/continuous_integration.md).

Maven forwarding is restricted to only the project level and
group level [endpoints](#naming-convention). The instance level endpoint
has naming restrictions that prevent it from being used for packages that don't follow that convention and also
introduces too much security risk for supply-chain style attacks.

#### Additional configuration for `mvn`

When using `mvn`, there are many ways to configure your Maven project so that it requests packages
in Maven Central from GitLab. Maven repositories are queried in a
[specific order](https://maven.apache.org/guides/mini/guide-multiple-repositories.html#repository-order).
By default, Maven Central is usually checked first through the
[Super POM](https://maven.apache.org/guides/introduction/introduction-to-the-pom.html#Super_POM), so
GitLab needs to be configured to be queried before maven-central.

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
            <value><personal_access_token></value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
  <mirrors>
    <mirror>
      <id>central-proxy</id>
      <name>GitLab proxy of central repo</name>
      <url>https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
```

### Create Maven packages with GitLab CI/CD

After you have configured your repository to use the Package Repository for Maven,
you can configure GitLab CI/CD to build new packages automatically.

::Tabs

:::TabTitle `mvn`

You can create a new package each time the default branch is updated.

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
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
   ```

1. Push those files to your repository.

The next time the `deploy` job runs, it copies `ci_settings.xml` to the
user's home location. In this example:

- The user is `root`, because the job runs in a Docker container.
- Maven uses the configured CI/CD variables.

:::TabTitle `gradle`

You can create a package each time the default branch
is updated.

1. Authenticate with [a CI job token in Gradle](#edit-the-client-configuration).

1. Add a `deploy` job to your `.gitlab-ci.yml` file:

   ```yaml
   deploy:
     image: gradle:6.5-jdk11
     script:
       - 'gradle publish'
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
   ```

1. Commit files to your repository.

When the pipeline is successful, the Maven package is created.

::EndTabs

### Version validation

The version string is validated by using the following regex.

```ruby
\A(?!.*\.\.)[\w+.-]+\z
```

You can experiment with the regex and try your version strings on [this regular expression editor](https://rubular.com/r/rrLQqUXjfKEoL6).

### Use different settings for snapshot and release deployments

To use different URLs or settings for snapshots and releases:

- In the `<distributionManagement>` section of your `pom.xml` file, define separate `<repository>` and `<snapshotRepository>` elements.

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

### Supported CLI commands

The GitLab Maven repository supports the following CLI commands:

::Tabs

:::TabTitle `mvn`

- `mvn deploy`: Publish your package to the package registry.
- `mvn install`: Install packages specified in your Maven project.
- `mvn dependency:get`: Install a specific package.

:::TabTitle `gradle`

- `gradle publish`: Publish your package to the package registry.
- `gradle install`: Install packages specified in your Gradle project.

::EndTabs

## Troubleshooting

While working with Maven packages in GitLab, you might encounter an issue.
To resolve many common issues, try these steps:

- Verify authentication - Ensure your authentication tokens are correct and have not expired.
- Check permissions - Confirm you have the necessary permissions to publish or install packages.
- Validate Maven settings - Double-check your `settings.xml` file for correct configuration.
- Review GitLab CI/CD logs - For CI/CD issues, carefully examine the job logs for error messages.
- Ensure correct endpoint URLs - Verify you're using the correct endpoint URLs for your project or group.
- Use the -s option with `mvn` commands - Always run Maven commands with the `-s` option, for example, `mvn package -s settings.xml`. Without this option, authentication settings aren't applied, and Maven might fail to find packages.

### Clear the cache

To improve performance, clients cache files related to a package. If you encounter issues, clear
the cache with these commands:

::Tabs

:::TabTitle `mvn`

```shell
rm -rf ~/.m2/repository
```

:::TabTitle `gradle`

```shell
rm -rf ~/.gradle/caches # Or replace ~/.gradle with your custom GRADLE_USER_HOME
```

::EndTabs

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

### "401 Unauthorized" error when trying to publish a package

This usually indicates an authentication issue. Check that:

- Your authentication token is valid and has not expired.
- You're using the correct token type (personal access token, deploy token, or CI job token).
- The token has the necessary permissions (`api`, `read_api`, or `read_repository`).
- For Maven projects, you're using the `-s` option with your mvn commands (for example, `mvn deploy -s settings.xml`). Without this option, Maven won't apply the authentication settings from your `settings.xml` file, leading to unauthorized errors.

### "400 Bad Request" error with message "Validation failed: Version is invalid"

GitLab has specific requirements for version strings. Ensure your version follows the format:

```regex
^(?!.*\.\.)(?!.*\.$)[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*(\+[0-9A-Za-z-]+)?$
```

For example, "1.0.0", "1.0-SNAPSHOT", and "1.0.0-alpha" are valid, but "1..0" or "1.0." are not.

### "Artifact already exists" errors when publishing

This error occurs when you try to publish a package version that already exists. To resolve:

- Increment your package version before publishing.
- If you're using SNAPSHOT versions, ensure you're allowing SNAPSHOT overwrites in your configuration.

### Published package not appearing in the UI

If you've just published a package, it might take a few moments to appear. If it still doesn't show:

- Verify you have the necessary permissions to view packages.
- Check that the package was successfully published by reviewing CI/CD logs or Maven output.
- Ensure you're looking in the correct project or group.

### Maven repository dependency conflicts

Dependency conflicts can be resolved by:

- Explicitly defining versions in your `pom.xml`.
- Using Maven's dependency management section to control versions.
- Using the `<exclusions>` tag to exclude conflicting transitive dependencies.

### "Unable to find valid certification path to requested target" error

This is typically a SSL certificate issue. To resolve:

- Ensure your JDK trusts the GitLab server's SSL certificate.
- If using a self-signed certificate, add it to the truststore of your JDK.
- As a last resort, you can disable SSL verification in Maven settings. Not recommended for production.

### "No plugin found for prefix" pipeline errors

This usually means Maven can't find the plugin. To fix:

- Ensure the plugin is correctly defined in your `pom.xml`.
- Check that your CI/CD configuration is using the correct Maven settings file.
- Verify that your pipeline has access to all necessary repositories.

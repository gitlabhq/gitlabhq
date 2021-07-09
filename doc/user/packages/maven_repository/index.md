---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Maven packages in the Package Repository **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5811) in GitLab Premium 11.3.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Free in 13.3.

Publish [Maven](https://maven.apache.org) artifacts in your project's Package Registry.
Then, install the packages whenever you need to use them as a dependency.

For documentation of the specific API endpoints that the Maven package manager
client uses, see the [Maven API documentation](../../../api/packages/maven.md).

## Build a Maven package

This section explains how to install Maven and build a package.

If you already use Maven and know how to build your own packages, go to the
[next section](#authenticate-to-the-package-registry-with-maven).

Maven repositories work well with Gradle, too. To set up a Gradle project, see [get started with Gradle](#build-a-java-project-with-gradle).

### Install Maven

The required minimum versions are:

- Java 11.0.5+
- Maven 3.6+

Follow the instructions at [maven.apache.org](https://maven.apache.org/install.html)
to download and install Maven for your local development environment. After
installation is complete, verify you can use Maven in your terminal by running:

```shell
mvn --version
```

The output should be similar to:

```shell
Apache Maven 3.6.1 (d66c9c0b3152b2e69ee9bac180bb8fcc8e6af555; 2019-04-04T20:00:29+01:00)
Maven home: /Users/<your_user>/apache-maven-3.6.1
Java version: 12.0.2, vendor: Oracle Corporation, runtime: /Library/Java/JavaVirtualMachines/jdk-12.0.2.jdk/Contents/Home
Default locale: en_GB, platform encoding: UTF-8
OS name: "mac os x", version: "10.15.2", arch: "x86_64", family: "mac"
```

### Create a project

Follow these steps to create a Maven project that can be
published to the GitLab Package Registry.

1. Open your terminal and create a directory to store the project.
1. From the new directory, run this Maven command to initialize a new package:

   ```shell
   mvn archetype:generate -DgroupId=com.mycompany.mydepartment -DartifactId=my-project -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
   ```

   The arguments are:

   - `DgroupId`: A unique string that identifies your package. Follow
   the [Maven naming conventions](https://maven.apache.org/guides/mini/guide-naming-conventions.html).
   - `DartifactId`: The name of the `JAR`, appended to the end of the `DgroupId`.
   - `DarchetypeArtifactId`: The archetype used to create the initial structure of
   the project.
   - `DinteractiveMode`: Create the project using batch mode (optional).

This message indicates that the project was set up successfully:

```shell
...
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  3.429 s
[INFO] Finished at: 2020-01-28T11:47:04Z
[INFO] ------------------------------------------------------------------------
```

In the folder where you ran the command, a new directory should be displayed.
The directory name should match the `DartifactId` parameter, which in this case,
is `my-project`.

## Build a Java project with Gradle

This section explains how to install Gradle and initialize a Java project.

If you already use Gradle and know how to build your own packages, go to the
[next section](#authenticate-to-the-package-registry-with-maven).

### Install Gradle

If you want to create a new Gradle project, you must install Gradle. Follow
instructions at [gradle.org](https://gradle.org/install/) to download and install
Gradle for your local development environment.

In your terminal, verify you can use Gradle by running:

```shell
gradle -version
```

To use an existing Gradle project, in the project directory,
on Linux execute `gradlew`, or on Windows execute `gradlew.bat`.

The output should be similar to:

```plaintext
------------------------------------------------------------
Gradle 6.0.1
------------------------------------------------------------

Build time:   2019-11-18 20:25:01 UTC
Revision:     fad121066a68c4701acd362daf4287a7c309a0f5

Kotlin:       1.3.50
Groovy:       2.5.8
Ant:          Apache Ant(TM) version 1.10.7 compiled on September 1 2019
JVM:          11.0.5 (Oracle Corporation 11.0.5+10)
OS:           Windows 10 10.0 amd64
```

### Create a Java project

Follow these steps to create a Maven project that can be
published to the GitLab Package Registry.

1. Open your terminal and create a directory to store the project.
1. From this new directory, run this Maven command to initialize a new package:

   ```shell
   gradle init
   ```

   The output should be:

   ```plaintext
   Select type of project to generate:
     1: basic
     2: application
     3: library
     4: Gradle plugin
   Enter selection (default: basic) [1..4]
   ```

1. Enter `3` to create a new Library project. The output should be:

   ```plaintext
   Select implementation language:
     1: C++
     2: Groovy
     3: Java
     4: Kotlin
     5: Scala
     6: Swift
   ```

1. Enter `3` to create a new Java Library project. The output should be:

   ```plaintext
   Select build script DSL:
     1: Groovy
     2: Kotlin
   Enter selection (default: Groovy) [1..2]
   ```

1. Enter `1` to create a new Java Library project that is described in Groovy DSL. The output should be:

   ```plaintext
   Select test framework:
     1: JUnit 4
     2: TestNG
     3: Spock
     4: JUnit Jupiter
   ```

1. Enter `1` to initialize the project with JUnit 4 testing libraries. The output should be:

   ```plaintext
   Project name (default: test):
   ```

1. Enter a project name or press Enter to use the directory name as project name.

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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213566) deploy token authentication in [GitLab Premium](https://about.gitlab.com/pricing/) 13.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Free in 13.3.

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
            <value>${env.CI_JOB_TOKEN}</value>
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

Create a file `~/.gradle/gradle.properties` with the following content:

```groovy
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

The corresponding section in Gradle would be:

```groovy
repositories {
    maven {
        url "https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven"
        name "GitLab"
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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/8798) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.7.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Free in 13.3.

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

For Gradle, the corresponding `repositories` section would look like:

```groovy
repositories {
    maven {
        url "https://gitlab.example.com/api/v4/groups/GROUP_ID/-/packages/maven"
        name "GitLab"
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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/8274) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.7.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Free in 13.3.

If you rely on many packages, it might be inefficient to include the `repository` section
with a unique URL for each package. Instead, you can use the instance-level endpoint for
all Maven packages stored in GitLab. All packages you have access to are available
for download.

**Only packages that have the same path as the project** are exposed by
the instance-level endpoint.

| Project | Package | Instance-level endpoint available |
| ------- | ------- | --------------------------------- |
| `foo/bar`           | `foo/bar/1.0-SNAPSHOT`           | Yes |
| `gitlab-org/gitlab` | `foo/bar/1.0-SNAPSHOT`           | No  |
| `gitlab-org/gitlab` | `gitlab-org/gitlab/1.0-SNAPSHOT` | Yes |

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

The corresponding repositories section in Gradle would look like:

```groovy
repositories {
    maven {
        url "https://gitlab.example.com/api/v4/packages/maven"
        name "GitLab"
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

   ```groovy
   plugins {
       id 'java'
       id 'maven-publish'
   }
   ```

1. Add a `publishing` section:

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
                   value = gitLabPrivateToken // the variable resides in ~/.gradle/gradle.properties
               }
               authentication {
                   header(HttpHeaderAuthentication)
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

Now navigate to your project's **Packages & Registries** page and view the published artifacts.

### Publishing a package with the same name or version

When you publish a package with the same name and version as an existing package, the new package
files are added to the existing package. You can still use the UI or API to access and view the
existing package's older files.

To delete these older package versions, consider using the Packages API or the UI.

#### Do not allow duplicate Maven packages

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/296895) in GitLab Free 13.9.

To prevent users from publishing duplicate Maven packages, you can use the [GraphQl API](../../../api/graphql/reference/index.md#packagesettings) or the UI.

In the UI:

1. For your group, go to **Settings > Packages & Registries**.
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

You can install packages by using the Maven commands directly.

1. In your project directory, run:

   ```shell
   mvn dependency:get -Dartifact=com.nickkipling.app:nick-test-app:1.1-SNAPSHOT
   ```

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

## Remove a package

For your project, go to **Packages & Registries > Package Registry**.

To remove a package, click the red trash icon or, from the package details, the **Delete** button.

## Create Maven packages with GitLab CI/CD

After you have configured your repository to use the Package Repository for Maven,
you can configure GitLab CI/CD to build new packages automatically.

### Create Maven packages with GitLab CI/CD by using Maven

You can create a new package each time the `master` branch is updated.

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
               <value>${env.CI_JOB_TOKEN}</value>
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
       <url>${env.CI_API_V4_URL}/projects/${env.CI_PROJECT_ID}/packages/maven</url>
     </repository>
   </repositories>
   <distributionManagement>
     <repository>
       <id>gitlab-maven</id>
       <url>${CI_API_V4_URL}/projects/${env.CI_PROJECT_ID}/packages/maven</url>
     </repository>
     <snapshotRepository>
       <id>gitlab-maven</id>
       <url>${CI_API_V4_URL}/projects/${env.CI_PROJECT_ID}/packages/maven</url>
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
       - master
   ```

1. Push those files to your repository.

The next time the `deploy` job runs, it copies `ci_settings.xml` to the
user's home location. In this example:

- The user is `root`, because the job runs in a Docker container.
- Maven uses the configured CI/CD variables.

### Create Maven packages with GitLab CI/CD by using Gradle

You can create a package each time the `master` branch
is updated.

1. Authenticate with [a CI job token in Gradle](#authenticate-with-a-ci-job-token-in-gradle).

1. Add a `deploy` job to your `.gitlab-ci.yml` file:

   ```yaml
   deploy:
     image: gradle:6.5-jdk11
     script:
       - 'gradle publish'
     only:
       - master
   ```

1. Commit files to your repository.

When the pipeline is successful, the package is created.

### Version validation

The version string is validated by using the following regex.

```ruby
\A(\.?[\w\+-]+\.?)+\z
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
rm -rf ~/.gradle/caches
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

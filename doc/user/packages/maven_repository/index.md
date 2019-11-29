# GitLab Maven Repository **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/5811) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.3.

With the GitLab [Maven](https://maven.apache.org) Repository, every
project can have its own space to store its Maven artifacts.

![GitLab Maven Repository](img/maven_package_view.png)

## Enabling the Maven Repository

NOTE: **Note:**
This option is available only if your GitLab administrator has
[enabled support for the Maven repository](../../../administration/packages/index.md).**(PREMIUM ONLY)**

After the Packages feature is enabled, the Maven Repository will be available for
all new projects by default. To enable it for existing projects, or if you want
to disable it:

1. Navigate to your project's **Settings > General > Permissions**.
1. Find the Packages feature and enable or disable it.
1. Click on **Save changes** for the changes to take effect.

You should then be able to see the **Packages** section on the left sidebar.
Next, you must configure your project to authorize with the GitLab Maven
repository.

## Authenticating to the GitLab Maven Repository

If a project is private or you want to upload Maven artifacts to GitLab,
credentials will need to be provided for authorization. Support is available for
[personal access tokens](#authenticating-with-a-personal-access-token) and
[CI job tokens](#authenticating-with-a-ci-job-token) only.
[Deploy tokens](../../project/deploy_tokens/index.md) and regular username/password
credentials do not work.

### Authenticating with a personal access token

To authenticate with a [personal access token](../../profile/personal_access_tokens.md),
set the scope to `api` and add a corresponding section to your
[`settings.xml`](https://maven.apache.org/settings.html) file:

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

You should now be able to upload Maven artifacts to your project.

### Authenticating with a CI job token

If you're using Maven with GitLab CI/CD, a CI job token can be used instead
of a personal access token.

To authenticate with a CI job token, add a corresponding section to your
[`settings.xml`](https://maven.apache.org/settings.html) file:

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

You can read more on
[how to create Maven packages using GitLab CI/CD](#creating-maven-packages-with-gitlab-cicd).

## Configuring your project to use the GitLab Maven repository URL

To download and upload packages from GitLab, you need a `repository` and
`distributionManagement` section in your `pom.xml` file.

Depending on your workflow and the amount of Maven packages you have, there are
3 ways you can configure your project to use the GitLab endpoint for Maven packages:

- **Project level**: Useful when you have few Maven packages which are not under
  the same GitLab group.
- **Group level**: Useful when you have many Maven packages under the same GitLab
  group.
- **Instance level**: Useful when you have many Maven packages under different
  GitLab groups or on their own namespace.

NOTE: **Note:**
In all cases, you need a project specific URL for uploading a package in
the `distributionManagement` section.

### Project level Maven endpoint

The example below shows how the relevant `repository` section of your `pom.xml`
would look like:

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </repository>
</repositories>
<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </repository>
  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </snapshotRepository>
</distributionManagement>
```

The `id` must be the same with what you
[defined in `settings.xml`](#authenticating-to-the-gitlab-maven-repository).

Replace `PROJECT_ID` with your project ID which can be found on the home page
of your project.

If you have a self-hosted GitLab installation, replace `gitlab.com` with your
domain name.

NOTE: **Note:**
For retrieving artifacts, you can use either the
[URL encoded](../../../api/README.md#namespaced-path-encoding) path of the project
(e.g., `group%2Fproject`) or the project's ID (e.g., `42`). However, only the
project's ID can be used for uploading.

### Group level Maven endpoint

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/8798) in GitLab Premium 11.7.

If you rely on many packages, it might be inefficient to include the `repository` section
with a unique URL for each package. Instead, you can use the group level endpoint for
all your Maven packages stored within one GitLab group. Only packages you have access to
will be available for download.

The group level endpoint works with any package names, which means the you
have the flexibility of naming compared to [instance level endpoint](#instance-level-maven-endpoint).
However, GitLab will not guarantee the uniqueness of the package names within
the group. You can have two projects with the same package name and package
version. As a result, GitLab will serve whichever one is more recent.

The example below shows how the relevant `repository` section of your `pom.xml`
would look like. You still need a project specific URL for uploading a package in
the `distributionManagement` section:

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/groups/GROUP_ID/-/packages/maven</url>
  </repository>
</repositories>
<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </repository>
  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </snapshotRepository>
</distributionManagement>
```

The `id` must be the same with what you
[defined in `settings.xml`](#authenticating-to-the-gitlab-maven-repository).

Replace `my-group` with your group name and `PROJECT_ID` with your project ID
which can be found on the home page of your project.

If you have a self-hosted GitLab installation, replace `gitlab.com` with your
domain name.

NOTE: **Note:**
For retrieving artifacts, you can use either the
[URL encoded](../../../api/README.md#namespaced-path-encoding) path of the group
(e.g., `group%2Fsubgroup`) or the group's ID (e.g., `12`).

### Instance level Maven endpoint

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/8274) in GitLab Premium 11.7.

If you rely on many packages, it might be inefficient to include the `repository` section
with a unique URL for each package. Instead, you can use the instance level endpoint for
all maven packages stored in GitLab and the packages you have access to will be available
for download.

Note that **only packages that have the same path as the project** are exposed via
the instance level endpoint.

| Project | Package | Instance level endpoint available |
| ------- | ------- | --------------------------------- |
| `foo/bar`           | `foo/bar/1.0-SNAPSHOT`           | Yes |
| `gitlab-org/gitlab` | `foo/bar/1.0-SNAPSHOT`           | No  |
| `gitlab-org/gitlab` | `gitlab-org/gitlab/1.0-SNAPSHOT` | Yes |

The example below shows how the relevant `repository` section of your `pom.xml`
would look like. You still need a project specific URL for uploading a package in
the `distributionManagement` section:

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/packages/maven</url>
  </repository>
</repositories>
<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </repository>
  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </snapshotRepository>
</distributionManagement>
```

The `id` must be the same with what you
[defined in `settings.xml`](#authenticating-to-the-gitlab-maven-repository).

Replace `PROJECT_ID` with your project ID which can be found on the home page
of your project.

If you have a self-hosted GitLab installation, replace `gitlab.com` with your
domain name.

NOTE: **Note:**
For retrieving artifacts, you can use either the
[URL encoded](../../../api/README.md#namespaced-path-encoding) path of the project
(e.g., `group%2Fproject`) or the project's ID (e.g., `42`). However, only the
project's ID can be used for uploading.

## Uploading packages

Once you have set up the [authentication](#authenticating-to-the-gitlab-maven-repository)
and [configuration](#configuring-your-project-to-use-the-gitlab-maven-repository-url),
test to upload a Maven artifact from a project of yours:

```sh
mvn deploy
```

You can then navigate to your project's **Packages** page and see the uploaded
artifacts or even delete them.

## Creating Maven packages with GitLab CI/CD

Once you have your repository configured to use the GitLab Maven Repository,
you can configure GitLab CI/CD to build new packages automatically. The example below
shows how to create a new package each time the `master` branch is updated:

1. Create a `ci_settings.xml` file that will serve as Maven's `settings.xml` file.
   Add the server section with the same id you defined in your `pom.xml` file.
   For example, in our case it's `gitlab-maven`:

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

1. Make sure your `pom.xml` file includes the following:

   ```xml
   <repositories>
     <repository>
       <id>gitlab-maven</id>
       <url>https://gitlab.com/api/v4/projects/${env.CI_PROJECT_ID}/packages/maven</url>
     </repository>
   </repositories>
   <distributionManagement>
     <repository>
       <id>gitlab-maven</id>
       <url>https://gitlab.com/api/v4/projects/${env.CI_PROJECT_ID}/packages/maven</url>
     </repository>
     <snapshotRepository>
       <id>gitlab-maven</id>
       <url>https://gitlab.com/api/v4/projects/${env.CI_PROJECT_ID}/packages/maven</url>
     </snapshotRepository>
   </distributionManagement>
   ```

   TIP: **Tip:**
   You can either let Maven utilize the CI environment variables or hardcode your project's ID.

1. Add a `deploy` job to your `.gitlab-ci.yml` file:

   ```yaml
   deploy:
     image: maven:3.3.9-jdk-8
     script:
       - 'mvn deploy -s ci_settings.xml'
     only:
       - master
   ```

1. Push those files to your repository.

The next time the `deploy` job runs, it will copy `ci_settings.xml` to the
user's home location (in this case the user is `root` since it runs in a
Docker container), and Maven will utilize the configured CI
[environment variables](../../../ci/variables/README.md#predefined-environment-variables).

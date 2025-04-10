---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: NuGet packages in the package registry
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Publish NuGet packages in your project's package registry. Then, install the
packages whenever you need to use them as a dependency.

The package registry works with:

- [NuGet CLI](https://learn.microsoft.com/en-us/nuget/reference/nuget-exe-cli-reference)
- [.NET Core CLI](https://learn.microsoft.com/en-us/dotnet/core/tools/)
- [Visual Studio](https://visualstudio.microsoft.com/vs/)

To learn about the specific API endpoints these clients use, see the [NuGet API reference](../../../api/packages/nuget.md).

Learn how to [install NuGet](../workflows/build_packages.md#nuget).

## Authenticate to the package registry

You need an authentication token to access the GitLab package registry. Different tokens are available depending on what you're trying to
achieve. For more information, review the [guidance on tokens](../package_registry/_index.md#authenticate-with-the-registry).

- If your organization uses two-factor authentication (2FA), you must use a
  [personal access token](../../profile/personal_access_tokens.md) with the scope set to `api`.
- If you publish a package with CI/CD pipelines, you can use a [CI/CD job token](../../../ci/jobs/ci_job_token.md) with
  private runners. You can also [register a variable](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) for instance runners.

## Use the GitLab endpoint for NuGet packages

You can use either a project or group endpoint to interact with the GitLab package registry:

- **Project endpoint**: Use when you have a few NuGet packages that are not in the same group.
- **Group endpoint**: Use when you have many NuGet packages in different projects under the same group.

Some actions, like publishing a package, are only available on the project endpoint.

Because of how NuGet handles credentials, the package registry rejects anonymous requests to public groups.

## Add the package registry as a source for NuGet packages

To publish and install packages to the package registry, you must add the
package registry as a source for your packages.

Prerequisites:

- Your GitLab username
- An authentication token (the following sections assume a personal access token)
- A name for your source
- A project or group ID

### With the project endpoint

{{< tabs >}}

{{< tab title="NuGet CLI" >}}

To add the package registry as a source with NuGet CLI, run the following command:

```shell
nuget source Add -Name <source_name> -Source "https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/index.json" -UserName <gitlab_username> -Password <personal_access_token>
```

Replace:

- `<source_name>` with your source name
- `<project_id>` with the project ID found on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id)
- `<gitlab_username>` with your GitLab username
- `<personal_access_token>` with your personal access token

For example:

```shell
nuget source Add -Name "GitLab" -Source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" -UserName carol -Password <your_access_token>
```

{{< /tab >}}

{{< tab title=".NET CLI" >}}

To add the package registry as a source with .NET CLI, run the following command:

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/index.json" --name <source_name> --username <gitlab_username> --password <personal_access_token>
```

Replace:

- `<source_name>` with your source name
- `<project_id>` with the project ID found on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id)
- `<gitlab_username>` with your GitLab username
- `<personal_access_token>` with your personal access token

Depending on your operating system, you may need to append `--store-password-in-clear-text` to the command.

For example:

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" --name gitlab --username carol --password <your_access_token> --store-password-in-clear-text
```

{{< /tab >}}

{{< tab title="Chocolatey CLI" >}}

You can add the package registry as a source feed with the Chocolatey CLI. If you use Chocolatey CLI v1.X, you can add only a NuGet v2 source feed.

To add the package registry as a source for Chocolatey, run the following command:

```shell
choco source add -n=<source_name> -s "'https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/v2'" -u=<gitlab_username> -p=<personal_access_token>
```

Replace:

- `<source_name>` with your source name
- `<project_id>` with the project ID found on the [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id)
- `<gitlab_username>` with your GitLab username
- `<personal_access_token>` with your personal access token

For example:

```shell
choco source add -n=gitlab -s "'https://gitlab.example.com/api/v4/projects/10/packages/nuget/v2'" -u=carol -p=<your_access_token>
```

{{< /tab >}}

{{< tab title="Visual Studio" >}}

To add the package registry as a source with Visual Studio:

1. Open [Visual Studio](https://visualstudio.microsoft.com/vs/).
1. In Windows, select **Tools > Options**. On macOS, select **Visual Studio > Preferences**.
1. In the **NuGet** section, select **Sources** to view a list of all your NuGet sources.
1. Select **Add**.
1. Complete the following fields:

   - **Name**: Name for the source.
   - **Source**: `https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/index.json`,
     where `<project_id>` is your project ID, and `gitlab.example.com` is
     your domain name.

1. Select **Save**.
1. When you access the package, you must enter your **Username** and **Password**:

   - **Username**: Your GitLab username.
   - **Password**: Your personal access token.

The source is displayed in your list.

If you get a warning, ensure that the **Source**, **Username**, and
**Password** are correct.

{{< /tab >}}

{{< tab title="Configuration file" >}}

To add the package registry as a source with a .NET configuration file:

1. In the root of your project, create a file named `nuget.config`.
1. Add the following configuration:

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <configuration>
    <packageSources>
        <clear />
        <add key="gitlab" value="https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/index.json" />
    </packageSources>
    <packageSourceCredentials>
        <gitlab>
            <add key="Username" value="%GITLAB_PACKAGE_REGISTRY_USERNAME%" />
            <add key="ClearTextPassword" value="%GITLAB_PACKAGE_REGISTRY_PASSWORD%" />
        </gitlab>
    </packageSourceCredentials>
   </configuration>
   ```

1. Configure the necessary environment variables:

   ```shell
   export GITLAB_PACKAGE_REGISTRY_USERNAME=<gitlab_username>
   export GITLAB_PACKAGE_REGISTRY_PASSWORD=<personal_access_token>
   ```

{{< /tab >}}

{{< /tabs >}}

### With the group endpoint

{{< tabs >}}

{{< tab title="NuGet CLI" >}}

To add the package registry as a source with NuGET CLI:

```shell
nuget source Add -Name <source_name> -Source "https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/nuget/index.json" -UserName <gitlab_username> -Password <personal_access_token>
```

Replace:

- `<source_name>` with your source name
- `<group_id>` with the group ID found on the [Group overview page](../../group/_index.md#access-a-group-by-using-the-group-id)
- `<gitlab_username>` with your GitLab username
- `<personal_access_token>` with your personal access token

For example:

```shell
nuget source Add -Name "GitLab" -Source "https://gitlab.example.com/api/v4/groups/23/-/packages/nuget/index.json" -UserName carol -Password <your_access_token>
```

{{< /tab >}}

{{< tab title=".NET CLI" >}}

To add the package registry as a source with .NET CLI:

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/nuget/index.json" --name <source_name> --username <gitlab_username> --password <personal_access_token>
```

Replace:

- `<source_name>` with your source name
- `<group_id>` with the group ID found on the [Group overview page](../../group/_index.md#access-a-group-by-using-the-group-id)
- `<gitlab_username>` with your GitLab username
- `<personal_access_token>` with your personal access token

The `--store-password-in-clear-text` flag might be necessary depending on your operating system.

For example:

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/groups/23/-/packages/nuget/index.json" --name gitlab --username carol --password <your_access_token> --store-password-in-clear-text
```

{{< /tab >}}

{{< tab title="Chocolatey CLI" >}}

The Chocolatey CLI is only compatible with the [project endpoint](#with-the-project-endpoint).

{{< /tab >}}

{{< tab title="Visual Studio" >}}

To add the package registry as a source with Visual Studio:

1. Open [Visual Studio](https://visualstudio.microsoft.com/vs/).
1. In Windows, select **Tools > Options**. On macOS, select **Visual Studio > Preferences**.
1. In the **NuGet** section, select **Sources** to view a list of all your NuGet sources.
1. Select **Add**.
1. Complete the following fields:

   - **Name**: Name for the source.
   - **Source**: `https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/nuget/index.json`,
     where `<group_id>` is your group ID, and `gitlab.example.com` is
     your domain name.

1. Select **Save**.
1. When you access the package, you must enter your **Username** and **Password**.

   - **Username**: Your GitLab username.
   - **Password**: Your personal access token.

The source is displayed in your list.

If you get a warning, ensure that the **Source**, **Username**, and
**Password** are correct.

{{< /tab >}}

{{< tab title="Configuration file" >}}

To add the package registry as a source with a .NET configuration file:

1. In the root of your project, create a file named `nuget.config`.
1. Add the following configuration:

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <configuration>
    <packageSources>
        <clear />
        <add key="gitlab" value="https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/nuget/index.json" />
    </packageSources>
    <packageSourceCredentials>
        <gitlab>
            <add key="Username" value="%GITLAB_PACKAGE_REGISTRY_USERNAME%" />
            <add key="ClearTextPassword" value="%GITLAB_PACKAGE_REGISTRY_PASSWORD%" />
        </gitlab>
    </packageSourceCredentials>
   </configuration>
   ```

1. Configure the necessary environment variables:

   ```shell
   export GITLAB_PACKAGE_REGISTRY_USERNAME=<gitlab_username>
   export GITLAB_PACKAGE_REGISTRY_PASSWORD=<personal_access_token>
   ```

{{< /tab >}}

{{< /tabs >}}

## Publish a package

Prerequisites:

- Set up the package registry as a [source](#add-the-package-registry-as-a-source-for-nuget-packages).
- Configure the [GitLab project endpoint for NuGet packages](#with-the-project-endpoint).

When publishing packages:

- Review the maximum file size limits for your GitLab instance:
  - The [package registry limits on GitLab.com instances](../../gitlab_com/_index.md#package-registry-limits) vary by file format, and are not configurable.
  - The [package registry limits on GitLab Self-Managed instances](../../../administration/instance_limits.md#file-size-limits) vary by file format, and are configurable.
- If duplicates are allowed, and you publish the same package with the same version multiple times, each
  consecutive upload is saved as a separate file. When installing a package,
  GitLab serves the most recent file.
- Most uploaded packages should be immediately visible in the **Package registry** page. A few packages might take up to 10 minutes before they are visible if they need to be processed in the background.
  a package.

### With NuGet CLI

Prerequisites:

- [A NuGet package created with NuGet CLI](https://learn.microsoft.com/en-us/nuget/create-packages/creating-a-package).

To publish a package, run the following command:`

```shell
nuget push <package_file> -Source <source_name>
```

Replace:

- `<package_file>` with your package filename, ending in `.nupkg`.
- `<source_name>` with the name of your source.

For example:

```shell
nuget push MyPackage.1.0.0.nupkg -Source gitlab
```

### With .NET CLI

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214674) publishing a package with the `--api-key` in GitLab 16.1.

{{< /history >}}

Prerequisites:

- [A NuGet package created with .NET CLI](https://learn.microsoft.com/en-us/nuget/create-packages/creating-a-package-dotnet-cli).

To publish a package, run the following command:

```shell
dotnet nuget push <package_file> --source <source_name>
```

Replace:

- `<package_file>` with your package filename, ending in `.nupkg`.
- `<source_name>` with the name of your source.

For example:

```shell
dotnet nuget push MyPackage.1.0.0.nupkg --source gitlab
```

You can publish a package using the `--api-key` option instead of `username` and `password`:

```shell
dotnet nuget push <package_file> --source <source_url> --api-key <personal_access_token>
```

Replace:

- `<package_file>` with your package filename, ending in `.nupkg`.
- `<source_url>` with the URL of the NuGet package registry.

For example:

```shell
dotnet nuget push MyPackage.1.0.0.nupkg --source https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/index.json --api-key <personal_access_token>
```

### With Chocolatey CLI

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416404) support for NuGet v2 and Chocolatey CLI in GitLab 16.2.

{{< /history >}}

Prerequisites:

- A source using a [project endpoint](#with-the-project-endpoint).

To publish a package with the Chocolatey CLI, run the following command:

```shell
choco push <package_file> --source <source_url> --api-key <gitlab_personal_access_token, deploy_token or job token>
```

Replace:

- `<package_file>` with your package filename, ending in `.nupkg`.
- `<source_url>` with the URL of the NuGet v2 feed package registry.

For example:

```shell
choco push MyPackage.1.0.0.nupkg --source "https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/v2" --api-key <personal_access_token>
```

### With a CI/CD pipeline

If you're publishing NuGet packages with GitLab CI/CD, you can use a
[`CI_JOB_TOKEN` predefined variable](../../../ci/jobs/ci_job_token.md) instead of
a personal access token or deploy token. The job token inherits the permissions of the
user or member that generates the pipeline.

The examples in the following sections address
common NuGet publishing workflows when using a CI/CD pipeline.

#### Publish packages when the default branch is updated

To publish new packages each time the `main` branch is
updated:

1. In the `.gitlab-ci.yml` file of your project, add the following `deploy` job:

   ```yaml
   default:
     # Updated to a more current SDK version
     image: mcr.microsoft.com/dotnet/sdk:7.0

   stages:
     - deploy

   deploy:
     stage: deploy
     script:
       # Build the package in Release configuration
       - dotnet pack -c Release
       # Configure GitLab package registry as a NuGet source
       - dotnet nuget add source "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
       # Push the package to the project's package registry
       - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH  # Only run on the main branch
     environment: production
   ```

1. Commit the changes and push them to your GitLab repository to trigger a new CI/CD build.

#### Publish versioned packages with Git tags

To publish versioned NuGet packages
with [Git tags](../../project/repository/tags/_index.md):

1. In the `.gitlab-ci.yml` file of your project, add the following `deploy` job:

   ```yaml
   publish-tagged-version:
     stage: deploy
     script:
       # Use the Git tag as the package version
       - dotnet pack -c Release /p:Version=${CI_COMMIT_TAG} /p:PackageVersion=${CI_COMMIT_TAG}
       # Configure GitLab package registry as a NuGet source
       - dotnet nuget add source "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
       # Push the package to the project's package registry
       - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
     rules:
       - if: $CI_COMMIT_TAG  # Only run when a tag is pushed
   ```

1. Commit the changes and push them to your GitLab repository.
1. Push a Git tag to trigger a new CI/CD build.

#### Publish conditionally for different environments

You can configure the CI/CD pipeline to conditionally
publish NuGet packages to different environments depending on your use case.

To conditionally publish NuGet packages
for `development` and `production` environments:

1. In the `.gitlab-ci.yml` file of your project, add the following `deploy` jobs:

   ```yaml
     # Publish development/preview packages
   publish-dev:
     stage: deploy
     script:
       # Create a development version with pipeline ID for uniqueness
       - VERSION="0.0.1-dev.${CI_PIPELINE_IID}"
       - dotnet pack -c Release /p:Version=$VERSION /p:PackageVersion=$VERSION
       # Configure GitLab package registry as a NuGet source
       - dotnet nuget add source "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
       # Push the package to the project's package registry
       - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
     rules:
       - if: $CI_COMMIT_BRANCH == "develop"
     environment: development

     # Publish stable release packages
   publish-release:
     stage: deploy
     script:
       - dotnet pack -c Release
       # Configure GitLab package registry as a NuGet source
       - dotnet nuget add source "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
       # Push the package to the project's package registry
       - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
     environment: production
   ```

1. Commit the changes and push them to your GitLab repository.

   With this CI/CD configuration:

   - Pushing NuGet packages to the `develop` branch publishes packages to the package registry of your `development` environment.
   - Pushing NuGet packages to the `main` branch publishes NuGet packages to the package registry of your `production` environment.

### Turn off duplicate NuGet packages

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/293748) in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `nuget_duplicates_option`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/419078) in GitLab 16.6. Feature flag `nuget_duplicates_option` removed.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/370471) the required role from Maintainer to Owner in GitLab 17.0.

{{< /history >}}

You can publish multiple packages with the same name and version.

To prevent group members and users from publishing duplicate NuGet packages, turn off the **Allow duplicates** setting:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Packages and registries**.
1. In the **NuGet** row of the **Duplicate packages** table, turn off the **Allow duplicates** toggle.
1. Optional. In the **Exceptions** text box, enter a regular expression that matches the names and versions of packages to allow.

You can also turn off duplicate NuGet packages with the
`nuget_duplicates_allowed` setting in the [GraphQL API](../../../api/graphql/reference/_index.md#packagesettings).

{{< alert type="warning" >}}

If the `.nuspec` file is not located in the root of the package
or the beginning of the archive, the package might
not be immediately recognized as a duplicate. When it is inevitably recognized as
a duplicate, an error displays in the **Package manager** page.

{{< /alert >}}

## Install a package

The GitLab package registry can contain multiple packages with the same name and version.
If you install a duplicate package,
the latest published package is retrieved.

Prerequisites:

- Set up the package registry as a [source](#add-the-package-registry-as-a-source-for-nuget-packages).
- Configure the [GitLab endpoint for NuGet packages](#use-the-gitlab-endpoint-for-nuget-packages).

### From the command line

{{< tabs >}}

{{< tab title="NuGet CLI" >}}

Install the latest version of a package by running this command:

```shell
nuget install <package_id> -OutputDirectory <output_directory> \
  -Version <package_version> \
  -Source <source_name>
```

- `<package_id>`: The package ID.
- `<output_directory>`: The output directory, where the package is installed.
- `<package_version>`: Optional. The package version.
- `<source_name>`: Optional. The source name.
  - `nuget` checks `nuget.org` for the requested package first.
If GitLab package registry has a NuGet package
with the same name as a package at
`nuget.org`, you must specify the source name
to install the correct package.

{{< /tab >}}

{{< tab title=".NET CLI" >}}

{{< alert type="note" >}}

If the GitLab package registry has a NuGet package with the same name as a package at
a different source, verify the order in which `dotnet` checks sources during
install. This behavior is defined in the `nuget.config` file.

{{< /alert >}}

Install the latest version of a package by running this command:

```shell
dotnet add package <package_id> \
       -v <package_version>
```

- `<package_id>`: The package ID.
- `<package_version>`: Optional. The package version.

{{< /tab >}}

{{< /tabs >}}

### With NuGet v2 feed

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416404) support for NuGet v2 install endpoints in GitLab 16.5.

{{< /history >}}

Prerequisites:

- A [v2 feed source](#with-the-project-endpoint) for Chocolatey.
- A package version must be provided when installing or upgrading a package with NuGet v2 feed.

To install a package with the Chocolatey CLI:

```shell
choco install <package_id> -Source <source_url> -Version <package_version>
```

- `<package_id>`: The package ID.
- `<source_url>`: The URL or name of the NuGet v2 feed package registry.
- `<package_version>`: The package version.

For example:

```shell
choco install MyPackage -Source gitlab -Version 1.0.2

# or

choco install MyPackage -Source "https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/v2" -u <username> -p <personal_access_token> -Version 1.0.2
```

To upgrade a package with the Chocolatey CLI:

```shell
choco upgrade <package_id> -Source <source_url> -Version <package_version>
```

- `<package_id>`: The package ID.
- `<source_url>`: The URL or name of the NuGet v2 feed package registry.
- `<package_version>`: The package version.

For example:

```shell
choco upgrade MyPackage -Source gitlab -Version 1.0.3
```

## Delete a package

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38275) support for NuGet package deletion in GitLab 16.5.

{{< /history >}}

{{< alert type="warning" >}}

Deleting a package is a permanent action that cannot be undone.

{{< /alert >}}

Prerequisites:

- You must have the [Maintainer](../../permissions.md#project-members-permissions) role or higher in the project.
- You must have both the package name and version.

To delete a package with the NuGet CLI:

```shell
nuget delete <package_id> <package_version> -Source <source_name> -ApiKey <personal_access_token>
```

- `<package_id>`: The package ID.
- `<package_version>`: The package version.
- `<source_name>`: The source name.

For example:

```shell
nuget delete MyPackage 1.0.0 -Source gitlab -ApiKey <personal_access_token>
```

## Symbol packages

GitLab can consume symbol files from the NuGet package registry.
You can use the GitLab package registry as a symbol server
to debug your NuGet packages.

Whenever you publish a NuGet package file (`.nupkg`),
symbol package files (`.snupkg`) are uploaded automatically
to the NuGet package registry.

You can also push them manually:

```shell
nuget push My.Package.snupkg -Source <source_name>
```

### Use the GitLab endpoint for symbol files

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416178) in GitLab 16.7.

{{< /history >}}

GitLab package registry provides a special `symbolfiles` endpoint that you can configure
with your project or group endpoint:

- **Project endpoint**:

  ```plaintext
  https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/symbolfiles
  ```

  - Replace `<project_id>` with the project ID.

- **Group endpoint**:

  ```plaintext
  https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/nuget/symbolfiles
  ```

  - Replace `<group_id>` with the group ID.

The `symbolfiles` endpoint is the source where a configured debugger
can push symbol files.

### Use the package registry as a symbol server

To use the symbol server:

1. Enable the `nuget_symbol_server_enabled` namespace setting with the [GraphQL API](../../../api/graphql/reference/_index.md#packagesettings).
1. Configure your debugger to use the symbol server.

For example, to configure Visual Studio as your debugger:

1. Select **Tools > Preferences**.
1. Select **Debugger > Symbol sources**.
1. Select **Add**.
1. Enter the symbol server URL.
1. Select **Add Source**.

After you configure the debugger, you can debug your application as usual.
The debugger automatically downloads the symbol PDB files from the package
registry if they're available.

#### Consume symbol packages

When the debugger is configured to consume symbol packages,
the debugger sends the following information
in a request:

- `Symbolchecksum` header: The SHA-256 checksum of the symbol file.
- `file_name` request parameter: The name of the symbol file. For example, `mypackage.pdb`.
- `signature` request parameter: The GUID and age of the PDB file.

The GitLab server matches this information to a symbol file and returns it.

Keep in mind that:

- Only portable PDB files are supported.
- Because debuggers cannot provide authentication tokens, the symbol server endpoint does not support typical authentication methods.
  The GitLab server requires the `signature` and `Symbolchecksum` to return the correct symbol file.

## Supported CLI commands

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38275) `nuget delete` and `dotnet nuget delete` commands in GitLab 16.5.

{{< /history >}}

The GitLab NuGet repository supports the following commands for the NuGet CLI (`nuget`) and the .NET
CLI (`dotnet`):

| NuGet | .NET | Description |
|-----------|----------|-------------|
| `nuget push` | `dotnet nuget push` | Upload a package to the registry. |
| `nuget install` | `dotnet add` | Install a package from the registry. |
| `nuget delete` | `dotnet nuget delete` | Delete a package from the registry. |

## Troubleshooting

When working with NuGet packages, you might encounter the following issues.

### Clear the NuGet cache

To improve performance, NuGet caches package files. If you encounter storage issues, clear the
cache with the following command:

```shell
nuget locals all -clear
```

### Errors when publishing NuGet packages in a Docker-based GitLab installation

You might get the following error messages
when publishing NuGet packages:

- `Error publishing`
- `Invalid Package: Failed metadata extraction error`

Webhook requests to local network addresses are blocked to prevent exploitation of
internal web services.

To resolve these errors, change your network settings to
[allow webhook and integration requests to the local network](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations).

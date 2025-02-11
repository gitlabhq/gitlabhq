---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: NuGet packages in the package registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Publish NuGet packages in your project's package registry. Then, install the
packages whenever you need to use them as a dependency.

The package registry works with:

- [NuGet CLI](https://learn.microsoft.com/en-us/nuget/reference/nuget-exe-cli-reference)
- [.NET Core CLI](https://learn.microsoft.com/en-us/dotnet/core/tools/)
- [Visual Studio](https://visualstudio.microsoft.com/vs/)

For documentation of the specific API endpoints that these
clients use, see the [NuGet API documentation](../../../api/packages/nuget.md).

Learn how to [install NuGet](../workflows/build_packages.md#nuget).

## Use the GitLab endpoint for NuGet Packages

To use the GitLab endpoint for NuGet Packages, choose an option:

- **Project-level**: Use when you have few NuGet packages and they are not in
  the same GitLab group.
- **Group-level**: Use when you have many NuGet packages in different projects within the
  same GitLab group.

Some features such as [publishing](#publish-a-nuget-package) a package are only available on the project-level endpoint.

When asking for versions of a given NuGet package name, the GitLab package registry returns a maximum of 300 most recent versions.

Do not use authentication methods other than the methods documented here. Undocumented authentication methods might be removed in the future.

WARNING:
Because of how NuGet handles credentials, the package registry rejects anonymous requests on the group-level endpoint.
To work around this limitation, set up [authentication](#add-the-package-registry-as-a-source-for-nuget-packages).

## Add the package registry as a source for NuGet packages

To publish and install packages to the package registry, you must add the
package registry as a source for your packages.

Prerequisites:

- Your GitLab username.
- A personal access token or deploy token. For repository authentication:
  - You can generate a [personal access token](../../profile/personal_access_tokens.md).
    - To install packages from the repository, the scope of the token must include `read_api` or `api`.
    - To publish packages to the repository, the scope of the token must include `api`.
  - You can generate a [deploy token](../../project/deploy_tokens/_index.md).
    - To install packages from the repository, the scope of the token must include `read_package_registry`.
    - To publish packages to the repository, the scope of the token must include `write_package_registry`.
- A name for your source.
- Depending on the [endpoint level](#use-the-gitlab-endpoint-for-nuget-packages) you use, either:
  - Your project ID, which is found on your [project overview page](../../project/working_with_projects.md#access-a-project-by-using-the-project-id).
  - Your group ID, which is found on your group's home page.

You can now add a new source to NuGet with:

- [NuGet CLI](#add-a-source-with-the-nuget-cli)
- [Visual Studio](#add-a-source-with-visual-studio)
- [.NET CLI](#add-a-source-with-the-net-cli)
- [Configuration file](#add-a-source-with-a-configuration-file)
- [Chocolatey CLI](#add-a-source-with-chocolatey-cli)

### Add a source with the NuGet CLI

#### Project-level endpoint

A project-level endpoint is required to publish NuGet packages to the package registry.
A project-level endpoint is also required to install NuGet packages from a project.

To use the [project-level](#use-the-gitlab-endpoint-for-nuget-packages) NuGet endpoint, add the package registry as a source with `nuget`:

```shell
nuget source Add -Name <source_name> -Source "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json" -UserName <gitlab_username or deploy_token_username> -Password <gitlab_personal_access_token or deploy_token>
```

- `<source_name>` is the desired source name.

For example:

```shell
nuget source Add -Name "GitLab" -Source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" -UserName carol -Password 12345678asdf
```

#### Group-level endpoint

To install a NuGet package from a group, use a group-level endpoint.

To use the [group-level](#use-the-gitlab-endpoint-for-nuget-packages) NuGet endpoint, add the package registry as a source with `nuget`:

```shell
nuget source Add -Name <source_name> -Source "https://gitlab.example.com/api/v4/groups/<your_group_id>/-/packages/nuget/index.json" -UserName <gitlab_username or deploy_token_username> -Password <gitlab_personal_access_token or deploy_token>
```

- `<source_name>` is the desired source name.

For example:

```shell
nuget source Add -Name "GitLab" -Source "https://gitlab.example.com/api/v4/groups/23/-/packages/nuget/index.json" -UserName carol -Password 12345678asdf
```

### Add a source with Visual Studio

#### Project-level endpoint

A project-level endpoint is required to publish NuGet packages to the package registry.
A project-level endpoint is also required to install NuGet packages from a project.

To use the [project-level](#use-the-gitlab-endpoint-for-nuget-packages) NuGet endpoint, add the package registry as a source with Visual Studio:

1. Open [Visual Studio](https://visualstudio.microsoft.com/vs/).
1. In Windows, select **Tools > Options**. On macOS, select **Visual Studio > Preferences**.
1. In the **NuGet** section, select **Sources** to view a list of all your NuGet sources.
1. Select **Add**.
1. Complete the following fields:

   - **Name**: Name for the source.
   - **Source**: `https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json`,
     where `<your_project_id>` is your project ID, and `gitlab.example.com` is
     your domain name.

1. Select **Save**.
1. When you access the package, you must enter your **Username** and **Password**:

   - **Username**: Your GitLab username or deploy token username.
   - **Password**: Your personal access token or deploy token.

The source is displayed in your list.

If you get a warning, ensure that the **Source**, **Username**, and
**Password** are correct.

#### Group-level endpoint

To install a package from a group, use a group-level endpoint.

To use the [group-level](#use-the-gitlab-endpoint-for-nuget-packages) NuGet endpoint, add the package registry as a source with Visual Studio:

1. Open [Visual Studio](https://visualstudio.microsoft.com/vs/).
1. In Windows, select **Tools > Options**. On macOS, select **Visual Studio > Preferences**.
1. In the **NuGet** section, select **Sources** to view a list of all your NuGet sources.
1. Select **Add**.
1. Complete the following fields:

   - **Name**: Name for the source.
   - **Source**: `https://gitlab.example.com/api/v4/groups/<your_group_id>/-/packages/nuget/index.json`,
     where `<your_group_id>` is your group ID, and `gitlab.example.com` is
     your domain name.

1. Select **Save**.
1. When you access the package, you must enter your **Username** and **Password**.

   - **Username**: Your GitLab username or deploy token username.
   - **Password**: Your personal access token or deploy token.

The source is displayed in your list.

If you get a warning, ensure that the **Source**, **Username**, and
**Password** are correct.

### Add a source with the .NET CLI

#### Project-level endpoint

A project-level endpoint is required to publish NuGet packages to the package registry.
A project-level endpoint is also required to install NuGet packages from a project.

To use the [project-level](#use-the-gitlab-endpoint-for-nuget-packages)
NuGet endpoint, add the package registry as a source with `nuget`:

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json" --name <source_name> --username <gitlab_username or deploy_token_username> --password <gitlab_personal_access_token or deploy_token>
```

- `<source_name>` is the desired source name.
- `--store-password-in-clear-text` might be necessary depending on your operating system.

For example:

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" --name gitlab --username carol --password 12345678asdf
```

#### Group-level endpoint

To install a NuGet package from a group, use a group-level endpoint.

To use the [group-level](#use-the-gitlab-endpoint-for-nuget-packages)
NuGet endpoint, add the package registry as a source with `nuget`:

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/groups/<your_group_id>/-/packages/nuget/index.json" --name <source_name> --username <gitlab_username or deploy_token_username> --password <gitlab_personal_access_token or deploy_token>
```

- `<source_name>` is the desired source name.
- `--store-password-in-clear-text` might be necessary depending on your operating system.

For example:

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/groups/23/-/packages/nuget/index.json" --name gitlab --username carol --password 12345678asdf
```

### Add a source with a configuration file

#### Project-level endpoint

A project-level endpoint is required to:

- Publish NuGet packages to the package registry.
- Install NuGet packages from a project.

To use the [project-level](#use-the-gitlab-endpoint-for-nuget-packages) package registry as a source for .NET:

1. In the root of your project, create a file named `nuget.config`.
1. Add this content:

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <configuration>
    <packageSources>
        <clear />
        <add key="gitlab" value="https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json" />
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
   export GITLAB_PACKAGE_REGISTRY_USERNAME=<gitlab_username or deploy_token_username>
   export GITLAB_PACKAGE_REGISTRY_PASSWORD=<gitlab_personal_access_token or deploy_token>
   ```

#### Group-level endpoint

To install a package from a group, use a group-level endpoint.

To use the [group-level](#use-the-gitlab-endpoint-for-nuget-packages) package registry as a source for .NET:

1. In the root of your project, create a file named `nuget.config`.
1. Add this content:

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <configuration>
    <packageSources>
        <clear />
        <add key="gitlab" value="https://gitlab.example.com/api/v4/groups/<your_group_id>/-/packages/nuget/index.json" />
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
   export GITLAB_PACKAGE_REGISTRY_USERNAME=<gitlab_username or deploy_token_username>
   export GITLAB_PACKAGE_REGISTRY_PASSWORD=<gitlab_personal_access_token or deploy_token>
   ```

### Add a source with Chocolatey CLI

You can add a source feed with the Chocolatey CLI. If you use Chocolatey CLI v1.x, you can add only a NuGet v2 source feed.

#### Configure a project-level endpoint

You need a project-level endpoint to publish NuGet packages to the package registry.

To use the [project-level](#use-the-gitlab-endpoint-for-nuget-packages) package registry as a source for Chocolatey:

- Add the package registry as a source with `choco`:

  ```shell
  choco source add -n=gitlab -s "'https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/v2'" -u=<gitlab_username or deploy_token_username> -p=<gitlab_personal_access_token or deploy_token>
  ```

## Publish a NuGet package

Prerequisites:

- Set up the [source](#add-the-package-registry-as-a-source-for-nuget-packages) with a [project-level endpoint](#use-the-gitlab-endpoint-for-nuget-packages).

When publishing packages:

- The package registry on GitLab.com can store up to 5 GB of content.
  This limit is [configurable for GitLab Self-Managed](../../../administration/instance_limits.md#package-registry-limits).
- If you publish the same package with the same version multiple times, each
  consecutive upload is saved as a separate file. When installing a package,
  GitLab serves the most recent file.
- When publishing packages to GitLab, they aren't displayed in the packages user
  interface of your project immediately. It can take up to 10 minutes to process
  a package.

### Publish a package with the NuGet CLI

Prerequisites:

- [A NuGet package created with NuGet CLI](https://learn.microsoft.com/en-us/nuget/create-packages/creating-a-package).
- Set a [project-level endpoint](#use-the-gitlab-endpoint-for-nuget-packages).

Publish a package by running this command:

```shell
nuget push <package_file> -Source <source_name>
```

- `<package_file>` is your package filename, ending in `.nupkg`.
- `<source_name>` is the [source name used during setup](#add-a-source-with-the-nuget-cli).

### Publish a package with the .NET CLI

> - Publishing a package with `--api-key` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214674) in GitLab 16.1.

Prerequisites:

- [A NuGet package created with .NET CLI](https://learn.microsoft.com/en-us/nuget/create-packages/creating-a-package-dotnet-cli).
- Set a [project-level endpoint](#use-the-gitlab-endpoint-for-nuget-packages).

Publish a package by running this command:

```shell
dotnet nuget push <package_file> --source <source_name>
```

- `<package_file>` is your package filename, ending in `.nupkg`.
- `<source_name>` is the [source name used during setup](#add-a-source-with-the-net-cli).

For example:

```shell
dotnet nuget push MyPackage.1.0.0.nupkg --source gitlab
```

You can publish a package using the `--api-key` option instead of `username` and `password`:

```shell
dotnet nuget push <package_file> --source <source_url> --api-key <gitlab_personal_access_token, deploy_token or job token>
```

- `<package_file>` is your package filename, ending in `.nupkg`.
- `<source_url>` is the URL of the NuGet package registry.

For example:

```shell
dotnet nuget push MyPackage.1.0.0.nupkg --source https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json --api-key <gitlab_personal_access_token, deploy_token or job token>
```

### Publish a NuGet package by using CI/CD

If you're using NuGet with GitLab CI/CD, a CI job token can be used instead of a
personal access token or deploy token. The token inherits the permissions of the
user that generates the pipeline.

This example shows how to create a new package each time the `main` branch is
updated:

1. Add a `deploy` job to your `.gitlab-ci.yml` file:

   ```yaml
   default:
     image: mcr.microsoft.com/dotnet/core/sdk:3.1

   stages:
     - deploy

   deploy:
     stage: deploy
     script:
       - dotnet pack -c Release
       - dotnet nuget add source "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
       - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
     rules:
      - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
     environment: production
   ```

1. Commit the changes and push it to your GitLab repository to trigger a new CI/CD build.

### Publish a NuGet package with Chocolatey CLI

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416404) in GitLab 16.2.

Prerequisites:

- The project-level package registry is a source for Chocolatey.

To publish a package with the Chocolatey CLI:

```shell
choco push <package_file> --source <source_url> --api-key <gitlab_personal_access_token, deploy_token or job token>
```

In this command:

- `<package_file>` is your package filename and ends with `.nupkg`.
- `<source_url>` is the URL of the NuGet v2 feed package registry.

For example:

```shell
choco push MyPackage.1.0.0.nupkg --source "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/v2" --api-key <gitlab_personal_access_token, deploy_token or job token>
```

### Publishing a package with the same name or version

When you publish a package with the same name or version as an existing package,
the existing package is overwritten.

### Do not allow duplicate NuGet packages

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/293748) in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `nuget_duplicates_option`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/419078) in GitLab 16.6. Feature flag `nuget_duplicates_option` removed.
> - Required role [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/370471) from Maintainer to Owner in GitLab 17.0.

To prevent users from publishing duplicate NuGet packages, you can use the [GraphQl API](../../../api/graphql/reference/_index.md#packagesettings) or the UI.

In the UI:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Packages and registries**.
1. In the **NuGet** row of the **Duplicate packages** table, turn off the **Allow duplicates** toggle.
1. Optional. In the **Exceptions** text box, enter a regular expression that matches the names and versions of packages to allow.

NOTE:
If **Allow duplicates** is turned on, you can specify package names and versions that should not have duplicates in the **Exceptions** text box.

Your changes are automatically saved.

WARNING:
If the .nuspec file isn't located in the root of the package or the beginning of the archive, the package might
not be recognized as a duplicate right away. However, it will be rejected later, and an error will be shown in the UI.

## Install packages

If multiple packages have the same name and version, when you install
a package, the most recently-published package is retrieved.

To install a NuGet package from the package registry, you must first
[add a project-level or group-level endpoint](#add-the-package-registry-as-a-source-for-nuget-packages).

### Install a package with the NuGet CLI

WARNING:
By default, `nuget` checks the official source at `nuget.org` first. If you have
a NuGet package in the package registry with the same name as a package at
`nuget.org`, you must specify the source name to install the correct package.

Install the latest version of a package by running this command:

```shell
nuget install <package_id> -OutputDirectory <output_directory> \
  -Version <package_version> \
  -Source <source_name>
```

- `<package_id>` is the package ID.
- `<output_directory>` is the output directory, where the package is installed.
- `<package_version>` The package version. Optional.
- `<source_name>` The source name. Optional.

### Install a package with the .NET CLI

WARNING:
If you have a package in the package registry with the same name as a package at
a different source, verify the order in which `dotnet` checks sources during
install. This is defined in the `nuget.config` file.

Install the latest version of a package by running this command:

```shell
dotnet add package <package_id> \
       -v <package_version>
```

- `<package_id>` is the package ID.
- `<package_version>` is the package version. Optional.

### Install a package using NuGet v2 feed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416405) in GitLab 16.5.

Prerequisites:

- The project-level package registry is a [v2 feed source](#add-a-source-with-chocolatey-cli) for Chocolatey.
- A version must be provided when installing or upgrading a package using NuGet v2 feed.

To install a package with the Chocolatey CLI:

```shell
choco install <package_id> -Source <source_url> -Version <package_version>
```

In this command:

- `<package_id>` is the package ID.
- `<source_url>` is the URL or name of the NuGet v2 feed package registry.
- `<package_version>` is the package version.

For example:

```shell
choco install MyPackage -Source gitlab -Version 1.0.2

# or

choco install MyPackage -Source "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/v2" -u <username> -p <gitlab_personal_access_token, deploy_token or job token> -Version 1.0.2
```

To upgrade a package with the Chocolatey CLI:

```shell
choco upgrade <package_id> -Source <source_url> -Version <package_version>
```

In this command:

- `<package_id>` is the package ID.
- `<source_url>` is the URL or name of the NuGet v2 feed package registry.
- `<package_version>` is the package version.

For example:

```shell
choco upgrade MyPackage -Source gitlab -Version 1.0.3
```

## Delete a package

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38275) in GitLab 16.5.

WARNING:
Deleting a package is a permanent action that cannot be undone.

Prerequisites:

- You must have the [Maintainer](../../permissions.md#project-members-permissions) role or higher in the project.
- You must have both the package name and version.

To delete a package with the NuGet CLI:

```shell
nuget delete <package_id> <package_version> -Source <source_name> -ApiKey <gitlab_personal_access_token, deploy_token or job token>
```

In this command:

- `<package_id>` is the package ID.
- `<package_version>` is the package version.
- `<source_name>` is the source name.

For example:

```shell
nuget delete MyPackage 1.0.0 -Source gitlab -ApiKey <gitlab_personal_access_token, deploy_token or job token>
```

## Symbol packages

If you push a `.nupkg`, symbol package files in the `.snupkg` format are uploaded automatically. You
can also push them manually:

```shell
nuget push My.Package.snupkg -Source <source_name>
```

### Use the package registry as a symbol server

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416178) in GitLab 16.7.

GitLab can consume symbol files from the NuGet package registry,
so you can use the package registry as a symbol server.

To use the symbol server:

1. Enable the `nuget_symbol_server_enabled` namespace setting with the [GraphQl API](../../../api/graphql/reference/_index.md#packagesettings).
1. Configure your debugger to use the symbol server.
   For example, to configure Visual Studio:

   1. Open **Tools > Preferences**.
   1. Select **Debugger > Symbol sources**.
   1. Select **Add**.
   1. Fill in the required fields. The URL for the symbol server is:

      ```shell
      https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/symbolfiles
      -- or --
      https://gitlab.example.com/api/v4/groups/<your_group_id>/-/packages/nuget/symbolfiles
      ```

   1. Select **Add Source**.

After you configure the debugger, you can debug your application as usual.
The debugger automatically downloads the symbol PDB files from the package registry as long as they're available.

#### Consuming symbol packages

When the debugger is configured to consume symbol packages, the debugger sends the following
in a request:

- `Symbolchecksum` header: The SHA-256 checksum of the symbol file.
- `file_name` request parameter: The name of the symbol file. For example, `mypackage.pdb`.
- `signature` request parameter: The GUID and age of the PDB file.

The GitLab server matches this information to a symbol file and returns it.

Note that:

- Only portable PDB files are supported.
- Because debuggers can't provide authentication tokens, the symbol server endpoint doesn't support the usual authentication methods.
  The GitLab server requires the `signature` and `Symbolchecksum` to return the correct symbol file.

## Supported CLI commands

> - `nuget delete` and `dotnet nuget delete` commands [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38275) in GitLab 16.5.

The GitLab NuGet repository supports the following commands for the NuGet CLI (`nuget`) and the .NET
CLI (`dotnet`):

- `nuget push`: Upload a package to the registry.
- `dotnet nuget push`: Upload a package to the registry.
- `nuget install`: Install a package from the registry.
- `dotnet add`: Install a package from the registry.
- `nuget delete`: Delete a package from the registry.
- `dotnet nuget delete`: Delete a package from the registry.

## Example project

For an example, see the Guided Exploration project
[Utterly Automated Software and Artifact Versioning with GitVersion](https://gitlab.com/guided-explorations/devops-patterns/utterly-automated-versioning).
This project:

- Generates NuGet packages by the `msbuild` method.
- Generates NuGet packages by the `nuget.exe` method.
- Uses GitLab releases and `release-cli` in connection with NuGet packaging.
- Uses a tool called [GitVersion](https://gitversion.net/)
  to automatically determine and increment versions for the NuGet package in complex repositories.

You can copy this example project to your own group or instance for testing. See the project page
for more details on what other GitLab CI patterns are demonstrated.

## Troubleshooting

### Clear NuGet cache

To improve performance, NuGet caches files related to a package. If you encounter issues, clear the
cache with this command:

```shell
nuget locals all -clear
```

### Errors when trying to publish NuGet packages in a Docker-based GitLab installation

Webhook requests to local network addresses are blocked to prevent exploitation of
internal web services. If you get `Error publishing` or
`Invalid Package: Failed metadata extraction error` messages
when you try to publish NuGet packages, change your network settings to
[allow webhook and integration requests to the local network](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations).

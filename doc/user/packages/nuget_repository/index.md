---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# NuGet packages in the Package Registry

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/20050) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.8.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Core in 13.3.

Publish NuGet packages in your project’s Package Registry. Then, install the
packages whenever you need to use them as a dependency.

The Package Registry works with:

- [NuGet CLI](https://docs.microsoft.com/en-us/nuget/reference/nuget-exe-cli-reference)
- [.NET Core CLI](https://docs.microsoft.com/en-us/dotnet/core/tools/)
- [Visual Studio](https://visualstudio.microsoft.com/vs/)

## Install NuGet

The required minimum versions are:

- [NuGet CLI 5.1 or later](https://www.nuget.org/downloads). If you have
  [Visual Studio](https://visualstudio.microsoft.com/vs/), the NuGet CLI is
  probably already installed.
- Alternatively, you can use [.NET SDK 3.0 or later](https://dotnet.microsoft.com/download/dotnet-core/3.0),
  which installs the NuGet CLI.
- NuGet protocol version 3 or later.

Verify that the [NuGet CLI](https://www.nuget.org/) is installed by running:

```shell
nuget help
```

The output should be similar to:

```plaintext
NuGet Version: 5.1.0.6013
usage: NuGet <command> [args] [options]
Type 'NuGet help <command>' for help on a specific command.

Available commands:

[output truncated]
```

### Install NuGet on macOS

For macOS, you can use [Mono](https://www.mono-project.com/) to run the
NuGet CLI.

1. If you use Homebrew, to install Mono, run `brew install mono`.
1. Download the Windows C# binary `nuget.exe` from the [NuGet CLI page](https://www.nuget.org/downloads).
1. Run this command:

   ```shell
   mono nuget.exe
   ```

## Add the Package Registry as a source for NuGet packages

To publish and install packages to the Package Registry, you must add the
Package Registry as a source for your packages.

Prerequisites:

- Your GitLab username.
- A personal access token or deploy token. For repository authentication:
  - You can generate a [personal access token](../../../user/profile/personal_access_tokens.md)
    with the scope set to `api`.
  - You can generate a [deploy token](../../project/deploy_tokens/index.md)
    with the scope set to `read_package_registry`, `write_package_registry`, or
    both.
- A name for your source.
- Your project ID, which is found on your project's home page.

You can now add a new source to NuGet with:

- [NuGet CLI](#add-a-source-with-the-nuget-cli)
- [Visual Studio](#add-a-source-with-visual-studio)
- [.NET CLI](#add-a-source-with-the-net-cli)

### Add a source with the NuGet CLI

To add the Package Registry as a source with `nuget`:

```shell
nuget source Add -Name <source_name> -Source "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json" -UserName <gitlab_username or deploy_token_username> -Password <gitlab_personal_access_token or deploy_token>
```

- `<source_name>` is the desired source name.

For example:

```shell
nuget source Add -Name "GitLab" -Source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" -UserName carol -Password 12345678asdf
```

### Add a source with Visual Studio

To add the Package Registry as a source with Visual Studio:

1. Open [Visual Studio](https://visualstudio.microsoft.com/vs/).
1. In Windows, select **File > Options**. On macOS, select **Visual Studio > Preferences**.
1. In the **NuGet** section, select **Sources** to view a list of all your NuGet sources.
1. Select **Add**.
1. Complete the following fields:
   - **Name**: Name for the source.
   - **Location**: `https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json`,
     where `<your_project_id>` is your project ID, and `gitlab.example.com` is
     your domain name.
   - **Username**: Your GitLab username or deploy token username.
   - **Password**: Your personal access token or deploy token.

   ![Visual Studio Adding a NuGet source](img/visual_studio_adding_nuget_source.png)

1. Click **Save**.

The source is displayed in your list.

![Visual Studio NuGet source added](img/visual_studio_nuget_source_added.png)

If you get a warning, ensure that the **Location**, **Username**, and
**Password** are correct.

### Add a source with the .NET CLI

To add the Package Registry as a source for .NET:

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
            <add key="Username" value="<gitlab_username or deploy_token_username>" />
            <add key="ClearTextPassword" value="<gitlab_personal_access_token or deploy_token>" />
        </gitlab>
    </packageSourceCredentials>
   </configuration>
   ```

## Publish a NuGet package

When publishing packages:

- The Package Registry on GitLab.com can store up to 500 MB of content.
  This limit is [configurable for self-managed GitLab instances](../../../administration/instance_limits.md#package-registry-limits).
- If you publish the same package with the same version multiple times, each
  consecutive upload is saved as a separate file. When installing a package,
  GitLab serves the most recent file.
- When publishing packages to GitLab, they aren't displayed in the packages user
  interface of your project immediately. It can take up to 10 minutes to process
  a package.

### Publish a package with the NuGet CLI

Prerequisite:

- [A NuGet package created with NuGet CLI](https://docs.microsoft.com/en-us/nuget/create-packages/creating-a-package).

Publish a package by running this command:

```shell
nuget push <package_file> -Source <source_name>
```

- `<package_file>` is your package filename, ending in `.nupkg`.
- `<source_name>` is the [source name used during setup](#add-a-source-with-the-nuget-cli).

### Publish a package with the .NET CLI

Prerequisite:

[A NuGet package created with .NET CLI](https://docs.microsoft.com/en-us/nuget/create-packages/creating-a-package-dotnet-cli).

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

### Publish a NuGet package by using CI/CD

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36424) in GitLab 13.3.

If you’re using NuGet with GitLab CI/CD, a CI job token can be used instead of a
personal access token or deploy token. The token inherits the permissions of the
user that generates the pipeline.

This example shows how to create a new package each time the `master` branch is
updated:

1. Add a `deploy` job to your `.gitlab-ci.yml` file:

   ```yaml
   image: mcr.microsoft.com/dotnet/core/sdk:3.1

   stages:
     - deploy

   deploy:
     stage: deploy
     script:
       - dotnet pack -c Release
       - dotnet nuget add source "$CI_SERVER_URL/api/v4/projects/$CI_PROJECT_ID/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
       - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
     only:
       - master
   ```

1. Commit the changes and push it to your GitLab repository to trigger a new CI/CD build.

## Install packages

### Install a package with the NuGet CLI

CAUTION: **Warning:**
By default, `nuget` checks the official source at `nuget.org` first. If you have
a NuGet package in the Package Registry with the same name as a package at
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

CAUTION: **Warning:**
If you have a package in the Package Registry with the same name as a package at
a different source, verify the order in which `dotnet` checks sources during
install. This is defined in the `nuget.config` file.

Install the latest version of a package by running this command:

```shell
dotnet add package <package_id> \
       -v <package_version>
```

- `<package_id>` is the package ID.
- `<package_version>` is the package version. Optional.

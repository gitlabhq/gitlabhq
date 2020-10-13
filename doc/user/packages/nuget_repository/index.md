---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab NuGet Repository

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/20050) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.8.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Core in 13.3.

With the GitLab NuGet Repository, every project can have its own space to store NuGet packages.

The GitLab NuGet Repository works with:

- [NuGet CLI](https://docs.microsoft.com/en-us/nuget/reference/nuget-exe-cli-reference)
- [.NET Core CLI](https://docs.microsoft.com/en-us/dotnet/core/tools/)
- [Visual Studio](https://visualstudio.microsoft.com/vs/)

## Setting up your development environment

[NuGet CLI 5.2 or later](https://www.nuget.org/downloads) is required. Earlier versions have not been tested
against the GitLab NuGet Repository and might not work. If you have [Visual Studio](https://visualstudio.microsoft.com/vs/),
NuGet CLI is probably already installed.

Alternatively, you can use [.NET SDK 3.0 or later](https://dotnet.microsoft.com/download/dotnet-core/3.0), which installs NuGet CLI.

You can confirm that [NuGet CLI](https://www.nuget.org/) is properly installed with:

```shell
nuget help
```

You should see something similar to:

```plaintext
NuGet Version: 5.2.0.6090
usage: NuGet <command> [args] [options]
Type 'NuGet help <command>' for help on a specific command.

Available commands:

[output truncated]
```

NOTE: **Note:**
GitLab currently only supports NuGet v3. Earlier versions are not supported.

### macOS support

For macOS, you can also use [Mono](https://www.mono-project.com/) to run
the NuGet CLI. For Homebrew users, run `brew install mono` to install
Mono. Then you should be able to download the Windows C# binary
`nuget.exe` from the [NuGet CLI page](https://www.nuget.org/downloads)
and run:

```shell
mono nuget.exe
```

## Enabling the NuGet Repository

NOTE: **Note:**
This option is available only if your GitLab administrator has
[enabled support for the Package Registry](../../../administration/packages/index.md).

When the NuGet Repository is enabled, it is available for all new projects
by default. To enable it for existing projects, or if you want to disable it:

1. Navigate to your project's **Settings > General > Visibility, project features, permissions**.
1. Find the Packages feature and enable or disable it.
1. Click on **Save changes** for the changes to take effect.

You should then be able to see the **Packages & Registries** section on the left sidebar.

## Adding the GitLab NuGet Repository as a source to NuGet

You need the following:

- Your GitLab username.
- A personal access token or deploy token. For repository authentication:
  - You can generate a [personal access token](../../../user/profile/personal_access_tokens.md) with the scope set to `api`.
  - You can generate a [deploy token](./../../project/deploy_tokens/index.md) with the scope set to `read_package_registry`, `write_package_registry`, or both.
- A suitable name for your source.
- Your project ID which can be found on the home page of your project.

You can now add a new source to NuGet with:

- [NuGet CLI](#add-nuget-repository-source-with-nuget-cli)
- [Visual Studio](#add-nuget-repository-source-with-visual-studio).
- [.NET CLI](#add-nuget-repository-source-with-net-cli)

### Add NuGet Repository source with NuGet CLI

To add the GitLab NuGet Repository as a source with `nuget`:

```shell
nuget source Add -Name <source_name> -Source "https://gitlab-instance.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json" -UserName <gitlab_username or deploy_token_username> -Password <gitlab_personal_access_token or deploy_token>
```

Where:

- `<source_name>` is your desired source name.

For example:

```shell
nuget source Add -Name "GitLab" -Source "https://gitlab.example/api/v4/projects/10/packages/nuget/index.json" -UserName carol -Password 12345678asdf
```

### Add NuGet Repository source with Visual Studio

1. Open [Visual Studio](https://visualstudio.microsoft.com/vs/).
1. Open the **FILE > OPTIONS** (Windows) or **Visual Studio > Preferences** (Mac OS).
1. In the **NuGet** section, open **Sources** to see a list of all your NuGet sources.
1. Click **Add**.
1. Fill the fields with:
   - **Name**: Desired name for the source
   - **Location**: `https://gitlab.com/api/v4/projects/<your_project_id>/packages/nuget/index.json`
     - Replace `<your_project_id>` with your project ID.
     - If you have a self-managed GitLab installation, replace `gitlab.com` with your domain name.
   - **Username**: Your GitLab username or deploy token username
   - **Password**: Your personal access token or deploy token

   ![Visual Studio Adding a NuGet source](img/visual_studio_adding_nuget_source.png)

1. Click **Save**.

   ![Visual Studio NuGet source added](img/visual_studio_nuget_source_added.png)

In case of any warning, please make sure that the **Location**, **Username**, and **Password** are correct.

### Add NuGet Repository source with .NET CLI

To add the GitLab NuGet Repository as a source for .NET, create a file named `nuget.config` in the root of your project with the following content:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
        <clear />
        <add key="gitlab" value="https://gitlab-instance.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json" />
    </packageSources>
    <packageSourceCredentials>
        <gitlab>
            <add key="Username" value="<gitlab_username or deploy_token_username>" />
            <add key="ClearTextPassword" value="<gitlab_personal_access_token or deploy_token>" />
        </gitlab>
    </packageSourceCredentials>
</configuration>
```

## Uploading packages

When uploading packages, note that:

- The Package Registry on GitLab.com can store up to 500 MB of content. This limit is [configurable for self-managed GitLab instances](../../../administration/instance_limits.md#package-registry-limits). 
- If you upload the same package with the same version multiple times, each consecutive upload
  is saved as a separate file. When installing a package, GitLab serves the most recent file.
- When uploading packages to GitLab, they are not displayed in the packages UI of your project
  immediately. It can take up to 10 minutes to process a package.

### Upload packages with NuGet CLI

This section assumes that your project is properly built and you already [created a NuGet package with NuGet CLI](https://docs.microsoft.com/en-us/nuget/create-packages/creating-a-package).
Upload your package using the following command:

```shell
nuget push <package_file> -Source <source_name>
```

Where:

- `<package_file>` is your package filename, ending in `.nupkg`.
- `<source_name>` is the [source name used during setup](#adding-the-gitlab-nuget-repository-as-a-source-to-nuget).

### Upload packages with .NET CLI

This section assumes that your project is properly built and you already [created a NuGet package with .NET CLI](https://docs.microsoft.com/en-us/nuget/create-packages/creating-a-package-dotnet-cli).
Upload your package using the following command:

```shell
dotnet nuget push <package_file> --source <source_name>
```

Where:

- `<package_file>` is your package filename, ending in `.nupkg`.
- `<source_name>` is the [source name used during setup](#adding-the-gitlab-nuget-repository-as-a-source-to-nuget).

For example:

```shell
dotnet nuget push MyPackage.1.0.0.nupkg --source gitlab
```

## Install packages

### Install a package with NuGet CLI

CAUTION: **Warning:**
By default, `nuget` checks the official source at `nuget.org` first. If you have a package in the
GitLab NuGet Repository with the same name as a package at `nuget.org`, you must specify the source
name to install the correct package.

Install the latest version of a package using the following command:

```shell
nuget install <package_id> -OutputDirectory <output_directory> \
  -Version <package_version> \
  -Source <source_name>
```

Where:

- `<package_id>` is the package ID.
- `<output_directory>` is the output directory, where the package is installed.
- `<package_version>` (Optional) is the package version.
- `<source_name>` (Optional) is the source name.

### Install a package with .NET CLI

CAUTION: **Warning:**
If you have a package in the GitLab NuGet Repository with the same name as a package at a different source,
you should verify the order in which `dotnet` checks sources during install. This is defined in the
`nuget.config` file.

Install the latest version of a package using the following command:

```shell
dotnet add package <package_id> \
       -v <package_version>
```

Where:

- `<package_id>` is the package ID.
- `<package_version>` (Optional) is the package version.

## Publishing a NuGet package with CI/CD

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36424) in GitLab 13.3.

If you’re using NuGet with GitLab CI/CD, a CI job token can be used instead of a personal access token or deploy token.
The token inherits the permissions of the user that generates the pipeline.

This example shows how to create a new package each time the `master` branch
is updated:

1. Add a `deploy` job to your `.gitlab-ci.yml` file:

   ```yaml
   image: mcr.microsoft.com/dotnet/core/sdk:3.1

   stages:
     - deploy

   deploy:
     stage: deploy
     script:
       - dotnet restore -p:Configuration=Release
       - dotnet build -c Release
       - dotnet pack -c Release
       - dotnet nuget add source "$CI_SERVER_URL/api/v4/projects/$CI_PROJECT_ID/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
       - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
     only:
       - master
   ```

1. Commit the changes and push it to your GitLab repository to trigger a new CI build.

# GitLab NuGet Repository **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/20050) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.8.

With the GitLab NuGet Repository, every project can have its own space to store NuGet packages.

The GitLab NuGet Repository works with:

- [NuGet CLI](https://docs.microsoft.com/en-us/nuget/reference/nuget-exe-cli-reference)
- [.NET Core CLI](https://docs.microsoft.com/en-us/dotnet/core/tools/)
- [Visual Studio](https://visualstudio.microsoft.com/vs/)

## Setting up your development environment

You will need [NuGet CLI 5.2 or later](https://www.nuget.org/downloads). Earlier versions have not been tested
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
[enabled support for the Package Registry](../../../administration/packages/index.md). **(PREMIUM ONLY)**

After the NuGet Repository is enabled, it will be available for all new projects
by default. To enable it for existing projects, or if you want to disable it:

1. Navigate to your project's **Settings > General > Permissions**.
1. Find the Packages feature and enable or disable it.
1. Click on **Save changes** for the changes to take effect.

You should then be able to see the **Packages** section on the left sidebar.

## Adding the GitLab NuGet Repository as a source to NuGet

You will need the following:

- Your GitLab username.
- A personal access token. You can generate a [personal access token](../../../user/profile/personal_access_tokens.md) with the scope set to `api` for repository authentication.
- A suitable name for your source.
- Your project ID which can be found on the home page of your project.

You can now add a new source to NuGet with:

- [NuGet CLI](#add-nuget-repository-source-with-nuget-cli)
- [Visual Studio](#add-nuget-repository-source-with-visual-studio).
- [.NET CLI](#add-nuget-repository-source-with-net-cli)

### Add NuGet Repository source with NuGet CLI

To add the GitLab NuGet Repository as a source with `nuget`:

```shell
nuget source Add -Name <source_name> -Source "https://gitlab-instance.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json" -UserName <gitlab_username> -Password <gitlab_personal_access_token>
```

Where:

- `<source_name>` is your desired source name.

For example:

```shell
nuget source Add -Name "GitLab" -Source "https//gitlab.example/api/v4/projects/10/packages/nuget/index.json" -UserName carol -Password 12345678asdf
```

### Add NuGet Repository source with Visual Studio

1. Open [Visual Studio](https://visualstudio.microsoft.com/vs/).
1. Open the **FILE > OPTIONS** (Windows) or **Visual Studio > Preferences** (Mac OS).
1. In the **NuGet** section, open **Sources**. You will see a list of all your NuGet sources.
1. Click **Add**.
1. Fill the fields with:
   - **Name**: Desired name for the source
   - **Location**: `https://gitlab.com/api/v4/projects/<your_project_id>/packages/nuget/index.json`
     - Replace `<your_project_id>` with your project ID.
     - If you have a self-managed GitLab installation, replace `gitlab.com` with your domain name.
   - **Username**: Your GitLab username
   - **Password**: Your personal access token

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
            <add key="Username" value="<gitlab_username>" />
            <add key="ClearTextPassword" value="<gitlab_personal_access_token>" />
        </gitlab>
    </packageSourceCredentials>
</configuration>
```

## Uploading packages

When uploading packages, note that:

- The maximum allowed size is 50 Megabytes.
- If you upload the same package with the same version multiple times, each consecutive upload
  is saved as a separate file. When installing a package, GitLab will serve the most recent file.
- When uploading packages to GitLab, they will not be displayed in the packages UI of your project
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
name or the wrong package will be installed.

Install the latest version of a package using the following command:

```shell
nuget install <package_id> -OutputDirectory <output_directory> \
  -Version <package_version> \
  -Source <source_name>
```

Where:

- `<package_id>` is the package ID.
- `<output_directory>` is the output directory, where the package will be installed.
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

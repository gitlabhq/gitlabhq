# GitLab NuGet Repository **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/20050) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.8.

CAUTION: **Work in progress**
This feature is in development, sections on uploading and installing packages will be coming soon, please follow along and help us make sure we're building the right solution for you in the [NuGet issue](https://gitlab.com/gitlab-org/gitlab/issues/20050).

With the GitLab NuGet Repository, every project can have its own space to store NuGet packages.

The GitLab NuGet Repository works with either [nuget CLI](https://www.nuget.org/) or [Visual Studio](https://visualstudio.microsoft.com/vs/).

## Setting up your development environment

You will need [nuget CLI](https://www.nuget.org/) 5.2 or above. Previous versions have not been tested against the GitLab NuGet Repository and might not work. You can install it by visiting the [downloads page](https://www.nuget.org/downloads).

If you have [Visual Studio](https://visualstudio.microsoft.com/vs/), [nuget CLI](https://www.nuget.org/) is probably already installed.

You can confirm that [nuget CLI](https://www.nuget.org/) is properly installed with:

```shell
nuget help
```

You should see something similar to:

```
NuGet Version: 5.2.0.6090
usage: NuGet <command> [args] [options]
Type 'NuGet help <command>' for help on a specific command.

Available commands:

[output truncated]
```

## Enabling the NuGet Repository

NOTE: **Note:**
This option is available only if your GitLab administrator has
[enabled support for the NuGet Repository](../../../administration/packages/index.md).**(PREMIUM ONLY)**

After the NuGet Repository is enabled, it will be available for all new projects
by default. To enable it for existing projects, or if you want to disable it:

1. Navigate to your project's **Settings > General > Permissions**.
1. Find the Packages feature and enable or disable it.
1. Click on **Save changes** for the changes to take effect.

You should then be able to see the **Packages** section on the left sidebar.

## Adding the GitLab NuGet Repository as a source to nuget

You will need the following:

- Your GitLab username.
- A personal access token. You can generate a [personal access token](../../../user/profile/personal_access_tokens.md) with the scope set to `api` for repository authentication.
- A suitable name for your source.
- Your project ID which can be found on the home page of your project.

You can now add a new source to nuget either using [nuget CLI](https://www.nuget.org/) or [Visual Studio](https://visualstudio.microsoft.com/vs/).

### Using nuget CLI

To add the GitLab NuGet Repository as a source with `nuget`:

```shell
nuget source Add -Name <source_name> -Source "https://example.gitlab.com/api/v4/projects/<your_project_id>/packages/nuget/index.json" -UserName <gitlab_username> -Password <gitlab_token>
```

Replace:

- `<source_name>` with your desired source name.
- `<your_project_id>` with your project ID.
- `<gitlab-username>` with your GitLab username.
- `<gitlab-token>` with your personal access token.
- `example.gitlab.com` with the URL of the GitLab instance you're using.

For example:

```shell
nuget source Add -Name "GitLab" -Source "https//gitlab.example/api/v4/projects/10/packages/nuget/index.json" -UserName carol -Password 12345678asdf
```

### Using Visual Studio

1. Open [Visual Studio](https://visualstudio.microsoft.com/vs/).
1. Open the **FILE > OPTIONS** (Windows) or **Visual Studio > Preferences** (Mac OS).
1. In the **NuGet** section, open **Sources**. You will see a list of all your NuGet sources.
1. Click **Add**.
1. Fill the fields with:
   - **Name**: Desired name for the source
   - **Location**: `https://gitlab.com/api/v4/projects/<your_project_id>/packages/nuget/index.json`
     - Replace `<your_project_id>` with your project ID.
     - If you have a self-hosted GitLab installation, replace `gitlab.com` with your domain name.
   - **Username**: Your GitLab username
   - **Password**: Your personal access token

   ![Visual Studio Adding a NuGet source](img/visual_studio_adding_nuget_source.png)

1. Click **Save**.

   ![Visual Studio NuGet source added](img/visual_studio_nuget_source_added.png)

In case of any warning, please make sure that the **Location**, **Username** and **Password** are correct.

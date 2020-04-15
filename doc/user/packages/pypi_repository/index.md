# GitLab PyPi Repository **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/208747) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.10.

With the GitLab PyPi Repository, every project can have its own space to store PyPi packages.

The GitLab PyPi Repository works with:

- [pip](https://pypi.org/project/pip/)
- [twine](https://pypi.org/project/twine/)

## Setting up your development environment

You will need a recent version of [pip](https://pypi.org/project/pip/) and [twine](https://pypi.org/project/twine/).

## Enabling the PyPi Repository

NOTE: **Note:**
This option is available only if your GitLab administrator has
[enabled support for the Package Registry](../../../administration/packages/index.md). **(PREMIUM ONLY)**

After the PyPi Repository is enabled, it will be available for all new projects
by default. To enable it for existing projects, or if you want to disable it:

1. Navigate to your project's **Settings > General > Permissions**.
1. Find the Packages feature and enable or disable it.
1. Click on **Save changes** for the changes to take effect.

You should then be able to see the **Packages** section on the left sidebar.

## Adding the GitLab PyPi Repository as a source

You will need the following:

- A personal access token. You can generate a [personal access token](../../../user/profile/personal_access_tokens.md) with the scope set to `api` for repository authentication.
- A suitable name for your source.
- Your project ID which can be found on the home page of your project.

Edit your `~/.pypirc` file and add the following:

```ini
[gitlab]
repository = https://gitlab.com/api/v4/projects/<project_id>/packages/pypi
username = __token__
password = <your personal access token>
```

## Uploading packages

When uploading packages, note that:

- The maximum allowed size is 50 Megabytes.
- If you upload the same package with the same version multiple times, each consecutive upload
  is saved as a separate file. When installing a package, GitLab will serve the most recent file.
- When uploading packages to GitLab, they will not be displayed in the packages UI of your project
  immediately. It can take up to 10 minutes to process a package.

### Upload packages with Twine

This section assumes that your project is properly built and you already [created a PyPi package with setuptools](https://packaging.python.org/tutorials/packaging-projects/).
Upload your package using the following command:

```shell
python -m twine upload --repository <source_name> dist/<package_file>
```

Where:

- `<package_file>` is your package filename, ending in `.tar.gz` or `.whl`.
- `<source_name>` is the [source name used during setup](#adding-the-gitlab-pypi-repository-as-a-source).

## Install packages

Install the latest version of a package using the following command:

```shell
pip install --index-url https://__token__:<personal_access_token>@gitlab.com/api/v4/projects/<project_id>/packages/pypi/simple --no-deps <package_name>
```

Where:

- `<package_name>` is the package name.
- `<personal_access_token>` is your personal access token.
- `<project_id>` is your project id number.

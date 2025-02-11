---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: PyPI packages in the package registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The Python Package Index (PyPI) is the official third-party software repository for Python.
Use the GitLab PyPI package registry to publish and share Python packages in your GitLab projects,
groups, and organizations. This integration enables you to manage your Python dependencies alongside
your code, providing a seamless workflow for Python development within GitLab.

The package registry works with:

- [pip](https://pypi.org/project/pip/)
- [twine](https://pypi.org/project/twine/)

For documentation of the specific API endpoints that the `pip` and `twine`
clients use, see the [PyPI API documentation](../../../api/packages/pypi.md).

Learn how to [build a PyPI package](../workflows/build_packages.md#pypi).

## Authenticate with the GitLab package registry

Before you interact with the GitLab package registry, you must authenticate with it.

You can authenticate with:

- A [personal access token](../../profile/personal_access_tokens.md)
  with the scope set to `api`.
- A [deploy token](../../project/deploy_tokens/_index.md) with the scope set to
  `read_package_registry`, `write_package_registry`, or both.
- A [CI/CD job token](../../../ci/jobs/ci_job_token.md).

Do not use authentication methods other than the methods documented here. Undocumented authentication methods might be removed in the future.

To authenticate with a GitLab token:

- Update the `TWINE_USERNAME` and `TWINE_PASSWORD` environment variables.

For example:

::Tabs

:::TabTitle With a personal access token

```yaml
run:
  image: python:latest
  variables:
    TWINE_USERNAME: <personal_access_token_name>
    TWINE_PASSWORD: <personal_access_token>
  script:
    - pip install build twine
    - python -m build
    - python -m twine upload --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi dist/*
```

:::TabTitle With a deploy token

```yaml
run:
  image: python:latest
  variables:
    TWINE_USERNAME: <deploy_token_username>
    TWINE_PASSWORD: <deploy_token>
  script:
    - pip install build twine
    - python -m build
    - python -m twine upload --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi dist/*
```

:::TabTitle With a CI/CD job token

```yaml
run:
  image: python:latest
  variables:
    TWINE_USERNAME: gitlab-ci-token
    TWINE_PASSWORD: $CI_JOB_TOKEN
  script:
    - pip install build twine
    - python -m build
    - python -m twine upload --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi dist/*
```

::EndTabs

### Authenticate for a group

To authenticate with the package registry for a group:

- Authenticate to the package registry, but use the group URL instead of the project URL:

```shell
https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/pypi
```

## Publish a PyPI package

You can publish a package with twine.

Prerequisites:

- You must [authenticate with the package registry](#authenticate-with-the-gitlab-package-registry).
- Your [version string must be valid](#use-valid-version-strings).
- The package:
  - Is 5 GB or less.
  - Has a `description` of 4000 characters or less. Longer `description` strings are truncated.
  - Isn't already published to the package registry. Trying to publish the same version of a package returns `400 Bad Request`.

PyPI packages are published using your project ID. If your project is in a group, PyPI packages published to the project registry
are also available in the group registry. For more information, see [Install from a group](#install-from-a-group).

To publish a package:

1. Define your repository source, edit the `~/.pypirc` file and add:

   ```ini
   [distutils]
   index-servers =
       gitlab

   [gitlab]
   repository = https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi
   ```

1. Upload your package with twine:

   ```shell
   python3 -m twine upload --repository gitlab dist/*
   ```

   When a package is published successfully, a message like this is displayed:

   ```plaintext
   Uploading distributions to https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi
   Uploading mypypipackage-0.0.1-py3-none-any.whl
   100%|███████████████████████████████████████████████████████████████████████████████████████████| 4.58k/4.58k [00:00<00:00, 10.9kB/s]
   Uploading mypypipackage-0.0.1.tar.gz
   100%|███████████████████████████████████████████████████████████████████████████████████████████| 4.24k/4.24k [00:00<00:00, 11.0kB/s]
   ```

The package is published to the package registry, and is shown on the **Packages and registries** page.

### Publish with inline authentication

If you didn't use a `.pypirc` file to define your repository source, you can
publish to the repository with inline authentication:

```shell
TWINE_PASSWORD=<personal_access_token, deploy_token, or $CI_JOB_TOKEN> \
TWINE_USERNAME=<username, deploy_token_username, or gitlab-ci-token> \
python3 -m twine upload --repository-url https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi dist/*
```

### Publishing packages with the same name and version

You cannot publish a package if a package of the same name and version already exists.
You must [delete the existing package](../package_registry/reduce_package_registry_storage.md#delete-a-package) first.
If you attempt to publish the same package
more than once, a `400 Bad Request` error occurs.

## Install a PyPI package

When a PyPI package is not found in the package registry, the request is forwarded to [pypi.org](https://pypi.org/).

Administrators can disable this behavior in the [Continuous Integration settings](../../../administration/settings/continuous_integration.md).

NOTE:
When you use the `--index-url` option, do not specify the port if it is a default
port. `http` URLs default to 80, and `https` URLs default to 443.

### Install from a project

To install the latest version of a package, use the following command:

```shell
pip install --index-url https://<personal_access_token_name>:<personal_access_token>@gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/simple --no-deps <package_name>
```

- `<package_name>` is the package name.
- `<personal_access_token_name>` is a personal access token name with the `read_api` scope.
- `<personal_access_token>` is a personal access token with the `read_api` scope.
- `<project_id>` is either the project's [URL-encoded](../../../api/rest/_index.md#namespaced-paths)
  path (for example, `group%2Fproject`), or the project's ID (for example `42`).

In these commands, you can use `--extra-index-url` instead of `--index-url`. If you were following the guide and want to install the
`MyPyPiPackage` package, you can run:

```shell
pip install mypypipackage --no-deps --index-url https://<personal_access_token_name>:<personal_access_token>@gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/simple
```

This message indicates that the package was installed successfully:

```plaintext
Looking in indexes: https://<personal_access_token_name>:****@gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/simple
Collecting mypypipackage
  Downloading https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/files/d53334205552a355fee8ca35a164512ef7334f33d309e60240d57073ee4386e6/mypypipackage-0.0.1-py3-none-any.whl (1.6 kB)
Installing collected packages: mypypipackage
Successfully installed mypypipackage-0.0.1
```

### Install from a group

To install the latest version of a package from a group, use the following command:

```shell
pip install --index-url https://<personal_access_token_name>:<personal_access_token>@gitlab.example.com/api/v4/groups/<group_id>/-/packages/pypi/simple --no-deps <package_name>
```

In this command:

- `<package_name>` is the package name.
- `<personal_access_token_name>` is a personal access token name with the `read_api` scope.
- `<personal_access_token>` is a personal access token with the `read_api` scope.
- `<group_id>` is the group ID.

In these commands, you can use `--extra-index-url` instead of `--index-url`.
If you're following the guide and want to install the `MyPyPiPackage` package, you can run:

```shell
pip install mypypipackage --no-deps --index-url https://<personal_access_token_name>:<personal_access_token>@gitlab.example.com/api/v4/groups/<group_id>/-/packages/pypi/simple
```

### Package names

GitLab looks for packages that use
[Python normalized names (PEP-503)](https://www.python.org/dev/peps/pep-0503/#normalized-names).
The characters `-`, `_`, and `.` are all treated the same, and repeated
characters are removed.

A `pip install` request for `my.package` looks for packages that match any of
the three characters, such as `my-package`, `my_package`, and `my....package`.

### Security implications

The security implications of using `--extra-index-url` versus `--index-url` when installing PyPI
packages are significant and worth understanding in detail. If you use:

- `--index-url`: This option replaces the default [PyPI index](https://pypi.org)
  with the specified URL. It's more secure because it only checks the specified index for packages.
  Use this option when you want to ensure packages are only installed from a trusted, private source
  (like the GitLab PyPI registry).
- `--extra-index-url`: This option adds an additional index to search, alongside the default PyPI index.
  It's less secure and more open to dependency confusion attacks, because it checks both the default PyPI
  and the additional index for packages.

## Using `requirements.txt`

If you want pip to access your public registry, add the `--extra-index-url` parameter along with the URL for your registry to your `requirements.txt` file.

```plaintext
--extra-index-url https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/simple
package-name==1.0.0
```

If this is a private registry, you can authenticate in a couple of ways. For example:

- Using your `requirements.txt` file:

  ```plaintext
  --extra-index-url https://__token__:<personal_token>@gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/simple
  package-name==1.0.0
  ```

- Using a `~/.netrc` file:

  ```plaintext
  machine gitlab.example.com
  login __token__
  password <personal_token>
  ```

## Versioning PyPI packages

Proper versioning is important for managing PyPI packages effectively. Follow these best practices to ensure your packages are versioned correctly.

### Use semantic versioning (SemVer)

Adopt semantic versioning for your packages. The version number should be in the format `MAJOR.MINOR.PATCH`:

- Increment `MAJOR` version for incompatible API changes.
- Increment `MINOR` version for backwards-compatible new features.
- Increment `PATCH` version for backwards-compatible bug fixes.

For example: 1.0.0, 1.1.0, 1.1.1.

For new projects, start with version 0.1.0. This indicates an initial development phase where the API is not yet stable.

### Use valid version strings

Ensure your version string is valid according to PyPI standards. GitLab uses a specific regex to validate version strings:

```ruby
\A(?:
    v?
    (?:([0-9]+)!)?                                                 (?# epoch)
    ([0-9]+(?:\.[0-9]+)*)                                          (?# release segment)
    ([-_\.]?((a|b|c|rc|alpha|beta|pre|preview))[-_\.]?([0-9]+)?)?  (?# pre-release)
    ((?:-([0-9]+))|(?:[-_\.]?(post|rev|r)[-_\.]?([0-9]+)?))?       (?# post release)
    ([-_\.]?(dev)[-_\.]?([0-9]+)?)?                                (?# dev release)
    (?:\+([a-z0-9]+(?:[-_\.][a-z0-9]+)*))?                         (?# local version)
)\z}xi
```

You can experiment with the regex and try your version strings by using this
[regular expression editor](https://rubular.com/r/FKM6d07ouoDaFV).

For more details about the regex, see the [Python documentation](https://www.python.org/dev/peps/pep-0440/#appendix-b-parsing-version-strings-with-regular-expressions).

## Supported CLI commands

The GitLab PyPI repository supports the following CLI commands:

- `twine upload`: Upload a package to the registry.
- `pip install`: Install a PyPI package from the registry.

## Troubleshooting

To improve performance, the pip command caches files related to a package. Pip doesn't remove data by
itself. The cache grows as new packages are installed. If you encounter issues, clear the cache with
this command:

```shell
pip cache purge
```

### Multiple `index-url` or `extra-index-url` parameters

You can define multiple `index-url` and `extra-index-url` parameters.

If you use the same domain name (such as `gitlab.example.com`) multiple times with different authentication
tokens, `pip` may not be able to find your packages. This problem is due to how `pip`
[registers and stores your tokens](https://github.com/pypa/pip/pull/10904#issuecomment-1126690115) during commands executions.

To workaround this issue, you can use a [group deploy token](../../project/deploy_tokens/_index.md) with the
scope `read_package_registry` from a common parent group for all projects or groups targeted by the
`index-url` and `extra-index-url` values.

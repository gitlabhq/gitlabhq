---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# PyPI packages in the Package Registry **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/208747) in GitLab Premium 12.10.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Free in 13.3.

Publish PyPI packages in your project's Package Registry. Then install the
packages whenever you need to use them as a dependency.

The Package Registry works with:

- [pip](https://pypi.org/project/pip/)
- [twine](https://pypi.org/project/twine/)

For documentation of the specific API endpoints that the `pip` and `twine`
clients use, see the [PyPI API documentation](../../../api/packages/pypi.md).

## Build a PyPI package

This section explains how to create a PyPI package.

If you already use PyPI and know how to build your own packages, go to the
[next section](#authenticate-with-the-package-registry).

### Install pip and twine

Install a recent version of [pip](https://pypi.org/project/pip/) and
[twine](https://pypi.org/project/twine/).

### Create a project

Create a test project.

1. Open your terminal.
1. Create a directory called `MyPyPiPackage`, and then go to that directory:

   ```shell
   mkdir MyPyPiPackage && cd MyPyPiPackage
   ```

1. Create another directory and go to it:

   ```shell
   mkdir mypypipackage && cd mypypipackage
   ```

1. Create the required files in this directory:

   ```shell
   touch __init__.py
   touch greet.py
   ```

1. Open the `greet.py` file, and then add:

   ```python
   def SayHello():
       print("Hello from MyPyPiPackage")
       return
   ```

1. Open the `__init__.py` file, and then add:

   ```python
   from .greet import SayHello
   ```

1. To test the code, in your `MyPyPiPackage` directory, start the Python prompt.

   ```shell
   python
   ```

1. Run this command:

   ```python
   >>> from mypypipackage import SayHello
   >>> SayHello()
   ```

A message indicates that the project was set up successfully:

```plaintext
Python 3.8.2 (v3.8.2:7b3ab5921f, Feb 24 2020, 17:52:18)
[Clang 6.0 (clang-600.0.57)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>> from mypypipackage import SayHello
>>> SayHello()
Hello from MyPyPiPackage
```

### Create a package

After you create a project, you can create a package.

1. In your terminal, go to the `MyPyPiPackage` directory.
1. Create a `setup.py` file:

   ```shell
   touch setup.py
   ```

   This file contains all the information about the package. For more information
   about this file, see [creating setup.py](https://packaging.python.org/tutorials/packaging-projects/#creating-setup-py).
   Because GitLab identifies packages based on
   [Python normalized names (PEP-503)](https://www.python.org/dev/peps/pep-0503/#normalized-names),
   ensure your package name meets these requirements. See the [installation section](#authenticate-with-a-ci-job-token)
   for details.

1. Open the `setup.py` file, and then add basic information:

   ```python
   import setuptools

   setuptools.setup(
       name="mypypipackage",
       version="0.0.1",
       author="Example Author",
       author_email="author@example.com",
       description="A small example package",
       packages=setuptools.find_packages(),
       classifiers=[
           "Programming Language :: Python :: 3",
           "License :: OSI Approved :: MIT License",
           "Operating System :: OS Independent",
       ],
       python_requires='>=3.6',
   )
   ```

1. Save the file.
1. Execute the setup:

   ```shell
   python3 setup.py sdist bdist_wheel
   ```

The output should be visible in a newly-created `dist` folder:

```shell
ls dist
```

The output should appear similar to the following:

```plaintext
mypypipackage-0.0.1-py3-none-any.whl mypypipackage-0.0.1.tar.gz
```

The package is now ready to be published to the Package Registry.

## Authenticate with the Package Registry

Before you can publish to the Package Registry, you must authenticate.

To do this, you can use:

- A [personal access token](../../../user/profile/personal_access_tokens.md)
  with the scope set to `api`.
- A [deploy token](../../project/deploy_tokens/index.md) with the scope set to
  `read_package_registry`, `write_package_registry`, or both.
- A [CI job token](#authenticate-with-a-ci-job-token).

### Authenticate with a personal access token

To authenticate with a personal access token, edit the `~/.pypirc` file and add:

```ini
[distutils]
index-servers =
    gitlab

[gitlab]
repository = https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi
username = <your_personal_access_token_name>
password = <your_personal_access_token>
```

- Your project ID is on your project's home page.

### Authenticate with a deploy token

To authenticate with a deploy token, edit your `~/.pypirc` file and add:

```ini
[distutils]
index-servers =
    gitlab

[gitlab]
repository = https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi
username = <deploy token username>
password = <deploy token>
```

Your project ID is on your project's home page.

### Authenticate with a CI job token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/202012) in GitLab 13.4.

To work with PyPI commands within [GitLab CI/CD](../../../ci/index.md), you
can use `CI_JOB_TOKEN` instead of a personal access token or deploy token.

For example:

```yaml
image: python:latest

run:
  script:
    - pip install twine
    - python setup.py sdist bdist_wheel
    - TWINE_PASSWORD=${CI_JOB_TOKEN} TWINE_USERNAME=gitlab-ci-token python -m twine upload --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi dist/*
```

You can also use `CI_JOB_TOKEN` in a `~/.pypirc` file that you check in to
GitLab:

```ini
[distutils]
index-servers =
    gitlab

[gitlab]
repository = https://gitlab.example.com/api/v4/projects/${env.CI_PROJECT_ID}/packages/pypi
username = gitlab-ci-token
password = ${env.CI_JOB_TOKEN}
```

### Authenticate to access packages within a group

Follow the instructions above for the token type, but use the group URL in place of the project URL:

```shell
https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/pypi
```

## Publish a PyPI package

Prerequisites:

- You must [authenticate with the Package Registry](#authenticate-with-the-package-registry).
- Your [version string must be valid](#ensure-your-version-string-is-valid).
- The maximum allowed package size is 5 GB.
- You can't upload the same version of a package multiple times. If you try,
  you receive the error `400 Bad Request`.
- You cannot publish PyPI packages to a group, only to a project.

You can then [publish a package by using twine](#publish-a-pypi-package-by-using-twine).

### Ensure your version string is valid

If your version string (for example, `0.0.1`) isn't valid, it gets rejected.
GitLab uses the following regex to validate the version string.

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

For more details about the regex, review this [documentation](https://www.python.org/dev/peps/pep-0440/#appendix-b-parsing-version-strings-with-regular-expressions).

### Publish a PyPI package by using twine

To publish a PyPI package, run a command like:

```shell
python3 -m twine upload --repository gitlab dist/*
```

This message indicates that the package was published successfully:

```plaintext
Uploading distributions to https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/pypi
Uploading mypypipackage-0.0.1-py3-none-any.whl
100%|███████████████████████████████████████████████████████████████████████████████████████████| 4.58k/4.58k [00:00<00:00, 10.9kB/s]
Uploading mypypipackage-0.0.1.tar.gz
100%|███████████████████████████████████████████████████████████████████████████████████████████| 4.24k/4.24k [00:00<00:00, 11.0kB/s]
```

To view the published package, go to your project's **Packages & Registries**
page.

If you didn't use a `.pypirc` file to define your repository source, you can
publish to the repository with the authentication inline:

```shell
TWINE_PASSWORD=<personal_access_token or deploy_token> TWINE_USERNAME=<username or deploy_token_username> python3 -m twine upload --repository-url https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi dist/*
```

If you didn't follow the steps on this page, ensure your package was properly
built, and that you [created a PyPI package with `setuptools`](https://packaging.python.org/tutorials/packaging-projects/).

You can then upload your package by using the following command:

```shell
python -m twine upload --repository <source_name> dist/<package_file>
```

- `<package_file>` is your package filename, ending in `.tar.gz` or `.whl`.
- `<source_name>` is the [source name used during setup](#authenticate-with-the-package-registry).

### Publishing packages with the same name or version

You cannot publish a package if a package of the same name and version already exists.
You must delete the existing package first. If you attempt to publish the same package
more than once, a `400 Bad Request` error occurs.

## Install a PyPI package

### Install from the project level

To install the latest version of a package, use the following command:

```shell
pip install --index-url https://<personal_access_token_name>:<personal_access_token>@gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/simple --no-deps <package_name>
```

- `<package_name>` is the package name.
- `<personal_access_token_name>` is a personal access token name with the `read_api` scope.
- `<personal_access_token>` is a personal access token with the `read_api` scope.
- `<project_id>` is the project ID.

In these commands, you can use `--extra-index-url` instead of `--index-url`. However, using
`--extra-index-url` makes you vulnerable to dependency confusion attacks because it checks the PyPi
repository for the package before it checks the custom repository. `--extra-index-url` adds the
provided URL as an additional registry which the client checks if the package is present.
`--index-url` tells the client to check for the package on the provided URL only.

If you were following the guide and want to install the
`MyPyPiPackage` package, you can run:

```shell
pip install mypypipackage --no-deps --index-url https://<personal_access_token_name>:<personal_access_token>@gitlab.example.com/api/v4/projects/<your_project_id>/packages/pypi/simple
```

This message indicates that the package was installed successfully:

```plaintext
Looking in indexes: https://<personal_access_token_name>:****@gitlab.example.com/api/v4/projects/<your_project_id>/packages/pypi/simple
Collecting mypypipackage
  Downloading https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/pypi/files/d53334205552a355fee8ca35a164512ef7334f33d309e60240d57073ee4386e6/mypypipackage-0.0.1-py3-none-any.whl (1.6 kB)
Installing collected packages: mypypipackage
Successfully installed mypypipackage-0.0.1
```

### Install from the group level

To install the latest version of a package from a group, use the following command:

```shell
pip install --index-url https://<personal_access_token_name>:<personal_access_token>@gitlab.example.com/api/v4/groups/<group_id>/-/packages/pypi/simple --no-deps <package_name>
```

In this command:

- `<package_name>` is the package name.
- `<personal_access_token_name>` is a personal access token name with the `read_api` scope.
- `<personal_access_token>` is a personal access token with the `read_api` scope.
- `<group_id>` is the group ID.

In these commands, you can use `--extra-index-url` instead of `--index-url`. However, using
`--extra-index-url` makes you vulnerable to dependency confusion attacks because it checks the PyPi
repository for the package before it checks the custom repository. `--extra-index-url` adds the
provided URL as an additional registry which the client checks if the package is present.
`--index-url` tells the client to check for the package at the provided URL only.

If you're following the guide and want to install the `MyPyPiPackage` package, you can run:

```shell
pip install mypypipackage --no-deps --index-url https://<personal_access_token_name>:<personal_access_token>@gitlab.example.com/api/v4/groups/<your_group_id>/-/packages/pypi/simple
```

### Package names

GitLab looks for packages that use
[Python normalized names (PEP-503)](https://www.python.org/dev/peps/pep-0503/#normalized-names).
The characters `-`, `_`, and `.` are all treated the same, and repeated
characters are removed.

A `pip install` request for `my.package` looks for packages that match any of
the three characters, such as `my-package`, `my_package`, and `my....package`.

## Supported CLI commands

The GitLab PyPI repository supports the following CLI commands:

- `twine upload`: Upload a package to the registry.
- `pip install`: Install a PyPI package from the registry.

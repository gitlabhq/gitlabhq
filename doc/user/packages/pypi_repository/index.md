---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# PyPI packages in the Package Registry

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/208747) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.10.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Core in 13.3.

Publish PyPI packages in your project’s Package Registry. Then install the
packages whenever you need to use them as a dependency.

The GitLab PyPI Repository works with:

- [pip](https://pypi.org/project/pip/)
- [twine](https://pypi.org/project/twine/)

## Build a PyPI package

This section covers creating a new example PyPI package to upload. This is a
quickstart to test out the **GitLab PyPI Registry**. If you already understand
how to build and publish your own packages, move on to the [next section](#authenticate-with-the-package-registry).

### Install pip and twine

You need a recent version of [pip](https://pypi.org/project/pip/) and [twine](https://pypi.org/project/twine/).

### Create a project

Understanding how to create a full Python project is outside the scope of this
guide, but you can create a small package to test out the registry. Start by
creating a new directory called `MyPyPiPackage`:

```shell
mkdir MyPyPiPackage && cd MyPyPiPackage
```

After creating this, create another directory inside:

```shell
mkdir mypypipackage && cd mypypipackage
```

Create two new files inside this directory to set up the basic project:

```shell
touch __init__.py
touch greet.py
```

Inside `greet.py`, add the following code:

```python
def SayHello():
    print("Hello from MyPyPiPackage")
    return
```

Inside the `__init__.py` file, add the following:

```python
from .greet import SayHello
```

Now that the basics of our project is completed, we can test that the code runs.
Start the Python prompt inside your top `MyPyPiPackage` directory. Then run:

```python
>>> from mypypipackage import SayHello
>>> SayHello()
```

You should see an output similar to the following:

```plaintext
Python 3.8.2 (v3.8.2:7b3ab5921f, Feb 24 2020, 17:52:18)
[Clang 6.0 (clang-600.0.57)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>> from mypypipackage import SayHello
>>> SayHello()
Hello from MyPyPiPackage
```

After we've verified that the sample project is working as previously described,
we can next work on creating a package.

### Create a package

Inside your `MyPyPiPackage` directory, we need to create a `setup.py` file. Run
the following:

```shell
touch setup.py
```

This file contains all the information about our package. For more information
about this file, see [creating setup.py](https://packaging.python.org/tutorials/packaging-projects/#creating-setup-py).
Becaue GitLab identifies packages based on
[Python normalized names (PEP-503)](https://www.python.org/dev/peps/pep-0503/#normalized-names),
ensure your package name meets these requirements. See the [installation section](#publish-a-pypi-package-by-using-cicd)
for more details.

For this guide, we don't need to extensively fill out this file. Add the
following to your `setup.py`:

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

Save the file, and then execute the setup:

```shell
python3 setup.py sdist bdist_wheel
```

If successful, you should be able to see the output in a newly created `dist`
folder. Run:

```shell
ls dist
```

And confirm your output matches the below:

```plaintext
mypypipackage-0.0.1-py3-none-any.whl mypypipackage-0.0.1.tar.gz
```

The package is now all set up and is ready to be uploaded to the
_GitLab PyPI Package Registry_. Before we do so, we next need to set up
authentication.

## Authenticate with the Package Registry

### Authenticate with a personal access token

You need the following:

- A personal access token. You can generate a
  [personal access token](../../../user/profile/personal_access_tokens.md)
  with the scope set to `api` for repository authentication.
- A suitable name for your source.
- Your project ID, which is found on the home page of your project.

Edit your `~/.pypirc` file and add the following:

```ini
[distutils]
index-servers =
    gitlab

[gitlab]
repository = https://gitlab.com/api/v4/projects/<project_id>/packages/pypi
username = __token__
password = <your personal access token>
```

### Authenticate with a deploy token

You need the following:

- A deploy token. You can generate a [deploy token](./../../project/deploy_tokens/index.md)
  with the `read_package_registry` or `write_package_registry` scopes for
  repository authentication.
- A suitable name for your source.
- Your project ID, which is found on the home page of your project.

Edit your `~/.pypirc` file and add the following:

```ini
[distutils]
index-servers =
    gitlab

[gitlab]
repository = https://gitlab.com/api/v4/projects/<project_id>/packages/pypi
username = <deploy token username>
password = <deploy token>
```

## Publish a PyPI package

When publishing packages, note that:

- The maximum allowed size is 50 Megabytes.
- You can't upload the same version of a package multiple times. If you try,
  you'll receive the error `Validation failed: File name has already been taken`.

### Ensure your version string is valid

If your version string (for example, `0.0.1`) is invalid, it will be rejected.
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

You can experiment with the regex and try your version strings using this
[regular expression editor](https://rubular.com/r/FKM6d07ouoDaFV).

For more details about the regex used, review this [documentation](https://www.python.org/dev/peps/pep-0440/#appendix-b-parsing-version-strings-with-regular-expressions).

### Publish a PyPI package by using twine

If you were following the steps on this page, the `MyPyPiPackage` package should
be ready to be uploaded. Run the following command:

```shell
python3 -m twine upload --repository gitlab dist/*
```

If successful, you should see the following:

```plaintext
Uploading distributions to https://gitlab.com/api/v4/projects/<your_project_id>/packages/pypi
Uploading mypypipackage-0.0.1-py3-none-any.whl
100%|███████████████████████████████████████████████████████████████████████████████████████████| 4.58k/4.58k [00:00<00:00, 10.9kB/s]
Uploading mypypipackage-0.0.1.tar.gz
100%|███████████████████████████████████████████████████████████████████████████████████████████| 4.24k/4.24k [00:00<00:00, 11.0kB/s]
```

This indicates that the package was uploaded successfully. You can then navigate
to your project's **Packages & Registries** page and see the uploaded packages.

If you would rather not use a `.pypirc` file to define your repository source,
you can upload to the repository with the authentication inline:

```shell
TWINE_PASSWORD=<personal_access_token or deploy_token> TWINE_USERNAME=<username or deploy_token_username> python3 -m twine upload --repository-url https://gitlab.com/api/v4/projects/<project_id>/packages/pypi dist/*
```

If you didn't use the steps on this page, you need to ensure your package has
been properly built, and that you [created a PyPI package with `setuptools`](https://packaging.python.org/tutorials/packaging-projects/).

You can then upload your package using the following command:

```shell
python -m twine upload --repository <source_name> dist/<package_file>
```

Where:

- `<package_file>` is your package filename, ending in `.tar.gz` or `.whl`.
- `<source_name>` is the [source name used during setup](#authenticate-with-the-package-registry).

### Publish a PyPI package by using CI/CD

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/202012) in GitLab 13.4.

To work with PyPI commands within [GitLab CI/CD](./../../../ci/README.md), you
can use `CI_JOB_TOKEN` in place of the personal access token or deploy a token
in your commands.

For example:

```yaml
image: python:latest

run:
  script:
    - pip install twine
    - python setup.py sdist bdist_wheel
    - TWINE_PASSWORD=${CI_JOB_TOKEN} TWINE_USERNAME=gitlab-ci-token python -m twine upload --repository-url https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/packages/pypi dist/*
```

You can also use `CI_JOB_TOKEN` in a `~/.pypirc` file that you check into GitLab:

```ini
[distutils]
index-servers =
    gitlab

[gitlab]
repository = https://gitlab.com/api/v4/projects/${env.CI_PROJECT_ID}/packages/pypi
username = gitlab-ci-token
password = ${env.CI_JOB_TOKEN}
```

## Install a PyPI package

Install the latest version of a package using the following command:

```shell
pip install --extra-index-url https://__token__:<personal_access_token>@gitlab.com/api/v4/projects/<project_id>/packages/pypi/simple --no-deps <package_name>
```

Where:

- `<package_name>` is the package name.
- `<personal_access_token>` is a personal access token with the `read_api` scope.
- `<project_id>` is the project ID.

If you were following the guide above and want to test installing the
`MyPyPiPackage` package, you can run the following:

```shell
pip install mypypipackage --no-deps --extra-index-url https://__token__:<personal_access_token>@gitlab.com/api/v4/projects/<your_project_id>/packages/pypi/simple
```

This should result in the following:

```plaintext
Looking in indexes: https://__token__:****@gitlab.com/api/v4/projects/<your_project_id>/packages/pypi/simple
Collecting mypypipackage
  Downloading https://gitlab.com/api/v4/projects/<your_project_id>/packages/pypi/files/d53334205552a355fee8ca35a164512ef7334f33d309e60240d57073ee4386e6/mypypipackage-0.0.1-py3-none-any.whl (1.6 kB)
Installing collected packages: mypypipackage
Successfully installed mypypipackage-0.0.1
```

GitLab looks for packages using
[Python normalized names (PEP-503)](https://www.python.org/dev/peps/pep-0503/#normalized-names),
so the characters `-`, `_`, and `.` are all treated the same and repeated characters are removed.
A `pip install` request for `my.package` looks for packages that match any of
the three characters, such as `my-package`, `my_package`, and `my....package`.

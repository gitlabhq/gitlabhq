---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

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

You should then be able to see the **Packages & Registries** section on the left sidebar.

## Getting started

This section will cover creating a new example PyPi package to upload. This is a
quickstart to test out the **GitLab PyPi Registry**. If you already understand how
to build and publish your own packages, move on to the [next section](#adding-the-gitlab-pypi-repository-as-a-source).

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

Once we've verified that the sample project is working as above, we can next
work on creating a package.

### Create a package

Inside your `MyPyPiPackage` directory, we need to create a `setup.py` file. Run
the following:

```shell
touch setup.py
```

This file contains all the information about our package. For more information
about this file, see [creating setup.py](https://packaging.python.org/tutorials/packaging-projects/#creating-setup-py).
For this guide, we don't need to extensively fill out this file, simply add the
below to your `setup.py`:

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

Save the file, then execute the setup like so:

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

Our package is now all set up and ready to be uploaded to the **GitLab PyPi
Package Registry**. Before we do so, we next need to set up authentication.

## Adding the GitLab PyPi Repository as a source

### Authenticating with a personal access token

You will need the following:

- A personal access token. You can generate a [personal access token](../../../user/profile/personal_access_tokens.md) with the scope set to `api` for repository authentication.
- A suitable name for your source.
- Your project ID which can be found on the home page of your project.

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

### Authenticating with a deploy token

You will need the following:

- A deploy token. You can generate a [deploy token](./../../project/deploy_tokens/index.md) with the `read_package_registry` and/or `write_package_registry` scopes for repository authentication.
- A suitable name for your source.
- Your project ID which can be found on the home page of your project.

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

## Uploading packages

When uploading packages, note that:

- The maximum allowed size is 50 Megabytes.
- If you upload the same package with the same version multiple times, each consecutive upload
  is saved as a separate file. When installing a package, GitLab will serve the most recent file.

### Upload packages with Twine

If you were following the guide above, then the `MyPyPiPackage` package should
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

If you did not follow the guide above, the you'll need to ensure your package
has been properly built and you [created a PyPi package with setuptools](https://packaging.python.org/tutorials/packaging-projects/).

You can then upload your package using the following command:

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
- `<personal_access_token>` is a personal access token with the `read_api` scope.
- `<project_id>` is the project ID.

If you were following the guide above and want to test installing the
`MyPyPiPackage` package, you can run the following:

```shell
pip install mypypipackage --no-deps --index-url https://__token__:<personal_access_token>@gitlab.com/api/v4/projects/<your_project_id>/packages/pypi/simple
```

This should result in the following:

```plaintext
Looking in indexes: https://__token__:****@gitlab.com/api/v4/projects/<your_project_id>/packages/pypi/simple
Collecting mypypipackage
  Downloading https://gitlab.com/api/v4/projects/<your_project_id>/packages/pypi/files/d53334205552a355fee8ca35a164512ef7334f33d309e60240d57073ee4386e6/mypypipackage-0.0.1-py3-none-any.whl (1.6 kB)
Installing collected packages: mypypipackage
Successfully installed mypypipackage-0.0.1
```

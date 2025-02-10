---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Build packages
---

Learn how to install and build packages different package formats.

- [Composer](#composer)
- [Conan](#conan)
- [Maven](#maven)
- [Gradle](#gradle)
- [npm](#npm)
- [Yarn](#yarn)
- [NuGet](#nuget)
- [PyPI](#pypi)

## Composer

1. Create a directory called `my-composer-package` and change to that directory:

   ```shell
   mkdir my-composer-package && cd my-composer-package
   ```

1. Run [`composer init`](https://getcomposer.org/doc/03-cli.md#init) and answer the prompts.

   For namespace, enter your unique [namespace](../../namespace/_index.md), like your GitLab username or group name.

   A file called `composer.json` is created:

   ```json
   {
     "name": "<namespace>/composer-test",
     "description": "Library XY",
     "type": "library",
     "license": "GPL-3.0-only",
     "authors": [
       {
         "name": "John Doe",
         "email": "john@example.com"
       }
     ],
     "require": {}
   }
   ```

## Conan

### Install Conan

Prerequisites:

- You must install Conan version 1.x. Support for Conan version 2 is proposed in [epic 8258](https://gitlab.com/groups/gitlab-org/-/epics/8258).

Download the Conan package manager to your local development environment by
following the instructions at [conan.io](https://conan.io/downloads).

When installation is complete, verify you can use Conan in your terminal by
running:

```shell
conan --version
```

The Conan version is printed in the output:

```plaintext
Conan version 1.20.5
```

### Install CMake

When you develop with C++ and Conan, you can select from many available
compilers. This example uses the CMake build system generator.

To install CMake:

- For Mac, use [Homebrew](https://brew.sh/) and run `brew install cmake`.
- For other operating systems, follow the instructions at [cmake.org](https://cmake.org/resources/).

When installation is complete, verify you can use CMake in your terminal by
running:

```shell
cmake --version
```

The CMake version is printed in the output.

### Create a project

To test the package registry, you need a C++ project. If you don't already have
one, you can clone the Conan [hello world starter project](https://github.com/conan-io/hello).

### Build a Conan package

To build a package:

1. Open a terminal and go to your project's root folder.
1. Generate a new recipe by running `conan new` with a package name and version:

   ```shell
   conan new Hello/0.1 -t
   ```

1. Create a package for the recipe by running `conan create` with the Conan user
   and channel:

   ```shell
   conan create . mycompany/beta
   ```

   NOTE:
   If you use an [instance remote](../conan_repository/_index.md#add-a-remote-for-your-instance), you must
   follow a specific [naming convention](../conan_repository/_index.md#package-recipe-naming-convention-for-instance-remotes).

A package with the recipe `Hello/0.1@mycompany/beta` is created.

For more details about creating and managing Conan packages, see the
[Conan documentation](https://docs.conan.io/en/latest/creating_packages.html).

## Maven

### Install Maven

The required minimum versions are:

- Java 11.0.5+
- Maven 3.6+

Follow the instructions at [maven.apache.org](https://maven.apache.org/install.html)
to download and install Maven for your local development environment. After
installation is complete, verify you can use Maven in your terminal by running:

```shell
mvn --version
```

The output should be similar to:

```shell
Apache Maven 3.6.1 (d66c9c0b3152b2e69ee9bac180bb8fcc8e6af555; 2019-04-04T20:00:29+01:00)
Maven home: /Users/<your_user>/apache-maven-3.6.1
Java version: 12.0.2, vendor: Oracle Corporation, runtime: /Library/Java/JavaVirtualMachines/jdk-12.0.2.jdk/Contents/Home
Default locale: en_GB, platform encoding: UTF-8
OS name: "mac os x", version: "10.15.2", arch: "x86_64", family: "mac"
```

### Build a Maven package

1. Open your terminal and create a directory to store the project.
1. From the new directory, run this Maven command to initialize a new package:

   ```shell
   mvn archetype:generate -DgroupId=com.mycompany.mydepartment -DartifactId=my-project -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
   ```

   The arguments are:

   - `DgroupId`: A unique string that identifies your package. Follow
     the [Maven naming conventions](https://maven.apache.org/guides/mini/guide-naming-conventions.html).
   - `DartifactId`: The name of the `JAR`, appended to the end of the `DgroupId`.
   - `DarchetypeArtifactId`: The archetype used to create the initial structure of
     the project.
   - `DinteractiveMode`: Create the project using batch mode (optional).

This message indicates that the project was set up successfully:

```shell
...
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  3.429 s
[INFO] Finished at: 2020-01-28T11:47:04Z
[INFO] ------------------------------------------------------------------------
```

In the folder where you ran the command, a new directory should be displayed.
The directory name should match the `DartifactId` parameter, which in this case,
is `my-project`.

## Gradle

### Install Gradle

If you want to create a new Gradle project, you must install Gradle. Follow
instructions at [gradle.org](https://gradle.org/install/) to download and install
Gradle for your local development environment.

In your terminal, verify you can use Gradle by running:

```shell
gradle -version
```

To use an existing Gradle project, in the project directory,
on Linux execute `gradlew`, or on Windows execute `gradlew.bat`.

The output should be similar to:

```plaintext
------------------------------------------------------------
Gradle 6.0.1
------------------------------------------------------------

Build time:   2019-11-18 20:25:01 UTC
Revision:     fad121066a68c4701acd362daf4287a7c309a0f5

Kotlin:       1.3.50
Groovy:       2.5.8
Ant:          Apache Ant(TM) version 1.10.7 compiled on September 1 2019
JVM:          11.0.5 (Oracle Corporation 11.0.5+10)
OS:           Windows 10 10.0 amd64
```

### Create a package

1. Open your terminal and create a directory to store the project.
1. From this new directory, run this command to initialize a new package:

   ```shell
   gradle init
   ```

   The output should be:

   ```plaintext
   Select type of project to generate:
     1: basic
     2: application
     3: library
     4: Gradle plugin
   Enter selection (default: basic) [1..4]
   ```

1. Enter `3` to create a new Library project. The output should be:

   ```plaintext
   Select implementation language:
     1: C++
     2: Groovy
     3: Java
     4: Kotlin
     5: Scala
     6: Swift
   ```

1. Enter `3` to create a new Java Library project. The output should be:

   ```plaintext
   Select build script DSL:
     1: Groovy
     2: Kotlin
   Enter selection (default: Groovy) [1..2]
   ```

1. Enter `1` to create a new Java Library project that is described in Groovy DSL, or `2` to create one that is described in Kotlin DSL. The output should be:

   ```plaintext
   Select test framework:
     1: JUnit 4
     2: TestNG
     3: Spock
     4: JUnit Jupiter
   ```

1. Enter `1` to initialize the project with JUnit 4 testing libraries. The output should be:

   ```plaintext
   Project name (default: test):
   ```

1. Enter a project name or press <kbd>Enter</kbd> to use the directory name as project name.

## sbt

### Install sbt

Install sbt to create new sbt projects.

To install sbt for your development environment:

1. Follow the instructions at [scala-sbt.org](https://www.scala-sbt.org/1.x/docs/Setup.html).

1. From your terminal, verify you can use sbt:

   ```shell
   sbt --version
   ```

The output is similar to:

```plaintext
[warn] Project loading failed: (r)etry, (q)uit, (l)ast, or (i)gnore? (default: r)
sbt script version: 1.9.8
```

### Create a Scala project

1. Open your terminal and create a directory to store the project.
1. From the new directory, initialize a new project:

   ```shell
   sbt new scala/scala-seed.g8
   ```

   The output is:

   ```plaintext
   Minimum Scala build.

   name [My Something Project]: hello

   Template applied in ./hello
   ```

1. Enter a project name or press <kbd>Enter</kbd> to use the directory name as project name.
1. Open the `build.sbt` file and edit it as described in the [sbt documentation](https://www.scala-sbt.org/1.x/docs/Publishing.html) to publish your project to the package registry.

## npm

### Install npm

Install Node.js and npm in your local development environment by following
the instructions at [npmjs.com](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm/).

When installation is complete, verify you can use npm in your terminal by
running:

```shell
npm --version
```

The npm version is shown in the output:

```plaintext
6.10.3
```

### Create an npm package

1. Create an empty directory.
1. Go to the directory and initialize an empty package by running:

   ```shell
   npm init
   ```

1. Enter responses to the questions. Ensure the **package name** follows
   the [naming convention](../npm_registry/_index.md#naming-convention) and is scoped to the project or group where the registry exists.

## Yarn

### Install Yarn

As an alternative to npm, you can install Yarn in your local environment by following the
instructions at [classic.yarnpkg.com](https://classic.yarnpkg.com/en/docs/install).

When installation is complete, verify you can use Yarn in your terminal by
running:

```shell
yarn --version
```

The Yarn version is shown in the output:

```plaintext
1.19.1
```

### Create a package

1. Create an empty directory.
1. Go to the directory and initialize an empty package by running:

   ```shell
   yarn init
   ```

1. Enter responses to the questions. Ensure the **package name** follows
   the [naming convention](../npm_registry/_index.md#naming-convention) and is scoped to the
   project or group where the registry exists.

A `package.json` file is created.

## NuGet

### Install NuGet

Follow the instructions from [Microsoft](https://learn.microsoft.com/en-us/nuget/install-nuget-client-tools) to install NuGet. If you have
[Visual Studio](https://visualstudio.microsoft.com/vs/), NuGet is
probably already installed.

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

## PyPI

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

### Create a PyPI package

After you create a project, you can create a package.

1. In your terminal, go to the `MyPyPiPackage` directory.
1. Create a `pyproject.toml` file:

   ```shell
   touch pyproject.toml
   ```

   This file contains all the information about the package. For more information
   about this file, see [creating `pyproject.toml`](https://packaging.python.org/en/latest/tutorials/packaging-projects/#creating-pyproject-toml).
   Because GitLab identifies packages based on
   [Python normalized names (PEP-503)](https://www.python.org/dev/peps/pep-0503/#normalized-names),
   ensure your package name meets these requirements. See the [installation section](../pypi_repository/_index.md#authenticate-with-the-gitlab-package-registry)
   for details.

1. Open the `pyproject.toml` file, and then add basic information:

   ```toml
   [build-system]
   requires = ["setuptools>=61.0"]
   build-backend = "setuptools.build_meta"

   [project]
   name = "mypypipackage"
   version = "0.0.1"
   authors = [
       { name="Example Author", email="author@example.com" },
   ]
   description = "A small example package"
   requires-python = ">=3.7"
   classifiers = [
      "Programming Language :: Python :: 3",
      "Operating System :: OS Independent",
   ]

   [tool.setuptools.packages]
   find = {}
   ```

1. Save the file.
1. Install the package build library:

   ```shell
   pip install build
   ```

1. Build the package:

   ```shell
   python -m build
   ```

The output should be visible in a newly-created `dist` folder:

```shell
ls dist
```

The output should appear similar to the following:

```plaintext
mypypipackage-0.0.1-py3-none-any.whl mypypipackage-0.0.1.tar.gz
```

The package is now ready to be published to the package registry.

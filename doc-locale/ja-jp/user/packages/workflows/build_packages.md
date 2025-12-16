---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージをビルドする
---

GitLabパッケージレジストリを使用して、さまざまなパッケージ形式のパッケージをインストールしてビルドします。

次のパッケージマネージャーがサポートされています:

- [Composer](#composer)
- [Conan 1](#conan-1)
- [Conan 2](#conan-2)
- [Maven](#maven)
- [Gradle](#gradle)
- [sbt](#sbt)
- [npm](#npm)
- [Yarn](#yarn)
- [NuGet](#nuget)
- [PyPI](#pypi)

## Composer {#composer}

1. `my-composer-package`というディレクトリを作成し、そのディレクトリに移動します:

   ```shell
   mkdir my-composer-package && cd my-composer-package
   ```

1. [`composer init`](https://getcomposer.org/doc/03-cli.md#init)を実行し、プロンプトに答えます。

   ネームスペースには、一意の[namespace](../../namespace/_index.md)（GitLabのユーザー名またはグループ名など）を入力します。

   `composer.json`というファイルが作成されます:

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

## Conan 1 {#conan-1}

### Conan 1をインストール {#install-conan-1}

前提要件: 

- Conanバージョン1.xをインストールする必要があります。

[conan.io](https://conan.io/downloads)の手順に従って、ローカルの開発環境にConanパッケージマネージャーをダウンロードします。

インストールが完了したら、以下を実行して、ターミナルでConanを使用できることを確認します:

```shell
conan --version
```

Conanのバージョンが出力に表示されます:

```plaintext
Conan version 1.20.5
```

### CMakeをインストール {#install-cmake}

C++とConanを使用して開発する場合、利用可能な多くのコンパイラから選択できます。この例では、CMakeビルドシステムジェネレーターを使用します。

CMakeをインストールするには:

- Macの場合は、[Homebrew](https://brew.sh/)を使用し、`brew install cmake`を実行します。
- 他のオペレーティングシステムの場合は、[cmake.org](https://cmake.org/resources/)の手順に従ってください。

インストールが完了したら、以下を実行して、ターミナルでCMakeを使用できることを確認します:

```shell
cmake --version
```

CMakeのバージョンが出力に表示されます。

### プロジェクトを作成する {#create-a-project}

パッケージレジストリをテストするには、C++プロジェクトが必要です。まだお持ちでない場合は、Conanの[hello world starter project](https://github.com/conan-io/hello)をクローンできます。

### Conan 1パッケージをビルド {#build-a-conan-1-package}

パッケージをビルドするには:

1. ターミナルを開き、プロジェクトのルートフォルダーに移動します。
1. `conan new`を呼び出して、パッケージ名とバージョンを指定して新しいレシピを生成します:

   ```shell
   conan new Hello/0.1 -t
   ```

1. `conan create`をConanのユーザー名とチャネルで呼び出して、レシピのパッケージを作成します:

   ```shell
   conan create . mycompany/beta
   ```

   {{< alert type="note" >}}

   [インスタンスリモート](../conan_1_repository/_index.md#add-a-remote-for-your-instance)を使用する場合は、特定の[命名規則](../conan_1_repository/_index.md#package-recipe-naming-convention-for-instance-remotes)に従う必要があります。

   {{< /alert >}}

レシピ`Hello/0.1@mycompany/beta`のパッケージが作成されます。

Conanパッケージの作成と管理の詳細については、[Conanドキュメント](https://docs.conan.io/en/latest/creating_packages.html)を参照してください。

## Conan 2 {#conan-2}

### Conan 2をインストール {#install-conan-2}

前提要件: 

- Conanバージョン2.xをインストールする必要があります。ベースとなるConanバージョン2が利用可能になり、今後の改善は[epic 8258](https://gitlab.com/groups/gitlab-org/-/epics/8258)で追跡できます。

[conan.io](https://docs.conan.io/2/installation.html)の手順に従って、ローカルの開発環境にConanパッケージマネージャーをインストールします。

インストールが完了したら、次のコマンドを実行して、ターミナルでConanを使用できることを確認します:

```shell
conan --version
```

Conanのバージョンが出力に表示されます:

```plaintext
Conan version 2.17.0
```

### Conan 2プロファイルを作成 {#create-conan-2-profile}

Conan 2のプロファイルを定義する必要があります。すでにプロファイルを定義している場合は、この手順をスキップしてください。

プロファイルを作成するには、次のコマンドを実行します:

```shell
conan profile detect
```

プロファイルをチェックします:

```shell
conan profile list
```

コマンドは、出力にプロファイルをリストします:

```plaintext
Profiles found in the cache:
default
```

生成されたプロファイルは、通常、開始するのに十分です。Conanプロファイルの詳細については、[Conan 2 profiles](https://docs.conan.io/2/reference/config_files/profiles.html#profiles)を参照してください。

### CMakeをインストール {#install-cmake-1}

C++とConanを使用して開発する場合、利用可能な多くのコンパイラから選択できます。次の例では、CMakeビルドシステムジェネレーターを使用します。

前提要件: 

- CMakeをインストールします。
  - macOSの場合は、[Homebrew](https://brew.sh/)をインストールし、`brew install cmake`を実行します。
  - 他のオペレーティングシステムの場合は、[cmake.org](https://cmake.org/resources/)の手順に従ってください。

インストールが完了したら、次のコマンドを使用して、ターミナルでCMakeを使用できることを確認します:

```shell
cmake --version
```

CMakeのバージョンが出力に表示されます。

### プロジェクトを作成する {#create-a-project-1}

前提要件: 

- パッケージレジストリをテストするには、C++プロジェクトが必要です。

ローカルプロジェクトフォルダーに移動し、`conan new`コマンドを使用して、`cmake_lib`テンプレートで`“Hello World”` C++ライブラリのサンプルプロジェクトを作成します:

```shell
mkdir hello && cd hello
conan new cmake_lib -d name=hello -d version=0.1
```

より高度な例については、Conan 2 [examples project](https://github.com/conan-io/examples2)を参照してください。

### Conan 2パッケージをビルド {#build-a-conan-2-package}

前提要件: 

- [C++プロジェクトを作成](#create-a-project)。

パッケージをビルドするには:

1. 前のセクションで作成した`hello`フォルダーにいることを確認してください。

1. `conan create`をConanのユーザー名とチャネルで呼び出して、レシピのパッケージを作成します:

   ```shell
   conan create . --channel=beta --user=mycompany
   ```

レシピ`hello/0.1@mycompany/beta`のパッケージが作成されます。

Conanパッケージの作成と管理の詳細については、[Creating packages](https://docs.conan.io/2/tutorial/creating_packages)を参照してください。

## Maven {#maven}

### Mavenをインストール {#install-maven}

必要な最小バージョンは次のとおりです:

- Java 11.0.5+
- 3.6+

[maven.apache.org](https://maven.apache.org/install.html)の手順に従って、ローカルの開発環境にMavenをダウンロードしてインストールします。インストールが完了したら、以下を実行して、ターミナルでMavenを使用できることを確認します:

```shell
mvn --version
```

出力は次のようになるはずです:

```shell
Apache Maven 3.6.1 (d66c9c0b3152b2e69ee9bac180bb8fcc8e6af555; 2019-04-04T20:00:29+01:00)
Maven home: /Users/<your_user>/apache-maven-3.6.1
Java version: 12.0.2, vendor: Oracle Corporation, runtime: /Library/Java/JavaVirtualMachines/jdk-12.0.2.jdk/Contents/Home
Default locale: en_GB, platform encoding: UTF-8
OS name: "mac os x", version: "10.15.2", arch: "x86_64", family: "mac"
```

### Mavenパッケージをビルド {#build-a-maven-package}

1. ターミナルを開き、プロジェクトを格納するディレクトリを作成します。
1. 新しいディレクトリから、このMavenコマンドを実行して新しいパッケージを初期化します:

   ```shell
   mvn archetype:generate -DgroupId=com.mycompany.mydepartment -DartifactId=my-project -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
   ```

   引数は次のとおりです:

   - `DgroupId`: お使いのパッケージを識別する一意の文字列。[Maven命名規則](https://maven.apache.org/guides/mini/guide-naming-conventions.html)に従ってください。
   - `DartifactId`: `JAR`の名前。`DgroupId`の末尾に追加されます。
   - `DarchetypeArtifactId`: プロジェクトの初期構造を作成するために使用されるアーキタイプ。
   - `DinteractiveMode`: バッチモードを使用してプロジェクトを作成します（オプション）。

このメッセージは、プロジェクトが正常にセットアップされたことを示しています:

```shell
...
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  3.429 s
[INFO] Finished at: 2020-01-28T11:47:04Z
[INFO] ------------------------------------------------------------------------
```

コマンドを実行したフォルダーに、新しいディレクトリが表示されます。ディレクトリ名は`DartifactId`パラメータと一致する必要があります。この場合、`my-project`です。

## Gradle {#gradle}

### Gradleをインストール {#install-gradle}

新しいGradleプロジェクトを作成する場合は、Gradleをインストールする必要があります。[gradle.org](https://gradle.org/install/)の手順に従って、ローカルの開発環境にGradleをダウンロードしてインストールします。

ターミナルで、以下を実行してGradleを使用できることを確認します:

```shell
gradle -version
```

既存のGradleプロジェクトを使用するには、プロジェクトディレクトリで、Linuxでは`gradlew`を実行し、Windowsでは`gradlew.bat`を実行します。

出力は次のようになるはずです:

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

### パッケージを作成 {#create-a-package}

1. ターミナルを開き、プロジェクトを格納するディレクトリを作成します。
1. この新しいディレクトリから、このコマンドを実行して新しいパッケージを初期化します:

   ```shell
   gradle init
   ```

   出力は次のようになります:

   ```plaintext
   Select type of project to generate:
     1: basic
     2: application
     3: library
     4: Gradle plugin
   Enter selection (default: basic) [1..4]
   ```

1. `3`を入力して、新しいライブラリプロジェクトを作成します。出力は次のようになります:

   ```plaintext
   Select implementation language:
     1: C++
     2: Groovy
     3: Java
     4: Kotlin
     5: Scala
     6: Swift
   ```

1. `3`を入力して、新しいJavaライブラリプロジェクトを作成します。出力は次のようになります:

   ```plaintext
   Select build script DSL:
     1: Groovy
     2: Kotlin
   Enter selection (default: Groovy) [1..2]
   ```

1. `1`を入力して、Groovy DSLで記述された新しいJavaライブラリプロジェクトを作成するか、`2`を入力して、Kotlin DSLで記述されたプロジェクトを作成します。出力は次のようになります:

   ```plaintext
   Select test framework:
     1: JUnit 4
     2: TestNG
     3: Spock
     4: JUnit Jupiter
   ```

1. `1`を入力して、JUnit 4テストライブラリを使用してプロジェクトを初期化します。出力は次のようになります:

   ```plaintext
   Project name (default: test):
   ```

1. プロジェクト名を入力するか、<kbd>Enter</kbd>キーを押してディレクトリ名をプロジェクト名として使用します。

## sbt {#sbt}

### sbtをインストール {#install-sbt}

新しいsbtプロジェクトを作成するには、sbtをインストールします。

開発環境にsbtをインストールするには:

1. [scala-sbt.org](https://www.scala-sbt.org/1.x/docs/Setup.html)の手順に従ってください。

1. ターミナルから、sbtを使用できることを確認します:

   ```shell
   sbt --version
   ```

出力は次のようになります:

```plaintext
[warn] Project loading failed: (r)etry, (q)uit, (l)ast, or (i)gnore? (default: r)
sbt script version: 1.9.8
```

### Scalaプロジェクトを作成 {#create-a-scala-project}

1. ターミナルを開き、プロジェクトを格納するディレクトリを作成します。
1. 新しいディレクトリから、新しいプロジェクトを初期化します:

   ```shell
   sbt new scala/scala-seed.g8
   ```

   出力は次のとおりです:

   ```plaintext
   Minimum Scala build.

   name [My Something Project]: hello

   Template applied in ./hello
   ```

1. プロジェクト名を入力するか、<kbd>Enter</kbd>キーを押してディレクトリ名をプロジェクト名として使用します。
1. `build.sbt`ファイルを開き、[sbtドキュメント](https://www.scala-sbt.org/1.x/docs/Publishing.html)の説明に従って編集し、プロジェクトをパッケージレジストリに公開します。

## NPM {#npm}

### npmをインストール {#install-npm}

[npmjs.com](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm/)の手順に従って、ローカル開発環境にNode.jsとnpmをインストールします。

インストールが完了したら、以下を実行して、ターミナルでnpmを使用できることを確認します:

```shell
npm --version
```

npmのバージョンが出力に表示されます:

```plaintext
6.10.3
```

### npmパッケージを作成 {#create-an-npm-package}

1. 空のディレクトリを作成します。
1. そのディレクトリに移動し、以下を実行して空のパッケージを初期化します:

   ```shell
   npm init
   ```

1. 質問に回答を入力します。パッケージ名が[命名規則](../npm_registry/_index.md#naming-convention)に従い、レジストリが存在するプロジェクトまたはグループにスコープされていることを確認してください。

## Yarn {#yarn}

### Yarnをインストール {#install-yarn}

npmの代替として、[classic.yarnpkg.com](https://classic.yarnpkg.com/en/docs/install)の手順に従って、ローカル環境にYarnをインストールできます。

インストールが完了したら、以下を実行して、ターミナルでYarnを使用できることを確認します:

```shell
yarn --version
```

Yarnのバージョンが出力に表示されます:

```plaintext
1.19.1
```

### パッケージを作成 {#create-a-package-1}

1. 空のディレクトリを作成します。
1. そのディレクトリに移動し、以下を実行して空のパッケージを初期化します:

   ```shell
   yarn init
   ```

1. 質問に回答を入力します。パッケージ名が[命名規則](../npm_registry/_index.md#naming-convention)に従い、レジストリが存在するプロジェクトまたはグループにスコープされていることを確認してください。

`package.json`ファイルが作成されます。

## NuGet {#nuget}

### NuGetをインストール {#install-nuget}

[Microsoft](https://learn.microsoft.com/en-us/nuget/install-nuget-client-tools)の手順に従って、NuGetをインストールします。[Visual Studio](https://visualstudio.microsoft.com/vs/)をお持ちの場合は、NuGetがすでにインストールされている可能性があります。

以下を実行して、[NuGet CLI](https://www.nuget.org/)がインストールされていることを確認します:

```shell
nuget help
```

出力は次のようになるはずです:

```plaintext
NuGet Version: 5.1.0.6013
usage: NuGet <command> [args] [options]
Type 'NuGet help <command>' for help on a specific command.

Available commands:

[output truncated]
```

## PyPI {#pypi}

### pipとtwineをインストール {#install-pip-and-twine}

最新バージョンの[Pip](https://pypi.org/project/pip/)と[twine](https://pypi.org/project/twine/)をインストールします。

### プロジェクトを作成する {#create-a-project-2}

テストプロジェクトを作成します。

1. ターミナルを開きます。
1. `MyPyPiPackage`というディレクトリを作成し、そのディレクトリに移動します:

   ```shell
   mkdir MyPyPiPackage && cd MyPyPiPackage
   ```

1. 別のディレクトリを作成して、そこに移動します:

   ```shell
   mkdir mypypipackage && cd mypypipackage
   ```

1. このディレクトリに必要なファイルを作成します:

   ```shell
   touch __init__.py
   touch greet.py
   ```

1. `greet.py`ファイルを開き、以下を追加します:

   ```python
   def SayHello():
       print("Hello from MyPyPiPackage")
       return
   ```

1. `__init__.py`ファイルを開き、以下を追加します:

   ```python
   from .greet import SayHello
   ```

1. コードをテストするには、`MyPyPiPackage`ディレクトリで、Pythonプロンプトを起動します。

   ```shell
   python
   ```

1. このコマンドを実行します:

   ```python
   >>> from mypypipackage import SayHello
   >>> SayHello()
   ```

メッセージは、プロジェクトが正常にセットアップされたことを示しています:

```plaintext
Python 3.8.2 (v3.8.2:7b3ab5921f, Feb 24 2020, 17:52:18)
[Clang 6.0 (clang-600.0.57)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>> from mypypipackage import SayHello
>>> SayHello()
Hello from MyPyPiPackage
```

### PyPIパッケージを作成 {#create-a-pypi-package}

プロジェクトを作成したら、パッケージを作成できます。

1. ターミナルで、`MyPyPiPackage`ディレクトリに移動します。
1. `pyproject.toml`ファイルを作成します:

   ```shell
   touch pyproject.toml
   ```

   このファイルには、パッケージに関するすべての情報が含まれています。このファイルの詳細については、[`pyproject.toml`の作成](https://packaging.python.org/en/latest/tutorials/packaging-projects/#creating-pyproject-toml)を参照してください。GitLabは[Pythonの正規化された名前（PEP-503）](https://www.python.org/dev/peps/pep-0503/#normalized-names)に基づいてパッケージを識別するため、パッケージ名がこれらの要件を満たしていることを確認してください。詳細については、[インストールセクション](../pypi_repository/_index.md#authenticate-with-the-gitlab-package-registry)を参照してください。

1. `pyproject.toml`ファイルを開き、基本的な情報を追加します:

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

1. ファイルを保存します。
1. パッケージビルドライブラリをインストールします:

   ```shell
   pip install build
   ```

1. パッケージをビルドします:

   ```shell
   python -m build
   ```

出力は、新しく作成された`dist`フォルダーに表示されます:

```shell
ls dist
```

出力は次のように表示されるはずです:

```plaintext
mypypipackage-0.0.1-py3-none-any.whl mypypipackage-0.0.1.tar.gz
```

これで、パッケージをパッケージレジストリに公開する準備ができました。

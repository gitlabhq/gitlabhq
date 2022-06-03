---
type: reference, howto
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Dependency Scanning **(ULTIMATE)**

The Dependency Scanning feature can automatically find security vulnerabilities in your
software dependencies while you're developing and testing your applications. For example,
dependency scanning lets you know if your application uses an external (open source)
library that is known to be vulnerable. You can then take action to protect your application.

Dependency Scanning is often considered part of Software Composition Analysis (SCA). SCA can contain
aspects of inspecting the items your code uses. These items typically include application and system
dependencies that are almost always imported from external sources, rather than sourced from items
you wrote yourself.

## Dependency Scanning compared to Container Scanning

GitLab offers both Dependency Scanning and Container Scanning
to ensure coverage for all of these dependency types. To cover as much of your risk area as
possible, we encourage you to use all of our security scanning tools:

- Dependency Scanning analyzes your project and tells you which software dependencies,
  including upstream dependencies, have been included in your project, and what known
  risks the dependencies contain. Dependency Scanning modifies its behavior based
  on the language and package manager of the project. It typically looks for a lock file
  then performs a build to fetch upstream dependency information. In the case of
  containers, Dependency Scanning uses the compatible manifest and reports only these
  declared software dependencies (and those installed as a sub-dependency).
  Dependency Scanning can not detect software dependencies that are pre-bundled
  into the container's base image. To identify pre-bundled dependencies, enable
  [Container Scanning](../container_scanning/) language scanning using the
  [`CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` variable](../container_scanning/#report-language-specific-findings).
- [Container Scanning](../container_scanning/) analyzes your containers and tells
  you about known risks in the operating system's (OS) packages. You can configure it
  to also report on software and language dependencies, if you enable it and use
  the [`CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` variable](../container_scanning/#report-language-specific-findings).
  Turning this variable on can result in some duplicate findings, as we do not yet
  de-duplicate results between Container Scanning and Dependency Scanning. For more details,
  efforts to de-duplicate these findings can be tracked in
  [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/348655).

The following table summarizes which types of dependencies each scanning tool can detect:

| Feature                                                                                      | Dependency Scanning | Container Scanning          |
| -----------------------------------------------------------                                  | ------------------- | ------------------          |
| Identify the manifest, lock file, or static file that introduced the dependency              | **{check-circle}**      | **{dotted-circle}**             |
| Development dependencies                                                                     | **{check-circle}**      | **{dotted-circle}**             |
| Dependencies in a lock file committed to your repository                                     | **{check-circle}**      | **{check-circle}** <sup>1</sup> |
| Binaries built by Go                                                                         | **{dotted-circle}**     | **{check-circle}** <sup>2</sup> |
| Dynamically-linked language-specific dependencies installed by the Operating System          | **{dotted-circle}**     | **{check-circle}**              |
| Operating system dependencies                                                                | **{dotted-circle}**     | **{check-circle}**              |
| Language-specific dependencies installed on the operating system (not built by your project) | **{dotted-circle}**     | **{check-circle}**              |

1. Lock file must be present in the image to be detected.
1. Binary file must be present in the image to be detected.

## Overview

If you're using [GitLab CI/CD](../../../ci/index.md), you can use dependency scanning to analyze
your dependencies for known vulnerabilities. GitLab scans all dependencies, including transitive
dependencies (also known as nested dependencies). You can take advantage of dependency scanning by
either:

- [Including the dependency scanning template](#configuration)
  in your existing `.gitlab-ci.yml` file.
- Implicitly using
  the [auto dependency scanning](../../../topics/autodevops/stages.md#auto-dependency-scanning)
  provided by [Auto DevOps](../../../topics/autodevops/index.md).

GitLab checks the dependency scanning report, compares the found vulnerabilities
between the source and target branches, and shows the information on the
merge request. The results are sorted by the [severity](../vulnerabilities/severities.md) of the
vulnerability.

![Dependency scanning Widget](img/dependency_scanning_v13_2.png)

## Requirements

Dependency Scanning runs in the `test` stage, which is available by default. If you redefine the
stages in the `.gitlab-ci.yml` file, the `test` stage is required.

To run dependency scanning jobs, by default, you need GitLab Runner with the
[`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
If you're using the shared runners on GitLab.com, this is enabled by default. The analyzer images
provided are for the Linux/amd64 architecture.

WARNING:
If you use your own runners, make sure your installed version of Docker
is **not** `19.03.0`. See [troubleshooting information](#error-response-from-daemon-error-processing-tar-file-docker-tar-relocation-error) for details.

WARNING:
Dependency Scanning does not support run-time installation of compilers and interpreters.
If you have need of this, please explain why by filling out the survey [here](https://docs.google.com/forms/d/e/1FAIpQLScKo7xEYA65rOjPTGIufAyfjPGnCALSJZoTxBlvskfFMEOZMw/viewform).

## Supported languages and package managers

Dependency Scanning automatically detects the languages used in the repository. All analyzers
matching the detected languages are run. There is usually no need to customize the selection of
analyzers. We recommend not specifying the analyzers so you automatically use the full selection
for best coverage, avoiding the need to make adjustments when there are deprecations or removals.
However, you can override the selection using the variable `DS_EXCLUDED_ANALYZERS`.

The language detection relies on CI job [`rules`](../../../ci/yaml/index.md#rules) and searches a
maximum of two directory levels from the repository's root. For example, the
`gemnasium-dependency_scanning` job is enabled if a repository contains either `Gemfile`,
`api/Gemfile`, or `api/client/Gemfile`, but not if the only supported dependency file is `api/v1/client/Gemfile`.

The following languages and dependency managers are supported:

<style>
table.supported-languages tr:nth-child(even) {
    background-color: transparent;
}

table.supported-languages td {
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.supported-languages tr td:first-child {
    border-left: 0;
}

table.supported-languages tr td:last-child {
    border-right: 0;
}

table.supported-languages ul {
    font-size: 1em;
    list-style-type: none;
    padding-left: 0px;
    margin-bottom: 0px;
}
</style>

<!-- markdownlint-disable MD044 -->
<table class="supported-languages">
  <thead>
    <tr>
      <th>Language</th>
      <th>Language Versions</th>
      <th>Package Manager</th>
      <th>Supported files</th>
      <th>Analyzer</th>
      <th><a href="#how-multiple-files-are-processed">Processes multiple files?</a></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Ruby</td>
      <td>N/A</td>
      <td><a href="https://bundler.io/">Bundler</a></td>
      <td>
        <ul>
            <li><code>Gemfile.lock</code></li>
            <li><code>gems.locked</code></li>
        </ul>
      </td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>Y</td>
    </tr>
    <tr>
      <td>PHP</td>
      <td>N/A</td>
      <td><a href="https://getcomposer.org/">Composer</a></td>
      <td><code>composer.lock</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>Y</td>
    </tr>
    <tr>
      <td>C</td>
      <td rowspan="2">N/A</td>
      <td rowspan="2"><a href="https://conan.io/">Conan</a></td>
      <td rowspan="2"><a href="https://docs.conan.io/en/latest/versioning/lockfiles.html"><code>conan.lock</code></a></td>
      <td rowspan="2"><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td rowspan="2">Y</td>
    </tr>
    <tr>
      <td>C++</td>
    </tr>
    <tr>
      <td>Go</td>
      <td>N/A</td>
      <td><a href="https://go.dev/">Go</a></td>
      <td><code>go.sum</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>Y</td>
    </tr>
    <tr>
      <td rowspan="2">Java</td>
      <td rowspan="2">8, 11, 13, 14, 15, 16, or 17</td>
      <td><a href="https://gradle.org/">Gradle</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-1">1</a></b></sup></td>
      <td>
        <ul>
            <li><code>build.gradle</code></li>
            <li><code>build.gradle.kts</code></li>
        </ul>
      </td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a></td>
      <td><code>pom.xml</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td rowspan="2">JavaScript</td>
      <td>N/A</td>
      <td><a href="https://www.npmjs.com/">npm</a></td>
      <td>
        <ul>
            <li><code>package-lock.json</code></li>
            <li><code>npm-shrinkwrap.json</code></li>
        </ul>
      </td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>Y</td>
    </tr>
    <tr>
      <td>N/A</td>
      <td><a href="https://classic.yarnpkg.com/en/">yarn</a></td>
      <td><code>yarn.lock</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>Y</td>
    </tr>
    <tr>
      <td>.NET</td>
      <td rowspan="2">N/A</td>
      <td rowspan="2"><a href="https://www.nuget.org/">NuGet</a></td>
      <td rowspan="2"><a href="https://docs.microsoft.com/en-us/nuget/consume-packages/package-references-in-project-files#enabling-lock-file"><code>packages.lock.json</code></a></td>
      <td rowspan="2"><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td rowspan="2">Y</td>
    </tr>
    <tr>
      <td>C#</td>
    </tr>
    <tr>
      <td rowspan="4">Python</td>
      <td rowspan="4">3.9</td>
      <td><a href="https://setuptools.readthedocs.io/en/latest/">setuptools</a></td>
      <td><code>setup.py</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://pip.pypa.io/en/stable/">pip</a></td>
      <td>
        <ul>
            <li><code>requirements.txt</code></li>
            <li><code>requirements.pip</code></li>
            <li><code>requires.txt</code></li>
        </ul>
      </td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://pipenv.pypa.io/en/latest/">Pipenv</a></td>
      <td>
        <ul>
            <li><a href="https://pipenv.pypa.io/en/latest/basics/#example-pipfile-pipfile-lock"><code>Pipfile</code></a></li>
            <li><a href="https://pipenv.pypa.io/en/latest/basics/#example-pipfile-pipfile-lock"><code>Pipfile.lock</code></a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-2">2</a></b></sup></li>
        </ul>
      </td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://python-poetry.org/">Poetry</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-4">4</a></b></sup></td>
      <td><code>poetry.lock</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td>Scala</td>
      <td>N/A</td>
      <td><a href="https://www.scala-sbt.org/">sbt</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-3">3</a></b></sup></td>
      <td><code>build.sbt</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
  </tbody>
</table>

<ol>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-1"></a>
    <p>
      Although Gradle with Java 8 is supported, there are other issues such that Android project builds are not supported at this time.
      Please see the backlog issue <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/336866">Android support for Dependency
      Scanning (gemnasium-maven)</a> for more details.
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-2"></a>
    <p>
      The presence of a <code>Pipfile.lock</code> file alone will <i>not</i> trigger the analyzer; the presence of a <code>Pipfile</code> is
      still required in order for the analyzer to be executed. However, if a <code>Pipfile.lock</code> file is found, it will be used by
      <code>Gemnasium</code> to scan the exact package versions listed in this file.
    </p>
    <p>
      Support for <code>Pipfile.lock</code> files without requiring the presence of a <code>Pipfile</code> is tracked in
      issue: <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/299294">Dependency Scanning of Pipfile.lock without
      installing project dependencies</a>.
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-3"></a>
    <p>
      Support for <a href="https://www.scala-sbt.org/">sbt</a> 1.3 and above was added in GitLab 13.9.
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-4"></a>
    <p>
      Support for <a href="https://python-poetry.org/">Poetry</a> projects with a <code>poetry.lock</code> file was <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/7006">added in GitLab 15.0</a>.
      Support for projects without a <code>poetry.lock</code> file is tracked in issue:
      <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/32774">Poetry's pyproject.toml support for dependency scanning.</a>
    </p>
  </li>
</ol>
<!-- markdownlint-enable MD044 -->

### How analyzers obtain dependency information

GitLab analyzers obtain dependency information using one of the following two methods:

1. [Parsing lockfiles directly.](#obtaining-dependency-information-by-parsing-lockfiles)
1. [Running a package manager or build tool to generate a dependency information file which is then parsed.](#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)

#### Obtaining dependency information by parsing lockfiles

The following package managers use lockfiles that GitLab analyzers are capable of parsing directly:

| Package Manager | Supported File Format Versions | Tested Versions                                                                                                                                                                                                                    |
| ------          | ------                         | ------                                                                                                                                                                                                                             |
| Bundler         | N/A                            | [1.17.3](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/ruby-bundler/default/Gemfile.lock#L118), [2.1.4](https://gitlab.com/gitlab-org/security-products/tests/ruby-bundler/-/blob/bundler2-FREEZE/Gemfile.lock#L118) |
| Composer        | N/A                            | [1.x](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/php-composer/default/composer.lock)                                                                                                                              |
| Conan           | 0.4                            | [1.x](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/c-conan/default/conan.lock)                                                                                                                                      |
| Go              | N/A                            | [1.x](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/go-modules/default/go.sum)                                                                                                                                       |
| NuGet           | v1                             | [4.9](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/csharp-nuget-dotnetcore/default/src/web.api/packages.lock.json#L2)                                                                                               |
| npm             | v1, v2                         | [6.x](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-npm/default/package-lock.json#L4), [7.x](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-npm/lockfileVersion2/package-lock.json#L4)         |
| yarn            | v1                             | [1.x](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/default/yarn.lock#L2)                                                                                                                                       |
| Poetry          | v1                             | [1.x](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python/-/blob/v3/qa/fixtures/python-poetry/default/poetry.lock)                                                                                                          |

#### Obtaining dependency information by running a package manager to generate a parsable file

To support the following package managers, the GitLab analyzers proceed in two steps:

1. Execute the package manager or a specific task, to export the dependency information.
1. Parse the exported dependency information.

| Package Manager | Pre-installed Versions                                                                                                                                                                                                                                                                                                                                                                                     | Tested Versions                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------          | ------                                                                                                                                                                                                                                                                                                                                                                                                     | ------                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| sbt             | [1.6.1](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.24.6/config/.tool-versions#L4)                                                                                                                                                                                                                                                                                 | [1.0.4](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L443-447), [1.1.6](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L449-453), [1.2.8](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L455-459), [1.3.12](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L461-465), [1.4.6](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L467-471), [1.5.8](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L473-477), [1.6.1](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L479-483)                                                                                                                                                                                                                                                                                                                                                                                                |
| Maven           | [3.6.3](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L95-97)                                                                                                                                                                                                                                                                                 | [3.6.3](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L95-97)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| Gradle          | [6.7.1](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.23.0/config/.tool-versions#L5)<sup><b><a href="#exported-dependency-information-notes-1">1</a></b></sup>, [7.3.3](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.26.0/config/.tool-versions#L5)<sup><b><a href="#exported-dependency-information-notes-1">1</a></b></sup> | [5.6.4](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L319-323), [6.7](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L286-288)<sup><b><a href="#exported-dependency-information-notes-2">2</a></b></sup>, [6.9](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L331-335), [7.3](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/blob/v2.28.1/spec/image_spec.rb#L300-302)<sup><b><a href="#exported-dependency-information-notes-2">2</a></b></sup> |
| setuptools      | [50.3.2](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v2.29.9/Dockerfile#L27)                                                                                                                                                                                                                                                                                                | [57.5.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python/-/blob/v2.22.0/spec/image_spec.rb#L224-247)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| pip             | [20.2.4](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v2.29.9/Dockerfile#L26)                                                                                                                                                                                                                                                                                                | [20.x](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python/-/blob/v2.22.0/spec/image_spec.rb#L77-91)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Pipenv          | [2018.11.26](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python/-/blob/v2.18.4/requirements.txt#L13)                                                                                                                                                                                                                                                                               | [2018.11.26](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python/-/blob/v2.22.0/spec/image_spec.rb#L168-191)<sup><b><a href="#exported-dependency-information-notes-3">3</a></b></sup>, [2018.11.26](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python/-/blob/v2.22.0/spec/image_spec.rb#L143-166)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |

<!-- markdownlint-disable MD044 -->
<ol>
  <li>
    <a id="exported-dependency-information-notes-1"></a>
    <p>
      Different versions of Java require different versions of Gradle. The versions of Gradle listed in the above table are pre-installed
      in the analyzer image. The version of Gradle used by the analyzer depends on whether your project uses a <code>gradlew</code>
      (Gradle wrapper) file or not:
    </p>
    <ul>
      <li>
        <p>
          If your project <i>does not use</i> a <code>gradlew</code> file, then the analyzer automatically switches to one of the
          pre-installed Gradle versions, based on the version of Java specified by the
          <a href="#configuring-specific-analyzers-used-by-dependency-scanning"><code>DS_JAVA_VERSION</code></a> variable.
        </p>
        <p>You can view the
          <a href="https://docs.gradle.org/current/userguide/compatibility.html#java">Gradle Java compatibility matrix</a> to see which version
          of Gradle is selected for each Java version. Note that we only support switching to one of these pre-installed Gradle versions
          for Java versions 13 to 17.
        </p>
      </li>
      <li>
        <p>
          If your project <i>does use</i> a <code>gradlew</code> file, then the version of Gradle pre-installed in the analyzer image is
          ignored, and the version specified in your <code>gradlew</code> file is used instead.
        </p>
      </li>
    </ul>
  </li>
  <li>
    <a id="exported-dependency-information-notes-2"></a>
    <p>
      These tests confirm that if a <code>gradlew</code> file does not exist, the version of <code>Gradle</code> pre-installed in the analyzer image is used.
    </p>
  </li>
  <li>
    <a id="exported-dependency-information-notes-3"></a>
    <p>
      This test confirms that if a <code>Pipfile.lock</code> file is found, it will be used by <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a> to scan the exact package versions listed in this file.
    </p>
  </li>
</ol>
<!-- markdownlint-enable MD044 -->

### How analyzers are triggered

GitLab relies on [`rules:exists`](../../../ci/yaml/index.md#rulesexists) to start the relevant analyzers for the languages detected by the presence of the
`Supported files` in the repository as shown in the [table above](#supported-languages-and-package-managers).

The current detection logic limits the maximum search depth to two levels. For example, the `gemnasium-dependency_scanning` job is enabled if
a repository contains either a `Gemfile.lock`, `api/Gemfile.lock`, or `api/client/Gemfile.lock`, but not if the only supported dependency file is `api/v1/client/Gemfile.lock`.

### How multiple files are processed

NOTE:
If you've run into problems while scanning multiple files, please contribute a comment to
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/337056).

#### Python

We only execute one installation in the directory where either a requirements file or a lock file has been detected. Dependencies are only analyzed by `gemnasium-python` for the first file that is detected. Files are searched for in the following order:

1. `requirements.txt`, `requirements.pip`, or `requires.txt` for projects using Pip.
1. `Pipfile` or `Pipfile.lock` for projects using Pipenv.
1. `poetry.lock` for projects using Poetry.
1. `setup.py` for project using Setuptools.

The search begins with the root directory and then continues with subdirectories if no builds are found in the root directory. Consequently a Poetry lock file in the root directory would be detected before a Pipenv file in a subdirectory.

#### Java and Scala

We only execute one build in the directory where a build file has been detected. For large projects that include
multiple Gradle, Maven, or sbt builds, or any combination of these, `gemnasium-maven` only analyzes dependencies for the first build file
that is detected. Build files are searched for in the following order:

1. `build.gradle` or `build.gradle.kts` for single or [multi-project](https://docs.gradle.org/current/userguide/intro_multi_project_builds.html) Gradle builds.
1. `pom.xml` for single or [multi-module](https://maven.apache.org/pom.html#Aggregation) Maven projects.
1. `build.sbt` for single or [multi-project](https://www.scala-sbt.org/1.x/docs/Multi-Project.html) sbt builds.

The search begins with the root directory and then continues with subdirectories if no builds are found in the root directory. Consequently an sbt build file in the root directory would be detected before a Gradle build file in a subdirectory.

#### JavaScript

The following analyzers are executed, each of which have different behavior when processing multiple files:

- [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)

   Supports multiple lockfiles

- [Retire.js](https://retirejs.github.io/retire.js/)

   Does not support multiple lockfiles. When multiple lockfiles exist, `Retire.js`
   analyzes the first lockfile discovered while traversing the directory tree in alphabetical order.

From GitLab 14.8 the `gemnasium` analyzer scans supported JavaScript projects for vendored libraries
(that is, those checked into the project but not managed by the package manager).

#### PHP, Go, C, C++, .NET, C&#35;, Ruby, JavaScript

The analyzer for these languages supports multiple lockfiles.

#### Support for additional languages

Support for additional languages, dependency managers, and dependency files are tracked in the following issues:

| Package Managers    | Languages | Supported files | Scan tools | Issue |
| ------------------- | --------- | --------------- | ---------- | ----- |
| [Poetry](https://python-poetry.org/) | Python | `pyproject.toml` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) | [GitLab#32774](https://gitlab.com/gitlab-org/gitlab/-/issues/32774) |

## Contribute your scanner

The [Security Scanner Integration](../../../development/integrations/secure.md) documentation explains how to integrate other security scanners into GitLab.

## Configuration

To enable dependency scanning for GitLab 11.9 and later, you must
[include](../../../ci/yaml/index.md#includetemplate) the
[`Dependency-Scanning.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml)
that is provided as a part of your GitLab installation.
For GitLab versions earlier than 11.9, you can copy and use the job as defined
that template.

Add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml
```

The included template creates dependency scanning jobs in your CI/CD
pipeline and scans your project's source code for possible vulnerabilities.
The results are saved as a
[dependency scanning report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning)
that you can later download and analyze. Due to implementation limitations, we
always take the latest dependency scanning artifact available.

### Enable Dependency Scanning via an automatic merge request

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4908) in GitLab 14.1 [with a flag](../../../administration/feature_flags.md) named `sec_dependency_scanning_ui_enable`. Enabled by default.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/282533) in GitLab 14.1.
> - [Feature flag `sec_dependency_scanning_ui_enable` removed](https://gitlab.com/gitlab-org/gitlab/-/issues/326005) in GitLab 14.2.

To enable Dependency Scanning in a project, you can create a merge request:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Configuration**.
1. In the **Dependency Scanning** row, select **Configure with a merge request**.
1. Review and merge the merge request to enable Dependency Scanning.

Pipelines now include a dependency scanning job.

### Customizing the dependency scanning settings

The Dependency Scanning settings can be changed through [CI/CD variables](#available-cicd-variables) by using the
[`variables`](../../../ci/yaml/index.md#variables) parameter in `.gitlab-ci.yml`.
For example:

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml

variables:
  SECURE_LOG_LEVEL: error
```

Because template is [evaluated before](../../../ci/yaml/index.md#include) the pipeline
configuration, the last mention of the variable takes precedence.

### Overriding dependency scanning jobs

WARNING:
Beginning in GitLab 13.0, the use of [`only` and `except`](../../../ci/yaml/index.md#only--except)
is no longer supported. When overriding the template, you must use [`rules`](../../../ci/yaml/index.md#rules) instead.

To override a job definition (for example, to change properties like `variables` or `dependencies`),
declare a new job with the same name as the one to override. Place this new job after the template
inclusion and specify any additional keys under it. For example, this disables `DS_REMEDIATE` for
the `gemnasium` analyzer:

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  variables:
    DS_REMEDIATE: "false"
```

To override the `dependencies: []` attribute, add an override job as above, targeting this attribute:

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  dependencies: ["build"]
```

### Available CI/CD variables

Dependency scanning can be [configured](#customizing-the-dependency-scanning-settings)
using environment variables.

#### Configuring dependency scanning

The following variables allow configuration of global dependency scanning settings.

| CI/CD variables             | Description |
| ----------------------------|------------ |
| `ADDITIONAL_CA_CERT_BUNDLE` | Bundle of CA certs to trust. The bundle of certificates provided here is also used by other tools during the scanning process, such as `git`, `yarn`, or `npm`. See [Using a custom SSL CA certificate authority](#using-a-custom-ssl-ca-certificate-authority) for more details. |
| `DS_EXCLUDED_ANALYZERS`      | Specify the analyzers (by name) to exclude from Dependency Scanning. For more information, see [Dependency Scanning Analyzers](analyzers.md). |
| `DS_DEFAULT_ANALYZERS`      | This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/287691) in GitLab 14.0 and [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/333299) in 15.0. Use `DS_EXCLUDED_ANALYZERS` instead. |
| `DS_EXCLUDED_PATHS`         | Exclude files and directories from the scan based on the paths. A comma-separated list of patterns. Patterns can be globs, or file or folder paths (for example, `doc,spec`). Parent directories also match patterns. Default: `"spec, test, tests, tmp"`. |
| `DS_IMAGE_SUFFIX`           | Suffix added to the image name. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354796) in GitLab 14.10.) Automatically set to `"-fips"` when FIPS mode is enabled. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/357922) in GitLab 15.0.) |
| `SECURE_ANALYZERS_PREFIX`   | Override the name of the Docker registry providing the official default images (proxy). Read more about [customizing analyzers](analyzers.md). |
| `SECURE_LOG_LEVEL`          | Set the minimum logging level. Messages of this logging level or higher are output. From highest to lowest severity, the logging levels are: `fatal`, `error`, `warn`, `info`, `debug`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10880) in GitLab 13.1. Default: `info`. |

#### Configuring specific analyzers used by dependency scanning

The following variables are used for configuring specific analyzers (used for a specific language/framework).

| CI/CD variable                       | Analyzer           | Default                      | Description |
|--------------------------------------| ------------------ | ---------------------------- |------------ |
| `GEMNASIUM_DB_LOCAL_PATH`            | `gemnasium`        | `/gemnasium-db`              | Path to local Gemnasium database. |
| `GEMNASIUM_DB_UPDATE_DISABLED`       | `gemnasium`        | `"false"`                    | Disable automatic updates for the `gemnasium-db` advisory database (For usage see: [examples](#hosting-a-copy-of-the-gemnasium_db-advisory-database))|
| `GEMNASIUM_DB_REMOTE_URL`            | `gemnasium`        | `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git` | Repository URL for fetching the Gemnasium database. |
| `GEMNASIUM_DB_REF_NAME`              | `gemnasium`        | `master`                     | Branch name for remote repository database. `GEMNASIUM_DB_REMOTE_URL` is required. |
| `DS_REMEDIATE`                       | `gemnasium`        | `"true"`                     | Enable automatic remediation of vulnerable dependencies. |
| `GEMNASIUM_LIBRARY_SCAN_ENABLED`     | `gemnasium`        | `"true"`                     | Enable detecting vulnerabilities in vendored JavaScript libraries. For now, `gemnasium` leverages [`Retire.js`](https://github.com/RetireJS/retire.js) to do this job. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350512) in GitLab 14.8. |
| `DS_JAVA_VERSION`                    | `gemnasium-maven`  | `17`                         | Version of Java. Available versions: `8`, `11`, `13`, `14`, `15`, `16`, `17`. |
| `MAVEN_CLI_OPTS`                     | `gemnasium-maven`  | `"-DskipTests --batch-mode"` | List of command line arguments that are passed to `maven` by the analyzer. See an example for [using private repositories](../index.md#using-private-maven-repositories). |
| `GRADLE_CLI_OPTS`                    | `gemnasium-maven`  |                              | List of command line arguments that are passed to `gradle` by the analyzer. |
| `SBT_CLI_OPTS`                       | `gemnasium-maven`  |                              | List of command-line arguments that the analyzer passes to `sbt`. |
| `PIP_INDEX_URL`                      | `gemnasium-python` | `https://pypi.org/simple`    | Base URL of Python Package Index. |
| `PIP_EXTRA_INDEX_URL`                | `gemnasium-python` |                              | Array of [extra URLs](https://pip.pypa.io/en/stable/reference/pip_install/#cmdoption-extra-index-url) of package indexes to use in addition to `PIP_INDEX_URL`. Comma-separated. **Warning:** Please read [the following security consideration](#python-projects) when using this environment variable. |
| `PIP_REQUIREMENTS_FILE`              | `gemnasium-python` |                              | Pip requirements file to be scanned. |
| `DS_PIP_VERSION`                     | `gemnasium-python` |                              | Force the install of a specific pip version (example: `"19.3"`), otherwise the pip installed in the Docker image is used. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12811) in GitLab 12.7) |
| `DS_PIP_DEPENDENCY_PATH`             | `gemnasium-python` |                              | Path to load Python pip dependencies from. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12412) in GitLab 12.2) |

#### Other variables

The previous tables are not an exhaustive list of all variables that can be used. They contain all specific GitLab and analyzer variables we support and test. There are many variables, such as environment variables, that you can pass in and they will work. This is a large list, many of which we may be unaware of, and as such is not documented.

For example, to pass the non-GitLab environment variable `HTTPS_PROXY` to all Dependency Scanning jobs,
set it as a [custom CI/CD variable in your `.gitlab-ci.yml`](../../../ci/variables/#create-a-custom-cicd-variable-in-the-gitlab-ciyml-file)
file like this:

```yaml
variables:
  HTTPS_PROXY: "https://squid-proxy:3128"
```

Alternatively we may use it in specific jobs, like Dependency Scanning:

```yaml
dependency_scanning:
  variables:
    HTTPS_PROXY: $HTTPS_PROXY
```

As we have not tested all variables you may find some will work and others will not.
If one does not work and you need it we suggest
[submitting a feature request](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Feature%20proposal%20-%20detailed&issue[title]=Docs%20feedback%20-%20feature%20proposal:%20Write%20your%20title)
or [contributing to the code](../../../development/index.md) to enable it to be used.

### Using a custom SSL CA certificate authority

You can use the `ADDITIONAL_CA_CERT_BUNDLE` CI/CD variable to configure a custom SSL CA certificate authority. The `ADDITIONAL_CA_CERT_BUNDLE` value should contain the [text representation of the X.509 PEM public-key certificate](https://tools.ietf.org/html/rfc7468#section-5.1). For example, to configure this value in the `.gitlab-ci.yml` file, use the following:

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

The `ADDITIONAL_CA_CERT_BUNDLE` value can also be configured as a [custom variable in the UI](../../../ci/variables/index.md#custom-cicd-variables), either as a `file`, which requires the path to the certificate, or as a variable, which requires the text representation of the certificate.

### Using private Maven repositories

If your private Maven repository requires login credentials,
you can use the `MAVEN_CLI_OPTS` CI/CD variable.

Read more on [how to use private Maven repositories](../index.md#using-private-maven-repositories).

#### FIPS-enabled images

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354796) in GitLab 14.10.

GitLab also offers [FIPS-enabled Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)
versions of the Gemnasium images. You can therefore replace standard images with FIPS-enabled images.

Gemnasium scanning jobs automatically use FIPS-enabled image when FIPS mode is enabled in the GitLab instance.
([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/357922) in GitLab 15.0.)

To manually switch to FIPS-enabled images, set the variable `DS_IMAGE_SUFFIX` to `"-fips"`.

## Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to
[address the vulnerabilities](../vulnerabilities/index.md).

## Solutions for vulnerabilities

Some vulnerabilities can be fixed by applying the solution that GitLab
automatically generates. Read more about the
[solutions for vulnerabilities](../vulnerabilities/index.md#resolve-a-vulnerability).

## Security Dashboard

The Security Dashboard is a good place to get an overview of all the security
vulnerabilities in your groups, projects and pipelines. Read more about the
[Security Dashboard](../security_dashboard/index.md).

## Vulnerabilities database update

For more information about the vulnerabilities database update, see the
[maintenance table](../index.md#vulnerability-scanner-maintenance).

## Dependency List

An additional benefit of dependency scanning is the ability to view your
project's dependencies and their known vulnerabilities. Read more about
the [Dependency List](../dependency_list/index.md).

## Reports JSON format

The dependency scanning tool emits a JSON report file. For more information, see the
[schema for this report](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/dependency-scanning-report-format.json).

Here's an example dependency scanning report:

```json
{
  "version": "2.0",
  "vulnerabilities": [
    {
      "id": "51e83874-0ff6-4677-a4c5-249060554eae",
      "category": "dependency_scanning",
      "name": "Regular Expression Denial of Service",
      "message": "Regular Expression Denial of Service in debug",
      "description": "The debug module is vulnerable to regular expression denial of service when untrusted user input is passed into the `o` formatter. It takes around 50k characters to block for 2 seconds making this a low severity issue.",
      "severity": "Unknown",
      "solution": "Upgrade to latest versions.",
      "scanner": {
        "id": "gemnasium",
        "name": "Gemnasium"
      },
      "location": {
        "file": "yarn.lock",
        "dependency": {
          "package": {
            "name": "debug"
          },
          "version": "1.0.5"
        }
      },
      "identifiers": [
        {
          "type": "gemnasium",
          "name": "Gemnasium-37283ed4-0380-40d7-ada7-2d994afcc62a",
          "value": "37283ed4-0380-40d7-ada7-2d994afcc62a",
          "url": "https://deps.sec.gitlab.com/packages/npm/debug/versions/1.0.5/advisories"
        }
      ],
      "links": [
        {
          "url": "https://nodesecurity.io/advisories/534"
        },
        {
          "url": "https://github.com/visionmedia/debug/issues/501"
        },
        {
          "url": "https://github.com/visionmedia/debug/pull/504"
        }
      ]
    },
    {
      "id": "5d681b13-e8fa-4668-957e-8d88f932ddc7",
      "category": "dependency_scanning",
      "name": "Authentication bypass via incorrect DOM traversal and canonicalization",
      "message": "Authentication bypass via incorrect DOM traversal and canonicalization in saml2-js",
      "description": "Some XML DOM traversal and canonicalization APIs may be inconsistent in handling of comments within XML nodes. Incorrect use of these APIs by some SAML libraries results in incorrect parsing of the inner text of XML nodes such that any inner text after the comment is lost prior to cryptographically signing the SAML message. Text after the comment, therefore, has no impact on the signature on the SAML message.\r\n\r\nA remote attacker can modify SAML content for a SAML service provider without invalidating the cryptographic signature, which may allow attackers to bypass primary authentication for the affected SAML service provider.",
      "severity": "Unknown",
      "solution": "Upgrade to fixed version.\r\n",
      "scanner": {
        "id": "gemnasium",
        "name": "Gemnasium"
      },
      "location": {
        "file": "yarn.lock",
        "dependency": {
          "package": {
            "name": "saml2-js"
          },
          "version": "1.5.0"
        }
      },
      "identifiers": [
        {
          "type": "gemnasium",
          "name": "Gemnasium-9952e574-7b5b-46fa-a270-aeb694198a98",
          "value": "9952e574-7b5b-46fa-a270-aeb694198a98",
          "url": "https://deps.sec.gitlab.com/packages/npm/saml2-js/versions/1.5.0/advisories"
        },
        {
          "type": "cve",
          "name": "CVE-2017-11429",
          "value": "CVE-2017-11429",
          "url": "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-11429"
        }
      ],
      "links": [
        {
          "url": "https://github.com/Clever/saml2/commit/3546cb61fd541f219abda364c5b919633609ef3d#diff-af730f9f738de1c9ad87596df3f6de84R279"
        },
        {
          "url": "https://github.com/Clever/saml2/issues/127"
        },
        {
          "url": "https://www.kb.cert.org/vuls/id/475445"
        }
      ]
    }
  ],
  "remediations": [
    {
      "fixes": [
        {
          "id": "5d681b13-e8fa-4668-957e-8d88f932ddc7",
        }
      ],
      "summary": "Upgrade saml2-js",
      "diff": "ZGlmZiAtLWdpdCBhL...OR0d1ZUc2THh3UT09Cg==" // some content is omitted for brevity
    }
  ]
}
```

### CycloneDX Software Bill of Materials

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350509) in GitLab 14.8 in [Beta](../../../policy/alpha-beta-support.md#beta-features).

In addition to the [JSON report file](#reports-json-format), the [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)
Dependency Scanning tool outputs a [CycloneDX](https://cyclonedx.org/) Software Bill of Materials (SBOM) for
each supported lock or build file it detects. These CycloneDX SBOMs are named
`cyclonedx-<package-type>-<package-manager>.json`, and are saved in the same directory
as the detected lock or build files.

For example, if your project has the following structure:

```plaintext
.
├── ruby-project/
│   └── Gemfile.lock
├── ruby-project-2/
│   └── Gemfile.lock
├── php-project/
│   └── composer.lock
└── go-project/
    └── go.sum
```

Then the Gemnasium scanner generates the following CycloneDX SBOMs:

```plaintext
.
├── ruby-project/
│   ├── Gemfile.lock
│   └── cyclonedx-gem-bundler.json
├── ruby-project-2/
│   ├── Gemfile.lock
│   └── cyclonedx-gem-bundler.json
├── php-project/
│   ├── composer.lock
│   └── cyclonedx-packagist-composer.json
└── go-project/
    ├── go.sum
    └── cyclonedx-go-go.json
```

The CycloneDX SBOMs can be downloaded [the same way as other job artifacts](../../../ci/pipelines/job_artifacts.md#download-job-artifacts).

### Merging multiple CycloneDX SBOMs

You can use a CI/CD job to merge multiple CycloneDX SBOMs into a single SBOM.
For example:

```yaml
stages:
  - test
  - merge-cyclonedx-sboms

include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml

merge cyclonedx sboms:
  stage: merge-cyclonedx-sboms
  image: alpine:latest
  script:
    - wget https://github.com/CycloneDX/cyclonedx-cli/releases/download/v0.22.0/cyclonedx-linux-musl-x64 -O /usr/local/bin/cyclonedx-cli
    - chmod 755 /usr/local/bin/cyclonedx-cli
    - apk --update add --no-cache icu-dev libstdc++
    - find * -name "cyclonedx-*.json" -exec cyclonedx-cli merge --input-files {} --output-file cyclonedx-all.json +
  artifacts:
    paths:
      - cyclonedx-all.json
```

GitLab uses [CycloneDX Properties](https://cyclonedx.org/use-cases/#properties--name-value-store)
to store implementation-specific details in the metadata of each CycloneDX SBOM,
such as the location of build and lock files. If multiple CycloneDX SBOMs are merged together,
this information is removed from the resulting merged file.

NOTE:
CycloneDX SBOMs are a [Beta](../../../policy/alpha-beta-support.md#beta-features) feature,
and the reports are subject to change during the beta period. Do not build integrations
that rely on the format of these SBOMs staying consistent, as the format might change
before the feature is made generally available.

## Versioning and release process

Please check the [Release Process documentation](https://gitlab.com/gitlab-org/security-products/release/blob/master/docs/release_process.md).

## Contributing to the vulnerability database

You can search the [`gemnasium-db`](https://gitlab.com/gitlab-org/security-products/gemnasium-db) project
to find a vulnerability in the GitLab Advisory Database.
You can also [submit new vulnerabilities](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md).

## Running dependency scanning in an offline environment

For self-managed GitLab instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, some adjustments are required for dependency scanning
jobs to run successfully. For more information, see [Offline environments](../offline_deployments/index.md).

### Requirements for offline dependency scanning

Here are the requirements for using dependency scanning in an offline environment:

- GitLab Runner with the [`docker` or `kubernetes` executor](#requirements).
- Docker Container Registry with locally available copies of dependency scanning [analyzer](https://gitlab.com/gitlab-org/security-products/analyzers) images.
- If you have a limited access environment you need to allow access, such as using a proxy, to the advisory database: `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git`.
  If you are unable to permit access to `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git` you must host an offline copy of this `git` repository and set the `GEMNASIUM_DB_REMOTE_URL` CI/CD variable to the URL of this repository. For more information on configuration variables, see [Dependency Scanning](#configuring-dependency-scanning).

  This advisory database is constantly being updated, so you must periodically sync your local copy with GitLab.

Note that GitLab Runner has a [default `pull policy` of `always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy),
meaning the runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. The GitLab Runner [`pull_policy` can be set to `if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)
in an offline environment if you prefer using only locally available Docker images. However, we
recommend keeping the pull policy setting to `always` if not in an offline environment, as this
enables the use of updated scanners in your CI/CD pipelines.

### Make GitLab dependency scanning analyzer images available inside your Docker registry

For dependency scanning with all [supported languages and frameworks](#supported-languages-and-package-managers),
import the following default dependency scanning analyzer images from `registry.gitlab.com` into
your [local Docker container registry](../../packages/container_registry/index.md):

```plaintext
registry.gitlab.com/security-products/gemnasium:3
registry.gitlab.com/security-products/gemnasium-maven:3
registry.gitlab.com/security-products/gemnasium-python:3
```

The process for importing Docker images into a local offline Docker registry depends on
**your network security policy**. Please consult your IT staff to find an accepted and approved
process by which external resources can be imported or temporarily accessed.
These scanners are [periodically updated](../index.md#vulnerability-scanner-maintenance)
with new definitions, and you may be able to make occasional updates on your own.

For details on saving and transporting Docker images as a file, see Docker's documentation on
[`docker save`](https://docs.docker.com/engine/reference/commandline/save/), [`docker load`](https://docs.docker.com/engine/reference/commandline/load/),
[`docker export`](https://docs.docker.com/engine/reference/commandline/export/), and [`docker import`](https://docs.docker.com/engine/reference/commandline/import/).

#### Support for Custom Certificate Authorities

Support for custom certificate authorities was introduced in the following versions.

| Analyzer | Version |
| -------- | ------- |
| `gemnasium` | [v2.8.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/releases/v2.8.0) |
| `gemnasium-maven` | [v2.9.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/releases/v2.9.0) |
| `gemnasium-python` | [v2.7.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python/-/releases/v2.7.0) |

### Set dependency scanning CI/CD job variables to use local dependency scanning analyzers

Add the following configuration to your `.gitlab-ci.yml` file. You must change the value of
`SECURE_ANALYZERS_PREFIX` to refer to your local Docker container registry. You must also change the
value of `GEMNASIUM_DB_REMOTE_URL` to the location of your offline Git copy of the
[`gemnasium-db` advisory database](https://gitlab.com/gitlab-org/security-products/gemnasium-db/):

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml

variables:
  SECURE_ANALYZERS_PREFIX: "docker-registry.example.com/analyzers"
  GEMNASIUM_DB_REMOTE_URL: "gitlab.example.com/gemnasium-db.git"
```

See explanations of the variables above in the [configuration section](#configuration).

### Specific settings for languages and package managers

See the following sections for configuring specific languages and package managers.

#### JavaScript (npm and yarn) projects

Add the following to the variables section of `.gitlab-ci.yml`:

```yaml
RETIREJS_JS_ADVISORY_DB: "example.com/jsrepository.json"
RETIREJS_NODE_ADVISORY_DB: "example.com/npmrepository.json"
```

#### Ruby (gem) projects

Add the following to the variables section of `.gitlab-ci.yml`:

```yaml
BUNDLER_AUDIT_ADVISORY_DB_REF_NAME: "master"
BUNDLER_AUDIT_ADVISORY_DB_URL: "gitlab.example.com/ruby-advisory-db.git"
```

#### Python (pip)

If you need to install Python packages before the analyzer runs, you should use `pip install --user` in the `before_script` of the scanning job. The `--user` flag causes project dependencies to be installed in the user directory. If you do not pass the `--user` option, packages are installed globally, and they are not scanned and don't show up when listing project dependencies.

#### Python (setuptools)

If you need to install Python packages before the analyzer runs, you should use `python setup.py install --user` in the `before_script` of the scanning job. The `--user` flag causes project dependencies to be installed in the user directory. If you do not pass the `--user` option, packages are installed globally, and they are not scanned and don't show up when listing project dependencies.

When using self-signed certificates for your private PyPi repository, no extra job configuration (aside
from the template `.gitlab-ci.yml` above) is needed. However, you must update your `setup.py` to
ensure that it can reach your private repository. Here is an example configuration:

1. Update `setup.py` to create a `dependency_links` attribute pointing at your private repository for each
   dependency in the `install_requires` list:

   ```python
   install_requires=['pyparsing>=2.0.3'],
   dependency_links=['https://pypi.example.com/simple/pyparsing'],
   ```

1. Fetch the certificate from your repository URL and add it to the project:

   ```shell
   echo -n | openssl s_client -connect pypi.example.com:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > internal.crt
   ```

1. Point `setup.py` at the newly downloaded certificate:

   ```python
   import setuptools.ssl_support
   setuptools.ssl_support.cert_paths = ['internal.crt']
   ```

## Hosting a copy of the gemnasium_db advisory database

The [`gemnasium_db`](https://gitlab.com/gitlab-org/security-products/gemnasium-db) Git repository is
used by `gemnasium`, `gemnasium-maven`, and `gemnasium-python` as the source of vulnerability data.
This repository updates at scan time to fetch the latest advisories. However, due to a restricted
networking environment, running this update is sometimes not possible. In this case, a user can do
one of the following:

- [Host a copy of the advisory database](#host-a-copy-of-the-advisory-database)
- [Use a local clone](#use-a-local-clone)

### Host a copy of the advisory database

If [gemnasium-db](https://gitlab.com/gitlab-org/security-products/gemnasium-db) is not reachable
from within the environment, the user can host their own Git copy. Then the analyzer can be
instructed to update the database from the user's copy by using `GEMNASIUM_DB_REMOTE_URL`:

```yaml
variables:
  GEMNASIUM_DB_REMOTE_URL: https://users-own-copy.example.com/gemnasium-db/.git

...
```

### Use a local clone

If a hosted copy is not possible, then the user can clone [gemnasium-db](https://gitlab.com/gitlab-org/security-products/gemnasium-db)
or create an archive before the scan and point the analyzer to the directory (using:
`GEMNASIUM_DB_LOCAL_PATH`). Turn off the analyzer's self-update mechanism (using:
`GEMNASIUM_DB_UPDATE_DISABLED`). In this example, the database directory is created in the
`before_script`, before the `gemnasium` analyzer's scan job:

```yaml
...

gemnasium-dependency_scanning:
  variables:
    GEMNASIUM_DB_LOCAL_PATH: ./gemnasium-db-local
    GEMNASIUM_DB_UPDATE_DISABLED: "true"
  before_script:
    - mkdir $GEMNASIUM_DB_LOCAL_PATH
    - tar -xzf gemnasium_db.tar.gz -C $GEMNASIUM_DB_LOCAL_PATH
```

## Warnings

We recommend that you use the most recent version of all containers, and the most recent supported version of all package managers and languages. Using previous versions carries an increased security risk because unsupported versions may no longer benefit from active security reporting and backporting of security fixes.

### Python projects

Extra care needs to be taken when using the [`PIP_EXTRA_INDEX_URL`](https://pipenv.pypa.io/en/latest/cli/#envvar-PIP_EXTRA_INDEX_URL)
environment variable due to a possible exploit documented by [CVE-2018-20225](https://nvd.nist.gov/vuln/detail/CVE-2018-20225):

> An issue was discovered in pip (all versions) because it installs the version with the highest version number, even if the user had
intended to obtain a private package from a private index. This only affects use of the `PIP_EXTRA_INDEX_URL` option, and exploitation
requires that the package does not already exist in the public index (and thus the attacker can put the package there with an arbitrary
version number).

## Troubleshooting

### Working around missing support for certain languages or package managers

As noted in the ["Supported languages" section](#supported-languages-and-package-managers)
some dependency definition files are not yet supported.
However, Dependency Scanning can be achieved if
the language, a package manager, or a third-party tool
can convert the definition file
into a supported format.

Generally, the approach is the following:

1. Define a dedicated converter job in your `.gitlab-ci.yml` file.
   Use a suitable Docker image, script, or both to facilitate the conversion.
1. Let that job upload the converted, supported file as an artifact.
1. Add [`dependencies: [<your-converter-job>]`](../../../ci/yaml/index.md#dependencies)
   to your `dependency_scanning` job to make use of the converted definitions files.

For example, Poetry projects that _only_ have a `pyproject.toml`
file can generate the `poetry.lock` file as follows.

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml

stages:
  - test

gemnasium-python-dependency_scanning:
  # Work around https://gitlab.com/gitlab-org/gitlab/-/issues/32774
  before_script:
    - pip install "poetry>=1,<2"  # Or via another method: https://python-poetry.org/docs/#installation
    - poetry update --lock # Generates the lock file to be analyzed.
```

### `Error response from daemon: error processing tar file: docker-tar: relocation error`

This error occurs when the Docker version that runs the dependency scanning job is `19.03.0`.
Consider updating to Docker `19.03.1` or greater. Older versions are not
affected. Read more in
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/13830#note_211354992 "Current SAST container fails").

### Getting warning message `gl-dependency-scanning-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/pipelines/job_artifacts.md#error-message-no-files-to-upload).

### Limitation when using rules:exists

The [dependency scanning CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml)
uses the [`rules:exists`](../../../ci/yaml/index.md#rulesexists)
syntax. This directive is limited to 10000 checks and always returns `true` after reaching this
number. Because of this, and depending on the number of files in your repository, a dependency
scanning job might be triggered even if the scanner doesn't support your project.

### Error: `dependency_scanning is used for configuration only, and its script should not be executed`

For information on this, see the [GitLab Secure troubleshooting section](../index.md#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed).

### Import multiple certificates for Java-based projects

The `gemnasium-maven` analyzer reads the contents of the `ADDITIONAL_CA_CERT_BUNDLE` variable using `keytool`, which imports either a single certificate or a certificate chain. Multiple unrelated certificates are ignored and only the first one is imported by `keytool`.

To add multiple unrelated certificates to the analyzer, you can declare a `before_script` such as this in the definition of the `gemnasium-maven-dependency_scanning` job:

```yaml
gemnasium-maven-dependency_scanning:
  before_script:
    - . $HOME/.bashrc # make the java tools available to the script
    - OIFS="$IFS"; IFS=""; echo $ADDITIONAL_CA_CERT_BUNDLE > multi.pem; IFS="$OIFS" # write ADDITIONAL_CA_CERT_BUNDLE variable to a PEM file
    - csplit -z --digits=2 --prefix=cert multi.pem "/-----END CERTIFICATE-----/+1" "{*}" # split the file into individual certificates
    - for i in `ls cert*`; do keytool -v -importcert -alias "custom-cert-$i" -file $i -trustcacerts -noprompt -storepass changeit -keystore /opt/asdf/installs/java/adoptopenjdk-11.0.7+10.1/lib/security/cacerts 1>/dev/null 2>&1 || true; done # import each certificate using keytool (note the keystore location is related to the Java version being used and should be changed accordingly for other versions)
    - unset ADDITIONAL_CA_CERT_BUNDLE # unset the variable so that the analyzer doesn't duplicate the import
```

### Dependency Scanning job fails with message `strconv.ParseUint: parsing "0.0": invalid syntax`

Invoking Docker-in-Docker is the likely cause of this error. Docker-in-Docker is:

- Disabled by default in GitLab 13.0 and later.
- Unsupported from GitLab 13.4 and later.

To fix this error, disable Docker-in-Docker for dependency scanning. Individual
`<analyzer-name>-dependency_scanning` jobs are created for each analyzer that runs in your CI/CD
pipeline.

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

variables:
  DS_DISABLE_DIND: "true"
```

### Message `<file> does not exist in <commit SHA>`

When the `Location` of a dependency in a file is shown, the path in the link goes to a specific Git
SHA.

If the lock file that our dependency scanning tools reviewed was cached, however, selecting that
link redirects you to the repository root, with the message:
`<file> does not exist in <commit SHA>`.

The lock file is cached during the build phase and passed to the dependency scanning job before the
scan occurs. Because the cache is downloaded before the analyzer run occurs, the existence of a lock
file in the `CI_BUILDS_DIR` directory triggers the dependency scanning job.

We recommend committing the lock files, which prevents this warning.

### I no longer get the latest Docker image after setting `DS_MAJOR_VERSION` or `DS_ANALYZER_IMAGE`

If you have manually set `DS_MAJOR_VERSION` or `DS_ANALYZER_IMAGE` for specific reasons,
and now must update your configuration to again get the latest patched versions of our
analyzers, edit your `.gitlab-ci.yml` file and either:

- Set your `DS_MAJOR_VERSION` to match the latest version as seen in
  [our current Dependency Scanning template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml#L18).
- If you hardcoded the `DS_ANALYZER_IMAGE` variable directly, change it to match the latest
  line as found in our [current Dependency Scanning template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml).
  The line number will vary depending on which scanning job you edited.

  For example, currently the `gemnasium-maven-dependency_scanning` job pulls the latest
  `gemnasium-maven` Docker image because `DS_ANALYZER_IMAGE` is set to
  `"$SECURE_ANALYZERS_PREFIX/gemnasium-maven:$DS_MAJOR_VERSION"`.

### Dependency Scanning of setuptools project fails with `use_2to3 is invalid` error

Support for [2to3](https://docs.python.org/3/library/2to3.html)
was [removed](https://setuptools.pypa.io/en/latest/history.html#v58-0-0)
in `setuptools` version `v58.0.0`. Dependency Scanning (running `python 3.9`) uses `setuptools`
version `58.1.0+`, which doesn't support `2to3`. Therefore, a `setuptools` dependency relying on
`lib2to3` will fail with this message:

```plaintext
error in <dependency name> setup command: use_2to3 is invalid
```

To work around this error, downgrade the analyzer's version of `setuptools` (e.g. `v57.5.0`):

```yaml
gemnasium-python-dependency_scanning:
  before_script:
    - pip install setuptools==57.5.0
```

### Dependency Scanning of projects using psycopg2 fails with `pg_config executable not found` error

Scanning a Python project that depends on `psycopg2` can fail with this message:

```plaintext
Error: pg_config executable not found.
```

[psycopg2](https://pypi.org/project/psycopg2/) depends on the `libpq-dev` Debian package,
which is not installed in the `gemnasium-python` Docker image. To work around this error,
install the `libpq-dev` package in a `before_script`:

```yaml
gemnasium-python-dependency_scanning:
  before_script:
    - apt-get update && apt-get install -y libpq-dev
```

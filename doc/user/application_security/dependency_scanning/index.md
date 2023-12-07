---
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

<style>
table.ds-table tr:nth-child(even) {
    background-color: transparent;
}

table.ds-table td {
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.ds-table tr td:first-child {
    border-left: 0;
}

table.ds-table tr td:last-child {
    border-right: 0;
}

table.ds-table ul {
    font-size: 1em;
    list-style-type: none;
    padding-left: 0px;
    margin-bottom: 0px;
}

table.no-vertical-table-lines td {
    border-left: none;
    border-right: none;
    border-bottom: 1px solid #f0f0f0;
}

table.no-vertical-table-lines tr {
    border-top: none;
}
</style>

# Dependency Scanning **(ULTIMATE ALL)**

Dependency Scanning analyzes your application's dependencies for known vulnerabilities. All
dependencies are scanned, including transitive dependencies, also known as nested dependencies.

Dependency Scanning is often considered part of Software Composition Analysis (SCA). SCA can contain
aspects of inspecting the items your code uses. These items typically include application and system
dependencies that are almost always imported from external sources, rather than sourced from items
you wrote yourself.

Dependency Scanning can run in the development phase of your application's life cycle. Every time a
pipeline runs, vulnerabilities are identified and compared between the source and target branches.
Vulnerabilities and their severity are listed in the merge request, enabling you to proactively
address the risk to your application, before the code change is committed.
Vulnerabilities can also be identified outside a pipeline by
[Continuous Vulnerability Scanning](../continuous_vulnerability_scanning/index.md).

GitLab offers both Dependency Scanning and [Container Scanning](../container_scanning/index.md) to
ensure coverage for all of these dependency types. To cover as much of your risk area as possible,
we encourage you to use all of our security scanners. For a comparison of these features, see
[Dependency Scanning compared to Container Scanning](../comparison_dependency_and_container_scanning.md).

![Dependency scanning Widget](img/dependency_scanning_v13_2.png)

WARNING:
Dependency Scanning does not support runtime installation of compilers and interpreters.

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Dependency Scanning](https://www.youtube.com/watch?v=TBnfbGk4c4o)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an interactive reading and how-to demo of this Dependency Scanning documentation, see [How to use dependency scanning tutorial hands-on GitLab Application Security part 3](https://youtu.be/ii05cMbJ4xQ?feature=shared)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For other interactive reading and how-to demos, see [Get Started With GitLab Application Security Playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)

## Supported languages and package managers

The following languages and dependency managers are supported:

<!-- markdownlint-disable MD044 -->
<table class="ds-table">
  <thead>
    <tr>
      <th>Language</th>
      <th>Language versions</th>
      <th>Package manager</th>
      <th>Supported files</th>
      <th><a href="#how-multiple-files-are-processed">Processes multiple files?</a></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>.NET</td>
      <td rowspan="2">All versions</td>
      <td rowspan="2"><a href="https://www.nuget.org/">NuGet</a></td>
      <td rowspan="2"><a href="https://learn.microsoft.com/en-us/nuget/consume-packages/package-references-in-project-files#enabling-lock-file"><code>packages.lock.json</code></a></td>
      <td rowspan="2">Y</td>
    </tr>
    <tr>
      <td>C#</td>
    </tr>
    <tr>
      <td>C</td>
      <td rowspan="2">All versions</td>
      <td rowspan="2"><a href="https://conan.io/">Conan</a></td>
      <td rowspan="2"><a href="https://docs.conan.io/en/latest/versioning/lockfiles.html"><code>conan.lock</code></a></td>
      <td rowspan="2">Y</td>
    </tr>
    <tr>
      <td>C++</td>
    </tr>
    <tr>
      <td>Go</td>
      <td>All versions</td>
      <td><a href="https://go.dev/">Go</a></td>
      <td>
        <ul>
          <li><code>go.mod</code></li>
          <li><code>go.sum</code></li>
        </ul>
      </td>
      <td>Y</td>
    </tr>
    <tr>
      <td rowspan="2">Java and Kotlin (not Android)<sup><b><a href="#notes-regarding-supported-languages-and-package-managers-1">1</a></b></sup></td>
      <td rowspan="2">
        8 LTS,
        11 LTS,
        17 LTS,
        or 21 LTS<sup><b><a href="#notes-regarding-supported-languages-and-package-managers-2">2</a></b></sup>
      </td>
      <td><a href="https://gradle.org/">Gradle</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-3">3</a></b></sup></td>
      <td>
        <ul>
            <li><code>build.gradle</code></li>
            <li><code>build.gradle.kts</code></li>
        </ul>
      </td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a></td>
      <td><code>pom.xml</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td rowspan="3">JavaScript and TypeScript</td>
      <td rowspan="3">All versions</td>
      <td><a href="https://www.npmjs.com/">npm</a></td>
      <td>
        <ul>
            <li><code>package-lock.json</code></li>
            <li><code>npm-shrinkwrap.json</code></li>
        </ul>
      </td>
      <td>Y</td>
    </tr>
    <tr>
      <td><a href="https://classic.yarnpkg.com/en/">yarn</a></td>
      <td><code>yarn.lock</code></td>
      <td>Y</td>
    </tr>
    <tr>
      <td><a href="https://pnpm.io/">pnpm</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-4">4</a></b></sup></td>
      <td><code>pnpm-lock.yaml</code></td>
      <td>Y</td>
    </tr>
    <tr>
      <td>PHP</td>
      <td>All versions</td>
      <td><a href="https://getcomposer.org/">Composer</a></td>
      <td><code>composer.lock</code></td>
      <td>Y</td>
    </tr>
    <tr>
      <td rowspan="4">Python</td>
      <td rowspan="4">3.9, 3.10<sup><b><a href="#notes-regarding-supported-languages-and-package-managers-5">5</a></b></sup></td>
      <td><a href="https://setuptools.readthedocs.io/en/latest/">setuptools</a></td>
      <td><code>setup.py</code></td>
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
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://pipenv.pypa.io/en/latest/">Pipenv</a></td>
      <td>
        <ul>
            <li><a href="https://pipenv.pypa.io/en/latest/pipfile/#example-pipfile"><code>Pipfile</code></a></li>
            <li><a href="https://pipenv.pypa.io/en/latest/pipfile/#example-pipfile-lock"><code>Pipfile.lock</code></a></li>
        </ul>
      </td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://python-poetry.org/">Poetry</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-6">6</a></b></sup></td>
      <td><code>poetry.lock</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td>Ruby</td>
      <td>All versions</td>
      <td><a href="https://bundler.io/">Bundler</a></td>
      <td>
        <ul>
            <li><code>Gemfile.lock</code></li>
            <li><code>gems.locked</code></li>
        </ul>
      </td>
      <td>Y</td>
    </tr>
    <tr>
      <td>Scala</td>
      <td>All versions</td>
      <td><a href="https://www.scala-sbt.org/">sbt</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-7">7</a></b></sup></td>
      <td><code>build.sbt</code></td>
      <td>N</td>
    </tr>
  </tbody>
</table>

<ol>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-1"></a>
    <p>
      Support for Kotlin projects for Android is tracked in <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/336866">issue 336866</a>.
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-2"></a>
    <p>
      Java 21 LTS for <a href="https://www.scala-sbt.org/">sbt</a> is limited to version 1.9.7. Support for more <a href="https://www.scala-sbt.org/">sbt</a> versions can be tracked in <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/430335">issue 430335</a>.
      It is not supported when <a href="https://docs.gitlab.com/ee/development/fips_compliance.html#enable-fips-mode">FIPS mode</a> is enabled.
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-3"></a>
    <p>
      Gradle is not supported when <a href="https://docs.gitlab.com/ee/development/fips_compliance.html#enable-fips-mode">FIPS mode</a> is enabled.
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-4"></a>
    <p>
      Support for <code>pnpm</code> lockfiles was <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/336809">introduced in GitLab 15.11</a>. <code>pnpm</code> lockfiles do not store bundled dependencies, so the reported dependencies may differ from <code>npm</code> or <code>yarn</code>.
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-5"></a>
    <p>
      For support of <code>Python 3.10</code>, add the following stanza to the GitLab CI/CD configuration file. This specifies that the <code>Python 3.10</code> image is to be used, instead of the default <code>Python 3.9</code>.
      <div class="language-yaml highlighter-rouge">
        <div class="highlight">
<pre class="highlight"><code><span class="na">gemnasium-dependency_scanning</span><span class="pi">:</span>
  <span class="na">image</span><span class="pi">:</span>
    <span class="na">name</span><span class="pi">:</span> <span class="s">$CI_TEMPLATE_REGISTRY_HOST/security-products/gemnasium-python:4-python-3.10</span></code></pre></div></div>
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-6"></a>
    <p>
      Support for <a href="https://python-poetry.org/">Poetry</a> projects with a <code>poetry.lock</code> file was <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/7006">added in GitLab 15.0</a>.
      Support for projects without a <code>poetry.lock</code> file is tracked in issue:
      <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/32774">Poetry's pyproject.toml support for dependency scanning.</a>
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-7"></a>
    <p>
      Support for <a href="https://www.scala-sbt.org/">sbt</a> 1.3 and above was added in GitLab 13.9.
    </p>
  </li>
</ol>
<!-- markdownlint-enable MD044 -->

## Dependency detection

Dependency Scanning automatically detects the languages used in the repository. All analyzers
matching the detected languages are run. There is usually no need to customize the selection of
analyzers. We recommend not specifying the analyzers so you automatically use the full selection for
best coverage, avoiding the need to make adjustments when there are deprecations or removals.
However, you can override the selection using the variable `DS_EXCLUDED_ANALYZERS`.

The language detection relies on CI job [`rules`](../../../ci/yaml/index.md#rules) and searches a
maximum of two directory levels from the repository's root. For example, the
`gemnasium-dependency_scanning` job is enabled if a repository contains either `Gemfile`,
`api/Gemfile`, or `api/client/Gemfile`, but not if the only supported dependency file is
`api/v1/client/Gemfile`.

For Java and Python, when a supported dependency file is detected, Dependency Scanning attempts to
build the project and execute some Java or Python commands to get the list of dependencies. For all
other projects, the lock file is parsed to obtain the list of dependencies without needing to build
the project first.

When a supported dependency file is detected, all dependencies, including transitive dependencies
are analyzed. There is no limit to the depth of nested or transitive dependencies that are analyzed.

### Dependency analyzers

Dependency Scanning supports the following official analyzers:

- `gemnasium`
- `gemnasium-maven`
- `gemnasium-python`

Each of these supported Gemnasium-based Dependency Scanning analyzers exist in the following project:

- [`gemnasium`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)

The analyzers are published as Docker images, which Dependency Scanning uses
to launch dedicated containers for each analysis. You can also integrate a custom
[security scanner](../../../development/integrations/secure.md).

### How analyzers obtain dependency information

GitLab analyzers obtain dependency information using one of the following two methods:

1. [Parsing lockfiles directly.](#obtaining-dependency-information-by-parsing-lockfiles)
1. [Running a package manager or build tool to generate a dependency information file which is then parsed.](#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)

#### Obtaining dependency information by parsing lockfiles

The following package managers use lockfiles that GitLab analyzers are capable of parsing directly:

<!-- markdownlint-disable MD044 -->
<table class="ds-table no-vertical-table-lines">
  <thead>
    <tr>
      <th>Package Manager</th>
      <th>Supported File Format Versions</th>
      <th>Tested Package Manager Versions</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Bundler</td>
      <td>Not applicable</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/ruby-bundler/default/Gemfile.lock#L118">1.17.3</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/tests/ruby-bundler/-/blob/bundler2-FREEZE/Gemfile.lock#L118">2.1.4</a>
      </td>
    </tr>
    <tr>
      <td>Composer</td>
      <td>Not applicable</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/php-composer/default/composer.lock">1.x</a>
      </td>
    </tr>
    <tr>
      <td>Conan</td>
      <td>0.4</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/c-conan/default/conan.lock#L38">1.x</a>
      </td>
    </tr>
    <tr>
      <td>Go</td>
      <td>Not applicable</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/go-modules/gosum/default/go.sum">1.x</a><sup><b><a href="#notes-regarding-parsing-lockfiles-1">1</a></b></sup>
      </td>
    </tr>
    <tr>
      <td>NuGet</td>
      <td>v1, v2<sup><b><a href="#notes-regarding-parsing-lockfiles-2">2</a></b></sup></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/csharp-nuget-dotnetcore/default/src/web.api/packages.lock.json#L2">4.9</a>
      </td>
    </tr>
    <tr>
      <td>npm</td>
      <td>v1, v2, v3<sup><b><a href="#notes-regarding-parsing-lockfiles-3">3</a></b></sup></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-npm/default/package-lock.json#L4">6.x</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-npm/lockfileVersion2/package-lock.json#L4">7.x</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/npm/fixtures/lockfile-v3/simple/package-lock.json#L4">9.x</a>
      </td>
    </tr>
    <tr>
      <td>pnpm</td>
      <td>v5, v6</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-pnpm/default/pnpm-lock.yaml#L1">7.x</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/pnpm/fixtures/v6/simple/pnpm-lock.yaml#L1">8.x</a>
      </td>
    </tr>
    <tr>
      <td>yarn</td>
      <td>v1, v2<sup><b><a href="#notes-regarding-parsing-lockfiles-4">4</a></b></sup>, v3<sup><b><a href="#notes-regarding-parsing-lockfiles-4">4</a></b></sup></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/classic/default/yarn.lock#L2">1.x</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/berry/v2/default/yarn.lock">2.x</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/berry/v3/default/yarn.lock">3.x</a>
      </td>
    </tr>
    <tr>
      <td>Poetry</td>
      <td>v1</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/python-poetry/default/poetry.lock">1.x</a>
      </td>
    </tr>
  </tbody>
</table>

<ol>
  <li>
    <a id="notes-regarding-parsing-lockfiles-1"></a>
    <p>
      Dependency Scanning only parses <code>go.sum</code> if it's unable to generate the build list
      used by the Go project.
    </p>
  </li>
  <li>
    <a id="notes-regarding-parsing-lockfiles-2"></a>
    <p>
      Support for NuGet version 2 lock files was <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/398680">introduced</a> in GitLab 16.2.
    </p>
  </li>
  <li>
    <a id="notes-regarding-parsing-lockfiles-3"></a>
    <p>
      Support for <code>lockfileVersion = 3</code> was <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/365176">introduced</a> in GitLab 15.7.
    </p>
  </li>
  <li>
    <a id="notes-regarding-parsing-lockfiles-4"></a>
    <p>
      Support for Yarn <code>v2</code> and <code>v3</code> was <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/263358">introduced in GitLab 15.11</a>. However, this feature is also available to versions of GitLab 15.0 and later.
    </p>
    <p>
      The following features are not supported for Yarn <code>v2</code> or <code>v3</code>:
    </p>
    <ul>
      <li>
        <a href="https://yarnpkg.com/features/workspaces">workspaces</a>
      </li>
      <li>
        <a href="https://yarnpkg.com/cli/patch">yarn patch</a>
      </li>
    </ul>
    <p>
      Yarn files that contain a patch, a workspace, or both, are still processed, but these features are ignored.
    </p>
  </li>
</ol>
<!-- markdownlint-enable MD044 -->

#### Obtaining dependency information by running a package manager to generate a parsable file

To support the following package managers, the GitLab analyzers proceed in two steps:

1. Execute the package manager or a specific task, to export the dependency information.
1. Parse the exported dependency information.

<!-- markdownlint-disable MD044 -->
<table class="ds-table no-vertical-table-lines">
  <thead>
    <tr>
      <th>Package Manager</th>
      <th>Pre-installed Versions</th>
      <th>Tested Versions</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>sbt</td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/build/gemnasium-maven/debian/config/.tool-versions#L4">1.6.2</a></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L726-730">1.0.4</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L732-736">1.1.6</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L738-742">1.2.8</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L662-666">1.3.12</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L668-672">1.4.6</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L674-678">1.5.8</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L680-694">1.6.2</a>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L696-700">1.7.3</a>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L702-706">1.8.3</a>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L708-713">1.9.6</a>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/.gitlab/ci/gemnasium-maven.gitlab-ci.yml#L109-119">1.9.7</a>
      </td>
    </tr>
    <tr>
      <td>maven</td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/build/gemnasium-maven/debian/config/.tool-versions#L3">3.6.3</a></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L83-85">3.6.3</a><sup><b><a href="#exported-dependency-information-notes-1">1</a></b></sup>
      </td>
    </tr>
    <tr>
      <td>Gradle</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/build/gemnasium-maven/debian/config/.tool-versions#L5">6.7.1</a><sup><b><a href="#exported-dependency-information-notes-2">2</a></b></sup>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/build/gemnasium-maven/debian/config/.tool-versions#L5">7.3.3</a><sup><b><a href="#exported-dependency-information-notes-2">2</a></b></sup>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L285-290">5.6.4</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L292-297">6.7</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L299-304">6.9</a>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L306-310">7.3</a>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/spec/gemnasium-maven_image_spec.rb#L312-316">8.4</a>
      </td>
    </tr>
    <tr>
      <td>setuptools</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v3.10.6/build/gemnasium-python/debian/Dockerfile#L17">58.1.0</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v3.10.6/spec/gemnasium-python_image_spec.rb#L249-271">&gt;= 65.6.3</a>
      </td>
    </tr>
    <tr>
      <td>pip</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v3.10.6/build/gemnasium-python/debian/Dockerfile#L17">22.0.4</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v3.0.2/spec/gemnasium-python_image_spec.rb#L88-102">20.x</a>
      </td>
    </tr>
    <tr>
      <td>Pipenv</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v3.10.6/build/gemnasium-python/requirements.txt#L13">2022.1.8</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v3.0.2/spec/gemnasium-python_image_spec.rb#L186-210">2022.1.8</a><sup><b><a href="#exported-dependency-information-notes-3">3</a></b></sup>,
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v3.0.2/spec/gemnasium-python_image_spec.rb#L161-183">2022.1.8</a>
      </td>
    </tr>
    <tr>
      <td>Go</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v3.10.6/build/gemnasium/alpine/Dockerfile#L88-91">1.18</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v3.10.6/build/gemnasium/alpine/Dockerfile#L88-91">1.18</a><sup><strong><a href="#exported-dependency-information-notes-4">4</a></strong></sup>
      </td>
    </tr>
  </tbody>
</table>

<ol>
  <li>
    <a id="exported-dependency-information-notes-1"></a>
    <p>
      This test uses the default version of <code>maven</code> specified by the <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v4.9.0/build/gemnasium-maven/debian/config/.tool-versions#L3"><code>.tool-versions</code></a> file.
    </p>
  </li>
  <li>
    <a id="exported-dependency-information-notes-2"></a>
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
          <a href="#analyzer-specific-settings"><code>DS_JAVA_VERSION</code></a> variable.
          By default, the analyzer uses Java 17 and Gradle 7.3.3.
        </p>
        <p>
          For Java versions <code>8</code> and <code>11</code>, Gradle <code>6.7.1</code> is automatically selected, and for Java version <code>17</code>, Gradle <code>7.3.3</code> is automatically selected.
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
    <a id="exported-dependency-information-notes-3"></a>
    <p>
      This test confirms that if a <code>Pipfile.lock</code> file is found, it is used by <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a> to scan the exact package versions listed in this file.
    </p>
  </li>
  <li>
    <a id="exported-dependency-information-notes-4"></a>
    <p>
      Because of the implementation of <code>go build</code>, the Go build process requires network access, a pre-loaded mod cache via <code>go mod download</code>, or vendored dependencies. For more information,
      refer to the Go documentation on <a href="https://pkg.go.dev/cmd/go#hdr-Compile_packages_and_dependencies">compiling packages and dependencies</a>.
    </p>
  </li>
</ol>
<!-- markdownlint-enable MD044 -->

### How analyzers are triggered

GitLab relies on [`rules:exists`](../../../ci/yaml/index.md#rulesexists) to start the relevant analyzers for the languages detected by the presence of the
`Supported files` in the repository as shown in the [table above](#supported-languages-and-package-managers).

The current detection logic limits the maximum search depth to two levels. For example, the `gemnasium-dependency_scanning` job is enabled if
a repository contains either a `Gemfile.lock`, `api/Gemfile.lock`, or `api/client/Gemfile.lock`, but not if the only supported dependency file is `api/v1/client/Gemfile.lock`.

When a supported dependency file is detected, all dependencies, including transitive dependencies are analyzed. There is no limit to the depth of nested or transitive dependencies that are analyzed.

### How multiple files are processed

NOTE:
If you've run into problems while scanning multiple files, contribute a comment to
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

1. `pom.xml` for single or [multi-module](https://maven.apache.org/pom.html#Aggregation) Maven projects.
1. `build.gradle` or `build.gradle.kts` for single or [multi-project](https://docs.gradle.org/current/userguide/intro_multi_project_builds.html) Gradle builds.
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

#### Go

Multiple files are supported. When a `go.mod` file is detected, the analyzer attempts to generate a [build list](https://go.dev/ref/mod#glos-build-list) using
[Minimal Version Selection](https://go.dev/ref/mod#glos-minimal-version-selection). If a non-fatal error is encountered, the analyzer falls back to parsing the
available `go.sum` file. The process is repeated for every detected `go.mod` and `go.sum` file.

#### PHP, C, C++, .NET, C&#35;, Ruby, JavaScript

The analyzer for these languages supports multiple lockfiles.

#### Support for additional languages

Support for additional languages, dependency managers, and dependency files are tracked in the following issues:

| Package Managers    | Languages | Supported files | Scan tools | Issue |
| ------------------- | --------- | --------------- | ---------- | ----- |
| [Poetry](https://python-poetry.org/) | Python | `pyproject.toml` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) | [GitLab#32774](https://gitlab.com/gitlab-org/gitlab/-/issues/32774) |

## Contribute your scanner

The [Security Scanner Integration](../../../development/integrations/secure.md) documentation explains how to integrate other security scanners into GitLab.

## Configuration

Enable the dependency scanning analyzer to ensure it scans your application's dependencies for known
vulnerabilities. You can then adjust its behavior by using CI/CD variables.

### Enabling the analyzer

Prerequisites:

- The `test` stage is required in the `.gitlab-ci.yml` file.
- On GitLab self-managed you need GitLab Runner with the
  [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor. On GitLab.com this
  is enabled by default on the shared runners. The analyzer images provided are for the Linux/amd64
  architecture.

To enable the analyzer, either:

- Enable [Auto DevOps](../../../topics/autodevops/index.md), which includes dependency scanning.
- Edit the `.gitlab-ci.yml` file manually. Use this method if your `.gitlab-ci.yml` file is complex.
- Use a preconfigured merge request.
- Create a [scan execution policy](../policies/scan-execution-policies.md) that enforces dependency
  scanning.

#### Edit the `.gitlab-ci.yml` file manually

This method requires you to manually edit the existing `.gitlab-ci.yml` file. Use this method if
your GitLab CI/CD configuration file is complex.

To enable dependency scanning:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline editor**.
1. Copy and paste the following to the bottom of the `.gitlab-ci.yml` file:

   ```yaml
   include:
     - template: Security/Dependency-Scanning.gitlab-ci.yml
   ```

1. Select the **Validate** tab, then select **Validate pipeline**.

   Continue if you see the message **Simulation completed successfully**. That indicates the file is
   valid.
1. Select the **Edit** tab.
1. Complete the fields. Do not use the default branch for the **Branch** field.
1. Select **Commit changes**.
1. Select **Code > Merge requests**.
1. Select the merge request just created.
1. Review the merge request, then select **Merge**.

Pipelines now include a dependency scanning job.

#### Use a preconfigured merge request

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4908) in GitLab 14.1 [with a flag](../../../administration/feature_flags.md) named `sec_dependency_scanning_ui_enable`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/326005) in GitLab 14.2. Feature flag `sec_dependency_scanning_ui_enable` removed.

This method automatically prepares a merge request that includes the dependency scanning template
in the `.gitlab-ci.yml` file. You then merge the merge request to enable dependency scanning.

NOTE:
This method works best with no existing `.gitlab-ci.yml` file, or with a minimal configuration
file. If you have a complex GitLab configuration file it might not be parsed successfully, and an
error might occur. In that case, use the [manual](#edit-the-gitlab-ciyml-file-manually) method instead.

To enable dependency scanning:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dependency Scanning** row, select **Configure with a merge request**.
1. Select **Create merge request**.
1. Review the merge request, then select **Merge**.

Pipelines now include a dependency scanning job.

### Running jobs in merge request pipelines

See [Use security scanning tools with merge request pipelines](../index.md#use-security-scanning-tools-with-merge-request-pipelines)

### Customizing analyzer behavior

You can use CI/CD variables to customize dependency scanning behavior.

WARNING:
You should test all customization of GitLab security scanning tools in a merge request before
merging these changes to the default branch. Failure to do so can give unexpected results,
including a large number of false positives.

### Overriding dependency scanning jobs

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

You can use CI/CD variables to [customize](#customizing-analyzer-behavior) dependency scanning behavior.

#### Global analyzer settings

The following variables allow configuration of global dependency scanning settings.

| CI/CD variables             | Description |
| ----------------------------|------------ |
| `ADDITIONAL_CA_CERT_BUNDLE` | Bundle of CA certs to trust. The bundle of certificates provided here is also used by other tools during the scanning process, such as `git`, `yarn`, or `npm`. See [Using a custom SSL CA certificate authority](#using-a-custom-ssl-ca-certificate-authority) for more details. |
| `DS_EXCLUDED_ANALYZERS`      | Specify the analyzers (by name) to exclude from Dependency Scanning. For more information, see [Dependency Scanning Analyzers](#dependency-analyzers). |
| `DS_EXCLUDED_PATHS`         | Exclude files and directories from the scan based on the paths. A comma-separated list of patterns. Patterns can be globs (see [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) for supported patterns), or file or folder paths (for example, `doc,spec`). Parent directories also match patterns. Default: `"spec, test, tests, tmp"`. |
| `DS_IMAGE_SUFFIX`           | Suffix added to the image name. (Introduced in GitLab 14.10. GitLab team members can view more information in this confidential issue: `https://gitlab.com/gitlab-org/gitlab/-/issues/354796`). Automatically set to `"-fips"` when FIPS mode is enabled. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/357922) in GitLab 15.0.) |
| `DS_MAX_DEPTH`              | Defines how many directory levels deep that the analyzer should search for supported files to scan. A value of `-1` scans all directories regardless of depth. Default: `2`. |
| `SECURE_ANALYZERS_PREFIX`   | Override the name of the Docker registry providing the official default images (proxy). |

#### Analyzer-specific settings

The following variables configure the behavior of specific dependency scanning analyzers.

| CI/CD variable                       | Analyzer           | Default                      | Description |
|--------------------------------------| ------------------ | ---------------------------- |------------ |
| `GEMNASIUM_DB_LOCAL_PATH`            | `gemnasium`        | `/gemnasium-db`              | Path to local Gemnasium database. |
| `GEMNASIUM_DB_UPDATE_DISABLED`       | `gemnasium`        | `"false"`                    | Disable automatic updates for the `gemnasium-db` advisory database (For usage see: [examples](#hosting-a-copy-of-the-gemnasium_db-advisory-database))|
| `GEMNASIUM_DB_REMOTE_URL`            | `gemnasium`        | `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git` | Repository URL for fetching the Gemnasium database. |
| `GEMNASIUM_DB_REF_NAME`              | `gemnasium`        | `master`                     | Branch name for remote repository database. `GEMNASIUM_DB_REMOTE_URL` is required. |
| `DS_REMEDIATE`                       | `gemnasium`        | `"true"`, `"false"` in FIPS mode | Enable automatic remediation of vulnerable dependencies. Not supported in FIPS mode. |
| `DS_REMEDIATE_TIMEOUT`               | `gemnasium`        | `5m`                       | Timeout for auto-remediation. |
| `GEMNASIUM_LIBRARY_SCAN_ENABLED`     | `gemnasium`        | `"true"`                     | Enable detecting vulnerabilities in vendored JavaScript libraries. For now, `gemnasium` leverages [`Retire.js`](https://github.com/RetireJS/retire.js) to do this job. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350512) in GitLab 14.8. |
| `DS_JAVA_VERSION`                    | `gemnasium-maven`  | `17`                         | Version of Java. Available versions: `8`, `11`, `17`, `21` |
| `MAVEN_CLI_OPTS`                     | `gemnasium-maven`  | `"-DskipTests --batch-mode"` | List of command line arguments that are passed to `maven` by the analyzer. See an example for [using private repositories](../index.md#using-private-maven-repositories). |
| `GRADLE_CLI_OPTS`                    | `gemnasium-maven`  |                              | List of command line arguments that are passed to `gradle` by the analyzer. |
| `SBT_CLI_OPTS`                       | `gemnasium-maven`  |                              | List of command-line arguments that the analyzer passes to `sbt`. |
| `PIP_INDEX_URL`                      | `gemnasium-python` | `https://pypi.org/simple`    | Base URL of Python Package Index. |
| `PIP_EXTRA_INDEX_URL`                | `gemnasium-python` |                              | Array of [extra URLs](https://pip.pypa.io/en/stable/reference/pip_install/#cmdoption-extra-index-url) of package indexes to use in addition to `PIP_INDEX_URL`. Comma-separated. **Warning:** Read [the following security consideration](#python-projects) when using this environment variable. |
| `PIP_REQUIREMENTS_FILE`              | `gemnasium-python` |                              | Pip requirements file to be scanned. |
| `PIPENV_PYPI_MIRROR`                 | `gemnasium-python` |                              | If set, overrides the PyPi index used by Pipenv with a [mirror](https://github.com/pypa/pipenv/blob/v2022.1.8/pipenv/environments.py#L263). |
| `DS_PIP_VERSION`                     | `gemnasium-python` |                              | Force the install of a specific pip version (example: `"19.3"`), otherwise the pip installed in the Docker image is used. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12811) in GitLab 12.7) |
| `DS_PIP_DEPENDENCY_PATH`             | `gemnasium-python` |                              | Path to load Python pip dependencies from. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12412) in GitLab 12.2) |
| `DS_INCLUDE_DEV_DEPENDENCIES`        | `gemnasium`        | `"true"`                     | When set to `"false"`, development dependencies and their vulnerabilities are not reported. Only Composer, NPM, and Poetry projects are supported. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227861) in GitLab 15.1. |
| `GOOS`                               | `gemnasium`        | `"linux"`                    | The operating system for which to compile Go code. |
| `GOARCH`                             | `gemnasium`        | `"amd64"`                    | The architecture of the processor for which to compile Go code. |
| `GOFLAGS`                            | `gemnasium`        |                              | The flags passed to the `go build` tool. |
| `GOPRIVATE`                          | `gemnasium`        |                              | A list of glob patterns and prefixes to be fetched from source. Read the Go private modules [documentation](https://go.dev/ref/mod#private-modules) for more information. |

#### Other variables

The previous tables are not an exhaustive list of all variables that can be used. They contain all specific GitLab and analyzer variables we support and test. There are many variables, such as environment variables, that you can pass in and they do work. This is a large list, many of which we may be unaware of, and as such is not documented.

For example, to pass the non-GitLab environment variable `HTTPS_PROXY` to all Dependency Scanning jobs,
set it as a [CI/CD variable in your `.gitlab-ci.yml`](../../../ci/variables/index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)
file like this:

```yaml
variables:
  HTTPS_PROXY: "https://squid-proxy:3128"
```

NOTE:
Gradle projects require [an additional variable](#using-a-proxy-with-gradle-projects) setup to use a proxy.

Alternatively we may use it in specific jobs, like Dependency Scanning:

```yaml
dependency_scanning:
  variables:
    HTTPS_PROXY: $HTTPS_PROXY
```

As we have not tested all variables you may find some do work and others do not.
If one does not work and you need it we suggest
[submitting a feature request](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Feature%20proposal%20-%20detailed&issue[title]=Docs%20feedback%20-%20feature%20proposal:%20Write%20your%20title)
or [contributing to the code](../../../development/index.md) to enable it to be used.

### Using a custom SSL CA certificate authority

You can use the `ADDITIONAL_CA_CERT_BUNDLE` CI/CD variable to configure a custom SSL CA certificate authority. The `ADDITIONAL_CA_CERT_BUNDLE` value should contain the [text representation of the X.509 PEM public-key certificate](https://www.rfc-editor.org/rfc/rfc7468#section-5.1). For example, to configure this value in the `.gitlab-ci.yml` file, use the following:

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

The `ADDITIONAL_CA_CERT_BUNDLE` value can also be configured as a [custom variable in the UI](../../../ci/variables/index.md#for-a-project), either as a `file`, which requires the path to the certificate, or as a variable, which requires the text representation of the certificate.

### Using private Maven repositories

If your private Maven repository requires login credentials,
you can use the `MAVEN_CLI_OPTS` CI/CD variable.

Read more on [how to use private Maven repositories](../index.md#using-private-maven-repositories).

#### FIPS-enabled images

> Introduced in GitLab 14.10. GitLab team members can view more information in this confidential issue:  `https://gitlab.com/gitlab-org/gitlab/-/issues/354796`

GitLab also offers [FIPS-enabled Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)
versions of the Gemnasium images. You can therefore replace standard images with FIPS-enabled images.

Gemnasium scanning jobs automatically use FIPS-enabled image when FIPS mode is enabled in the GitLab instance.
([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/357922) in GitLab 15.0.)

To manually switch to FIPS-enabled images, set the variable `DS_IMAGE_SUFFIX` to `"-fips"`.

Dependency scanning for Gradle projects and auto-remediation for Yarn projects are not supported in FIPS mode.

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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350509) in GitLab 14.8 in [Beta](../../../policy/experiment-beta-support.md#beta).
> - Generally available in GitLab 15.7.

In addition to the [JSON report file](#reports-json-format), the [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)
Dependency Scanning tool outputs a [CycloneDX](https://cyclonedx.org/) Software Bill of Materials (SBOM) for
each supported lock or build file it detects. These CycloneDX SBOMs are named
`gl-sbom-<package-type>-<package-manager>.cdx.json`, and are saved in the same directory
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
│   └── gl-sbom-gem-bundler.cdx.json
├── ruby-project-2/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
├── php-project/
│   ├── composer.lock
│   └── gl-sbom-packagist-composer.cdx.json
└── go-project/
    ├── go.sum
    └── gl-sbom-go-go.cdx.json
```

You can download CycloneDX SBOMs [the same way as other job artifacts](../../../ci/jobs/job_artifacts.md#download-job-artifacts).

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
  image:
    name: cyclonedx/cyclonedx-cli:0.24.2
    entrypoint: [""]
  script:
    - apt-get update && apt-get install -y jq
    - find . -name "gl-sbom-*.cdx.json" -exec cyclonedx merge --output-file gl-sbom-all.cdx.json --input-files "{}" +
    # remove duplicates from merged file. See https://github.com/CycloneDX/cyclonedx-cli/issues/188 for details.
    - |
      jq '. |
      {
        "bomFormat": .bomFormat,
        "specVersion": .specVersion,
        "serialNumber": .serialNumber,
        "version": .version,
        "metadata": {
          "tools": [
            (.metadata.tools | unique[])
          ]
        },
        "components": [
          (.components | unique[])
        ]
      }' "gl-sbom-all.cdx.json" > gl-sbom-all.cdx.json.tmp && mv gl-sbom-all.cdx.json.tmp gl-sbom-all.cdx.json
    # optional: validate the merged sbom
    - cyclonedx validate --input-version v1_4 --input-file gl-sbom-all.cdx.json
  artifacts:
    paths:
      - gl-sbom-all.cdx.json
```

GitLab uses [CycloneDX Properties](https://cyclonedx.org/use-cases/#properties--name-value-store)
to store implementation-specific details in the metadata of each CycloneDX SBOM,
such as the location of build and lock files. If multiple CycloneDX SBOMs are merged together,
this information is removed from the resulting merged file.

## Versioning and release process

Check the [Release Process documentation](../../../development/sec/analyzer_development_guide.md#versioning-and-release-process).

## Contributing to the vulnerability database

To find a vulnerability, you can search the [`GitLab Advisory Database`](https://advisories.gitlab.com/).
You can also [submit new vulnerabilities](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md).

## Running dependency scanning in an offline environment

For self-managed GitLab instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, some adjustments are required for dependency scanning
jobs to run successfully. For more information, see [Offline environments](../offline_deployments/index.md).

### Requirements for offline dependency scanning

Here are the requirements for using dependency scanning in an offline environment:

- GitLab Runner with the `docker` or `kubernetes` executor.
- Docker container registry with locally available copies of dependency scanning [analyzer](https://gitlab.com/gitlab-org/security-products/analyzers) images.
- If you have a limited access environment you need to allow access, such as using a proxy, to the advisory database: `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git`.
  If you are unable to permit access to `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git` you must host an offline copy of this `git` repository and set the `GEMNASIUM_DB_REMOTE_URL` CI/CD variable to the URL of this repository. For more information on configuration variables, see [Customizing analyzer behavior](#customizing-analyzer-behavior).

  This advisory database is constantly being updated, so you must periodically sync your local copy with GitLab.

GitLab Runner has a [default `pull policy` of `always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy),
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
registry.gitlab.com/security-products/gemnasium:4
registry.gitlab.com/security-products/gemnasium-maven:4
registry.gitlab.com/security-products/gemnasium-python:4
```

The process for importing Docker images into a local offline Docker registry depends on
**your network security policy**. Consult your IT staff to find an accepted and approved
process by which external resources can be imported or temporarily accessed.
These scanners are [periodically updated](../index.md#vulnerability-scanner-maintenance)
with new definitions, and you may be able to make occasional updates on your own.

For details on saving and transporting Docker images as a file, see the Docker documentation on
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

See explanations of the previous variables in the [configuration section](#customizing-analyzer-behavior).

### Hosting a copy of the `gemnasium_db` advisory database

The [`gemnasium_db`](https://gitlab.com/gitlab-org/security-products/gemnasium-db) Git repository is
used by `gemnasium`, `gemnasium-maven`, and `gemnasium-python` as the source of vulnerability data.
This repository updates at scan time to fetch the latest advisories. However, due to a restricted
networking environment, running this update is sometimes not possible. In this case, a user can do
one of the following:

- [Host a copy of the advisory database](#host-a-copy-of-the-advisory-database)
- [Use a local clone](#use-a-local-clone)

#### Host a copy of the advisory database

If [gemnasium-db](https://gitlab.com/gitlab-org/security-products/gemnasium-db) is not reachable
from within the environment, the user can host their own Git copy. Then the analyzer can be
instructed to update the database from the user's copy by using `GEMNASIUM_DB_REMOTE_URL`:

```yaml
variables:
  GEMNASIUM_DB_REMOTE_URL: https://users-own-copy.example.com/gemnasium-db/.git

...
```

#### Use a local clone

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

## Using a proxy with Gradle projects

The Gradle wrapper script does not read the `HTTP(S)_PROXY` environment variables. See [this upstream issue](https://github.com/gradle/gradle/issues/11065).

To make the Gradle wrapper script use a proxy, you can specify the options using the `GRADLE_CLI_OPTS` CI/CD variable:

```yaml
variables:
  GRADLE_CLI_OPTS: "-Dhttps.proxyHost=squid-proxy -Dhttps.proxyPort=3128 -Dhttp.proxyHost=squid-proxy -Dhttp.proxyPort=3128 -Dhttp.nonProxyHosts=localhost"
```

## Using a proxy with Maven projects

Maven does not read the `HTTP(S)_PROXY` environment variables.

To make the Maven dependency scanner use a proxy, you can specify the options using the `MAVEN_CLI_OPTS` CI/CD variable:

```yaml
variables:
  MAVEN_CLI_OPTS: "-DproxySet=true -Dhttps.proxyHost=squid-proxy -Dhttps.proxyPort=3128 -Dhttp.proxyHost=squid-proxy -Dhttp.proxyPort=3218"
```

## Specific settings for languages and package managers

See the following sections for configuring specific languages and package managers.

### Python (pip)

If you need to install Python packages before the analyzer runs, you should use `pip install --user` in the `before_script` of the scanning job. The `--user` flag causes project dependencies to be installed in the user directory. If you do not pass the `--user` option, packages are installed globally, and they are not scanned and don't show up when listing project dependencies.

### Python (setuptools)

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
   printf "\n" | openssl s_client -connect pypi.example.com:443 -servername pypi.example.com | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > internal.crt
   ```

1. Point `setup.py` at the newly downloaded certificate:

   ```python
   import setuptools.ssl_support
   setuptools.ssl_support.cert_paths = ['internal.crt']
   ```

### Python (Pipenv)

If running in a limited network connectivity environment, you must configure the `PIPENV_PYPI_MIRROR`
variable to use a private PyPi mirror. This mirror must contain both default and development dependencies.

```yaml
variables:
  PIPENV_PYPI_MIRROR: https://pypi.example.com/simple
```

<!-- markdownlint-disable MD044 -->
Alternatively, if it's not possible to use a private registry, you can load the required packages
into the Pipenv virtual environment cache. For this option, the project must check in the
`Pipfile.lock` into the repository, and load both default and development packages into the cache.
See the example [python-pipenv](https://gitlab.com/gitlab-org/security-products/tests/python-pipenv/-/blob/41cc017bd1ed302f6edebcfa3bc2922f428e07b6/.gitlab-ci.yml#L20-42)
project for an example of how this can be done.
<!-- markdownlint-enable MD044 -->

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

### Debug-level logging

Debug-level logging can help when troubleshooting. For details, see
[debug-level logging](../index.md#debug-level-logging).

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

For information on this, see the [general Application Security troubleshooting section](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload).

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

### You no longer get the latest Docker image after setting `DS_MAJOR_VERSION` or `DS_ANALYZER_IMAGE`

If you have manually set `DS_MAJOR_VERSION` or `DS_ANALYZER_IMAGE` for specific reasons,
and now must update your configuration to again get the latest patched versions of our
analyzers, edit your `.gitlab-ci.yml` file and either:

- Set your `DS_MAJOR_VERSION` to match the latest version as seen in
  [our current Dependency Scanning template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml#L18).
- If you hardcoded the `DS_ANALYZER_IMAGE` variable directly, change it to match the latest
  line as found in our [current Dependency Scanning template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml).
  The line number varies depending on which scanning job you edited.

  For example, currently the `gemnasium-maven-dependency_scanning` job pulls the latest
  `gemnasium-maven` Docker image because `DS_ANALYZER_IMAGE` is set to
  `"$SECURE_ANALYZERS_PREFIX/gemnasium-maven:$DS_MAJOR_VERSION"`.

### Dependency Scanning of setuptools project fails with `use_2to3 is invalid` error

Support for [2to3](https://docs.python.org/3/library/2to3.html)
was [removed](https://setuptools.pypa.io/en/latest/history.html#v58-0-0)
in `setuptools` version `v58.0.0`. Dependency Scanning (running `python 3.9`) uses `setuptools`
version `58.1.0+`, which doesn't support `2to3`. Therefore, a `setuptools` dependency relying on
`lib2to3` fails with this message:

```plaintext
error in <dependency name> setup command: use_2to3 is invalid
```

To work around this error, downgrade the analyzer's version of `setuptools` (for example, `v57.5.0`):

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

### `NoSuchOptionException` when using `poetry config http-basic` with `CI_JOB_TOKEN`

This error can occur when the automatically generated `CI_JOB_TOKEN` starts with a hyphen (`-`).
To avoid this error, follow [Poetry's configuration advice](https://python-poetry.org/docs/repositories/#configuring-credentials).

### Error: Project has `<number>` unresolved dependencies

The error message `Project has <number> unresolved dependencies` indicates a dependency resolution problem caused by your `gradle.build` or `gradle.build.kts` file. In the current release, `gemnasium-maven` cannot continue processing when an unresolved dependency is encountered. However, There is an [open issue](https://gitlab.com/gitlab-org/gitlab/-/issues/337083) to allow `gemnasium-maven` to recover from unresolved dependency errors and produce a dependency graph. Until this issue has been resolved, consult the [Gradle dependency resolution docs](https://docs.gradle.org/current/userguide/dependency_resolution.html) for details on how to fix your `gradle.build` file.

### Setting build constraints when scanning Go projects

Dependency scanning runs within a `linux/amd64` container. As a result, the build list generated
for a Go project contains dependencies that are compatible with this environment. If your deployment environment is not
`linux/amd64`, the final list of dependencies might contain additional incompatible
modules. The dependency list might also omit modules that are only compatible with your deployment environment. To prevent
this issue, you can configure the build process to target the operating system and architecture of the deployment
environment by setting the `GOOS` and `GOARCH` [environment variables](https://go.dev/ref/mod#minimal-version-selection)
of your `.gitlab-ci.yml` file.

For example:

```yaml
variables:
  GOOS: "darwin"
  GOARCH: "arm64"
```

You can also supply build tag constraints by using the `GOFLAGS` variable:

```yaml
variables:
  GOFLAGS: "-tags=test_feature"
```

### Dependency Scanning of Go projects returns false positives

The `go.sum` file contains an entry of every module that was considered while generating the project's [build list](https://go.dev/ref/mod#glos-build-list).
Multiple versions of a module are included in the `go.sum` file, but the [MVS](https://go.dev/ref/mod#minimal-version-selection)
algorithm used by `go build` only selects one. As a result, when dependency scanning uses `go.sum`, it might report false positives.

To prevent false positives, Gemnasium only uses `go.sum` if it is unable to generate the build list for the Go project. If `go.sum` is selected, a warning occurs:

```shell
[WARN] [Gemnasium] [2022-09-14T20:59:38Z] ▶ Selecting "go.sum" parser for "/test-projects/gitlab-shell/go.sum". False positives may occur. See https://gitlab.com/gitlab-org/gitlab/-/issues/321081.
```

---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting dependency scanning
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When working with dependency scanning, you might encounter the following issues.

## Debug-level logging

Debug-level logging can help when troubleshooting. For details, see
[debug-level logging](../troubleshooting_application_security.md#debug-level-logging).

## Run the analyzer in a local environment

You can run a dependency scanning analyzer locally to debug issues or verify behavior without running a pipeline.

For example, to run the Python analyzer:

```shell
cd project-git-repository

docker run \
   --interactive --tty --rm \
   --volume "$PWD":/tmp/app \
   --env CI_PROJECT_DIR=/tmp/app \
   --env SECURE_LOG_LEVEL=debug \
   -w /tmp/app \
   registry.gitlab.com/security-products/gemnasium-python:5 /analyzer run
```

This command runs the analyzer with debug-level logging and mounts your local repository to analyze the dependencies.
You can replace `registry.gitlab.com/security-products/gemnasium-python:5` with the appropriate scanner `image:tag` combination for your project's language and dependency manager.

### Working around missing support for certain languages or package managers

As noted in the [Supported languages](_index.md#supported-languages-and-package-managers) some
dependency definition files are not yet supported. However, dependency scanning can be achieved if
the language, a package manager, or a third-party tool can convert the definition file into a
supported format.

Generally, the approach is the following:

1. Define a dedicated converter job in your `.gitlab-ci.yml` file.
   Use a suitable Docker image, script, or both to facilitate the conversion.
1. Let that job upload the converted, supported file as an artifact.
1. Add [`dependencies: [<your-converter-job>]`](../../../ci/yaml/_index.md#dependencies)
   to your `dependency_scanning` job to make use of the converted definitions files.

For example, Poetry projects that only have a `pyproject.toml`
file can generate the `poetry.lock` file as follows.

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

stages:
  - test

gemnasium-python-dependency_scanning:
  # Work around https://gitlab.com/gitlab-org/gitlab/-/issues/32774
  before_script:
    - pip install "poetry>=1,<2"  # Or via another method: https://python-poetry.org/docs/#installation
    - poetry update --lock # Generates the lock file to be analyzed.
```

## Dependency scanning jobs are running unexpectedly

The [dependency scanning CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml)
uses the [`rules:exists`](../../../ci/yaml/_index.md#rulesexists)
syntax. This directive is limited to 10000 checks and always returns `true` after reaching this
number. Because of this, and depending on the number of files in your repository, a dependency
scanning job might be triggered even if the scanner doesn't support your project. For more details about this limitation, see the [`rules:exists` documentation](../../../ci/yaml/_index.md#rulesexists).

## Error: `dependency_scanning is used for configuration only, and its script should not be executed`

For information, see [application security testing troubleshooting](../troubleshooting_application_security.md#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed).

## Import multiple certificates for Java-based projects

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

## Dependency scanning job fails with message `strconv.ParseUint: parsing "0.0": invalid syntax`

Docker-in-Docker is unsupported, and attempting to invoke it is the likely cause of this error.

To fix this error, disable Docker-in-Docker for dependency scanning. Individual
`<analyzer-name>-dependency_scanning` jobs are created for each analyzer that runs in your CI/CD
pipeline.

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

variables:
  DS_DISABLE_DIND: "true"
```

## Message `<file> does not exist in <commit SHA>`

When the `Location` of a dependency in a file is shown, the path in the link goes to a specific Git
SHA.

If the lock file that our dependency scanning tools reviewed was cached, however, selecting that
link redirects you to the repository root, with the message:
`<file> does not exist in <commit SHA>`.

The lock file is cached during the build phase and passed to the dependency scanning job before the
scan occurs. Because the cache is downloaded before the analyzer run occurs, the existence of a lock
file in the `CI_BUILDS_DIR` directory triggers the dependency scanning job.

To prevent this warning, lock files should be committed.

## You no longer get the latest Docker image after setting `DS_MAJOR_VERSION` or `DS_ANALYZER_IMAGE`

If you have manually set `DS_MAJOR_VERSION` or `DS_ANALYZER_IMAGE` for specific reasons,
and now must update your configuration to again get the latest patched versions of our
analyzers, edit your `.gitlab-ci.yml` file and either:

- Set the `DS_MAJOR_VERSION` to match the version referenced in the
  [Dependency Scanning template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml#L17).
- If you hardcoded the `DS_ANALYZER_IMAGE` variable directly, change it to match the latest
  line as found in the [dependency scanning template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml).
  The line number varies depending on which scanning job you edited.

  For example, the `gemnasium-maven-dependency_scanning` job pulls the latest
  `gemnasium-maven` Docker image because `DS_ANALYZER_IMAGE` is set to
  `"$SECURE_ANALYZERS_PREFIX/gemnasium-maven:$DS_MAJOR_VERSION"`.

## Dependency scanning of setuptools project fails with `use_2to3 is invalid` error

Support for [2to3](https://docs.python.org/3/library/2to3.html)
was [removed](https://setuptools.pypa.io/en/latest/history.html#v58-0-0)
in `setuptools` version `v58.0.0`. Dependency scanning (running `python 3.9`) uses `setuptools`
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

## Dependency scanning of projects using psycopg2 fails with `pg_config executable not found` error

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

## `NoSuchOptionException` when using `poetry config http-basic` with `CI_JOB_TOKEN`

This error can occur when the automatically generated `CI_JOB_TOKEN` starts with a hyphen (`-`).
To avoid this error, follow [Poetry's configuration advice](https://python-poetry.org/docs/repositories/#configuring-credentials).

## Error: project has unresolved dependencies

The following error messages indicate a Gradle dependency resolution issue
caused by your `build.gradle` or `build.gradle.kts` file:

- `Project has <number> unresolved dependencies` (GitLab 16.7 to 16.9)
- `project has unresolved dependencies: ["dependency_name:version"]` (GitLab 17.0 and later)

In GitLab 16.7 to 16.9, `gemnasium-maven` cannot continue processing when an unresolved dependency is encountered.

In GitLab 17.0 and later, `gemnasium-maven` supports the `DS_GRADLE_RESOLUTION_POLICY` environment variable which you can use to control how unresolved dependencies are handled. By default, the scan fails when unresolved dependencies are encountered. However, you can set the environment variable `DS_GRADLE_RESOLUTION_POLICY` to `"none"` to allow the scan to continue and produce partial results.

Consult the [Gradle dependency resolution documentation](https://docs.gradle.org/current/userguide/dependency_resolution.html) for guidance on
fixing your `build.gradle` file. For more details, refer to [issue 482650](https://gitlab.com/gitlab-org/gitlab/-/issues/482650).

Additionally, there is a known issue in Kotlin 2.0.0 affecting dependency resolution, which is scheduled to be fixed in Kotlin 2.0.20.
For more information, refer to [this issue](https://github.com/gradle/github-dependency-graph-gradle-plugin/issues/140#issuecomment-2230255380).

## Setting build constraints when scanning Go projects

Dependency scanning runs in a `linux/amd64` container. As a result, the build list generated
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

## Dependency scanning of Go projects returns false positives

The `go.sum` file contains an entry of every module that was considered while generating the project's [build list](https://go.dev/ref/mod#glos-build-list).
Multiple versions of a module are included in the `go.sum` file, but the [MVS](https://go.dev/ref/mod#minimal-version-selection)
algorithm used by `go build` only selects one. As a result, when dependency scanning uses `go.sum`, it might report false positives.

To prevent false positives, Gemnasium only uses `go.sum` if it is unable to generate the build list for the Go project. If `go.sum` is selected, a warning occurs:

```shell
[WARN] [Gemnasium] [2022-09-14T20:59:38Z] ▶ Selecting "go.sum" parser for "/test-projects/gitlab-shell/go.sum". False positives may occur. See https://gitlab.com/gitlab-org/gitlab/-/issues/321081.
```

## `Host key verification failed` when trying to use `ssh`

After installing `openssh-client` on any `gemnasium` image, using `ssh` might lead to a `Host key verification failed` message. This can occur if you use `~` to represent the user directory during setup, due to setting `$HOME` to `/tmp` when building the image. This issue is described in [Cloning project over SSH fails when using `gemnasium-python` image](https://gitlab.com/gitlab-org/gitlab/-/issues/374571). `openssh-client` expects to find `/root/.ssh/known_hosts` but this path does not exist; `/tmp/.ssh/known_hosts` exists instead.

This has been resolved in `gemnasium-python` where `openssh-client` is pre-installed, but the issue could occur when installing `openssh-client` from scratch on other images. To resolve this, you may either:

1. Use absolute paths (`/root/.ssh/known_hosts` instead of `~/.ssh/known_hosts`) when setting up keys and hosts.
1. Add `UserKnownHostsFile` to your `ssh` config specifying the relevant `known_hosts` files, for example: `echo 'UserKnownHostsFile /tmp/.ssh/known_hosts' >> /etc/ssh/ssh_config`.

## `ERROR: THESE PACKAGES DO NOT MATCH THE HASHES FROM THE REQUIREMENTS FILE`

This error occurs when the hash for a package in a `requirements.txt` file does not match the hash of the downloaded package.
As a security measure, `pip` will assume that the package has been tampered with and will refuse to install it.
To remediate this, ensure that the hash contained in the requirements file is correct.
For requirement files generated by [`pip-compile`](https://pip-tools.readthedocs.io/en/stable/), run `pip-compile --generate-hashes` to ensure that the hash is up to date.
If using a `Pipfile.lock` generated by [`pipenv`](https://pipenv.pypa.io/), run `pipenv verify` to verify that the lock file contains the latest package hashes.

## `ERROR: In --require-hashes mode, all requirements must have their versions pinned with ==`

This error occurs if the requirements file was generated on a different platform than the one used by the GitLab Runner.
Support for targeting other platforms is tracked in [issue 416376](https://gitlab.com/gitlab-org/gitlab/-/issues/416376).

## Editable flags can cause dependency scanning for Python to hang

If you use the [`-e/--editable`](https://pip.pypa.io/en/stable/cli/pip_install/#install-editable) flag in the `requirements.txt` file to target the current directory, you might encounter an issue that causes the Gemnasium Python dependency scanner to hang when it runs `pip3 download`.
This command is required to build the target project.

To resolve this issue, don't use the `-e/--editable` flag when you run dependency scanning for Python.

## Handling out of memory errors with SBT

If you encounter out of memory errors with SBT while using dependency scanning on a Scala project, you can address this by setting the [`SBT_CLI_OPTS`](_index.md#analyzer-specific-settings) environment variable. An example configuration is:

```yaml
variables:
  SBT_CLI_OPTS: "-J-Xmx8192m -J-Xms4192m -J-Xss2M"
```

If you're using the Kubernetes executor, you may need to override the default Kubernetes resource settings. Refer to the [Kubernetes executor documentation](https://docs.gitlab.com/runner/executors/kubernetes/#overwrite-container-resources) for details on how to adjust container resources to prevent memory issues.

## No `package-lock.json` file in NPM projects

By default, the dependency scanning job runs only when there is a `package-lock.json` file in the
repository. However, some NPM projects generate the `package-lock.json` file during the build
process, instead of storing them in the Git repository.

To scan dependencies in these projects:

1. Generate the `package-lock.json` file in a build job.
1. Store the generated file as an artifact.
1. Modify the dependency scanning job to use the artifact and adjust its rules.

For example, your configuration might look like this:

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

build:
  script:
    - npm i
  artifacts:
    paths:
      - package-lock.json  # Store the generated package-lock.json as an artifact

gemnasium-dependency_scanning:
  needs: ["build"]
  rules:
    - if: "$DEPENDENCY_SCANNING_DISABLED == 'true' || $DEPENDENCY_SCANNING_DISABLED == '1'"
      when: never
    - if: "$DS_EXCLUDED_ANALYZERS =~ /gemnasium([^-]|$)/"
      when: never
    - if: $CI_COMMIT_BRANCH && $GITLAB_FEATURES =~ /\bdependency_scanning\b/ && $CI_GITLAB_FIPS_MODE == "true"
      variables:
        DS_IMAGE_SUFFIX: "-fips"
        DS_REMEDIATE: 'false'
    - if: "$CI_COMMIT_BRANCH && $GITLAB_FEATURES =~ /\\bdependency_scanning\\b/"
```

## No dependency scanning job added to the pipeline

The dependency scanning job uses rules to check if either lockfiles with dependencies or build-tool
related files exist. If none of these files are detected, the job is not added to the pipeline, even
if the lockfile are generated by another job in the pipeline.

If you experience this situation, ensure your repository contains a
[supported file](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files),
or a file indicating that a supported file is generated at runtime. Consider whether such files can
be added to your repository to trigger the dependency scanning job.

If you believe that your repository does contain such files and the job is still not triggered, [open an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new) with the following information:

- The language and build tool you use.
- What kind of lockfile you provide and where it gets generated.

You can also contribute directly to the [dependency scanning template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml#L269-270).

## Dependency scanning fails with `gradlew: permission denied`

The `permission denied` error on `gradlew` typically indicates that `gradlew` was checked into the repository without an executable bit set. The error might appear in your job with this message:

```plaintext
[FATA] [gemnasium-maven] [2024-11-14T21:55:59Z] [/go/src/app/cmd/gemnasium-maven/main.go:65] ▶ fork/exec /builds/path/to/gradlew: permission denied
```

Make the file executable by running `chmod +ux gradlew` locally and pushing it to your Git repository.

## Dependency scanning nebula lock creation fails due to unsupported Gradle version

When attempting to create [dependency.lock files](dependency_scanning_sbom/_index.md#dependency-lock-plugin) with an unsupported Gradle version (9.0 or above) the following error occurs:

```plaintext
FAILURE: Build failed with an exception.
* Where:
Initialization script '/builds/gitlab-org/app/app/nebula.gradle' line: 11
* What went wrong:
Failed to notify build listener.
> org/gradle/util/NameMatcher
```

Try downgrading your gradle build to Gradle 8.10.2.

## Dependency scanning scanner is no longer `Gemnasium`

Historically, the scanner used by dependency scanning is `Gemnasium` and this is what user can see on the [vulnerability page](../vulnerabilities/_index.md).

With the roll out of [Dependency scanning by using SBOM](dependency_scanning_sbom/_index.md), we are replacing the `Gemnasium` scanner with the built-in `GitLab SBoM Vulnerability Scanner`. This new scanner is no longer executed in a CI/CD job but rather within the GitLab platform. While the two scanners are expected to provide the same results, because the SBOM scan happens after the existing dependency scanning CI/CD job, existing vulnerabilities have their scanner value updated with the new `GitLab SBoM Vulnerability Scanner`.

As we move forward with the roll out and ultimately replace the existing Gemnasium analyzer, the `GitLab SBoM Vulnerability Scanner` will be the only expected value for GitLab built-in dependency scanning feature.

## Dependency list for project not being updated based on latest SBOM

When a pipeline has a failing job that would generate an SBOM, the `DeleteNotPresentOccurrencesService` does not execute, which prevents the dependency list from being changed or updated. This can occur even if there are other successful jobs that upload an SBOM, and the pipeline overall is successful. This is designed to prevent accidentally removing dependencies from the dependency list when related security scanning jobs fail. If the project dependency list is not updating as expected, check for any SBOM-related jobs that may have failed in the pipeline, and fix them or remove them.

## Dependency scanning fails with `open /etc/ssl/certs/ca-certificates.crt: permission denied`

This error typically indicates that the user running the container is not a part of the `root` group.
Ensure that the user is a part of the group by running `id`.

```shell
$ id
uid=1000(node) gid=0(root) groups=0(root),1000(node)
```

If you're running OpenShift or using the Kubernetes executor, ensure that you configure the runner to
run using group ID (GID) 0.

```toml
[[runners]]
[runners.kubernetes]
    [runners.kubernetes.pod_security_context]
    run_as_non_root = true
    run_as_group = 0
```

## Error: `node with package name <package_name> does not exist`

This issue occurs when the package manager, usually nuget, is unable to find the package. This might
happen because the image used to build the application is different than the image used to run the
dependency scan.

To resolve this issue, use the same .NET SDK image that the dependency scanner uses to build your
application. You can find the exact image by running:

```shell
curl --silent "https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/raw/master/build/gemnasium/alpine/Dockerfile" | grep "vrange-nuget-build" | grep "FROM"
```

Check the Dockerfile linked above for the current image version.

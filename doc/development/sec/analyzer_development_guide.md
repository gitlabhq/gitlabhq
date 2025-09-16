---
stage: Application Security Testing
group: Static Analysis
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Sec section analyzer development
---

Analyzers are shipped as Docker images to execute within a CI pipeline context. This guide describes development and testing
practices across analyzers.

## Shared modules

There are a number of shared Go modules shared across analyzers for common behavior and interfaces:

- The [`command`](https://gitlab.com/gitlab-org/security-products/analyzers/command#how-to-use-the-library) Go package implements a CLI interface.
- The [`common`](https://gitlab.com/gitlab-org/security-products/analyzers/common) project provides miscellaneous shared modules for logging, certificate handling, and directory search capabilities.
- The [`report`](https://gitlab.com/gitlab-org/security-products/analyzers/report) Go package's `Report` and `Finding` structs marshal JSON reports.
- The [`template`](https://gitlab.com/gitlab-org/security-products/analyzers/template) project scaffolds new analyzers.

## How to use the analyzers

Analyzers are shipped as Docker images. For example, to run the
[Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) Docker image to scan the working directory:

1. `cd` into the directory of the source code you want to scan.
1. Run `docker login registry.gitlab.com` and provide username plus
   [personal](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)
   or [project](../../user/project/settings/project_access_tokens.md#create-a-project-access-token)
   access token with at least the `read_registry` scope.
1. Run the Docker image:

   ```shell
   docker run \
       --interactive --tty --rm \
       --volume "$PWD":/tmp/app \
       --env CI_PROJECT_DIR=/tmp/app \
       -w /tmp/app \
       registry.gitlab.com/gitlab-org/security-products/analyzers/semgrep:latest /analyzer run
   ```

1. The Docker container generates a report in the mounted project directory with a report filename corresponding to the analyzer category. For example, [SAST](../../user/application_security/sast/_index.md) generates a file named `gl-sast-report.json`.

## Analyzers development

To update the analyzer:

1. Modify the Go source code.
1. Build a new Docker image.
1. Run the analyzer against its test project.
1. Compare the generated report with what's expected.

Here's how to create a Docker image named `analyzer`:

```shell
docker build -t analyzer .
```

For example, to test Secret Detection run the following:

```shell
wget https://gitlab.com/gitlab-org/security-products/ci-templates/-/raw/master/scripts/compare_reports.sh
sh ./compare_reports.sh sd test/fixtures/gl-secret-detection-report.json test/expect/gl-secret-detection-report.json \
| patch -Np1 test/expect/gl-secret-detection-report.json && Git commit -m 'Update expectation' test/expect/gl-secret-detection-report.json
rm compare_reports.sh
```

You can also compile the binary for your own environment and run it locally
but `analyze` and `run` probably won't work
since the runtime dependencies of the analyzer are missing.

Here's an example based on
[SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs):

```shell
go build -o analyzer
./analyzer search test/fixtures
./analyzer convert test/fixtures/app/spotbugsXml.Xml > ./gl-sast-report.json
```

### Secure stage CI/CD Templates and components

The secure stage is responsible for maintaining the following CI/CD Templates and Components:

- [Composition Analysis](https://handbook.gitlab.com/handbook/engineering/development/sec/secure/composition-analysis)
  - CI/CD Templates
    - [`Dependency-Scanning.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml)
    - [`Dependency-Scanning.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml)
    - [`Container-Scanning.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Container-Scanning.gitlab-ci.yml)
    - [`Container-Scanning.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Container-Scanning.latest.gitlab-ci.yml)
  - CI/CD Components
    - [Dependency Scanning](https://gitlab.com/components/dependency-scanning/-/blob/main/templates/main/template.yml)
    - [Container Scanning](https://gitlab.com/components/container-scanning/-/blob/main/templates/container-scanning.yml)
- [Static Analysis (SAST)](https://handbook.gitlab.com/handbook/engineering/development/sec/secure/static-analysis)
  - CI/CD Templates
    - [`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)
    - [`SAST.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/SAST.latest.gitlab-ci.yml)
    - [`SAST-IaC.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/SAST-IaC.gitlab-ci.yml)
    - [`SAST-IaC.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/SAST-IaC.latest.gitlab-ci.yml#L1-1)
  - CI/CD Components
    - [SAST](https://gitlab.com/components/sast/-/blob/main/templates/sast.yml)
- [Secret Detection](https://handbook.gitlab.com/handbook/engineering/development/sec/secure/secret-detection)
  - CI/CD Templates
    - [`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)
    - [`Secret-Detection.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.latest.gitlab-ci.yml)
  - CI/CD Components
    - [Secret Detection](https://gitlab.com/components/secret-detection/-/blob/main/templates/secret-detection.yml)

Changes must always be made to both the CI/CD template and component for your group, and you must also determine if the changes need to be applied to the latest CI/CD template.

Analyzers are also referenced in the [`Secure-Binaries.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Secure-Binaries.gitlab-ci.yml) file for [offline environments](../../user/application_security/offline_deployments/_index.md#using-the-official-gitlab-template). Ensure this file is also kept in sync when doing changes.

### Execution criteria

[Enabling SAST](../../user/application_security/sast/_index.md#configure-sast-in-your-cicd-yaml) requires including a pre-defined [template](https://gitlab.com/gitlab-org/gitlab/-/blob/ee4d473eb9a39f2f84b719aa0ca13d2b8e11dc7e/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml) to your GitLab CI/CD configuration.

The following independent criteria determine which analyzer needs to be run on a project:

1. The SAST template uses [`rules:exists`](../../ci/yaml/_index.md#rulesexists) to determine which analyzer will be run based on the presence of certain files. For example, the Brakeman analyzer [runs when there are](https://gitlab.com/gitlab-org/gitlab/-/blob/ee4d473eb9a39f2f84b719aa0ca13d2b8e11dc7e/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml#L60) `.rb` files and a `Gemfile`.
1. Each analyzer runs a customizable [match interface](https://gitlab.com/gitlab-org/security-products/analyzers/common/-/blob/master/search/search.go) before it performs the actual analysis. For example: [Flawfinder checks for C/C++ files](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder/-/blob/f972ac786268fb649553056a94cda05cdc1248b2/plugin/plugin.go#L14).
1. For some analyzers that run on generic file extensions, there is a check based on a CI/CD variable. For example: Kubernetes manifests are written in YAML, so [Kubesec](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec) runs only when [`SCAN_KUBERNETES_MANIFESTS` is set to true](../../user/application_security/sast/_index.md#enabling-kubesec-analyzer).

Step 1 helps prevent wastage of compute quota that would be spent running analyzers not suitable for the project. However, due to [technical limitations](https://gitlab.com/gitlab-org/gitlab/-/issues/227632), it cannot be used for large projects. Therefore, step 2 acts as final check to ensure a mismatched analyzer is able to exit early.

## How to test the analyzers

Video walkthrough of how Dependency Scanning analyzers are using [downstream pipeline](../../ci/pipelines/downstream_pipelines.md) feature to test analyzers using test projects:

<i class="fa-youtube-play" aria-hidden="true"></i>
[How Sec leverages the downstream pipeline feature of GitLab to test analyzers end to end](https://www.youtube.com/watch?v=KauRBlfUbDE)
<!-- Video published on 2019-10-09 -->

### Testing local changes

To test local changes in the shared modules (such as `command` or `report`) for an analyzer
you can use the
[`go mod replace`](https://github.com/golang/go/wiki/Modules#when-should-i-use-the-replace-directive)
directive to load `command` with your local changes instead of using the version of command that has been
tagged remotely. For example:

```shell
go mod edit -replace gitlab.com/gitlab-org/security-products/analyzers/command/v3=/local/path/to/command
```

Alternatively you can achieve the same result by manually updating the `go.mod` file:

```plaintext
module gitlab.com/gitlab-org/security-products/analyzers/awesome-analyzer/v2

replace gitlab.com/gitlab-org/security-products/analyzers/command/v3 => /path/to/command

require (
    ...
    gitlab.com/gitlab-org/security-products/analyzers/command/v3 v2.19.0
)
```

#### Testing local changes in Docker

To use Docker with `replace` in the `go.mod` file:

1. Copy the contents of `command` into the directory of the analyzer. `cp -r /path/to/command path/to/analyzer/command`.
1. Add a copy statement in the analyzer's `Dockerfile`: `COPY command /command`.
1. Update the `replace` statement to make sure it matches the destination of the `COPY` statement in the step above:
   `replace gitlab.com/gitlab-org/security-products/analyzers/command/v3 => /command`

### Testing container orchestration compatibility

Users may use tools other than Docker to orchestrate their containers and run their analyzers,
such as [containerd](https://containerd.io/), [Podman](https://podman.io/), or [skopeo](https://github.com/containers/skopeo).
To ensure compatibility with these tools, we [periodicically test](https://gitlab.com/gitlab-org/security-products/tests/analyzer-containerization-support/-/blob/main/.gitlab-ci.yml?ref_type=heads)
all analyzers using a scheduled pipeline. A Slack alert is raised if a test fails.

To avoid compatibility issues when building analyzer Docker images, use the [OCI media types](https://docs.docker.com/build/exporters/#oci-media-types) instead of the default proprietary Docker media types.

In addition to the periodic test, we ensure compatibility for users of the [`ci-templates` repo](https://gitlab.com/gitlab-org/security-products/ci-templates):

1. Analyzers using the [`ci-templates` `docker-test.yml` template](https://gitlab.com/gitlab-org/security-products/ci-templates/-/blob/master/includes-dev/docker-test.yml)
include [`tests`](https://gitlab.com/gitlab-org/security-products/ci-templates/-/blob/08319f7586fd9cc66f58ca894525ab54a2b7d831/includes-dev/docker-test.yml#L155-179) to ensure our Docker images function correctly with supported Docker tools.

   These tests are executed in Merge Request pipelines and scheduled pipelines, and prevent images from being released if they break the supported Docker tools.
1. The [`ci-templates` `docker.yml` template](https://gitlab.com/gitlab-org/security-products/ci-templates/-/blob/master/includes-dev/docker.yml)
specifies [`oci-mediatypes=true`](https://docs.docker.com/build/exporters/#oci-media-types) for the `docker buildx` command when building analyzer images.
This builds images using [OCI](https://opencontainers.org/) media types rather than Docker proprietary media types.

When creating a new analyzer, or changing the location of existing analyzer images,
add it to the periodic test, or consider using the shared [`ci-templates`](https://gitlab.com/gitlab-org/security-products/ci-templates/) which includes an automated test.

## Analyzer scripts

The [analyzer-scripts](https://gitlab.com/gitlab-org/secure/tools/analyzer-scripts) repository contains scripts that can be used to interact with most analyzers. They enable you to build, run, and debug analyzers in a GitLab CI-like environment, and are particularly useful for locally validating changes to an analyzer.

For more information, refer to the [project README](https://gitlab.com/gitlab-org/secure/tools/analyzer-scripts/-/blob/master/README.md).

## Versioning and release process

GitLab Security Products use an independent versioning system from GitLab `MAJOR.MINOR`. All products use a variation of [Semantic Versioning](https://semver.org) and are available as Docker images.

`Major` is bumped with every new major release of GitLab, when [breaking changes are allowed](../deprecation_guidelines/_index.md). `Minor` is bumped for new functionality, and `Patch` is reserved for bugfixes.

The analyzers are released as Docker images following this scheme:

- each push to the default branch will override the `edge` image tag
- each push to any `awesome-feature` branch will generate a matching `awesome-feature` image tag
- each Git tag will generate the corresponding `Major.Minor.Patch` image tag. A manual job allows to override the corresponding `Major` and the `latest` image tags to point to this `Major.Minor.Patch`.

In most circumstances it is preferred to rely on the `MAJOR` image,
which is automatically kept up to date with the latest advisories or patches to our tools.
Our [included CI templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Security) pin to major version but if preferred, users can override their version directly.

To release a new analyzer Docker image, there are two different options:

- [Manual release process](#manual-release-process)
- [Automatic release process](#automatic-release-process)

The following diagram describes the Docker tags that are created when a new analyzer version is released:

```mermaid
graph LR

A1[git tag v1.1.0]--> B1(run CI pipeline)
B1 -->|build and tag patch| D1[1.1.0]
B1 -->|tag minor| E1[1.1]
B1 -->|retag major| F1[1]
B1 -->|retag latest| G1[latest]

A2[git tag v1.1.1]--> B2(run CI pipeline)
B2 -->|build and tag patch| D2[1.1.1]
B2 -->|retag minor| E2[1.1]
B2 -->|retag major| F2[1]
B2 -->|retag latest| G2[latest]

A3[push to default branch]--> B3(run CI pipeline)
B3 -->|build and tag edge| D3[edge]
```

Per our Continuous Deployment flow, for new components that do not have a counterpart in the GitLab
Rails application, the component can be released at any time. Until the components
are integrated with the existing application, iteration should not be blocked by
[our standard release cycle and process](https://handbook.gitlab.com/handbook/product/product-processes/).

### Manual release process

1. Ensure that the `CHANGELOG.md` entry for the new analyzer is correct.
1. Ensure that the release source (typically the `master` or `main` branch) has a passing pipeline.
1. Create a new release for the analyzer project by selecting the **Deployments** menu on the left-hand side of the project window, then selecting the **Releases** sub-menu.
1. Select **New release** to open the **New Release** page.
   1. In the **Tag name** drop down, enter the same version used in the `CHANGELOG.md`, for example `v2.4.2`, and select the option to create the tag (`Create tag v2.4.2` here).
   1. In the **Release title** text box enter the same version used above, for example `v2.4.2`.
   1. In the `Release notes` text box, copy and paste the notes from the corresponding version in the `CHANGELOG.md`.
   1. Leave all other settings as the default values.
   1. Select **Create release**.

After following the above process and creating a new release, a new Git tag is created with the `Tag name` provided above. This triggers a new pipeline with the given tag version and a new analyzer Docker image is built.

If the analyzer uses the [`analyzer.yml` template](https://gitlab.com/gitlab-org/security-products/ci-templates/blob/b446fd3/includes-dev/analyzer.yml#L209-217), then the pipeline triggered as part of the **New release** process above automatically tags and deploys a new version of the analyzer Docker image.

If the analyzer does not use the `analyzer.yml` template, you'll need to manually tag and deploy a new version of the analyzer Docker image:

1. Select the **CI/CD** menu on the left-hand side of the project window, then select the **Pipelines** sub-menu.
1. A new pipeline should currently be running with the same tag used previously, for example `v2.4.2`.
1. After the pipeline has completed, it will be in a `blocked` state.
1. Select the `Manual job` play button on the right hand side of the window and select `tag version` to tag and deploy a new version of the analyzer Docker image.

Use your best judgment to decide when to create a Git tag, which will then trigger the release job. If you
can't decide, then ask for other's input.

### Automatic release process

The following must be performed before the automatic release process can be used:

1. Configure `CREATE_GIT_TAG: true` as a [`CI/CD` environment variable](../../ci/variables/_index.md).
1. Check the `Variables` in the CI/CD project settings:

   - If the project is located under the `gitlab-org/security-products/analyzers` namespace, then it automatically inherits the `GITLAB_TOKEN` environment variable and nothing else needs to be done.
   - If the project is not located under the `gitlab-org/security-products/analyzers` namespace, then you'll need to create a new [masked and hidden](../../ci/variables/_index.md#hide-a-cicd-variable) `GITLAB_TOKEN` [`CI/CD` environment variable](../../ci/variables/_index.md) and set its value to the Personal Access Token for the [@gl-service-dev-secure-analyzers-automation](https://gitlab.com/gl-service-dev-secure-analyzers-automation) account described in the [Service account used in the automatic release process](#service-account-used-in-the-automatic-release-process) section below.

After the above steps have been completed, the automatic release process executes as follows:

1. A project maintainer merges an MR into the default branch.
1. The default pipeline is triggered, and the `upsert git tag` job is executed.
   - If the most recent version in the `CHANGELOG.md` matches one of the Git tags, the job is a no-op.
   - Else, this job automatically creates a new release and Git tag using the [releases API](../../api/releases/_index.md#create-a-release). The version and message is obtained from the most recent entry in the `CHANGELOG.md` file for the project.
1. A pipeline is automatically triggered for the new Git tag. This pipeline releases the `latest`, `major`, `minor` and `patch` Docker images of the analyzer.

### Service account used in the automatic release process

| Key                                    | Value                                                                                                                             |
|----------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| Account name                           | [@gl-service-dev-secure-analyzers-automation](https://gitlab.com/gl-service-dev-secure-analyzers-automation)                      |
| Purpose                                | Used for creating releases/tags                                                                                                   |
| Member of                              | [`gitlab-org/security-products`](https://gitlab.com/groups/gitlab-org/security-products/-/group_members?search=gl-service-dev-secure-analyzers-automation) |
| Maximum role                           | `Developer`                                                                                                                       |
| Scope of the associated `GITLAB_TOKEN` | `api`                                                                                                                             |
| Expiry date of `GITLAB_TOKEN`          | `December 3, 2025`                                                                                                              |

{{< alert type="warning" >}}

Any changes to the service account's access token scopes or the `GITLAB_TOKEN`
variable permissions should be announced in the section's Slack channel.

{{< /alert>}}

### Token rotation for service account

The `GITLAB_TOKEN` for the [@gl-service-dev-secure-analyzers-automation](https://gitlab.com/gl-service-dev-secure-analyzers-automation) service account **must** be rotated before the `Expiry Date` listed [above](#service-account-used-in-the-automatic-release-process) by doing the following:

1. Log in as the `gl-service-dev-secure-analyzers-automation` user.

   The list of administrators who have credentials for this account can be found in the [service account access request](https://gitlab.com/gitlab-com/team-member-epics/access-requests/-/issues/29538#admin-users).

   Administrators can find the login credentials in the shared GitLab `1password` vault.

1. Create a new [Personal Access Token](../../user/profile/personal_access_tokens.md) with `api` scope for the `gl-service-dev-secure-analyzers-automation` service account.
1. Update the `password` field of the `GitLab API Token - gl-service-dev-secure-analyzers-automation` account in the shared GitLab `1password` vault to the new Personal Access Token created in step 2 (above), and set the `Expires at` field to indicate when the token expires.
1. Update the expiry date of the `GITLAB_TOKEN` field in the [Service account used in the automatic release process](#service-account-used-in-the-automatic-release-process) table.
1. Set the following variables to the new Personal Access Token created in step 2 above:

   {{< alert type="note" >}}

   It's crucial to [mask and hide](../../ci/variables/_index.md#hide-a-cicd-variable) the following variables.

   {{< /alert >}}

   1. `GITLAB_TOKEN` CI/CD variable for the [`gitlab-org/security-products/analyzers`](https://gitlab.com/groups/gitlab-org/security-products/analyzers/-/settings/ci_cd#js-cicd-variables-settings) group.

      This allows all projects under the `gitlab-org/security-products/analyzers` namespace to inherit this `GITLAB_TOKEN` value.

   1. `GITLAB_TOKEN` CI/CD variable for the [`gitlab-org/security-products/ci-templates`](https://gitlab.com/gitlab-org/security-products/ci-templates/-/settings/ci_cd#js-cicd-variables-settings) project.

      This must be explicitly configured because the `ci-templates` project is not nested under the `gitlab-org/security-products/analyzers` namespace, and therefore _does not inherit_ the `GITLAB_TOKEN` value.

      The `ci-templates` project requires the `GITLAB_TOKEN` to allow certain scripts to execute API calls. This step can be removed after [allow JOB-TOKEN access to CI/lint endpoint](https://gitlab.com/gitlab-org/gitlab/-/issues/438781) has been completed.

   1. `GITLAB_TOKEN` CI/CD variable for the [`gitlab-org/secure/tools/security-triage-automation`](https://gitlab.com/gitlab-org/secure/tools/security-triage-automation) project.

      This must be explicitly configured because the `security-triage-automation` project is not nested under the `gitlab-org/security-products/analyzers` namespace, and therefore _does not inherit_ the `GITLAB_TOKEN` value.

   1. `GITLAB_TOKEN` CI/CD variable for [`gitlab-org/security-products/license-db`](https://gitlab.com/groups/gitlab-org/security-products/license-db/-/settings/ci_cd#ci-variables) group.

      This must be explicitly configured because the `license-db` project is not nested under the `gitlab-org/security-products/analyzers` namespace, and therefore _does not inherit_ the `GITLAB_TOKEN` value.

   1. `SEC_REGISTRY_PASSWORD` CI/CD variable for [`gitlab-advanced-sast`](https://gitlab.com/gitlab-org/security-products/analyzers/gitlab-advanced-sast/-/settings/ci_cd#js-cicd-variables-settings).

      This allows our [tagging script](https://gitlab.com/gitlab-org/security-products/ci-templates/blob/cfe285a/scripts/tag_image.sh) to pull from the private container registry in the development project `registry.gitlab.com/gitlab-org/security-products/analyzers/<analyzer-name>/tmp`, and push to the publicly accessible container registry `registry.gitlab.com/security-products/<analyzer-name>`.

### Steps to perform after releasing an analyzer

1. After a new version of the analyzer Docker image has been tagged and deployed, test it with the corresponding test project.
1. Announce the release on the relevant group Slack channel. Example message:

   > FYI I've just released `ANALYZER_NAME` `ANALYZER_VERSION`. `LINK_TO_RELEASE`

**Never delete a Git tag that has been pushed** as there is a good
chance that the tag will be used and/or cached by the Go package registry.

### Backporting a critical fix or patch

To backport a critical fix or patch to an earlier version, follow the steps below.

1. Create a new branch from the tag you are backporting the fix to, if it doesn't exist.
   - For example, if the latest stable tag is `v4` and you are backporting a fix to `v3`, create a new branch called `v3`.
1. Submit a merge request targeting the branch you just created.
1. After its approved, merge the merge request into the branch.
1. Create a new tag for the branch.
1. If the analyzer has the [automatic release process](#automatic-release-process) enabled, a new version will be released.
1. If not, you have to follow the [manual release process](#manual-release-process) to release a new version.
1. NOTE: the release pipeline will override the latest `edge` tag so the most recent release pipeline's `tag edge` job may need to be re-ran to avoid a regression for that tag.

### Preparing analyzers for a major version release

This process applies to the following groups:

- [Composition Analysis](https://handbook.gitlab.com/handbook/engineering/development/sec/secure/composition-analysis)
- [Static Analysis (SAST)](https://handbook.gitlab.com/handbook/engineering/development/sec/secure/static-analysis)
- [Secret Detection](https://handbook.gitlab.com/handbook/engineering/development/sec/secure/secret-detection)

Other groups are responsible for documenting their own major version release process.

Choose one of the following scenarios based on whether the major version release contains breaking changes:

1. [Major version release without breaking changes](#major-version-release-without-breaking-changes)
1. [Major version release with breaking changes](#major-version-release-with-breaking-changes)

#### Major version release without breaking changes

Assuming the current analyzer release is `v{N}`:

1. [Configure protected tags and branches](#configure-protected-tags-and-branches).
1. During the milestone of the major release, when there are no more changes to be merged into the `default` branch:
   1. Create a `v{N}` branch from the `default` branch.
   1. Create and merge a new Merge Request in the `default` branch containing only the following change to the `CHANGELOG.md` file:

      ```markdown
      ## v{N+1}.0.0
      - Major version release (!<MR-ID>)
      ```

   1. [Configure scheduled pipelines](#configure-scheduled-pipelines).
   1. [Bump major analyzer versions in the CI/CD templates and components](#bump-major-analyzer-versions-in-the-cicd-templates-and-components)

#### Major version release with breaking changes

Assuming the current analyzer release is `v{N}`:

1. [Configure protected tags and branches](#configure-protected-tags-and-branches).
1. Create a new branch `v{N+1}` to "stage" breaking changes.
1. In the milestones leading up to the major release milestone:
   - Merge non-breaking changes to the `default` branch (aka `master` or `main`)
   - Merge breaking changes to the `v{N+1}` branch, and create a separate `release candidate` entry in the `CHANGELOG.md` file for each change:

     ```markdown
     ## v{N+1}.0.0-rc.0
     - some breaking change (!123)
     ```

      Using `release candidates` allows us to release **all breaking changes in a single major version bump**, which follows the [semver guidance](https://semver.org) of only making breaking changes in a major version update.

1. During the milestone of the major release, when there are no more changes to be merged into the `default`  or `v{N+1}` branches:
   1. Create a `v{N}` branch from the `default` branch.
   1. Create a Merge Request in the `v{N+1}` branch to squash all the `release candidate` changelog entries into a single entry for `v{N+1}`.

      For example, if the `CHANGELOG.md` contains the following 3 `release candidate` entries for version `v{N+1}`:

      ```markdown
      ## v{N+1}.0.0-rc.2
      - yet another breaking change (!125)

      ## v{N+1}.0.0-rc.1
      - another breaking change (!124)

      ## v{N+1}.0.0-rc.0
      - some breaking change (!123)
      ```

      Then the new Merge Request should update the `CHANGELOG.md` to have a single major release for `v{N+1}`, by combining all the `release candidate` entries into a single entry:

      ```markdown
      ## v{N+1}.0.0
      - yet another breaking change (!125)
      - another breaking change (!124)
      - some breaking change (!123)
      ```

   1. Create a Merge Request to merge all the breaking changes from the `v{N+1}` branch into the `default` branch.
   1. Delete the `v{N+1}` branch, since it's no longer needed, as the `default` branch now contains all the changes from the `v{N+1}` branch.
   1. [Configure scheduled pipelines](#configure-scheduled-pipelines).
   1. [Bump major analyzer versions in the CI/CD templates and components](#bump-major-analyzer-versions-in-the-cicd-templates-and-components).

##### Configure protected tags and branches

1. Ensure the wildcard `v*` is set as both a [Protected Tag](../../user/project/protected_tags.md) and [Protected Branch](../../user/project/repository/branches/protected.md) for the project.
1. Verify the [gl-service-dev-secure-analyzers-automation](https://gitlab.com/gl-service-dev-secure-analyzers-automation) service account is `Allowed to create` protected tags.

   See step `3.1` of the [Officially supported images](#officially-supported-images) section for more details.

##### Configure scheduled pipelines

1. Ensure three scheduled pipelines exist, creating them if necessary, and set `PUBLISH_IMAGES: true` for all of them:
   - `Republish images v{N}` (against the `v{N}` branch)

      This scheduled pipeline needs to be created
   - `Daily build` (against the `default` branch)

      This scheduled pipeline should already exist
   - `Republish images v{N-1}` (against the `v{N-1}` branch)

      This scheduled pipeline should already exist
1. Delete the scheduled pipeline for the `v{N-2}` branch (if it exists), since we only support [two previous major versions](https://about.gitlab.com/support/statement-of-support/#version-support).

##### Bump major analyzer versions in the CI/CD templates and components

When images for all the `v{N+1}` analyzers are available under `registry.gitlab.com/security-products/<ANALYZER-NAME>:<TAG>`, create a new merge request to bump the major version for each analyzer in the [Secure stage CI/CD templates and components](#secure-stage-cicd-templates-and-components) belonging to your group.

## Development of new analyzers

We occasionally need to build out new analyzer projects to support new frameworks and tools.
In doing so we should follow [our engineering Open Source guidelines](https://handbook.gitlab.com/handbook/engineering/open-source/),
including licensing and [code standards](../go_guide/_index.md).

In addition, to write a custom analyzer that will integrate into the GitLab application
a minimal feature set is required:

### Checklist

Verify whether the underlying tool has:

- A [permissive software license](https://handbook.gitlab.com/handbook/engineering/open-source/#using-open-source-software).
- Headless execution (CLI tool).
- Bundle-able dependencies to be packaged as a Docker image, to be executed using GitLab Runner's [Linux or Windows Docker executor](https://docs.gitlab.com/runner/executors/docker.html).
- Compatible projects that can be detected based on filenames or extensions.
- Offline execution (no internet access) or can be configured to use custom proxies and/or CA certificates.
- The image is compatible with other container orchestration tools (see [testing container orchestration compatibility](#testing-container-orchestration-compatibility)).

#### Dockerfile

The `Dockerfile` should use an unprivileged user with the name `GitLab`.
This is necessary to provide compatibility with Red Hat OpenShift instances,
which don't allow containers to run as an admin (root) user.
There are certain limitations to keep in mind when running a container as an unprivileged user,
such as the fact that any files that need to be written on the Docker filesystem will require the appropriate permissions for the `GitLab` user.
See the following merge request for more details:
[Use GitLab user instead of root in Docker image](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/merge_requests/130).

#### Minimal vulnerability data

See [our security-report-schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/src/security-report-format.json) for a full list of required fields.

The [security-report-schema](https://gitlab.com/gitlab-org/security-products/security-report-schemas) repository contains JSON schemas that list the required fields for each report type:

- [Container Scanning](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/container-scanning-report-format.json)
- [DAST](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/dast-report-format.json)
- [Dependency Scanning](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/dependency-scanning-report-format.json)
- [SAST](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/sast-report-format.json)
- [Secret Detection](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/secret-detection-report-format.json)

#### Compatibility with report schema

Security reports uploaded as artifacts to
GitLab are [validated](../integrations/secure.md#report-validation) before being
[ingested](security_report_ingestion_overview.md).

Security report schemas are versioned using SchemaVer: `MODEL-REVISION-ADDITION`. The Sec Section
is responsible for the
[`security-report-schemas` project](https://gitlab.com/gitlab-org/security-products/security-report-schemas),
including the compatibility of GitLab and the schema versions. Schema changes must follow the
product-wide [deprecation guidelines](../deprecation_guidelines/_index.md).

When a new `MODEL` version is introduced, analyzers that adopt the new schema are responsible for
ensuring that GitLab deployments that do not vendor this new schema version continue to ingest
security reports without errors or warnings.

This can be accomplished in different ways:

1. Implement support for multiple schema versions in the analyzer. Based on the GitLab version, the
   analyzer emits a security report using the latest schema version supported by GitLab.
   - Pro: analyzer can decide at runtime what the best version to utilize is.
   - Con: implementation effort and increased complexity.
1. Release a new analyzer major version. Instances that don't vendor the latest `MODEL` schema
   version continue to use an analyzer version that emits reports using version `MODEL-1`.
   - Pro: keeps analyzer code simple.
   - Con: extra analyzer version to maintain.
1. Delay use of new schema. This relies on `additionalProperties=true`, which allows a report to
   include properties that are not present in the schema. A new analyzer major version would be
   released at the usual cadence.
   - Pro: no extra analyzer to maintain, keep analyzer code simple.
   - Con: increased risk and/or effort to mitigate the risk of not having the schema validated.

If you are unsure which path to follow, reach-out to the
[`security-report-schemas` maintainers](https://gitlab.com/groups/gitlab-org/maintainers/security-report-schemas/-/group_members?with_inherited_permissions=exclude).

### Location of Container Images

Container images for secure analyzers are published in two places:

- [Officially supported images](#officially-supported-images) in the `registry.gitlab.com/security-products` namespace, for example:

  ```shell
  registry.gitlab.com/security-products/semgrep:5
  ```

- [Temporary development images](#temporary-development-images) in the project namespace, for example:

  ```shell
  registry.gitlab.com/gitlab-org/security-products/analyzers/semgrep/tmp:d27d44a9b33cacff0c54870a40515ec5f2698475
  ```

#### Officially supported images

The location of officially supported images, as referenced by our secure templates is:

```shell
registry.gitlab.com/security-products/<ANALYZER-NAME>:<TAG>
```

For example, the [`semgrep-sast`](https://gitlab.com/gitlab-org/gitlab/blob/v17.7.0-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml#L172) job in the `SAST.gitlab-ci.yml` template references the container image `registry.gitlab.com/security-products/semgrep:5`.

In order to push images to this location:

1. Create a new project in `https://gitlab.com/security-products/<ANALYZER-NAME>`.

   For example: `https://gitlab.com/security-products/semgrep`

   Images for this project will be published to `registry.gitlab.com/security-products/<ANALYZER-NAME>:<TAG>`.

   For example: `registry.gitlab.com/security-products/semgrep:5`

1. Configure the project `https://gitlab.com/security-products/<ANALYZER-NAME>` as follows:

   1. Add the following permissions:

      - Maintainer: `@gitlab-org/secure/managers`, `@gitlab-org/govern/managers`
      - Developer: [@gl-service-dev-secure-analyzers-automation](https://gitlab.com/gl-service-dev-secure-analyzers-automation)

         This is necessary to allow the [service account used in the automatic release process](#service-account-used-in-the-automatic-release-process) to push images to `registry.gitlab.com/security-products/<ANALYZER-NAME>:<TAG>`.

   1. Configure the following project settings:

      - `Settings -> General -> Visibility, project features, permissions`
         - `Project visibility`
            - `Public`
         - `Additional options`
            - `Users can request access`
               - `Disabled`
         - `Issues`
            - `Disabled`
         - `Repository`
            - `Only Project Members`
            - `Merge Requests`
               - `Disabled`
            - `Forks`
               - `Disabled`
            - `Git Large File Storage (LFS)`
               - `Disabled`
            - `CI/CD`
               - `Disabled`
         - `Container Registry`
            - `Everyone with access`
         - `Analytics`, `Requirements`, `Security and compliance`, `Wiki`, `Snippets`, `Package registry`, `Model experiments`, `Model registry`, `Pages`, `Monitor`, `Environments`, `Feature flags`, `Infrastructure`, `Releases`, `GitLab Duo`
            - `Disabled`

1. Configure the following options for the _analyzer project_, located at `https://gitlab.com/gitlab-org/security-products/analyzers/<ANALYZER_NAME>`:

   1. Add the wildcard `v*` as a [Protected Tag](../../user/project/protected_tags.md).

      Ensure the [gl-service-dev-secure-analyzers-automation](https://gitlab.com/gl-service-dev-secure-analyzers-automation) service account has been explicitly added to the list of accounts `Allowed to create` protected tags. This is required to allow the [`upsert git tag`](https://gitlab.com/gitlab-org/security-products/ci-templates/blob/2a3519d/includes-dev/upsert-git-tag.yml#L35-44) job to create new releases for the analyzer project.

   1. Add the wildcard `v*` as a [Protected Branch](../../user/project/repository/branches/protected.md).

   1. [`CI/CD` environment variables](../../ci/variables/_index.md)

      {{< alert type="note" >}}

      It's crucial to [mask and hide](../../ci/variables/_index.md#hide-a-cicd-variable) the `SEC_REGISTRY_PASSWORD` variable.

      {{< /alert >}}

      | Key                     | Value                                                                       |
      |-------------------------|-----------------------------------------------------------------------------|
      | `SEC_REGISTRY_IMAGE`    | `registry.gitlab.com/security-products/$CI_PROJECT_NAME`                    |
      | `SEC_REGISTRY_USER`     | `gl-service-dev-secure-analyzers-automation`                                |
      | `SEC_REGISTRY_PASSWORD` | Personal Access Token for `gl-service-dev-secure-analyzers-automation` user. Request an [administrator](https://gitlab.com/gitlab-com/team-member-epics/access-requests/-/issues/29538#admin-users) to configure this token value. |

      The above variables are used by the [tag_image.sh](https://gitlab.com/gitlab-org/security-products/ci-templates/blob/a784f5d/scripts/tag_image.sh#L21-26) script in the `ci-templates` project to push the container image to `registry.gitlab.com/security-products/<ANALYZER-NAME>:<TAG>`.

      See the [semgrep CI/CD Variables](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/settings/ci_cd#js-cicd-variables-settings) for an example.

#### Temporary development images

The location of temporary development images is:

```shell
registry.gitlab.com/gitlab-org/security-products/analyzers/<ANALYZER-NAME>/tmp:<TAG>
```

For example, one of the development images for the [`semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) analyzer is:

```shell
registry.gitlab.com/gitlab-org/security-products/analyzers/semgrep/tmp:7580d6b037d93646774de601be5f39c46707bf04
```

In order to
[restrict the number of people who have write access to the container registry](https://gitlab.com/gitlab-org/gitlab/-/issues/297525),
the container registry in the development project must be [made private](https://gitlab.com/gitlab-org/gitlab/-/issues/470641) by configuring the following [project features and permissions](../../user/project/settings/_index.md) settings for the project located at `https://gitlab.com/gitlab-org/security-products/analyzers/<ANALYZER-NAME>`:

- `Settings -> General -> Visibility, project features, permissions`
  - `Container Registry`
    - `Only Project Members`

Each group in the Sec Section is responsible for:

1. Managing the deprecation and removal schedule for their artifacts, and creating issues for this purpose.
1. Creating and configuring projects under the new location.
1. Configuring builds to push release artifacts to the new location.
1. Removing or keeping images in old locations according to their own support agreements.

### Daily rebuild of Container Images

The analyzer images are rebuilt on a daily basis to ensure that we frequently and automatically pull patches provided by vendors of the base images we rely on.

This process only applies to the images used in versions of GitLab matching the current MAJOR release. The intent is not to release a newer version each day but rather rebuild each active variant of an image and overwrite the corresponding tags:

- the `MAJOR.MINOR.PATCH` image tag (for example: `4.1.7`)
- the `MAJOR.MINOR` image tag(for example: `4.1`)
- the `MAJOR` image tag (for example: `4`)
- the `latest` image tag

The implementation of the rebuild process may vary [depending on the project](../../user/application_security/detect/vulnerability_scanner_maintenance.md), though a shared CI configuration is available in our [development ci-templates project](https://gitlab.com/gitlab-org/security-products/ci-templates/-/blob/master/includes-dev/docker.yml) to help achieving this.

## Adding new language support to GitLab Advanced SAST (GLAS)

This guide helps engineers evaluate and add new language support to GLAS. These guidelines ensure consistent quality when expanding language coverage, rather than serving as strict requirements.

### Language support readiness criteria

Adapt these guidelines to your specific language while maintaining our analyzer quality standards.

These guidelines come from our experience adding PHP support to GLAS (see [issue #514210](https://gitlab.com/gitlab-org/gitlab/-/issues/514210)) and help determine when new language support is ready for production.

#### Quality readiness

##### Cross-file analysis capability

- Support the most common dependency management patterns in the target language
- Support common inclusion mechanisms specific to the language

##### Detection quality

- Precision Rate ≥ 80% across supported CWEs
- Comprehensive test corpus for each supported CWE
- Testing against popular frameworks in the language ecosystem

#### Coverage readiness

##### Priority-based coverage

- Must cover critical injection vulnerabilities relevant to the language
- Must cover common security misconfigurations
- Must align with industry standards (OWASP Top 10, SANS CWE Top 25)
- Focus on high-impact vulnerabilities commonly found in the language

#### Support readiness

##### Documentation requirements

- Language listed and described in supported languages documentation
- CWE coverage table updated with new language column
- All supported CWEs properly marked
- Known limitations clearly documented

#### Performance readiness

##### Standard performance criteria

- Medium-sized applications: < 10 minutes
- Very large applications: < 30 minutes with multi-core options

##### Benchmark definition

- Define representative codebases for benchmarking
- Include common frameworks and libraries

## Security and Build fixes of Go

The `Dockerfile` of the Secure analyzers implemented in Go must reference a `MAJOR` release of Go, and not a `MINOR` revision.
This ensures that the version of Go used to compile the analyzer includes all the security fixes available at a given time.
For example, the multi-stage Dockerfile of an analyzer must use the `golang:1.15-alpine` image
to build the analyzer CLI, but not `golang:1.15.4-alpine`.

When a `MINOR` revision of Go is released, and when it includes security fixes,
project maintainers must check whether the Secure analyzers need to be re-built.
The version of Go used for the build should appear in the log of the `build` job corresponding to the release,
and it can also be extracted from the Go binary using the [strings](https://en.wikipedia.org/wiki/Strings_(Unix)) command.

If the latest image of the analyzer was built with the affected version of Go, then it needs to be rebuilt.
To rebuild the image, maintainers can either:

- trigger a new pipeline for the Git tag that corresponds to the stable release
- create a new Git tag where the `BUILD` number is incremented
- trigger a pipeline for the default branch, and where the `PUBLISH_IMAGES` variable is set to a non-empty value

Either way a new Docker image is built, and it's published with the same image tags: `MAJOR.MINOR.PATCH` and `MAJOR`.

This workflow assumes full compatibility between `MINOR` revisions of the same `MAJOR` release of Go.
If there's a compatibility issue, the project pipeline will fail when running the tests.
In that case, it might be necessary to reference a `MINOR` revision of Go in the Dockerfile
and document that exception until the compatibility issue has been resolved.

Since it is NOT referenced in the `Dockerfile`, the `MINOR` revision of Go is NOT mentioned in the project changelog.

There may be times where it makes sense to use a build tag as the changes made are build related and don't
require a changelog entry. For example, pushing Docker images to a new registry location.

### Git tag to rebuild

When creating a new Git tag to rebuild the analyzer,
the new tag has the same `MAJOR.MINOR.PATCH` version as before,
but the `BUILD` number (as defined in [semver](https://semver.org/)) is incremented.

For instance, if the latest release of the analyzer is `v1.2.3`,
and if the corresponding Docker image was built using an affected version of Go,
then maintainers create the Git tag `v1.2.3+1` to rebuild the image.
If the latest release is `v1.2.3+1`, then they create `v1.2.3+2`.

The build number is automatically removed from the image tag.
To illustrate, creating a Git tag `v1.2.3+1` in the `gemnasium` project
makes the pipeline rebuild the image, and push it as `gemnasium:1.2.3`.

The Git tag created to rebuild has a simple message that explains why the new build is needed.
Example: `Rebuild with Go 1.15.6`.
The tag has no release notes, and no release is created.

To create a new Git tag to rebuild the analyzer, follow these steps:

1. Create a new Git tag and provide a message

   ```shell
   git tag -a v1.2.3+1 -m "Rebuild with Go 1.15.6"
   ```

1. Push the tags to the repo

   ```shell
   git push origin --tags
   ```

1. A new pipeline for the Git tag will be triggered and a new image will be built and tagged.
1. Run a new pipeline for the `master` branch in order to run the full suite of tests and generate a new vulnerability report for the newly tagged image. This is necessary because the release pipeline triggered in step `3.` above runs only a subset of tests, for example, it does not perform a `Container Scanning` analysis.

### Monthly release process

This should be done on the **18th of each month**. Though, this is a soft deadline and there is no harm in doing it within a few days after.

First, create a new issue for a release with a script from this repo: `./scripts/release_issue.rb MAJOR.MINOR`.
This issue will guide you through the whole release process. In general, you have to perform the following tasks:

- Check the list of supported technologies in GitLab documentation.
  - [Supported languages in SAST](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)
  - [Supported languages in DS](../../user/application_security/dependency_scanning/_index.md#supported-languages-and-package-managers)
  - [Supported languages in LS](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#supported-languages-and-package-managers)

- Check that CI **_job definitions are still accurate_** in vendored CI/CD templates and **_all of the ENV vars are propagated_** to the Docker containers upon `docker run` per tool.

  - [SAST vendored CI/CD template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)
  - [Dependency Scanning vendored CI/CD template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml)
  - [Container Scanning CI/CD template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/Container-Scanning.gitlab-ci.yml)

  If needed, go to the pipeline corresponding to the last Git tag,
  and trigger the manual job that controls the build of this image.

#### Dependency updates

All dependencies and upstream scanners (if any) used in the analyzer source are updated on a monthly cadence which primarily includes security fixes and non-breaking changes.

##### SAST and Secret Detection

SAST and Secret Detection teams use an internal tool ([SastBot](https://gitlab.com/gitlab-org/security-products/analyzers/sast-analyzer-deps-bot#dependency-update-automation)) to automate dependency management of SAST and Pipeline-based Secret Detection analyzers. SastBot generates MRs on the **8th of each month** and distributes their assignment among team members to take them forward for review. For details on the process, see [Dependency Update Automation](https://gitlab.com/gitlab-org/security-products/analyzers/sast-analyzer-deps-bot#dependency-update-automation).

SastBot requires different access tokens for each job. It uses the `DEP_GITLAB_TOKEN` environment variable to retrieve the token when running scheduled pipeline jobs.

| Scheduled Pipeline | Token Source | Role | Scope | `DEP_GITLAB_TOKEN` Token Configuration Location | Token Expiry |
|--------------------|--------------|------|-------|-------------------------------------------------|--------------|
| `Merge Request Metadata Update` | [`security-products/analyzers`](https://gitlab.com/gitlab-org/security-products/analyzers) group | `developer` | `api` | Settings \> CI/CI Variables section (Masked, Protected, Hidden) | `Jul 25, 2026` |
| `Release Issue Creation` | [`security-products/release`](https://gitlab.com/gitlab-org/security-products/release) project | `planner` | `api` | Configuration section of the scheduled pipeline job | `Jul 28, 2026` |
| Analyzers | [`sast-bot`](https://gitlab.com/gitlab-org/security-products/analyzers/sast-bot) group | `developer` | `api` | Configuration section of the scheduled pipeline job | `Jul 28, 2026` |

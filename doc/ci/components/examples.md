---
stage: Verify
group: Pipeline Authoring
info: This page is maintained by Developer Relations, author @dnsmichi, see https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation
title: CI/CD component examples
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Test a component

Depending on a component's functionality, [testing the component](_index.md#test-the-component) might require additional files in the repository.
For example, a component which lints, builds, and tests software in a specific programming language requires actual source code samples.
You can have source code examples, configuration files, and similar in the same repository.

For example, the Code Quality CI/CD component's has several [code samples for testing](https://gitlab.com/components/code-quality/-/tree/main/src).

### Example: Test a Rust language CI/CD component

Depending on a component's functionality, [testing the component](_index.md#test-the-component) might require additional files in the repository.

The following "hello world" example for the Rust programming language uses the `cargo` tool chain for simplicity:

1. Go to the CI/CD component root directory.
1. Initialize a new Rust project by using the `cargo init` command.

   ```shell
   cargo init
   ```

   The command creates all required project files, including a `src/main.rs` "hello world" example.
   This step is sufficient to build the Rust source code in a component job with `cargo build`.

   ```plaintext
   tree
   .
   ├── Cargo.toml
   ├── LICENSE.md
   ├── README.md
   ├── src
   │   └── main.rs
   └── templates
       └── build.yml
   ```

1. Ensure that the component has a job to build the Rust source code, for example,
   in `templates/build.yml`:

   ```yaml
   spec:
     inputs:
       stage:
         default: build
         description: 'Defines the build stage'
       rust_version:
         default: latest
         description: 'Specify the Rust version, use values from https://hub.docker.com/_/rust/tags Defaults to latest'
   ---

   "build-$[[ inputs.rust_version ]]":
     stage: $[[ inputs.stage ]]
     image: rust:$[[ inputs.rust_version ]]
     script:
       - cargo build --verbose
   ```

   In this example:

   - The `stage` and `rust_version` inputs can be modified from their default values.
     The CI/CD job starts with a `build-` prefix and dynamically creates the name based on the `rust_version` input.
     The command `cargo build --verbose` compiles the Rust source code.

1. Test the component's `build` template in the project's `.gitlab-ci.yml` configuration file:

   ```yaml
   include:
     # include the component located in the current project from the current SHA
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       inputs:
         stage: build

   stages: [build, test, release]
   ```

1. For running tests and more, add additional functions and tests into the Rust code,
   and add a component template and job running `cargo test` in `templates/test.yml`.

   ```yaml
   spec:
     inputs:
       stage:
         default: test
         description: 'Defines the test stage'
       rust_version:
         default: latest
         description: 'Specify the Rust version, use values from https://hub.docker.com/_/rust/tags Defaults to latest'
   ---

   "test-$[[ inputs.rust_version ]]":
     stage: $[[ inputs.stage ]]
     image: rust:$[[ inputs.rust_version ]]
     script:
       - cargo test --verbose
   ```

1. Test the additional job in the pipeline by including the `test` component template:

   ```yaml
   include:
     # include the component located in the current project from the current SHA
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       inputs:
         stage: build
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/test@$CI_COMMIT_SHA
       inputs:
         stage: test

   stages: [build, test, release]
   ```

## CI/CD component patterns

This section provides practical examples of implementing common patterns in CI/CD components.

### Use boolean inputs to conditionally configure jobs

You can compose jobs with two conditionals by combining `boolean` type inputs and
[`extends`](../yaml/_index.md#extends) functionality.

For example, to configure complex caching behavior with a `boolean` input:

```yaml
spec:
  inputs:
    enable_special_caching:
      description: 'If set to `true` configures a complex caching behavior'
      type: boolean
---

.my-component:enable_special_caching:false:
  extends: null

.my-component:enable_special_caching:true:
  cache:
    policy: pull-push
    key: $CI_COMMIT_SHA
    paths: [...]

my-job:
  extends: '.my-component:enable_special_caching:$[[ inputs.enable_special_caching ]]'
  script: ... # run some fancy tooling
```

This pattern works by passing the `enable_special_caching` input into
the `extends` keyword of the job.
Depending on whether `enable_special_caching` is `true` or `false`,
the appropriate configuration is selected from the predefined hidden jobs
(`.my-component:enable_special_caching:true` or `.my-component:enable_special_caching:false`).

### Use `options` to conditionally configure jobs

You can compose jobs with multiple options, for behavior similar to `if` and `elseif`
conditionals. Use the [`extends`](../yaml/_index.md#extends) with `string` type
and multiple `options` for any number of conditions.

For example, to configure complex caching behavior with 3 different options:

```yaml
spec:
  inputs:
    cache_mode:
      description: Defines the caching mode to use for this component
      type: string
      options:
        - default
        - aggressive
        - relaxed
---

.my-component:enable_special_caching:false:
  extends: null

.my-component:cache_mode:aggressive:
  cache:
    policy: push
    key: $CI_COMMIT_SHA
    paths: ['*/**']

.my-component:cache_mode:relaxed:
  cache:
    policy: pull-push
    key: $CI_COMMIT_BRANCH
    paths: ['bin/*']

my-job:
  extends: '.my-component:cache_mode:$[[ inputs.cache_mode ]]'
  script: ... # run some fancy tooling
```

In this example, `cache_mode` input offers `default`, `aggressive`, and `relaxed` options,
each corresponding to a different hidden job.
By extending the component job with `extends: '.my-component:cache_mode:$[[ inputs.cache_mode ]]'`,
the job dynamically inherits the correct caching configuration based on the selected option.

## CI/CD component migration examples

This section shows practical examples of migrating CI/CD templates and pipeline configuration
into reusable CI/CD components.

### CI/CD component migration example: Go

A complete pipeline for the software development lifecycle can be composed with multiple jobs and stages.
CI/CD templates for programming languages may provide multiple jobs in a single template file.
As a practice, the following Go CI/CD template should be migrated.

```yaml
default:
  image: golang:latest

stages:
  - test
  - build
  - deploy

format:
  stage: test
  script:
    - go fmt $(go list ./... | grep -v /vendor/)
    - go vet $(go list ./... | grep -v /vendor/)
    - go test -race $(go list ./... | grep -v /vendor/)

compile:
  stage: build
  script:
    - mkdir -p mybinaries
    - go build -o mybinaries ./...
  artifacts:
    paths:
      - mybinaries
```

NOTE:
You can also start with migrating one job, instead of all jobs. Follow the instructions below,
and only migrate the `build` CI/CD job in the first iteration.

The CI/CD template migration involves the following steps:

1. Analyze the CI/CD jobs and dependencies, and define migration actions:
   - The `image` configuration is global, [needs to be moved into the job definitions](_index.md#avoid-using-global-keywords).
   - The `format` job runs multiple `go` commands in one job. The `go test` command should be moved
     into a separate job to increase pipeline efficiency.
   - The `compile` job runs `go build` and should be renamed to `build`.
1. Define optimization strategies for better pipeline efficiency.
   - The `stage` job attribute should be configurable to allow different CI/CD pipeline consumers.
   - The `image` key uses a hardcoded image tag `latest`. Add [`golang_version` as input](../yaml/inputs.md)
     with `latest` as default value for more flexible and reusable pipelines. The input must match
     the Docker Hub image tag values.
   - The `compile` job builds the binaries into a hard-coded target directory `mybinaries`,
     which can be enhanced with a dynamic [input](../yaml/inputs.md) and default value `mybinaries`.
1. Create a template [directory structure](_index.md#directory-structure) for the new component,
   based on one template for each job.

   - The name of the template should follow the `go` command, for example `format.yml`, `build.yml`, and `test.yml`.
   - Create a new project, initialize a Git repository, add/commit all changes, set a remote origin and push.
     Modify the URL for your CI/CD component project path.
   - Create additional files as outlined in the guidance to [write a component](_index.md#write-a-component):
     `README.md`, `LICENSE.md`, `.gitlab-ci.yml`, `.gitignore`. The following shell commands
     initialize the Go component structure:

   ```shell
   git init

   mkdir templates
   touch templates/{format,build,test}.yml

   touch README.md LICENSE.md .gitlab-ci.yml .gitignore

   git add -A
   git commit -avm "Initial component structure"

   git remote add origin https://gitlab.example.com/components/golang.git

   git push
   ```

1. Create the CI/CD jobs as template. Start with the `build` job.
   - Define the following inputs in the `spec` section: `stage`, `golang_version` and `binary_directory`.
   - Add a dynamic job name definition, accessing `inputs.golang_version`.
   - Use the similar pattern for dynamic Go image versions, accessing `inputs.golang_version`.
   - Assign the stage to the `inputs.stage` value.
   - Create the binary director from `inputs.binary_directory` and add it as parameter to `go build`.
   - Define the artifacts path to `inputs.binary_directory`.

     ```yaml
     spec:
       inputs:
         stage:
           default: 'build'
           description: 'Defines the build stage'
         golang_version:
           default: 'latest'
           description: 'Go image version tag'
         binary_directory:
           default: 'mybinaries'
           description: 'Output directory for created binary artifacts'
     ---

     "build-$[[ inputs.golang_version ]]":
       image: golang:$[[ inputs.golang_version ]]
       stage: $[[ inputs.stage ]]
       script:
         - mkdir -p $[[ inputs.binary_directory ]]
         - go build -o $[[ inputs.binary_directory ]] ./...
       artifacts:
         paths:
           - $[[ inputs.binary_directory ]]
     ```

   - The `format` job template follows the same patterns, but only requires the `stage` and `golang_version` inputs.

     ```yaml
     spec:
       inputs:
         stage:
           default: 'format'
           description: 'Defines the format stage'
         golang_version:
           default: 'latest'
           description: 'Golang image version tag'
     ---

     "format-$[[ inputs.golang_version ]]":
       image: golang:$[[ inputs.golang_version ]]
       stage: $[[ inputs.stage ]]
       script:
         - go fmt $(go list ./... | grep -v /vendor/)
         - go vet $(go list ./... | grep -v /vendor/)
     ```

   - The `test` job template follows the same patterns, but only requires the `stage` and `golang_version` inputs.

     ```yaml
     spec:
       inputs:
         stage:
           default: 'test'
           description: 'Defines the format stage'
         golang_version:
           default: 'latest'
           description: 'Golang image version tag'
     ---

     "test-$[[ inputs.golang_version ]]":
       image: golang:$[[ inputs.golang_version ]]
       stage: $[[ inputs.stage ]]
       script:
         - go test -race $(go list ./... | grep -v /vendor/)
     ```

1. In order to test the component, modify the `.gitlab-ci.yml` configuration file,
   and add [tests](_index.md#test-the-component).

   - Specify a different value for `golang_version` as input for the `build` job.
   - Modify the URL for your CI/CD component path.

     ```yaml
     stages: [format, build, test]

     include:
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/format@$CI_COMMIT_SHA
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
         inputs:
           golang_version: "1.21"
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/test@$CI_COMMIT_SHA
         inputs:
           golang_version: latest
     ```

1. Add Go source code to test the CI/CD component. The `go` commands expect a Go project
   with `go.mod` and `main.go` in the root directory.

   - Initialize the Go modules. Modify the URL for your CI/CD component path.

     ```shell
     go mod init example.gitlab.com/components/golang
     ```

   - Create a `main.go` file with a main function, printing `Hello, CI/CD component` for example.
     Tip: Use code comments to generate Go code using [GitLab Duo Code Suggestions](../../user/project/repository/code_suggestions/_index.md).

     ```go
     // Specify the package, import required packages
     // Create a main function
     // Inside the main function, print "Hello, CI/CD Component"

     package main

     import "fmt"

     func main() {
       fmt.Println("Hello, CI/CD Component")
     }
     ```

   - The directory tree should look as follows:

     ```plaintext
     tree
     .
     ├── LICENSE.md
     ├── README.md
     ├── go.mod
     ├── main.go
     └── templates
         ├── build.yml
         ├── format.yml
         └── test.yml
     ```

Follow the remaining steps in the [converting a CI/CD template into a component](_index.md#convert-a-cicd-template-to-a-component)
section to complete the migration:

1. Commit and push the changes, and verify the CI/CD pipeline results.
1. Follow the guidance on [writing a component](_index.md#write-a-component) to update the `README.md` and `LICENSE.md` files.
1. [Release the component](_index.md#publish-a-new-release) and verify it in the CI/CD catalog.
1. Add the CI/CD component into your staging/production environment.

The [GitLab-maintained Go component](https://gitlab.com/components/go) provides an example
for a successful migration from a Go CI/CD template, enhanced with inputs and component best practices.
You can inspect the Git history to learn more.

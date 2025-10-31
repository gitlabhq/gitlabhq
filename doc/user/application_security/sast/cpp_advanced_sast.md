---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Advanced SAST C/C++ configuration
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

## Getting started

To run the analyzer in your pipeline, include the SAST template and enable GitLab Advanced SAST:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_CPP_ENABLED: "true"
  SAST_COMPILATION_DATABASE: "compile_commands.json"
```

Alternatively, with the [SAST component](https://gitlab.com/components/sast/-/blob/main/templates/sast.yml):

```yaml
include:
  - component: gitlab.com/components/sast/sast
    inputs:
      run_advanced_sast_cpp: "true"

variables:
  SAST_COMPILATION_DATABASE: "compile_commands.json"
```

This minimal configuration assumes that your project can generate a compilation database (CDB).
The next section explains how to create one.

## Prerequisites

The GitLab Advanced SAST CPP analyzer requires a compilation database (CDB) to correctly parse and analyze source files.

A CDB is a JSON file (`compile_commands.json`) that contains one entry for each translation unit.
Each entry typically specifies:

- The compiler command used to build the file
- The compiler flags and include paths
- The working directory where compilation is performed

The CDB allows the analyzer to reproduce the exact build environment, ensuring accurate parsing and semantic analysis.

### Create a CDB

The way you generate a CDB depends on your build system. Below are common examples.

#### Example: CMake

[CMake](https://cmake.org/) can generate a CDB directly with `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`:

```shell
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

This option does not build the project.
It produces a `compile_commands.json` file in the `build` folder, which records the compiler commands for each source file.
The GitLab Advanced SAST CPP analyzer relies on this file to reproduce the build environment accurately.

#### Examples for various build systems

You can also find complete examples of creating a CDB and running the GitLab Advanced SAST CPP with different build systems:

- [CMake example](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/1)
- [Meson example](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/2)
- [compiledb example](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/5)
- [compiledb-go example](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/7)
- [Make + Bear example](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/4)
- [Ninja + Bear example](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/3)
- [Bazel example](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/8)

### Provide the CDB to the analyzer

Tell the GitLab Advanced SAST CPP analyzer where to find the CDB with the `SAST_COMPILATION_DATABASE` variable:

```yaml
variables:
  SAST_COMPILATION_DATABASE: YOUR_COMPILATION_DATABASE.json
```

If SAST_COMPILATION_DATABASE is not specified, the GitLab Advanced SAST CPP analyzer defaults to using a file named `compile_commands.json located` in the project root.

### Optimization: Parallel execution for efficiency

You can run the analyzer in parallel by splitting the CDB into multiple fragments.
The [`GitLab Advanced SAST CPP` repository](https://gitlab.com/gitlab-org/security-products/analyzers/clangsa/-/blob/main/templates/scripts.yml) provides helper scripts for this.

1. Include the scripts:

   ```yaml
   include:
     - project: "gitlab-org/security-products/analyzers/clangsa"
       file: "templates/scripts.yml"
   ```

1. Reference the helper scripts and split the CDB in your build job:

   ```yaml
   <YOUR-BUILD-JOB-NAME>:
     script:
       - <your-script to generate the CDB>
       - !reference [.clangsa-scripts]
       - split_cdb "${BUILD_DIR}" 1 4 # Split into 4 fragments
     artifacts:
       paths:
         - ${BUILD_DIR} # Pass the split CDB files to the parallelized gitlab-advanced-sast-cpp jobs
   ```

   {{< alert type="note" >}}
   `split_cdb` is hardcoded to read `${BUILD_DIR}/compile_commands.json`.
   Make sure your build generates the CDB at this exact location before calling `split_cdb`.
   {{< /alert >}}

1. Run parallel analyzer jobs:

   ```yaml
   gitlab-advanced-sast-cpp:
     parallel: 4
     variables:
       SAST_COMPILATION_DATABASE: "${BUILD_DIR}/compile_commands${CI_NODE_INDEX}.json"
     needs:
       - job: <YOUR-BUILD-JOB-NAME>
         artifacts: true
   ```

    - `parallel: 4` shards execution across 4 jobs.
    - `${CI_NODE_INDEX}` (1, 2, 3, 4) selects the correct CDB fragment.
    - `needs` ensures the analyzer jobs receive the artifacts produced by your build job.

With this setup, your build job produces a single `compile_commands.json`.
The `split_cdb` script creates multiple partitions, and the analyzer jobs run in parallel, with each job processing one partition.

## Ruleset configuration

GitLab Advanced SAST CPP supports [custom rulesets](customize_rulesets.md) where a "rule" is a GitLab Advanced SAST CPP checker.

Custom rulesets can be created with [passthroughs](customize_rulesets.md#build-a-custom-configuration-using-a-passthrough-chain-for-semgrep) composed of [`CodeChecker` configuration files](https://github.com/Ericsson/codechecker/blob/master/docs/config_file.md).

Passthrough configuration is handled as follows:

- `targetDir` and `target` are ignored. After processing passthroughs, any resulting flags are passed directly to `CodeChecker`
- `overwrite` mode replaces the entire configuration and `append` mode appends flags
- Certain `CodeChecker` flags cannot be customized, including the analyzer flags `-o`, `--output` and the parse flags `-o, --output, -e, --export`
- `server` and `store` configuration items are ignored

For example, given the following `.gitlab/sastconfig.toml`:

```toml
[gitlab-advanced-sast-cpp]
    description = "My ruleset"

    [[gitlab-advanced-sast-cpp.passthrough]]
        # replace the GitLab default configuration with my own
        mode  = "overwrite"
        type  = "url"
        value = "https://example.com/gitlab-advanced-sast-cpp.yaml"

    [[gitlab-advanced-sast-cpp.passthrough]]
        # append flags from a file in the current repository
        mode  = "append"
        type  = "file"
        value = "gitlab-advanced-sast-cpp.yml"
```

with the following content at `https://example.com/gitlab-advanced-sast-cpp.yaml`:

```yaml
analyzer:
  - --disable-all
  - --enable=core.DivideZero
```

and `gitlab-advanced-sast-cpp.yml` containing:

```yaml
analyzer:
  - --enable=core.CallAndMessage
```

the effective resulting configuration will be:

```yaml
analyzer:
  - --disable-all
  - --enable=core.DivideZero
  - --enable=core.CallAndMessage
```

## Troubleshooting

### Rebasing paths with `cdb-rebase`

If the paths inside the CDB do not match the container paths in your CI job, adjust them with [cdb-rebase](https://gitlab.com/gitlab-org/security-products/analyzers/clangsa/-/tree/main/cmd/cdb-rebase).

Install:

```shell
go install gitlab.com/gitlab-org/secure/tools/cdb-rebase@latest
```

The binary is installed in `$GOPATH/bin` or `$HOME/go/bin`. Ensure this directory is in your `PATH`.

Example usage:

```shell
cdb-rebase compile_commands.json /host/path /container/path > rebased_compile_commands.json
```

### Fixing the CDB

If the build environment differs from the scan environment, the generated CDB might require adjustments.
You can modify it with [jq](https://jqlang.org),
or use `cdb_append`, a shell function from the [predefined helper script](https://gitlab.com/gitlab-org/security-products/analyzers/clangsa/-/blob/main/templates/scripts.yml).

`cdb_append` appends compiler options to an existing CDB.
It accepts:

- First argument: the folder containing `compile_commands.json`
- Subsequent arguments: additional compiler options to append

Example in CI:

```yaml
include:
  - project: "gitlab-org/security-products/analyzers/clangsa"
    file: "templates/scripts.yml"

<YOUR-BUILD-JOB-NAME>:
  script:
    - !reference [.clangsa-scripts]
    - <your-script to generate the CDB>
    - cdb_append "${BUILD_DIR}" "-I'$PWD/include-cache'" "-Wno-error=register"
```

### Caching a CDB

To accelerate the compilation and analysis process, the CDB can be [cached](../../../ci/caching/_index.md).

```yaml
.cdb_cache:
  cache: &cdb_cache
    key:
      files:
        - Makefile
        - src/
    paths:
      - compile_commands.json

<YOUR-BUILD-JOB-NAME>:
  script:
    - <your-script to generate the CDB>
  cache:
    <<: *cdb_cache
    policy: pull-push

gitlab-advanced-sast-cpp:
  cache:
    <<: *cdb_cache
    policy: pull
```

For a complete example see the demo project [`cached-cdb`](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/cached-db).

### Handling absolute paths in a CDB

In the [demo project](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/cached-db/-/blob/1a36792b744d7a6ad396a8ac8114ca8947e45b62/.gitlab-ci.yml#L27), `bear` is run from the [Builds directory](https://docs.gitlab.com/runner/configuration/advanced-configuration/#default-build-directory) of a Docker job.
The CDB paths are absolute, based at [/builds/$CI_PROJECT_PATH](../../../ci/variables/predefined_variables.md).
The analyzer job `gitlab-advanced-sast-cpp` runs in the same location, so paths are correct.

If the CDB was generated at a path not available during analysis, it must be rebased.
The `cdb-rebase` tool, included in the analyzer image, rewrites `directory`, `file`, and `output` paths.

Example:

```yaml
gitlab-advanced-sast-cpp:
  before-script:
    # Rebase the original CDB to be relative to the current directory.
    #
    # ORIGINAL_CDB_PATH     - Path to the CDB artifact from a previous job (e.g., artifacts/compile_commands.json)
    # ORIGINAL_CDB_BASEPATH - The absolute path to the project root when the ORIGINAL_CDB_PATH was generated.
    #                         (e.g., /mnt/custom_build_area/my-project or /home/user/my-project)
    - /cdb-rebase   --input "$ORIGINAL_CDB_PATH" \
                    --output compile_commands.json \
                    --src "$ORIGINAL_CDB_BASEPATH" \
                    --dst .
```

For a full demonstration, see [cdb-rebase-demo](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/cdb-rebase-demo)

Beyond simple path rebasing, `cdb-rebase` can also manage include files between the build and scan environments:

- Cache external headers: with `--include-cache`, headers outside the source tree are copied into a portable cache.
- Add include paths: with `--include`, specify extra include directories to be cached.
- Exclude files: with `--exclude`, skip headers you don’t want to carry over.

Example:

```shell
/cdb-rebase --src /my-project \
            --dst /scan-env \
            --input build/compile_commands.json \
            --output rebased_cdb.json \
            --include-cache include-cache \
            --include third_party/include \
            --exclude dummy.h
```

The `cde-rebase` tool is also available to environments with Go installed, so rebasing the CDB when it is generated is possible, e.g.

```shell
go install gitlab.com/gitlab-org/security-products/analyzers/clangsa/cmd/cdb-rebase@latest
bear -o compile_commands_abs.json -- make
cdb-rebase -i compile_commands_abs.json -o compile_commands.json -s "$PWD" -d .
```

Note: the `go install` command above installs `cdb-rebase` to the `GOBIN` path, which can be found with `go env GOBIN`.

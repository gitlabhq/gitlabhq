---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Coverage-guided fuzz testing
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Coverage-guided fuzz testing sends random inputs to an instrumented version of your application in
an effort to cause unexpected behavior. Such behavior indicates a bug that you should address.
GitLab allows you to add coverage-guided fuzz testing to your pipelines. This helps you discover
bugs and potential security issues that other QA processes may miss.

You should use fuzz testing in addition to the other security scanners in [GitLab Secure](../_index.md)
and your own test processes. If you're using [GitLab CI/CD](../../../ci/_index.md),
you can run your coverage-guided fuzz testing as part your CI/CD workflow.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Coverage Fuzzing](https://www.youtube.com/watch?v=bbIenVVcjW0).

## Coverage-guided fuzz testing process

The fuzz testing process:

1. Compiles the target application.
1. Runs the instrumented application, using the `gitlab-cov-fuzz` tool.
1. Parses and analyzes the exception information output by the fuzzer.
1. Downloads the [corpus](../terminology/_index.md#corpus) from either:
   - The previous pipelines.
   - If `COVFUZZ_USE_REGISTRY` is set to `true`, the [corpus registry](#corpus-registry).
1. Downloads crash events from previous pipeline.
1. Outputs the parsed crash events and data to the `gl-coverage-fuzzing-report.json` file.
1. Updates the corpus, either:
   - In the job's pipeline.
   - If `COVFUZZ_USE_REGISTRY` is set to `true`, in the corpus registry.

The results of the coverage-guided fuzz testing are available in the CI/CD pipeline.

## Supported fuzzing engines and languages

You can use the following fuzzing engines to test the specified languages.

| Language                                    | Fuzzing Engine                                                                                       | Example                                                                                                                         |
|---------------------------------------------|------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| C/C++                                       | [libFuzzer](https://llvm.org/docs/LibFuzzer.html)                                                    | [c-cpp-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/c-cpp-fuzzing-example)                   |
| Go                                          | [go-fuzz (libFuzzer support)](https://github.com/dvyukov/go-fuzz)                                    | [go-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example)                 |
| Swift                                       | [libFuzzer](https://github.com/apple/swift/blob/master/docs/libFuzzerIntegration.md)                 | [swift-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/swift-fuzzing-example)           |
| Rust                                        | [cargo-fuzz (libFuzzer support)](https://github.com/rust-fuzz/cargo-fuzz)                            | [rust-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/rust-fuzzing-example)             |
| Java (Maven only)<sup>1</sup>               | [Javafuzz](https://gitlab.com/gitlab-org/security-products/analyzers/fuzzers/javafuzz) (recommended) | [javafuzz-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/javafuzz-fuzzing-example)     |
| Java                                        | [JQF](https://github.com/rohanpadhye/JQF) (not preferred)                                            | [jqf-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/java-fuzzing-example)              |
| JavaScript                                  | [`jsfuzz`](https://gitlab.com/gitlab-org/security-products/analyzers/fuzzers/jsfuzz)                 | [jsfuzz-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/jsfuzz-fuzzing-example)         |
| Python                                      | [`pythonfuzz`](https://gitlab.com/gitlab-org/security-products/analyzers/fuzzers/pythonfuzz)         | [pythonfuzz-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/pythonfuzz-fuzzing-example) |
| AFL (any language that works on top of AFL) | [AFL](https://lcamtuf.coredump.cx/afl/)                                                              | [afl-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/afl-fuzzing-example)               |

1. Support for Gradle is planned in [issue 409764](https://gitlab.com/gitlab-org/gitlab/-/issues/409764).

## Confirm status of coverage-guided fuzz testing

To confirm the status of coverage-guided fuzz testing:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Coverage Fuzzing** section the status is:
   - **Not configured**
   - **Enabled**
   - A prompt to upgrade to GitLab Ultimate.

## Enable coverage-guided fuzz testing

To enable coverage-guided fuzz testing, edit `.gitlab-ci.yml`:

1. Add the `fuzz` stage to the list of stages.

1. If your application is not written in Go, [provide a Docker image](../../../ci/yaml/_index.md#image) using the matching fuzzing
   engine. For example:

   ```yaml
   image: python:latest
   ```

1. [Include](../../../ci/yaml/_index.md#includetemplate) the
   [`Coverage-Fuzzing.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Coverage-Fuzzing.gitlab-ci.yml)
   provided as part of your GitLab installation.

1. Customize the `my_fuzz_target` job to meet your requirements.

### Example extract of coverage-guided fuzzing configuration

```yaml
stages:
  - fuzz

include:
  - template: Coverage-Fuzzing.gitlab-ci.yml

my_fuzz_target:
  extends: .fuzz_base
  script:
    # Build your fuzz target binary in these steps, then run it with gitlab-cov-fuzz
    # See our example repos for how you could do this with any of our supported languages
    - ./gitlab-cov-fuzz run --regression=$REGRESSION -- <your fuzz target>
```

The `Coverage-Fuzzing` template includes the [hidden job](../../../ci/jobs/_index.md#hide-a-job)
`.fuzz_base`, which you must [extend](../../../ci/yaml/_index.md#extends) for each of your fuzzing
targets. Each fuzzing target **must** have a separate job. For example, the
[go-fuzzing-example project](https://gitlab.com/gitlab-org/security-products/demos/go-fuzzing-example)
contains one job that extends `.fuzz_base` for its single fuzzing target.

The hidden job `.fuzz_base` uses several YAML keys that you must not override in your own
job. If you include these keys in your own job, you must copy their original content:

- `before_script`
- `artifacts`
- `rules`

### Available CI/CD variables

Use the following variables to configure coverage-guided fuzz testing in your CI/CD pipeline.

WARNING:
All customization of GitLab security scanning tools should be tested in a merge request before
merging these changes to the default branch. Failure to do so can give unexpected results, including
a large number of false positives.

| CI/CD variable            | Description                                                                     |
|---------------------------|---------------------------------------------------------------------------------|
| `COVFUZZ_ADDITIONAL_ARGS` | Arguments passed to `gitlab-cov-fuzz`. Used to customize the behavior of the underlying fuzzing engine. Read the fuzzing engine's documentation for a complete list of arguments. |
| `COVFUZZ_BRANCH`          | The branch on which long-running fuzzing jobs are to be run. On all other branches, only fuzzing regression tests are run. Default: Repository's default branch. |
| `COVFUZZ_SEED_CORPUS`     | Path to a seed corpus directory. Default: empty. |
| `COVFUZZ_URL_PREFIX`      | Path to the `gitlab-cov-fuzz` repository cloned for use with an offline environment. You should only change this value when using an offline environment. Default: `https://gitlab.com/gitlab-org/security-products/analyzers/gitlab-cov-fuzz/-/raw`. |
| `COVFUZZ_USE_REGISTRY`    | Set to `true` to have the corpus stored in the GitLab corpus registry. The variables `COVFUZZ_CORPUS_NAME` and `COVFUZZ_GITLAB_TOKEN` are required if this variable is set to `true`. Default: `false`. |
| `COVFUZZ_CORPUS_NAME`     | Name of the corpus to be used in the job. |
| `COVFUZZ_GITLAB_TOKEN`    | Environment variable configured with [personal access token](../../profile/personal_access_tokens.md#create-a-personal-access-token) or [project access token](../../project/settings/project_access_tokens.md#create-a-project-access-token) with API read/write access. |

#### Seed corpus

Files in the [seed corpus](../terminology/_index.md#seed-corpus) must be updated manually. They are
not updated or overwritten by the coverage-guide fuzz testing job.

## Output

Each fuzzing step outputs these artifacts:

- `gl-coverage-fuzzing-report.json`: A report containing details of the coverage-guided fuzz testing
  and its results.
- `artifacts.zip`: This file contains two directories:
  - `corpus`: Contains all test cases generated by the current and all previous jobs.
  - `crashes`: Contains all crash events the current job found and those not fixed in
    previous jobs.

You can download the JSON report file from the CI/CD pipelines page. For more information, see
[Downloading artifacts](../../../ci/jobs/job_artifacts.md#download-job-artifacts).

## Corpus registry

The corpus registry is a library of corpora. Corpora in a project's registry are available to
all jobs in that project. A project-wide registry is a more efficient way to manage corpora than
the default option of one corpus per job.

The corpus registry uses the package registry to store the project's corpora. Corpora stored in
the registry are hidden to ensure data integrity.

When you download a corpus, the file is named `artifacts.zip`, regardless of the filename used when
the corpus was initially uploaded. This file contains only the corpus, which is different to the
artifacts files you can download from the CI/CD pipeline. Also, a project member with a Reporter or above privilege can download the corpus using the direct download link.

### View details of the corpus registry

To view details of the corpus registry:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Coverage Fuzzing** section, select **Manage corpus**.

### Create a corpus in the corpus registry

To create a corpus in the corpus registry, either:

- Create a corpus in a pipeline
- Upload an existing corpus file

#### Create a corpus in a pipeline

To create a corpus in a pipeline:

1. In the `.gitlab-ci.yml` file, edit the `my_fuzz_target` job.
1. Set the following variables:
   - Set `COVFUZZ_USE_REGISTRY` to `true`.
   - Set `COVFUZZ_CORPUS_NAME` to name the corpus.
   - Set `COVFUZZ_GITLAB_TOKEN` to the value of the personal access token.

After the `my_fuzz_target` job runs, the corpus is stored in the corpus registry, with the name
provided by the `COVFUZZ_CORPUS_NAME` variable. The corpus is updated on every pipeline run.

#### Upload a corpus file

To upload an existing corpus file:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Coverage Fuzzing** section, select **Manage corpus**.
1. Select **New corpus**.
1. Complete the fields.
1. Select **Upload file**.
1. Select **Add**.

You can now reference the corpus in the `.gitlab-ci.yml` file. Ensure the value used in the
`COVFUZZ_CORPUS_NAME` variable matches exactly the name given to the uploaded corpus file.

### Use a corpus stored in the corpus registry

To use a corpus stored in the corpus registry, you must reference it by its name. To confirm the
name of the relevant corpus, view details of the corpus registry.

Prerequisites:

- [Enable coverage-guide fuzz testing](#enable-coverage-guided-fuzz-testing) in the project.

1. Set the following variables in the `.gitlab-ci.yml` file:
   - Set `COVFUZZ_USE_REGISTRY` to `true`.
   - Set `COVFUZZ_CORPUS_NAME` to the name of the corpus.
   - Set `COVFUZZ_GITLAB_TOKEN` to the value of the personal access token.

## Coverage-guided fuzz testing report

For detailed information about the `gl-coverage-fuzzing-report.json` file's format, read the
[schema](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/coverage-fuzzing-report-format.json).

Example coverage-guided fuzzing report:

```json-doc
{
  "version": "v1.0.8",
  "regression": false,
  "exit_code": -1,
  "vulnerabilities": [
    {
      "category": "coverage_fuzzing",
      "message": "Heap-buffer-overflow\nREAD 1",
      "description": "Heap-buffer-overflow\nREAD 1",
      "severity": "Critical",
      "stacktrace_snippet": "INFO: Seed: 3415817494\nINFO: Loaded 1 modules   (7 inline 8-bit counters): 7 [0x10eee2470, 0x10eee2477), \nINFO: Loaded 1 PC tables (7 PCs): 7 [0x10eee2478,0x10eee24e8), \nINFO:        5 files found in corpus\nINFO: -max_len is not provided; libFuzzer will not generate inputs larger than 4096 bytes\nINFO: seed corpus: files: 5 min: 1b max: 4b total: 14b rss: 26Mb\n#6\tINITED cov: 7 ft: 7 corp: 5/14b exec/s: 0 rss: 26Mb\n=================================================================\n==43405==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x602000001573 at pc 0x00010eea205a bp 0x7ffee0d5e090 sp 0x7ffee0d5e088\nREAD of size 1 at 0x602000001573 thread T0\n    #0 0x10eea2059 in FuzzMe(unsigned char const*, unsigned long) fuzz_me.cc:9\n    #1 0x10eea20ba in LLVMFuzzerTestOneInput fuzz_me.cc:13\n    #2 0x10eebe020 in fuzzer::Fuzzer::ExecuteCallback(unsigned char const*, unsigned long) FuzzerLoop.cpp:556\n    #3 0x10eebd765 in fuzzer::Fuzzer::RunOne(unsigned char const*, unsigned long, bool, fuzzer::InputInfo*, bool*) FuzzerLoop.cpp:470\n    #4 0x10eebf966 in fuzzer::Fuzzer::MutateAndTestOne() FuzzerLoop.cpp:698\n    #5 0x10eec0665 in fuzzer::Fuzzer::Loop(std::__1::vector\u003cfuzzer::SizedFile, fuzzer::fuzzer_allocator\u003cfuzzer::SizedFile\u003e \u003e\u0026) FuzzerLoop.cpp:830\n    #6 0x10eead0cd in fuzzer::FuzzerDriver(int*, char***, int (*)(unsigned char const*, unsigned long)) FuzzerDriver.cpp:829\n    #7 0x10eedaf82 in main FuzzerMain.cpp:19\n    #8 0x7fff684fecc8 in start+0x0 (libdyld.dylib:x86_64+0x1acc8)\n\n0x602000001573 is located 0 bytes to the right of 3-byte region [0x602000001570,0x602000001573)\nallocated by thread T0 here:\n    #0 0x10ef92cfd in wrap__Znam+0x7d (libclang_rt.asan_osx_dynamic.dylib:x86_64+0x50cfd)\n    #1 0x10eebdf31 in fuzzer::Fuzzer::ExecuteCallback(unsigned char const*, unsigned long) FuzzerLoop.cpp:541\n    #2 0x10eebd765 in fuzzer::Fuzzer::RunOne(unsigned char const*, unsigned long, bool, fuzzer::InputInfo*, bool*) FuzzerLoop.cpp:470\n    #3 0x10eebf966 in fuzzer::Fuzzer::MutateAndTestOne() FuzzerLoop.cpp:698\n    #4 0x10eec0665 in fuzzer::Fuzzer::Loop(std::__1::vector\u003cfuzzer::SizedFile, fuzzer::fuzzer_allocator\u003cfuzzer::SizedFile\u003e \u003e\u0026) FuzzerLoop.cpp:830\n    #5 0x10eead0cd in fuzzer::FuzzerDriver(int*, char***, int (*)(unsigned char const*, unsigned long)) FuzzerDriver.cpp:829\n    #6 0x10eedaf82 in main FuzzerMain.cpp:19\n    #7 0x7fff684fecc8 in start+0x0 (libdyld.dylib:x86_64+0x1acc8)\n\nSUMMARY: AddressSanitizer: heap-buffer-overflow fuzz_me.cc:9 in FuzzMe(unsigned char const*, unsigned long)\nShadow bytes around the buggy address:\n  0x1c0400000250: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n  0x1c0400000260: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n  0x1c0400000270: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n  0x1c0400000280: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n  0x1c0400000290: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n=\u003e0x1c04000002a0: fa fa fd fa fa fa fd fa fa fa fd fa fa fa[03]fa\n  0x1c04000002b0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\n  0x1c04000002c0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\n  0x1c04000002d0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\n  0x1c04000002e0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\n  0x1c04000002f0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\nShadow byte legend (one shadow byte represents 8 application bytes):\n  Addressable:           00\n  Partially addressable: 01 02 03 04 05 06 07 \n  Heap left redzone:       fa\n  Freed heap region:       fd\n  Stack left redzone:      f1\n  Stack mid redzone:       f2\n  Stack right redzone:     f3\n  Stack after return:      f5\n  Stack use after scope:   f8\n  Global redzone:          f9\n  Global init order:       f6\n  Poisoned by user:        f7\n  Container overflow:      fc\n  Array cookie:            ac\n  Intra object redzone:    bb\n  ASan internal:           fe\n  Left alloca redzone:     ca\n  Right alloca redzone:    cb\n  Shadow gap:              cc\n==43405==ABORTING\nMS: 1 EraseBytes-; base unit: de3a753d4f1def197604865d76dba888d6aefc71\n0x46,0x55,0x5a,\nFUZ\nartifact_prefix='./crashes/'; Test unit written to ./crashes/crash-0eb8e4ed029b774d80f2b66408203801cb982a60\nBase64: RlVa\nstat::number_of_executed_units: 122\nstat::average_exec_per_sec:     0\nstat::new_units_added:          0\nstat::slowest_unit_time_sec:    0\nstat::peak_rss_mb:              28",
      "scanner": {
        "id": "libFuzzer",
        "name": "libFuzzer"
      },
      "location": {
        "crash_address": "0x602000001573",
        "crash_state": "FuzzMe\nstart\nstart+0x0\n\n",
        "crash_type": "Heap-buffer-overflow\nREAD 1"
      },
      "tool": "libFuzzer"
    }
  ]
}
```

## Duration of coverage-guided fuzz testing

The available durations for coverage-guided fuzz testing are:

- 10-minute duration (default): Recommended for the default branch.
- 60-minute duration: Recommended for the development branch and merge requests. The longer duration provides greater coverage.
  In the `COVFUZZ_ADDITIONAL_ARGS` variable set the value `--regression=true`.

For a complete example, read the [Go coverage-guided fuzzing example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example/-/blob/master/.gitlab-ci.yml).

### Continuous coverage-guided fuzz testing

It's also possible to run the coverage-guided fuzzing jobs longer and without blocking your main
pipeline. This configuration uses the GitLab
[parent-child pipelines](../../../ci/pipelines/downstream_pipelines.md#parent-child-pipelines).

The suggested workflow in this scenario is to have long-running, asynchronous fuzzing jobs on the
main or development branch, and short synchronous fuzzing jobs on all other branches and MRs. This
balances the needs of completing the per-commit pipeline complete quickly, while also giving the
fuzzer a large amount of time to fully explore and test the app. Long-running fuzzing jobs are
usually necessary for the coverage-guided fuzzer to find deeper bugs in your codebase.

The following is an extract of the `.gitlab-ci.yml` file for this
workflow. For the full example, see the [Go fuzzing example's repository](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example/-/tree/continuous_fuzzing):

```yaml

sync_fuzzing:
  variables:
    COVFUZZ_ADDITIONAL_ARGS: '-max_total_time=300'
  trigger:
    include: .covfuzz-ci.yml
    strategy: depend
  rules:
    - if: $CI_COMMIT_BRANCH != 'continuous_fuzzing' && $CI_PIPELINE_SOURCE != 'merge_request_event'

async_fuzzing:
  variables:
    COVFUZZ_ADDITIONAL_ARGS: '-max_total_time=3600'
  trigger:
    include: .covfuzz-ci.yml
  rules:
    - if: $CI_COMMIT_BRANCH == 'continuous_fuzzing' && $CI_PIPELINE_SOURCE != 'merge_request_event'
```

This creates two jobs:

1. `sync_fuzzing`: Runs all your fuzz targets for a short period of time in a blocking
   configuration. This finds simple bugs and allows you to be confident that your MRs aren't
   introducing new bugs or causing old bugs to reappear.
1. `async_fuzzing`: Runs on your branch and finds deep bugs in your code without blocking your
   development cycle and MRs.

The `covfuzz-ci.yml` is the same as that in the [original synchronous example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example#running-go-fuzz-from-ci).

## FIPS-enabled binary

[Starting in GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/352549) the coverage fuzzing binary is compiled with `golang-fips` on Linux x86 and uses OpenSSL as the cryptographic backend. For more details, see [FIPS compliance at GitLab with Go](../../../development/fips_gitlab.md#go).

## Offline environment

To use coverage fuzzing in an offline environment:

1. Clone [`gitlab-cov-fuzz`](https://gitlab.com/gitlab-org/security-products/analyzers/gitlab-cov-fuzz)
   to a private repository that your offline GitLab instance can access.

1. For each fuzzing step, set `COVFUZZ_URL_PREFIX` to `${NEW_URL_GITLAB_COV_FUZ}/-/raw`, where
   `NEW_URL_GITLAB_COV_FUZ` is the URL of the private `gitlab-cov-fuzz` clone that you set up in the
   first step.

## Interacting with the vulnerabilities

After a vulnerability is found, you can [address it](../vulnerabilities/_index.md).
The merge request widget lists the vulnerability and contains a button for downloading the fuzzing
artifacts. By selecting one of the detected vulnerabilities, you can see its details.

![Coverage Fuzzing Security Report](img/coverage_fuzzing_report_v13_6.png)

You can also view the vulnerability from the [Security Dashboard](../security_dashboard/_index.md),
which shows an overview of all the security vulnerabilities in your groups, projects, and pipelines.

Selecting the vulnerability opens a modal that provides additional information about the
vulnerability:

- Status: The vulnerability's status. As with any type of vulnerability, a coverage fuzzing
  vulnerability can be Detected, Confirmed, Dismissed, or Resolved.
- Project: The project in which the vulnerability exists.
- Crash type: The type of crash or weakness in the code. This typically maps to a [CWE](https://cwe.mitre.org/).
- Crash state: A normalized version of the stack trace, containing the last three functions of the
  crash (without random addresses).
- Stack trace snippet: The last few lines of the stack trace, which shows details about the crash.
- Identifier: The vulnerability's identifier. This maps to either a [CVE](https://cve.mitre.org/)
  or [CWE](https://cwe.mitre.org/).
- Severity: The vulnerability's severity. This can be Critical, High, Medium, Low, Info, or Unknown.
- Scanner: The scanner that detected the vulnerability (for example, Coverage Fuzzing).
- Scanner Provider: The engine that did the scan. For Coverage Fuzzing, this can be any of the
  engines listed in [Supported fuzzing engines and languages](#supported-fuzzing-engines-and-languages).

## Troubleshooting

### Error `Unable to extract corpus folder from artifacts zip file`

If you see this error message, and `COVFUZZ_USE_REGISTRY` is set to `true`, ensure that the uploaded
corpus file extracts into a folder named `corpus`.

### Error `400 Bad request - Duplicate package is not allowed`

If you see this error message when running the fuzzing job with `COVFUZZ_USE_REGISTRY` set to `true`,
ensure that duplicates are allowed. For more details, see
[duplicate Generic packages](../../packages/generic_packages/_index.md#disable-publishing-duplicate-package-names).

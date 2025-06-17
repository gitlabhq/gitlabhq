---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting scripts and job logs
---

## `Syntax is incorrect` in scripts that use `:`

If you use a colon (`:`) in a script, GitLab might output:

- `Syntax is incorrect`
- `script config should be a string or a nested array of strings up to 10 levels deep`

For example, if you use `"PRIVATE-TOKEN: ${PRIVATE_TOKEN}"` as part of a cURL command:

```yaml
pages-job:
  stage: deploy
  script:
    - curl --header 'PRIVATE-TOKEN: ${PRIVATE_TOKEN}' "https://gitlab.example.com/api/v4/projects"
  environment: production
```

The YAML parser thinks the `:` defines a YAML keyword, and outputs the
`Syntax is incorrect` error.

To use commands that contain a colon, you should wrap the whole command
in single quotes. You might need to change existing single quotes (`'`) into double quotes (`"`):

```yaml
pages-job:
  stage: deploy
  script:
    - 'curl --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" "https://gitlab.example.com/api/v4/projects"'
  environment: production
```

## Job does not fail when using `&&` in a script

If you use `&&` to combine two commands together in a single script line, the job
might return as successful, even if one of the commands failed. For example:

```yaml
job-does-not-fail:
  script:
    - invalid-command xyz && invalid-command abc
    - echo $?
    - echo "The job should have failed already, but this is executed unexpectedly."
```

The `&&` operator returns an exit code of `0` even though the two commands failed,
and the job continues to run. To force the script to exit when either command fails,
enclose the entire line in parentheses:

```yaml
job-fails:
  script:
    - (invalid-command xyz && invalid-command abc)
    - echo "The job failed already, and this is not executed."
```

## Multiline commands not preserved by folded YAML multiline block scalar

If you use the `- >` folded YAML multiline block scalar to split long commands,
additional indentation causes the lines to be processed as individual commands.

For example:

```yaml
script:
  - >
    RESULT=$(curl --silent
      --header
        "Authorization: Bearer $CI_JOB_TOKEN"
      "${CI_API_V4_URL}/job"
    )
```

This fails as the indentation causes the line breaks to be preserved:

```plaintext
$ RESULT=$(curl --silent # collapsed multi-line command
curl: no URL specified!
curl: try 'curl --help' or 'curl --manual' for more information
/bin/bash: line 149: --header: command not found
/bin/bash: line 150: https://gitlab.example.com/api/v4/job: No such file or directory
```

Resolve this by either:

- Removing the extra indentation:

  ```yaml
  script:
    - >
      RESULT=$(curl --silent
      --header
      "Authorization: Bearer $CI_JOB_TOKEN"
      "${CI_API_V4_URL}/job"
      )
  ```

- Modifying the script so the extra line breaks are handled, for example using shell line continuation:

  ```yaml
  script:
    - >
      RESULT=$(curl --silent \
        --header \
          "Authorization: Bearer $CI_JOB_TOKEN" \
        "${CI_API_V4_URL}/job")
  ```

## Job log output is not formatted as expected or contains unexpected characters

Sometimes the formatting in the job log displays incorrectly with tools that rely
on the `TERM` environment variable for coloring or formatting. For example, with the `mypy` command:

![Example output](img/incorrect_log_rendering_v16_5.png)

GitLab Runner runs the container's shell in non-interactive mode, so the shell's `TERM`
environment variable is set to `dumb`. To fix the formatting for these tools, you can:

- Add an additional script line to set `TERM=ansi` in the shell's environment before running the command.
- Add a `TERM` [CI/CD variable](../variables/_index.md) with a value of `ansi`.

## `after_script` section execution stops early and incorrect `$CI_JOB_STATUS` values

In GitLab Runner 16.9.0 to 16.11.0:

- The `after_script` section execution sometimes stops too early.
- The status of the `$CI_JOB_STATUS` predefined variable is
  [incorrectly set as `failed` while the job is canceling](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37485).

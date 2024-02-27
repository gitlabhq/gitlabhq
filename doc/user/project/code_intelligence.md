---
stage: Create
group: Code Review
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Code Intelligence

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Code Intelligence adds code navigation features common to interactive
development environments (IDE), including:

- Type signatures and symbol documentation.
- Go-to definition.

Code Intelligence is built into GitLab and powered by [LSIF](https://lsif.dev/)
(Language Server Index Format), a file format for precomputed code
intelligence data. GitLab processes one LSIF file per project, and
Code Intelligence does not support different LSIF files per branch.
Follow epic [#4212, Code intelligence enhancements](https://gitlab.com/groups/gitlab-org/-/epics/4212)
for progress on upcoming enhancements.

NOTE:
You can automate this feature in your applications by using [Auto DevOps](../../topics/autodevops/index.md).

## Configuration

Enable code intelligence for a project by adding a GitLab CI/CD job to the project's
`.gitlab-ci.yml` which generates the LSIF artifact:

```yaml
code_navigation:
  image: sourcegraph/lsif-go:v1
  allow_failure: true # recommended
  script:
    - lsif-go
  artifacts:
    reports:
      lsif: dump.lsif
```

The generated LSIF file size might be limited by
the [artifact application limits (`ci_max_artifact_size_lsif`)](../../administration/instance_limits.md#maximum-file-size-per-type-of-artifact),
default to 100 MB (configurable by an instance administrator).

After the job succeeds, code intelligence data can be viewed while browsing the code:

![Code intelligence](img/code_intelligence_v13_4.png)

## Find references

To find where a particular object is being used, you can see links to specific lines of code
under the **References** tab:

![Find references](img/code_intelligence_find_references_v13_3.png)

## Language support

Generating an LSIF file requires a language server indexer implementation for the
relevant language. View a complete list of [available LSIF indexers](https://lsif.dev/#implementations-server) on their website and
refer to their documentation to see how to generate an LSIF file for your specific language.

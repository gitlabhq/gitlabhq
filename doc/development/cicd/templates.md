---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, concepts, howto
---

# Development guide for GitLab CI/CD templates

This document explains how to develop [GitLab CI/CD templates](../../ci/examples/README.md).

## Place the template file in a relevant directory

All template files reside in the `lib/gitlab/ci/templates` directory, and are categorized by the following sub-directories:

| Sub-directory  | Content                                            | [Selectable in UI](#make-sure-the-new-template-can-be-selected-in-ui) |
|----------------|----------------------------------------------------|-----------------------------------------------------------------------|
| `/AWS/*`       | Cloud Deployment (AWS) related jobs                | No      |
| `/Jobs/*`      | Auto DevOps related jobs                           | No      |
| `/Pages/*`     | Static site generators for GitLab Pages (for example Jekyll) | Yes     |
| `/Security/*`  | Security related jobs                              | Yes     |
| `/Terraform/*` | Infrastructure as Code related templates           | No      |
| `/Verify/*`    | Verify/testing related jobs                        | Yes     |
| `/Workflows/*` | Common uses of the `workflow:` keyword             | No      |
| `/*` (root)    | General templates                                  | Yes     |

## Criteria

The file must follow the [`.gitlab-ci.yml` syntax](../../ci/yaml/README.md).
Verify it's valid by pasting it into the CI lint tool at `https://gitlab.com/gitlab-org/gitlab/-/ci/lint`.

Also, all templates must be named with the `*.gitlab-ci.yml` suffix.

### Backward compatibility

A template might be dynamically included with the `include:template:` keyword. If
you make a change to an *existing* template, you **must** make sure that it won't break
CI/CD in existing projects.

For example, changing a job name in a template could break pipelines in an existing project.
Let's say there is a template named `Performance.gitlab-ci.yml` with the following content:

```yaml
performance:
  image: registry.gitlab.com/gitlab-org/verify-tools/performance:v0.1.0
  script: ./performance-test $TARGET_URL
```

and users include this template with passing an argument to the `performance` job.
This can be done by specifying the environment variable `TARGET_URL` in _their_ `.gitlab-ci.yml`:

```yaml
include:
  template: Performance.gitlab-ci.yml

performance:
  variables:
    TARGET_URL: https://awesome-app.com
```

If the job name `performance` in the template is renamed to `browser-performance`,
user's `.gitlab-ci.yml` will immediately cause a lint error because there
are no such jobs named `performance` in the included template anymore. Therefore,
users have to fix their `.gitlab-ci.yml` that could annoy their workflow.

Please read [versioning](#versioning) section for introducing breaking change safely.

## Versioning

Versioning allows you to introduce a new template without modifying the existing
one. This process is useful when we need to introduce a breaking change,
but don't want to affect the existing projects that depends on the current template.

### Stable version

A stable CI/CD template is a template that only introduces breaking changes in major
release milestones. Name the stable version of a template as `<template-name>.gitlab-ci.yml`,
for example `Jobs/Deploy.gitlab-ci.yml`.

You can make a new stable template by copying [the latest template](#latest-version)
available in a major milestone release of GitLab like `13.0`. All breaking changes
must be announced in a blog post before the official release, for example
[GitLab.com is moving to 13.0, with narrow breaking changes](https://about.gitlab.com/releases/2020/05/06/gitlab-com-13-0-breaking-changes/)

You can change a stable template version in a minor GitLab release like `13.1` if:

- The change is not a [breaking change](#backward-compatibility).
- The change is ported to [the latest template](#latest-version), if one exists.

### Latest version

Templates marked as `latest` can be updated in any release, even with
[breaking changes](#backward-compatibility). Add `.latest` to the template name if
it's considered the latest version, for example `Jobs/Deploy.latest.gitlab-ci.yml`.

When you introduce [a breaking change](#backward-compatibility),
you **must** test and document [the upgrade path](#verify-breaking-changes).
In general, we should not promote the latest template as the best option, as it could surprise users with unexpected problems.

If the `latest` template does not exist yet, you can copy [the stable template](#stable-version).

### How to include an older stable template

Users may want to use an older [stable template](#stable-version) that is not bundled
in the current GitLab package. For example, the stable templates in GitLab v13.0 and
GitLab v14.0 could be so different that a user will want to continue using the v13.0 template even
after upgrading to GitLab 14.0.

You can add a note in the template or in documentation explaining how to use `include:remote`
to include older template versions. If other templates are included with `include: template`,
they can be combined with the `include: remote`:

```yaml
# To use the v13 stable template, which is not included in v14, fetch the specific
# template from the remote template repository with the `include:remote:` keyword.
# If you fetch from the GitLab canonical project, use the following URL format:
# https://gitlab.com/gitlab-org/gitlab/-/raw/<version>/lib/gitlab/ci/templates/<template-name>
include:
  - template: Auto-DevOps.gitlab-ci.yml
  - remote: https://gitlab.com/gitlab-org/gitlab/-/raw/v13.0.1-ee/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml
```

### Further reading

There is an [open issue](https://gitlab.com/gitlab-org/gitlab/-/issues/17716) about
introducing versioning concepts in GitLab CI Templates. You can check that issue to
follow the progress.

## Testing

Each CI/CD template must be tested in order to make sure that it's safe to be published.

### Manual QA

It's always good practice to test the template in a minimal demo project.
To do so, please follow the following steps:

1. Create a public sample project on <https://gitlab.com>.
1. Add a `.gitlab-ci.yml` to the project with the proposed template.
1. Run pipelines and make sure that everything runs properly, in all possible cases
   (merge request pipelines, schedules, and so on).
1. Link to the project in the description of the merge request that is adding a new template.

This is useful information for reviewers to make sure the template is safe to be merged.

### Make sure the new template can be selected in UI

Templates located under some directories are also [selectable in the **New file** UI](#place-the-template-file-in-a-relevant-directory).
When you add a template into one of those directories, make sure that it correctly appears in the dropdown:

![CI/CD template selection](img/ci_template_selection_v13_1.png)

### Write an RSpec test

You should write an RSpec test to make sure that pipeline jobs will be generated correctly:

1. Add a test file at `spec/lib/gitlab/ci/templates/<template-category>/<template-name>_spec.rb`
1. Test that pipeline jobs are properly created via `Ci::CreatePipelineService`.

### Verify breaking changes

When you introduce a breaking change to [a `latest` template](#latest-version),
you must:

1. Test the upgrade path from [the stable template](#stable-version).
1. Verify what kind of errors users will encounter.
1. Document it as a troubleshooting guide.

This information will be important for users when [a stable template](#stable-version)
is updated in a major version GitLab release.

## Security

A template could contain malicious code. For example, a template that contains the `export` shell command in a job
might accidentally expose project secret variables in a job log.
If you're unsure if it's secure or not, you need to ask security experts for cross-validation.

## Contribute CI/CD Template Merge Requests

After your CI/CD Template MR is created and labeled with `ci::templates`, DangerBot suggests one reviewer and one maintainer that can review your code. When your merge request is ready for review, please `@mention` the reviewer and ask them to review your CI/CD Template changes. See details in the merge request that added [a DangerBot task for CI/CD Template MRs](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44688).

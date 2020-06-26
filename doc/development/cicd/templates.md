# Development guide for GitLab CI/CD templates

This document explains how to develop [GitLab CI/CD templates](../../ci/examples/README.md).

## Place the template file in a relevant directory

All template files reside in the `lib/gitlab/ci/templates` directory, and are categorized by the following sub-directories:

| Sub-directroy | Content                                                      | [Selectable in UI](#make-sure-the-new-template-can-be-selected-in-ui) |
|---------------|--------------------------------------------------------------|-----------------------------------------------------------------------|
| `/Jobs/*`     | Auto DevOps related jobs                                     | Yes                                                                   |
| `/Pages/*`    | Static site generators for GitLab Pages (for example Jekyll) | Yes                                                                   |
| `/Security/*` | Security related jobs                                        | Yes                                                                   |
| `/Verify/*`   | Verify/testing related jobs                                  | Yes                                                                   |
| `/Worklows/*` | Common uses of the `workflow:` keyword                       | No                                                                    |
| `/*` (root)   | General templates                                            | Yes                                                                   |

## Criteria

The file must follow the [`.gitlab-ci.yml` syntax](../../ci/yaml/README.md).
Verify it's valid by pasting it into the CI lint tool at `https://gitlab.com/gitlab-org/gitlab/-/ci/lint`.

Also, all templates must be named with the `*.gitlab-ci.yml` suffix.

### Backward compatibility

A template might be dynamically included with the `include:template:` keyword. If
you make a change to an *existing* template, you must make sure that it won't break
CI/CD in existing projects.

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

## Security

A template could contain malicious code. For example, a template that contains the `export` shell command in a job
might accidentally expose project secret variables in a job log.
If you're unsure if it's secure or not, you need to ask security experts for cross-validation.

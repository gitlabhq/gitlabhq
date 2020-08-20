---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers"
type: reference
---

# Code Intelligence

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/1576) in GitLab 13.1.

Code Intelligence adds code navigation features common to interactive
development environments (IDE), including:

- Type signatures and symbol documentation.
- Go-to definition.

Code Intelligence is built into GitLab and powered by [LSIF](https://lsif.dev/)
(Language Server Index Format), a file format for precomputed code
intelligence data.

## Configuration

Enable code intelligence for a project by adding a GitLab CI/CD job to the project's
`.gitlab-ci.yml` which will generate the LSIF artifact:

```yaml
code_navigation:
  image: golang:1.14.0
  allow_failure: true # recommended
  script:
    - go get github.com/sourcegraph/lsif-go/cmd/lsif-go
    - lsif-go
  artifacts:
    reports:
      lsif: dump.lsif
```

The generated LSIF file must be less than 170MiB.

After the job succeeds, code intelligence data can be viewed while browsing the code:

![Code intelligence](img/code_intelligence_v13_1.png)

## Find references

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217392) in GitLab 13.2.
> - [Became enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/225621) on GitLab 13.3.
> - It's enabled on GitLab.com.

To find where a particular object is being used, you can see links to specific lines of code
under the **References** tab:

![Find references](img/code_intelligence_find_references_v13_3.png)

### Enable or disable find references

Find references is under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can opt to disable it for your instance.

To disable it:

```ruby
Feature.disable(:code_navigation_references)
```

To enable it:

```ruby
Feature.enable(:code_navigation_references)
```

## Language support

Generating an LSIF file requires a language server indexer implementation for the
relevant language.

| Language | Implementation |
|---|---|
| Go | [sourcegraph/lsif-go](https://github.com/sourcegraph/lsif-go) |
| JavaScript | [sourcegraph/lsif-node](https://github.com/sourcegraph/lsif-node) |
| TypeScript | [sourcegraph/lsif-node](https://github.com/sourcegraph/lsif-node) |

View a complete list of [available LSIF indexers](https://lsif.dev/#implementations-server) on their website and
refer to their documentation to see how to generate an LSIF file for your specific language.

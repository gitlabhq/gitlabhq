---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: reference
---

# Parent-child pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16094) in GitLab 12.7.

As pipelines grow more complex, a few related problems start to emerge:

- The staged structure, where all steps in a stage must be completed before the first
  job in next stage begins, causes arbitrary waits, slowing things down.
- Configuration for the single global pipeline becomes very long and complicated,
  making it hard to manage.
- Imports with [`include`](yaml/README.md#include) increase the complexity of the configuration, and create the potential
  for namespace collisions where jobs are unintentionally duplicated.
- Pipeline UX can become unwieldy with so many jobs and stages to work with.

Additionally, sometimes the behavior of a pipeline needs to be more dynamic. The ability
to choose to start sub-pipelines (or not) is a powerful ability, especially if the
YAML is dynamically generated.

![Parent pipeline graph expanded](img/parent_pipeline_graph_expanded_v12_6.png)

Similarly to [multi-project pipelines](multi_project_pipelines.md), a pipeline can trigger a
set of concurrently running child pipelines, but within the same project:

- Child pipelines still execute each of their jobs according to a stage sequence, but
  would be free to continue forward through their stages without waiting for unrelated
  jobs in the parent pipeline to finish.
- The configuration is split up into smaller child pipeline configurations, which are
  easier to understand. This reduces the cognitive load to understand the overall configuration.
- Imports are done at the child pipeline level, reducing the likelihood of collisions.
- Each pipeline has only relevant steps, making it easier to understand what's going on.

Child pipelines work well with other GitLab CI/CD features:

- Use [`only: changes`](yaml/README.md#onlychangesexceptchanges) to trigger pipelines only when
  certain files change. This is useful for monorepos, for example.
- Since the parent pipeline in `.gitlab-ci.yml` and the child pipeline run as normal
  pipelines, they can have their own behaviors and sequencing in relation to triggers.

See the [`trigger:`](yaml/README.md#trigger) keyword documentation for full details on how to
include the child pipeline configuration.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Parent-Child Pipelines feature demo](https://youtu.be/n8KpBSqZNbk).

## Examples

The simplest case is [triggering a child pipeline](yaml/README.md#trigger) using a
local YAML file to define the pipeline configuration. In this case, the parent pipeline will
trigger the child pipeline, and continue without waiting:

```yaml
microservice_a:
  trigger:
    include: path/to/microservice_a.yml
```

You can include multiple files when composing a child pipeline:

```yaml
microservice_a:
  trigger:
    include:
      - local: path/to/microservice_a.yml
      - template: Security/SAST.gitlab-ci.yml
```

NOTE: **Note:**
The max number of entries that are accepted for `trigger:include:` is three.

Similar to [multi-project pipelines](multi_project_pipelines.md#mirroring-status-from-triggered-pipeline),
we can set the parent pipeline to depend on the status of the child pipeline upon completion:

```yaml
microservice_a:
  trigger:
    include:
      - local: path/to/microservice_a.yml
      - template: Security/SAST.gitlab-ci.yml
    strategy: depend
```

## Merge Request child pipelines

To trigger a child pipeline as a [Merge Request Pipeline](merge_request_pipelines/index.md) we need to:

- Set the trigger job to run on merge requests:

```yaml
# parent .gitlab-ci.yml
microservice_a:
  trigger:
    include: path/to/microservice_a.yml
  rules:
    - if: $CI_MERGE_REQUEST_ID
```

- Configure the child pipeline by either:

  - Setting all jobs in the child pipeline to evaluate in the context of a merge request:

    ```yaml
    # child path/to/microservice_a.yml
    workflow:
      rules:
        - if: $CI_MERGE_REQUEST_ID

    job1:
      script: ...

    job2:
      script: ...
    ```

  - Alternatively, setting the rule per job. For example, to create only `job1` in
    the context of merge request pipelines:

    ```yaml
    # child path/to/microservice_a.yml
    job1:
      script: ...
      rules:
        - if: $CI_MERGE_REQUEST_ID

    job2:
      script: ...
    ```

## Dynamic child pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/35632) in GitLab 12.9.

Instead of running a child pipeline from a static YAML file, you can define a job that runs
your own script to generate a YAML file, which is then [used to trigger a child pipeline](yaml/README.md#trigger-child-pipeline-with-generated-configuration-file).

This technique can be very powerful in generating pipelines targeting content that changed or to
build a matrix of targets and architectures.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Create child pipelines using dynamically generated configurations](https://youtu.be/nMdfus2JWHM).

We also have an [example project using Dynamic Child Pipelines with Jsonnet](https://gitlab.com/gitlab-org/project-templates/jsonnet) which shows how to use a data templating language to generate your `.gitlab-ci.yml` at runtime. You could use a similar process for other templating languages like [Dhall](https://dhall-lang.org/) or [`ytt`](https://get-ytt.io/).

In GitLab 12.9, the child pipeline could fail to be created in certain cases, causing the parent pipeline to fail.
This is [resolved in GitLab 12.10](https://gitlab.com/gitlab-org/gitlab/-/issues/209070).

## Nested child pipelines

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29651) in GitLab 13.4.
> - It's [deployed behind a feature flag](../user/feature_flags.md), enabled by default.
> - It's enabled on GitLab.com.
> - It's recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#enable-or-disable-nested-child-pipelines). **(CORE ONLY)**

Parent and child pipelines were introduced with a maximum depth of one level of child
pipelines, which was later increased to two. A parent pipeline can trigger many child
pipelines, and these child pipelines can trigger their own child pipelines. It's not
possible to trigger another level of child pipelines.

### Enable or disable nested child pipelines **(CORE ONLY)**

Nested child pipelines with a depth of two are under development but ready for
production use. This feature is deployed behind a feature flag that is **enabled by default**.

[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md)
can opt to disable it.

To enable it:

```ruby
Feature.enable(:ci_child_of_child_pipeline)
```

To disable it:

```ruby
Feature.disable(:ci_child_of_child_pipeline)
```

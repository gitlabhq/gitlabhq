---
owning-stage: "~devops::verify"
description: The Syntactic Sugar extensions to the Step Definition
---

# The Syntactic Sugar extensions to the Step Definition

[The Step Definition](step-definition.md) describes a minimal required syntax
to be supported. To aid common workflows the following syntactic sugar is used
to extend different parts of that document.

## Syntactic Sugar for Step Reference

Each of syntactic sugar extensions is converted into the simple
[step reference](step-definition.md#steps-that-use-other-steps).

### Easily execute scripts in a target environment

`script:` is a shorthand syntax to aid execution of simple scripts, which cannot be used with `step:`
and is run by an externally stored step component provided by GitLab.

The GitLab-provided step component performs shell auto-detection unless overwritten,
similar to how GitLab Runner does that now: based on a running system.

`inputs:` and `env:` can be used for additional control of some aspects of that step component.

For example:

```yaml
spec:
---
type: steps
steps:
  - script: bundle exec rspec
  - script: bundle exec rspec
    inputs:
      shell: sh  # Force runner to use `sh` shell, instead of performing auto-detection
```

This syntax example translates into the following equivalent syntax for
execution by the Step Runner:

```yaml
spec:
---
type: steps
steps:
  - step: gitlab.com/gitlab-org/components/steps/script@v1.0
    inputs:
      script: bundle exec rspec
  - step: gitlab.com/gitlab-org/components/steps/script@v1.0
    inputs:
      script: bundle exec rspec
      shell: sh  # Force runner to use `sh` shell, instead of performing auto-detection
```

This syntax example is **invalid** (and ambiguous) because the `script:` and `step:` cannot be used together:

```yaml
spec:
---
type: steps
steps:
  - step: gitlab.com/my-component/ruby/install@v1.0
    script: bundle exec rspec
```

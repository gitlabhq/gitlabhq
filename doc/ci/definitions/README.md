## CI/CD Definitions

### Pipelines

A pipeline is a group of [builds] that get executed in [stages] (batches). All of
the builds in a stage are executed in parallel (if there are enough concurrent
[runners]), and if they all succeed, the pipeline moves on to the next stage. If
one of the builds fails, the next stage is not (usually) executed.

### Builds

Builds are runs of [jobs]. Not to be confused with a `build` stage.

### Jobs

Jobs are the basic work unit of CI/CD. Jobs are used to create [builds], which are
then picked up by [Runners] and executed within the environment of the Runner.
Each job is run independently from each other.

### Runners

A runner is an isolated (virtual) machine that picks up builds through the
coordinator API of GitLab CI. A runner can be specific to a certain project or
serve any project in GitLab CI. A runner that serves all projects is called a
shared runner.

### Stages

Stages allow [jobs] to be grouped into parallel and sequential [builds]. Builds
of the same stage are executed in parallel and builds of the next stage are run
after the jobs from the previous stage complete successfully. Stages allow for
flexible multi-stage [pipelines]. By default [pipelines] have `build`, `test`
and `deploy` stages, but these can be defined in `.gitlab-ci.yml`. If a job
doesn't specify a stage, the job is assigned to the test stage.

### Environments

Environments are places where code gets deployed, such as staging or production.
CI/CD [Pipelines] usually have one or more deploy stages with [jobs] that do
[deployments] to an environment.

### Deployments

Deployments are created when [jobs] deploy versions of code to [environments].

[pipelines]: #pipelines
[builds]: #builds
[runners]: #runners
[jobs]: #jobs
[stages]: #stages
[environments]: #environments
[deployments]: #deployments

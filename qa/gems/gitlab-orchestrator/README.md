# `orchestrator`

`orchestrator` is a CLI tool that supports setting up and deploying:
- [Cloud Native GitLab](https://gitlab.com/gitlab-org/build/CNG) using the official [GitLab Chart](https://gitlab.com/gitlab-org/charts/gitlab).
- [Omnibus GitLab](https://docs.gitlab.com/install/docker/) instances using Docker.

## Usage

`orchestrator` is an internal gem; it is not published on [rubygems](https://rubygems.org/). Run `orchestrator` by prefixing commands with
`bundle exec` within its directory, for example:

```shell
$ bundle exec orchestrator help

Commands:
  orchestrator create [SUBCOMMAND]   # Manage deployment related object creation
  orchestrator destroy [SUBCOMMAND]  # Manage deployment related object cleanup
  orchestrator doctor                # Validate presence of all required system dependencies
  orchestrator help [COMMAND]        # Describe available commands or one specific command
  orchestrator log [SUBCOMMAND]      # Manage deployment related logs
  orchestrator version               # Print orchestrator version
```

### Example commands

#### 1) Create a Cloud Native GitLab deployment (Helm-based)

```shell
$ bundle exec orchestrator create deployment kind
```

This command spins up a Kubernetes cluster using [kind](https://kind.sigs.k8s.io/) and deploys GitLab via the Helm chart.

#### 2) Create a Docker-based GitLab Omnibus instance

```shell
$ bundle exec orchestrator create instance gitlab
```

This command launches a local container using the GitLab Docker image.

### Environment variables

It is possible to configure certain options via environment variables. Following environment variables are supported:

* `ORCHESTRATOR_FORCE_COLOR` - force color output in case support is not detected properly (useful for CI executions)
* `CNG_HELM_REPOSITORY_CACHE` - custom helm repository cache folder. Equivalent to global `--repository-cache` flag of `helm` command

## Add new deployments

The main feature `orchestrator` is to programmatically manage different deployment type configurations and setup. To implement new deployment configuration:

1. Add a new subcommand method to the [`Deployment`](lib/gitlab/cng/commands/subcommands/deployment.rb) class. This allows you to to define your own input
   arguments and documentation.
1. Define a configuration class based on the [`Base`](lib/gitlab/cng/lib/deployment/configurations/_base.rb) configuration class. You can implement:
   - `pre-deployment` setup: optional setup steps that are executed before installing the `GitLab` instance.
   - `post-deployment` setup: optional setup steps that are executed after instance of `GitLab` has been installed.
   - `helm` values: set of values to apply during installation.
1. Define a cleanup class based on the [`Base`](lib/gitlab/cng/lib/deployment/configurations/cleanup/_base.rb) cleanup class. Implement a single method
   that deletes all objects created by `pre-deployment` and `post-deployment` setup.

All different options for `GitLab` deployment on `Kubernetes` cluster are described in [GitLab Helm chart](https://docs.gitlab.com/charts/) documentation page.

## Tips

### kubectl context

`orchestrator` CLI uses [`kubectl`](https://github.com/kubernetes/kubectl) and [Helm](https://github.com/helm/helm) to perform all `kubernetes`-related
operations. When running a deployment, [current context](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_config/kubectl_config_current-context/)
is always used. If non-default arguments are used when running the deployment, make sure current context points to the cluster where the deployment should be executed.

### Shell integration

To make `orchestrator` globally available in your shell without the need to run the commands from a specific folder and prefixed with `bundle exec`, add the following
function to your shell's configuration file (for example,`.zshrc` or `.bash_profile`):

```shell
function orchestrator() {
  (cd $PATH_TO_GITLAB_REPO/gems/gitlab-orchestrator && BUNDLE_AUTO_INSTALL=true bundle exec orchestrator "$@")
}
```

## Troubleshooting

### Helm deployment

Because `orchestrator` tool essentially wraps `helm upgrade --install` command, official [Troubleshooting the GitLab chart](https://docs.gitlab.com/charts/troubleshooting) guide can be used for troubleshooting deployment failures.

### CI setup

Documentation on where to find environment logs and other useful information for troubleshooting failures on CI can be found in [test pipelines](../../../doc/development/testing_guide/end_to_end/test_pipelines.md#e2etest-on-cng) documentation section.

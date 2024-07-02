# `cng`

`cng` is a CLI tool that supports setting up and deploying [Cloud Native GitLab](https://gitlab.com/gitlab-org/build/CNG) builds
using the official [GitLab Chart](https://gitlab.com/gitlab-org/charts/gitlab).

## Usage

`cng` is internal gem so it is not published to [rubygems](https://rubygems.org/). Run `cng` by prefixing commands with
`bundle exec` within its directory.

```shell
$ bundle exec cng
Commands:
  cng create [SUBCOMMAND]   # Manage deployment related object creation
  cng destroy [SUBCOMMAND]  # Manage deployment related object cleanup
  cng doctor                # Validate presence of all required system dependencies
  cng help [COMMAND]        # Describe available commands or one specific command
  cng log [SUBCOMMAND]      # Manage deployment related logs
  cng version               # Print cng orchestrator version
```

## Add new deployments

The main feature `cng` is to programmatically manage different deployment type configurations and setup. To implement new deployment configuration:

1. Add a new subcommand method to the [`Deployment`](lib/gitlab/cng/commands/subcommands/deployment.rb) class. This allows you to to define your own input
   arguments and documentation.
1. Define a configuration class based on the [`Base`](lib/gitlab/cng/lib/deployment/configurations/_base.rb) configuration class. You can implement:
   - `pre-deployment` setup: optional setup steps that are executed before installing the `GitLab` instance.
   - `post-deployment` setup: optional setup steps that are executed after instance of `GitLab` has been installed.
   - `helm` values: set of values to apply during installation.
1. Define a cleanup class based on the [`Base`](lib/gitlab/cng/lib/deployment/configurations/cleanup/_base.rb) cleanup class. Implement a single method
   that deletes all objects created by `pre-deployment` and `post-deployment` setup.

## Tips

### kubectl context

`cng` CLI uses [`kubectl`](https://github.com/kubernetes/kubectl) and [Helm](https://github.com/helm/helm) to perform all `kubernetes`-related
operations. When running a deployment, [current context](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_config/kubectl_config_current-context/)
is always used. If non-default arguments are used when running the deployment, make sure current context points to the cluster where the deployment should be executed.

### Shell integration

To make `cng` globally available in your shell without the need to run the commands from a specific folder and prefixed with `bundle exec`, add the following
function to your shell's configuration file (for example,`.zshrc` or `.bash_profile`):

```shell
function cng() {
  (cd $PATH_TO_GITLAB_REPO/gems/gitlab-cng && BUNDLE_AUTO_INSTALL=true bundle exec cng "$@")
}
```

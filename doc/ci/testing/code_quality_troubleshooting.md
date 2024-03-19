---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Code Quality

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

When working with Code Quality, you might encounter the following issues.

## The code cannot be found and the pipeline runs always with default configuration

You are probably using a private runner with the Docker-in-Docker socket-binding configuration.
You should configure Code Quality checks to run on your worker as documented in
[Improve Code Quality performance with private runners](../../ci/testing/code_quality.md#improve-code-quality-performance-with-private-runners).

## Changing the default configuration has no effect

A common issue is that the terms `Code Quality` (GitLab specific) and `Code Climate`
(Engine used by GitLab) are very similar. You must add a **`.codeclimate.yml`** file
to change the default configuration, **not** a `.codequality.yml` file. If you use
the wrong filename, the [default `.codeclimate.yml`](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template)
is still used.

## No Code Quality report is displayed in a merge request

This can be due to multiple reasons:

- You just added the Code Quality job in your `.gitlab-ci.yml`. The report does not have anything to
  compare to yet, so no information can be displayed. It only displays after future merge requests
  have something to compare to.
- Your pipeline is not set to run the code quality job on your target branch. If there is no report
  generated from the target branch, your merge request branch reports have nothing to compare to. In this
  situation you get an error stating `Base pipeline codequality artifact not found`.
- The [`artifacts:expire_in`](../yaml/index.md#artifactsexpire_in) CI/CD setting can cause the Code
  Quality artifacts to expire faster than desired.
- The widgets use the pipeline of the latest commit to the target branch. If commits are made to the
  default branch that do not run the code quality job, this may cause the merge request widget to
  have no base report for comparison.
- If you use the [`REPORT_STDOUT` environment variable](https://gitlab.com/gitlab-org/ci-cd/codequality#environment-variables),
  no report file is generated and nothing displays in the merge request.

## Only a single Code Quality report is displayed, but more are defined

Code Quality automatically [combines multiple reports](../../ci/testing/code_quality.md#integrate-multiple-tools).

In GitLab 15.6 and earlier, Code Quality used only the artifact from the latest created job (with the largest job ID). Code Quality artifacts from earlier jobs were ignored.

## RuboCop errors

When using Code Quality jobs on a Ruby project, you can encounter problems running RuboCop.
For example, the following error can appear when using either a very recent or very old version
of Ruby:

```plaintext
/usr/local/bundle/gems/rubocop-0.52.1/lib/rubocop/config.rb:510:in `check_target_ruby':
Unknown Ruby version 2.7 found in `.ruby-version`. (RuboCop::ValidationError)
Supported versions: 2.1, 2.2, 2.3, 2.4, 2.5
```

This is caused by the default version of RuboCop used by the check engine not covering
support for the Ruby version in use.

To use a custom version of RuboCop that
[supports the version of Ruby used by the project](https://docs.rubocop.org/rubocop/compatibility.html#support-matrix),
you can [override the configuration through a `.codeclimate.yml` file](https://docs.codeclimate.com/docs/rubocop#using-rubocops-newer-versions)
created in the project repository.

For example, to specify using RuboCop release **0.67**:

```yaml
version: "2"
plugins:
  rubocop:
    enabled: true
    channel: rubocop-0-67
```

## No Code Quality appears on merge requests when using custom tool

If your merge requests do not show any Code Quality changes when using a custom tool, ensure that
the line property is an `integer`.

## Error: `Could not analyze code quality`

You might get the error:

```shell
error: (CC::CLI::Analyze::EngineFailure) engine pmd ran for 900 seconds and was killed
Could not analyze code quality for the repository at /code
```

If you enabled any of the Code Climate plugins, and the Code Quality CI/CD job fails with this
error message, it's likely the job takes longer than the default timeout of 900 seconds:

To work around this problem, set `TIMEOUT_SECONDS` to a higher value in your `.gitlab.-ci.yml` file.

For example:

```yaml
code_quality:
  variables:
    TIMEOUT_SECONDS: 3600
```

## Using Code Quality with Kubernetes CI executor

Code Quality requires a Docker in Docker setup to work. The Kubernetes executor already [has support for this](https://docs.gitlab.com/runner/executors/kubernetes.html#using-dockerdind).

To ensure Code Quality jobs can run on a Kubernetes executor:

- If you're using TLS to communicate with the Docker daemon, the executor [must be running in privileged mode](https://docs.gitlab.com/runner/executors/kubernetes.html#other-configtoml-settings). Additionally, the certificate directory must be [specified as a volume mount](../docker/using_docker_build.md#docker-in-docker-with-tls-enabled-in-kubernetes).
- It is possible that the DinD service doesn't start up fully before the Code Quality job starts. This is a limitation documented in
the [Kubernetes executor for GitLab Runner](https://docs.gitlab.com/runner/executors/kubernetes.html#docker-cannot-connect-to-the-docker-daemon-at-tcpdocker2375-is-the-docker-daemon-running) troubleshooting section.

## Error: `x509: certificate signed by unknown authority`

If you set the `CODE_QUALITY_IMAGE` to an image that is hosted in a Docker registry which uses a TLS
certificate that is not trusted, such as a self-signed certificate, you can see errors like the one
below:

```shell
$ docker pull --quiet "$CODE_QUALITY_IMAGE"
Error response from daemon: Get https://gitlab.example.com/v2/: x509: certificate signed by unknown authority
```

To fix this, configure the Docker daemon to [trust certificates](https://distribution.github.io/distribution/about/insecure/#use-self-signed-certificates)
by putting the certificate inside of the `/etc/docker/certs.d` directory.

This Docker daemon is exposed to the subsequent Code Quality Docker container in the
[GitLab Code Quality template](https://gitlab.com/gitlab-org/gitlab/-/blob/v13.8.3-ee/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml#L41)
and should be to exposed any other containers in which you want to have your certificate
configuration apply.

### Docker

If you have access to GitLab Runner configuration, add the directory as a
[volume mount](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#volumes-in-the-runnersdocker-section).

Replace `gitlab.example.com` with the actual domain of the registry.

Example:

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    volumes = ["/cache", "/etc/gitlab-runner/certs/gitlab.example.com.crt:/etc/docker/certs.d/gitlab.example.com/ca.crt:ro"]
```

### Kubernetes

If you have access to GitLab Runner configuration and the Kubernetes cluster,
you can [mount a ConfigMap](https://docs.gitlab.com/runner/executors/kubernetes.html#configmap-volumes).

Replace `gitlab.example.com` with the actual domain of the registry.

1. Create a ConfigMap with the certificate:

   ```shell
   kubectl create configmap registry-crt --namespace gitlab-runner --from-file /etc/gitlab-runner/certs/gitlab.example.com.crt
   ```

1. Update GitLab Runner `config.toml` to specify the ConfigMap:

   ```toml
   [[runners]]
     ...
     executor = "kubernetes"
     [runners.kubernetes]
       image = "alpine:3.12"
       privileged = true
       [[runners.kubernetes.volumes.config_map]]
         name = "registry-crt"
         mount_path = "/etc/docker/certs.d/gitlab.example.com/ca.crt"
         sub_path = "gitlab.example.com.crt"
   ```

## Failed to load Code Quality report

The Code Quality report can fail to load when there are issues parsing data from the artifact file.
To gain insight into the errors, you can execute a GraphQL query using the following steps:

1. Go to the pipeline details page.
1. Append `.json` to the URL.
1. Copy the `iid` of the pipeline.
1. Go to the [interactive GraphQL explorer](../../api/graphql/index.md#interactive-graphql-explorer).
1. Run the following query:

   ```graphql
   {
     project(fullPath: "<fullpath-to-your-project>") {
       pipeline(iid: "<iid>") {
         codeQualityReports {
           count
           nodes {
             line
             description
             path
             fingerprint
             severity
           }
           pageInfo {
             hasNextPage
             hasPreviousPage
             startCursor
             endCursor
           }
         }
       }
     }
   }
   ```

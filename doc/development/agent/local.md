---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Run the Kubernetes Agent locally **(PREMIUM SELF)**

You can run `kas` and `agentk` locally to test the [Kubernetes Agent](index.md) yourself.

1. Create a `cfg.yaml` file from the contents of
   [`config_example.yaml`](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/kascfg/config_example.yaml), or this example:

   ```yaml
   agent:
    listen:
       network: tcp
       address: 127.0.0.1:8150
       websocket: false
     gitops:
       poll_period: "10s"
   gitlab:
     address: http://localhost:3000
     authentication_secret_file: /Users/tkuah/code/ee-gdk/gitlab/.gitlab_kas_secret
   ```

1. Create a `token.txt`. This is the token for
   [the agent you created](../../user/clusters/agent/index.md#create-an-agent-record-in-gitlab). This file must not contain a newline character. You can create the file with this command:

   ```shell
   echo -n "<TOKEN>" > token.txt
   ```

1. Start the binaries with the following commands:

   ```shell
   # Need GitLab to start
   gdk start
   # Stop GDK's version of kas
   gdk stop gitlab-k8s-agent

   # Start kas
   bazel run //cmd/kas -- --configuration-file="$(pwd)/cfg.yaml"
   ```

1. In a new terminal window, run this command to start `agentk`:

   ```shell
   bazel run //cmd/agentk -- --kas-address=grpc://127.0.0.1:8150 --token-file="$(pwd)/token.txt"
   ```

You can also inspect the
[Makefile](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/Makefile)
for more targets.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
To learn more about how the repository is structured, see
[GitLab Kubernetes Agent repository overview](https://www.youtube.com/watch?v=j8CyaCWroUY).

## Run tests locally

You can run all tests, or a subset of tests, locally.

- **To run all tests**: Run the command `make test`.
- **To run all test targets in the directory**: Run the command
  `bazel test //internal/module/gitops/server:all`.

  You can use `*` in the command, instead of `all`, but it must be quoted to
  avoid shell expansion: `bazel test '//internal/module/gitops/server:*'`.
- **To run all tests in a directory and its subdirectories**: Run the command
  `bazel test //internal/module/gitops/server/...`.

### Run specific test scenarios

To run only a specific test scenario, you need the directory name and the target
name of the test. For example, to run the tests at
`internal/module/gitops/server/module_test.go`, the `BUILD.bazel` file that
defines the test's target name lives at `internal/module/gitops/server/BUILD.bazel`.
In the latter, the target name is defined like:

```bazel
go_test(
    name = "server_test",
    size = "small",
    srcs = [
        "module_test.go",
```

The target name is `server_test` and the directory is `internal/module/gitops/server/`.
Run the test scenario with this command:

```shell
bazel test //internal/module/gitops/server:server_test
```

### Additional resources

- Bazel documentation about [specifying targets to build](https://docs.bazel.build/versions/master/guide.html#specifying-targets-to-build).
- [The Bazel query](https://docs.bazel.build/versions/master/query.html)
- [Bazel query how to](https://docs.bazel.build/versions/master/query-how-to.html)

## KAS QA tests

This section describes how to run KAS tests against different GitLab environments based on the
[GitLab QA orchestrator](https://gitlab.com/gitlab-org/gitlab-qa).

### Status

The `kas` QA tests currently have some limitations. You can run them manually on GDK, but they don't
run automatically with the nightly jobs against the live environment. See the section below
to learn how to run them against different environments.

### Prepare

Before performing any of these tests, if you have a `k3s` instance running, make sure to
stop it manually before running them. Otherwise, the tests might fail with the message
`failed to remove k3s cluster`.

You might need to specify the correct Agent image version that matches the `kas` image version. You can use the `GITLAB_AGENTK_VERSION` local environment for this.

### Against `staging`

1. Go to your local `qa/qa/service/cluster_provider/k3s.rb` and comment out
   [this line](https://gitlab.com/gitlab-org/gitlab/-/blob/5b15540ea78298a106150c3a1d6ed26416109b9d/qa/qa/service/cluster_provider/k3s.rb#L8) and
   [this line](https://gitlab.com/gitlab-org/gitlab/-/blob/5b15540ea78298a106150c3a1d6ed26416109b9d/qa/qa/service/cluster_provider/k3s.rb#L36).
   We don't allow local connections on `staging` as they require an admin user.
1. Ensure you don't have an `EE_LICENSE` environment variable set as this would force an admin login.
1. Go to your GDK root folder and `cd gitlab/qa`.
1. Login with your user in staging and create a group to be used as sandbox.
   Something like: `username-qa-sandbox`.
1. Create an access token for your user with the `api` permission.
1. Replace the values given below with your own and run:

   ```shell
   GITLAB_SANDBOX_NAME="<THE GROUP ID YOU CREATED ON STEP 2>" \
   GITLAB_QA_ACCESS_TOKEN="<THE ACCESS TOKEN YOU CREATED ON STEP 3>" \
   GITLAB_USERNAME="<YOUR STAGING USERNAME>" \
   GITLAB_PASSWORD="<YOUR STAGING PASSWORD>" \
   bundle exec bin/qa Test::Instance::All https://staging.gitlab.com -- --tag quarantine qa/specs/features/ee/api/7_configure/kubernetes/kubernetes_agent_spec.rb
   ```

### Against GDK

1. Go to your `qa/qa/fixtures/kubernetes_agent/agentk-manifest.yaml.erb` and comment out [this line](https://gitlab.com/gitlab-org/gitlab/-/blob/a55b78532cfd29426cf4e5b4edda81407da9d449/qa/qa/fixtures/kubernetes_agent/agentk-manifest.yaml.erb#L27) and uncomment [this line](https://gitlab.com/gitlab-org/gitlab/-/blob/a55b78532cfd29426cf4e5b4edda81407da9d449/qa/qa/fixtures/kubernetes_agent/agentk-manifest.yaml.erb#L28).
   GDK's `kas` listens on `grpc`, not on `wss`.
1. Go to the GDK's root folder and `cd gitlab/qa`.
1. On the contrary to staging, run the QA test in GDK as admin, which is the default choice. To do so, use the default sandbox group and run the command below. Make sure to adjust your credentials if necessary, otherwise, the test might fail:

   ```shell
   GITLAB_USERNAME=root \
   GITLAB_PASSWORD="5iveL\!fe" \
   GITLAB_ADMIN_USERNAME=root \
   GITLAB_ADMIN_PASSWORD="5iveL\!fe" \
   bundle exec bin/qa Test::Instance::All http://gdk.test:3000 -- --tag quarantine qa/specs/features/ee/api/7_configure/kubernetes/kubernetes_agent_spec.rb
   ```

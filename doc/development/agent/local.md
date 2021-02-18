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

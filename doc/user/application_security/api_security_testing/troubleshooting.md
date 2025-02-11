---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting
---

## API security testing job times out after N hours

For larger repositories, the API security testing job could time out on the [small hosted runner on Linux](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64), which is set per default. If this happens in your jobs, you should scale up to a [larger runner](performance.md#using-a-larger-runner).

See the following documentation sections for assistance:

- [Performance tuning and testing speed](performance.md)
- [Using a larger Runner](performance.md#using-a-larger-runner)
- [Excluding operations by path](configuration/customizing_analyzer_settings.md#exclude-paths)
- [Excluding slow operations](performance.md#excluding-slow-operations)

## API security testing job takes too long to complete

See [Performance Tuning and Testing Speed](performance.md)

## Error: `Error waiting for DAST API 'http://127.0.0.1:5000' to become available`

A bug exists in versions of the API security testing analyzer prior to v1.6.196 that can cause a background process to fail under certain conditions. The solution is to update to a newer version of the API security testing analyzer.

The version information can be found in the job details for the `dast_api` job.

If the issue is occurring with versions v1.6.196 or greater, contact Support and provide the following information:

1. Reference this troubleshooting section and ask for the issue to be escalated to the Dynamic Analysis Team.
1. The full console output of the job.
1. The `gl-api-security-scanner.log` file available as a job artifact. In the right-hand panel of the job details page, select the **Browse** button.
1. The `dast_api` job definition from your `.gitlab-ci.yml` file.

**Error message**

- In [GitLab 15.6 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/376078), `Error waiting for DAST API 'http://127.0.0.1:5000' to become available`
- In GitLab 15.5 and earlier, `Error waiting for API Security 'http://127.0.0.1:5000' to become available`.

## `Failed to start scanner session (version header not found)`

The API security testing engine outputs an error message when it cannot establish a connection with the scanner application component. The error message is shown in the job output window of the `dast_api` job. A common cause of this issue is changing the `APISEC_API` variable from its default.

**Error message**

- `Failed to start scanner session (version header not found).`

**Solution**

- Remove the `APISEC_API` variable from the `.gitlab-ci.yml` file. The value inherits from the API security testing CI/CD template. We recommend this method instead of manually setting a value.
- If removing the variable is not possible, check to see if this value has changed in the latest version of the [API security testing CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml). If so, update the value in the `.gitlab-ci.yml` file.

## `Failed to start session with scanner. Please retry, and if the problem persists reach out to support.`

The API security testing engine outputs an error message when it cannot establish a connection with the scanner application component. The error message is shown in the job output window of the `dast_api` job. A common cause for this issue is that the background component cannot use the selected port as it's already in use. This error can occur intermittently if timing plays a part (race condition). This issue occurs most often with Kubernetes environments when other services are mapped into the container causing port conflicts.

Before proceeding with a solution, it is important to confirm that the error message was produced because the port was already taken. To confirm this was the cause:

1. Go to the job console.

1. Look for the artifact `gl-api-security-scanner.log`. You can either download all artifacts by selecting **Download** and then search for the file, or directly start searching by selecting **Browse**.

1. Open the file `gl-api-security-scanner.log` in a text editor.

1. If the error message was produced because the port was already taken, you should see in the file a message like the following:

   - In [GitLab 15.5 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/367734):

     ```log
     Failed to bind to address http://127.0.0.1:5500: address already in use.
     ```

   - In GitLab 15.4 and earlier:

     ```log
     Failed to bind to address http://[::]:5000: address already in use.
     ```

The text `http://[::]:5000` in the previous message could be different in your case, for instance it could be `http://[::]:5500` or `http://127.0.0.1:5500`. As long as the remaining parts of the error message are the same, it is safe to assume the port was already taken.

If you did not find evidence that the port was already taken, check other troubleshooting sections which also address the same error message shown in the job console output. If there are no more options, feel free to [get support or request an improvement](_index.md#get-support-or-request-an-improvement) through the proper channels.

Once you have confirmed the issue was produced because the port was already taken. Then, [GitLab 15.5 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/367734) introduced the configuration variable `APISEC_API_PORT`. This configuration variable allows setting a fixed port number for the scanner background component.

**Solution**

1. Ensure your `.gitlab-ci.yml` file defines the configuration variable `APISEC_API_PORT`.
1. Update the value of `APISEC_API_PORT` to any available port number greater than 1024. We recommend checking that the new value is not in used by GitLab. See the full list of ports used by GitLab in [Package defaults](../../../administration/package_information/defaults.md#ports)

## `Application cannot determine the base URL for the target API`

The API security testing engine outputs an error message when it cannot determine the target API after inspecting the OpenAPI document. This error message is shown when the target API has not been set in the `.gitlab-ci.yml` file, it is not available in the `environment_url.txt` file, and it could not be computed using the OpenAPI document.

There is a order of precedence in which the API security testing engine tries to get the target API when checking the different sources. First, it tries to use the `APISEC_TARGET_URL`. If the environment variable has not been set, then the API security testing engine attempts to use the `environment_url.txt` file. If there is no file `environment_url.txt`, then the API security testing engine uses the OpenAPI document contents and the URL provided in `APISEC_OPENAPI` (if a URL is provided) to try to compute the target API.

The best-suited solution depends on whether or not your target API changes for each deployment. In static environments, the target API is the same for each deployment, in this case refer to the [static environment solution](#static-environment-solution). If the target API changes for each deployment a [dynamic environment solution](#dynamic-environment-solutions) should be applied.

## API security testing job excludes some paths from operations

If you find that some paths are being excluded from operations, make sure that:

- The variable `DAST_API_EXCLUDE_URLS` is not configured to exclude operations you want to test.
- The `consumes` array is defined and has a valid type in the target definition JSON file.

  For an example definition, see the [example project target definition file](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-example/-/blob/12e2b039d08208f1dd38a1e7c52b0bda848bb449/rest_target_openapi.json?plain=1#L13).

### Static environment solution

This solution is for pipelines in which the target API URL doesn't change (is static).

**Add environmental variable**

For environments where the target API remains the same, we recommend you specify the target URL by using the `APISEC_TARGET_URL` environment variable. In your `.gitlab-ci.yml`, add a variable `APISEC_TARGET_URL`. The variable must be set to the base URL of API testing target. For example:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OPENAPI: test-api-specification.json
```

### Dynamic environment solutions

In a dynamic environment your target API changes for each different deployment. In this case, there is more than one possible solution, we recommend you use the `environment_url.txt` file when dealing with dynamic environments.

**Use environment_url.txt**

To support dynamic environments in which the target API URL changes during each pipeline, API security testing engine supports the use of an `environment_url.txt` file that contains the URL to use. This file is not checked into the repository, instead it's created during the pipeline by the job that deploys the test target and collected as an artifact that can be used by later jobs in the pipeline. The job that creates the `environment_url.txt` file must run before the API security testing engine job.

1. Modify the test target deployment job adding the base URL in an `environment_url.txt` file at the root of your project.
1. Modify the test target deployment job collecting the `environment_url.txt` as an artifact.

Example:

```yaml
deploy-test-target:
  script:
    # Perform deployment steps
    # Create environment_url.txt (example)
    - echo http://${CI_PROJECT_ID}-${CI_ENVIRONMENT_SLUG}.example.org > environment_url.txt

  artifacts:
    paths:
      - environment_url.txt
```

## Use OpenAPI with an invalid schema

There are cases where the document is autogenerated with an invalid schema or cannot be edited manually in a timely manner. In those scenarios, the API security testing is able to perform a relaxed validation by setting the variable `APISEC_OPENAPI_RELAXED_VALIDATION`. We recommend providing a fully compliant OpenAPI document to prevent unexpected behaviors.

### Edit a non-compliant OpenAPI file

To detect and correct elements that don't comply with the OpenAPI specifications, we recommend using an editor. An editor commonly provides document validation, and suggestions to create a schema-compliant OpenAPI document. Suggested editors include:

| Editor | OpenAPI 2.0 | OpenAPI 3.0.x | OpenAPI 3.1.x |
| -- | -- | -- | -- |
| [Stoplight Studio](https://stoplight.io/solutions) | **{check-circle}** YAML, JSON | **{check-circle}** YAML, JSON | **{check-circle}** YAML, JSON |
| [Swagger Editor](https://editor.swagger.io/) | **{check-circle}** YAML, JSON | **{check-circle}** YAML, JSON | **{dotted-circle}** YAML, JSON |

If your OpenAPI document is generated manually, load your document in the editor and fix anything that is non-compliant. If your document is generated automatically, load it in your editor to identify the issues in the schema, then go to the application and perform the corrections based on the framework you are using.

### Enable OpenAPI relaxed validation

Relaxed validation is meant for cases when the OpenAPI document cannot meet OpenAPI specifications, but it still has enough content to be consumed by different tools. A validation is performed but less strictly in regards to document schema.

API security testing can still try to consume an OpenAPI document that does not fully comply with OpenAPI specifications. To instruct API security testing to perform a relaxed validation, set the variable `APISEC_OPENAPI_RELAXED_VALIDATION` to any value, for example:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_OPENAPI_RELAXED_VALIDATION: 'On'
```

## `No operation in the OpenAPI document is consuming any supported media type`

API security testing uses the specified media types in the OpenAPI document to generate requests. If no request can be created due to the lack of supported media types, then an error is thrown.

**Error message**

- `Error, no operation in the OpenApi document is consuming any supported media type. Check 'OpenAPI Specification' to check the supported media types.`

**Solution**

1. Review supported media types in the [OpenAPI Specification](configuration/enabling_the_analyzer.md#openapi-specification) section.
1. Edit your OpenAPI document, allowing at least a given operation to accept any of the supported media types. Alternatively, a supported media type could be set in the OpenAPI document level and get applied to all operations. This step may require changes in your application to ensure the supported media type is accepted by the application.

## Error: `The SSL connection could not be established, see inner exception.`

API security testing is compatible with a broad range of TLS configurations, including outdated protocols and ciphers.
Despite broad support, you might encounter connection errors, like this:

```plaintext
Error, error occurred trying to download `<URL>`:
There was an error when retrieving content from Uri:' <URL>'.
Error:The SSL connection could not be established, see inner exception.
```

This error occurs because API security testing could not establish a secure connection with the server at the given URL.

To resolve the issue:

If the host in the error message supports non-TLS connections, change `https://` to `http://` in your configuration.
For example, if an error occurs with the following configuration:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: https://test-deployment/
  APISEC_OPENAPI: https://specs/openapi.json
```

Change the prefix of `APISEC_OPENAPI` from `https://` to `http://`:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: https://test-deployment/
  APISEC_OPENAPI: http://specs/openapi.json
```

If you cannot use a non-TLS connection to access the URL, contact the Support team for help.

You can expedite the investigation with the [testssl.sh tool](https://testssl.sh/). From a machine with a bash shell and connectivity to the affected server:

1. Download the latest release `zip` or `tar.gz` file and extract from <https://github.com/drwetter/testssl.sh/releases>.
1. Run `./testssl.sh --log https://specs`.
1. Attach the log file to your support ticket.

## `ERROR: Job failed: failed to pull image`

This error message occurs when pulling an image from a container registry that requires authentication to access (it is not public).

In the job console output the error looks like:

```log
Running with gitlab-runner 15.6.0~beta.186.ga889181a (a889181a)
  on blue-2.shared.runners-manager.gitlab.com/default XxUrkriX
Resolving secrets
00:00
Preparing the "docker+machine" executor
00:06
Using Docker executor with image registry.gitlab.com/security-products/api-security:2 ...
Starting service registry.example.com/my-target-app:latest ...
Pulling docker image registry.example.com/my-target-app:latest ...
WARNING: Failed to pull image with policy "always": Error response from daemon: Get https://registry.example.com/my-target-app/manifests/latest: unauthorized (manager.go:237:0s)
ERROR: Job failed: failed to pull image "registry.example.com/my-target-app:latest" with specified policies [always]: Error response from daemon: Get https://registry.example.com/my-target-app/manifests/latest: unauthorized (manager.go:237:0s)
```

**Error message**

- In GitLab 15.9 and earlier, `ERROR: Job failed: failed to pull image` followed by `Error response from daemon: Get IMAGE: unauthorized`.

**Solution**

Authentication credentials are provided using the methods outlined in the [Access an image from a private container registry](../../../ci/docker/using_docker_images.md#access-an-image-from-a-private-container-registry) documentation section. The method used is dictated by your container registry provider and its configuration. If your using a container registry provided by a 3rd party, such as a cloud provider (Azure, Google Could (GCP), AWS and so on), check the providers documentation for information on how to authenticate to their container registries.

The following example uses the [statically defined credentials](../../../ci/docker/using_docker_images.md#use-statically-defined-credentials) authentication method. In this example the container registry is `registry.example.com` and image is `my-target-app:latest`.

1. Read how to [Determine your `DOCKER_AUTH_CONFIG` data](../../../ci/docker/using_docker_images.md#determine-your-docker_auth_config-data) to understand how to compute the variable value for `DOCKER_AUTH_CONFIG`. The configuration variable `DOCKER_AUTH_CONFIG` contains the Docker JSON configuration to provide the appropriate authentication information. For example, to access private container registry: `registry.example.com` with the credentials `abcdefghijklmn`, the Docker JSON looks like:

   ```json
   {
       "auths": {
           "registry.example.com": {
               "auth": "abcdefghijklmn"
           }
       }
   }
   ```

1. Add the `DOCKER_AUTH_CONFIG` as a CI/CD variable. Instead of adding the configuration variable directly in your `.gitlab-ci.yml`file you should create a project [CI/CD variable](../../../ci/variables/_index.md#for-a-project).
1. Rerun your job, and the statically-defined credentials are now used to sign in to the private container registry `registry.example.com`, and let you pull the image `my-target-app:latest`. If succeeded the job console shows an output like:

   ```log
   Running with gitlab-runner 15.6.0~beta.186.ga889181a (a889181a)
     on blue-4.shared.runners-manager.gitlab.com/default J2nyww-s
   Resolving secrets
   00:00
   Preparing the "docker+machine" executor
   00:56
   Using Docker executor with image registry.gitlab.com/security-products/api-security:2 ...
   Starting service registry.example.com/my-target-app:latest ...
   Authenticating with credentials from $DOCKER_AUTH_CONFIG
   Pulling docker image registry.example.com/my-target-app:latest ...
   Using docker image sha256:139c39668e5e4417f7d0eb0eeb74145ba862f4f3c24f7c6594ecb2f82dc4ad06 for registry.example.com/my-target-app:latest with digest registry.example.com/my-target-
   app@sha256:2b69fc7c3627dbd0ebaa17674c264fcd2f2ba21ed9552a472acf8b065d39039c ...
   Waiting for services to be up and running (timeout 30 seconds)...
   ```

## Differing vulnerability results between consecutive scans

It is possible that consecutive scans may return differing vulnerability findings in the absence of code or configuration changes. This is primarily due to the unpredictability associated with the target environment and its state, and the parallelization of requests sent by the scanner. Multiple requests are sent in parallel by the scanner to optimize scan time, which in turn means that the exact order the target server responds to the requests is not predetermined.

Timing attack vulnerabilities that are detected by the length of time between request and response such as OS Command or SQL Injections may be detected if the server is under load and unable to service responses to the tests within their given thresholds. The same scan executions when the server is not under load may not return positive findings for these vulnerabilities, leading to differing results. Profiling the target server, [Performance tuning and testing speed](performance.md), and establishing baselines for optimal server performance during testing may be helpful in identifying where false positives may appear due to the aforementioned factors.

## `sudo: The "no new privileges" flag is set, which prevents sudo from running as root.`

Starting with v5 of the analyzer, a non-root user is used by default. This requires the use of `sudo` when performing privileged operations.

This error occurs with a specific container daemon setup that prevents running containers from obtaining new permissions. In most settings, this is not the default configuration, it's something specifically configured, often as part of a security hardening guide.

**Error message**

This issue can be identified by the error message generated when a `before_script` or `APISEC_PRE_SCRIPT` is executed:

```shell
$ sudo apk add nodejs

sudo: The "no new privileges" flag is set, which prevents sudo from running as root.

sudo: If sudo is running in a container, you may need to adjust the container configuration to disable the flag.
```

**Solution**

This issue can be worked around in the following ways:

- Run the container as the `root` user. You should test this configuration as it may not work in all cases. This can be done by modifying the CICD configuration and checking the job output to make sure that `whoami` returns `root` and not `gitlab`. If `gitlab` is displayed, use another workaround. After testing has confirmed the change is successful, the `before_script` can be removed.

  ```yaml
  api_security:
    image:
      name: $SECURE_ANALYZERS_PREFIX/$APISEC_IMAGE:$APISEC_VERSION$APISEC_IMAGE_SUFFIX
      docker:
        user: root
   before_script:
     - whoami
  ```

  _Example job console output:_

  ```log
  Executing "step_script" stage of the job script
  Using docker image sha256:8b95f188b37d6b342dc740f68557771bb214fe520a5dc78a88c7a9cc6a0f9901 for registry.gitlab.com/security-products/api-security:5 with digest registry.gitlab.com/security-products/api-security@sha256:092909baa2b41db8a7e3584f91b982174772abdfe8ceafc97cf567c3de3179d1 ...
  $ whoami
  root
  $ /peach/analyzer-api-security
  17:17:14 [INF] API Security: Gitlab API Security
  17:17:14 [INF] API Security: -------------------
  17:17:14 [INF] API Security:
  17:17:14 [INF] API Security: version: 5.7.0
  ```

- Wrap the container and add any dependencies at build time. This option has the benefit of running with lower privileges than root which may be a requirement for some customers.

  1. Create a new `Dockerfile` that wraps the existing image.

     ```yaml
     ARG SECURE_ANALYZERS_PREFIX
     ARG APISEC_IMAGE
     ARG APISEC_VERSION
     ARG APISEC_IMAGE_SUFFIX
     FROM $SECURE_ANALYZERS_PREFIX/$APISEC_IMAGE:$APISEC_VERSION$APISEC_IMAGE_SUFFIX
     USER root

     RUN pip install ...
     RUN apk add ...

     USER gitlab
     ```

  1. Build the new image and push it to your local container registry before the API Security Testing job starts. The image should be removed after the `api_security` job has been completed.

     ```shell
     TARGET_NAME=apisec-$CI_COMMIT_SHA
     docker build -t $TARGET_IMAGE \
       --build-arg "SECURE_ANALYZERS_PREFIX=$SECURE_ANALYZERS_PREFIX" \
       --build-arg "APISEC_IMAGE=$APISEC_IMAGE" \
       --build-arg "APISEC_VERSION=$APISEC_VERSION" \
       --build-arg "APISEC_IMAGE_SUFFIX=$APISEC_IMAGE_SUFFIX" \
       .
     docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
     docker push $TARGET_IMAGE
     ```

  1. Extend the `api_security` job and use the new image name.

     ```yaml
     api_security:
       image: apisec-$CI_COMMIT_SHA
     ```

  1. Remove the temporary container from the registry. See [this documentation page for information on removing container images.](../../packages/container_registry/delete_container_registry_images.md)

- Change the GitLab Runner configuration, disabling the no-new-privileges flag. This could have security implications and should be discussed with your operations and security teams.

## `Index was outside the bounds of the array.    at Peach.Web.Runner.Services.RunnerOptions.GetHeaders()`

This error message indicates that the API security testing analyzer is unable to parse the value of the `APISEC_REQUEST_HEADERS` or `APISEC_REQUEST_HEADERS_BASE64` configuration variable.

**Error message**

This issue can be identified by two error messages. The first error message is seen in the job console output and the second in the `gl-api-security-scanner.log` file.

_Error message from job console:_

```log
05:48:38 [ERR] API Security: Testing failed: An unexpected exception occurred: Index was outside the bounds of the array.
```

_Error message from `gl_api_security-scanner.log`:_

```log
08:45:43.616 [ERR] <Peach.Web.Core.Services.WebRunnerMachine> Unexpected exception in WebRunnerMachine::Run()
System.IndexOutOfRangeException: Index was outside the bounds of the array.
   at Peach.Web.Runner.Services.RunnerOptions.GetHeaders() in /builds/gitlab-org/security-products/analyzers/api-fuzzing-src/web/PeachWeb/Runner/Services/[RunnerOptions.cs:line 362
   at Peach.Web.Runner.Services.RunnerService.Start(Job job, IRunnerOptions options) in /builds/gitlab-org/security-products/analyzers/api-fuzzing-src/web/PeachWeb/Runner/Services/RunnerService.cs:line 67
   at Peach.Web.Core.Services.WebRunnerMachine.Run(IRunnerOptions runnerOptions, CancellationToken token) in /builds/gitlab-org/security-products/analyzers/api-fuzzing-src/web/PeachWeb/Core/Services/WebRunnerMachine.cs:line 321
08:45:43.634 [WRN] <Peach.Web.Core.Services.WebRunnerMachine> * Session failed: An unexpected exception occurred: Index was outside the bounds of the array.
08:45:43.677 [INF] <Peach.Web.Core.Services.WebRunnerMachine> Finished testing. Performed a total of 0 requests.
```

**Solution**

This issue occurs due to a malformed `APISEC_REQUEST_HEADERS` or `APISEC_REQUEST_HEADERS_BASE64` variable. The expected format is one or more headers of `Header: value` construction separated by a comma. The solution is to correct the syntax to match what is expected.

_Valid examples:_

- `Authorization: Bearer XYZ`
- `X-Custom: Value,Authorization: Bearer XYZ`

_Invalid examples:_

- `Header:,value`
- `HeaderA: value,HeaderB:,HeaderC: value`
- `Header`

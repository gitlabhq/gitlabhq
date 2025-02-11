---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: API Discovery
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9302) in GitLab 15.9. The API Discovery feature is in [beta](../../../../policy/development_stages_support.md).

API Discovery analyzes your application and produces an OpenAPI document describing the web APIs it exposes. This schema document can then be used by the [API security testing analyzer](../../api_security_testing/_index.md) or [API Fuzzing](../../api_fuzzing/_index.md) to perform security scans of the web API.

## Supported frameworks

- [Java Spring-Boot](#java-spring-boot)

## When does API Discovery run?

API Discovery runs as a standalone job in your pipeline. The resulting OpenAPI document is captured as a job artifact so it can be used by other jobs in later stages.

API Discovery runs in the `test` stage by default. The `test` stage was chosen as it typically executes before the stages used by other security features such as API security testing and API fuzzing.

## Example API Discovery configurations

The following projects demonstrate API Discovery:

- [Example Java Spring Boot v2 Pet Store](https://gitlab.com/gitlab-org/security-products/demos/api-discovery/java-spring-boot-v2-petstore)

## Java Spring-Boot

[Spring Boot](https://spring.io/projects/spring-boot/) is a popular framework for creating stand-alone, production-grade Spring-based applications.

### Supported Applications

- Spring Boot: v2.X (>= 2.1)
- Java: 11, 17 (LTS versions)
- Executable JARs

API Discovery supports Spring Boot major version 2, minor versions 1 and later. Versions 2.0.X are not supported due to known bugs which affect API Discovery and were fixed in 2.1.

Major version 3 is planned to be supported in the future. Support for major version 1 is not planned.

API Discovery is tested with and officially supports LTS versions of the Java runtime. Other versions may work also, and bug reports from non-LTS versions are welcome.

Only applications that are built as Spring Boot [executable JARs](https://docs.spring.io/spring-boot/redirect.html?page=executable-jar#appendix.executable-jar.nested-jars.jar-structure) are supported.

### Configure as pipeline job

The easiest way to run API Discovery is through a pipeline job based on our CI template.
When running in this method, you provide a container image that has the required dependencies installed (such as an appropriate Java runtime). See [Image Requirements](#image-requirements) for more information.

1. A container image that meets the [image requirements](#image-requirements) is uploaded to a container registry. If the container registry requires authentication see [this help section](../../../../ci/docker/using_docker_images.md#access-an-image-from-a-private-container-registry).
1. In a job in the `build` stage, build your application and configure the resulting Spring Boot executable JAR as a job artifact.
1. Include the API Discovery template in your `.gitlab-ci.yml` file.

   ```yaml
   include:
      - template: Security/API-Discovery.gitlab-ci.yml
   ```

   Only a single `include` statement is allowed per `.gitlab-ci.yml` file. If you are including other files, combine them into a single `include` statement.

   ```yaml
   include:
      - template: Security/API-Discovery.gitlab-ci.yml
      - template: Security/DAST-API.gitlab-ci.yml
   ```

1. Create a new job that extends from `.api_discovery_java_spring_boot`. The default stage is `test` which can be optionally changed to any value.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
   ```

1. Configure the `image` for the job.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: openjdk:11-jre-slim
   ```

1. Provide the Java class path needed by your application. This includes your compatible build
   artifact from step 2, along with any additional dependencies. For this example, the build artifact
   is `build/libs/spring-boot-app-0.0.0.jar` and contains all needed dependencies. The variable
   `API_DISCOVERY_JAVA_CLASSPATH` is used to provide the class path.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: openjdk:11-jre-slim
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
   ```

1. Optional. If the image provided is missing a dependency needed by API Discovery, it can be added
   using a `before_script`. In this example, the `openjdk:11-jre-slim` container doesn't include
   `curl` which is required by API Discovery. The dependency can be installed using the Debian
   package manager `apt`:

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: openjdk:11-jre-slim
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
       before_script:
           - apt-get update && apt-get install -y curl
   ```

1. Optional. If the image provided doesn't automatically set the `JAVA_HOME` environment variable,
   or include `java` in the path, the `API_DISCOVERY_JAVA_HOME` variable can be used.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: openjdk:11-jre-slim
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
           API_DISCOVERY_JAVA_HOME: /opt/java
   ```

1. Optional. If the package registry at `API_DISCOVERY_PACKAGES` is not public, provide a token that
   has read access to the GitLab API and registry using the `API_DISCOVERY_PACKAGE_TOKEN` variable.
   This is not required if you are using `gitlab.com` and have not customized the `API_DISCOVERY_PACKAGES`
   variable. The following example uses a
   [custom CI/CD variable](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) named
   `GITLAB_READ_TOKEN` to store the token.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: openjdk:8-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
           API_DISCOVERY_PACKAGE_TOKEN: $GITLAB_READ_TOKEN
   ```

After the API Discovery job has successfully run, the OpenAPI document is available as a job artifact called `gl-api-discovery-openapi.json`.

#### Image requirements

- Linux container image.
- Java versions 11 or 17 are officially supported, but other versions are likely compatible as well.
- The `curl` command.
- A shell at `/bin/sh` (like `busybox`, `sh`, or `bash`).

### Available CI/CD variables

| CI/CD variable                              | Description        |
|---------------------------------------------|--------------------|
| `API_DISCOVERY_DISABLED`                    | Disables the API Discovery job when using template job rules. |
| `API_DISCOVERY_DISABLED_FOR_DEFAULT_BRANCH` | Disables the API Discovery job for default branch pipelines when using template job rules. |
| `API_DISCOVERY_JAVA_CLASSPATH`              | Java class-path that includes target Spring Boot application. (`build/libs/sample-0.0.0.jar`) |
| `API_DISCOVERY_JAVA_HOME`                   | If provided is used to set `JAVA_HOME`. |
| `API_DISCOVERY_PACKAGES`                    | GitLab Project Package API Prefix (defaults to `$CI_API_V4_URL/projects/42503323/packages`). |
| `API_DISCOVERY_PACKAGE_TOKEN`               | GitLab token for calling the GitLab package API. Only needed when `API_DISCOVERY_PACKAGES` is set to a non-public project. |
| `API_DISCOVERY_VERSION`                     | API Discovery version to use (defaults to `1`). Can be used to pin a version by providing the full version number `1.1.0`. |

## Get support or request an improvement

To get support for your particular problem, use the [getting help channels](https://about.gitlab.com/get-help/).

The [GitLab issue tracker on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues) is the right place for bugs and feature proposals about API Discovery.
Use `~"Category:API Security"` [label](../../../../development/labels/_index.md) when opening a new issue regarding API Discovery to ensure it is quickly reviewed by the right people. Refer to our [review response SLO](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#review-response-slo) to understand when you should receive a response.

[Search the issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues) for similar entries before submitting your own, there's a good chance somebody else had the same issue or feature proposal. Show your support with an emoji reaction or join the discussion.

When experiencing a behavior not working as expected, consider providing contextual information:

- GitLab version if using a self-managed instance.
- `.gitlab-ci.yml` job definition.
- Full job console output.
- Framework in use with version (for example Spring Boot v2.3.2).
- Language runtime with version (for example OpenJDK v17.0.1).
<!-- - Scanner log file is available as a job artifact named `gl-api-discovery.log`. -->

WARNING:
**Sanitize data attached to a support issue**. Remove sensitive information, including: credentials, passwords, tokens, keys, and secrets.

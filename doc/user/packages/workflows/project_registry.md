---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Manage packages with dedicated, type-specific registries
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Organize your packages by type in dedicated projects within a top-level artifact management group. This approach provides clear ownership and type-specific policies.

Use this approach when you want to:

- Organize packages by type with dedicated policies and settings.
- Provide a single consumption endpoint for all organizational packages.
- Migrate packages from third-party registries to a structured GitLab setup.
- Separate package management concerns from application source code.
- Apply different governance policies to different package types.
- Maintain clear ownership while enabling organization-wide access.

## Example walkthrough

To effectively organize and manage
your packages with this approach, you should:

- Create a dedicated top-level group for artifact
management with projects organized by package type.
- Limit the top-level group to only projects with
artifacts to improve performance when consuming packages.

### Recommended structure

The following example
provides an overview of how you should
structure your top-level group and projects:

```plaintext
company_namespace/artifact_management/ # top-level group
├── java-packages/           # Maven packages
├── node-packages/           # npm packages
├── python-packages/         # PyPI packages
├── docker-images/           # Container registry
├── terraform-modules/       # Terraform modules
├── nuget-packages/          # NuGet packages
└── generic-packages/        # Generic file packages
```

{{< alert type="note" >}}

Some organizations prefer additional separation based on package lifecycle or stability. For example, you might create separate projects for `java-releases/` and `java-snapshots/`. This way, you can apply different cleanup policies, access controls, or approval workflows for stable packages and development packages.

{{< /alert >}}

### Create the group and projects

Create a new top-level group for artifact management:

1. On the top bar, select **Create new** ({{< icon name="plus" >}}) and **New group**.
1. Select **Create group**.
1. In the **Group name** text box, enter `Artifact Management` or similar.
1. In **Group URL**, keep the generated path.
1. Select the [**Visibility level**](../../public_access.md) of the group.
1. Select **Create group**.

Create projects for each package type you need:

1. On the top bar, select **Search or go to** and find your artifact management group.
1. On the left sidebar, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**.
1. Select **Create blank project**.
1. Enter a **Project name** for your desired package type. For example, `java-packages` or `node-packages`.
1. Set the appropriate visibility level.
1. Select **Create project**.

Start with the package types your organization uses most,
then expand the structure as you adopt additional package formats.
This approach scales naturally while maintaining security and ease of use.

Configure group settings:

1. In your artifact management group, on the left sidebar, select **Settings** > **Packages and registries**.
1. Configure any group policies you need, like **Duplicate packages** or **Package forwarding**.
1. Set up group access controls as needed.

## Configure authentication and access

Authentication varies based on your use case. Refer
to the suggestions below. For more information about
authentication, see [Authenticate with the registry](../../packages/package_registry/supported_functionality.md#authenticate-with-the-registry)

For local development (developers):

- Personal access tokens for individual developers
- Group access tokens for shared team credentials

For CI/CD pipelines:

- CI/CD job tokens (preferred) - automatic authentication
- Project access tokens for special cases

For external systems:

- Deploy tokens for read-only consumption
- Project and group access tokens for more granular control

### Set up top-level group access

Create a group deploy token for organization-wide package consumption:

1. In your artifact management group, on the left sidebar, select **Settings** > **Repository**.
1. Expand **Deploy tokens**.
1. Select **Add token** and complete the fields:
   - For the **Name**, enter `package-consumption`.
   - For **Scopes**, select `read_package_registry`.
1. Select **Create deploy token**.

Save the token securely.

If you want to use CI/CD job tokens for publishing,
configure the job token allowlist:

1. In each package-specific project, on the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Token Access**.
1. Add projects that should be allowed to publish packages to this package registry.

### Configure project settings

For each package type project, configure:

- **Lifecycle policies** appropriate for that package type
- **Protected packages** rules, if needed
- **Protected container tag** rules, if needed
- **Project access tokens** for specific use cases

## Publish packages

Teams should publish packages to the appropriate type-specific project registry.
See the following examples for each supported package format.

{{< tabs >}}

{{< tab title="Maven" >}}

Configure your project's `pom.xml` to publish to the `java-packages` project:

```xml
<distributionManagement>
    <repository>
        <id>gitlab-maven</id>
        <url>${CI_API_V4_URL}/projects/JAVA_PACKAGES_PROJECT_ID/packages/maven</url>
    </repository>
    <snapshotRepository>
        <id>gitlab-maven</id>
        <url>${CI_API_V4_URL}/projects/JAVA_PACKAGES_PROJECT_ID/packages/maven</url>
    </snapshotRepository>
</distributionManagement>
```

Configure authentication in your `settings.xml`:

```xml
<servers>
    <server>
        <id>gitlab-maven</id>
        <configuration>
            <httpHeaders>
                <property>
                    <name>Job-Token</name>
                    <value>${CI_JOB_TOKEN}</value>
                </property>
            </httpHeaders>
        </configuration>
    </server>
</servers>
```

Publish with:

```shell
mvn deploy

{{< /tab >}}

{{< tab title="npm" >}}

Configure your project's `package.json`:

```json
{
  "name": "@company/my-package",
  "publishConfig": {
    "registry": "${CI_API_V4_URL}/projects/NODE_PACKAGES_PROJECT_ID/packages/npm/"
  }
}
```

For CI/CD publishing, the job token is used automatically:

```yaml
publish:
  script:
    - npm publish
```

For local publishing, configure authentication:

```shell
npm config set @company:registry https://gitlab.example.com/api/v4/projects/NODE_PACKAGES_PROJECT_ID/packages/npm/
npm config set //gitlab.example.com/api/v4/projects/NODE_PACKAGES_PROJECT_ID/packages/npm/:_authToken ${PERSONAL_ACCESS_TOKEN}

{{< /tab >}}

{{< tab title="PyPI" >}}

Configure publishing in your CI/CD pipeline:

```yaml
publish:
  script:
    - pip install build twine
    - python -m build
    - TWINE_PASSWORD=${CI_JOB_TOKEN} TWINE_USERNAME=gitlab-ci-token twine upload --repository-url ${CI_API_V4_URL}/projects/PYTHON_PACKAGES_PROJECT_ID/packages/pypi dist/*
```

For local publishing:

```shell
twine upload --repository-url https://gitlab.example.com/api/v4/projects/PYTHON_PACKAGES_PROJECT_ID/packages/pypi --username __token__ --password ${PERSONAL_ACCESS_TOKEN} dist/*

{{< /tab >}}

{{< tab title="Container registry" >}}

Build and push Docker images:

```yaml
build-image:
  script:
    - docker build -t $CI_REGISTRY/artifact-management/docker-images/my-app:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY/artifact-management/docker-images/my-app:$CI_COMMIT_SHA
```

For local development:

```shell
docker login gitlab.example.com -u ${USERNAME} -p ${PERSONAL_ACCESS_TOKEN}
docker push gitlab.example.com/artifact-management/docker-images/my-app:latest

{{< /tab >}}

{{< tab title="Terraform" >}}

Publish Terraform modules:

```yaml
publish-module:
  script:
    - tar -czf module.tar.gz *.tf
    - 'curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file module.tar.gz "${CI_API_V4_URL}/projects/TERRAFORM_PACKAGES_PROJECT_ID/packages/terraform/modules/my-module/my-provider/1.0.0/file"'
```

{{< /tab >}}

{{< tab title="NuGet" >}}

Configure publishing in your project file or CI/CD pipeline:

```yaml
publish:
  script:
    - dotnet pack
    - dotnet nuget push "bin/Release/*.nupkg" --source ${CI_API_V4_URL}/projects/NUGET_PACKAGES_PROJECT_ID/packages/nuget/index.json --api-key ${CI_JOB_TOKEN}
```

For local publishing:

```shell
dotnet nuget push package.nupkg --source https://gitlab.example.com/api/v4/projects/NUGET_PACKAGES_PROJECT_ID/packages/nuget/index.json --api-key ${PERSONAL_ACCESS_TOKEN}

{{< /tab >}}

{{< tab title="Generic" >}}

Upload generic packages:

```yaml
upload-package:
  script:
    - 'curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file my-package.zip "${CI_API_V4_URL}/projects/GENERIC_PACKAGES_PROJECT_ID/packages/generic/my-package/1.0.0/my-package.zip"'
```

{{< /tab >}}

{{< /tabs >}}

## Consume packages

For package consumption, you can either:

- Use the Maven virtual registry.
- Use the top-level group endpoint.

### Using the Maven virtual registry (beta)

The Maven virtual registry can enhance your
artifact management setup by aggregating
packages from multiple sources. You can:

- Add internal packages by using your top-level group endpoint for Maven as an upstream (For example, `https://gitlab.example.com/api/v4/groups/artifact-management/-/packages/maven`).
- Add external upstream registries, like Maven Central or private registries.
- Add other GitLab projects or groups.

This approach provides a single endpoint that combines
internal and external dependencies with intelligent
caching and upstream prioritization.

Use the Maven virtual registry when you:

- Need to aggregate internal GitLab packages with external upstream registries
- Want to cache external dependencies for improved reliability
- Need to prioritize private registries over public ones
- Want a single endpoint that handles both internal and external dependencies

Publishing is not supported by the Maven virtual registry.

For more information, see [Maven virtual registry](../virtual_registry/maven/_index.md).

#### Configure the Maven virtual registry within a top-level artifact management group

1. Create the virtual registry at the top-level group:
   - In your `artifact-management` group, go to **Deploy** > **Virtual registry**.
   - Create a Maven virtual registry (for example, "Company Maven Registry").
1. Configure upstream registries:
   - Add your internal `java-packages` project as an upstream.
   - Add external registries like Maven Central or private repositories.
   - Order upstreams with private registries first and public registries last.
1. Configure Maven clients to use the virtual registry:

```xml
   <mirrors>
     <mirror>
       <id>central-proxy</id>
       <name>GitLab virtual registry</name>
       <url>https://gitlab.example.com/api/v4/virtual_registries/packages/maven/<registry_id></url>
       <mirrorOf>central</mirrorOf>
     </mirror>
   </mirrors>
```

The virtual registry supports multiple token types, including personal access tokens, group deploy tokens, group access tokens, and CI/CD job tokens. Each token type uses a different HTTP header name. For more information, see [Authenticate to the virtual registry](../virtual_registry/_index.md#authenticate-to-the-virtual-registry).

The following example implements a personal access token:

```xml
   <servers>
     <server>
       <id>gitlab-maven</id>
       <configuration>
         <httpHeaders>
           <property>
             <name>Private-Token</name>
             <value>${PERSONAL_ACCESS_TOKEN}</value>
           </property>
         </httpHeaders>
       </configuration>
     </server>
   </servers>
```

### Configure a top-level group endpoint

Configure your projects to consume packages from the top-level group endpoint.
This approach provides access to all package types through a single configuration:

{{< tabs >}}

{{< tab title="Maven" >}}

Configure your `pom.xml` to consume from the group registry:

```xml
<repositories>
    <repository>
        <id>gitlab-maven</id>
        <url>https://gitlab.example.com/api/v4/groups/artifact-management/-/packages/maven</url>
    </repository>
</repositories>
```

Configure authentication in your `settings.xml`:

```xml
<settings>
    <servers>
        <server>
            <id>gitlab-maven</id>
            <username>deploy-token-username</username>
            <password>deploy-token-password</password>
        </server>
    </servers>
</settings>
```

{{< /tab >}}

{{< tab title="npm" >}}

Configure your `.npmrc` file:

```ini
@company:registry=https://gitlab.example.com/api/v4/groups/artifact-management/-/packages/npm/
//gitlab.example.com/api/v4/groups/artifact-management/-/packages/npm/:_authToken=${DEPLOY_TOKEN}
```

{{< /tab >}}

{{< tab title="PyPI" >}}

Configure `pip` to use the group registry:

```ini
# pip.conf or ~/.pip/pip.conf
[global]
extra-index-url = https://deploy-token-username:deploy-token-password@gitlab.example.com/api/v4/groups/artifact-management/-/packages/pypi/simple/
```

Or use environment variables:

```shell
pip install --index-url https://deploy-token-username:deploy-token-password@gitlab.example.com/api/v4/groups/artifact-management/-/packages/pypi/simple/ --no-index my-package

{{< /tab >}}

{{< tab title="Container Registry" >}}

Pull images from the group registry:

```shell
docker login gitlab.example.com -u deploy-token-username -p deploy-token-password
docker pull gitlab.example.com/artifact-management/docker-images/my-app:latest

{{< /tab >}}

{{< tab title="Terraform" >}}

Configure Terraform to use GitLab credentials with environment variables:

```shell
export TF_TOKEN_gitlab_example_com="deploy-token-password"

Then reference modules in your Terraform configuration:

```hcl
module "example" {
  source = "gitlab.example.com/artifact-management/terraform-modules//my-module"
  version = "1.0.0"
}
```

Or using the project-specific URL:

```hcl
module "example" {
  source = "https://gitlab.example.com/api/v4/projects/TERRAFORM_PACKAGES_PROJECT_ID/packages/terraform/modules/my-module/my-provider/1.0.0"
}
```

{{< /tab >}}

{{< tab title="NuGet" >}}

Configure NuGet to use the group registry:

```xml
<!-- nuget.config -->
<configuration>
  <packageSources>
    <add key="GitLab" value="https://gitlab.example.com/api/v4/groups/artifact-management/-/packages/nuget/index.json" />
  </packageSources>
  <packageSourceCredentials>
    <GitLab>
      <add key="Username" value="deploy-token-username" />
      <add key="ClearTextPassword" value="deploy-token-password" />
    </GitLab>
  </packageSourceCredentials>
</configuration>

{{< /tab >}}

{{< tab title="Generic" >}}

Download generic packages:

```shell
curl --header "DEPLOY-TOKEN: ${DEPLOY_TOKEN}" "https://gitlab.example.com/api/v4/groups/artifact-management/-/packages/generic/my-package/1.0.0/my-package.zip" --output my-package.zip

{{< /tab >}}

{{< /tabs >}}

## Example CI/CD configuration

The following example shows you how a project
might consume packages from multiple package types:

```yaml
stages:
  - build
  - test

variables:
  MAVEN_OPTS: "-Dmaven.repo.local=${CI_PROJECT_DIR}/.m2/repository"

before_script:
  # Configure npm registry
  - echo "@company:registry=${CI_API_V4_URL}/groups/artifact-management/-/packages/npm/" >> .npmrc
  - echo "//${CI_SERVER_HOST}/api/v4/groups/artifact-management/-/packages/npm/:_authToken=${CI_JOB_TOKEN}" >> .npmrc

build:
  stage: build
  script:
    # Install npm dependencies from group registry
    - npm install
    # Build with Maven dependencies from group registry
    - mvn compile
  cache:
    paths:
      - .m2/repository/
      - node_modules/
```

## Publish alongside source code

Some organizations prefer publishing packages alongside their application source code, as described in the [enterprise scale tutorial](../package_registry/enterprise_structure_tutorial.md). This approach works well when:

- Packages are tightly coupled to specific applications.
- You want package ownership to align with source code ownership.
- Teams manage both code and packages together.

The artifact management approach works better when:

- You want streamlined package governance.
- Packages are shared across multiple projects.
- You need type-specific policies and controls.
- You're migrating from traditional artifact repositories.

Start with the package types your organization uses most, then expand the structure as you adopt additional package formats. This approach scales naturally while maintaining security and ease of use.

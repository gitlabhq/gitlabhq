---
status: proposed
creation-date: "2023-08-31"
authors: [ "@jdrpereira", "@10io" ]
coach: "@grzesiek"
approvers: [ "@trizzi", "@crystalpoole" ]
owning-stage: "~devops::package"
participating-stages: []
---

# Google Artifact Registry Integration

## Summary

GitLab and Google Cloud have recently [announced](https://about.gitlab.com/blog/2023/08/29/gitlab-google-partnership-s3c/) a partnership to combine the unique capabilities of their platforms.

As highlighted in the announcement, one key goal is the ability to "_use Google's Artifact Registry with GitLab pipelines and packaging to create a security data plane_". The initial step toward this goal is to allow users to configure a new [Google Artifact Registry](https://cloud.google.com/artifact-registry) (abbreviated as GAR from now on) [project integration](../../../user/project/integrations/index.md) and display [container image artifacts](https://cloud.google.com/artifact-registry/docs/supported-formats) in the GitLab UI.

## Motivation

Refer to the [announcement](https://about.gitlab.com/blog/2023/08/29/gitlab-google-partnership-s3c/) blog post for more details about the motivation and long-term goals of the GitLab and Google Cloud partnership.

Regarding the scope of this design document, our primary focus is to fulfill the Product requirement of providing users with visibility over their container images in GAR. The motivation for this specific goal is rooted in foundational research on the use of external registries as a complement to the GitLab container registry ([internal](https://gitlab.com/gitlab-org/ux-research/-/issues/2602)).

Since this marks the first step in the GAR integration, our aim is to achieve this goal in a way that establishes a foundation to facilitate reusability in the future. This groundwork could benefit potential future expansions, such as support for additional artifact formats (npm, Maven, etc.), and features beyond the Package stage (e.g., vulnerability scanning, deployments, etc.).

### Goals

- Allow GitLab users to configure a new [project integration](../../../user/project/integrations/index.md) for connecting to GAR.
- Limited to a single top-level GAR [repository](https://cloud.google.com/artifact-registry/docs/repositories) per GitLab project.
- Limited to GAR repositories in [Standard](https://cloud.google.com/artifact-registry/docs/repositories#mode) mode. Support for Remote and Virtual [repository modes](https://cloud.google.com/artifact-registry/docs/repositories#mode) (both in Preview) is a strech goal.
- Limited to GAR repositories of format [Container images](https://cloud.google.com/artifact-registry/docs/supported-formats#container).
- Use a Google Cloud [service account](https://cloud.google.com/iam/docs/service-account-overview) provided by the GitLab project owner/maintainer to interact with GAR.
- Allow GitLab users to list container images under the connected GAR repository, including sub-repositories. The list should be paginable and sortable.
- For each listed image, display its URI, list of tags, size, digest, upload time, media type, build time, and update time, as documented [here](https://cloud.google.com/artifact-registry/docs/reference/rest/v1/projects.locations.repositories.dockerImages#DockerImage).
- Listing container images under the connected GAR repository is restricted to users with [Reporter+](../../../user/permissions.md#roles) roles.

### Non-Goals

While some of these may become goals for future iterations, they are currently out of scope:

- Create, update and delete operations.
- Connecting to multiple (top-level) GAR repositories under the same project.
- Support for [repository formats](https://cloud.google.com/artifact-registry/docs/supported-formats) beyond container images.
- Support for other [Identity and Access Management (IAM)](https://cloud.google.com/security/products/iam) permissions/credentials beyond [service accounts](https://cloud.google.com/iam/docs/service-account-overview).
- GAR [cleanup policies](https://cloud.google.com/artifact-registry/docs/repositories/cleanup-policy).
- Filtering the images list by their attributes (name or value). The current [GAR API](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1#listdockerimagesrequest) does not support filtering.
- [Artifact analysis and vulnerability scanning](https://cloud.google.com/artifact-registry/docs/analysis).

## Proposal

### Design and Implementation Details

#### Project Integration

A new [project integration](../../../user/project/integrations/index.md) for GAR will be created. Once enabled, this will display a new "Google Artifact Registry" item in the "Operate" section of the sidebar. This is also where the [Harbor](../../../user/project/integrations/harbor.md) integration is displayed if enabled.

The GAR integration can be enabled by project owner/maintainer(s), who must provide four configuration parameters during setup:

- **GCP project ID**: The globally unique identifier for the GCP project where the target GAR repository lives.
- **Repository location**: The [GCP location](https://cloud.google.com/about/locations) where the target GAR repository lives.
- **Repository name**: The name of the target GAR repository.
- **GCP service account key**: The _content_ (not the file) of the [service account key](https://cloud.google.com/iam/docs/keys-create-delete) in JSON format ([sample](https://cloud.google.com/iam/docs/keys-create-delete#creating)).

#### Authentication

The integration is simplified by using a single GCP service account for the integration. Users retain the ability to [audit usage](https://cloud.google.com/iam/docs/audit-logging/examples-service-accounts#access-with-key) of this service account on the GCP side and revoke permissions if/when necessary.

The service account key provided during the integration setup must be granted at least with the [`Artifact Registry Reader`](https://cloud.google.com/artifact-registry/docs/access-control#permissions) role in the target GCP project.

Saving the (encrypted) service account key JSON content in the backend allows us to easily grab and use it to initialize the GAR client (more about that later). Providing the content of the key file instead of uploading it is similar to what we do with users' public SSH keys.

As previously highlighted, access to the GAR integration features is restricted to users with [Reporter+](../../../user/permissions.md#roles) roles.

#### Resource Mapping

For the [GitLab container registry](../../../user/packages/container_registry/index.md), repositories within a specific project must have a path that matches the project full path. This is essentially how we establish a resource mapping between GitLab Rails and the registry, which serves multiple purposes, including granular authorization, scoping storage usage to a given project/group/namespace, and more.

Regarding the GAR integration, since there is no equivalent entities for GitLab project/group/namespace resources on the GAR side, we aim to simplify matters by allowing users to attach any [GAR repository](https://cloud.google.com/artifact-registry/docs/repositories) to any GitLab project, regardless of their respective paths. Similarly, we do not plan to restrict the attachment of a particular GAR repository to a single GitLab project. Ultimately, it is up to users to determine how to organize both datasets in the way that best suits their needs.

#### GAR API

GAR provides three APIs: Docker API, REST API, and RPC API.

The [Docker API](https://cloud.google.com/artifact-registry/docs/reference/docker-api) is based on the [Docker Registry HTTP API V2](https://distribution.github.io/distribution/spec/api/), now superseded by the [OCI Distribution Specification API](https://github.com/opencontainers/distribution-spec/blob/main/spec.md) (from now on referred to as OCI API). This API is used for pushing/pulling images to/from GAR and also provides some discoverability operations. Refer to [Alternative Solutions](#alternative-solutions) for the reasons why we don't intend to use it.

Among the proprietary GAR APIs, the [REST API](https://cloud.google.com/artifact-registry/docs/reference/rest) provides basic functionality for managing repositories. This includes [`list`](https://cloud.google.com/artifact-registry/docs/reference/rest/v1/projects.locations.repositories.dockerImages/list) and [`get`](https://cloud.google.com/artifact-registry/docs/reference/rest/v1/projects.locations.repositories.dockerImages/get) operations for container image repositories, which could be used for this integration. Both operations return the same data structure, represented by the [`DockerImage`](https://cloud.google.com/artifact-registry/docs/reference/rest/v1/projects.locations.repositories.dockerImages#DockerImage) object, so both provide the same level of detail.

Last but not least, there is also an [RPC API](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1), backed by gRPC and Protocol Buffers. This API provides the most functionality, covering all GAR features. From the available operations, we can make use of the [`ListDockerImagesRequest`](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1#listdockerimagesrequest) and [`GetDockerImageRequest`](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1#google.devtools.artifactregistry.v1.GetDockerImageRequest) operations. As with the REST API, both responses are composed of [`DockerImage`](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1#google.devtools.artifactregistry.v1.DockerImage) objects.

Between the two proprietary API options, we chose the RPC one because it provides support not only for the operations we need today but also offers better coverage of all GAR features, which will be beneficial in future iterations. Finally, we do not intend to make direct use of this API but rather use it through the official Ruby client SDK. See [Client SDK](backend.md#client-sdk) below for more details.

#### Backend Integration

This integration will need several changes on the backend side of the rails project. See the [backend](backend.md) page for additional details.

#### UI/UX

This integration will include a dedicated page named "Google Artifact Registry," listed under the "Operate" section of the sidebar. This page will enable users to view the list of all container images in the configured GAR repository. See the [UI/UX](ui_ux.md) page for additional details.

#### GraphQL APIs

*TODO: Describe any GraphQL APIs or changes to existing APIs that will be needed for this integration.*

## Alternative Solutions

### Use Docker/OCI API

One alternative solution considered was to use the Docker/OCI API provided by GAR, as it is a common standard for container registries. This approach would have allowed GitLab to reuse [existing logic](https://gitlab.com/gitlab-org/gitlab/-/blob/20df77103147c0c8ff1c22a888516eba4bab3c46/lib/container_registry/client.rb) for connecting to container registries, which could potentially speed up development. However, there were several drawbacks to this approach:

- **Authentication Complexity**: The API requires authentication tokens, which need to be requested at the [login endpoint](https://distribution.github.io/distribution/spec/auth/token/). These tokens have limited validity, adding complexity to the authentication process. Handling expiring tokens would have been necessary.

- **Limited Focus**: The API is solely focused on container registry objects, which does not align with the goal of creating a flexible integration framework for adopting additional GAR artifacts (e.g. package registry formats) down the road.

- **Discoverability Limitations**: The API has severe limitations when it comes to discoverability, lacking features like filtering or sorting.

- **Multiple Requests**: To retrieve all the required information about each image, multiple requests to different endpoints (listing tags, obtaining image manifests, and image configuration blobs) would have been necessary, leading to a `1+N` performance issue.

GitLab had previously faced significant challenges with the last two limitations, prompting the development of a custom [GitLab container registry API](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/api.md) to address them. Additionally, GitLab decided to [deprecate support](../../../update/deprecations.md#use-of-third-party-container-registries-is-deprecated) for connecting to third-party container registries using the Docker/OCI API due to these same limitations and the increased cost of maintaining two solutions in parallel. As a result, there is an ongoing effort to replace the use of the Docker/OCI API endpoints with custom API endpoints for all container registry functionalities in GitLab.

Considering these factors, the decision was made to build the GAR integration from scratch using the proprietary GAR API. This approach provides more flexibility and control over the integration and can serve as a foundation for future expansions, such as support for other GAR artifact formats.

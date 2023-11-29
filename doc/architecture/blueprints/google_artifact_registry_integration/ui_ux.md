---
stage: package
group: container registry
description: 'UI/UX for Google Artifact Registry Integration'
---

# UI/UX for Google Artifact Registry Integration

## Structure and Organization

Unlike the GitLab container registry (and therefore the Docker Registry and OCI Distribution), GAR does not treat tags as the primary "artifacts" in a repository. Instead, the primary "artifacts" are the image manifests. For each manifest object (represented by [`DockerImage`](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1#google.devtools.artifactregistry.v1.DockerImage)), there is a list of assigned tags (if any). Consequently, when listing the contents of a repository through the GAR API, the response comprises a collection of manifest objects (along with their associated tags as properties), rather than a collection of tag objects. Additionally, due to this design choice, untagged manifests are also present in the response.

To maximize flexibility, extensibility, and maintain familiarity for GAR users, we plan to fully embrace the GAR API data structures while surfacing data in the GitLab UI. We won't attempt to emulate a "list of tags" response to match the UI/UX that we already have for the GitLab container registry.

Considering the above, there will be a view that provides a pageable and sortable list of all images in the configured GAR repository. Additionally, there will be a detail view to display more information about a single image. You can find a list of available image attributes documented [here](https://cloud.google.com/artifact-registry/docs/reference/rpc/google.devtools.artifactregistry.v1#google.devtools.artifactregistry.v1.DockerImage).

## Designs

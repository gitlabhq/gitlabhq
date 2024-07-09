---
owning-stage: "~devops::secure"
description: 'EPSS Support ADR 002: Use a new bucket for EPSS data'
---

# EPSS Support ADR 002: Use a new bucket for EPSS data

## Context

PMDB exports data to GCP buckets. The data is later pulled by GitLab instances. Advisory data and license data are stored in different buckets. This is sensible, because advisory and license data are not directly related, and rather provide additional information about packages. Data is updated based on deltas—changes from the previous state of the data. Only those changes are saved with each addition to the database.

EPSS data is directly associated with advisories, so it feels natural to add it to the existing advisories bucket. However, the current advisories bucket is structured based on `purl_type`. Adding an `epss` data type would couple `epss` with `purl_type` which is a faulty pairing. Due to the tight coupling between `purl_type` and the existing advisories bucket, it would be difficult and convoluted to add `epss` to it.

Following [extensive discussions on the EPSS epic](https://gitlab.com/groups/gitlab-org/-/epics/11544#note_1952695268) and [discussion](https://gitlab.com/gitlab-org/gitlab/-/issues/468131#note_1961344123) during the refinement of PMDB issues, it was initially decided to use the existing bucket as this feels most intuitive and at the time felt a healthier approach. [Further discussion](https://gitlab.com/gitlab-org/gitlab/-/issues/467672#note_1980715240) during the refinement of the GitLab backend effort led to the decision to use a new bucket, due to the complexity of the coupling of `purl_type` and other, unrelated areas in the monolith. Adding `epss` to `purl_type` would impact other components and we want to avoid having to work around that. We may want to later simplify these areas and reconsider the bucket structure at a later stage.

## Decision

Export EPSS data to a new bucket, rather than exporting it into the existing PMDB advisories bucket.

## Consequences

The implementation is simpler than adding a directory to the existing advisories bucket, but may feel less intuitive. 
This change require the relevant Terraform changes regarding the provisioning of a new bucket.
This should also be addressed in the exporter and the GitLab `package_metadata` sync configuration.

## Alternatives

The other option is to add EPSS data to the advisories bucket, since they are directly related. This was the [initial decision](https://gitlab.com/gitlab-org/gitlab/-/issues/468131#note_1980366323). This would allow us to utilize existing mechanisms and keep related data close. However, EPSS data doesn't fit into the current structure of the advisories bucket. An ideal solution would reconstruct the buckets in a manner more fitting for this approach, but this would be a big effort and is not critical enough.

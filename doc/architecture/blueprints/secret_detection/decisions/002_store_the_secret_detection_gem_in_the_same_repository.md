---
owning-stage: "~devops::secure"
description: "GitLab Secret Detection ADR 002: Store the Secret Detection Gem in the same repository"
---

# GitLab Secret Detection ADR 002: Store the Secret Detection Gem in the same repository

## Context

During [Phase 1](../index.md#phase-1---ruby-pushcheck-pre-receive-integration), we opted for using the [Ruby-based push check approach](../decisions/001_use_ruby_push_check_approach_within_monolith.md) to block secrets from being committed to a repository, and as such the scanning of secrets was performed by a library (or a Ruby gem) developed internally within GitLab for this specific purpose.

Part of the process to create this library and make it available for use within the Rails monolith, we had to make a decision on the best way to distribute the library.

## Approach

We evaluated two possible approaches:

1. Store the library [in the same repository](../../../../development/gems.md#in-the-same-repo) as the monolith.
1. Store the library [in an external repository](../../../../development/gems.md#in-the-external-repo).

Each approach came with some advantages and disadvantages, mostly around distribution, consistency, maintainability, and the overhead of having to set up review and release workflows and similar processes. See below for more information.

### Within the same repository as the monolith

Having the gem developed and stored in the same repository meant having it packaged within GitLab monolith itself, and with that ensuring it does not have to be installed as a dependency. This would also reduce maintainability overhead in terms of defining workflows and processes from scratch. On the other hand, the library would have less visibility as it is not exposed or published to the wider community.

### In an external repository

Storing the library in an external repository meant having more visibility especially as the gem would be published on RubyGems.org, which would have garnered more interest and possibly contributions from the community into the feature. Additionally, the gem would be available to be used in other projects and applications. However, in doing so, the maintainability overhead would have increased signficantly for various reasons such as:

- Changes would need to be coordinated between multiple repositories when a new version is released.
- Review and release workflows, and similar processes would need to be defined separately.

## Decision

The decision was made to store the library in the same repository during the first phase to ensure easier distribution since it's packaged within GitLab and will be available immediately without having to install external dependencies.

With that said, we still followed [the process](../../../../development/gems.md#reserve-a-gem-name) to reserve the gem on [RubyGems.org](https://rubygems.org/gems/gitlab-secret_detection) to avoid name-squatters from taking over the name and providing malicious code to 3rd-parties.

We have no plans to publish the gem externally at least until [Phase 2](../index.md#phase-2---standalone-pre-receive-service) as we begin to consider building a standalone service to perform secret detection.

---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab SLSA
---

This page contains information pertaining to GitLab SLSA support.

Related topics:

- [Provenance version 1 `buildType` specification](provenance_v1.md)

## SLSA provenance generation

GitLab offers a SLSA Level 1 compliant provenance statement that can be
[automatically generated for all build artifacts produced by the GitLab Runner](../../runners/configure_runners.md#artifact-provenance-metadata).
This provenance statement is produced by the runner itself.

### Sign and verify SLSA provenance with a CI/CD Component

The [GitLab SLSA CI/CD component](https://gitlab.com/explore/catalog/components/slsa)
provides configurations for:

- Signing runner-generated provenance statements.
- Generating [Verification Summary Attestations (VSA)](https://slsa.dev/spec/v1.0/verification_summary)
  for job artifacts.

For more information and example configurations, see the [SLSA Component documentation](https://gitlab.com/components/slsa#slsa-supply-chain-levels-for-software-artifacts).

---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Deprecation terms
---

## Deprecation

- Required before ending support for a feature or removing a feature.
- Feature not recommended for use.
- Development restricted to Priority 1 / Severity 1 bug fixes.
- Will be removed in a future major release.
- Begins after a deprecation announcement outlining an end-of-support or removal date.
- Ends after the end-of-support date or removal date has passed.

## End of support

- Optional step before removal.
- Feature usage strongly discouraged.
- No support or fixes provided.
- No longer tested internally.
- Will be removed in a future major release.
- Begins after an end-of-support date has passed.

Announcing an end-of-support period
should only be used in special circumstances and is not recommended for general use.
Most features should be deprecated and then removed.

## Removal

- Feature usage impossible.
- Feature no longer supported (if End of Support period hasn't already been announced).
- Happens in a major release in line with our
  [semantic versioning policy](../policy/maintenance.md).
- Begins after removal date has passed.

## Breaking change

Any change counts as a breaking change if customers need to take action to ensure their GitLab workflows aren't disrupted.

A breaking change could come from sources such as:

- An intentional product change
- A configuration update
- A third-party deprecation

By default, no breaking change is allowed unless the breaking change implementation plan has been approved by leadership.

## Third-party dependencies

This section applies to all previous terms.

Changes (deprecation, end of support, removal, or breaking change) in third-party dependencies are handled separately from changes to features in GitLab itself:

- These changes follow the dependency's own lifecycle and are not subject to feature process and timeline requirements for GitLab.
- GitLab will try to minimize impact and provide a smooth migration experience for third-party dependency changes that affect our product.
- Security updates to dependencies might be applied without following their standard deprecation processes when necessary to address severe vulnerabilities within vulnerability resolution SLAs. For more information, see the GitLab Handbook.
- In cases where dependencies change outside our control or timeline, GitLab might need to implement changes to our own software outside our usual process and timeline to
  maintain our functionality, compatibility, or security.
- GitLab will make reasonable efforts to communicate significant third-party dependency changes.
- GitLab is not responsible for any changes in third-party dependency functionality that is not directly used by GitLab products.
- Customers who leverage these third-party dependencies beyond the usage patterns of GitLab do so at their own risk and should:
  - Monitor the third-party's release notes independently.
  - Test their custom implementations against new dependency versions.
  - Plan their own migration strategies for third-party changes.

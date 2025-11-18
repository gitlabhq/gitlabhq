---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Support details.
title: Support for features in different stages of development
---

GitLab sometimes releases features at different development stages, such as experimental or beta.
Users can opt in and test the new experience.
Some reasons for these kinds of feature releases include:

- Validating the edge-cases of scale, support, and maintenance burden of features in their current form for every designed use case.
- Features not complete enough to be considered an MVC, but added to the codebase as part of the development process.

Some features may not be aligned to these recommendations if they were developed before the recommendations were in place,
or if a team determined an alternative implementation approach was needed.

All other features are considered to be publicly available.

## Terminology

For clarity, this policy uses the following definitions:

**Explicit opt-in**: A feature is disabled by default and requires a deliberate enablement action by an authorized user (such as an instance administrator, group owner, or individual user, depending on feature scope). Features that are available to enable but remain disabled unless activated are considered to require explicit opt-in.

**Enabled by default**: A feature is active for users or instances without requiring an opt-in action. Features must not be enabled by default during Experimental or Beta stages.

**Production use**: Refers to both:

- Customer production workloads (features that users depend on for business operations)
- GitLab-managed production infrastructure (shared services affecting platform reliability or security) supporting GitLab.com, Dedicated, and Dedicated for Federal

**Internal testing**: Use of pre-GA features by GitLab team members for validation purposes, also known as Customer Zero.

## Experiment

Experimental features:

- Are not ready for production use.
- Must be disabled by default and require explicit opt-in. Cannot be automatically enabled for users or instances without customer action.
- On multi-tenant platforms, must maintain tenant isolation such that users who opt in do not create risk for other tenants.
- May have security fixes released in canonical (in the open) depending on the current state of release maturity. Standard vulnerability remediation SLOs do not apply to experimental features.
- Require VP approval for exceptions to move to Beta without meeting stated Beta requirements.
- Have [no support available](https://about.gitlab.com/support/statement-of-support/#experiment-beta-features).
  Issues regarding such features should be opened in the [GitLab issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues).
- Might be unstable.
- Could be removed at any time.
- Might have a risk of data loss.
- Might have no documentation, or information limited to just GitLab issues or a blog.
- Might not have a finalized user experience, and might only be accessible through quick actions or API requests.
- Internal testing (Customer Zero) may use Experimental features for engineering validation. Features affecting company-wide business processes (such as onboarding, access management, or compliance workflows) require documented risk acceptance from Engineering and Security leadership.

## Beta

Beta features:

- Might not be ready for production use.
- Must be disabled by default and require explicit opt-in. Cannot be automatically enabled for users or instances without customer action.
- On multi-tenant platforms, must maintain tenant isolation such that users who opt in do not create risk for other tenants.
- Must have a documented and stakeholder-aligned plan for establishing a security release process before general availability. This process must enable secure vulnerability remediation without premature public disclosure, including how vulnerabilities are identified, tracked, prioritized, fixed, and communicated through coordinated disclosure.
- May have security fixes released in canonical (in the open) depending on the current state of release maturity. Standard vulnerability remediation SLOs do not apply to beta features.
- Must have a documented and stakeholder-aligned plan for implementing audit logging before general availability. This plan must specify what events are logged, log format and retention, how security teams will access logs, and integration points with existing audit systems.
- Require e-group approval for exceptions to move to GA without meeting stated GA requirements.
- Are [supported on a commercially-reasonable effort basis](https://about.gitlab.com/support/statement-of-support/#experiment-beta-features),
  but with the expectation that issues require extra time and assistance from development to troubleshoot.
- Might be unstable.
- Have configuration and dependencies that are unlikely to change.
- Have features and functions that are unlikely to change. However, breaking changes can occur outside of major releases
  or with less notice than for generally available features.
- Have a low risk of data loss.
- Have a user experience that is complete or near completion.
- Can be equivalent to partner "Public Preview" status.

## Public availability

Two types of public releases are available:

- Limited availability
- Generally available

Both types are production-ready, but have different scopes.

### Feature Maturity Transition Principle

When evaluating whether a feature is ready to advance maturity stages, apply the **incident response test**:

> "If this feature were already at the target maturity level and this risk manifested, would we declare an incident and push an urgent fix?"

Features should not transition to GA with risks that would trigger incident response if they occurred post-GA, including:

- Critical (S1/S2) security vulnerabilities
- Performance degradations that would breach SLA commitments
- Data integrity issues requiring customer notification
- Availability impacts affecting platform stability

This principle ensures features reach production maturity with appropriate risk posture rather than creating predictable future incidents.

### Limited availability

Limited availability features follow the same security requirements as generally available features but may be deployed on a subset of platforms or with scale limitations during initial rollout.

Limited availability features:

- Are ready for production use at a reduced scale.
- Must have an operational security release process that enables secure vulnerability remediation without premature public disclosure.
- Must have operational audit logging that enables security teams (internal and customer) to detect anomalous behavior, investigate security incidents, and answer fundamental questions about who, what, where, and when. Audit logging does not require a polished UI experience but must provide programmatic access to security-relevant events.
- Must have [operational runbook documentation](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs).
- Can be initially available on one or more GitLab platforms (GitLab.com, GitLab Self-Managed, GitLab Dedicated).
- Might initially be free, then become paid when generally available.
- Might be offered at a discount before becoming generally available.
- Might have commercial terms that change for new contracts when generally available.
- Are [fully supported](https://about.gitlab.com/support/statement-of-support/) and documented.
- Have a complete user experience aligned with GitLab design standards.

### Generally available

Generally available features:

- Are ready for production use at any scale.
- Must have a completed security review before moving to GA. Security review scope is determined by feature characteristics (customer-facing functionality, infrastructure impact, data access patterns). Features moving to GA with partially complete security reviews require E-Group approval.
- Adhere to vulnerability remediation SLOs and do not ship with any S1/S2 vulnerabilities without documented risk acceptance from E-Group. Apply the incident response test: features must not ship with risks that would trigger urgent patching if discovered post-GA.
- Must have an operational security release process that enables secure vulnerability remediation without premature public disclosure.
- Must have operational audit logging that enables security teams (internal and customer) to detect anomalous behavior, investigate security incidents, and answer fundamental questions about who, what, where, and when. Audit logging does not require a polished UI experience but must provide programmatic access to security-relevant events.
- Are [fully supported](https://about.gitlab.com/support/statement-of-support/) and documented.
- Have a complete user experience aligned with GitLab design standards.
- Must be available on all GitLab platforms (GitLab.com, GitLab.com Cells, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government).

## Exception Governance

In exceptional circumstances where business needs require deviation from these requirements, GitLab follows a documented exception process with executive approval and risk acceptance.

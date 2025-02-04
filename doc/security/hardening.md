---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Hardening Recommendations
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

This documentation is for GitLab instances where the overall system can be "hardened"
against common and even not-so-common attacks. It is not designed to completely
eradicate attacks, but to provide strong mitigation thereby reducing overall risk. Some
of the techniques apply to any GitLab deployment, such as SaaS or self-managed, while other
techniques apply to the underlying OS.

These techniques are a work in progress, and have not been tested at scale
(such as a large environments with many users). They have been tested on a self-managed
single instance running a Linux package installation, and while many of the techniques can
translated to other deployment types, they may not all work or apply.

Most of the listed recommendations provide specific recommendations or
reference choices one can make based upon the general documentation.
Through hardening, there may be impact to certain features your users may specifically
want or depend on, so you should communicate with users and do a phased rollout of hardening
changes.

The hardening instructions are in five categories for easier
understanding. They are listed in the following section.

## GitLab hardening general concepts

This details information on hardening as an approach to security and some of the larger
philosophies. For more information, see [hardening general concepts](hardening_general_concepts.md).

## GitLab application settings

Application settings made using the GitLab GUI to the application itself. For more information, see
[application recommendations](hardening_application_recommendations.md).

## GitLab CI/CD settings

CI/CD is a core component of GitLab, and while application of security principles
are based upon needs, there are several things you can do to make your CI/CD more secure.
For more information, see [CI/CD Recommendations](hardening_cicd_recommendations.md).

## GitLab configuration settings

Configuration file settings used to control and configure the
application (such as `gitlab.rb`) are documented separately. For more information, see the
[configuration recommendations](hardening_configuration_recommendations.md).

## Operating System settings

You can adjust the underlying operating system to increase overall security. For more information, see the
[operating system recommendations](hardening_operating_system_recommendations.md).

## NIST 800-53 compliance

You can configure GitLab Self-Managed to enforce compliance with the NIST 800-53 security standard. For more information, see [NIST 800-53 compliance](hardening_nist_800_53.md).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

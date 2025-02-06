---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Plan a migration from another tool to GitLab CI/CD
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Before starting a migration from another tool to GitLab CI/CD, you should begin by
developing a migration plan.

Review the advice on [managing organizational changes](#manage-organizational-changes)
first for advice on initial steps for larger migrations.

Users involved in the migration itself should review the [questions to ask before starting a migration](#technical-questions-to-ask-before-starting-a-migration),
as an important technical step for setting expectations. CI/CD tools differ in approach,
structure, and technical specifics. While some concepts map one-to-one, others require
interactive conversion.

It's important to focus on your desired end state instead of strictly translating
the behavior of your old tool.

## Manage organizational changes

An important part of transitioning to GitLab CI/CD is the cultural and organizational
changes that come with the move, and successfully managing them.

A few things that organizations have reported as helping:

- Set and communicate a clear vision of what your migration goals are, which helps
  your users understand why the effort is worth it. The value is clear when
  the work is done, but people need to be aware while it's in progress too.
- Sponsorship and alignment from the relevant leadership teams helps with the point above.
- Spend time educating your users on what's different, and share this guide
  with them.
- Finding ways to sequence or delay parts of the migration can help a lot. Importantly though,
  try not to leave things in a non-migrated (or partially-migrated) state for too
  long.
- To gain all the benefits of GitLab, moving your existing configuration over as-is,
  including any current problems, isn't enough. Take advantage of the improvements
  that GitLab CI/CD offers, and update your implementation as part of the transition.

## Technical questions to ask before starting a migration

Asking some initial technical questions about your CI/CD needs helps quickly define
the migration requirements:

- How many projects use this pipeline?
- What branching strategy is used? Feature branches? Mainline? Release branches?
- What tools do you use to build your code? For example, Maven, Gradle, or NPM?
- What tools do you use to test your code? For example JUnit, Pytest, or Jest?
- Do you use any security scanners?
- Where do you store any built packages?
- How do you deploy your code?
- Where do you deploy your code?

## Related topics

- How to migrate Atlassian Bamboo Server's CI/CD infrastructure to GitLab CI/CD, [part one](https://about.gitlab.com/blog/2022/07/06/migration-from-atlassian-bamboo-server-to-gitlab-ci/)
  and [part two](https://about.gitlab.com/blog/2022/07/11/how-to-migrate-atlassians-bamboo-servers-ci-cd-infrastructure-to-gitlab-ci-part-two/)

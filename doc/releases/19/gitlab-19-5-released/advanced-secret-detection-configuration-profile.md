---
title: Customize security configuration profiles
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/configuration/security_configuration_profiles/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/20198
categories: [ Security Testing Configuration, Secret Detection, SAST, Software Composition Analysis ]
weight: 50
---

You can now customize Secret Detection and SAST profiles in the UI. Set scan options like excluded paths, custom analyzer images, and full Git history scans once for a group, and apply them to all its projects.

Previously, a security configuration profile enabled a scanner with its default settings. Anything beyond the defaults required edits to `.gitlab-ci.yml` in each project. Now the profile includes those settings too.

Currently, customization of Dependency Scanning profiles is only available through the GraphQL API. UI customization is planned in a future release.

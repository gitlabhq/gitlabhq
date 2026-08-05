---
title: Improved array support for CI/CD inputs
stage: verify
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../ci/inputs/#access-individual-array-elements"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/issues/587657"
categories: [ Pipeline Composition ]
weight: 60
---

CI/CD inputs now have improved support for working with arrays.
Use the array index operator `[]` to access specific elements within array inputs.
This enhancement provides more flexible and powerful input interpolation capabilities in your pipeline configurations,
enabling you to reference individual array items directly without additional processing steps.

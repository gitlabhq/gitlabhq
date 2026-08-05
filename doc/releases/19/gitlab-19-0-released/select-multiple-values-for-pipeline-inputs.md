---
title: Select multiple values for pipeline inputs
stage: verify
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../ci/inputs/#array-inputs-with-options"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/566155"
categories: [ Pipeline Composition ]
weight: 70
---

Previously, you could only select a single value when selecting input options in the UI,
limiting flexibility for pipelines with more complex options.

Now when you run a pipeline with inputs from the UI, you can select multiple values from a dropdown list
and the selected values are combined into an array, for example `["option1","option2"]`.
This makes it easy to restart services on multiple instances, build multiple Docker images,
run tests with multiple tag combinations, or perform any operation across multiple targets
in a single pipeline run.

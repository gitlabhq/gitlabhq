---
title: Group-level custom review instructions for GitLab Duo
stage: ai-powered
level: primary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/gitlab_duo/customize_duo/review_instructions/#configure-custom-review-instructions-for-a-group"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21504"
categories: [ Duo Code Review ]
add_ons: [ GitLab Duo Enterprise ]
weight: 10
---

In previous versions of GitLab, you could only define custom review instructions for
GitLab Duo at the project level. Teams working across many projects in the
same group had to duplicate the same instructions in every project.

Now you can configure shared custom review instructions for an entire group and its subgroups.

Select a project in your group to use as a template. When GitLab Duo performs a code review, it combines the group-level `.gitlab/duo/mr-review-instructions.yaml` file with any instructions defined in the individual project.

Both Code Review Flow and GitLab Duo Code Review support group-level custom instructions.

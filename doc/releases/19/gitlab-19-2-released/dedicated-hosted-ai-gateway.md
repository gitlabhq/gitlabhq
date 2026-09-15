---
title: AI Gateway for GitLab Dedicated
tier: [ Ultimate ]
offering: [ gitlab_dedicated ]
stage: gitlab_dedicated
documentation_link: "../../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms/#configure-authentication-with-aws-bedrock"
work_item: https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/work_items/13486
categories: [ GitLab Dedicated ]
level: secondary
---

The AI Gateway for GitLab Dedicated runs in your AWS environment, in the same region as your GitLab Dedicated
instance. Inference requests, including code inputs, prompts, and model responses, stay within your network
and region. All GitLab Duo Agent Platform inference requests stay in the same audit scope as your GitLab Dedicated
instance. The AI Gateway for GitLab Dedicated is enabled by default, with no setup required.

Optionally, you can use Bring Your Own Model (BYOM) to connect to your own cloud-hosted models. You can power GitLab Duo Agent Platform capabilities with the models you choose, in your region, under your access controls.

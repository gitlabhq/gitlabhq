---
title: IAM roles for Amazon Bedrock self-hosted models
tier: [ Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: ai_platform
documentation_link: "../../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms/#assume-an-iam-role-with-aws-bedrock"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/542393
categories: [ Model Selection ]
level: secondary
weight: 50
---

Previously, you could not control which AWS credentials
the AI Gateway used for your Amazon Bedrock models.
A single AWS identity needed access to all these models.

With this release, you can specify an IAM role for each model,
and the AI Gateway assumes that role when calling the model.
This way, each model gets only the AWS access it needs,
even when the role is in another AWS account.

---
owning-stage: "~devops::ai-powered"
description: 'AI Context Management ADR 001: Keeping AI Context Policy Management close to AI Context Retriever'
---

# AI Context Management ADR 001: Keeping AI Context Policy Management close to AI Context Retriever

## Summary

To manage AI Context effectively and ensure flexible and scalable solutions, AI Context Policy Management will reside in the
same environment, as the AI Context Retriever, and, as a result, as close to the context fetching mechanism as possible. This
approach aims to reduce latency and improve user control over the contextual information sent to AI systems.

## Context

The original blueprint outlined the necessity of a flexible AI Context Management system to provide accurate and relevant
AI responses while addressing security and trust concerns. It suggested that AI Context Policy Management should act as
a filtering solution between the context resolver and the context fetcher in the AI Context Retriever. However, the
blueprint did not specify the exact location for the AI Context Policy Management within the system.

During [a sync discussion](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155707#note_1978675445), it was determined
that placing the AI Context Policy Management close to AI Context Retriever would provide significant benefits. This decision
aligns with our approach of having shared components, like the AI Gateway and the Duo Chat UI, to ensure consistency and reduce
redundancy across different environments.

## Decision

AI Context Management will happen as close to the user's interaction with Duo features as possible. As a result, the [AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist) will only receive context that is policy-compliant.

Users interact with Duo features in many different environments, including their IDE and the GitLab Web UI. Rather than retrieving the context from this environment and sending it to the AI Gateway for filtering based on the AI Context Policy, this decision states that the AI Context Retriever will filter this content *before* it reaches the AI Gateway.

This decision allows for better security, flexibility and scalability, enabling dynamic user interactions and immediate feedback on context validation.

## Consequences

- *Implementation Complexity*: Users must create, modify, and remove context policies in each environment where they are
interacting with Duo features. This requires multiple implementations to support different environments.
- *Flexibility and Scalability*: Storing AI Context Policy Management close the AI Context Retriever allows for more flexible
and scalable policy implementations tailored to specific environments, such as IDEs and the Web.
- *Reduced Latency*: Filtering out unwanted context at the earliest possible stage reduces latency and ensures that only
the necessary information is sent to the AI models.
- *User Experience*: This approach facilitates dynamic UX, providing instant feedback to users in case of failed context
validation. Users can manage their supplementary context more effectively through a user-friendly interface.
- *Security*: By managing policies closer to the content retrieving mechanism, sensitive information can be filtered out
locally, enhancing security and user trust.

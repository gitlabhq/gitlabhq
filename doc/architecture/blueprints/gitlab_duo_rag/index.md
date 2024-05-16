---
status: proposed
creation-date: "2024-01-25"
authors: [ "@shinya.maeda", "@mikolaj_wawrzyniak" ]
coach: [ "@stanhu" ]
approvers: [ "@pwietchner", "@oregand", "@tlinz" ]
owning-stage: "~devops::ai-powered"
participating-stages: ["~devops::data stores", "~devops::create"]
---

# Retrieval Augmented Generation (RAG) for GitLab Duo on self-managed

RAG is an application architecture used to provide knowledge to a large language model that doesn't exist in its training set, so that it can use that knowledge to answer user questions. To learn more about RAG, see [RAG for GitLab](../gitlab_rag/index.md).

## Goals of this blueprint

This blueprint aims to drive a decision for a RAG solution for GitLab Duo on self-managed, specifically for shipping GitLab Duo with access to GitLab documentation. We outline three potential solutions, including PoCs for each to demonstrate feasibility for this use case.

## Constraints

- The solution must be viable for self-managed customers to run and maintain
- The solution must be shippable in 1-2 milestones <!-- I don't actually know that this is true, just adding an item for time constraint -->
- The solution should be low-lock-in, since we are still determining our long term technical solution(s) for RAG at GitLab

## Proposals for GitLab Duo Chat RAG for GitLab documentation

The following solutions have been proposed and evaluated for the GitLab Duo Chat for GitLab documentation use case:

- [Vertex AI Search](vertex_ai_search.md)
- [Elasticsearch](elasticsearch.md)
- [PostgreSQL with PGVector extension](postgresql.md)

You can read more about how each evaluatoin was conducted in the links above.

## Chosen solution

[Vertex AI Search](vertex_ai_search.md) is going to be implemented due to the low lock-in and being able to reach customers quickly. It could be moved over to another solution in the future.

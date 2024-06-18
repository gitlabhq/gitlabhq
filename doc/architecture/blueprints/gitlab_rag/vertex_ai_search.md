---
status: proposed
creation-date: "2024-02-20"
authors: [ "@bvenker", "@mikolaj_wawrzyniak" ]
coach: [ "@stanhu" ]
approvers: [ "@pwietchner", "@oregand", "@shinya.meda", "@mikolaj_wawrzyniak" ]
owning-stage: "~devops::data stores"
participating-stages: ["~devops::ai-powered", "~devops::create"]
---

# Vertex AI Search

This page explains how to retrieve data from Google Vertex AI Search for [RAG](index.md).

## Overview

Some of our data are public resources that don't require [data access check](index.md#data-access-policy) when retrieving.
These data are often identical across GitLab instances so it's redundant to ingest the same data into every single database.
It'd be more efficient to serve the data from the single service.

We can use [Vertex AI Search](https://cloud.google.com/products/agent-builder?hl=en) in this case.
It can search at scale, with high queries per second (QPS), high recall, low latency, and cost efficiency.

This approach allows us to minimize code that we can't update on a customer's behalf, which means avoiding hard-coding AI-related logic in the GitLab monolith codebase. We can retain the flexibility to make changes in our product without asking customers to upgrade their GitLab version.
This is same with the [AI Gateway](../ai_gateway/index.md)'s design principle.

```mermaid
flowchart LR
  subgraph GitLab managed
    subgraph AIGateway
        VertexAIClient["VertexAIClient"]
    end

    subgraph Vertex AI Search["Vertex AI Search"]
        subgraph SearchApp1["App"]
        direction LR
        App1DataStore(["BigQuery"])
        end
        subgraph SearchApp2["App"]
        direction LR
        App2DataStore(["Cloud Storage / Website URLs"])
        end
    end
  end

  subgraph SM or SaaS GitLab
    DuoFeatureA["Duo feature A"]
    DuoFeatureB["Duo feature B"]
  end

  DuoFeatureA -- Semantic search --- VertexAIClient
  DuoFeatureB -- Semantic search --- VertexAIClient
  VertexAIClient -- Search from Gitlab Docs --- SearchApp1
  VertexAIClient -- Search from other data store --- SearchApp2
```

## Limitations

- Data **must be** [GREEN level](index.md#data-access-policy) and publicly shareable.
  - Examples:
  - GitLab documentations (`gitlab-org/gitlab/doc`, `gitlab-org/gitlab-runner/docs`, `gitlab-org/omnibus-gitlab/doc`, etc)
  - Dynamically construct few-shot prompt templates with [Example selectors](https://python.langchain.com/v0.1/docs/modules/model_io/prompts/example_selectors/).

**IMPORTANT: We do NOT persist customer data into Vertex AI Search. See the other solutions for persisting customer data.**

## Performance and scalability implications

- GitLab-side: Vertex AI Search can [search at scale, with high queries per second (QPS), high recall, low latency, and cost efficiency](https://cloud.google.com/vertex-ai/docs/vector-search/overview).
- GitLab-side: Vertex AI Search supports [global and multi-region deployments](https://cloud.google.com/generative-ai-app-builder/docs/locations).
- Customer-side: The outbound requests from their GitLab Self-managed instances could cause more network latency than retrieving from a local vector store.
  This latency issue is addressable by multi-region deployments.

## Availability

- Customer-side: Air-gapped solutions can't be supported due to the required access to AI Gateway (`cloud.gitlab.com`).
  This concern would be negligible since GitLab Duo already requires the access.
- Customer-side: Since the service is the single point of failure, retrievers stop working when the service is down.

## Cost implications

- GitLab-side: See [Vertex AI Search pricing](https://cloud.google.com/generative-ai-app-builder/pricing).
- Customer-side: No additional cost required.

## Maintenance

- GitLab-side: GitLab needs to maintain the data store (e.g. Structured data in Bigquery or unstructured data in Cloud Storage). Google automatically detects the schema and indexes the stored data.
- Customer-side: No maintenance required.

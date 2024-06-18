---
status: proposed
creation-date: "2024-01-25"
authors: [ "@shinya.maeda", "@mikolaj_wawrzyniak" ]
coach: [ "@stanhu" ]
approvers: [ "@pwietchner", "@oregand", "@tlinz" ]
owning-stage: "~devops::ai-powered"
participating-stages: ["~devops::data stores", "~devops::create"]
---

# Elasticsearch

For more information on Elasticsearch and RAG broadly, see the [Elasticsearch article](../gitlab_rag/elasticsearch.md) in [RAG at GitLab](../gitlab_rag/index.md).

## Retrieve GitLab Documentation

A [proof of concept](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145392) was done to switch the documentation embeddings from being stored in the embedding database to being stored on Elasticsearch.

### Synchronizing embeddings with data source

The same procedure used by [PostgreSQL](postgresql.md) can be followed to keep the embeddings up to date in Elasticsearch.

### Retrieval

To get the nearest neighbours, the following query can be executed an index containing the embeddings:

```ruby
{
  "knn": {
    "field": vector_field_containing_embeddings,
    "query_vector": embedding_for_question,
    "k": limit,
    "num_candidates": number_of_candidates_to_compare
  }
}
```

### Requirements to get to self-managed

- Productionalize the PoC [MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145392)
- Get more self-managed instances to install Elasticsearch by [shipping GitLab with Elasticsearch](https://gitlab.com/gitlab-org/gitlab/-/issues/438178). Elastic gave their approval to ship with the free license. The work required for making it easy for customers to host Elasticsearch is more than 2 milestones.

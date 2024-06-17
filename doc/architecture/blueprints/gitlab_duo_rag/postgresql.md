---
status: proposed
creation-date: "2024-01-25"
authors: [ "@shinya.maeda", "@mikolaj_wawrzyniak" ]
coach: [ "@stanhu" ]
approvers: [ "@pwietchner", "@oregand", "@tlinz" ]
owning-stage: "~devops::ai-powered"
participating-stages: ["~devops::data stores", "~devops::create"]
---

# PostgreSQL

## Retrieve GitLab Documentation

PGVector is currently being used for the retrieval of relevant documentation for GitLab Duo chat's RAG.

A separate `embedding` database runs alongside `geo` and `main` which has the `pg-vector` extension installed and contains embeddings for GitLab documentation.

- Statistics (as of January 2024):
  - Data type: Markdown written in natural language (Unstructured)
  - Data access level: Green (No authorization required)
  - Data source: `https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc`
  - Data size: 147 MB in `vertex_gitlab_docs`. 2194 pages.
  - Service: `https://docs.gitlab.com/` ([source repo](https://gitlab.com/gitlab-org/gitlab-docs)
  - Example of user input: "How do I create an issue?"
  - Example of expected AI-generated response: "To create an issue:\n\nOn the left sidebar, select Search or go to and find your project.\n\nOn the left sidebar, select Plan > Issues, and then, in the upper-right corner, select New issue."

### Synchronizing embeddings with data source

Here is the overview of synchronizing process that is currently running in GitLab.com:

1. Load documentation files of the GitLab instance. i.e. `doc/**/*.md`.
1. Compare the checksum of each file to detect an new, update or deleted documents.
1. If a doc is added or updated:
   1. Split the docs with the following strategy:
      - Text splitter: Split by new lines (`\n`). Subsequently split by 100~1500 chars.
   1. Bulk-fetch embeddings of the chunks from `textembedding-gecko` model (768 dimensions).
   1. Bulk-insert the embeddings into the `vertex_gitlab_docs` table.
   1. Cleanup the older embeddings.
1. If a doc is deleted:
   1. Delete embeddings of the page.

As of today, there are 17345 rows (chunks) on `vertex_gitlab_docs` table on GitLab.com.

For Self-managed instances, we serve embeddings from AI Gateway and GCP's Cloud Storage,
so the above process can be simpler:

1. Download an embedding package from Cloud Storage through AI Gateway API.
1. Bulk-insert the embeddings into the `vertex_gitlab_docs` table.
1. Delete older embeddings.

We generate this embeddings package before GitLab monthly release.
Sidekiq cron worker automatically renews the embeddings by comparing the embedding version and the GitLab version.
If it's outdated, it will download the new embedding package.

Going further, we can consolidate the business logic between SaaS and Self-managed by generating the package every day (or every grpd deployment).
This is to reduce the point of failure in the business logic and let us easily reproduce an issue that reported by Self-managed users.

Here is the current table schema:

```sql
CREATE TABLE vertex_gitlab_docs (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    version integer DEFAULT 0 NOT NULL,                                 -- For replacing the old embeddings by new embeddings (e.g. when doc is updated)
    embedding vector(768),                                              -- Vector representation of the chunk
    url text NOT NULL,
    content text NOT NULL,                                              -- Chunked data
    metadata jsonb NOT NULL,                                            -- Additional metadata e.g. page URL, file name
    CONSTRAINT check_2e35a254ce CHECK ((char_length(url) <= 2048)),
    CONSTRAINT check_93ca52e019 CHECK ((char_length(content) <= 32768))
);

CREATE INDEX index_vertex_gitlab_docs_on_version_and_metadata_source_and_id ON vertex_gitlab_docs USING btree (version, ((metadata ->> 'source'::text)), id);
CREATE INDEX index_vertex_gitlab_docs_on_version_where_embedding_is_null ON vertex_gitlab_docs USING btree (version) WHERE (embedding IS NULL);
```

### Retrieval

After the embeddings are ready, GitLab-Rails can retrieve chunks in the following steps:

1. Fetch embedding of the user input from `textembedding-gecko` model (768 dimensions).
1. Query to `vertex_gitlab_docs` table for finding the nearest neighbors. e.g.:

   ```sql
   SELECT *
   FROM vertex_gitlab_docs
   ORDER BY vertex_gitlab_docs.embedding <=> '[vectors of user input]'               -- nearest neighbors by cosine distance
   LIMIT 10
   ```

### Requirements to get to self-managed

All instances of GitLab have postgres running but allowing instances to administer a separate database for embeddings or combining the embeddings into the main database would require some effort which spans more than a milestone.

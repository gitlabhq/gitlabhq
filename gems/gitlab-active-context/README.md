# GitLab Active Context

`ActiveContext` is a gem used for interfacing with vector stores like Elasticsearch, OpenSearch and Postgres with PGVector for storing and querying vectors.

## How it works

See [Active Context](https://docs.gitlab.com/development/ai_features/semantic_search/active_context/).

## Installation

TODO

## Getting started

See [Configuring the Active Context initializer](https://docs.gitlab.com/development/ai_features/semantic_search/#configuring-the-active-context-initializer).

## Usage

See [Adding Semantic Search Collections](https://docs.gitlab.com/development/ai_features/semantic_search/adding_semantic_search_collections/)

## How to

- [Setting or switching an embedding model](https://docs.gitlab.com/development/ai_features/semantic_search/#setting-or-switching-an-embedding-model)

## Contributing

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Development guidelines

1. Avoid adding too many changes in the monolith, keep concerns in the gem
1. It's okay to reuse lib-type GitLab logic in the gem and stub it in specs. Avoid duplication this kind of logic into the code for long-term maintainability.
1. Avoid referencing application logic from the monolith in the gem

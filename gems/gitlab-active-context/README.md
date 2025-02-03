# GitLab Active Context

`ActiveContext` is a gem used for interfacing with vector stores like Elasticsearch, OpenSearch and Postgres with PGVector for storing and querying vectors.

## How it works

See [How it works](doc/how_it_works.md).

## Installation

TODO

## Getting started

See [Getting started](doc/getting_started.md).

## Usage

Follow the guides to set up a new collection:

1. Use an existing queue or [set up a new queue](doc/usage.md#registering-a-queue)
1. Use an existing reference class or [set up a new reference class](doc/usage.md#adding-a-new-reference-type)
1. [Add a collection class](doc/usage.md#adding-a-new-collection)

## Contributing

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Development guidelines

1. Avoid adding too many changes in the monolith, keep concerns in the gem
1. It's okay to reuse lib-type GitLab logic in the gem and stub it in specs. Avoid duplication this kind of logic into the code for long-term maintainability.
1. Avoid referencing application logic from the monolith in the gem

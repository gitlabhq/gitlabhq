# GitLab CI API

## Purpose

Main purpose of GitLab CI API is to provide necessary data and context for
GitLab CI Runners.

For consumer API take a look at this [documentation](../../api/README.md) where
you will find all relevant information.

## API Prefix

Current CI API prefix is `/ci/api/v1`.

You need to prepend this prefix to all examples in this documentation, like:

    GET /ci/api/v1/builds/:id/artifacts

## Resources

- [Builds](builds.md)
- [Runners](runners.md)

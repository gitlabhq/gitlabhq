# GitLab CI API

## Purpose

The main purpose of GitLab CI API is to provide the necessary data and context
for GitLab CI Runners.

All relevant information about the consumer API can be found in a
[separate document](../../api/README.md).

## API Prefix

The current CI API prefix is `/ci/api/v1`.

You need to prepend this prefix to all examples in this documentation, like:

```bash
GET /ci/api/v1/builds/:id/artifacts
```

## Resources

- [Builds](builds.md)
- [Runners](runners.md)

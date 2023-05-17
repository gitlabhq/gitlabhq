## Frontend Integration Specs

This directory contains Frontend integration specs. Go to `spec/frontend` if you're looking for Frontend unit tests.

Frontend integration specs:

- Mock out the Backend.
- Don't test individual components, but instead test use cases.
- Are expected to run slower than unit tests.
- Could end up having their own environment.

As a result, they deserve their own special place.

## Run frontend integration tests locally

The frontend integration specs are all about testing integration frontend bundles against a
mock backend. The mock backend is built using the fixtures and GraphQL schema.

We can generate the necessary fixtures and GraphQL schema by running:

```shell
bundle exec rake frontend:fixtures gitlab:graphql:schema:dump
```

You can also download those fixtures from the package registry: see [download fixtures](https://docs.gitlab.com/ee/development/testing_guide/frontend_testing.html#download-fixtures) for more info.

Then we can use [Jest](https://jestjs.io/) to run the frontend integration tests:

```shell
yarn jest:integration <path-to-integration-test>
```

If you'd like to run the frontend integration specs **without** setting up the fixtures first, then you
can set `GL_IGNORE_WARNINGS=1`:

```shell
GL_IGNORE_WARNINGS=1 yarn jest:integration <path-to-integration-test>
```

The `jest-integration` job executes the frontend integration tests in our
CI/CD pipelines.

## References

- https://docs.gitlab.com/ee/development/testing_guide/testing_levels.html#frontend-integration-tests
- https://gitlab.com/gitlab-org/gitlab/-/issues/208800

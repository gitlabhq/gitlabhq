## Frontend Integration Specs

This directory contains Frontend integration specs. Go to `spec/frontend` if you're looking for Frontend unit tests.

Frontend integration specs:

- Mock out the Backend.
- Don't test individual components, but instead test use cases.
- Are expected to run slower than unit tests.
- Could end up having their own environment.

As a result, they deserve their own special place.

## References

- https://docs.gitlab.com/ee/development/testing_guide/testing_levels.html#frontend-integration-tests
- https://gitlab.com/gitlab-org/gitlab/-/issues/208800

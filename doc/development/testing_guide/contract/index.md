---
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Contract testing

Contract tests consist of two parts — consumer tests and provider tests. A simple example of a consumer and provider relationship is between the frontend and backend. The frontend would be the consumer and the backend is the provider. The frontend consumes the API that is provided by the backend. The test helps ensure that these two sides follow an agreed upon contract and any divergence from the contract triggers a meaningful conversation to prevent breaking changes from slipping through.

Consumer tests are similar to unit tests with each spec defining a requests and an expected mock responses and creating a contract based on those definitions. On the other hand, provider tests are similar to integration tests as each spec takes the request defined in the contract and runs that request against the actual service which is then matched against the contract to validate the contract.

You can check out the existing contract tests at:

- [`spec/contracts/consumer/specs`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/spec/contracts/consumer/specs) for the consumer tests.
- [`spec/contracts/provider/specs`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/spec/contracts/provider/specs) for the provider tests.

The contracts themselves are stored in [`/spec/contracts/contracts`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/spec/contracts/contracts) at the moment. The plan is to use [PactBroker](https://docs.pact.io/pact_broker/docker_images) hosted in AWS or another similar service.

## Write the tests

- [Writing consumer tests](consumer_tests.md)
- [Writing provider tests](provider_tests.md)

### Run the consumer tests

Before running the consumer tests, go to `spec/contracts/consumer` and run `npm install`. To run all the consumer tests, you just need to run `npm test -- /specs`. Otherwise, to run a specific spec file, replace `/specs` with the specific spec filename.

### Run the provider tests

Before running the provider tests, make sure your GDK (GitLab Development Kit) is fully set up and running. You can follow the setup instructions detailed in the [GDK repository](https://gitlab.com/gitlab-org/gitlab-development-kit/-/tree/main). To run the provider tests, you use Rake tasks that are defined in [`./lib/tasks/contracts.rake`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/tasks/contracts.rake). To get a list of all the Rake tasks related to the provider tests, run `bundle exec rake -T contracts`. For example:

```shell
$ bundle exec rake -T contracts
rake contracts:mr:pact:verify:diffs                # Verify provider against the consumer pacts for diffs
rake contracts:mr:pact:verify:discussions          # Verify provider against the consumer pacts for discussions
rake contracts:mr:pact:verify:metadata             # Verify provider against the consumer pacts for metadata
rake contracts:mr:test:merge_request[contract_mr]  # Run all merge request contract tests
```

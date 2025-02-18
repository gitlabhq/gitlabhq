---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Writing consumer tests
---

This tutorial guides you through writing a consumer test from scratch. To start, the consumer tests are written using [`jest-pact`](https://github.com/pact-foundation/jest-pact) that builds on top of [`pact-js`](https://github.com/pact-foundation/pact-js). This tutorial shows you how to write a consumer test for the `/discussions.json` REST API endpoint, which is `/:namespace_name/:project_name/-/merge_requests/:id/discussions.json`, that is called in the `MergeRequests#show` page. For an example of a GraphQL consumer test, see [`spec/contracts/consumer/specs/project/pipelines/show.spec.js`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/spec/contracts/consumer/specs/project/pipelines/show.spec.js).

## Create the skeleton

Start by creating the skeleton of a consumer test. Since this is for a request in the `MergeRequests#show` page, under `spec/contracts/consumer/specs/project/merge_requests`, create a file called `show.spec.js`.
Then, populate it with the following function and parameters:

- [`pactWith`](#the-pactwith-function)
- [`PactOptions`](#the-pactoptions-parameter)
- [`PactFn`](#the-pactfn-parameter)

For more information about how the contract test directory is structured, see [Test suite folder structure](_index.md#test-suite-folder-structure).

### The `pactWith` function

The Pact consumer test is defined through the `pactWith` function that takes `PactOptions` and the `PactFn`.

```javascript
import { pactWith } from 'jest-pact';

pactWith(PactOptions, PactFn);
```

### The `PactOptions` parameter

`PactOptions` with `jest-pact` introduces [additional options](https://github.com/pact-foundation/jest-pact/blob/dce370c1ab4b7cb5dff12c4b62246dc229c53d0e/README.md#defaults) that build on top of the ones [provided in `pact-js`](https://github.com/pact-foundation/pact-js#constructor). In most cases, you define the `consumer`, `provider`, `log`, and `dir` options for these tests.

```javascript
import { pactWith } from 'jest-pact';

pactWith(
  {
    consumer: 'MergeRequests#show',
    provider: 'GET discussions',
    log: '../logs/consumer.log',
    dir: '../contracts/project/merge_requests/show',
  },
  PactFn
);
```

For more information about how to name consumers and providers, see [Naming conventions](_index.md#naming-conventions).

### The `PactFn` parameter

The `PactFn` is where your tests are defined. This is where you set up the mock provider and where you can use the standard Jest methods like [`Jest.describe`](https://jestjs.io/docs/api#describename-fn), [`Jest.beforeEach`](https://jestjs.io/docs/api#beforeeachfn-timeout), and [`Jest.it`](https://jestjs.io/docs/api#testname-fn-timeout). For more information, see [https://jestjs.io/docs/api](https://jestjs.io/docs/api).

```javascript
import { pactWith } from 'jest-pact';

pactWith(
  {
    consumer: 'MergeRequests#show',
    provider: 'GET discussions',
    log: '../logs/consumer.log',
    dir: '../contracts/project/merge_requests/show',
  },

  (provider) => {
    describe('GET discussions', () => {
      beforeEach(() => {

      });

      it('return a successful body', async () => {

      });
    });
  },
);
```

## Set up the mock provider

Before you run your test, set up the mock provider that handles the specified requests and returns a specified response. To do that, define the state and the expected request and response in an [`Interaction`](https://github.com/pact-foundation/pact-js/blob/master/src/dsl/interaction.ts).

For this tutorial, define four attributes for the `Interaction`:

1. `state`: A description of what the prerequisite state is before the request is made.
1. `uponReceiving`: A description of what kind of request this `Interaction` is handling.
1. `withRequest`: Where you define the request specifications. It contains the request `method`, `path`, and any `headers`, `body`, or `query`.
1. `willRespondWith`: Where you define the expected response. It contains the response `status`, `headers`, and `body`.

After you define the `Interaction`, add that interaction to the mock provider by calling `addInteraction`.

```javascript
import { pactWith } from 'jest-pact';
import { Matchers } from '@pact-foundation/pact';

pactWith(
  {
    consumer: 'MergeRequests#show',
    provider: 'GET discussions',
    log: '../logs/consumer.log',
    dir: '../contracts/project/merge_requests/show',
  },

  (provider) => {
    describe('GET discussions', () => {
      beforeEach(() => {
        const interaction = {
          state: 'a merge request with discussions exists',
          uponReceiving: 'a request for discussions',
          withRequest: {
            method: 'GET',
            path: '/gitlab-org/gitlab-qa/-/merge_requests/1/discussions.json',
            headers: {
              Accept: '*/*',
            },
          },
          willRespondWith: {
            status: 200,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: Matchers.eachLike({
              id: Matchers.string('fd73763cbcbf7b29eb8765d969a38f7d735e222a'),
              project_id: Matchers.integer(6954442),
              ...
              resolved: Matchers.boolean(true)
            }),
          },
        };
        provider.addInteraction(interaction);
      });

      it('return a successful body', async () => {

      });
    });
  },
);
```

### Response body `Matchers`

Notice how we use `Matchers` in the `body` of the expected response. This allows us to be flexible enough to accept different values but still be strict enough to distinguish between valid and invalid values. We must ensure that we have a tight definition that is neither too strict nor too lax. Read more about the [different types of `Matchers`](https://github.com/pact-foundation/pact-js/blob/master/docs/matching.md). We are currently using the V2 matching rules.

## Write the test

After the mock provider is set up, you can write the test. For this test, you make a request and expect a particular response.

First, set up the client that makes the API request. To do that, create `spec/contracts/consumer/resources/api/project/merge_requests.js` and add the following API request. If the endpoint is a GraphQL, then we create it under `spec/contracts/consumer/resources/graphql` instead.

```javascript
import axios from 'axios';

export async function getDiscussions(endpoint) {
  const { url } = endpoint;

  return axios({
    method: 'GET',
    baseURL: url,
    url: '/gitlab-org/gitlab-qa/-/merge_requests/1/discussions.json',
    headers: { Accept: '*/*' },
  })
}
```

After that's set up, import it to the test file and call it to make the request. Then, you can make the request and define your expectations.

```javascript
import { pactWith } from 'jest-pact';
import { Matchers } from '@pact-foundation/pact';

import { getDiscussions } from '../../../resources/api/project/merge_requests';

pactWith(
  {
    consumer: 'MergeRequests#show',
    provider: 'GET discussions',
    log: '../logs/consumer.log',
    dir: '../contracts/project/merge_requests/show',
  },

  (provider) => {
    describe('GET discussions', () => {
      beforeEach(() => {
        const interaction = {
          state: 'a merge request with discussions exists',
          uponReceiving: 'a request for discussions',
          withRequest: {
            method: 'GET',
            path: '/gitlab-org/gitlab-qa/-/merge_requests/1/discussions.json',
            headers: {
              Accept: '*/*',
            },
          },
          willRespondWith: {
            status: 200,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: Matchers.eachLike({
              id: Matchers.string('fd73763cbcbf7b29eb8765d969a38f7d735e222a'),
              project_id: Matchers.integer(6954442),
              ...
              resolved: Matchers.boolean(true)
            }),
          },
        };
      });

      it('return a successful body', async () => {
        const discussions = await getDiscussions({
          url: provider.mockService.baseUrl,
        });

        expect(discussions).toEqual(Matchers.eachLike({
          id: 'fd73763cbcbf7b29eb8765d969a38f7d735e222a',
          project_id: 6954442,
          ...
          resolved: true
        }));
      });
    });
  },
);
```

There we have it! The consumer test is now set up. You can now try [running this test](_index.md#run-the-consumer-tests).

## Improve test readability

As you may have noticed, the request and response definitions can get large. This results in the test being difficult to read, with a lot of scrolling to find what you want. You can make the test easier to read by extracting these out to a `fixture`.

Create a file under `spec/contracts/consumer/fixtures/project/merge_requests` called `discussions.fixture.js` where you will place the `request` and `response` definitions.

```javascript
import { Matchers } from '@pact-foundation/pact';

const body = Matchers.eachLike({
  id: Matchers.string('fd73763cbcbf7b29eb8765d969a38f7d735e222a'),
  project_id: Matchers.integer(6954442),
  ...
  resolved: Matchers.boolean(true)
});

const Discussions = {
  body: Matchers.extractPayload(body),

  success: {
    status: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
    body,
  },

  scenario: {
    state: 'a merge request with discussions exists',
    uponReceiving: 'a request for discussions',
  },

  request: {
    withRequest: {
      method: 'GET',
      path: '/gitlab-org/gitlab-qa/-/merge_requests/1/discussions.json',
      headers: {
        Accept: '*/*',
      },
    },
  },
};

exports.Discussions = Discussions;
```

With all of that moved to the `fixture`, you can simplify the test to the following:

```javascript
import { pactWith } from 'jest-pact';

import { Discussions } from '../../../fixtures/project/merge_requests/discussions.fixture';
import { getDiscussions } from '../../../resources/api/project/merge_requests';

const CONSUMER_NAME = 'MergeRequests#show';
const PROVIDER_NAME = 'GET discussions';
const CONSUMER_LOG = '../logs/consumer.log';
const CONTRACT_DIR = '../contracts/project/merge_requests/show';

pactWith(
  {
    consumer: CONSUMER_NAME,
    provider: PROVIDER_NAME,
    log: CONSUMER_LOG,
    dir: CONTRACT_DIR,
  },

  (provider) => {
    describe(PROVIDER_NAME, () => {
      beforeEach(() => {
        const interaction = {
          ...Discussions.scenario,
          ...Discussions.request,
          willRespondWith: Discussions.success,
        };
        provider.addInteraction(interaction);
      });

      it('return a successful body', async () => {
        const discussions = await getDiscussions({
          url: provider.mockService.baseUrl,
        });

        expect(discussions).toEqual(Discussions.body);
      });
    });
  },
);
```

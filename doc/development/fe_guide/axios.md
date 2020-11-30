---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Axios

We use [Axios](https://github.com/axios/axios) to communicate with the server in Vue applications and most new code.

In order to guarantee all defaults are set you *should not use Axios directly*, you should import Axios from `axios_utils`.

## CSRF token

All our requests require a CSRF token.
To guarantee this token is set, we are importing [Axios](https://github.com/axios/axios), setting the token, and exporting `axios` .

This exported module should be used instead of directly using Axios to ensure the token is set.

## Usage

```javascript
  import axios from './lib/utils/axios_utils';

  axios.get(url)
    .then((response) => {
      // `data` is the response that was provided by the server
      const data = response.data;

      // `headers` the headers that the server responded with
      // All header names are lower cased
      const paginationData = response.headers;
    })
    .catch(() => {
      //handle the error
    });
```

## Mock Axios response in tests

To help us mock the responses we are using [axios-mock-adapter](https://github.com/ctimmerm/axios-mock-adapter).

Advantages over [`spyOn()`](https://jasmine.github.io/api/edge/global.html#spyOn):

- no need to create response objects
- does not allow call through (which we want to avoid)
- simple API to test error cases
- provides `replyOnce()` to allow for different responses

We have also decided against using [Axios interceptors](https://github.com/axios/axios#interceptors) because they are not suitable for mocking.

### Example

```javascript
  import axios from '~/lib/utils/axios_utils';
  import MockAdapter from 'axios-mock-adapter';

  let mock;
  beforeEach(() => {
    // This sets the mock adapter on the default instance
    mock = new MockAdapter(axios);
    // Mock any GET request to /users
    // arguments for reply are (status, data, headers)
    mock.onGet('/users').reply(200, {
      users: [
        { id: 1, name: 'John Smith' }
      ]
    });
  });

  afterEach(() => {
    mock.restore();
  });
```

### Mock poll requests in tests with Axios

Because polling function requires a header object, we need to always include an object as the third argument:

```javascript
  mock.onGet('/users').reply(200, { foo: 'bar' }, {});
```

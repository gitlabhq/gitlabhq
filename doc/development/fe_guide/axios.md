# Axios
We use [axios][axios] to communicate with the server in Vue applications and most new code.

In order to guarantee all defaults are set you *should not use `axios` directly*, you should import `axios` from `axios_utils`.

## CSRF token
All our request require a CSRF token.
To guarantee this token is set, we are importing [axios][axios], setting the token, and exporting `axios` .

This exported module should be used instead of directly using `axios` to ensure the token is set.

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

## Mock axios response in tests

To help us mock the responses we are using [axios-mock-adapter][axios-mock-adapter].

Advantages over [`spyOn()`]:

- no need to create response objects
- does not allow call through (which we want to avoid)
- simple API to test error cases 
- provides `replyOnce()` to allow for different responses

We have also decided against using [axios interceptors] because they are not suitable for mocking.

[axios interceptors]: https://github.com/axios/axios#interceptors
[`spyOn()`]: https://jasmine.github.io/api/edge/global.html#spyOn

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

### Mock poll requests in tests with axios

Because polling function requires a header object, we need to always include an object as the third argument:

```javascript
  mock.onGet('/users').reply(200, { foo: 'bar' }, {});
```

[axios]: https://github.com/axios/axios
[axios-instance]: #creating-an-instance
[axios-interceptors]: https://github.com/axios/axios#interceptors
[axios-mock-adapter]: https://github.com/ctimmerm/axios-mock-adapter

# Network requests

We also use [Axios][axios] to handle all of our network requests. Some of our legacy codebase still use Vue-Resource but we are in the process of transitioning that to Axios.

## Creating requests

Since all of our network requests require a CSRF token, we automatically bundle that into a utility file called `axios_utils`.

```
import axios from './lib/utils/axios_utils';

// this request will include a CSRF token
axios.get(url)
  .then((response) => {})
  .catch(() => {});
```

## Testing

When writing tests related to axios, we recommend mocking the responses using the [axios-mock-adapter].

```
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

We will have to include an empty object as the third argument when mocking poll requests as they require a header object.

```
mock.onGet('/pollingUrl').reply(200, { user: 1 }, {});
```

[axios]: https://github.com/axios/axios
[axios-mock-adapter]: https://github.com/ctimmerm/axios-mock-adapter

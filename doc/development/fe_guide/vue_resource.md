# Vue Resouce
In Vue applications we use [vue-resource][vue-resource-repo] to communicate with the server.

## HTTP Status Codes

### `.json()`
When making a request to the server, you will most likely need to access the body of the response.
Use `.json()` to convert. Because `.json()` returns a Promise the follwoing structure should be used:

  ```javascript
  service.get('url')
    .then(resp => resp.json())
    .then((data) => {
      this.store.storeData(data);
    })
    .catch(() => new Flash('Something went wrong'));
  ```


When using `Poll` (`app/assets/javascripts/lib/utils/poll.js`), the `successCallback` needs to handle `.json()` as a Promise:
  ```javascript
  successCallback: (response) => {
    return response.json().then((data) => {
      // handle the response
    });
  }
  ```

### 204
Some endpoints - usually `delete` endpoints - return `204` as the success response.
When handling `204 - No Content` responses, we cannot use `.json()` since it tries to parse the non-existant body content.

When handling `204` responses, do not use `.json`, otherwise the promise will throw an error and will enter the `catch` statement:

```javascript
  Vue.http.delete('path')
    .then(() => {
      // success!
    })
    .catch(() => {
      // handle error
    })
```

## Headers
Headers are being parsed into a plain object in an interceptor.
In Vue-resource 1.x `headers` object was changed into an `Headers` object. In order to not change all old code, an interceptor was added.

If you need to write a unit test that takes the headers in consideration, you need to include an interceptor to parse the headers after your test interceptor.
You can see an example in `spec/javascripts/environments/environment_spec.js`:
  ```javascript
  import { headersInterceptor } from './helpers/vue_resource_helper';

  beforeEach(() => {
    Vue.http.interceptors.push(myInterceptor);
    Vue.http.interceptors.push(headersInterceptor);
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, myInterceptor);
    Vue.http.interceptors = _.without(Vue.http.interceptors, headersInterceptor);
  });
  ```

## CSRF token
We use a Vue Resource interceptor to manage the CSRF token.
`app/assets/javascripts/vue_shared/vue_resource_interceptor.js` holds all our common interceptors.
Note: You don't need to load `app/assets/javascripts/vue_shared/vue_resource_interceptor.js`
since it's already being loaded by `common_vue.js`.


[vue-resource-repo]: https://github.com/pagekit/vue-resource

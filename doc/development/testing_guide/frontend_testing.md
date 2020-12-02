---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Frontend testing standards and style guidelines

There are two types of test suites you'll encounter while developing frontend code
at GitLab. We use Karma with Jasmine and Jest for JavaScript unit and integration testing,
and RSpec feature tests with Capybara for e2e (end-to-end) integration testing.

Unit and feature tests need to be written for all new features.
Most of the time, you should use [RSpec](https://github.com/rspec/rspec-rails#feature-specs) for your feature tests.

Regression tests should be written for bug fixes to prevent them from recurring
in the future.

See the [Testing Standards and Style Guidelines](index.md) page for more
information on general testing practices at GitLab.

## Vue.js testing

If you are looking for a guide on Vue component testing, you can jump right away to this [section](../fe_guide/vue.md#testing-vue-components).

## Jest

We use Jest to write frontend unit and integration tests.
Jest tests can be found in `/spec/frontend` and `/ee/spec/frontend` in EE.

## Karma test suite

While GitLab has switched over to [Jest](https://jestjs.io) you'll still find Karma tests in our
application because some of our specs require a browser and can't be easiliy migrated to Jest.
Those specs will eventually drop Karma in favor of either Jest or RSpec. You can track this migration
in the [related epic](https://gitlab.com/groups/gitlab-org/-/epics/4900).

[Karma](http://karma-runner.github.io/) is a test runner which uses
[Jasmine](https://jasmine.github.io/) as its test framework. Jest also uses Jasmine as foundation,
that's why it's looking quite similar.

Karma tests live in `spec/javascripts/` and `/ee/spec/javascripts` in EE.

`app/assets/javascripts/behaviors/autosize.js`
might have a corresponding `spec/javascripts/behaviors/autosize_spec.js` file.

Keep in mind that in a CI environment, these tests are run in a headless
browser and you will not have access to certain APIs, such as
[`Notification`](https://developer.mozilla.org/en-US/docs/Web/API/notification),
which have to be stubbed.

### Differences to Karma

- Jest runs in a Node.js environment, not in a browser. Support for running Jest tests in a browser [is planned](https://gitlab.com/gitlab-org/gitlab/-/issues/26982).
- Because Jest runs in a Node.js environment, it uses [jsdom](https://github.com/jsdom/jsdom) by default. See also its [limitations](#limitations-of-jsdom) below.
- Jest does not have access to Webpack loaders or aliases.
  The aliases used by Jest are defined in its [own configuration](https://gitlab.com/gitlab-org/gitlab/blob/master/jest.config.js).
- All calls to `setTimeout` and `setInterval` are mocked away. See also [Jest Timer Mocks](https://jestjs.io/docs/en/timer-mocks).
- `rewire` is not required because Jest supports mocking modules. See also [Manual Mocks](https://jestjs.io/docs/en/manual-mocks).
- No [context object](https://jasmine.github.io/tutorials/your_first_suite#section-The_%3Ccode%3Ethis%3C/code%3E_keyword) is passed to tests in Jest.
  This means sharing `this.something` between `beforeEach()` and `it()` for example does not work.
  Instead you should declare shared variables in the context that they are needed (via `const` / `let`).
- The following will cause tests to fail in Jest:
  - Unmocked requests.
  - Unhandled Promise rejections.
  - Calls to `console.warn`, including warnings from libraries like Vue.

### Limitations of jsdom

As mentioned [above](#differences-to-karma), Jest uses jsdom instead of a browser for running tests.
This comes with a number of limitations, namely:

- [No scrolling support](https://github.com/jsdom/jsdom/blob/15.1.1/lib/jsdom/browser/Window.js#L623-L625)
- [No element sizes or positions](https://github.com/jsdom/jsdom/blob/15.1.1/lib/jsdom/living/nodes/Element-impl.js#L334-L371)
- [No layout engine](https://github.com/jsdom/jsdom/issues/1322) in general

See also the issue for [support running Jest tests in browsers](https://gitlab.com/gitlab-org/gitlab/-/issues/26982).

### Debugging Jest tests

Running `yarn jest-debug` will run Jest in debug mode, allowing you to debug/inspect as described in the [Jest docs](https://jestjs.io/docs/en/troubleshooting#tests-are-failing-and-you-don-t-know-why).

### Timeout error

The default timeout for Jest is set in
[`/spec/frontend/test_setup.js`](https://gitlab.com/gitlab-org/gitlab/blob/master/spec/frontend/test_setup.js).

If your test exceeds that time, it will fail.

If you cannot improve the performance of the tests, you can increase the timeout
for a specific test using
[`setTestTimeout`](https://gitlab.com/gitlab-org/gitlab/blob/master/spec/frontend/helpers/timeout.js).

```javascript
import { setTestTimeout } from 'helpers/timeout';

describe('Component', () => {
  it('does something amazing', () => {
    setTestTimeout(500);
    // ...
  });
});
```

Remember that the performance of each test depends on the environment.

### Timout error due to async components

If your component is fetching some other components asynchroneously based on some conditions, it might happen so that your Jest suite for this component will become flaky timing out from time to time. 

```javascript
// ide.vue
export default {
  components: {
    'error-message': () => import('./error_message.vue'),
    'gl-button': () => import('@gitlab/ui/src/components/base/button/button.vue'),
    ...
};
```

To address this issue, you can "help" Jest by stubbing the async components so that Jest would not need to fetch those asynchroneously at the run-time.

```javascript
// ide_spec.js
import { GlButton } from '@gitlab/ui';
import ErrorMessage from '~/ide/components/error_message.vue';
...
return shallowMount(ide, {
  ...
  stubs: {
    ErrorMessage,
    GlButton,
    ...
  },
})
```

## What and how to test

Before jumping into more gritty details about Jest-specific workflows like mocks and spies, we should briefly cover what to test with Jest.

### Don't test the library

Libraries are an integral part of any JavaScript developer's life. The general advice would be to not test library internals, but expect that the library knows what it's supposed to do and has test coverage on its own.
A general example could be something like this

```javascript
import { convertToFahrenheit } from 'temperatureLibrary'

function getFahrenheit(celsius) {
  return convertToFahrenheit(celsius)
}
```

It does not make sense to test our `getFahrenheit` function because underneath it does nothing else but invoking the library function, and we can expect that one is working as intended. (Simplified, I know)

Let's take a short look into Vue land. Vue is a critical part of the GitLab JavaScript codebase. When writing specs for Vue components, a common gotcha is to actually end up testing Vue provided functionality, because it appears to be the easiest thing to test. Here's an example taken from our codebase.

```javascript
// Component
{
  computed: {
    hasMetricTypes() {
      return this.metricTypes.length;
    },
}
```

and here's the corresponding spec

```javascript
 describe('computed', () => {
    describe('hasMetricTypes', () => {
      it('returns true if metricTypes exist', () => {
        factory({ metricTypes });
        expect(wrapper.vm.hasMetricTypes).toBe(2);
      });

      it('returns true if no metricTypes exist', () => {
        factory();
        expect(wrapper.vm.hasMetricTypes).toBe(0);
      });
    });
});
```

Testing the `hasMetricTypes` computed prop would seem like a given, but to test if the computed property is returning the length of `metricTypes`, is testing the Vue library itself. There is no value in this, besides it adding to the test suite. Better is to test it in the way the user interacts with it. Probably through the template.

Keep an eye out for these kinds of tests, as they just make updating logic more fragile and tedious than it needs to be. This is also true for other libraries.

Some more examples can be found in the [Frontend unit tests section](testing_levels.md#frontend-unit-tests)

### Don't test your mock

Another common gotcha is that the specs end up verifying the mock is working. If you are using mocks, the mock should support the test, but not be the target of the test.

```javascript
const spy = jest.spyOn(idGenerator, 'create')
spy.mockImplementation = () = '1234'

// Bad
expect(idGenerator.create()).toBe('1234')

// Good: actually focusing on the logic of your component and just leverage the controllable mocks output
expect(wrapper.find('div').html()).toBe('<div id="1234">...</div>')
```

### Follow the user

The line between unit and integration tests can be quite blurry in a component heavy world. The most important guideline to give is the following:

- Write clean unit tests if there is actual value in testing a complex piece of logic in isolation to prevent it from breaking in the future
- Otherwise, try to write your specs as close to the user's flow as possible

For example, it's better to use the generated markup to trigger a button click and validate the markup changed accordingly than to call a method manually and verify data structures or computed properties. There's always the chance of accidentally breaking the user flow, while the tests pass and provide a false sense of security.

## Common practices

Following you'll find some general common practices you will find as part of our test suite. Should you stumble over something not following this guide, ideally fix it right away. 🎉

### How to query DOM elements

When it comes to querying DOM elements in your tests, it is best to uniquely and semantically target
the element.

Preferentially, this is done by targeting what the user actually sees using [DOM Testing Library](https://testing-library.com/docs/dom-testing-library/intro).
When selecting by text it is best to use [`getByRole` or `findByRole`](https://testing-library.com/docs/dom-testing-library/api-queries#byrole)
as these enforce accessibility best practices as well. The examples below demonstrate the order of preference.

When writing Vue component unit tests, it can be wise to query children by component, so that the unit test can focus on comprehensive value coverage
rather than dealing with the complexity of a child component's behavior.

Sometimes, neither of the above are feasible. In these cases, adding test attributes to simplify the selectors might be the best option. A list of
possible selectors include:

- A semantic attribute like `name` (also verifies that `name` was setup properly)
- A `data-testid` attribute ([recommended by maintainers of `@vue/test-utils`](https://github.com/vuejs/vue-test-utils/issues/1498#issuecomment-610133465))
- a Vue `ref` (if using `@vue/test-utils`)

```javascript
import { getByRole, getByText } from '@testing-library/dom'

// In this example, `wrapper` is a `@vue/test-utils` wrapper returned from `mount` or `shallowMount`.
it('exists', () => {
  // Best (especially for integration tests)
  getByRole(wrapper.element, 'link', { name: /Click Me/i })
  getByRole(wrapper.element, 'link', { name: 'Click Me' })
  getByText(wrapper.element, 'Click Me')
  getByText(wrapper.element, /Click Me/i)

  // Good (especially for unit tests)
  wrapper.find(FooComponent);
  wrapper.find('input[name=foo]');
  wrapper.find('[data-testid="foo"]');
  wrapper.find({ ref: 'foo'});

  // Bad
  wrapper.find('.js-foo');
  wrapper.find('.btn-primary');
  wrapper.find('.qa-foo-component');
  wrapper.find('[data-qa-selector="foo"]');
});
```

It is not recommended that you add `.js-*` classes just for testing purposes. Only do this if there are no other feasible options available.

Do not use a `.qa-*` class or `data-qa-selector` attribute for any tests other than QA end-to-end testing.

### Querying for child components

When testing Vue components with `@vue/test-utils` another possible approach is querying for child
components instead of querying for DOM nodes. This assumes that implementation details of behavior
under test should be covered by that component's individual unit test. There is no strong preference
in writing DOM or component queries as long as your tests reliably cover expected behavior for the
component under test.

Example:

```javascript
it('exists', () => {
    wrapper.find(FooComponent);
});
```

### Naming unit tests

When writing describe test blocks to test specific functions/methods,
please use the method name as the describe block name.

**Bad**:

```javascript
describe('#methodName', () => {
  it('passes', () => {
    expect(true).toEqual(true);
  });
});

describe('.methodName', () => {
  it('passes', () => {
    expect(true).toEqual(true);
  });
});
```

**Good**:

```javascript
describe('methodName', () => {
  it('passes', () => {
    expect(true).toEqual(true);
  });
});
```

### Testing promises

When testing Promises you should always make sure that the test is asynchronous and rejections are handled. It's now possible to use the `async/await` syntax in the test suite:

```javascript
it('tests a promise', async () => {
  const users = await fetchUsers()
  expect(users.length).toBe(42)
});

it('tests a promise rejection', async () => {
  await expect(user.getUserName(1)).rejects.toThrow('User with 1 not found.');
});
```

You can also simply return a promise from the test function.

Using the `done` and `done.fail` callbacks is discouraged when working with
promises. They should only be used when testing callback-based code.

**Bad**:

```javascript
// missing return
it('tests a promise', () => {
  promise.then(data => {
    expect(data).toBe(asExpected);
  });
});

// uses done/done.fail
it('tests a promise', done => {
  promise
    .then(data => {
      expect(data).toBe(asExpected);
    })
    .then(done)
    .catch(done.fail);
});
```

**Good**:

```javascript
// verifying a resolved promise
it('tests a promise', () => {
  return promise
    .then(data => {
      expect(data).toBe(asExpected);
    });
});

// verifying a resolved promise using Jest's `resolves` matcher
it('tests a promise', () => {
  return expect(promise).resolves.toBe(asExpected);
});

// verifying a rejected promise using Jest's `rejects` matcher
it('tests a promise rejection', () => {
  return expect(promise).rejects.toThrow(expectedError);
});
```

### Manipulating Time

Sometimes we have to test time-sensitive code. For example, recurring events that run every X amount of seconds or similar. Here you'll find some strategies to deal with that:

#### `setTimeout()` / `setInterval()` in application

If the application itself is waiting for some time, mock await the waiting. In Jest this is already
[done by default](https://gitlab.com/gitlab-org/gitlab/blob/a2128edfee799e49a8732bfa235e2c5e14949c68/jest.config.js#L47)
(see also [Jest Timer Mocks](https://jestjs.io/docs/en/timer-mocks)). In Karma you can use the
[Jasmine mock clock](https://jasmine.github.io/api/2.9/Clock.html).

```javascript
const doSomethingLater = () => {
  setTimeout(() => {
    // do something
  }, 4000);
};
```

**in Jest:**

```javascript
it('does something', () => {
  doSomethingLater();
  jest.runAllTimers();

  expect(something).toBe('done');
});
```

**in Karma:**

```javascript
it('does something', () => {
  jasmine.clock().install();

  doSomethingLater();
  jasmine.clock().tick(4000);

  expect(something).toBe('done');
  jasmine.clock().uninstall();
});
```

### Waiting in tests

Sometimes a test needs to wait for something to happen in the application before it continues.
Avoid using [`setTimeout`](https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/setTimeout)
because it makes the reason for waiting unclear and if used within Karma with a time larger than zero it will slow down our test suite.
Instead use one of the following approaches.

#### Promises and Ajax calls

Register handler functions to wait for the `Promise` to be resolved.

```javascript
const askTheServer = () => {
  return axios
    .get('/endpoint')
    .then(response => {
      // do something
    })
    .catch(error => {
      // do something else
    });
};
```

**in Jest:**

```javascript
it('waits for an Ajax call', async () => {
  await askTheServer()
  expect(something).toBe('done');
});
```

**in Karma:**

```javascript
it('waits for an Ajax call', done => {
  askTheServer()
    .then(() => {
      expect(something).toBe('done');
    })
    .then(done)
    .catch(done.fail);
});
```

If you are not able to register handlers to the `Promise`, for example because it is executed in a synchronous Vue life cycle hook, please take a look at the [waitFor](#wait-until-axios-requests-finish) helpers or you can flush all pending `Promise`s:

**in Jest:**

```javascript
it('waits for an Ajax call', () => {
  synchronousFunction();
  jest.runAllTicks();

  expect(something).toBe('done');
});
```

#### Vue rendering

To wait until a Vue component is re-rendered, use either of the equivalent
[`Vue.nextTick()`](https://vuejs.org/v2/api/#Vue-nextTick) or `vm.$nextTick()`.

**in Jest:**

```javascript
it('renders something', () => {
  wrapper.setProps({ value: 'new value' });

  return wrapper.vm.$nextTick().then(() => {
    expect(wrapper.text()).toBe('new value');
  });
});
```

**in Karma:**

```javascript
it('renders something', done => {
  wrapper.setProps({ value: 'new value' });

  wrapper.vm
    .$nextTick()
    .then(() => {
      expect(wrapper.text()).toBe('new value');
    })
    .then(done)
    .catch(done.fail);
});
```

#### Events

If the application triggers an event that you need to wait for in your test, register an event handler which contains
the assertions:

```javascript
it('waits for an event', done => {
  eventHub.$once('someEvent', eventHandler);

  someFunction();

  function eventHandler() {
    expect(something).toBe('done');
    done();
  }
});
```

In Jest you can also use a `Promise` for this:

```javascript
it('waits for an event', () => {
  const eventTriggered = new Promise(resolve => eventHub.$once('someEvent', resolve));

  someFunction();

  return eventTriggered.then(() => {
    expect(something).toBe('done');
  });
});
```

### Ensuring that tests are isolated

Tests are normally architected in a pattern which requires a recurring setup and breakdown of the component under test. This is done by making use of the `beforeEach` and `afterEach` hooks.

Example

```javascript
  let wrapper;

  beforeEach(() => {
    wrapper = mount(Component);
  });

  afterEach(() => {
    wrapper.destroy();
  });
```

When looking at this initially you'd suspect that the component is setup before each test and then broken down afterwards, providing isolation between tests.

This is however not entirely true as the `destroy` method does not remove everything which has been mutated on the `wrapper` object. For functional components, destroy only removes the rendered DOM elements from the document.

In order to ensure that a clean wrapper object and DOM are being used in each test, the breakdown of the component should rather be performed as follows:

```javascript
  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });
```

See also the [Vue Test Utils documentation on `destroy`](https://vue-test-utils.vuejs.org/api/wrapper/#destroy).

### Jest best practices

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/34209) in GitLab 13.2.

#### Prefer `toBe` over `toEqual` when comparing primitive values

Jest has [`toBe`](https://jestjs.io/docs/en/expect#tobevalue) and
[`toEqual`](https://jestjs.io/docs/en/expect#toequalvalue) matchers.
As [`toBe`](https://jestjs.io/docs/en/expect#tobevalue) uses
[`Object.is`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is)
to compare values, it's faster (by default) than using `toEqual`.
While the latter will eventually fallback to leverage [`Object.is`](https://github.com/facebook/jest/blob/master/packages/expect/src/jasmineUtils.ts#L91),
for primitive values, it should only be used when complex objects need a comparison.

Examples:

```javascript
const foo = 1;

// Bad
expect(foo).toEqual(1);

// Good
expect(foo).toBe(1);
```

#### Prefer more befitting matchers

Jest provides useful matchers like `toHaveLength` or `toBeUndefined` to make your tests more
readable and to produce more understandable error messages. Check their docs for the
[full list of matchers](https://jestjs.io/docs/en/expect#methods).

Examples:

```javascript
const arr = [1, 2];

// prints:
// Expected length: 1
// Received length: 2
expect(arr).toHaveLength(1);

// prints:
// Expected: 1
// Received: 2
expect(arr.length).toBe(1);

// prints:
// expect(received).toBe(expected) // Object.is equality
// Expected: undefined
// Received: "bar"
const foo = 'bar';
expect(foo).toBe(undefined);

// prints:
// expect(received).toBeUndefined()
// Received: "bar"
const foo = 'bar';
expect(foo).toBeUndefined();
```

#### Avoid using `toBeTruthy` or `toBeFalsy`

Jest also provides following matchers: `toBeTruthy` and `toBeFalsy`. We should not use them because
they make tests weaker and produce false-positive results.

For example, `expect(someBoolean).toBeFalsy()` passes when `someBoolean === null`, and when
`someBoolean === false`.

#### Tricky `toBeDefined` matcher

Jest has the tricky `toBeDefined` matcher that can produce false positive test. Because it
[validates](https://github.com/facebook/jest/blob/master/packages/expect/src/matchers.ts#L204)
the given value for `undefined` only.

```javascript
// Bad: if finder returns null, the test will pass
expect(wrapper.find('foo')).toBeDefined();

// Good
expect(wrapper.find('foo').exists()).toBe(true);
```

#### Avoid using `setImmediate`

Try to avoid using `setImmediate`. `setImmediate` is an ad-hoc solution to run your callback after
the I/O completes. And it's not part of the Web API, hence, we target NodeJS environments in our
unit tests.

Instead of `setImmediate`, use `jest.runAllTimers` or `jest.runOnlyPendingTimers` to run pending timers.
The latter is useful when you have `setInterval` in the code. **Remember:** our Jest configuration uses fake timers.

## Avoid non-deterministic specs

Non-determinism is the breeding ground for flaky and brittle specs. Such specs end up breaking the CI pipeline, interrupting the work flow of other contributors.

1. Make sure your test subject's collaborators (e.g., axios, apollo, lodash helpers) and test environment (e.g., Date) behave consistently across systems and over time.
1. Make sure tests are focused and not doing "extra work" (e.g., needlessly creating the test subject more than once in an individual test)

### Faking `Date` for determinism

Consider using `useFakeDate` to ensure a consistent value is returned with every `new Date()` or `Date.now()`.

```javascript
import { useFakeDate } from 'helpers/fake_date';

describe('cool/component', () => {
  useFakeDate();

  // ...
});
```

### Faking `Math.random` for determinism

Consider replacing `Math.random` with a fake when the test subject depends on it.

```javascript
beforeEach(() => {
  // https://xkcd.com/221/
  jest.spyOn(Math, 'random').mockReturnValue(0.4);
});
```

## Factories

TBU

## Mocking Strategies with Jest

### Stubbing and Mocking

Jasmine provides stubbing and mocking capabilities. There are some subtle differences in how to use it within Karma and Jest.

Stubs or spies are often used synonymously. In Jest it's quite easy thanks to the `.spyOn` method.
[Official docs](https://jestjs.io/docs/en/jest-object#jestspyonobject-methodname)
The more challenging part are mocks, which can be used for functions or even dependencies.

### Manual module mocks

Manual mocks are used to mock modules across the entire Jest environment. This is a very powerful testing tool that helps simplify
unit testing by mocking out modules which cannot be easily consumed in our test environment.

> **WARNING:** Do not use manual mocks if a mock should not be consistently applied in every spec (i.e. it's only needed by a few specs).
> Instead, consider using [`jest.mock(..)`](https://jestjs.io/docs/en/jest-object#jestmockmodulename-factory-options)
> (or a similar mocking function) in the relevant spec file.

#### Where should I put manual mocks?

Jest supports [manual module mocks](https://jestjs.io/docs/en/manual-mocks) by placing a mock in a `__mocks__/` directory next to the source module
(e.g. `app/assets/javascripts/ide/__mocks__`). **Don't do this.** We want to keep all of our test-related code in one place (the `spec/` folder).

If a manual mock is needed for a `node_modules` package, please use the `spec/frontend/__mocks__` folder. Here's an example of
a [Jest mock for the package `monaco-editor`](https://gitlab.com/gitlab-org/gitlab/blob/b7f914cddec9fc5971238cdf12766e79fa1629d7/spec/frontend/__mocks__/monaco-editor/index.js#L1).

If a manual mock is needed for a CE module, please place it in `spec/frontend/mocks/ce`.

- Files in `spec/frontend/mocks/ce` will mock the corresponding CE module from `app/assets/javascripts`, mirroring the source module's path.
  - Example: `spec/frontend/mocks/ce/lib/utils/axios_utils` will mock the module `~/lib/utils/axios_utils`.
- We don't support mocking EE modules yet.
- If a mock is found for which a source module doesn't exist, the test suite will fail. 'Virtual' mocks, or mocks that don't have a 1-to-1 association with a source module, are not supported yet.

#### Manual mock examples

- [`mocks/axios_utils`](https://gitlab.com/gitlab-org/gitlab/blob/bd20aeb64c4eed117831556c54b40ff4aee9bfd1/spec/frontend/mocks/ce/lib/utils/axios_utils.js#L1) -
  This mock is helpful because we don't want any unmocked requests to pass any tests. Also, we are able to inject some test helpers such as `axios.waitForAll`.
- [`__mocks__/mousetrap/index.js`](https://gitlab.com/gitlab-org/gitlab/blob/cd4c086d894226445be9d18294a060ba46572435/spec/frontend/__mocks__/mousetrap/index.js#L1) -
  This mock is helpful because the module itself uses AMD format which webpack understands, but is incompatible with the jest environment. This mock doesn't remove
  any behavior, only provides a nice es6 compatible wrapper.
- [`__mocks__/monaco-editor/index.js`](https://gitlab.com/gitlab-org/gitlab/blob/b7f914cddec9fc5971238cdf12766e79fa1629d7/spec/frontend/__mocks__/monaco-editor/index.js) -
  This mock is helpful because the Monaco package is completely incompatible in a Jest environment. In fact, webpack requires a special loader to make it work. This mock
  simply makes this package consumable by Jest.

### Keep mocks light

Global mocks introduce magic and technically can reduce test coverage. When mocking is deemed profitable:

- Keep the mock short and focused.
- Please leave a top-level comment in the mock on why it is necessary.

### Additional mocking techniques

Please consult the [official Jest docs](https://jestjs.io/docs/en/jest-object#mock-modules) for a full overview of the available mocking features.

## Running Frontend Tests

For running the frontend tests, you need the following commands:

- `rake frontend:fixtures` (re-)generates [fixtures](#frontend-test-fixtures). Make sure that
  fixtures are up-to-date before running tests that require them.
- `yarn jest` runs Jest tests.
- `yarn karma` runs Karma tests.

### Live testing and focused testing -- Jest

While you work on a test suite, you may want to run these specs in watch mode, so they rerun automatically on every save.

```shell
# Watch and rerun all specs matching the name icon
yarn jest --watch icon

# Watch and rerun one specific file
yarn jest --watch path/to/spec/file.spec.js
```

You can also run some focused tests without the `--watch` flag

```shell
# Run specific jest file
yarn jest ./path/to/local_spec.js
# Run specific jest folder
yarn jest ./path/to/folder/
# Run all jest files which path contain term
yarn jest term
```

### Live testing and focused testing -- Karma

Karma allows something similar, but it's way more costly.

Running Karma with `yarn run karma-start` will compile the JavaScript
assets and run a server at `http://localhost:9876/` where it will automatically
run the tests on any browser which connects to it. You can enter that URL on
multiple browsers at once to have it run the tests on each in parallel.

While Karma is running, any changes you make will instantly trigger a recompile
and retest of the **entire test suite**, so you can see instantly if you've broken
a test with your changes. You can use [Jasmine focused](https://jasmine.github.io/2.5/focused_specs.html) or
excluded tests (with `fdescribe` or `xdescribe`) to get Karma to run only the
tests you want while you're working on a specific feature, but make sure to
remove these directives when you commit your code.

It is also possible to only run Karma on specific folders or files by filtering
the run tests via the argument `--filter-spec` or short `-f`:

```shell
# Run all files
yarn karma-start
# Run specific spec files
yarn karma-start --filter-spec profile/account/components/update_username_spec.js
# Run specific spec folder
yarn karma-start --filter-spec profile/account/components/
# Run all specs which path contain vue_shared or vie
yarn karma-start -f vue_shared -f vue_mr_widget
```

You can also use glob syntax to match files. Remember to put quotes around the
glob otherwise your shell may split it into multiple arguments:

```shell
# Run all specs named `file_spec` within the IDE subdirectory
yarn karma -f 'spec/javascripts/ide/**/file_spec.js'
```

## Frontend test fixtures

Frontend fixtures are files containing responses from backend controllers. These responses can be either HTML
generated from haml templates or JSON payloads. Frontend tests that rely on these responses are
often using fixtures to validate correct integration with the backend code.

### Generate fixtures

You can find code to generate test fixtures in:

- `spec/frontend/fixtures/`, for running tests in CE.
- `ee/spec/frontend/fixtures/`, for running tests in EE.

You can generate fixtures by running:

- `bin/rake frontend:fixtures` to generate all fixtures
- `bin/rspec spec/frontend/fixtures/merge_requests.rb` to generate specific fixtures (in this case for `merge_request.rb`)

You can find generated fixtures are in `tmp/tests/frontend/fixtures-ee`.

#### Creating new fixtures

For each fixture, you can find the content of the `response` variable in the output file.
For example, test named `"merge_requests/diff_discussion.json"` in `spec/frontend/fixtures/merge_requests.rb`
will produce output file `tmp/tests/frontend/fixtures-ee/merge_requests/diff_discussion.json`.
The `response` variable gets automatically set if the test is marked as `type: :request` or `type: :controller`.

When creating a new fixture, it often makes sense to take a look at the corresponding tests for the
endpoint in `(ee/)spec/controllers/` or `(ee/)spec/requests/`.

### Use fixtures

Jest and Karma test suites import fixtures in different ways:

- The Karma test suite are served by [jasmine-jquery](https://github.com/velesin/jasmine-jquery).
- Jest use `spec/frontend/helpers/fixtures.js`.

The following are examples of tests that work for both Karma and Jest:

```javascript
it('makes a request', () => {
  const responseBody = getJSONFixture('some/fixture.json'); // loads spec/frontend/fixtures/some/fixture.json
  axiosMock.onGet(endpoint).reply(200, responseBody);

  myButton.click();

  // ...
});

it('uses some HTML element', () => {
  loadFixtures('some/page.html'); // loads spec/frontend/fixtures/some/page.html and adds it to the DOM

  const element = document.getElementById('#my-id');

  // ...
});
```

## Data-driven tests

Similar to [RSpec's parameterized tests](best_practices.md#table-based--parameterized-tests),
Jest supports data-driven tests for:

- Individual tests using [`test.each`](https://jestjs.io/docs/en/api#testeachtable-name-fn-timeout) (aliased to `it.each`).
- Groups of tests using [`describe.each`](https://jestjs.io/docs/en/api#describeeachtable-name-fn-timeout).

These can be useful for reducing repetition within tests. Each option can take an array of
data values or a tagged template literal.

For example:

```javascript
// function to test
const icon = status => status ? 'pipeline-passed' : 'pipeline-failed'
const message = status => status ? 'pipeline-passed' : 'pipeline-failed'

// test with array block
it.each([
    [false, 'pipeline-failed'],
    [true, 'pipeline-passed']
])('icon with %s will return %s',
 (status, icon) => {
    expect(renderPipeline(status)).toEqual(icon)
 }
);
```

**Note**: only use template literal block if pretty print is **not** needed for spec output. For example, empty strings, nested objects etc.

For example, when testing the difference between an empty search string and a non-empty search string, the use of the array block syntax with the pretty print option would be preferred. That way the differences between an empty string e.g. `''` and a non-empty string e.g. `'search string'` would be visible in the spec output. Whereas with a template literal block, the empty string would be shown as a space, which could lead to a confusing developer experience

```javascript
// bad
it.each`
    searchTerm | expected
    ${''} | ${{ issue: { users: { nodes: [] } } }}
    ${'search term'} | ${{ issue: { other: { nested: [] } } }}
`('when search term is $searchTerm, it returns $expected', ({ searchTerm, expected }) => {
  expect(search(searchTerm)).toEqual(expected)
});

// good
it.each([
    ['', { issue: { users: { nodes: [] } } }],
    ['search term', { issue: { other: { nested: [] } } }],
])('when search term is %p, expect to return %p',
 (searchTerm, expected) => {
    expect(search(searchTerm)).toEqual(expected)
 }
);

```

```javascript
// test suite with tagged template literal block
describe.each`
    status   | icon                 | message
    ${false} | ${'pipeline-failed'} | ${'Pipeline failed - boo-urns'}
    ${true}  | ${'pipeline-passed'} | ${'Pipeline succeeded - win!'}
`('pipeline component', ({ status, icon, message }) => {
    it(`returns icon ${icon} with status ${status}`, () => {
        expect(icon(status)).toEqual(message)
    })

    it(`returns message ${message} with status ${status}`, () => {
        expect(message(status)).toEqual(message)
    })
});
```

## Gotchas

### RSpec errors due to JavaScript

By default RSpec unit tests will not run JavaScript in the headless browser
and will simply rely on inspecting the HTML generated by rails.

If an integration test depends on JavaScript to run correctly, you need to make
sure the spec is configured to enable JavaScript when the tests are run. If you
don't do this you'll see vague error messages from the spec runner.

To enable a JavaScript driver in an `rspec` test, add `:js` to the
individual spec or the context block containing multiple specs that need
JavaScript enabled:

```ruby
# For one spec
it 'presents information about abuse report', :js do
  # assertions...
end

describe "Admin::AbuseReports", :js do
  it 'presents information about abuse report' do
    # assertions...
  end
  it 'shows buttons for adding to abuse report' do
    # assertions...
  end
end
```

## Overview of Frontend Testing Levels

Main information on frontend testing levels can be found in the [Testing Levels page](testing_levels.md).

Tests relevant for frontend development can be found at the following places:

- `spec/javascripts/`, for Karma tests
- `spec/frontend/`, for Jest tests
- `spec/features/`, for RSpec tests

RSpec runs complete [feature tests](testing_levels.md#frontend-feature-tests), while the Jest and Karma directories contain [frontend unit tests](testing_levels.md#frontend-unit-tests), [frontend component tests](testing_levels.md#frontend-component-tests), and [frontend integration tests](testing_levels.md#frontend-integration-tests).

All tests in `spec/javascripts/` will eventually be migrated to `spec/frontend/` (see also [#52483](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/52483)).

Before May 2018, `features/` also contained feature tests run by Spinach. These tests were removed from the codebase in May 2018 ([#23036](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/23036)).

See also [Notes on testing Vue components](../fe_guide/vue.md#testing-vue-components).

## Test helpers

### Vuex Helper: `testAction`

We have a helper available to make testing actions easier, as per [official documentation](https://vuex.vuejs.org/guide/testing.html):

```javascript
testAction(
  actions.actionName, // action
  { }, // params to be passed to action
  state, // state
  [
    { type: types.MUTATION},
    { type: types.MUTATION_1, payload: {}},
  ], // mutations committed
  [
    { type: 'actionName', payload: {}},
    { type: 'actionName1', payload: {}},
  ] // actions dispatched
  done,
);
```

Check an example in [`spec/javascripts/ide/stores/actions_spec.jsspec/javascripts/ide/stores/actions_spec.js`](https://gitlab.com/gitlab-org/gitlab/blob/master/spec/javascripts/ide/stores/actions_spec.js).

### Wait until Axios requests finish

The Axios Utils mock module located in `spec/frontend/mocks/ce/lib/utils/axios_utils.js` contains two helper methods for Jest tests that spawn HTTP requests.
These are very useful if you don't have a handle to the request's Promise, for example when a Vue component does a request as part of its life cycle.

- `waitFor(url, callback)`: Runs `callback` after a request to `url` finishes (either successfully or unsuccessfully).
- `waitForAll(callback)`: Runs `callback` once all pending requests have finished. If no requests are pending, runs `callback` on the next tick.

Both functions run `callback` on the next tick after the requests finish (using `setImmediate()`), to allow any `.then()` or `.catch()` handlers to run.

## Testing with older browsers

Some regressions only affect a specific browser version. We can install and test in particular browsers with either Firefox or BrowserStack using the following steps:

### BrowserStack

[BrowserStack](https://www.browserstack.com/) allows you to test more than 1200 mobile devices and browsers.
You can use it directly through the [live app](https://www.browserstack.com/live) or you can install the [chrome extension](https://chrome.google.com/webstore/detail/browserstack/nkihdmlheodkdfojglpcjjmioefjahjb) for easy access.
Sign in to BrowserStack with the credentials saved in the **Engineering** vault of GitLab's
[shared 1Password account](https://about.gitlab.com/handbook/security/#1password-guide).

### Firefox

#### macOS

You can download any older version of Firefox from the releases FTP server, <https://ftp.mozilla.org/pub/firefox/releases/>:

1. From the website, select a version, in this case `50.0.1`.
1. Go to the mac folder.
1. Select your preferred language, you will find the DMG package inside, download it.
1. Drag and drop the application to any other folder but the `Applications` folder.
1. Rename the application to something like `Firefox_Old`.
1. Move the application to the `Applications` folder.
1. Open up a terminal and run `/Applications/Firefox_Old.app/Contents/MacOS/firefox-bin -profilemanager` to create a new profile specific to that Firefox version.
1. Once the profile has been created, quit the app, and run it again like normal. You now have a working older Firefox version.

---

[Return to Testing documentation](index.md)

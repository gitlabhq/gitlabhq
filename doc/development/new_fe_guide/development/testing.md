# Overview of Frontend Testing

Tests relevant for frontend development can be found at two places:

- `spec/javascripts/` which are run by Karma and contain
  - [frontend unit tests](#frontend-unit-tests)
  - [frontend component tests](#frontend-component-tests)
  - [frontend integration tests](#frontend-integration-tests)
- `spec/features/` which are run by RSpec and contain
  - [feature tests](#feature-tests)

In addition there were feature tests in `features/` run by Spinach in the past.
These have been removed from our codebase in May 2018 ([#23036](https://gitlab.com/gitlab-org/gitlab-ce/issues/23036)).

## Frontend unit tests

Unit tests are on the lowest abstraction level and typically test functionality that is not directly perceivable by a user.

### When to use unit tests

<details>
  <summary>exported functions and classes</summary>
  Anything that is exported can be reused at various places in a way you have no control over.
  Therefore it is necessary to document the expected behavior of the public interface with tests.
</details>

<details>
  <summary>Vuex actions</summary>
  Any Vuex action needs to work in a consistent way independent of the component it is triggered from.
</details>

<details>
  <summary>Vuex mutations</summary>
  For complex Vuex mutations it helps to identify the source of a problem by separating the tests from other parts of the Vuex store.
</details>

### When *not* to use unit tests

<details>
  <summary>non-exported functions or classes</summary>
  Anything that is not exported from a module can be considered private or an implementation detail and doesn't need to be tested.
</details>

<details>
  <summary>constants</summary>
  Testing the value of a constant would mean to copy it.
  This results in extra effort without additional confidence that the value is correct.
</details>

<details>
  <summary>Vue components</summary>
  Computed properties, methods, and lifecycle hooks can be considered an implementation detail of components and need not be tested.
  They are implicitly covered by component tests.
  The <a href="https://vue-test-utils.vuejs.org/guides/#getting-started">official guidelines</a> suggest the same.
</details>

### What to mock in unit tests

<details>
  <summary>state of the class under test</summary>
  Modifying the state of the class under test directly rather than using methods of the class avoids side-effects in test setup.
</details>

<details>
  <summary>other exported classes</summary>
  Every class needs to be tested in isolation to prevent test scenarios from growing exponentially.
</details>

<details>
  <summary>single DOM elements if passed as parameters</summary>
  For tests that only operate on single DOM elements rather than a whole page, creating these elements is cheaper than loading a whole HTML fixture.
</details>

<details>
  <summary>all server requests</summary>
  When running frontend unit tests, the backend may not be reachable.
  Therefore all outgoing requests need to be mocked.
</details>

<details>
  <summary>asynchronous background operations</summary>
  Background operations cannot be stopped or waited on, so they will continue running in the following tests and cause side effects.
</details>

### What *not* to mock in unit tests

<details>
  <summary>non-exported functions or classes</summary>
  Everything that is not exported can be considered private to the module and will be implicitly tested via the exported classes / functions.
</details>

<details>
  <summary>methods of the class under test</summary>
  By mocking methods of the class under test, the mocks will be tested and not the real methods.
</details>

<details>
  <summary>utility functions (pure functions, or those that only modify parameters)</summary>
  If a function has no side effects because it has no state, it is safe to not mock it in tests.
</details>

<details>
  <summary>full HTML pages</summary>
  Loading the HTML of a full page slows down tests, so it should be avoided in unit tests.
</details>

## Frontend component tests

Component tests cover the state of a single component that is perceivable by a user depending on external signals such as user input, events fired from other components, or application state.

### When to use component tests

- Vue components

### When *not* to use component tests

<details>
  <summary>Vue applications</summary>
  Vue applications may contain many components.
  Testing them on a component level requires too much effort.
  Therefore they are tested on frontend integration level.
</details>

<details>
  <summary>HAML templates</summary>
  HAML templates contain only Markup and no frontend-side logic.
  Therefore they are not complete components.
</details>

### What to mock in component tests

<details>
  <summary>DOM</summary>
  Operating on the real DOM is significantly slower than on the virtual DOM.
</details>

<details>
  <summary>properties and state of the component under test</summary>
  Similarly to testing classes, modifying the properties directly (rather than relying on methods of the component) avoids side-effects.
</details>

<details>
  <summary>Vuex store</summary>
  To avoid side effects and keep component tests simple, Vuex stores are replaced with mocks.
</details>

<details>
  <summary>all server requests</summary>
  Similar to unit tests, when running component tests, the backend may not be reachable.
  Therefore all outgoing requests need to be mocked.
</details>

<details>
  <summary>asynchronous background operations</summary>
  Similar to unit tests, background operations cannot be stopped or waited on, so they will continue running in the following tests and cause side effects.
</details>

<details>
  <summary>child components</summary>
  Every component is tested individually, so child components are mocked.
  See also <a href="https://vue-test-utils.vuejs.org/api/#shallowmount">shallowMount()</a>
</details>

### What *not* to mock in component tests

<details>
  <summary>methods or computed properties of the component under test</summary>
  By mocking part of the component under test, the mocks will be tested and not the real component.
</details>

<details>
  <summary>functions and classes independent from Vue</summary>
  All plain JavaScript code is already covered by unit tests and needs not to be mocked in component tests.
</details>

## Frontend integration tests

Integration tests cover the interaction between all components on a single page.
Their abstraction level is comparable to how a user would interact with the UI.

### When to use integration tests

<details>
  <summary>page bundles (<code>index.js</code> files in <code>app/assets/javascripts/pages/</code>)</summary>
  Testing the page bundles ensures the corresponding frontend components integrate well.
</details>

<details>
  <summary>Vue applications outside of page bundles</summary>
  Testing Vue applications as a whole ensures the corresponding frontend components integrate well.
</details>

### What to mock in integration tests

<details>
  <summary>HAML views (use fixtures instead)</summary>
  Rendering HAML views requires a Rails environment including a running database which we cannot rely on in frontend tests.
</details>

<details>
  <summary>all server requests</summary>
  Similar to unit and component tests, when running component tests, the backend may not be reachable.
  Therefore all outgoing requests need to be mocked.
</details>

<details>
  <summary>asynchronous background operations that are not perceivable on the page</summary>
  Background operations that affect the page need to be tested on this level.
  All other background operations cannot be stopped or waited on, so they will continue running in the following tests and cause side effects.
</details>

### What *not* to mock in integration tests

<details>
  <summary>DOM</summary>
  Testing on the real DOM ensures our components work in the environment they are meant for.
  Part of this will be delegated to <a href="https://gitlab.com/gitlab-org/quality/team-tasks/issues/45">cross-browser testing</a>.
</details>

<details>
  <summary>properties or state of components</summary>
  On this level, all tests can only perform actions a user would do.
  For example to change the state of a component, a click event would be fired.
</details>

<details>
  <summary>Vuex stores</summary>
  When testing the frontend code of a page as a whole, the interaction between Vue components and Vuex stores is covered as well.
<details>

## Feature tests

In contrast to [frontend integration tests](#frontend-integration-tests), feature tests make requests against the real backend instead of using fixtures.
This also implies that database queries are executed which makes this category significantly slower.

### When to use feature tests

- use cases that require a backend and cannot be tested using fixtures
- behavior that is not part of a page bundle but defined globally

### Relevant notes

A `:js` flag is added to the test to make sure the full environment is loaded.

```
scenario 'successfully', :js do
  sign_in(create(:admin))
end
```

The steps of each test are written using capybara methods ([documentation](http://www.rubydoc.info/gems/capybara/2.15.1)).

Bear in mind <abbr title="XMLHttpRequest">XHR</abbr> calls might require you to use `wait_for_requests` in between steps, like so:

```rspec
find('.form-control').native.send_keys(:enter)

wait_for_requests

expect(page).not_to have_selector('.card')
```

## Test helpers

---

> TODO: update the following sections

---

## Types of tests in our codebase

* **RSpec**
  * **[Ruby unit tests](#ruby-unit-tests-spec-rb)** for models, controllers, helpers, etc. (`/spec/**/*.rb`)
  * **[Full feature tests](#full-feature-tests-spec-features-rb)** (`/spec/features/**/*.rb`)
* **[Karma](#karma-tests-spec-javascripts-js)** (`/spec/javascripts/**/*.js`)
* <s>Spinach</s> — These have been removed from our codebase in May 2018. (`/features/`)

## RSpec: Ruby unit tests `/spec/**/*.rb`

These tests are meant to unit test the ruby models, controllers and helpers.

### When do we write/update these tests?

Whenever we create or modify any Ruby models, controllers or helpers we add/update corresponding tests.

---

## RSpec: Full feature tests `/spec/features/**/*.rb`

Full feature tests will load a full app environment and allow us to test things like rendering DOM, interacting with links and buttons, testing the outcome of those interactions through multiple pages if necessary. These are also called end-to-end tests but should not be confused with QA end-to-end tests (`package-and-qa` manual pipeline job).

### When do we write/update these tests?

When we add a new feature, we write at least two tests covering the success and the failure scenarios.

### Relevant notes

A `:js` flag is added to the test to make sure the full environment is loaded.

```
scenario 'successfully', :js do
  sign_in(create(:admin))
end
```

The steps of each test are written using capybara methods ([documentation](http://www.rubydoc.info/gems/capybara/2.15.1)).

Bear in mind <abbr title="XMLHttpRequest">XHR</abbr> calls might require you to use `wait_for_requests` in between steps, like so:

```rspec
find('.form-control').native.send_keys(:enter)

wait_for_requests

expect(page).not_to have_selector('.card')
```

---

## Karma tests `/spec/javascripts/**/*.js`

These are the more frontend-focused, at the moment. They're **faster** than `rspec` and make for very quick testing of frontend components.

### When do we write/update these tests?

When we add/update a method/action/mutation to Vue or Vuex, we write karma tests to ensure the logic we wrote doesn't break. We should, however, refrain from writing tests that double-test Vue's internal features.

### Relevant notes

Karma tests are run against a virtual DOM.

To populate the DOM, we can use fixtures to fake the generation of HTML instead of having Rails do that.

Be sure to check the [best practices for karma tests](../../testing_guide/frontend_testing.html#best-practices).

### Vue and Vuex

Test as much as possible without double-testing Vue's internal features, as mentioned above.

Make sure to test computedProperties, mutations, actions. Run the action and test that the proper mutations are committed.

Also check these [notes on testing Vue components](../../fe_guide/vue.html#testing-vue-components).

#### Vuex Helper: `testAction`

We have a helper available to make testing actions easier, as per [official documentation](https://vuex.vuejs.org/en/testing.html):

```
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

Check an example in [spec/javascripts/ide/stores/actions_spec.jsspec/javascripts/ide/stores/actions_spec.js](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/spec/javascripts/ide/stores/actions_spec.js).

#### Vue Helper: `mountComponent`

To make mounting a Vue component easier and more readable, we have a few helpers available in `spec/helpers/vue_mount_component_helper`.

* `createComponentWithStore`
* `mountComponentWithStore`

Examples of usage:

```
beforeEach(() => {
  vm = createComponentWithStore(Component, store);

  vm.$store.state.currentBranchId = 'master';

  vm.$mount();
},
```

```
beforeEach(() => {
  vm = mountComponentWithStore(Component, {
    el: '#dummy-element',
    store,
    props: { badge },
  });
},
```

Don't forget to clean up:

```
afterEach(() => {
  vm.$destroy();
});
```
## Testing with older browsers

Some regressions only affect a specific browser version. We can install and test in particular browsers with either Firefox or Browserstack using the following steps:


### Browserstack

[Browserstack](https://www.browserstack.com/) allows you to test more than 1200 mobile devices and browsers. 
You can use it directly through the [live app](https://www.browserstack.com/live) or you can install the [chrome extension](https://chrome.google.com/webstore/detail/browserstack/nkihdmlheodkdfojglpcjjmioefjahjb) for easy access.
You can find the credentials on 1Password, under `frontendteam@gitlab.com`.

### Firefox

#### macOS
You can download any older version of Firefox from the releases FTP server, https://ftp.mozilla.org/pub/firefox/releases/

1. From the website, select a version, in this case `50.0.1`.
2. Go to the mac folder.
3. Select your preferred language, you will find the dmg package inside, download it.
4. Drag and drop the application to any other folder but the `Applications` folder.
5. Rename the application to something like `Firefox_Old`.
6. Move the application to the `Applications` folder.
7. Open up a terminal and run `/Applications/Firefox_Old.app/Contents/MacOS/firefox-bin -profilemanager` to create a new profile specific to that Firefox version.
8. Once the profile has been created, quit the app, and run it again like normal. You now have a working older Firefox version.

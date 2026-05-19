import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createDefaultClient from '~/lib/graphql';

/**
 * @param {boolean|VueApollo} apolloProviderOption
 * @returns {undefined | VueApollo}
 */
const getApolloProvider = (apolloProviderOption) => {
  if (apolloProviderOption) {
    Vue.use(VueApollo);
    if (apolloProviderOption === true) {
      return new VueApollo({
        defaultClient: createDefaultClient(),
      });
    }

    // Checking for `instanceof VueApollo` may fail when using aliases in Vue3 compat mode
    // Check for a configured `defaultClient` instead
    if (apolloProviderOption.defaultClient) {
      return apolloProviderOption;
    }
  }

  return undefined;
};

const registerVueRouter = () => {
  Vue.use(VueRouter);
};

const registerGlToast = () => {
  Vue.use(GlToast);
};

/**
 * Initializes a component as a simple vue app, passing the necessary props. If the element
 * has a data attribute named `data-view-model`, the content of that attributed will be
 * converted from json and passed on to the component as a prop. The root component is then
 * responsible for setting up it's children, injections, and other desired features.
 * If the element has a data attribute named `data-provide`
 * the content of that attribute will be
 * converted from json and passed on to the component as a provide values.
 *
 * @param {string} selector css selector for where to build
 * @param {Vue.component} component The Vue component to be built as the root of the app
 * @param {{withApolloProvider: boolean|VueApollo}} options. extra options to be passed to the vue app
 *      withApolloProvider: if true, instantiates a default apolloProvider. Also accepts and instance of VueApollo
 *      withVueRouter: if true, registers Vue Router as a Vue plugin. Use when the root component (or any of
 *        its descendants) declares its own router via the `router` option, or uses `<router-view>`,
 *        `<router-link>`, `$route`, or `$router`.
 *      withGlToast: if true, registers GlToast as a Vue plugin. Use when the root component (or any of
 *        its descendants) calls `this.$toast.show(...)` to display toast notifications.
 * @param {{name: string}} Name of the app

 *
 * @example
 * ```html
 * <div id='#mount-here' data-view-model="{'some': 'object'}" />
 * ```
 *
 * ```javascript
 * initSimpleApp('#mount-here', MyApp, { withApolloProvider: true, name: 'MyAppRoot' })
 * ```
 *
 * This will mount MyApp as root on '#mount-here'. It will receive {'some': 'object'} as it's
 * view model prop.
 *
 * @example
 * ```html
 * <div id='#mount-here' data-provide="{'some': 'object'}" />
 * ```
 *
 * ```javascript
 * initSimpleApp('#mount-here', MyApp, { withApolloProvider: true, name: 'MyAppRoot' })
 * ```
 *
 * This will mount MyApp as root on '#mount-here'. It will receive {'some': 'object'} as it's
 * provide values.
 */
export const initSimpleApp = (
  selector,
  component,
  {
    withApolloProvider,
    withVueRouter = false,
    withGlToast = false,
    name,
    additionalProvide = {},
  } = {},
) => {
  const element = document.querySelector(selector);

  if (!element) {
    return null;
  }

  if (withVueRouter) {
    registerVueRouter();
  }

  if (withGlToast) {
    registerGlToast();
  }

  const apolloProvider = getApolloProvider(withApolloProvider);
  const provide = {
    ...(element.dataset.provide ? JSON.parse(element.dataset.provide) : {}),
    ...additionalProvide,
  };
  const props = element.dataset.viewModel ? JSON.parse(element.dataset.viewModel) : {};

  return new Vue({
    el: element,
    apolloProvider,
    name,
    provide,
    render(h) {
      return h(component, { props });
    },
  });
};

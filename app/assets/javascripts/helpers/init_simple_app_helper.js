import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

/**
 * @param {boolean|VueApollo} apolloProviderOption
 * @returns {undefined | VueApollo}
 */
const getApolloProvider = (apolloProviderOption) => {
  if (apolloProviderOption === true) {
    Vue.use(VueApollo);

    return new VueApollo({
      defaultClient: createDefaultClient(),
    });
  }

  if (apolloProviderOption instanceof VueApollo) {
    return apolloProviderOption;
  }

  return undefined;
};

/**
 * Initializes a component as a simple vue app, passing the necessary props. If the element
 * has a data attribute named `data-view-model`, the content of that attributed will be
 * converted from json and passed on to the component as a prop. The root component is then
 * responsible for setting up it's children, injections, and other desired features.
 *
 * @param {string} selector css selector for where to build
 * @param {Vue.component} component The Vue compoment to be built as the root of the app
 * @param {{withApolloProvider: boolean|VueApollo}} options. extra options to be passed to the vue app
 *      withApolloProvider: if true, instantiates a default apolloProvider. Also accepts and instance of VueApollo
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
 */
export const initSimpleApp = (selector, component, { withApolloProvider, name } = {}) => {
  const element = document.querySelector(selector);

  if (!element) {
    return null;
  }

  const props = element.dataset.viewModel ? JSON.parse(element.dataset.viewModel) : {};

  return new Vue({
    el: element,
    apolloProvider: getApolloProvider(withApolloProvider),
    name,
    render(h) {
      return h(component, { props });
    },
  });
};

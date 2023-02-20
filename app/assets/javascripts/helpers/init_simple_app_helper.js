import Vue from 'vue';

/**
 * Initializes a component as a simple vue app, passing the necessary props. If the element
 * has a data attribute named `data-view-model`, the content of that attributed will be
 * converted from json and passed on to the component as a prop. The root component is then
 * responsible for setting up it's children, injections, and other desired features.
 *
 * @param {string} selector css selector for where to build
 * @param {Vue.component} component The Vue compoment to be built as the root of the app
 *
 * @example
 * ```html
 * <div id='#mount-here' data-view-model="{'some': 'object'}" />
 * ```
 *
 * ```javascript
 * initSimpleApp('#mount-here', MyApp)
 * ```
 *
 * This will mount MyApp as root on '#mount-here'. It will receive {'some': 'object'} as it's
 * view model prop.
 */
export const initSimpleApp = (selector, component) => {
  const element = document.querySelector(selector);

  if (!element) {
    return null;
  }

  const props = element.dataset.viewModel ? JSON.parse(element.dataset.viewModel) : {};

  return new Vue({
    el: element,
    render(h) {
      return h(component, { props });
    },
  });
};

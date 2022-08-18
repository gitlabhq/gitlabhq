/**
 * Deprecated. Please do not use.
 * Please see https://gitlab.com/groups/gitlab-org/-/epics/2445
 */
const mountComponent = (Component, props = {}, el = null) =>
  new Component({
    propsData: props,
  }).$mount(el);

/**
 * Deprecated. Please do not use.
 * Please see https://gitlab.com/groups/gitlab-org/-/epics/2445
 */
export const createComponentWithStore = (Component, store, propsData = {}) =>
  new Component({
    store,
    propsData,
  });

/**
 * Deprecated. Please do not use.
 * Please see https://gitlab.com/groups/gitlab-org/-/epics/2445
 */
export const mountComponentWithStore = (Component, { el, props, store }) =>
  new Component({
    store,
    propsData: props || {},
  }).$mount(el);

/**
 * Deprecated. Please do not use.
 * Please see https://gitlab.com/groups/gitlab-org/-/epics/2445
 */
export default mountComponent;

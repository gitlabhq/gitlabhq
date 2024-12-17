import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { describeSkipVue3, SkipReason } from 'helpers/vue3_conditional';
import Item from '~/ide/components/merge_requests/item.vue';
import { createRouter } from '~/ide/ide_router';
import { createStore } from '~/ide/stores';

const TEST_ITEM = {
  iid: 1,
  projectPathWithNamespace: 'gitlab-org/gitlab-ce',
  title: 'Merge request title',
};

const skipReason = new SkipReason({
  name: 'IDE merge request item',
  reason: 'Legacy WebIDE is due for deletion',
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/508949',
});
describeSkipVue3(skipReason, () => {
  Vue.use(Vuex);

  let wrapper;
  let store;
  let router;

  const createComponent = (props = {}) => {
    wrapper = mount(Item, {
      propsData: {
        item: {
          ...TEST_ITEM,
        },
        currentId: `${TEST_ITEM.iid}`,
        currentProjectId: TEST_ITEM.projectPathWithNamespace,
        ...props,
      },
      router,
      store,
    });
  };
  const findIcon = () => wrapper.find('[data-testid="mobile-issue-close-icon"]');

  beforeEach(() => {
    store = createStore();
    router = createRouter(store);
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders merge requests data', () => {
      expect(wrapper.text()).toContain('Merge request title');
      expect(wrapper.text()).toContain('gitlab-org/gitlab-ce!1');
    });

    it('renders link with href', () => {
      const expectedHref = router.resolve(
        `/project/${TEST_ITEM.projectPathWithNamespace}/merge_requests/${TEST_ITEM.iid}`,
      ).href;

      expect(wrapper.element.tagName.toLowerCase()).toBe('a');
      expect(wrapper.attributes('href')).toBe(expectedHref);
    });

    it('renders icon if ID matches currentId', () => {
      expect(findIcon().exists()).toBe(true);
    });
  });

  describe('with different currentId', () => {
    beforeEach(() => {
      createComponent({ currentId: `${TEST_ITEM.iid + 1}` });
    });

    it('does not render icon', () => {
      expect(findIcon().exists()).toBe(false);
    });
  });

  describe('with different project ID', () => {
    beforeEach(() => {
      createComponent({ currentProjectId: 'test/test' });
    });

    it('does not render icon', () => {
      expect(findIcon().exists()).toBe(false);
    });
  });
});

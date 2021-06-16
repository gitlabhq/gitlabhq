import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Item from '~/ide/components/branches/item.vue';
import { createRouter } from '~/ide/ide_router';
import { createStore } from '~/ide/stores';
import Timeago from '~/vue_shared/components/time_ago_tooltip.vue';
import { projectData } from '../../mock_data';

const TEST_BRANCH = {
  name: 'main',
  committedDate: '2018-01-05T05:50Z',
};
const TEST_PROJECT_ID = projectData.name_with_namespace;

describe('IDE branch item', () => {
  let wrapper;
  let store;
  let router;

  function createComponent(props = {}) {
    wrapper = shallowMount(Item, {
      propsData: {
        item: { ...TEST_BRANCH },
        projectId: TEST_PROJECT_ID,
        isActive: false,
        ...props,
      },
      router,
    });
  }

  beforeEach(() => {
    store = createStore();
    router = createRouter(store);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('if not active', () => {
    beforeEach(() => {
      createComponent();
    });
    it('renders branch name and timeago', () => {
      expect(wrapper.text()).toContain(TEST_BRANCH.name);
      expect(wrapper.find(Timeago).props('time')).toBe(TEST_BRANCH.committedDate);
      expect(wrapper.find(GlIcon).exists()).toBe(false);
    });

    it('renders link to branch', () => {
      const expectedHref = router.resolve(`/project/${TEST_PROJECT_ID}/edit/${TEST_BRANCH.name}`)
        .href;

      expect(wrapper.text()).toMatch('a');
      expect(wrapper.attributes('href')).toBe(expectedHref);
    });
  });

  it('renders icon if is not active', () => {
    createComponent({ isActive: true });

    expect(wrapper.find(GlIcon).exists()).toBe(true);
  });
});

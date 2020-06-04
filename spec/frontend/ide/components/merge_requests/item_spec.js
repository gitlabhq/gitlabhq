import { mount } from '@vue/test-utils';
import router from '~/ide/ide_router';
import Item from '~/ide/components/merge_requests/item.vue';

const TEST_ITEM = {
  iid: 1,
  projectPathWithNamespace: 'gitlab-org/gitlab-ce',
  title: 'Merge request title',
};

describe('IDE merge request item', () => {
  let wrapper;

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
    });
  };
  const findIcon = () => wrapper.find('.ic-mobile-issue-close');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
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

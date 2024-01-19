import { GlTab, GlTabs, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import CatalogTabs from '~/ci/catalog/components/list/catalog_tabs.vue';
import { SCOPE } from '~/ci/catalog/constants';

describe('Catalog Tabs', () => {
  let wrapper;

  const defaultProps = {
    isLoading: false,
    resourceCounts: {
      all: 11,
      namespaces: 4,
    },
  };

  const findAllTab = () => wrapper.findByTestId('resources-all-tab');
  const findGroupResourcesTab = () => wrapper.findByTestId('resources-group-tab');
  const findLoadingIcons = () => wrapper.findAllComponents(GlLoadingIcon);

  const triggerTabChange = (index) => wrapper.findAllComponents(GlTab).at(index).vm.$emit('click');

  const createComponent = (props = defaultProps) => {
    wrapper = extendedWrapper(
      shallowMount(CatalogTabs, {
        propsData: {
          ...props,
        },
        stubs: { GlTabs },
      }),
    );
  };

  describe('When count queries are loading', () => {
    beforeEach(() => {
      createComponent({ ...defaultProps, isLoading: true });
    });

    it('renders loading icons', () => {
      expect(findLoadingIcons()).toHaveLength(2);
    });
  });

  describe('When both tabs have resources', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders All tab with count', () => {
      expect(trimText(findAllTab().text())).toBe(`All ${defaultProps.resourceCounts.all}`);
    });

    it('renders group resources tab with count', () => {
      expect(trimText(findGroupResourcesTab().text())).toBe(
        `Your groups ${defaultProps.resourceCounts.namespaces}`,
      );
    });

    it.each`
      tabIndex | expectedScope
      ${0}     | ${SCOPE.all}
      ${1}     | ${SCOPE.namespaces}
    `('emits setScope with $expectedScope on tab change', ({ tabIndex, expectedScope }) => {
      triggerTabChange(tabIndex);

      expect(wrapper.emitted()).toEqual({ setScope: [[expectedScope]] });
    });
  });
});

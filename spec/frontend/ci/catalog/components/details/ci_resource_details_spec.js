import { GlTabs, GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CiResourceComponents from '~/ci/catalog/components/details/ci_resource_components.vue';
import CiResourceDetails from '~/ci/catalog/components/details/ci_resource_details.vue';
import CiResourceReadme from '~/ci/catalog/components/details/ci_resource_readme.vue';

describe('CiResourceDetails', () => {
  let wrapper;

  const defaultProps = {
    resourcePath: 'twitter/project-1',
    version: '1.0.1',
  };

  const createComponent = ({ props = {}, slots = {} } = {}) => {
    wrapper = shallowMount(CiResourceDetails, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      slots,
    });
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findCiResourceReadme = () => wrapper.findComponent(CiResourceReadme);
  const findCiResourceComponents = () => wrapper.findComponent(CiResourceComponents);

  describe('tabs', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the readme and components tabs', () => {
      expect(findAllTabs()).toHaveLength(2);
      expect(findCiResourceComponents().exists()).toBe(true);
      expect(findCiResourceReadme().exists()).toBe(true);
    });

    it('syncs the active tab with the URL query params', () => {
      expect(findTabs().props('syncActiveTabWithQueryParams')).toBe(true);
    });

    it('assigns a query param value to each tab', () => {
      expect(findAllTabs().wrappers.map((tab) => tab.props('queryParamValue'))).toEqual([
        'components',
        'readme',
      ]);
    });

    it('passes lazy attribute to all tabs', () => {
      findAllTabs().wrappers.forEach((tab) => {
        expect(tab.attributes().lazy).not.toBeUndefined();
      });
    });
  });

  describe('Inner tab components', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes the right props to the readme component', () => {
      expect(findCiResourceReadme().props('resourcePath')).toBe(defaultProps.resourcePath);
      expect(findCiResourceReadme().props('version')).toBe(defaultProps.version);
    });

    it('passes the right props to the components tab', () => {
      expect(findCiResourceComponents().props('resourcePath')).toBe(defaultProps.resourcePath);
      expect(findCiResourceComponents().props('version')).toBe(defaultProps.version);
    });
  });

  describe('extra-tabs slot', () => {
    it('renders content provided to the extra-tabs slot', () => {
      createComponent({
        slots: { 'extra-tabs': '<div data-testid="extra-tab-content"></div>' },
      });

      expect(wrapper.find('[data-testid="extra-tab-content"]').exists()).toBe(true);
    });

    it('does not render extra tabs when the slot is empty', () => {
      createComponent();

      expect(wrapper.find('[data-testid="extra-tab-content"]').exists()).toBe(false);
    });
  });
});

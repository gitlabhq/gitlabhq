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

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(CiResourceDetails, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlTabs,
      },
    });
  };
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findCiResourceReadme = () => wrapper.findComponent(CiResourceReadme);
  const findCiResourceComponents = () => wrapper.findComponent(CiResourceComponents);

  describe('UI', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes the right props to the readme component', () => {
      expect(findCiResourceReadme().props().resourceId).toBe(defaultProps.resourceId);
    });
  });

  describe('tabs', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the readme and components tabs', () => {
      expect(findAllTabs()).toHaveLength(2);
      expect(findCiResourceComponents().exists()).toBe(true);
      expect(findCiResourceReadme().exists()).toBe(true);
    });

    it('passes lazy attribute to all tabs', () => {
      findAllTabs().wrappers.forEach((tab) => {
        expect(tab.attributes().lazy).not.toBeUndefined();
      });
    });

    describe('Inner tab components', () => {
      beforeEach(() => {
        createComponent();
      });

      it('passes lazy attribute to all tabs', () => {
        findAllTabs().wrappers.forEach((tab) => {
          expect(tab.attributes().lazy).not.toBeUndefined();
        });
      });

      it('passes the right props to the readme component', () => {
        expect(findCiResourceReadme().props().resourceId).toBe(defaultProps.resourceId);
        expect(findCiResourceReadme().props().version).toBe(defaultProps.version);
      });

      it('passes the right props to the components tab', () => {
        expect(findCiResourceComponents().props().resourceId).toBe(defaultProps.resourceId);
      });
    });
  });
});

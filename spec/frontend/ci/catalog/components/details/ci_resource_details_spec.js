import { GlTabs, GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CiResourceComponents from '~/ci/catalog/components/details/ci_resource_components.vue';
import CiResourceDetails from '~/ci/catalog/components/details/ci_resource_details.vue';
import CiResourceReadme from '~/ci/catalog/components/details/ci_resource_readme.vue';

describe('CiResourceDetails', () => {
  let wrapper;

  const defaultProps = {
    resourcePath: 'twitter/project-1',
  };
  const defaultProvide = {
    glFeatures: { ciCatalogComponentsTab: true },
  };

  const createComponent = ({ provide = {}, props = {} } = {}) => {
    wrapper = shallowMount(CiResourceDetails, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        GlTabs,
      },
    });
  };
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findCiResourceReadme = () => wrapper.findComponent(CiResourceReadme);
  const findCiResourceComponents = () => wrapper.findComponent(CiResourceComponents);

  describe('tabs', () => {
    describe('when feature flag `ci_catalog_components_tab` is enabled', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the readme and components tab', () => {
        expect(findAllTabs()).toHaveLength(2);
        expect(findCiResourceComponents().exists()).toBe(true);
        expect(findCiResourceReadme().exists()).toBe(true);
      });
    });

    describe('when feature flag `ci_catalog_components_tab` is disabled', () => {
      beforeEach(() => {
        createComponent({
          provide: { glFeatures: { ciCatalogComponentsTab: false } },
        });
      });

      it('renders only readme tab as default', () => {
        expect(findCiResourceReadme().exists()).toBe(true);
        expect(findCiResourceComponents().exists()).toBe(false);
        expect(findAllTabs()).toHaveLength(1);
      });
    });

    describe('UI', () => {
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
      });

      it('passes the right props to the components tab', () => {
        expect(findCiResourceComponents().props().resourceId).toBe(defaultProps.resourceId);
      });
    });
  });
});

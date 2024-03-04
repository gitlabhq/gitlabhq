import { GlTabs, GlTab } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import ExperimentBadge from '~/vue_shared/components/badges/experiment_badge.vue';
import CiResourceComponents from '~/ci/catalog/components/details/ci_resource_components.vue';
import CiResourceDetails from '~/ci/catalog/components/details/ci_resource_details.vue';
import CiResourceReadme from '~/ci/catalog/components/details/ci_resource_readme.vue';
import waitForPromises from 'helpers/wait_for_promises';

describe('CiResourceDetails', () => {
  let wrapper;

  const defaultProps = {
    resourcePath: 'twitter/project-1',
  };

  const createComponent = ({ mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(CiResourceDetails, {
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
  const findExperimentBadge = () => wrapper.findComponent(ExperimentBadge);

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

    it('renders an Experiment Badge for the components tab', async () => {
      createComponent({ mountFn: mount });
      await waitForPromises();

      expect(findExperimentBadge().exists()).toBe(true);
    });

    it('passes the right props to the components tab', () => {
      expect(findCiResourceComponents().props().resourceId).toBe(defaultProps.resourceId);
    });
  });
});

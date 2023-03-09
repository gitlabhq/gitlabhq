import { mount, shallowMount } from '@vue/test-utils';
import { GlBadge, GlTab } from '@gitlab/ui';

import IntegrationTabs from '~/integrations/overrides/components/integration_tabs.vue';
import { settingsTabTitle, overridesTabTitle } from '~/integrations/constants';

describe('IntegrationTabs', () => {
  let wrapper;

  const editPath = 'mock/edit';

  const createComponent = ({ mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(IntegrationTabs, {
      propsData: props,
      provide: {
        editPath,
      },
      stubs: {
        GlTab,
      },
    });
  };

  const findGlBadge = () => wrapper.findComponent(GlBadge);
  const findGlTab = () => wrapper.findComponent(GlTab);
  const findSettingsLink = () => wrapper.find('a');

  describe('template', () => {
    it('renders "Settings" tab as a link', () => {
      createComponent({ mountFn: mount });

      expect(findSettingsLink().text()).toMatchInterpolatedText(settingsTabTitle);
      expect(findSettingsLink().attributes('href')).toBe(editPath);
    });

    it('renders "Projects using custom settings" tab as active', () => {
      const projectOverridesCount = '1';

      createComponent({
        props: { projectOverridesCount },
      });

      expect(findGlTab().exists()).toBe(true);
      expect(findGlTab().text()).toMatchInterpolatedText(
        `${overridesTabTitle} ${projectOverridesCount}`,
      );
      expect(findGlBadge().text()).toBe(projectOverridesCount);
    });

    describe('when count is `null', () => {
      it('renders "Projects using custom settings" tab without count', () => {
        createComponent();

        expect(findGlTab().exists()).toBe(true);
        expect(findGlTab().text()).toMatchInterpolatedText(overridesTabTitle);
        expect(findGlBadge().exists()).toBe(false);
      });
    });
  });
});

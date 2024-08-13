import { shallowMount } from '@vue/test-utils';
import { GlBadge, GlTab } from '@gitlab/ui';

import { visitUrl } from '~/lib/utils/url_utility';
import IntegrationTabs from '~/integrations/overrides/components/integration_tabs.vue';
import { settingsTabTitle, overridesTabTitle } from '~/integrations/constants';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('IntegrationTabs', () => {
  let wrapper;

  const editPath = 'mock/edit';

  const createComponent = (props = {}) => {
    wrapper = shallowMount(IntegrationTabs, {
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
  const findAllTabs = () => wrapper.findAllComponents(GlTab);

  describe('template', () => {
    it('renders "Settings" tab', () => {
      createComponent();

      const tab = findAllTabs().at(0);

      expect(tab.exists()).toBe(true);
      expect(tab.attributes('title')).toBe(settingsTabTitle);
    });

    it('redirects to editPath when the settings tab is clicked', async () => {
      createComponent();

      const tab = findAllTabs().at(0);

      await tab.vm.$emit('click');

      expect(visitUrl).toHaveBeenCalledWith(editPath);
    });

    it('renders "Projects using custom settings" tab as active', () => {
      const projectOverridesCount = '1';

      createComponent({ projectOverridesCount });

      const tab = findAllTabs().at(1);

      expect(tab.exists()).toBe(true);
      expect(tab.text()).toMatchInterpolatedText(`${overridesTabTitle} ${projectOverridesCount}`);
      expect(findGlBadge().text()).toBe(projectOverridesCount);
    });

    describe('when count is `null', () => {
      it('renders "Projects using custom settings" tab without count', () => {
        createComponent();

        const tab = findAllTabs().at(1);

        expect(tab.exists()).toBe(true);
        expect(tab.text()).toMatchInterpolatedText(overridesTabTitle);
        expect(findGlBadge().exists()).toBe(false);
      });
    });
  });
});

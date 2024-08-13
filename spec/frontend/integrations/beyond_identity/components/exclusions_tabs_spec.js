import { GlTabs, GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { visitUrl } from '~/lib/utils/url_utility';
import ExclusionsTabs from '~/integrations/beyond_identity/components/exclusions_tabs.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('ExclusionsTabs component', () => {
  let wrapper;
  const editPath = 'path/to/edit';

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findAllTabs = () => wrapper.findAllComponents(GlTab);

  const createComponent = () =>
    shallowMountExtended(ExclusionsTabs, {
      provide: {
        editPath,
      },
      stubs: { GlTabs },
    });

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('default behavior', () => {
    it('renders a tabs component', () => {
      expect(findTabs().exists()).toBe(true);
    });

    it('renders a nav item for Settings', () => {
      const tab = findAllTabs().at(0);
      expect(tab.attributes('title')).toBe('Settings');
    });

    it('renders a tab for Exclusions', () => {
      const tab = findAllTabs().at(1);
      expect(tab.attributes('title')).toBe('Exclusions');
    });

    it('redirects to editPath when the settings tab is clicked', async () => {
      const tab = findAllTabs().at(0);

      await tab.vm.$emit('click');

      expect(visitUrl).toHaveBeenCalledWith(editPath);
    });
  });
});

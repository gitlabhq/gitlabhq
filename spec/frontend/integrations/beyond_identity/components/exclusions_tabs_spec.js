import { GlNavItem, GlTabs, GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ExclusionsTabs from '~/integrations/beyond_identity/components/exclusions_tabs.vue';

describe('ExclusionsTabs component', () => {
  let wrapper;
  const editPath = 'path/to/edit';

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findNavItem = () => wrapper.findComponent(GlNavItem);
  const findTab = () => wrapper.findComponent(GlTab);

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
      expect(findNavItem().text()).toBe('Settings');
      expect(findNavItem().attributes('href')).toBe(editPath);
    });

    it('renders a tab for Exclusions', () => {
      expect(findTab().text()).toBe('Exclusions');
    });
  });
});

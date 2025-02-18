import { mountExtended } from 'helpers/vue_test_utils_helper';
import VisibilityLevel from '~/organizations/settings/general/components/visibility_level.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import VisibilityLevelRadioButtons from '~/visibility_level/components/visibility_level_radio_buttons.vue';
import {
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS,
} from '~/visibility_level/constants';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';

describe('VisibilityLevel', () => {
  let wrapper;

  const defaultProvide = {
    organization: {
      id: 1,
      name: 'GitLab',
      path: 'foo-bar',
      description: 'foo bar',
      visibilityLevel: VISIBILITY_LEVEL_PRIVATE_INTEGER,
    },
  };

  const createComponent = () => {
    wrapper = mountExtended(VisibilityLevel, {
      provide: defaultProvide,
      stubs: {
        SettingsBlock,
      },
    });
  };

  const findSettingsBlockTitle = () => wrapper.findByTestId('settings-block-title');
  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);
  const findVisibilityLevelRadioButtons = () => wrapper.findComponent(VisibilityLevelRadioButtons);
  const findHelpPageLink = () => wrapper.findComponent(HelpPageLink);

  beforeEach(() => {
    createComponent();
  });

  it('renders settings block with title and description', () => {
    expect(findSettingsBlockTitle().text()).toBe('Visibility');
    expect(findSettingsBlock().text()).toContain('Choose organization visibility level.');
  });

  it('renders visibility level field with the current visibility as the only option', () => {
    expect(findVisibilityLevelRadioButtons().props()).toEqual({
      checked: VISIBILITY_LEVEL_PRIVATE_INTEGER,
      visibilityLevels: [VISIBILITY_LEVEL_PRIVATE_INTEGER],
      visibilityLevelDescriptions: ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS,
    });
  });

  it('renders label description with link to docs', () => {
    expect(wrapper.text()).toContain('Who can see this organization?');
    expect(findHelpPageLink().props()).toEqual({
      href: 'user/organization/_index',
      anchor: 'view-an-organizations-visibility-level',
    });
    expect(findHelpPageLink().text()).toBe('Learn more about visibility levels');
  });
});

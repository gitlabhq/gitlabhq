import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerConfigurationPopover from '~/ci/runner/components/runner_configuration_popover.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';

describe('RunnerConfigurationPopover', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(RunnerConfigurationPopover, {
      stubs: {
        GlSprintf,
      },
    });
  };

  const findHelpPopover = () => wrapper.findComponent(HelpPopover);
  const findHelpLink = () => findHelpPopover().findComponent(GlLink);
  const findCode = () => findHelpPopover().find('code');

  it('renders popover', () => {
    createComponent();

    expect(findHelpPopover().exists()).toBe(true);
  });

  it('renders help link', () => {
    createComponent();

    expect(findHelpLink().text()).toBe('single runner entry');
    expect(findHelpLink().attributes('href')).toContain(
      '/runner/configuration/advanced-configuration#the-runners-section',
    );
  });

  it('renders code text', () => {
    createComponent();

    expect(findCode().text()).toBe('config.toml');
  });
});

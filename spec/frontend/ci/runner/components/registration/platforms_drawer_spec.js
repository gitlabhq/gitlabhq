import { GlDrawer, GlLink, GlIcon, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';

import PlatformsDrawer from '~/ci/runner/components/registration/platforms_drawer.vue';
import CliCommand from '~/ci/runner/components/registration/cli_command.vue';
import { LINUX_PLATFORM, MACOS_PLATFORM, INSTALL_HELP_URL } from '~/ci/runner/constants';
import { installScript, platformArchitectures } from '~/ci/runner/components/registration/utils';

const MOCK_WRAPPER_HEIGHT = '99px';
const LINUX_ARCHS = platformArchitectures({ platform: LINUX_PLATFORM });
const MACOS_ARCHS = platformArchitectures({ platform: MACOS_PLATFORM });

jest.mock('~/lib/utils/dom_utils', () => ({
  getContentWrapperHeight: () => MOCK_WRAPPER_HEIGHT,
}));

describe('RegistrationInstructions', () => {
  let wrapper;

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findArchitectureOptions = () => wrapper.findByLabelText('Architecture').findAll('option');
  const findCliCommand = () => wrapper.findComponent(CliCommand);
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(PlatformsDrawer, {
      propsData: {
        open: true,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  it('shows drawer', () => {
    createComponent();

    expect(findDrawer().props()).toMatchObject({
      open: true,
      headerHeight: MOCK_WRAPPER_HEIGHT,
    });
  });

  it('closes drawer', () => {
    createComponent();
    findDrawer().vm.$emit('close');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('shows selection options', () => {
    createComponent({ mountFn: mountExtended });

    expect(findArchitectureOptions().wrappers.map((w) => w.attributes('value'))).toEqual(
      LINUX_ARCHS,
    );
  });

  it('shows script', () => {
    createComponent();

    expect(findCliCommand().props('command')).toBe(
      installScript({ platform: LINUX_PLATFORM, architecture: LINUX_ARCHS[0] }),
    );
  });

  it('shows selection options for another platform', () => {
    createComponent({
      mountFn: mountExtended,
      props: {
        platform: MACOS_PLATFORM,
      },
    });

    expect(findArchitectureOptions().wrappers.map((w) => w.attributes('value'))).toEqual(
      MACOS_ARCHS,
    );

    expect(findCliCommand().props('command')).toBe(
      installScript({ platform: MACOS_PLATFORM, architecture: MACOS_ARCHS[0] }),
    );
  });

  it('shows external link for more information', () => {
    createComponent();

    expect(findLink().attributes('href')).toBe(INSTALL_HELP_URL);
    expect(findLink().findComponent(GlIcon).props('name')).toBe('external-link');
  });
});

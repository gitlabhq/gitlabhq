import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerStatusPopover from '~/ci/runner/components/runner_status_popover.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { onlineContactTimeoutSecs, staleTimeoutSecs } from '../mock_data';

describe('RunnerStatusPopover', () => {
  let wrapper;

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(RunnerStatusPopover, {
      provide: {
        onlineContactTimeoutSecs,
        staleTimeoutSecs,
        ...provide,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findHelpPopover = () => wrapper.findComponent(HelpPopover);

  it('renders popoover', () => {
    createComponent();

    expect(findHelpPopover().exists()).toBe(true);
  });

  it('renders complete text', () => {
    createComponent();

    expect(findHelpPopover().text()).toMatchSnapshot();
  });
});

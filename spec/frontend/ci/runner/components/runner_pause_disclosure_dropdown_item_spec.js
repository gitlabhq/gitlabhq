import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { I18N_PAUSE, I18N_RESUME } from '~/ci/runner/constants';

import RunnerPauseDisclosureDropdownItem from '~/ci/runner/components/runner_pause_disclosure_dropdown_item.vue';
import RunnerPauseAction from '~/ci/runner/components/runner_pause_action.vue';

describe('RunnerPauseButton', () => {
  let wrapper;

  const findRunnerPauseAction = () => wrapper.findComponent(RunnerPauseAction);
  const findDisclosureDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  const createComponent = ({
    props = {},
    onClick = jest.fn(),
    mountFn = shallowMountExtended,
  } = {}) => {
    wrapper = mountFn(RunnerPauseDisclosureDropdownItem, {
      propsData: {
        runner: {},
        ...props,
      },
      stubs: {
        RunnerPauseAction: stubComponent(RunnerPauseAction, {
          render() {
            return this.$scopedSlots.default({
              onClick,
            });
          },
        }),
      },
    });
  };

  it('Displays paused runner button content', () => {
    createComponent({
      props: { runner: { paused: true } },
      mountFn: mountExtended,
    });

    expect(findDisclosureDropdownItem().text()).toBe(I18N_RESUME);
  });

  it('Displays active runner button content', () => {
    createComponent({
      props: { runner: { paused: false } },
      mountFn: mountExtended,
    });

    expect(findDisclosureDropdownItem().text()).toBe(I18N_PAUSE);
  });

  it('Triggers action', () => {
    const mockOnClick = jest.fn();

    createComponent({ onClick: mockOnClick });
    findDisclosureDropdownItem().vm.$emit('action');

    expect(mockOnClick).toHaveBeenCalled();
  });

  it('Emits toggledPaused when done', () => {
    createComponent();

    findRunnerPauseAction().vm.$emit('done');

    expect(wrapper.emitted('toggledPaused')).toHaveLength(1);
  });
});

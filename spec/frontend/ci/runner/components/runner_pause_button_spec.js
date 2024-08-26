import { GlButton } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import {
  I18N_PAUSE,
  I18N_PAUSE_TOOLTIP,
  I18N_RESUME,
  I18N_RESUME_TOOLTIP,
} from '~/ci/runner/constants';

import RunnerPauseButton from '~/ci/runner/components/runner_pause_button.vue';
import RunnerPauseAction from '~/ci/runner/components/runner_pause_action.vue';

describe('RunnerPauseButton', () => {
  let wrapper;

  const findRunnerPauseAction = () => wrapper.findComponent(RunnerPauseAction);
  const findBtn = () => wrapper.findComponent(GlButton);
  const getTooltip = () => getBinding(findBtn().element, 'gl-tooltip').value;

  const createComponent = ({
    props = {},
    loading,
    onClick = jest.fn(),
    mountFn = shallowMountExtended,
  } = {}) => {
    wrapper = mountFn(RunnerPauseButton, {
      propsData: {
        runner: {},
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        RunnerPauseAction: stubComponent(RunnerPauseAction, {
          render() {
            return this.$scopedSlots.default({
              loading,
              onClick,
            });
          },
        }),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('Pause/Resume button', () => {
    describe.each`
      runnerState | paused   | expectedIcon | expectedContent | expectedTooltip
      ${'paused'} | ${true}  | ${'play'}    | ${I18N_RESUME}  | ${I18N_RESUME_TOOLTIP}
      ${'active'} | ${false} | ${'pause'}   | ${I18N_PAUSE}   | ${I18N_PAUSE_TOOLTIP}
    `(
      'When the runner is $runnerState',
      ({ paused, expectedIcon, expectedContent, expectedTooltip }) => {
        beforeEach(() => {
          createComponent({
            props: {
              runner: { paused },
            },
          });
        });

        it(`Displays a ${expectedIcon} button`, () => {
          expect(findBtn().props('loading')).toBe(false);
          expect(findBtn().props('icon')).toBe(expectedIcon);
        });

        it('Displays button content', () => {
          expect(findBtn().text()).toBe(expectedContent);
          expect(getTooltip()).toBe(expectedTooltip);
        });

        it('Does not display redundant text for screen readers', () => {
          expect(findBtn().attributes('aria-label')).toBe(undefined);
        });
      },
    );
  });

  describe('Compact button', () => {
    describe.each`
      runnerState | paused   | expectedIcon | expectedContent | expectedTooltip
      ${'paused'} | ${true}  | ${'play'}    | ${I18N_RESUME}  | ${I18N_RESUME_TOOLTIP}
      ${'active'} | ${false} | ${'pause'}   | ${I18N_PAUSE}   | ${I18N_PAUSE_TOOLTIP}
    `(
      'When the runner is $runnerState',
      ({ paused, expectedIcon, expectedContent, expectedTooltip }) => {
        beforeEach(() => {
          createComponent({
            props: {
              runner: { paused },
              compact: true,
            },
            mountFn: mountExtended,
          });
        });

        it(`Displays a ${expectedIcon} button`, () => {
          expect(findBtn().props('loading')).toBe(false);
          expect(findBtn().props('icon')).toBe(expectedIcon);
        });

        it('Displays button content', () => {
          expect(findBtn().text()).toBe('');
          // Note: Use <template v-if> to ensure rendering a
          // text-less button. Ensure we don't send even empty an
          // content slot to prevent a distorted/rectangular button.
          expect(wrapper.find('.gl-button-text').exists()).toBe(false);

          expect(getTooltip()).toBe(expectedTooltip);
        });

        it('Does not display redundant text for screen readers', () => {
          expect(findBtn().attributes('aria-label')).toBe(expectedContent);
        });
      },
    );
  });

  it('Shows loading state', () => {
    createComponent({ loading: true });

    expect(findBtn().props('loading')).toBe(true);
    expect(getTooltip()).toBe('');
  });

  it('Triggers action', () => {
    const mockOnClick = jest.fn();

    createComponent({ onClick: mockOnClick });
    findBtn().vm.$emit('click');

    expect(mockOnClick).toHaveBeenCalled();
  });

  it('Emits toggledPaused when done', () => {
    createComponent();

    findRunnerPauseAction().vm.$emit('done');

    expect(wrapper.emitted('toggledPaused')).toHaveLength(1);
  });
});

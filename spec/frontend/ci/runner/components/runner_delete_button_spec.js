import { GlButton } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { I18N_DELETE_RUNNER } from '~/ci/runner/constants';

import RunnerDeleteButton from '~/ci/runner/components/runner_delete_button.vue';
import RunnerDeleteAction from '~/ci/runner/components/runner_delete_action.vue';
import { allRunnersData } from '../mock_data';

const mockRunner = allRunnersData.data.runners.nodes[0];

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

describe('RunnerDeleteButton', () => {
  let wrapper;

  const findBtn = () => wrapper.findComponent(GlButton);
  const getTooltip = () => getBinding(findBtn().element, 'gl-tooltip').value;

  const createComponent = ({ props = {}, loading, onClick = jest.fn() } = {}) => {
    wrapper = shallowMountExtended(RunnerDeleteButton, {
      propsData: {
        runner: mockRunner,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        RunnerDeleteAction: stubComponent(RunnerDeleteAction, {
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

  it('Displays a delete button without a icon or tooltip', () => {
    expect(findBtn().props()).toMatchObject({
      loading: false,
      icon: '',
    });
    expect(findBtn().classes('btn-icon')).toBe(false);
    expect(findBtn().text()).toBe(I18N_DELETE_RUNNER);

    expect(getTooltip()).toBe('');
  });

  it('Does not have tabindex when button is enabled', () => {
    expect(wrapper.attributes('tabindex')).toBeUndefined();
  });

  it('Triggers delete when clicked', () => {
    const mockOnClick = jest.fn();

    createComponent({ onClick: mockOnClick });
    expect(mockOnClick).not.toHaveBeenCalled();

    findBtn().vm.$emit('click');
    expect(mockOnClick).toHaveBeenCalledTimes(1);
  });

  it('Does not display redundant text for screen readers', () => {
    expect(findBtn().attributes('aria-label')).toBe(undefined);
  });

  it('Passes other attributes to the button', () => {
    createComponent({ props: { category: 'secondary' } });

    expect(findBtn().props('category')).toBe('secondary');
  });

  describe('When loading result', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('The button has a loading state', () => {
      expect(findBtn().props('loading')).toBe(true);
    });
  });

  describe('When done after deleting', () => {
    const doneEvent = { message: 'done!' };

    beforeEach(() => {
      wrapper.findComponent(RunnerDeleteAction).vm.$emit('done', doneEvent);
    });

    it('emits deleted event', () => {
      expect(wrapper.emitted('deleted')).toEqual([[doneEvent]]);
    });
  });

  describe('When displaying a compact button', () => {
    beforeEach(() => {
      createComponent({
        props: { compact: true },
      });
    });

    it('Displays no text', () => {
      expect(findBtn().text()).toBe('');
    });

    it('Displays "x" icon', () => {
      expect(findBtn().props('icon')).toBe('close');
      expect(findBtn().classes('btn-icon')).toBe(true);
    });

    it('Display correctly for screen readers', () => {
      expect(findBtn().attributes('aria-label')).toBe(I18N_DELETE_RUNNER);
      expect(getTooltip()).toBe(I18N_DELETE_RUNNER);
    });

    describe('When loading result', () => {
      beforeEach(() => {
        createComponent({
          props: { compact: true },
          loading: true,
        });
      });

      it('The stale tooltip is removed', () => {
        expect(getTooltip()).toBe('');
      });
    });
  });
});

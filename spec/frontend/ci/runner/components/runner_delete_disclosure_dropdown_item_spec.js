import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { I18N_DELETE } from '~/ci/runner/constants';

import RunnerDeleteDisclosureDropdownItem from '~/ci/runner/components/runner_delete_disclosure_dropdown_item.vue';
import RunnerDeleteAction from '~/ci/runner/components/runner_delete_action.vue';
import { allRunnersData } from '../mock_data';

const mockRunner = allRunnersData.data.runners.nodes[0];

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

describe('RunnerDeleteDisclosureDropdownItem', () => {
  let wrapper;
  let mockOnClick;

  const findDisclosureDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  const createComponent = () => {
    mockOnClick = jest.fn();

    wrapper = shallowMountExtended(RunnerDeleteDisclosureDropdownItem, {
      propsData: {
        runner: mockRunner,
      },
      stubs: {
        RunnerDeleteAction: stubComponent(RunnerDeleteAction, {
          render() {
            return this.$scopedSlots.default({
              onClick: mockOnClick,
            });
          },
        }),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('Displays a delete item', () => {
    expect(findDisclosureDropdownItem().text()).toBe(I18N_DELETE);
  });

  it('Does not trigger on load', () => {
    expect(mockOnClick).not.toHaveBeenCalled();
  });

  it('Triggers delete when clicked', () => {
    findDisclosureDropdownItem().vm.$emit('action');
    expect(mockOnClick).toHaveBeenCalledTimes(1);
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
});

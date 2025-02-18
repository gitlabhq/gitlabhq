import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TodosBulkBar from '~/todos/components/todos_bulk_bar.vue';
import { TABS_INDICES } from '~/todos/constants';

describe('TodosBulkBar', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(TodosBulkBar, {
      propsData: {
        ids: ['1', '2'],
        tab: TABS_INDICES.pending,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findSnoozeButton = () => wrapper.findByTestId('bulk-action-snooze');
  const findUnsnoozeButton = () => wrapper.findByTestId('bulk-action-unsnooze');
  const findResolveButton = () => wrapper.findByTestId('bulk-action-resolve');
  const findRestoreButton = () => wrapper.findByTestId('bulk-action-restore');

  it('shows number of selected items', () => {
    createComponent({ ids: ['1', '2', '3'] });
    expect(wrapper.findByTestId('selected-count').text()).toMatch(/3\s+selected/);
  });

  describe('button visibility', () => {
    it.each([
      [
        'pending',
        {
          snooze: true,
          unsnooze: false,
          resolve: true,
          restore: false,
        },
      ],
      [
        'snoozed',
        {
          snooze: false,
          unsnooze: true,
          resolve: true,
          restore: false,
        },
      ],
      [
        'done',
        {
          snooze: false,
          unsnooze: false,
          resolve: false,
          restore: true,
        },
      ],
    ])('shows correct buttons for %s tab', (tabName, expected) => {
      createComponent({ tab: TABS_INDICES[tabName] });

      expect(findSnoozeButton().exists()).toBe(expected.snooze);
      expect(findUnsnoozeButton().exists()).toBe(expected.unsnooze);
      expect(findResolveButton().exists()).toBe(expected.resolve);
      expect(findRestoreButton().exists()).toBe(expected.restore);
    });
  });
});

import { shallowMount } from '@vue/test-utils';
import { GlDisclosureDropdown, GlTooltip } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import SnoozeTodoDropdown from '~/todos/components/snooze_todo_dropdown.vue';
import { TODO_STATE_PENDING } from '~/todos/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import snoozeTodoMutation from '~/todos/components/mutations/snooze_todo.mutation.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeDate } from 'helpers/fake_date';

Vue.use(VueApollo);

describe('SnoozeTodoDropdown', () => {
  let wrapper;
  const mockTodo = {
    id: 'gid://gitlab/Todo/1',
    state: TODO_STATE_PENDING,
  };
  const mockCurrentTime = new Date('2024-12-18T13:24:00');
  const mockForAnHour = new Date('2024-12-18T14:24:00');
  const mockUntilLaterToday = new Date('2024-12-18T17:24:00');
  const mockUntilTomorrow = new Date('2024-12-19T08:00:00');
  const mockToastShow = jest.fn();

  useFakeDate(mockCurrentTime);

  const snoozeTodoMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      todoSnooze: {
        todo: {
          ...mockTodo,
          snoozedUntil: mockCurrentTime,
        },
        errors: [],
      },
    },
  });

  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findGlTooltip = () => wrapper.findComponent(GlTooltip);
  const getPredefinedSnoozingOption = (index) =>
    findGlDisclosureDropdown().props('items')[0].items[index];
  const toTimeString = (date) =>
    date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  const createComponent = ({
    snoozeTodoMutationHandler = snoozeTodoMutationSuccessHandler,
  } = {}) => {
    const mockApollo = createMockApollo();

    mockApollo.defaultClient.setRequestHandler(snoozeTodoMutation, snoozeTodoMutationHandler);

    wrapper = shallowMount(SnoozeTodoDropdown, {
      apolloProvider: mockApollo,
      propsData: {
        todo: mockTodo,
      },
      provide: {
        currentTime: mockCurrentTime,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  it('renders the snoozing options', () => {
    createComponent();

    expect(findGlDisclosureDropdown().props('items')).toEqual([
      {
        items: [
          expect.objectContaining({
            formattedDate: `Today, ${toTimeString(mockForAnHour)}`,
            text: 'For one hour',
          }),
          expect.objectContaining({
            formattedDate: `Today, ${toTimeString(mockUntilLaterToday)}`,
            text: 'Until later today',
          }),
          expect.objectContaining({
            formattedDate: `Tomorrow, ${toTimeString(mockUntilTomorrow)}`,
            text: 'Until tomorrow',
          }),
        ],
        name: 'Snooze',
      },
    ]);
  });

  it('has the correct props', () => {
    createComponent();

    expect(findGlDisclosureDropdown().props()).toMatchObject({
      toggleText: 'Snooze',
      icon: 'clock',
      placement: 'bottom-end',
      textSrOnly: true,
      noCaret: true,
      fluidWidth: true,
    });
  });

  it.each`
    index | expectedDate
    ${0}  | ${'2024-12-18T14:24:00.000Z'}
    ${1}  | ${'2024-12-18T17:24:00.000Z'}
    ${2}  | ${'2024-12-19T08:00:00.000Z'}
  `(
    'triggers the snooze action with snoozeUntil = $expectedDate when clicking option #$index',
    ({ index, expectedDate }) => {
      createComponent();

      getPredefinedSnoozingOption(index).action();

      expect(snoozeTodoMutationSuccessHandler).toHaveBeenCalledWith({
        snoozeUntil: new Date(expectedDate),
        todoId: mockTodo.id,
      });
    },
  );

  it('shows an error when the to snooze mutation returns some errors', async () => {
    createComponent({
      snoozeTodoMutationHandler: jest.fn().mockResolvedValue({
        data: {
          todoSnooze: {
            todo: { ...mockTodo },
            errors: ['Could not snooze todo-item.'],
          },
        },
      }),
    });
    getPredefinedSnoozingOption(0).action();
    await waitForPromises();

    expect(mockToastShow).toHaveBeenCalledWith('Failed to snooze todo. Try again later.', {
      variant: 'danger',
    });
  });

  it('shows an error when it fails to snooze the to-do item', async () => {
    createComponent({
      snoozeTodoMutationHandler: jest.fn().mockRejectedValue(),
    });
    getPredefinedSnoozingOption(0).action();
    await waitForPromises();

    expect(mockToastShow).toHaveBeenCalledWith('Failed to snooze todo. Try again later.', {
      variant: 'danger',
    });
  });

  it('attaches a tooltip to the dropdown toggle', () => {
    createComponent();
    const tooltip = findGlTooltip();

    expect(tooltip.exists()).toBe(true);
    expect(tooltip.text()).toBe('Snooze');
  });

  it('only shows the tooltip when the dropdown is closed', async () => {
    createComponent();
    findGlDisclosureDropdown().vm.$emit('shown');
    await nextTick();

    expect(findGlTooltip().exists()).toBe(false);

    findGlDisclosureDropdown().vm.$emit('hidden');
    await nextTick();

    expect(findGlTooltip().exists()).toBe(true);
  });
});

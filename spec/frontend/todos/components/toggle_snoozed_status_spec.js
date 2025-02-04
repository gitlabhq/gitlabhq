import { GlTooltip } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ToggleSnoozedStatus from '~/todos/components/toggle_snoozed_status.vue';
import { TODO_STATE_PENDING } from '~/todos/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import snoozeTodoMutation from '~/todos/components/mutations/snooze_todo.mutation.graphql';
import unSnoozeTodoMutation from '~/todos/components/mutations/un_snooze_todo.mutation.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeDate } from 'helpers/fake_date';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mockTracking, unmockTracking } from 'jest/__helpers__/tracking_helper';
import { stubComponent } from 'helpers/stub_component';
import SnoozeTodoModal from '~/todos/components/snooze_todo_modal.vue';

Vue.use(VueApollo);

describe('ToggleSnoozedStatus', () => {
  let wrapper;
  const mockTodo = {
    id: 'gid://gitlab/Todo/1',
    state: TODO_STATE_PENDING,
  };
  const mockCurrentTime = new Date('2024-12-18T13:24:00');
  const mockToastShow = jest.fn();
  const SnoozeTodoModalStub = stubComponent(SnoozeTodoModal, {
    methods: {
      show: jest.fn(),
    },
  });

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
  const unSnoozeTodoMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      todoUnSnooze: {
        todo: { ...mockTodo, snoozedUntil: mockCurrentTime },
        errors: [],
      },
    },
  });

  const findSnoozeDropdown = () => wrapper.findByTestId('snooze-dropdown');
  const findGlTooltip = () => wrapper.findComponent(GlTooltip);
  const getPredefinedSnoozingOption = (index) =>
    findSnoozeDropdown().props('items')[0].items[index];
  const findUnSnoozeButton = () => wrapper.findByTestId('un-snooze-button');

  const createComponent = ({
    props = {},
    snoozeTodoMutationHandler = snoozeTodoMutationSuccessHandler,
    unSnoozeTodoMutationHandler = unSnoozeTodoMutationSuccessHandler,
  } = {}) => {
    const mockApollo = createMockApollo();

    mockApollo.defaultClient.setRequestHandler(snoozeTodoMutation, snoozeTodoMutationHandler);
    mockApollo.defaultClient.setRequestHandler(unSnoozeTodoMutation, unSnoozeTodoMutationHandler);

    wrapper = shallowMountExtended(ToggleSnoozedStatus, {
      apolloProvider: mockApollo,
      propsData: {
        todo: mockTodo,
        ...props,
      },
      provide: {
        currentTime: mockCurrentTime,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
      stubs: {
        SnoozeTodoModal: SnoozeTodoModalStub,
      },
    });
  };

  describe('snoozing dropdown', () => {
    it('renders the dropdown if `isSnoozed` is `false` and the todo is pending', () => {
      createComponent({ props: { isSnoozed: false, isPending: true } });

      expect(findSnoozeDropdown().exists()).toBe(true);
    });

    it('does not render the dropdown if `isSnoozed` is `true` and the todo is pending', () => {
      createComponent({ props: { isSnoozed: true, isPending: true } });

      expect(findSnoozeDropdown().exists()).toBe(false);
    });

    it('does not render the dropdown if `isSnoozed` is `false` and the todo is done', () => {
      createComponent({
        props: { isSnoozed: false, isPending: false },
      });

      expect(findSnoozeDropdown().exists()).toBe(false);
    });
  });

  it('renders the snoozing options', () => {
    createComponent({ props: { isSnoozed: false, isPending: true } });

    expect(findSnoozeDropdown().props('items')).toEqual([
      {
        items: [
          expect.objectContaining({
            formattedDate: 'Today, 2:24 PM',
            text: 'For one hour',
          }),
          expect.objectContaining({
            formattedDate: 'Today, 5:24 PM',
            text: 'Until later today',
          }),
          expect.objectContaining({
            formattedDate: 'Tomorrow, 8:00 AM',
            text: 'Until tomorrow',
          }),
        ],
        name: 'Snooze',
      },
      {
        items: [
          expect.objectContaining({
            text: 'Until a specific time and date',
          }),
        ],
      },
    ]);
  });

  it('has the correct props', () => {
    createComponent({ props: { isSnoozed: false, isPending: true } });

    expect(findSnoozeDropdown().props()).toMatchObject({
      toggleText: 'Snooze...',
      icon: 'clock',
      placement: 'bottom-end',
      textSrOnly: true,
      noCaret: true,
      fluidWidth: true,
    });
  });

  it.each`
    index | expectedDate                  | expectedTrackingLabel
    ${0}  | ${'2024-12-18T14:24:00.000Z'} | ${'snooze_for_one_hour'}
    ${1}  | ${'2024-12-18T17:24:00.000Z'} | ${'snooze_until_later_today'}
    ${2}  | ${'2024-12-19T08:00:00.000Z'} | ${'snooze_until_tomorrow'}
  `(
    'triggers the snooze action with snoozeUntil = $expectedDate when clicking option #$index',
    ({ index, expectedDate, expectedTrackingLabel }) => {
      createComponent({ props: { isSnoozed: false, isPending: true } });
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      getPredefinedSnoozingOption(index).action();

      expect(snoozeTodoMutationSuccessHandler).toHaveBeenCalledWith({
        snoozeUntil: new Date(expectedDate),
        todoId: mockTodo.id,
      });
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_todo_item_action', {
        label: expectedTrackingLabel,
      });

      unmockTracking();
    },
  );

  it('opens the custom snooze todo modal when clicking on the `Until a specific time and date` option', () => {
    createComponent({ props: { isSnoozed: false, isPending: true } });

    expect(SnoozeTodoModalStub.methods.show).not.toHaveBeenCalled();

    findSnoozeDropdown().props('items')[1].items[0].action();

    expect(SnoozeTodoModalStub.methods.show).toHaveBeenCalled();
  });

  it('shows an error when the to snooze mutation returns some errors', async () => {
    createComponent({
      props: { isSnoozed: false, isPending: true },
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
      props: { isSnoozed: false, isPending: true },
      snoozeTodoMutationHandler: jest.fn().mockRejectedValue(),
    });
    getPredefinedSnoozingOption(0).action();
    await waitForPromises();

    expect(mockToastShow).toHaveBeenCalledWith('Failed to snooze todo. Try again later.', {
      variant: 'danger',
    });
  });

  it('attaches a tooltip to the dropdown toggle', () => {
    createComponent({ props: { isSnoozed: false, isPending: true } });
    const tooltip = findGlTooltip();

    expect(tooltip.exists()).toBe(true);
    expect(tooltip.text()).toBe('Snooze...');
  });

  it('only shows the tooltip when the dropdown is closed', async () => {
    createComponent({ props: { isSnoozed: false, isPending: true } });
    findSnoozeDropdown().vm.$emit('shown');
    await nextTick();

    expect(findGlTooltip().exists()).toBe(false);

    findSnoozeDropdown().vm.$emit('hidden');
    await nextTick();

    expect(findGlTooltip().exists()).toBe(true);
  });

  describe('un-snooze button', () => {
    it('renders if the to-do item is snoozed', () => {
      createComponent({ props: { isSnoozed: true, isPending: true } });

      expect(findUnSnoozeButton().exists()).toBe(true);
    });

    it('has the correct attributes', () => {
      createComponent({ props: { isSnoozed: true, isPending: true } });

      expect(findUnSnoozeButton().attributes()).toMatchObject({
        icon: 'time-out',
        title: 'Remove snooze',
        'aria-label': 'Remove snooze',
      });
    });

    it('triggers the un-snooze mutation', () => {
      createComponent({ props: { isSnoozed: true, isPending: true } });

      findUnSnoozeButton().vm.$emit('click');

      expect(unSnoozeTodoMutationSuccessHandler).toHaveBeenCalledWith({
        todoId: mockTodo.id,
      });
    });

    it('shows an error when the to un-snooze mutation returns some errors', async () => {
      createComponent({
        props: { isSnoozed: true, isPending: true },
        unSnoozeTodoMutationHandler: jest.fn().mockResolvedValue({
          data: {
            todoUnSnooze: {
              todo: { ...mockTodo },
              errors: ['Could not un-snooze todo-item.'],
            },
          },
        }),
      });

      findUnSnoozeButton().vm.$emit('click');
      await waitForPromises();

      expect(mockToastShow).toHaveBeenCalledWith('Failed to un-snooze todo. Try again later.', {
        variant: 'danger',
      });
    });

    it('shows an error when it fails to un-snooze the to-do item', async () => {
      createComponent({
        props: { isSnoozed: true, isPending: true },
        unSnoozeTodoMutationHandler: jest.fn().mockRejectedValue(),
      });
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      findUnSnoozeButton().vm.$emit('click');
      await waitForPromises();

      expect(mockToastShow).toHaveBeenCalledWith('Failed to un-snooze todo. Try again later.', {
        variant: 'danger',
      });
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_todo_item_action', {
        label: 'remove_snooze',
      });

      unmockTracking();
    });

    it('has a tooltip attached', () => {
      createComponent({ props: { isSnoozed: true, isPending: true } });

      const tooltip = getBinding(findUnSnoozeButton().element, 'gl-tooltip');

      expect(tooltip).toBeDefined();
    });
  });
});

import { GlDatepicker } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import SidebarDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import SidebarFormattedDate from '~/sidebar/components/date/sidebar_formatted_date.vue';
import SidebarInheritDate from '~/sidebar/components/date/sidebar_inherit_date.vue';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import epicStartDateQuery from '~/sidebar/queries/epic_start_date.query.graphql';
import issueDueDateQuery from '~/sidebar/queries/issue_due_date.query.graphql';
import issueDueDateSubscription from '~/graphql_shared/subscriptions/work_item_dates.subscription.graphql';
import {
  issuableDueDateResponse,
  issuableStartDateResponse,
  issueDueDateSubscriptionResponse,
} from '../../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('Sidebar date Widget', () => {
  let wrapper;
  let fakeApollo;
  const date = '2021-04-15';

  const findEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findPopoverIcon = () => wrapper.find('[data-testid="inherit-date-popover"]');
  const findDatePicker = () => wrapper.findComponent(GlDatepicker);

  const createComponent = ({
    dueDateQueryHandler = jest.fn().mockResolvedValue(issuableDueDateResponse()),
    startDateQueryHandler = jest.fn().mockResolvedValue(issuableStartDateResponse()),
    dueDateSubscriptionHandler = jest.fn().mockResolvedValue(issueDueDateSubscriptionResponse()),
    canInherit = false,
    dateType = undefined,
    issuableType = 'issue',
  } = {}) => {
    fakeApollo = createMockApollo([
      [issueDueDateQuery, dueDateQueryHandler],
      [epicStartDateQuery, startDateQueryHandler],
      [issueDueDateSubscription, dueDateSubscriptionHandler],
    ]);

    wrapper = shallowMount(SidebarDateWidget, {
      apolloProvider: fakeApollo,
      provide: {
        canUpdate: true,
      },
      propsData: {
        fullPath: 'group/project',
        iid: '1',
        issuableType,
        canInherit,
        dateType,
      },
      stubs: {
        SidebarEditableItem,
        GlDatepicker,
      },
    });
  };

  beforeEach(() => {
    window.gon.first_day_of_week = 1;
  });

  afterEach(() => {
    fakeApollo = null;
  });

  it('passes a `loading` prop as true to editable item when query is loading', () => {
    createComponent();

    expect(findEditableItem().props('loading')).toBe(true);
  });

  it('dateType is due date by default', () => {
    createComponent();

    expect(wrapper.text()).toContain('Due date');
  });

  it('does not display icon popover by default', () => {
    createComponent();

    expect(findPopoverIcon().exists()).toBe(false);
  });

  it('does not render GlDatePicker', () => {
    createComponent();

    expect(findDatePicker().exists()).toBe(false);
  });

  describe('when issuable has no due date', () => {
    beforeEach(async () => {
      createComponent({
        dueDateQueryHandler: jest.fn().mockResolvedValue(issuableDueDateResponse(null)),
      });
      await waitForPromises();
    });

    it('passes a `loading` prop as false to editable item', () => {
      expect(findEditableItem().props('loading')).toBe(false);
    });

    it('emits `dueDateUpdated` event with a `null` payload', () => {
      expect(wrapper.emitted('dueDateUpdated')).toEqual([[null]]);
    });
  });

  describe('when issue has due date', () => {
    beforeEach(async () => {
      createComponent({
        dueDateQueryHandler: jest.fn().mockResolvedValue(issuableDueDateResponse(date)),
      });
      await waitForPromises();
    });

    it('passes a `loading` prop as false to editable item', () => {
      expect(findEditableItem().props('loading')).toBe(false);
    });

    it('emits `dueDateUpdated` event with the date payload', () => {
      expect(wrapper.emitted('dueDateUpdated')).toEqual([[date]]);
    });

    it('uses a correct prop to set the initial date and first day of the week for GlDatePicker', () => {
      expect(findDatePicker().props()).toMatchObject({
        value: new Date(date),
        autocomplete: 'off',
        defaultDate: expect.any(Object),
        firstDay: window.gon.first_day_of_week,
      });
    });

    it('renders GlDatePicker', () => {
      expect(findDatePicker().exists()).toBe(true);
    });
  });

  describe('real time issue due date feature', () => {
    it('should call the subscription', async () => {
      const dueDateSubscriptionHandler = jest
        .fn()
        .mockResolvedValue(issueDueDateSubscriptionResponse());
      createComponent({ dueDateSubscriptionHandler });
      await waitForPromises();

      expect(dueDateSubscriptionHandler).toHaveBeenCalled();
    });
  });

  it.each`
    canInherit | component               | componentName             | expected
    ${true}    | ${SidebarFormattedDate} | ${'SidebarFormattedDate'} | ${false}
    ${true}    | ${SidebarInheritDate}   | ${'SidebarInheritDate'}   | ${true}
    ${false}   | ${SidebarFormattedDate} | ${'SidebarFormattedDate'} | ${true}
    ${false}   | ${SidebarInheritDate}   | ${'SidebarInheritDate'}   | ${false}
  `(
    'when canInherit is $canInherit, $componentName display is $expected',
    async ({ canInherit, component, expected }) => {
      createComponent({ canInherit });
      await waitForPromises();

      expect(wrapper.findComponent(component).exists()).toBe(expected);
    },
  );

  it('does not render SidebarInheritDate when canInherit is true and date is loading', () => {
    createComponent({ canInherit: true });

    expect(wrapper.findComponent(SidebarInheritDate).exists()).toBe(false);
  });

  it('displays an alert message when query is rejected', async () => {
    createComponent({
      dueDateQueryHandler: jest.fn().mockRejectedValue('Houston, we have a problem'),
    });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalled();
  });

  it.each`
    dateType       | text            | event                 | mockedResponse               | issuableType | queryHandler
    ${'dueDate'}   | ${'Due date'}   | ${'dueDateUpdated'}   | ${issuableDueDateResponse}   | ${'issue'}   | ${'dueDateQueryHandler'}
    ${'startDate'} | ${'Start date'} | ${'startDateUpdated'} | ${issuableStartDateResponse} | ${'epic'}    | ${'startDateQueryHandler'}
  `(
    'when dateType is $dateType, component renders $text and emits $event',
    async ({ dateType, text, event, mockedResponse, issuableType, queryHandler }) => {
      createComponent({
        dateType,
        issuableType,
        [queryHandler]: jest.fn().mockResolvedValue(mockedResponse(date)),
      });
      await waitForPromises();

      expect(wrapper.text()).toContain(text);
      expect(wrapper.emitted(event)).toEqual([[date]]);
    },
  );

  it('displays icon popover when issuable can inherit date', () => {
    createComponent({ canInherit: true });

    expect(findPopoverIcon().exists()).toBe(true);
  });
});

import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import SidebarDueDateWidget from '~/sidebar/components/due_date/sidebar_due_date_widget.vue';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import issueDueDateQuery from '~/sidebar/queries/issue_due_date.query.graphql';
import { issueDueDateResponse } from '../../mock_data';

jest.mock('~/flash');

Vue.use(VueApollo);

describe('Sidebar Due date Widget', () => {
  let wrapper;
  let fakeApollo;
  const date = '2021-04-15';

  const findEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findFormattedDueDate = () => wrapper.find("[data-testid='sidebar-duedate-value']");

  const createComponent = ({
    dueDateQueryHandler = jest.fn().mockResolvedValue(issueDueDateResponse()),
  } = {}) => {
    fakeApollo = createMockApollo([[issueDueDateQuery, dueDateQueryHandler]]);

    wrapper = shallowMount(SidebarDueDateWidget, {
      apolloProvider: fakeApollo,
      provide: {
        fullPath: 'group/project',
        iid: '1',
        canUpdate: true,
      },
      propsData: {
        issuableType: 'issue',
      },
      stubs: {
        SidebarEditableItem,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  it('passes a `loading` prop as true to editable item when query is loading', () => {
    createComponent();

    expect(findEditableItem().props('loading')).toBe(true);
  });

  describe('when issue has no due date', () => {
    beforeEach(async () => {
      createComponent({
        dueDateQueryHandler: jest.fn().mockResolvedValue(issueDueDateResponse(null)),
      });
      await waitForPromises();
    });

    it('passes a `loading` prop as false to editable item', () => {
      expect(findEditableItem().props('loading')).toBe(false);
    });

    it('dueDate is null by default', () => {
      expect(findFormattedDueDate().text()).toBe('None');
    });

    it('emits `dueDateUpdated` event with a `null` payload', () => {
      expect(wrapper.emitted('dueDateUpdated')).toEqual([[null]]);
    });
  });

  describe('when issue has due date', () => {
    beforeEach(async () => {
      createComponent({
        dueDateQueryHandler: jest.fn().mockResolvedValue(issueDueDateResponse(date)),
      });
      await waitForPromises();
    });

    it('passes a `loading` prop as false to editable item', () => {
      expect(findEditableItem().props('loading')).toBe(false);
    });

    it('has dueDate', () => {
      expect(findFormattedDueDate().text()).toBe('Apr 15, 2021');
    });

    it('emits `dueDateUpdated` event with the date payload', () => {
      expect(wrapper.emitted('dueDateUpdated')).toEqual([[date]]);
    });
  });

  it('displays a flash message when query is rejected', async () => {
    createComponent({
      dueDateQueryHandler: jest.fn().mockRejectedValue('Houston, we have a problem'),
    });
    await waitForPromises();

    expect(createFlash).toHaveBeenCalled();
  });
});

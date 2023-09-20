import { shallowMount } from '@vue/test-utils';
import ActivityEventsList from '~/admin/abuse_report/components/activity_events_list.vue';

describe('ActivityEventsList', () => {
  let wrapper;

  const mockSlotContent = 'Test slot content';

  const findActivityEventsList = () => wrapper.findComponent(ActivityEventsList);

  const createComponent = () => {
    wrapper = shallowMount(ActivityEventsList, {
      slots: {
        'history-items': mockSlotContent,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders activity title', () => {
    expect(findActivityEventsList().text()).toContain('Activity');
  });

  it('renders history-items slot', () => {
    expect(findActivityEventsList().text()).toContain(mockSlotContent);
  });
});

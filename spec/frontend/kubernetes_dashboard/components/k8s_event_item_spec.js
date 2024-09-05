import { shallowMount } from '@vue/test-utils';
import { GlBadge, GlSprintf } from '@gitlab/ui';
import K8sEventItem from '~/kubernetes_dashboard/components/k8s_event_item.vue';
import { useFakeDate } from 'helpers/fake_date';

describe('~/kubernetes_dashboard/components/k8s_event_item.vue', () => {
  useFakeDate(2023, 4, 1, 12, 4);
  let wrapper;

  const event = {
    type: 'normal',
    source: { component: 'my-component' },
    reason: 'Reason 1',
    message: 'Event 1',
    lastTimestamp: '2023-05-01T12:00:00Z',
  };

  const findTypeBadge = () => wrapper.findComponent(GlBadge);
  const findLastTimestamp = () => wrapper.find('[data-testid="event-last-timestamp"]');

  const createWrapper = () => {
    wrapper = shallowMount(K8sEventItem, {
      propsData: {
        event,
      },
      stubs: { GlSprintf },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('renders type badge', () => {
    expect(findTypeBadge().text()).toBe(event.type);
  });

  it('renders event source', () => {
    expect(wrapper.text()).toContain(`Source: ${event.source.component}`);
  });

  it('renders event last timestamp tooltip in correct format', () => {
    expect(findLastTimestamp().attributes('title')).toBe('May 1, 2023 at 12:00:00 PM GMT');
  });

  it('renders event age as text', () => {
    expect(findLastTimestamp().text()).toBe('4m');
  });

  it('renders event reason with message', () => {
    expect(wrapper.text()).toContain(`${event.reason}: ${event.message}`);
  });
});

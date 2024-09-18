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
  };

  const findTypeBadge = () => wrapper.findComponent(GlBadge);
  const findLastTimestamp = () => wrapper.find('[data-testid="event-last-timestamp"]');

  const createWrapper = ({ timestamp = '2023-05-01T12:00:00Z' } = {}) => {
    wrapper = shallowMount(K8sEventItem, {
      propsData: {
        event: {
          ...event,
          timestamp,
        },
      },
      stubs: { GlSprintf },
    });
  };

  it('renders type badge', () => {
    createWrapper();
    expect(findTypeBadge().text()).toBe(event.type);
  });

  it('renders event source', () => {
    createWrapper();
    expect(wrapper.text()).toContain(`Source: ${event.source.component}`);
  });

  it('renders event last timestamp tooltip in correct format', () => {
    createWrapper();
    expect(findLastTimestamp().attributes('title')).toBe('May 1, 2023 at 12:00:00 PM GMT');
  });

  it('renders unknown for event time if timestamp is not provided', () => {
    createWrapper({ timestamp: '' });
    expect(findLastTimestamp().text()).toBe('unknown');
  });

  it('renders event age as text', () => {
    createWrapper();
    expect(findLastTimestamp().text()).toBe('4m');
  });

  it('renders event reason with message', () => {
    createWrapper();
    expect(wrapper.text()).toContain(`${event.reason}: ${event.message}`);
  });
});

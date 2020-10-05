import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import HighlightBar from '~/issue_show/components/incidents/highlight_bar.vue';
import { formatDate } from '~/lib/utils/datetime_utility';

jest.mock('~/lib/utils/datetime_utility');

describe('Highlight Bar', () => {
  let wrapper;

  const alert = {
    iid: 1,
    startedAt: '2020-05-29T10:39:22Z',
    detailsUrl: 'http://127.0.0.1:3000/root/unique-alerts/-/alert_management/1/details',
    eventCount: 1,
    title: 'Alert 1',
  };

  const mountComponent = () => {
    wrapper = shallowMount(HighlightBar, {
      propsData: {
        alert,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findLink = () => wrapper.find(GlLink);

  it('renders a link to the alert page', () => {
    expect(findLink().exists()).toBe(true);
    expect(findLink().attributes('href')).toBe(alert.detailsUrl);
    expect(findLink().attributes('title')).toBe(alert.title);
    expect(findLink().text()).toBe(`#${alert.iid}`);
  });

  it('renders formatted start time of the alert', () => {
    const formattedDate = '2020-05-29 UTC';
    formatDate.mockReturnValueOnce(formattedDate);
    mountComponent();
    expect(formatDate).toHaveBeenCalledWith(alert.startedAt, 'yyyy-mm-dd Z');
    expect(wrapper.text()).toContain(formattedDate);
  });

  it('renders a number of alert events', () => {
    expect(wrapper.text()).toContain(alert.eventCount);
  });
});

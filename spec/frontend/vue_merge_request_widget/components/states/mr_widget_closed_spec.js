import { shallowMount } from '@vue/test-utils';
import closedComponent from '~/vue_merge_request_widget/components/states/mr_widget_closed.vue';
import MrWidgetAuthorTime from '~/vue_merge_request_widget/components/mr_widget_author_time.vue';
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';

const MOCK_DATA = {
  metrics: {
    mergedBy: {},
    closedBy: {
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://localhost:3000/root',
      avatarUrl: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    },
    mergedAt: 'Jan 24, 2018 1:02pm UTC',
    closedAt: 'Jan 24, 2018 1:02pm UTC',
    readableMergedAt: '',
    readableClosedAt: 'less than a minute ago',
  },
  targetBranchPath: '/twitter/flight/commits/so_long_jquery',
  targetBranch: 'so_long_jquery',
};

describe('MRWidgetClosed', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(closedComponent, {
      propsData: {
        mr: MOCK_DATA,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders closed icon', () => {
    expect(wrapper.findComponent(StateContainer).exists()).toBe(true);
    expect(wrapper.findComponent(StateContainer).props().status).toBe('closed');
  });

  it('renders mr widget author time', () => {
    expect(wrapper.findComponent(MrWidgetAuthorTime).exists()).toBe(true);
    expect(wrapper.findComponent(MrWidgetAuthorTime).props()).toEqual({
      actionText: 'Closed by',
      author: MOCK_DATA.metrics.closedBy,
      dateTitle: MOCK_DATA.metrics.closedAt,
      dateReadable: MOCK_DATA.metrics.readableClosedAt,
    });
  });
});

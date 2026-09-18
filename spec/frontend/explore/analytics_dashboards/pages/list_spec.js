import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ExploreAnalyticsDashboardsList from '~/explore/analytics_dashboards/pages/list.vue';
import IndexLayout from '~/vue_shared/components/index_layout.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';

describe('ExploreAnalyticsDashboardsList', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ExploreAnalyticsDashboardsList, {
      stubs: {
        IndexLayout,
        PageHeading,
      },
    });
  };

  const findPageHeading = () => wrapper.findComponent(PageHeading);

  beforeEach(() => {
    createComponent();
  });

  it('renders the page heading with the title', () => {
    expect(findPageHeading().exists()).toBe(true);
    expect(findPageHeading().props('heading')).toBe('Analytics dashboards');
  });
});

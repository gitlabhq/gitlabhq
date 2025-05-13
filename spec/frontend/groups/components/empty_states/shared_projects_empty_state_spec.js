import { mountExtended } from 'helpers/vue_test_utils_helper';
import SharedProjectsEmptyState from '~/groups/components/empty_states/shared_projects_empty_state.vue';
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';
import { SEARCH_MINIMUM_LENGTH } from '~/groups/constants';

let wrapper;

const defaultProvide = {
  emptyProjectsIllustration: '/assets/illustrations/empty-state/empty-projects-md.svg',
};

const createComponent = () => {
  wrapper = mountExtended(SharedProjectsEmptyState, {
    provide: defaultProvide,
  });
};

describe('SharedProjectsEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(ResourceListsEmptyState).props()).toMatchObject({
      title: 'This group has not been invited to any other projects.',
      svgPath: defaultProvide.emptyProjectsIllustration,
      search: '',
      searchMinimumLength: SEARCH_MINIMUM_LENGTH,
    });
    expect(wrapper.text()).toContain('Projects this group has been invited to will appear here.');
  });
});

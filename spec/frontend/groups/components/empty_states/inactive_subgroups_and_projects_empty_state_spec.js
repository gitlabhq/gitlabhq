import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InactiveSubgroupsAndProjectsEmptyState from '~/groups/components/empty_states/inactive_subgroups_and_projects_empty_state.vue';
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';
import { SEARCH_MINIMUM_LENGTH } from '~/groups/constants';

let wrapper;

const defaultProvide = {
  emptyProjectsIllustration: '/assets/llustrations/empty-state/empty-projects-md.svg',
};

const createComponent = () => {
  wrapper = shallowMountExtended(InactiveSubgroupsAndProjectsEmptyState, {
    provide: defaultProvide,
  });
};

describe('InactiveSubgroupsAndProjectsEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(ResourceListsEmptyState).props()).toMatchObject({
      title: 'There are no inactive subgroups or projects in this group',
      svgPath: defaultProvide.emptyProjectsIllustration,
      search: '',
      searchMinimumLength: SEARCH_MINIMUM_LENGTH,
    });
  });
});

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InactiveProjectsEmptyState from '~/groups/components/empty_states/inactive_projects_empty_state.vue';
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';
import { SEARCH_MINIMUM_LENGTH } from '~/groups/constants';

let wrapper;

const defaultProvide = {
  emptyProjectsIllustration: '/assets/llustrations/empty-state/empty-projects-md.svg',
};

const createComponent = () => {
  wrapper = shallowMountExtended(InactiveProjectsEmptyState, {
    provide: defaultProvide,
  });
};

describe('InactiveProjectsEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(ResourceListsEmptyState).props()).toMatchObject({
      title: InactiveProjectsEmptyState.i18n.title,
      svgPath: defaultProvide.emptyProjectsIllustration,
      search: '',
      searchMinimumLength: SEARCH_MINIMUM_LENGTH,
    });
  });
});

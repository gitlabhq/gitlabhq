import { GlEmptyState } from '@gitlab/ui';
import emptySearchSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupsAndProjectsEmptyState from '~/organizations/shared/components/groups_and_projects_empty_state.vue';

describe('GroupsAndProjectsEmptyState', () => {
  let wrapper;

  const defaultPropsData = {
    svgPath: 'path/to/svg',
    title: 'No results',
    description: 'Try again',
    search: '',
  };

  const createComponent = ({ propsData = {}, scopedSlots = {} } = {}) => {
    wrapper = shallowMountExtended(GroupsAndProjectsEmptyState, {
      propsData: { ...defaultPropsData, ...propsData },
      scopedSlots,
    });
  };

  describe('when search is empty', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlEmptyState component with passed props', () => {
      expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
        title: defaultPropsData.title,
        description: defaultPropsData.description,
        svgPath: defaultPropsData.svgPath,
        svgHeight: 144,
      });
    });
  });

  describe('when search is not empty', () => {
    beforeEach(() => {
      createComponent({ propsData: { search: 'foo' } });
    });

    it('renders GlEmptyState component with no results found message', () => {
      expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
        title: 'No results found',
        description: 'Edit your criteria and try again.',
        svgPath: emptySearchSvgPath,
        svgHeight: 144,
      });
    });
  });

  it('renders actions slot', () => {
    createComponent({ scopedSlots: { actions: '<div data-testid="actions-slot"></div>' } });

    expect(wrapper.findByTestId('actions-slot').exists()).toBe(true);
  });
});

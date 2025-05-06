import { GlEmptyState } from '@gitlab/ui';
import emptyStateProjectsSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-projects-md.svg?url';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ResourceListsEmptyState, {
  TYPES,
} from '~/vue_shared/components/resource_lists/empty_state.vue';
import EmptyResult from '~/vue_shared/components/empty_result.vue';

describe('ResourceListsEmptyState', () => {
  let wrapper;

  const defaultPropsData = {
    search: '',
    svgPath: emptyStateProjectsSvgPath,
    title: "You don't have any projects yet.",
    description:
      'Projects are where you can store your code, access issues, wiki, and other features of GitLab.',
    type: TYPES.search,
  };

  const createComponent = ({ propsData = {}, scopedSlots } = {}) => {
    wrapper = shallowMountExtended(ResourceListsEmptyState, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      scopedSlots,
    });
  };

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('without search', () => {
    it('renders empty state correctly', () => {
      createComponent();

      expect(findGlEmptyState().props()).toMatchObject({
        title: defaultPropsData.title,
        description: defaultPropsData.description,
        svgPath: emptyStateProjectsSvgPath,
      });
    });

    describe('with description slot', () => {
      beforeEach(() => {
        createComponent({
          scopedSlots: { description: '<div data-testid="description-slot"></div>' },
        });
      });

      it('correctly renders description', () => {
        expect(wrapper.findByTestId('description-slot').exists()).toBe(true);
      });
    });

    describe('with actions slot', () => {
      beforeEach(() => {
        createComponent({
          scopedSlots: { actions: '<div data-testid="actions-slot"></div>' },
        });
      });

      it('correctly renders actions', () => {
        expect(wrapper.findByTestId('actions-slot').exists()).toBe(true);
      });
    });
  });

  describe('with search', () => {
    beforeEach(() => {
      createComponent({ propsData: { search: 'tes' } });
    });

    it('renders EmptyResult component with correct props', () => {
      expect(wrapper.findComponent(EmptyResult).props()).toEqual({
        search: 'tes',
        searchMinimumLength: 0,
        type: defaultPropsData.type,
      });
    });
  });
});

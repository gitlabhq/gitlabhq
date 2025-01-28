import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectsListEmptyState from '~/vue_shared/components/projects_list/projects_list_empty_state.vue';

const MOCK_EMPTY_STATE_SEARCH_SVG_PATH = 'illustrations/empty-state/empty-search-md.svg';
const MOCK_EMPTY_STATE_PROJECTS_SVG_PATH = 'illustrations/empty-state/empty-projects-md.svg';

describe('ProjectsListEmptyState', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMountExtended(ProjectsListEmptyState, {
      propsData: {
        search: '',
        ...props,
      },
      provide: {
        emptyStateSearchSvgPath: MOCK_EMPTY_STATE_SEARCH_SVG_PATH,
        emptyStateProjectsSvgPath: MOCK_EMPTY_STATE_PROJECTS_SVG_PATH,
      },
    });
  };

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('without search', () => {
    it('renders empty state correctly', () => {
      createComponent();

      expect(findGlEmptyState().props()).toMatchObject({
        title: "You don't have any projects yet.",
        description:
          'Projects are where you can store your code, access issues, wiki, and other features of GitLab.',
        svgPath: MOCK_EMPTY_STATE_PROJECTS_SVG_PATH,
      });
    });

    describe('when title prop is passed', () => {
      const title = "You haven't starred any projects yet.";

      beforeEach(() => {
        createComponent({ title });
      });

      it('correctly passes to `GlEmptyState` component', () => {
        expect(findGlEmptyState().props('title')).toBe(title);
      });
    });

    describe('when description prop is passed', () => {
      const description =
        'Visit a project and select the star icon to save projects you want to find later.';

      beforeEach(() => {
        createComponent({ description });
      });

      it('correctly passes to `GlEmptyState` component', () => {
        expect(findGlEmptyState().props('description')).toBe(description);
      });
    });
  });

  describe('with search >=3 characters', () => {
    beforeEach(() => {
      createComponent({ search: 'tes' });
    });

    it('renders empty state correctly', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        title: 'No results found',
        description: 'Edit your criteria and try again.',
        svgPath: MOCK_EMPTY_STATE_SEARCH_SVG_PATH,
      });
    });
  });

  describe('with search <3 characters', () => {
    beforeEach(() => {
      createComponent({ search: 'te' });
    });

    it('renders empty state correctly', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        title: 'No results found',
        description: 'Search must be at least 3 characters.',
        svgPath: MOCK_EMPTY_STATE_SEARCH_SVG_PATH,
      });
    });
  });
});

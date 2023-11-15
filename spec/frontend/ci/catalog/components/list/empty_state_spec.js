import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EmptyState from '~/ci/catalog/components/list/empty_state.vue';
import { COMPONENTS_DOCS_URL } from '~/ci/catalog/constants';

describe('EmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findComponentsDocLink = () => wrapper.findComponent(GlLink);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(EmptyState, {
      propsData: {
        ...props,
      },
      stubs: {
        GlEmptyState,
        GlSprintf,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the default empty state', () => {
      const emptyState = findEmptyState();

      expect(emptyState.exists()).toBe(true);
      expect(emptyState.props().title).toBe('Get started with the CI/CD Catalog');
      expect(emptyState.props().description).toBe(
        'Create a pipeline component repository and make reusing pipeline configurations faster and easier.',
      );
    });
  });

  describe('when there is a search query', () => {
    beforeEach(() => {
      createComponent({
        props: { searchTerm: 'a' },
      });
    });

    it('renders the search description', () => {
      expect(findEmptyState().text()).toContain(
        'Edit your search and try again. Or learn to create a component repository.',
      );
    });

    it('renders the link to the components documentation', () => {
      const docsLink = findComponentsDocLink();
      expect(docsLink.exists()).toBe(true);
      expect(docsLink.attributes().href).toBe(COMPONENTS_DOCS_URL);
    });

    describe('and it is less than 3 characters', () => {
      beforeEach(() => {
        createComponent({
          props: { searchTerm: 'a' },
        });
      });

      it('render the too few chars empty state title', () => {
        expect(findEmptyState().props().title).toBe('Search must be at least 3 characters');
      });
    });

    describe('and it has more than 3 characters', () => {
      beforeEach(() => {
        createComponent({
          props: { searchTerm: 'my component' },
        });
      });

      it('renders the search empty state title', () => {
        expect(findEmptyState().props().title).toBe('No result found');
      });
    });
  });
});

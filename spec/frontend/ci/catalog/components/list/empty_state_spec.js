import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EmptyState from '~/ci/catalog/components/list/empty_state.vue';
import { COMPONENTS_DOCS_URL } from '~/ci/catalog/constants';

describe('EmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findComponentsDocLink = () => wrapper.findComponent(GlLink);
  const findDescription = () => wrapper.findComponent(GlSprintf);

  const createComponent = ({ props = {}, stubGlSprintf = false } = {}) => {
    wrapper = shallowMountExtended(EmptyState, {
      propsData: {
        ...props,
      },
      stubs: {
        GlEmptyState,
        GlSprintf: stubGlSprintf ? GlSprintf : true,
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
      expect(emptyState.props().svgPath).toBe('file-mock');
    });
  });

  describe('when there is a search query', () => {
    beforeEach(() => {
      createComponent({
        props: { searchTerm: 'a' },
      });
    });

    describe('and it is less than 3 characters', () => {
      beforeEach(() => {
        createComponent({
          props: { searchTerm: 'a' },
        });
      });

      it('render the too few chars empty state title', () => {
        expect(findEmptyState().props().title).toBe('Search incomplete');
      });

      it('renders the too small search description', () => {
        expect(findDescription().attributes().message).toContain(
          'Search keyword must have at least 3 characters',
        );
      });
    });

    describe('and it has more than 3 characters', () => {
      beforeEach(() => {
        createComponent({
          props: { searchTerm: 'my component' },
        });
      });

      it('renders the search empty state title and description', () => {
        expect(findEmptyState().props().title).toBe('No components match your search criteria');
      });

      it('renders the search empty description', () => {
        expect(findDescription().attributes().message).toContain(
          'Edit your search and try again, or %{linkStart}learn how to create a component project%{linkEnd}.',
        );
      });

      it('renders the link to the components documentation', () => {
        createComponent({
          props: { searchTerm: 'my component' },
          stubGlSprintf: true,
        });
        const docsLink = findComponentsDocLink();
        expect(docsLink.exists()).toBe(true);
        expect(docsLink.attributes().href).toBe(COMPONENTS_DOCS_URL);
      });
    });
  });
});

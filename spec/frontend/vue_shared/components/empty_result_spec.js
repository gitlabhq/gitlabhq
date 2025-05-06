import emptyStateSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg';
import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyResult from '~/vue_shared/components/empty_result.vue';

describe('Empty result', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(EmptyResult, {
      propsData: props,
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('when searchMinimumLength prop is not passed', () => {
    it('renders empty search state', () => {
      createComponent({ type: 'search' });

      expect(findEmptyState().props()).toMatchObject({
        svgPath: emptyStateSvgPath,
        title: 'No results found',
        description: 'Edit your search and try again.',
      });
    });

    it('renders empty filter state', () => {
      createComponent({ type: 'filter' });

      expect(findEmptyState().props()).toMatchObject({
        svgPath: emptyStateSvgPath,
        title: 'No results found',
        description: 'To widen your search, change or remove filters above.',
      });
    });
  });

  describe('when searchMinimumLength prop is passed', () => {
    describe('with search >= minimum search length', () => {
      beforeEach(() => {
        createComponent({ search: 'tes', searchMinimumLength: 3 });
      });

      it('renders empty state correctly', () => {
        expect(findEmptyState().props()).toMatchObject({
          title: 'No results found',
          description: 'Edit your search and try again.',
          svgPath: emptyStateSvgPath,
        });
      });
    });

    describe('with search < minimum search length', () => {
      beforeEach(() => {
        createComponent({ search: 'te', searchMinimumLength: 3 });
      });

      it('renders empty state correctly', () => {
        expect(findEmptyState().props()).toMatchObject({
          title: 'No results found',
          description: 'Search must be at least 3 characters.',
          svgPath: emptyStateSvgPath,
        });
      });
    });
  });
});

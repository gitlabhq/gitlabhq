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

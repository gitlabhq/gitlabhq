import { shallowMount } from '@vue/test-utils';
import IndexPage from '~/repository/pages/index.vue';
import TreePage from '~/repository/pages/tree.vue';
import { updateElementsVisibility } from '~/repository/utils/dom';

jest.mock('~/repository/utils/dom');

describe('Repository index page component', () => {
  let wrapper;

  function factory() {
    wrapper = shallowMount(IndexPage, {
      propsData: { refType: 'heads' },
    });
  }

  afterEach(() => {
    updateElementsVisibility.mockClear();
  });

  it('calls updateElementsVisibility on mounted', () => {
    factory();

    expect(updateElementsVisibility).toHaveBeenCalledWith('.js-show-on-project-root', true);
  });

  it('calls updateElementsVisibility after destroy', () => {
    factory();
    wrapper.destroy();

    expect(updateElementsVisibility.mock.calls.pop()).toEqual(['.js-show-on-project-root', false]);
  });

  it('renders TreePage', () => {
    factory();

    const child = wrapper.findComponent(TreePage);

    expect(child.exists()).toBe(true);
    expect(child.props()).toEqual({ path: '/', refType: 'heads' });
  });
});

import { shallowMount } from '@vue/test-utils';
import TreePage from '~/repository/pages/tree.vue';
import { updateElementsVisibility } from '~/repository/utils/dom';

jest.mock('~/repository/utils/dom');

describe('Repository tree page component', () => {
  let wrapper;

  function factory(path) {
    wrapper = shallowMount(TreePage, { propsData: { path } });
  }

  afterEach(() => {
    wrapper.destroy();

    updateElementsVisibility.mockClear();
  });

  describe('when root path', () => {
    beforeEach(() => {
      factory('/');
    });

    it('shows root elements', () => {
      expect(updateElementsVisibility.mock.calls).toEqual([
        ['.js-show-on-root', true],
        ['.js-hide-on-root', false],
      ]);
    });

    describe('when changed', () => {
      beforeEach(() => {
        updateElementsVisibility.mockClear();

        wrapper.setProps({ path: '/test' });
      });

      it('hides root elements', () => {
        expect(updateElementsVisibility.mock.calls).toEqual([
          ['.js-show-on-root', false],
          ['.js-hide-on-root', true],
        ]);
      });
    });
  });

  describe('when non-root path', () => {
    beforeEach(() => {
      factory('/test');
    });

    it('hides root elements', () => {
      expect(updateElementsVisibility.mock.calls).toEqual([
        ['.js-show-on-root', false],
        ['.js-hide-on-root', true],
      ]);
    });
  });
});

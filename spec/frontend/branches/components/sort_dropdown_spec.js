import { GlSearchBoxByClick } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import SortDropdown from '~/branches/components/sort_dropdown.vue';
import * as urlUtils from '~/lib/utils/url_utility';

describe('Branches Sort Dropdown', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    return extendedWrapper(
      mount(SortDropdown, {
        provide: {
          mode: 'overview',
          projectBranchesFilteredPath: '/root/ci-cd-project-demo/-/branches?state=all',
          sortOptions: {
            name_asc: 'Name',
            updated_asc: 'Oldest updated',
            updated_desc: 'Last updated',
          },
          ...props,
        },
      }),
    );
  };

  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByClick);
  const findBranchesDropdown = () => wrapper.findByTestId('branches-dropdown');

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('When in overview mode', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should have a search box with a placeholder', () => {
      const searchBox = findSearchBox();

      expect(searchBox.exists()).toBe(true);
      expect(searchBox.find('input').attributes('placeholder')).toBe('Filter by branch name');
    });

    it('should not have a branches dropdown when in overview mode', () => {
      const branchesDropdown = findBranchesDropdown();

      expect(branchesDropdown.exists()).toBe(false);
    });
  });

  describe('when in All branches mode', () => {
    beforeEach(() => {
      wrapper = createWrapper({ mode: 'all' });
    });

    it('should have a search box with a placeholder', () => {
      const searchBox = findSearchBox();

      expect(searchBox.exists()).toBe(true);
      expect(searchBox.find('input').attributes('placeholder')).toBe('Filter by branch name');
    });

    it('should have a branches dropdown when in all branches mode', () => {
      const branchesDropdown = findBranchesDropdown();

      expect(branchesDropdown.exists()).toBe(true);
    });
  });

  describe('when submitting a search term', () => {
    beforeEach(() => {
      urlUtils.visitUrl = jest.fn();

      wrapper = createWrapper();
    });

    it('should call visitUrl', () => {
      const searchBox = findSearchBox();

      searchBox.vm.$emit('submit');

      expect(urlUtils.visitUrl).toHaveBeenCalledWith(
        '/root/ci-cd-project-demo/-/branches?state=all',
      );
    });
  });
});

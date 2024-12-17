import { GlSearchBoxByClick } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import SortDropdown from '~/branches/components/sort_dropdown.vue';
import * as urlUtils from '~/lib/utils/url_utility';

describe('Branches Sort Dropdown', () => {
  let wrapper;

  const createWrapper = (props = {}, state = 'all') => {
    return extendedWrapper(
      mount(SortDropdown, {
        provide: {
          mode: 'overview',
          projectBranchesFilteredPath: `/root/ci-cd-project-demo/-/branches?state=${state}`,
          sortOptions: {
            name_asc: 'Name',
            updated_asc: 'Oldest updated',
            updated_desc: 'Last updated',
          },
          showDropdown: false,
          sortedBy: 'updated_desc',
          ...props,
        },
      }),
    );
  };

  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByClick);
  const findBranchesDropdown = () => wrapper.findByTestId('branches-dropdown');

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
      wrapper = createWrapper({ mode: 'all', showDropdown: true });
    });

    it('should have a search box with a placeholder', () => {
      const searchBox = findSearchBox();

      expect(searchBox.exists()).toBe(true);
      expect(searchBox.find('input').attributes('placeholder')).toBe('Filter by branch name');
    });

    it('should have a branches dropdown', () => {
      const branchesDropdown = findBranchesDropdown();

      expect(branchesDropdown.exists()).toBe(true);
    });
  });

  describe('when url contains a search param', () => {
    const branchName = 'branch-1';

    beforeEach(() => {
      setWindowLocation(`/root/ci-cd-project-demo/-/branches?search=${branchName}`);
      wrapper = createWrapper();
    });

    it('should set the default the input value to search param', () => {
      expect(findSearchBox().props('value')).toBe(branchName);
    });
  });

  describe('when submitting a search term', () => {
    beforeEach(() => {
      urlUtils.visitUrl = jest.fn();
      wrapper = createWrapper();
    });

    it('should call visitUrl', () => {
      const searchTerm = 'branch-1';
      const searchBox = findSearchBox();
      searchBox.vm.$emit('input', searchTerm);
      searchBox.vm.$emit('submit');

      expect(urlUtils.visitUrl).toHaveBeenCalledWith(
        '/root/ci-cd-project-demo/-/branches?state=all&sort=updated_desc&search=branch-1',
      );
    });
  });

  describe('when state is not "all" and search term is submitted', () => {
    beforeEach(() => {
      urlUtils.visitUrl = jest.fn();
      wrapper = createWrapper({}, 'active');
    });

    it('should call visitUrl with state=all', () => {
      const searchTerm = 'branch-1';
      const searchBox = findSearchBox();
      searchBox.vm.$emit('input', searchTerm);
      searchBox.vm.$emit('submit');

      expect(urlUtils.visitUrl).toHaveBeenCalledWith(
        '/root/ci-cd-project-demo/-/branches?state=all&sort=updated_desc&search=branch-1',
      );
    });
  });
});

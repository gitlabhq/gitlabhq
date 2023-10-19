import { GlListboxItem, GlSearchBoxByClick } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import * as urlUtils from '~/lib/utils/url_utility';
import SortDropdown from '~/tags/components/sort_dropdown.vue';
import setWindowLocation from 'helpers/set_window_location_helper';

describe('Tags sort dropdown', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    return extendedWrapper(
      mount(SortDropdown, {
        provide: {
          filterTagsPath: '/root/ci-cd-project-demo/-/tags',
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
  const findTagsDropdown = () => wrapper.findByTestId('tags-dropdown');

  describe('default state', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should have a search box with a placeholder', () => {
      const searchBox = findSearchBox();

      expect(searchBox.exists()).toBe(true);
      expect(searchBox.find('input').attributes('placeholder')).toBe('Filter by tag name');
    });

    it('should have a sort order dropdown', () => {
      const tagsDropdown = findTagsDropdown();

      expect(tagsDropdown.exists()).toBe(true);
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
        '/root/ci-cd-project-demo/-/tags?search=branch-1&sort=updated_desc',
      );
    });

    it('should send a sort parameter', () => {
      const sortDropdownItem = findTagsDropdown().findAllComponents(GlListboxItem).at(0);

      sortDropdownItem.trigger('click');

      expect(urlUtils.visitUrl).toHaveBeenCalledWith(
        '/root/ci-cd-project-demo/-/tags?sort=name_asc',
      );
    });
  });
});

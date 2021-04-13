import { GlDropdownItem, GlSearchBoxByClick } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import * as urlUtils from '~/lib/utils/url_utility';
import SortDropdown from '~/tags/components/sort_dropdown.vue';

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

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

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
      const branchesDropdown = findTagsDropdown();

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
        '/root/ci-cd-project-demo/-/tags?sort=updated_desc',
      );
    });

    it('should send a sort parameter', () => {
      const sortDropdownItems = findTagsDropdown().findAllComponents(GlDropdownItem).at(0);

      sortDropdownItems.vm.$emit('click');

      expect(urlUtils.visitUrl).toHaveBeenCalledWith(
        '/root/ci-cd-project-demo/-/tags?sort=name_asc',
      );
    });
  });
});

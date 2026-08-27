import { GlSearchBoxByClick, GlSorting } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { SORT_OPTION_NAME, SORT_OPTION_UPDATED, SORT_OPTION_VERSION } from '~/tags/constants';

import { visitUrl } from '~/lib/utils/url_utility';
import SortDropdown from '~/tags/components/sort_dropdown.vue';
import setWindowLocation from 'helpers/set_window_location_helper';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('SortDropdown', () => {
  let wrapper;

  const defaultPath = '/root/ci-cd-project-demo/-/tags';

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(SortDropdown, {
      provide: { filterTagsPath: defaultPath },
      ...props,
    });
  };

  beforeEach(() => {
    setWindowLocation(defaultPath);
    createComponent();
  });

  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByClick);
  const findSorting = () => wrapper.findComponent(GlSorting);

  describe('default rendering', () => {
    it('renders a search box with correct placeholder', () => {
      expect(findSearchBox().props('placeholder')).toBe('Filter by tag name');
    });

    it('renders a sorting component with SORT_OPTIONS', () => {
      const SORT_OPTIONS = [
        { value: SORT_OPTION_NAME, text: 'Name' },
        { value: SORT_OPTION_UPDATED, text: 'Updated date' },
        { value: SORT_OPTION_VERSION, text: 'Version' },
      ];
      expect(findSorting().props('sortOptions')).toEqual(SORT_OPTIONS);
    });

    it('has default sortBy=updated and order=desc', () => {
      expect(findSorting().props('sortBy')).toBe('updated');
      expect(findSorting().props('isAscending')).toBe(false);
    });
  });

  describe('when URL contains query parameters', () => {
    it.each([
      ['name_asc', 'name', true],
      ['name_desc', 'name', false],
      ['updated_asc', 'updated', true],
      ['updated_desc', 'updated', false],
      ['version_asc', 'version', true],
      ['version_desc', 'version', false],
    ])(
      'initializes state from URL params with sort=%s',
      (sortParam, expectedOption, expectedAscending) => {
        setWindowLocation(`${defaultPath}?search=release&sort=${sortParam}`);
        createComponent();

        expect(findSearchBox().props('value')).toBe('release');
        expect(findSorting().props('sortBy')).toBe(expectedOption);
        expect(findSorting().props('isAscending')).toBe(expectedAscending);
      },
    );
  });

  describe('on search submit', () => {
    it('navigates with search, sort, and order params', async () => {
      await findSearchBox().vm.$emit('input', 'frontend');
      await findSearchBox().vm.$emit('submit');

      expect(visitUrl).toHaveBeenCalledWith(`${defaultPath}?sort=updated_desc&search=frontend`);
    });
  });

  describe('on sort changes', () => {
    it('calls visitUrl when sortBy changes', async () => {
      await findSorting().vm.$emit('sort-by-change', 'version');

      expect(visitUrl).toHaveBeenCalledWith(`${defaultPath}?sort=version_desc`);
    });
  });

  describe('when sortDirection changes', () => {
    it('calls visitUrl when sort direction changes', async () => {
      await findSorting().vm.$emit('sort-direction-change', true); // ascending

      expect(visitUrl).toHaveBeenCalledWith(`${defaultPath}?sort=updated_asc`);
    });
  });

  describe('when search term is empty', () => {
    it('omits search parameter in URL', async () => {
      await findSearchBox().vm.$emit('input', '');
      wrapper.vm.visitUrlFromOption();

      expect(visitUrl).toHaveBeenCalledWith(`${defaultPath}?sort=updated_desc`);
    });
  });
});

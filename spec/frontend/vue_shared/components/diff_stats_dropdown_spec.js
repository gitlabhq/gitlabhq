import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlSprintf,
  GlSearchBoxByType,
  GlIcon,
} from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import DiffStatsDropdown, { i18n } from '~/vue_shared/components/diff_stats_dropdown.vue';
import { ARROW_DOWN_KEY } from '~/lib/utils/keys';

jest.mock('fuzzaldrin-plus', () => ({
  filter: jest.fn().mockReturnValue([]),
}));

const mockFiles = [
  {
    added: 0,
    href: '#a5cc2925ca8258af241be7e5b0381edf30266302',
    icon: 'file-modified',
    iconColor: '',
    name: '',
    path: '.gitignore',
    removed: 3,
    title: '.gitignore',
  },
  {
    added: 1,
    href: '#fa288d1472d29beccb489a676f68739ad365fc47',
    icon: 'file-modified',
    iconColor: 'danger',
    name: 'package-lock.json',
    path: 'lock/file/path',
    removed: 1,
  },
];

describe('Diff Stats Dropdown', () => {
  let wrapper;
  const focusInputMock = jest.fn();

  const createComponent = ({ changed = 0, added = 0, deleted = 0, files = [] } = {}) => {
    wrapper = mountExtended(DiffStatsDropdown, {
      propsData: {
        changed,
        added,
        deleted,
        files,
      },
      stubs: {
        GlSprintf,
        GlSearchBoxByType: stubComponent(GlSearchBoxByType, {
          methods: { focusInput: focusInputMock },
        }),
      },
    });
  };

  const findChanged = () => wrapper.findComponent(GlDisclosureDropdown);
  const findChangedFiles = () => findChanged().findAllComponents(GlDisclosureDropdownItem);
  const findCollapsed = () => wrapper.findByTestId('diff-stats-additions-deletions-expanded');
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  describe('file item', () => {
    beforeEach(() => {
      createComponent({ files: mockFiles });
    });

    it('when no file name provided', () => {
      expect(findChangedFiles().at(0).text()).toContain(i18n.noFileNameAvailable);
    });

    it('when all file data is available', () => {
      const fileData = findChangedFiles().at(1);
      const fileText = findChangedFiles().at(1).text();
      expect(fileText).toContain(mockFiles[1].name);
      expect(fileText).toContain(mockFiles[1].path);
      expect(fileData.findComponent(GlIcon).props('name')).toEqual(mockFiles[1].icon);
      expect(fileData.findComponent(GlIcon).classes()).toContain('gl-text-danger');
      expect(fileData.find('a').attributes('href')).toEqual(mockFiles[1].href);
    });

    it('when no files changed', () => {
      createComponent({ files: [] });
      expect(findChanged().text()).toContain(i18n.noFilesFound);
    });
  });

  describe.each`
    changed | added | deleted | expectedDropdownHeader | expectedAddedDeletedCollapsed
    ${0}    | ${0}  | ${0}    | ${'0 changed files'}   | ${'with 0 additions and 0 deletions'}
    ${2}    | ${0}  | ${2}    | ${'2 changed files'}   | ${'with 0 additions and 2 deletions'}
    ${2}    | ${2}  | ${0}    | ${'2 changed files'}   | ${'with 2 additions and 0 deletions'}
    ${2}    | ${1}  | ${1}    | ${'2 changed files'}   | ${'with 1 addition and 1 deletion'}
    ${1}    | ${0}  | ${1}    | ${'1 changed file'}    | ${'with 0 additions and 1 deletion'}
    ${1}    | ${1}  | ${0}    | ${'1 changed file'}    | ${'with 1 addition and 0 deletions'}
    ${4}    | ${2}  | ${2}    | ${'4 changed files'}   | ${'with 2 additions and 2 deletions'}
  `(
    'when there are $changed changed file(s), $added added and $deleted deleted file(s)',
    ({ changed, added, deleted, expectedDropdownHeader, expectedAddedDeletedCollapsed }) => {
      beforeEach(() => {
        createComponent({ changed, added, deleted });
      });

      it(`dropdown header should be '${expectedDropdownHeader}'`, () => {
        expect(findChanged().props('toggleText')).toBe(expectedDropdownHeader);
      });

      it(`added and deleted count in collapsed section should be '${expectedAddedDeletedCollapsed}'`, () => {
        expect(findCollapsed().text()).toBe(expectedAddedDeletedCollapsed);
      });
    },
  );

  describe('fuzzy file search', () => {
    beforeEach(() => {
      createComponent({ files: mockFiles });
    });

    it('should call `fuzzaldrinPlus.filter` to search for files when the search query is NOT empty', async () => {
      const searchStr = 'file name';
      findSearchBox().vm.$emit('input', searchStr);
      await nextTick();
      expect(fuzzaldrinPlus.filter).toHaveBeenCalledWith(mockFiles, searchStr, { key: 'name' });
    });

    it('should NOT call `fuzzaldrinPlus.filter` to search for files when the search query is empty', async () => {
      const searchStr = '';
      findSearchBox().vm.$emit('input', searchStr);
      await nextTick();
      expect(fuzzaldrinPlus.filter).not.toHaveBeenCalled();
    });
  });

  describe('on dropdown open', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should set the search input focus', () => {
      findChanged().vm.$emit('shown');
      expect(focusInputMock).toHaveBeenCalled();
    });
  });

  describe('keyboard nav', () => {
    beforeEach(() => {
      createComponent({ files: mockFiles });
    });

    it('focuses the first item when pressing the down key within the search box', () => {
      const { element } = wrapper.find('.gl-new-dropdown-item');
      const spy = jest.spyOn(element, 'focus');
      findSearchBox().vm.$emit('keydown', new KeyboardEvent({ key: ARROW_DOWN_KEY }));

      expect(spy).toHaveBeenCalled();
    });
  });
});

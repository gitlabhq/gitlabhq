import { GlLoadingIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import VirtualList from 'vue-virtual-scroll-list';
import { Mousetrap } from '~/lib/mousetrap';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { file } from 'jest/ide/helpers';
import FindFileComponent from '~/vue_shared/components/file_finder/index.vue';
import FileFinderItem from '~/vue_shared/components/file_finder/item.vue';
import { setHTMLFixture } from 'helpers/fixtures';

describe('File finder item spec', () => {
  let wrapper;

  const TEST_FILES = [
    {
      ...file('index.js'),
      path: 'index.js',
      type: 'blob',
      url: '/index.jsurl',
    },
    {
      ...file('component.js'),
      path: 'component.js',
      type: 'blob',
    },
  ];

  function createComponent(props) {
    wrapper = mountExtended(FindFileComponent, {
      attachTo: document.body,
      propsData: {
        files: TEST_FILES,
        visible: true,
        loading: false,
        ...props,
      },
    });
  }

  const findAllFileFinderItems = () => wrapper.findAllComponents(FileFinderItem);
  const findSearchInput = () => wrapper.findByTestId('search-input');
  const enterSearchText = (text) => findSearchInput().setValue(text);
  const clearSearch = () => wrapper.findByTestId('clear-search-input').vm.$emit('click');

  describe('with entries', () => {
    beforeEach(() => {
      createComponent({
        files: TEST_FILES,
      });

      return nextTick();
    });

    it('renders list of blobs', () => {
      expect(wrapper.text()).toContain('index.js');
      expect(wrapper.text()).toContain('component.js');
      expect(wrapper.text()).not.toContain('folder');
    });

    it('filters entries', async () => {
      await enterSearchText('index');

      expect(wrapper.text()).toContain('index.js');
      expect(wrapper.text()).not.toContain('component.js');
    });

    it('shows clear button when searchText is not empty', async () => {
      await enterSearchText('index');

      expect(wrapper.find('.dropdown-input').classes()).toContain('has-value');
      expect(wrapper.find('.dropdown-input-search').classes()).toContain('hidden');
    });

    it('clear button resets searchText', async () => {
      await enterSearchText('index');
      expect(findSearchInput().element.value).toBe('index');

      await clearSearch();

      expect(findSearchInput().element.value).toBe('');
    });

    it('clear button focuses search input', async () => {
      expect(findSearchInput().element).not.toBe(document.activeElement);

      await enterSearchText('index');
      await clearSearch();

      expect(findSearchInput().element).toBe(document.activeElement);
    });

    describe('listShowCount', () => {
      it('returns 1 when no filtered entries exist', async () => {
        await enterSearchText('testing 123');

        expect(wrapper.findComponent(VirtualList).props('remain')).toBe(1);
      });

      it('returns entries length when not filtered', () => {
        expect(wrapper.findComponent(VirtualList).props('remain')).toBe(2);
      });
    });

    describe('filtering', () => {
      it('renders only items that match the filter', async () => {
        await enterSearchText('index');

        expect(findAllFileFinderItems()).toHaveLength(1);
      });
    });

    describe('DOM Performance', () => {
      it('renders less DOM nodes if not visible by utilizing v-if', async () => {
        createComponent({ visible: false });

        await nextTick();

        expect(wrapper.findByTestId('overlay').exists()).toBe(false);
      });
    });

    describe('watches', () => {
      describe('searchText', () => {
        it('resets focusedIndex when updated', async () => {
          await enterSearchText('index');
          await nextTick();

          expect(findAllFileFinderItems().at(0).props('focused')).toBe(true);
        });
      });

      describe('visible', () => {
        it('resets searchText when changed to false', async () => {
          await enterSearchText('test');
          await wrapper.setProps({ visible: false });
          // need to set it back to true, so the component's content renders
          await wrapper.setProps({ visible: true });

          expect(findSearchInput().element.value).toBe('');
        });
      });
    });

    describe('openFile', () => {
      it('closes file finder', () => {
        expect(wrapper.emitted('toggle')).toBeUndefined();

        findSearchInput().trigger('keyup.enter');

        expect(wrapper.emitted('toggle')).toHaveLength(1);
      });

      it('pushes to router', () => {
        expect(wrapper.emitted('click')).toBeUndefined();

        findSearchInput().trigger('keyup.enter');

        expect(wrapper.emitted('click')).toHaveLength(1);
      });
    });

    describe('onKeyup', () => {
      it('opens file on enter key', async () => {
        expect(wrapper.emitted('click')).toBeUndefined();

        await findSearchInput().trigger('keyup.enter');

        expect(wrapper.emitted('click')[0][0]).toBe(TEST_FILES[0]);
      });

      it('closes file finder on esc key', async () => {
        expect(wrapper.emitted('toggle')).toBeUndefined();

        await findSearchInput().trigger('keyup.esc');

        expect(wrapper.emitted('toggle')[0][0]).toBe(false);
      });
    });

    describe('onKeyDown', () => {
      describe('up key', () => {
        it('resets to last index when at top', async () => {
          expect(findAllFileFinderItems().at(0).props('focused')).toBe(true);

          await findSearchInput().trigger('keydown.up');

          expect(findAllFileFinderItems().at(-1).props('focused')).toBe(true);
        });

        it('minus 1 from focusedIndex', async () => {
          await findSearchInput().trigger('keydown.up');
          await findSearchInput().trigger('keydown.up');

          expect(findAllFileFinderItems().at(0).props('focused')).toBe(true);
        });
      });

      describe('down key', () => {
        it('resets to first index when at bottom', async () => {
          await findSearchInput().trigger('keydown.down');
          expect(findAllFileFinderItems().at(-1).props('focused')).toBe(true);

          await findSearchInput().trigger('keydown.down');
          expect(findAllFileFinderItems().at(0).props('focused')).toBe(true);
        });

        it('adds 1 to focusedIndex', async () => {
          expect(findAllFileFinderItems().at(0).props('focused')).toBe(true);

          await findSearchInput().trigger('keydown.down');

          expect(findAllFileFinderItems().at(1).props('focused')).toBe(true);
        });
      });
    });
  });

  describe('without entries', () => {
    it('renders loading text when loading', () => {
      createComponent({ loading: true, files: [] });

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('renders no files text', () => {
      createComponent({ files: [] });

      expect(wrapper.text()).toContain('No files found.');
    });
  });

  describe('keyboard shortcuts', () => {
    beforeEach(async () => {
      createComponent();
      await nextTick();
    });

    it('calls toggle on `t` key press', () => {
      expect(wrapper.emitted('toggle')).toBeUndefined();

      Mousetrap.trigger('t');

      expect(wrapper.emitted('toggle')).not.toBeUndefined();
    });

    it('calls toggle on `mod+p` key press', () => {
      expect(wrapper.emitted('toggle')).toBeUndefined();

      Mousetrap.trigger('mod+p');

      expect(wrapper.emitted('toggle')).not.toBeUndefined();
    });

    it('always allows `mod+p` to trigger toggle', () => {
      expect(
        Mousetrap.prototype.stopCallback(
          null,
          wrapper.find('.dropdown-input-field').element,
          'mod+p',
        ),
      ).toBe(false);
    });

    it('onlys handles `t` when focused in input-field', () => {
      expect(
        Mousetrap.prototype.stopCallback(null, wrapper.find('.dropdown-input-field').element, 't'),
      ).toBe(true);
    });

    it('stops callback in monaco editor', () => {
      setHTMLFixture('<div class="inputarea"></div>');

      expect(
        Mousetrap.prototype.stopCallback(null, document.querySelector('.inputarea'), 't'),
      ).toBe(true);
    });
  });
});

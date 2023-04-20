import Mousetrap from 'mousetrap';
import Vue, { nextTick } from 'vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { file } from 'jest/ide/helpers';
import { UP_KEY_CODE, DOWN_KEY_CODE, ENTER_KEY_CODE, ESC_KEY_CODE } from '~/lib/utils/keycodes';
import FindFileComponent from '~/vue_shared/components/file_finder/index.vue';

describe('File finder item spec', () => {
  const Component = Vue.extend(FindFileComponent);
  let vm;

  function createComponent(props) {
    vm = new Component({
      propsData: {
        files: [],
        visible: true,
        loading: false,
        ...props,
      },
    });

    vm.$mount('#app');
  }

  beforeEach(() => {
    setHTMLFixture('<div id="app"></div>');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('with entries', () => {
    beforeEach(() => {
      createComponent({
        files: [
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
        ],
      });

      return nextTick();
    });

    it('renders list of blobs', () => {
      expect(vm.$el.textContent).toContain('index.js');
      expect(vm.$el.textContent).toContain('component.js');
      expect(vm.$el.textContent).not.toContain('folder');
    });

    it('filters entries', async () => {
      vm.searchText = 'index';

      await nextTick();

      expect(vm.$el.textContent).toContain('index.js');
      expect(vm.$el.textContent).not.toContain('component.js');
    });

    it('shows clear button when searchText is not empty', async () => {
      vm.searchText = 'index';

      await nextTick();

      expect(vm.$el.querySelector('.dropdown-input').classList).toContain('has-value');
      expect(vm.$el.querySelector('.dropdown-input-search').classList).toContain('hidden');
    });

    it('clear button resets searchText', () => {
      vm.searchText = 'index';

      vm.clearSearchInput();

      expect(vm.searchText).toBe('');
    });

    it('clear button focuses search input', async () => {
      jest.spyOn(vm.$refs.searchInput, 'focus').mockImplementation(() => {});
      vm.searchText = 'index';

      vm.clearSearchInput();

      await nextTick();

      expect(vm.$refs.searchInput.focus).toHaveBeenCalled();
    });

    describe('listShowCount', () => {
      it('returns 1 when no filtered entries exist', () => {
        vm.searchText = 'testing 123';

        expect(vm.listShowCount).toBe(1);
      });

      it('returns entries length when not filtered', () => {
        expect(vm.listShowCount).toBe(2);
      });
    });

    describe('filteredBlobsLength', () => {
      it('returns length of filtered blobs', () => {
        vm.searchText = 'index';

        expect(vm.filteredBlobsLength).toBe(1);
      });
    });

    describe('DOM Performance', () => {
      it('renders less DOM nodes if not visible by utilizing v-if', async () => {
        vm.visible = false;

        await nextTick();

        expect(vm.$el).toBeInstanceOf(Comment);
      });
    });

    describe('watches', () => {
      describe('searchText', () => {
        it('resets focusedIndex when updated', async () => {
          vm.focusedIndex = 1;
          vm.searchText = 'test';

          await nextTick();

          expect(vm.focusedIndex).toBe(0);
        });
      });

      describe('visible', () => {
        it('resets searchText when changed to false', async () => {
          vm.searchText = 'test';
          vm.visible = false;

          await nextTick();

          expect(vm.searchText).toBe('');
        });
      });
    });

    describe('openFile', () => {
      beforeEach(() => {
        jest.spyOn(vm, '$emit').mockImplementation(() => {});
      });

      it('closes file finder', () => {
        vm.openFile(vm.files[0]);

        expect(vm.$emit).toHaveBeenCalledWith('toggle', false);
      });

      it('pushes to router', () => {
        vm.openFile(vm.files[0]);

        expect(vm.$emit).toHaveBeenCalledWith('click', vm.files[0]);
      });
    });

    describe('onKeyup', () => {
      it('opens file on enter key', async () => {
        const event = new CustomEvent('keyup');
        event.keyCode = ENTER_KEY_CODE;

        jest.spyOn(vm, 'openFile').mockImplementation(() => {});

        vm.$refs.searchInput.dispatchEvent(event);

        await nextTick();

        expect(vm.openFile).toHaveBeenCalledWith(vm.files[0]);
      });

      it('closes file finder on esc key', async () => {
        const event = new CustomEvent('keyup');
        event.keyCode = ESC_KEY_CODE;

        jest.spyOn(vm, '$emit').mockImplementation(() => {});

        vm.$refs.searchInput.dispatchEvent(event);

        await nextTick();

        expect(vm.$emit).toHaveBeenCalledWith('toggle', false);
      });
    });

    describe('onKeyDown', () => {
      let el;

      beforeEach(() => {
        el = vm.$refs.searchInput;
      });

      describe('up key', () => {
        const event = new CustomEvent('keydown');
        event.keyCode = UP_KEY_CODE;

        it('resets to last index when at top', () => {
          el.dispatchEvent(event);

          expect(vm.focusedIndex).toBe(1);
        });

        it('minus 1 from focusedIndex', () => {
          vm.focusedIndex = 1;

          el.dispatchEvent(event);

          expect(vm.focusedIndex).toBe(0);
        });
      });

      describe('down key', () => {
        const event = new CustomEvent('keydown');
        event.keyCode = DOWN_KEY_CODE;

        it('resets to first index when at bottom', () => {
          vm.focusedIndex = 1;
          el.dispatchEvent(event);

          expect(vm.focusedIndex).toBe(0);
        });

        it('adds 1 to focusedIndex', () => {
          el.dispatchEvent(event);

          expect(vm.focusedIndex).toBe(1);
        });
      });
    });
  });

  describe('without entries', () => {
    it('renders loading text when loading', () => {
      createComponent({ loading: true });

      expect(vm.$el.querySelector('.gl-spinner')).not.toBe(null);
    });

    it('renders no files text', () => {
      createComponent();

      expect(vm.$el.textContent).toContain('No files found.');
    });
  });

  describe('keyboard shortcuts', () => {
    beforeEach(async () => {
      createComponent();

      jest.spyOn(vm, 'toggle').mockImplementation(() => {});

      await nextTick();
    });

    it('calls toggle on `t` key press', async () => {
      Mousetrap.trigger('t');

      await nextTick();
      expect(vm.toggle).toHaveBeenCalled();
    });

    it('calls toggle on `mod+p` key press', async () => {
      Mousetrap.trigger('mod+p');

      await nextTick();
      expect(vm.toggle).toHaveBeenCalled();
    });

    it('always allows `mod+p` to trigger toggle', () => {
      expect(
        Mousetrap.prototype.stopCallback(
          null,
          vm.$el.querySelector('.dropdown-input-field'),
          'mod+p',
        ),
      ).toBe(false);
    });

    it('onlys handles `t` when focused in input-field', () => {
      expect(
        Mousetrap.prototype.stopCallback(null, vm.$el.querySelector('.dropdown-input-field'), 't'),
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

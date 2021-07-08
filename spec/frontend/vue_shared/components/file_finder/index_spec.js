import Mousetrap from 'mousetrap';
import Vue from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
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
    setFixtures('<div id="app"></div>');
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('with entries', () => {
    beforeEach((done) => {
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

      setImmediate(done);
    });

    it('renders list of blobs', () => {
      expect(vm.$el.textContent).toContain('index.js');
      expect(vm.$el.textContent).toContain('component.js');
      expect(vm.$el.textContent).not.toContain('folder');
    });

    it('filters entries', (done) => {
      vm.searchText = 'index';

      setImmediate(() => {
        expect(vm.$el.textContent).toContain('index.js');
        expect(vm.$el.textContent).not.toContain('component.js');

        done();
      });
    });

    it('shows clear button when searchText is not empty', (done) => {
      vm.searchText = 'index';

      setImmediate(() => {
        expect(vm.$el.querySelector('.dropdown-input').classList).toContain('has-value');
        expect(vm.$el.querySelector('.dropdown-input-search').classList).toContain('hidden');

        done();
      });
    });

    it('clear button resets searchText', (done) => {
      vm.searchText = 'index';

      waitForPromises()
        .then(() => {
          vm.clearSearchInput();
        })
        .then(waitForPromises)
        .then(() => {
          expect(vm.searchText).toBe('');
        })
        .then(done)
        .catch(done.fail);
    });

    it('clear button focuses search input', (done) => {
      jest.spyOn(vm.$refs.searchInput, 'focus').mockImplementation(() => {});
      vm.searchText = 'index';

      waitForPromises()
        .then(() => {
          vm.clearSearchInput();
        })
        .then(waitForPromises)
        .then(() => {
          expect(vm.$refs.searchInput.focus).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    describe('listShowCount', () => {
      it('returns 1 when no filtered entries exist', (done) => {
        vm.searchText = 'testing 123';

        setImmediate(() => {
          expect(vm.listShowCount).toBe(1);

          done();
        });
      });

      it('returns entries length when not filtered', () => {
        expect(vm.listShowCount).toBe(2);
      });
    });

    describe('listHeight', () => {
      it('returns 55 when entries exist', () => {
        expect(vm.listHeight).toBe(55);
      });

      it('returns 33 when entries dont exist', (done) => {
        vm.searchText = 'testing 123';

        setImmediate(() => {
          expect(vm.listHeight).toBe(33);

          done();
        });
      });
    });

    describe('filteredBlobsLength', () => {
      it('returns length of filtered blobs', (done) => {
        vm.searchText = 'index';

        setImmediate(() => {
          expect(vm.filteredBlobsLength).toBe(1);

          done();
        });
      });
    });

    describe('DOM Performance', () => {
      it('renders less DOM nodes if not visible by utilizing v-if', async () => {
        vm.visible = false;

        await waitForPromises();

        expect(vm.$el).toBeInstanceOf(Comment);
      });
    });

    describe('watches', () => {
      describe('searchText', () => {
        it('resets focusedIndex when updated', (done) => {
          vm.focusedIndex = 1;
          vm.searchText = 'test';

          setImmediate(() => {
            expect(vm.focusedIndex).toBe(0);

            done();
          });
        });
      });

      describe('visible', () => {
        it('resets searchText when changed to false', (done) => {
          vm.searchText = 'test';
          vm.visible = true;

          waitForPromises()
            .then(() => {
              vm.visible = false;
            })
            .then(waitForPromises)
            .then(() => {
              expect(vm.searchText).toBe('');
            })
            .then(done)
            .catch(done.fail);
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
      it('opens file on enter key', (done) => {
        const event = new CustomEvent('keyup');
        event.keyCode = ENTER_KEY_CODE;

        jest.spyOn(vm, 'openFile').mockImplementation(() => {});

        vm.$refs.searchInput.dispatchEvent(event);

        setImmediate(() => {
          expect(vm.openFile).toHaveBeenCalledWith(vm.files[0]);

          done();
        });
      });

      it('closes file finder on esc key', (done) => {
        const event = new CustomEvent('keyup');
        event.keyCode = ESC_KEY_CODE;

        jest.spyOn(vm, '$emit').mockImplementation(() => {});

        vm.$refs.searchInput.dispatchEvent(event);

        setImmediate(() => {
          expect(vm.$emit).toHaveBeenCalledWith('toggle', false);

          done();
        });
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
      createComponent({
        loading: true,
      });

      expect(vm.$el.textContent).toContain('Loading...');
    });

    it('renders no files text', () => {
      createComponent();

      expect(vm.$el.textContent).toContain('No files found.');
    });
  });

  describe('keyboard shortcuts', () => {
    beforeEach((done) => {
      createComponent();

      jest.spyOn(vm, 'toggle').mockImplementation(() => {});

      vm.$nextTick(done);
    });

    it('calls toggle on `t` key press', (done) => {
      Mousetrap.trigger('t');

      vm.$nextTick()
        .then(() => {
          expect(vm.toggle).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls toggle on `mod+p` key press', (done) => {
      Mousetrap.trigger('mod+p');

      vm.$nextTick()
        .then(() => {
          expect(vm.toggle).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
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
      setFixtures('<div class="inputarea"></div>');

      expect(
        Mousetrap.prototype.stopCallback(null, document.querySelector('.inputarea'), 't'),
      ).toBe(true);
    });
  });
});

import Vue from 'vue';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import newDropdown from '~/ide/components/new_dropdown/index.vue';
import { createStore } from '~/ide/stores';

describe('new dropdown component', () => {
  let store;
  let vm;

  beforeEach(() => {
    store = createStore();

    const component = Vue.extend(newDropdown);

    vm = createComponentWithStore(component, store, {
      branch: 'main',
      path: '',
      mouseOver: false,
      type: 'tree',
    });

    vm.$store.state.currentProjectId = 'abcproject';
    vm.$store.state.path = '';
    vm.$store.state.trees['abcproject/mybranch'] = {
      tree: [],
    };

    vm.$mount();

    jest.spyOn(vm.$refs.newModal, 'open').mockImplementation(() => {});
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders new file, upload and new directory links', () => {
    const buttons = vm.$el.querySelectorAll('.dropdown-menu button');

    expect(buttons[0].textContent.trim()).toBe('New file');
    expect(buttons[1].textContent.trim()).toBe('Upload file');
    expect(buttons[2].textContent.trim()).toBe('New directory');
  });

  describe('createNewItem', () => {
    it('opens modal for a blob when new file is clicked', () => {
      vm.$el.querySelectorAll('.dropdown-menu button')[0].click();

      expect(vm.$refs.newModal.open).toHaveBeenCalledWith('blob', '');
    });

    it('opens modal for a tree when new directory is clicked', () => {
      vm.$el.querySelectorAll('.dropdown-menu button')[2].click();

      expect(vm.$refs.newModal.open).toHaveBeenCalledWith('tree', '');
    });
  });

  describe('isOpen', () => {
    it('scrolls dropdown into view', (done) => {
      jest.spyOn(vm.$refs.dropdownMenu, 'scrollIntoView').mockImplementation(() => {});

      vm.isOpen = true;

      setImmediate(() => {
        expect(vm.$refs.dropdownMenu.scrollIntoView).toHaveBeenCalledWith({
          block: 'nearest',
        });

        done();
      });
    });
  });

  describe('delete entry', () => {
    it('calls delete action', () => {
      jest.spyOn(vm, 'deleteEntry').mockImplementation(() => {});

      vm.$el.querySelectorAll('.dropdown-menu button')[4].click();

      expect(vm.deleteEntry).toHaveBeenCalledWith('');
    });
  });
});

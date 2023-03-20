import { mount } from '@vue/test-utils';
import NewDropdown from '~/ide/components/new_dropdown/index.vue';
import Button from '~/ide/components/new_dropdown/button.vue';
import { createStore } from '~/ide/stores';

describe('new dropdown component', () => {
  let wrapper;

  const findAllButtons = () => wrapper.findAllComponents(Button);

  const mountComponent = () => {
    const store = createStore();
    store.state.currentProjectId = 'abcproject';
    store.state.path = '';
    store.state.trees['abcproject/mybranch'] = { tree: [] };

    wrapper = mount(NewDropdown, {
      store,
      propsData: {
        branch: 'main',
        path: '',
        mouseOver: false,
        type: 'tree',
      },
    });
  };

  beforeEach(() => {
    mountComponent();
    jest.spyOn(wrapper.vm.$refs.newModal, 'open').mockImplementation(() => {});
  });

  it('renders new file, upload and new directory links', () => {
    expect(findAllButtons().at(0).text()).toBe('New file');
    expect(findAllButtons().at(1).text()).toBe('Upload file');
    expect(findAllButtons().at(2).text()).toBe('New directory');
  });

  describe('createNewItem', () => {
    it('opens modal for a blob when new file is clicked', () => {
      findAllButtons().at(0).trigger('click');

      expect(wrapper.vm.$refs.newModal.open).toHaveBeenCalledWith('blob', '');
    });

    it('opens modal for a tree when new directory is clicked', () => {
      findAllButtons().at(2).trigger('click');

      expect(wrapper.vm.$refs.newModal.open).toHaveBeenCalledWith('tree', '');
    });
  });

  describe('isOpen', () => {
    it('scrolls dropdown into view', async () => {
      jest.spyOn(wrapper.vm.$refs.dropdownMenu, 'scrollIntoView').mockImplementation(() => {});

      await wrapper.setProps({ isOpen: true });

      expect(wrapper.vm.$refs.dropdownMenu.scrollIntoView).toHaveBeenCalledWith({
        block: 'nearest',
      });
    });
  });

  describe('delete entry', () => {
    it('calls delete action', () => {
      jest.spyOn(wrapper.vm, 'deleteEntry').mockImplementation(() => {});

      findAllButtons().at(4).trigger('click');

      expect(wrapper.vm.deleteEntry).toHaveBeenCalledWith('');
    });
  });
});

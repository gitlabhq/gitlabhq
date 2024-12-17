import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { describeSkipVue3, SkipReason } from 'helpers/vue3_conditional';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import NewDropdown from '~/ide/components/new_dropdown/index.vue';
import Button from '~/ide/components/new_dropdown/button.vue';
import Modal from '~/ide/components/new_dropdown/modal.vue';
import { stubComponent } from 'helpers/stub_component';

Vue.use(Vuex);

const skipReason = new SkipReason({
  name: 'new dropdown component',
  reason: 'Legacy WebIDE is due for deletion',
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/508949',
});
describeSkipVue3(skipReason, () => {
  let wrapper;
  const openMock = jest.fn();
  const deleteEntryMock = jest.fn();

  const findAllButtons = () => wrapper.findAllComponents(Button);

  const mountComponent = (props = {}) => {
    const fakeStore = () => {
      return new Vuex.Store({
        actions: {
          deleteEntry: deleteEntryMock,
        },
      });
    };

    wrapper = mountExtended(NewDropdown, {
      store: fakeStore(),
      propsData: {
        branch: 'main',
        path: '',
        mouseOver: false,
        type: 'tree',
        ...props,
      },
      stubs: {
        NewModal: stubComponent(Modal, {
          methods: {
            open: openMock,
          },
        }),
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  it('renders new file, upload and new directory links', () => {
    expect(findAllButtons().at(0).text()).toBe('New file');
    expect(findAllButtons().at(1).text()).toBe('Upload file');
    expect(findAllButtons().at(2).text()).toBe('New directory');
  });

  describe('createNewItem', () => {
    it('opens modal for a blob when new file is clicked', () => {
      findAllButtons().at(0).vm.$emit('click');

      expect(openMock).toHaveBeenCalledWith('blob', '');
    });

    it('opens modal for a tree when new directory is clicked', () => {
      findAllButtons().at(2).vm.$emit('click');

      expect(openMock).toHaveBeenCalledWith('tree', '');
    });
  });

  describe('isOpen', () => {
    it('scrolls dropdown into view', async () => {
      const dropdownMenu = wrapper.findByTestId('dropdown-menu');
      const scrollIntoViewSpy = jest.spyOn(dropdownMenu.element, 'scrollIntoView');

      await wrapper.setProps({ isOpen: true });

      expect(scrollIntoViewSpy).toHaveBeenCalledWith({ block: 'nearest' });
    });
  });

  describe('delete entry', () => {
    it('calls delete action', () => {
      findAllButtons().at(4).trigger('click');

      expect(deleteEntryMock).toHaveBeenCalledWith(expect.anything(), '');
    });
  });
});

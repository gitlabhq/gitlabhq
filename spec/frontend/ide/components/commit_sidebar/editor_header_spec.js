import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import { createStore } from '~/ide/stores';
import EditorHeader from '~/ide/components/commit_sidebar/editor_header.vue';
import { file } from '../../helpers';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('IDE commit editor header', () => {
  let wrapper;
  let f;
  let store;

  const findDiscardModal = () => wrapper.find({ ref: 'discardModal' });
  const findDiscardButton = () => wrapper.find({ ref: 'discardButton' });

  beforeEach(() => {
    f = file('file');
    store = createStore();

    wrapper = mount(EditorHeader, {
      store,
      localVue,
      propsData: {
        activeFile: f,
      },
    });

    jest.spyOn(wrapper.vm, 'discardChanges').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders button to discard', () => {
    expect(wrapper.vm.$el.querySelectorAll('.btn')).toHaveLength(1);
  });

  describe('discard button', () => {
    let modal;

    beforeEach(() => {
      modal = findDiscardModal();

      jest.spyOn(modal.vm, 'show');

      findDiscardButton().trigger('click');
    });

    it('opens a dialog confirming discard', () => {
      expect(modal.vm.show).toHaveBeenCalled();
    });

    it('calls discardFileChanges if dialog result is confirmed', () => {
      modal.vm.$emit('ok');

      expect(wrapper.vm.discardChanges).toHaveBeenCalledWith(f.path);
    });
  });
});

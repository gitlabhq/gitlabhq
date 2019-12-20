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
  const findActionButton = () => wrapper.find({ ref: 'actionButton' });

  beforeEach(() => {
    f = file('file');
    store = createStore();

    wrapper = mount(EditorHeader, {
      store,
      localVue,
      sync: false,
      propsData: {
        activeFile: f,
      },
    });

    jest.spyOn(wrapper.vm, 'stageChange').mockImplementation();
    jest.spyOn(wrapper.vm, 'unstageChange').mockImplementation();
    jest.spyOn(wrapper.vm, 'discardFileChanges').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders button to discard & stage', () => {
    expect(wrapper.vm.$el.querySelectorAll('.btn').length).toBe(2);
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

      expect(wrapper.vm.discardFileChanges).toHaveBeenCalledWith(f.path);
    });
  });

  describe('stage/unstage button', () => {
    it('unstages the file if it was already staged', () => {
      f.staged = true;

      findActionButton().trigger('click');

      expect(wrapper.vm.unstageChange).toHaveBeenCalledWith(f.path);
    });

    it('stages the file if it was not staged', () => {
      findActionButton().trigger('click');

      expect(wrapper.vm.stageChange).toHaveBeenCalledWith(f.path);
    });
  });
});

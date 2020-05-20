import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import { createStore } from '~/ide/stores';
import EditorHeader from '~/ide/components/commit_sidebar/editor_header.vue';
import { file } from '../../helpers';

const localVue = createLocalVue();
localVue.use(Vuex);

const TEST_FILE_PATH = 'test/file/path';

describe('IDE commit editor header', () => {
  let wrapper;
  let store;

  const createComponent = (fileProps = {}) => {
    wrapper = mount(EditorHeader, {
      store,
      localVue,
      propsData: {
        activeFile: {
          ...file(TEST_FILE_PATH),
          staged: true,
          ...fileProps,
        },
      },
    });
  };

  const findDiscardModal = () => wrapper.find({ ref: 'discardModal' });
  const findDiscardButton = () => wrapper.find({ ref: 'discardButton' });

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it.each`
    fileProps                            | shouldExist
    ${{ staged: false, changed: false }} | ${false}
    ${{ staged: true, changed: false }}  | ${true}
    ${{ staged: false, changed: true }}  | ${true}
    ${{ staged: true, changed: true }}   | ${true}
  `('with $fileProps, show discard button is $shouldExist', ({ fileProps, shouldExist }) => {
    createComponent(fileProps);

    expect(findDiscardButton().exists()).toBe(shouldExist);
  });

  describe('discard button', () => {
    beforeEach(() => {
      createComponent();

      const modal = findDiscardModal();
      jest.spyOn(modal.vm, 'show');

      findDiscardButton().trigger('click');
    });

    it('opens a dialog confirming discard', () => {
      expect(findDiscardModal().vm.show).toHaveBeenCalled();
    });

    it('calls discardFileChanges if dialog result is confirmed', () => {
      expect(store.dispatch).not.toHaveBeenCalled();

      findDiscardModal().vm.$emit('ok');

      expect(store.dispatch).toHaveBeenCalledWith('discardFileChanges', TEST_FILE_PATH);
    });
  });
});

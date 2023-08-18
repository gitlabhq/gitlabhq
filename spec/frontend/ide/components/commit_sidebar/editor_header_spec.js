import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import EditorHeader from '~/ide/components/commit_sidebar/editor_header.vue';
import { stubComponent } from 'helpers/stub_component';
import { createStore } from '~/ide/stores';
import { file } from '../../helpers';

Vue.use(Vuex);

const TEST_FILE_PATH = 'test/file/path';

describe('IDE commit editor header', () => {
  let wrapper;
  let store;
  const showMock = jest.fn();

  const createComponent = (fileProps = {}) => {
    wrapper = shallowMount(EditorHeader, {
      store,
      propsData: {
        activeFile: {
          ...file(TEST_FILE_PATH),
          staged: true,
          ...fileProps,
        },
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: { show: showMock },
        }),
      },
    });
  };

  const findDiscardModal = () => wrapper.findComponent({ ref: 'discardModal' });
  const findDiscardButton = () => wrapper.findComponent({ ref: 'discardButton' });

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
    it('opens a dialog confirming discard', () => {
      createComponent();
      findDiscardButton().vm.$emit('click');

      expect(showMock).toHaveBeenCalled();
    });

    it('calls discardFileChanges if dialog result is confirmed', () => {
      store = createStore();
      jest.spyOn(store, 'dispatch').mockImplementation();

      createComponent();

      expect(store.dispatch).not.toHaveBeenCalled();

      findDiscardModal().vm.$emit('primary');

      expect(store.dispatch).toHaveBeenCalledWith('discardFileChanges', TEST_FILE_PATH);
    });
  });
});

import { GlLoadingIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LoadingIndicator from '~/content_editor/components/loading_indicator.vue';
import EditorStateObserver from '~/content_editor/components/editor_state_observer.vue';
import {
  LOADING_CONTENT_EVENT,
  LOADING_SUCCESS_EVENT,
  LOADING_ERROR_EVENT,
} from '~/content_editor/constants';

describe('content_editor/components/loading_indicator', () => {
  let wrapper;

  const findEditorStateObserver = () => wrapper.findComponent(EditorStateObserver);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createWrapper = () => {
    wrapper = shallowMountExtended(LoadingIndicator);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when loading content', () => {
    beforeEach(async () => {
      createWrapper();

      findEditorStateObserver().vm.$emit(LOADING_CONTENT_EVENT);

      await nextTick();
    });

    it('displays loading indicator', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when loading content succeeds', () => {
    beforeEach(async () => {
      createWrapper();

      findEditorStateObserver().vm.$emit(LOADING_CONTENT_EVENT);
      await nextTick();
      findEditorStateObserver().vm.$emit(LOADING_SUCCESS_EVENT);
      await nextTick();
    });

    it('hides loading indicator', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when loading content fails', () => {
    const error = 'error';

    beforeEach(async () => {
      createWrapper();

      findEditorStateObserver().vm.$emit(LOADING_CONTENT_EVENT);
      await nextTick();
      findEditorStateObserver().vm.$emit(LOADING_ERROR_EVENT, error);
      await nextTick();
    });

    it('hides loading indicator', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });
});

import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LoadingIndicator from '~/content_editor/components/loading_indicator.vue';

describe('content_editor/components/loading_indicator', () => {
  let wrapper;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createWrapper = () => {
    wrapper = shallowMountExtended(LoadingIndicator);
  };

  describe('when loading content', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays loading indicator', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });
});

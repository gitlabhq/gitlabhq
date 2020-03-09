import { shallowMount } from '@vue/test-utils';
import Popover from '~/blob/suggest_gitlab_ci_yml/components/popover.vue';
import Cookies from 'js-cookie';
import * as utils from '~/lib/utils/common_utils';

jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  scrollToElement: jest.fn(),
}));

const target = 'gitlab-ci-yml-selector';
const dismissKey = 'suggest_gitlab_ci_yml_99';
const defaultTrackLabel = 'suggest_gitlab_ci_yml';

describe('Suggest gitlab-ci.yml Popover', () => {
  let wrapper;

  function createWrapper(trackLabel) {
    wrapper = shallowMount(Popover, {
      propsData: {
        target,
        trackLabel,
        dismissKey,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when no dismiss cookie is set', () => {
    beforeEach(() => {
      createWrapper(defaultTrackLabel);
    });

    it('sets popoverDismissed to false', () => {
      expect(wrapper.vm.popoverDismissed).toEqual(false);
    });
  });

  describe('when the dismiss cookie is set', () => {
    beforeEach(() => {
      Cookies.set(dismissKey, true);
      createWrapper(defaultTrackLabel);
    });

    it('sets popoverDismissed to true', () => {
      expect(wrapper.vm.popoverDismissed).toEqual(true);
    });

    beforeEach(() => {
      Cookies.remove(dismissKey);
    });
  });

  describe('when the popover is mounted with the trackLabel of the Confirm button popover at the bottom of the page', () => {
    it('calls scrollToElement so that the Confirm button and popover will be in sight', () => {
      const scrollToElementSpy = jest.spyOn(utils, 'scrollToElement');
      const commitTrackLabel = 'suggest_commit_first_project_gitlab_ci_yml';

      createWrapper(commitTrackLabel);

      expect(scrollToElementSpy).toHaveBeenCalled();
    });
  });
});

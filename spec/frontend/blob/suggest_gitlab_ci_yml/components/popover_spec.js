import { shallowMount } from '@vue/test-utils';
import { mockTracking, unmockTracking, triggerEvent } from 'helpers/tracking_helper';
import { GlButton } from '@gitlab/ui';
import Popover from '~/blob/suggest_gitlab_ci_yml/components/popover.vue';
import * as utils from '~/lib/utils/common_utils';

jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  scrollToElement: jest.fn(),
}));

const target = 'gitlab-ci-yml-selector';
const dismissKey = '99';
const defaultTrackLabel = 'suggest_gitlab_ci_yml';
const commitTrackLabel = 'suggest_commit_first_project_gitlab_ci_yml';

const dismissCookie = 'suggest_gitlab_ci_yml_99';
const humanAccess = 'owner';
const mergeRequestPath = '/some/path';

describe('Suggest gitlab-ci.yml Popover', () => {
  let wrapper;

  function createWrapper(trackLabel) {
    wrapper = shallowMount(Popover, {
      propsData: {
        target,
        trackLabel,
        dismissKey,
        mergeRequestPath,
        humanAccess,
      },
      stubs: {
        'gl-popover': { template: '<div><slot name="title"></slot><slot></slot></div>' },
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
      utils.setCookie(dismissCookie, true);

      createWrapper(defaultTrackLabel);
    });

    it('sets popoverDismissed to true', () => {
      expect(wrapper.vm.popoverDismissed).toEqual(true);
    });

    afterEach(() => {
      utils.removeCookie(dismissCookie);
    });
  });

  describe('tracking', () => {
    let trackingSpy;

    beforeEach(() => {
      document.body.dataset.page = 'projects:blob:new';
      trackingSpy = mockTracking('_category_', undefined, jest.spyOn);

      createWrapper(commitTrackLabel);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('sends a tracking event with the expected properties for the popover being viewed', () => {
      const expectedCategory = undefined;
      const expectedAction = undefined;
      const expectedLabel = 'suggest_commit_first_project_gitlab_ci_yml';
      const expectedProperty = 'owner';

      expect(trackingSpy).toHaveBeenCalledWith(expectedCategory, expectedAction, {
        label: expectedLabel,
        property: expectedProperty,
      });
    });

    it('sends a tracking event when the popover is dismissed', () => {
      const expectedLabel = commitTrackLabel;
      const expectedAction = 'click_button';
      const expectedProperty = 'owner';
      const expectedValue = '10';
      const dismissButton = wrapper.find(GlButton);
      trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);

      triggerEvent(dismissButton.element);

      expect(trackingSpy).toHaveBeenCalledWith('_category_', expectedAction, {
        label: expectedLabel,
        property: expectedProperty,
        value: expectedValue,
      });
    });
  });

  describe('when the popover is mounted with the trackLabel of the Confirm button popover at the bottom of the page', () => {
    it('calls scrollToElement so that the Confirm button and popover will be in sight', () => {
      const scrollToElementSpy = jest.spyOn(utils, 'scrollToElement');

      createWrapper(commitTrackLabel);

      expect(scrollToElementSpy).toHaveBeenCalled();
    });
  });
});

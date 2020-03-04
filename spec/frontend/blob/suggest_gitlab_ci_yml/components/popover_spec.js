import { shallowMount } from '@vue/test-utils';
import Popover from '~/blob/suggest_gitlab_ci_yml/components/popover.vue';
import Cookies from 'js-cookie';

const popoverTarget = 'gitlab-ci-yml-selector';
const dismissKey = 'suggest_gitlab_ci_yml_99';

describe('Suggest gitlab-ci.yml Popover', () => {
  let wrapper;

  function createWrapper() {
    wrapper = shallowMount(Popover, {
      propsData: {
        target: popoverTarget,
        cssClass: 'js-class',
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
      createWrapper();
    });

    it('sets popoverDismissed to false', () => {
      expect(wrapper.vm.popoverDismissed).toEqual(false);
    });
  });

  describe('when the dismiss cookie is set', () => {
    beforeEach(() => {
      Cookies.set(dismissKey, true);
      createWrapper();
    });

    it('sets popoverDismissed to true', () => {
      expect(wrapper.vm.popoverDismissed).toEqual(true);
    });
  });
});

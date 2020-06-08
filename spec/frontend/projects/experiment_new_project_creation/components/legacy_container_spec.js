import { shallowMount } from '@vue/test-utils';
import LegacyContainer from '~/projects/experiment_new_project_creation/components/legacy_container.vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('Legacy container component', () => {
  let wrapper;
  let dummy;

  const createComponent = propsData => {
    wrapper = shallowMount(LegacyContainer, { propsData });
  };

  afterEach(() => {
    wrapper.destroy();
    resetHTMLFixture();
    wrapper = null;
  });

  describe('when selector targets real node', () => {
    beforeEach(() => {
      setHTMLFixture('<div class="dummy-target"></div>');
      dummy = document.querySelector('.dummy-target');
      createComponent({ selector: '.dummy-target' });
    });

    it('moves node inside component when mounted', () => {
      expect(dummy.parentNode).toBe(wrapper.element);
    });

    it('moves node back when unmounted', () => {
      wrapper.destroy();
      expect(dummy.parentNode).toBe(document.body);
    });
  });

  describe('when selector targets template node', () => {
    beforeEach(() => {
      setHTMLFixture('<template class="dummy-target">content</template>');
      dummy = document.querySelector('.dummy-target');
      createComponent({ selector: '.dummy-target' });
    });

    it('copies node content when mounted', () => {
      expect(dummy.innerHTML).toEqual(wrapper.element.innerHTML);
      expect(dummy.parentNode).toBe(document.body);
    });
  });
});

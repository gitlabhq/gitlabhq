import { shallowMount } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import LegacyContainer from '~/vue_shared/new_namespace/components/legacy_container.vue';

describe('Legacy container component', () => {
  let wrapper;
  let dummy;

  const createComponent = (propsData) => {
    wrapper = shallowMount(LegacyContainer, { propsData });
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when selector targets real node', () => {
    beforeEach(() => {
      setHTMLFixture('<div class="dummy-target"></div>');
      dummy = document.querySelector('.dummy-target');
      createComponent({ selector: '.dummy-target' });
    });

    describe('when mounted', () => {
      it('moves node inside component', () => {
        expect(dummy.parentNode).toBe(wrapper.element);
      });

      it('sets active class', () => {
        expect(dummy.classList.contains('active')).toBe(true);
      });
    });

    describe('when unmounted', () => {
      beforeEach(() => {
        wrapper.destroy();
      });

      it('moves node back', () => {
        expect(dummy.parentNode).toBe(document.body);
      });

      it('removes active class', () => {
        expect(dummy.classList.contains('active')).toBe(false);
      });
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

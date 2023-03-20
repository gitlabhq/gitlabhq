import Vue, { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { GlBanner } from '@gitlab/ui';
import App from '~/work_items_hierarchy/components/app.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

Vue.use(VueApollo);

describe('WorkItemsHierarchy App', () => {
  let wrapper;
  const createComponent = (props = {}, data = {}) => {
    wrapper = extendedWrapper(
      mount(App, {
        provide: {
          illustrationPath: '/foo.svg',
          licensePlan: 'free',
          ...props,
        },
        data() {
          return data;
        },
      }),
    );
  };

  describe('survey banner', () => {
    it('shows when the banner is visible', () => {
      createComponent({}, { bannerVisible: true });

      expect(wrapper.findComponent(GlBanner).exists()).toBe(true);
    });

    it('hide when close is called', async () => {
      createComponent({}, { bannerVisible: true });

      wrapper.findByTestId('close-icon').trigger('click');

      await nextTick();

      expect(wrapper.findComponent(GlBanner).exists()).toBe(false);
    });
  });

  describe('Unavailable structure', () => {
    it.each`
      licensePlan   | visible
      ${'free'}     | ${true}
      ${'premium'}  | ${true}
      ${'ultimate'} | ${false}
    `('visibility is $visible when plan is $licensePlan', ({ licensePlan, visible }) => {
      createComponent({ licensePlan });

      expect(wrapper.findByTestId('unavailable-structure').exists()).toBe(visible);
    });
  });
});

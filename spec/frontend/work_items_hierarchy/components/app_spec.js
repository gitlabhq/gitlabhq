import { nextTick } from 'vue';
import { createLocalVue, mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { GlBanner } from '@gitlab/ui';
import App from '~/work_items_hierarchy/components/app.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('WorkItemsHierarchy App', () => {
  let wrapper;
  const createComponent = (props = {}, data = {}) => {
    wrapper = extendedWrapper(
      mount(App, {
        localVue,
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

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    licensePlan
    ${'free'}
    ${'premium'}
    ${'ultimate'}
  `('when licensePlan is $licensePlan', ({ licensePlan }) => {
    beforeEach(() => {
      createComponent({ licensePlan });
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('survey banner', () => {
    it('shows when the banner is visible', () => {
      createComponent({}, { bannerVisible: true });

      expect(wrapper.find(GlBanner).exists()).toBe(true);
    });

    it('hide when close is called', async () => {
      createComponent({}, { bannerVisible: true });

      wrapper.findByTestId('close-icon').trigger('click');

      await nextTick();

      expect(wrapper.find(GlBanner).exists()).toBe(false);
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

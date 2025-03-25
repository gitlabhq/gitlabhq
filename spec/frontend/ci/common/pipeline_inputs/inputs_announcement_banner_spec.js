import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import InputsAnnouncementBanner from '~/ci/common/pipeline_inputs/inputs_announcement_banner.vue';

describe('InputsAdoptionBanner', () => {
  let wrapper;
  let userCalloutDismissSpy;

  const createComponent = ({ shouldShowCallout = true } = {}) => {
    userCalloutDismissSpy = jest.fn();

    wrapper = shallowMount(InputsAnnouncementBanner, {
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  const findBanner = () => wrapper.findComponent(GlBanner);

  describe('on mount', () => {
    describe('banner', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the banner', () => {
        expect(findBanner().exists()).toBe(true);
      });

      it('sets the correct props', () => {
        expect(findBanner().props()).toMatchObject({
          variant: 'introduction',
          buttonLink: '/help/ci/yaml/inputs#define-input-parameters-with-specinputs',
          buttonText: 'Start using inputs',
        });
      });
    });

    describe('dismissing the banner', () => {
      it('calls the dismiss callback', () => {
        createComponent();
        findBanner().vm.$emit('close');

        expect(userCalloutDismissSpy).toHaveBeenCalled();
      });
    });

    describe('when the banner has been dismissed', () => {
      it('does not show the banner', () => {
        createComponent({
          shouldShowCallout: false,
        });
        expect(findBanner().exists()).toBe(false);
      });
    });
  });
});

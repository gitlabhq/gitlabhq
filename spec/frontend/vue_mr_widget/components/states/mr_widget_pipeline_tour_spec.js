import { shallowMount } from '@vue/test-utils';
import { GlPopover } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { mockTracking, triggerEvent, unmockTracking } from 'helpers/tracking_helper';
import pipelineTourState from '~/vue_merge_request_widget/components/states/mr_widget_pipeline_tour.vue';
import { popoverProps, cookieKey } from './pipeline_tour_mock_data';

describe('MRWidgetPipelineTour', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    describe(`when ${cookieKey} cookie is set`, () => {
      beforeEach(() => {
        Cookies.set(cookieKey, true);
        wrapper = shallowMount(pipelineTourState, {
          propsData: popoverProps,
        });
      });

      it('does not render the popover', () => {
        const popover = wrapper.find(GlPopover);

        expect(popover.exists()).toBe(false);
      });

      describe('tracking', () => {
        let trackingSpy;

        beforeEach(() => {
          trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
        });

        afterEach(() => {
          unmockTracking();
        });
        it('does not call tracking', () => {
          expect(trackingSpy).not.toHaveBeenCalled();
        });
      });
    });

    describe(`when ${cookieKey} cookie is not set`, () => {
      const findOkBtn = () => wrapper.find({ ref: 'ok' });
      const findDismissBtn = () => wrapper.find({ ref: 'no-thanks' });

      beforeEach(() => {
        Cookies.remove(cookieKey);
        wrapper = shallowMount(pipelineTourState, {
          propsData: popoverProps,
        });
      });

      it('renders the popover', () => {
        const popover = wrapper.find(GlPopover);

        expect(popover.exists()).toBe(true);
      });

      it('renders the show me how button', () => {
        const button = findOkBtn();

        expect(button.exists()).toBe(true);
        expect(button.attributes().category).toBe('primary');
      });

      it('renders the dismiss button', () => {
        const button = findDismissBtn();

        expect(button.exists()).toBe(true);
        expect(button.attributes().category).toBe('secondary');
      });

      it('renders the empty pipelines image', () => {
        const image = wrapper.find('img');

        expect(image.exists()).toBe(true);
        expect(image.attributes().src).toBe(popoverProps.pipelineSvgPath);
      });

      describe('tracking', () => {
        let trackingSpy;

        beforeEach(() => {
          trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
        });

        afterEach(() => {
          unmockTracking();
        });

        it('send event for basic view of popover', () => {
          document.body.dataset.page = 'projects:merge_requests:show';

          wrapper.vm.trackOnShow();

          expect(trackingSpy).toHaveBeenCalledWith(undefined, undefined, {
            label: popoverProps.trackLabel,
            property: popoverProps.humanAccess,
          });
        });

        it('send an event when ok button is clicked', () => {
          const okBtn = findOkBtn();
          triggerEvent(okBtn.element);

          expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_button', {
            label: popoverProps.trackLabel,
            property: popoverProps.humanAccess,
            value: '10',
          });
        });

        it('send an event when dismiss button is clicked', () => {
          const dismissBtn = findDismissBtn();
          triggerEvent(dismissBtn.element);

          expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_button', {
            label: popoverProps.trackLabel,
            property: popoverProps.humanAccess,
            value: '20',
          });
        });
      });

      describe('dismissPopover', () => {
        it('updates popoverDismissed', () => {
          const button = findDismissBtn();
          const popover = wrapper.find(GlPopover);
          button.vm.$emit('click');

          return wrapper.vm.$nextTick().then(() => {
            expect(Cookies.get(cookieKey)).toBe('true');
            expect(popover.exists()).toBe(false);
          });
        });
      });
    });
  });
});

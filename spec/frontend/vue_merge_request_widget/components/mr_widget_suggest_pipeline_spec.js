import { GlSprintf } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import MrWidgetIcon from '~/vue_merge_request_widget/components/mr_widget_icon.vue';
import suggestPipelineComponent from '~/vue_merge_request_widget/components/mr_widget_suggest_pipeline.vue';
import { SP_TRACK_LABEL, SP_HELP_URL } from '~/vue_merge_request_widget/constants';

import { suggestProps, iconName } from './pipeline_tour_mock_data';

describe('MRWidgetSuggestPipeline', () => {
  describe('template', () => {
    let wrapper;

    describe('core functionality', () => {
      let trackingSpy;

      beforeEach(() => {
        document.body.dataset.page = 'projects:merge_requests:show';
        trackingSpy = mockTracking('_category_', undefined, jest.spyOn);

        wrapper = mount(suggestPipelineComponent, {
          propsData: suggestProps,
          stubs: {
            GlSprintf,
            UserCalloutDismisser: makeMockUserCalloutDismisser({
              shouldShowCallout: true,
            }),
          },
        });
      });

      afterEach(() => {
        unmockTracking();
      });

      it('renders the expected text', () => {
        const messageText = /Looks like there's no pipeline here./;

        expect(wrapper.text()).toMatch(messageText);
      });

      it('renders widget icon', () => {
        const icon = wrapper.findComponent(MrWidgetIcon);

        expect(icon.exists()).toBe(true);
        expect(icon.props()).toEqual(
          expect.objectContaining({
            name: iconName,
          }),
        );
      });

      it('renders the help link', () => {
        const link = wrapper.find('[data-testid="help"]');

        expect(link.exists()).toBe(true);
        expect(link.attributes('href')).toBe(SP_HELP_URL);
      });

      describe('tracking', () => {
        it('send event for basic view of the suggest pipeline widget', () => {
          const expectedCategory = undefined;
          const expectedAction = undefined;

          expect(trackingSpy).toHaveBeenCalledWith(expectedCategory, expectedAction, {
            label: SP_TRACK_LABEL,
            property: suggestProps.humanAccess,
          });
        });
      });
    });
  });
});

import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DevopsScoreCallout from '~/analytics/devops_reports/components/devops_score_callout.vue';
import { INTRO_COOKIE_KEY } from '~/analytics/devops_reports/constants';
import * as utils from '~/lib/utils/common_utils';
import { devopsReportDocsPath, devopsScoreIntroImagePath } from '../mock_data';

describe('DevopsScoreCallout', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(DevopsScoreCallout, {
      provide: {
        devopsReportDocsPath,
        devopsScoreIntroImagePath,
      },
    });
  };

  const findBanner = () => wrapper.findComponent(GlBanner);

  describe('with no cookie set', () => {
    beforeEach(() => {
      utils.setCookie = jest.fn();

      createComponent();
    });

    it('displays the banner', () => {
      expect(findBanner().exists()).toBe(true);
    });

    it('does not call setCookie', () => {
      expect(utils.setCookie).not.toHaveBeenCalled();
    });

    describe('when the close button is clicked', () => {
      beforeEach(() => {
        findBanner().vm.$emit('close');
      });

      it('sets the dismissed cookie', () => {
        expect(utils.setCookie).toHaveBeenCalledWith(INTRO_COOKIE_KEY, 'true');
      });

      it('hides the banner', () => {
        expect(findBanner().exists()).toBe(false);
      });
    });
  });

  describe('with the dismissed cookie set', () => {
    beforeEach(() => {
      jest.spyOn(utils, 'getCookie').mockReturnValue('true');

      createComponent();
    });

    it('hides the banner', () => {
      expect(findBanner().exists()).toBe(false);
    });
  });
});

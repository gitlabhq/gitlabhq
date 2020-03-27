import Vue from 'vue';
import { setUrlParams } from '~/lib/utils/url_utility';
import SurveyBanner from './survey_banner.vue';

let bannerInstance;
const SURVEY_URL_BASE = 'https://gitlab.fra1.qualtrics.com/jfe/form/SV_00PfofFfY9s8Shf';

export default function initServerlessSurveyBanner() {
  const el = document.querySelector('.js-serverless-survey-banner');
  if (el && !bannerInstance) {
    const { userName, userEmail } = el.dataset;

    // pre-populate survey fields
    const surveyUrl = setUrlParams(
      {
        Q_PopulateResponse: JSON.stringify({
          QID1: userEmail,
          QID2: userName,
          QID16: '1', // selects "yes" to "do you currently use GitLab?"
        }),
      },
      SURVEY_URL_BASE,
    );

    bannerInstance = new Vue({
      el,
      render(createElement) {
        return createElement(SurveyBanner, {
          props: {
            surveyUrl,
          },
        });
      },
    });
  }
}

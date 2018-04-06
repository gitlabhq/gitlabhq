import $ from 'jquery';
import EETrialBanner from './ee_trial_banner';

export default function initEETrialBanner() {
  const $trialBanner = $('.js-gitlab-ee-license-banner');
  if ($trialBanner.length) {
    const eeTrialBanner = new EETrialBanner($trialBanner);
    eeTrialBanner.init();
  }
}

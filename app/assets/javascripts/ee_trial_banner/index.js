import EETrialBanner from './ee_trial_banner';

$(() => {
  const $trialBanner = $('.js-gitlab-ee-license-banner');
  if ($trialBanner.length) {
    const eeTrialBanner = new EETrialBanner($trialBanner);
    eeTrialBanner.init();
  }
});

import EETrialBanner from './ee_trial_banner';

$(() => {
  const $trialBanner = $('.js-gitlab-ee-trial-banner');
  if ($trialBanner.length) {
    const eeTrialBanner = new EETrialBanner($trialBanner);
    eeTrialBanner.init();
  }
});

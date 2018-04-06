import $ from 'jquery';
import initEETrialBanner from 'ee/ee_trial_banner';

$(() => {
  /**
   * EE specific scripts
   */
  $('#modal-upload-trial-license').modal('show');

  // EE specific calls
  initEETrialBanner();
});

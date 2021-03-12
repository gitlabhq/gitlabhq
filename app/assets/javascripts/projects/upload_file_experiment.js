import ExperimentTracking from '~/experimentation/experiment_tracking';

function trackEvent(eventName) {
  const isEmpty = Boolean(document.querySelector('.project-home-panel.empty-project'));
  const property = isEmpty ? 'empty' : 'nonempty';
  const label = 'blob-upload-modal';
  const Tracking = new ExperimentTracking('empty_repo_upload', { label, property });

  Tracking.event(eventName);
}

export function initUploadFileTrigger() {
  const uploadFileTriggerEl = document.querySelector('.js-upload-file-experiment-trigger');

  if (uploadFileTriggerEl) {
    uploadFileTriggerEl.addEventListener('click', () => {
      trackEvent('click_upload_modal_trigger');
    });
  }
}

export function trackUploadFileFormSubmitted() {
  trackEvent('click_upload_modal_form_submit');
}

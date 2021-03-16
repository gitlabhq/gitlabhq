import ExperimentTracking from '~/experimentation/experiment_tracking';

export const trackFileUploadEvent = (eventName) => {
  const isEmpty = Boolean(document.querySelector('.project-home-panel.empty-project'));
  const property = isEmpty ? 'empty' : 'nonempty';
  const label = 'blob-upload-modal';
  const FileUploadTracking = new ExperimentTracking('empty_repo_upload', { label, property });
  FileUploadTracking.event(eventName);
};

import ExperimentTracking from '~/experiment_tracking';
import * as UploadFileExperiment from '~/projects/upload_file_experiment';

const mockExperimentTrackingEvent = jest.fn();
jest.mock('~/experiment_tracking', () =>
  jest.fn().mockImplementation(() => ({
    event: mockExperimentTrackingEvent,
  })),
);

const fixture = `<a class='js-upload-file-experiment-trigger' data-toggle='modal' data-target='#modal-upload-blob'></a><div id='modal-upload-blob'></div><div class='project-home-panel empty-project'></div>`;
const findModal = () => document.querySelector('[aria-modal="true"]');
const findTrigger = () => document.querySelector('.js-upload-file-experiment-trigger');

beforeEach(() => {
  ExperimentTracking.mockClear();
  mockExperimentTrackingEvent.mockClear();

  document.body.innerHTML = fixture;
});

afterEach(() => {
  document.body.innerHTML = '';
});

describe('trackUploadFileFormSubmitted', () => {
  it('initializes ExperimentTracking with the correct arguments and calls the tracking event with correct arguments', () => {
    UploadFileExperiment.trackUploadFileFormSubmitted();

    expect(ExperimentTracking).toHaveBeenCalledWith('empty_repo_upload', {
      label: 'blob-upload-modal',
      property: 'empty',
    });
    expect(mockExperimentTrackingEvent).toHaveBeenCalledWith('click_upload_modal_form_submit');
  });

  it('initializes ExperimentTracking with the correct arguments when the project is not empty', () => {
    document.querySelector('.empty-project').remove();

    UploadFileExperiment.trackUploadFileFormSubmitted();

    expect(ExperimentTracking).toHaveBeenCalledWith('empty_repo_upload', {
      label: 'blob-upload-modal',
      property: 'nonempty',
    });
  });
});

describe('initUploadFileTrigger', () => {
  it('calls modal and tracks event', () => {
    UploadFileExperiment.initUploadFileTrigger();

    expect(findModal()).not.toExist();
    findTrigger().click();
    expect(findModal()).toExist();
    expect(mockExperimentTrackingEvent).toHaveBeenCalledWith('click_upload_modal_trigger');
  });
});

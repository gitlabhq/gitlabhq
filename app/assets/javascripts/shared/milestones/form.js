import $ from 'jquery';
import initDatePicker from '~/behaviors/date_picker';
import GLForm from '../../gl_form';
import ZenMode from '../../zen_mode';

export default (initGFM = true) => {
  new ZenMode(); // eslint-disable-line no-new
  initDatePicker();

  // eslint-disable-next-line no-new
  new GLForm($('.milestone-form'), {
    emojis: true,
    members: initGFM,
    issues: initGFM,
    mergeRequests: initGFM,
    epics: initGFM,
    milestones: initGFM,
    labels: initGFM,
    snippets: initGFM,
    vulnerabilities: initGFM,
  });
};

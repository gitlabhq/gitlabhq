import $ from 'jquery';
import GLForm from '~/gl_form';
import ZenMode from '~/zen_mode';

export default () => {
  // eslint-disable-next-line no-new
  new GLForm($('.snippet-form'), {
    members: false,
    issues: false,
    mergeRequests: false,
    epics: false,
    milestones: false,
    labels: false,
    snippets: false,
  });
  new ZenMode(); // eslint-disable-line no-new
};

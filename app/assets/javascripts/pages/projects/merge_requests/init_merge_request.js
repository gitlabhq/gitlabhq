/* eslint-disable no-new */

import $ from 'jquery';
import Diff from '~/diff';
import ShortcutsNavigation from '~/shortcuts_navigation';
import GLForm from '~/gl_form';
import IssuableForm from '~/issuable_form';
import LabelsSelect from '~/labels_select';
import MilestoneSelect from '~/milestone_select';
import IssuableTemplateSelectors from '~/templates/issuable_template_selectors';

export default () => {
  new Diff();
  new ShortcutsNavigation();
  new GLForm($('.merge-request-form'), true);
  new IssuableForm($('.merge-request-form'));
  new LabelsSelect();
  new MilestoneSelect();
  new IssuableTemplateSelectors();
};

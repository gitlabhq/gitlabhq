/* eslint-disable no-new */

import $ from 'jquery';
import IssuableForm from 'ee_else_ce/issuable_form';
import Diff from '~/diff';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import GLForm from '~/gl_form';
import LabelsSelect from '~/labels_select';
import MilestoneSelect from '~/milestone_select';
import IssuableTemplateSelectors from '~/templates/issuable_template_selectors';

export default () => {
  new Diff();
  new ShortcutsNavigation();
  new GLForm($('.merge-request-form'));
  new IssuableForm($('.merge-request-form'));
  new LabelsSelect();
  new MilestoneSelect();
  new IssuableTemplateSelectors({
    warnTemplateOverride: true,
  });
};

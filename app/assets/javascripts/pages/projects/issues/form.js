/* eslint-disable no-new */

import $ from 'jquery';
import IssuableForm from 'ee_else_ce/issuable_form';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import GLForm from '~/gl_form';
import initSuggestions from '~/issuable_suggestions';
import initIssuableTypeSelector from '~/issuable_type_selector';
import LabelsSelect from '~/labels_select';
import MilestoneSelect from '~/milestone_select';
import IssuableTemplateSelectors from '~/templates/issuable_template_selectors';

export default () => {
  new ShortcutsNavigation();
  new GLForm($('.issue-form'));
  new IssuableForm($('.issue-form'));
  new LabelsSelect();
  new MilestoneSelect();
  new IssuableTemplateSelectors({
    warnTemplateOverride: true,
  });

  initSuggestions();
  initIssuableTypeSelector();
};

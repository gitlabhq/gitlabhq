/* eslint-disable no-new */

import $ from 'jquery';
import IssuableForm from 'ee_else_ce/issuable/issuable_form';
import IssuableLabelSelector from '~/issuable/issuable_label_selector';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import GLForm from '~/gl_form';
import LabelsSelect from '~/labels/labels_select';
import IssuableTemplateSelectors from '~/issuable/issuable_template_selectors';
import { mountMilestoneDropdown } from '~/sidebar/mount_sidebar';

export default () => {
  new ShortcutsNavigation();
  new GLForm($('.merge-request-form'));
  new IssuableForm($('.merge-request-form'));
  IssuableLabelSelector();
  new LabelsSelect();
  new IssuableTemplateSelectors({
    warnTemplateOverride: true,
  });
  mountMilestoneDropdown('[name="merge_request[milestone_id]"]');
};

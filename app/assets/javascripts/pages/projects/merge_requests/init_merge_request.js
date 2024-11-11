/* eslint-disable no-new */

import $ from 'jquery';
import IssuableForm from 'ee_else_ce/issuable/issuable_form';
import IssuableLabelSelector from '~/issuable/issuable_label_selector';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import LabelsSelect from '~/labels/labels_select';
import { mountMilestoneDropdown } from '~/sidebar/mount_sidebar';
import mountMergeScheduleInput from './mount_merge_schedule_input';

export default () => {
  addShortcutsExtension(ShortcutsNavigation);
  new IssuableForm($('.merge-request-form'));
  IssuableLabelSelector();
  new LabelsSelect();
  mountMilestoneDropdown('[name="merge_request[milestone_id]"]');
  mountMergeScheduleInput();
};

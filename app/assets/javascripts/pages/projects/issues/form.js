/* eslint-disable no-new */
import GLForm from '~/gl_form';
import IssuableForm from '~/issuable_form';
import LabelsSelect from '~/labels_select';
import MilestoneSelect from '~/milestone_select';
import ShortcutsNavigation from '~/shortcuts_navigation';
import IssuableTemplateSelectors from '~/templates/issuable_template_selectors';
<<<<<<< HEAD
import WeightSelect from 'ee/weight_select';
=======
>>>>>>> upstream/master

export default () => {
  new ShortcutsNavigation();
  new GLForm($('.issue-form'), true);
  new IssuableForm($('.issue-form'));
  new LabelsSelect();
  new MilestoneSelect();
  new IssuableTemplateSelectors();
<<<<<<< HEAD
  new WeightSelect();
=======
>>>>>>> upstream/master
};

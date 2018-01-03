/* eslint-disable no-new */
import LabelsSelect from './labels_select';
import subscriptionSelect from './subscription_select';
import UsersSelect from './users_select';
import issueStatusSelect from './issue_status_select';
import MilestoneSelect from './milestone_select';
<<<<<<< HEAD

import WeightSelect from 'ee/weight_select'; // eslint-disable-line import/first
=======
>>>>>>> upstream/master

export default () => {
  new UsersSelect();
  new LabelsSelect();
  new MilestoneSelect();
  issueStatusSelect();
  subscriptionSelect();
  new WeightSelect();
};

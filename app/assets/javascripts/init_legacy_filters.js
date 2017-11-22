/* eslint-disable no-new */
import LabelsSelect from './labels_select';
/* global MilestoneSelect */
<<<<<<< HEAD
/* global WeightSelect */
=======
>>>>>>> upstream/master
import subscriptionSelect from './subscription_select';
import UsersSelect from './users_select';
import issueStatusSelect from './issue_status_select';

export default () => {
  new UsersSelect();
  new LabelsSelect();
  new MilestoneSelect();
  issueStatusSelect();
  subscriptionSelect();
<<<<<<< HEAD
  new WeightSelect();
=======
>>>>>>> upstream/master
};

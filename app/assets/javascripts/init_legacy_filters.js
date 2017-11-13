/* eslint-disable no-new */
import LabelsSelect from './labels_select';
/* global MilestoneSelect */
/* global SubscriptionSelect */

import UsersSelect from './users_select';
import issueStatusSelect from './issue_status_select';

export default () => {
  new UsersSelect();
  new LabelsSelect();
  new MilestoneSelect();
  issueStatusSelect();
  new SubscriptionSelect();
};

/* eslint-disable no-new */
/* global LabelsSelect */
/* global MilestoneSelect */
/* global IssueStatusSelect */
/* global SubscriptionSelect */

import UsersSelect from './users_select';

export default () => {
  new UsersSelect();
  new LabelsSelect();
  new MilestoneSelect();
  new IssueStatusSelect();
  new SubscriptionSelect();
};

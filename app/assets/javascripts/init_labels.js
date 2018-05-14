import $ from 'jquery';
import LabelManager from './label_manager';
import GroupLabelSubscription from './group_label_subscription';
import ProjectLabelSubscription from './project_label_subscription';

export default () => {
  if ($('.prioritized-labels').length) {
    new LabelManager(); // eslint-disable-line no-new
  }
  $('.label-subscription').each((i, el) => {
    const $el = $(el);

    if ($el.find('.dropdown-group-label').length) {
      new GroupLabelSubscription($el); // eslint-disable-line no-new
    } else {
      new ProjectLabelSubscription($el); // eslint-disable-line no-new
    }
  });
};

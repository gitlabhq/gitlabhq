import $ from 'jquery';
import ShortcutsNavigation from '~/shortcuts_navigation';
import NotificationsForm from '~/notifications_form';
import UserCallout from '~/user_callout';
import TreeView from '~/tree';
import BlobViewer from '~/blob/viewer/index';
import Activities from '~/activities';
import { ajaxGet } from '~/lib/utils/common_utils';
import Star from '../../../star';
import notificationsDropdown from '../../../notifications_dropdown';

document.addEventListener('DOMContentLoaded', () => {
  new Star(); // eslint-disable-line no-new
  notificationsDropdown();
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new NotificationsForm(); // eslint-disable-line no-new
  new UserCallout({ // eslint-disable-line no-new
    setCalloutPerProject: true,
    className: 'js-autodevops-banner',
  });

  if ($('#tree-slider').length) new TreeView(); // eslint-disable-line no-new
  if ($('.blob-viewer').length) new BlobViewer(); // eslint-disable-line no-new
  if ($('.project-show-activity').length) new Activities(); // eslint-disable-line no-new
  $('#tree-slider').waitForImages(() => {
    ajaxGet(document.querySelector('.js-tree-content').dataset.logsPath);
  });
});

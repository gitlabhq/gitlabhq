import $ from 'jquery';
import initBlob from '~/blob_edit/blob_bundle';
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

  // Project show page loads different overview content based on user preferences
  const treeSlider = document.querySelector('#tree-slider');
  if (treeSlider) {
    new TreeView(); // eslint-disable-line no-new
    initBlob();
  }

  if (document.querySelector('.blob-viewer')) {
    new BlobViewer(); // eslint-disable-line no-new
  }

  if (document.querySelector('.project-show-activity')) {
    new Activities(); // eslint-disable-line no-new
  }

  $(treeSlider).waitForImages(() => {
    ajaxGet(document.querySelector('.js-tree-content').dataset.logsPath);
  });
});

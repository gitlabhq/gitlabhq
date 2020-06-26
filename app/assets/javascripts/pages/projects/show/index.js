import initBlob from '~/blob_edit/blob_bundle';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import NotificationsForm from '~/notifications_form';
import UserCallout from '~/user_callout';
import BlobViewer from '~/blob/viewer/index';
import Activities from '~/activities';
import initReadMore from '~/read_more';
import leaveByUrl from '~/namespaces/leave_by_url';
import Star from '../../../star';
import notificationsDropdown from '../../../notifications_dropdown';
import initNamespaceStorageLimitAlert from '~/namespace_storage_limit_alert';
import { showLearnGitLabProjectPopover } from '~/onboarding_issues';
import initTree from 'ee_else_ce/repository';

document.addEventListener('DOMContentLoaded', () => {
  initReadMore();
  initNamespaceStorageLimitAlert();
  new Star(); // eslint-disable-line no-new
  notificationsDropdown();
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new NotificationsForm(); // eslint-disable-line no-new
  // eslint-disable-next-line no-new
  new UserCallout({
    setCalloutPerProject: false,
    className: 'js-autodevops-banner',
  });

  // Project show page loads different overview content based on user preferences
  const treeSlider = document.getElementById('js-tree-list');
  if (treeSlider) {
    initBlob();
    initTree();
  }

  if (document.querySelector('.blob-viewer')) {
    new BlobViewer(); // eslint-disable-line no-new
  }

  if (document.querySelector('.project-show-activity')) {
    new Activities(); // eslint-disable-line no-new
  }

  leaveByUrl('project');

  showLearnGitLabProjectPopover();
});

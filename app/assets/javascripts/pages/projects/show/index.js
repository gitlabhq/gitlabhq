import Vue from 'vue';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { initFindFileShortcut } from '~/projects/behaviors';
import initClustersDeprecationAlert from '~/projects/clusters_deprecation_alert';
import leaveByUrl from '~/namespaces/leave_by_url';
import initTerraformNotification from '~/projects/terraform_notification';
import { initUploadFileTrigger } from '~/projects/upload_file';
import initReadMore from '~/read_more';
import initAmbiguousRefModal from '~/ref/init_ambiguous_ref_modal';
import CodeDropdown from '~/vue_shared/components/code_dropdown/code_dropdown.vue';
import initSourceCodeDropdowns from '~/vue_shared/components/download_dropdown/init_download_dropdowns';
import EmptyProject from '~/pages/projects/show/empty_project';
import initHeaderApp from '~/repository/init_header_app';
import initWebIdeLink from '~/pages/projects/shared/web_ide_link';
import CompactCodeDropdown from '~/repository/components/code_dropdown/compact_code_dropdown.vue';
import { initHomePanel } from '../home_panel';

// Project show page loads different overview content based on user preferences
if (document.getElementById('js-tree-list')) {
  import(/* webpackChunkName: 'treeList' */ 'ee_else_ce/repository')
    .then(({ default: initTree }) => {
      initTree();
    })
    .catch(() => {});
}

if (document.querySelector('.blob-viewer')) {
  import(/* webpackChunkName: 'blobViewer' */ '~/blob/viewer')
    .then(({ BlobViewer }) => {
      new BlobViewer(); // eslint-disable-line no-new
      initHeaderApp({ isReadmeView: true });
    })
    .catch(() => {});
}

if (document.querySelector('.project-show-activity')) {
  import(/* webpackChunkName: 'activitiesList' */ '~/activities')
    .then(({ default: Activities }) => {
      new Activities(); // eslint-disable-line no-new
    })
    .catch(() => {});
}

addShortcutsExtension(ShortcutsNavigation);

initUploadFileTrigger();
initClustersDeprecationAlert();
initTerraformNotification();
initReadMore();
initAmbiguousRefModal();
initHomePanel();

if (document.querySelector('.js-autodevops-banner')) {
  import(/* webpackChunkName: 'userCallOut' */ '~/user_callout')
    .then(({ default: UserCallout }) => {
      // eslint-disable-next-line no-new
      new UserCallout({
        setCalloutPerProject: false,
        className: 'js-autodevops-banner',
      });
    })
    .catch(() => {});
}

leaveByUrl('project');

const initCodeDropdown = () => {
  const codeDropdownEl = document.querySelector('#js-project-show-empty-page #js-code-dropdown');

  if (!codeDropdownEl) return false;

  const { sshUrl, httpUrl, kerberosUrl } = codeDropdownEl.dataset;

  const CodeDropdownComponent =
    gon.features.directoryCodeDropdownUpdates && gon.features.blobRepositoryVueHeaderApp
      ? CompactCodeDropdown
      : CodeDropdown;

  return new Vue({
    el: codeDropdownEl,
    render(createElement) {
      return createElement(CodeDropdownComponent, {
        props: {
          sshUrl,
          httpUrl,
          kerberosUrl,
        },
      });
    },
  });
};

const initEmptyProjectTabs = () => {
  const emptyProjectEl = document.querySelector('#js-project-show-empty-page');

  if (!emptyProjectEl) return;

  new EmptyProject(); // eslint-disable-line no-new
};

initCodeDropdown();
initSourceCodeDropdowns();
initFindFileShortcut();
initEmptyProjectTabs();
initWebIdeLink({ el: document.getElementById('js-tree-web-ide-link') });

import Vue from 'vue';
import createRouter from './router';
import App from './components/app.vue';
import Breadcrumbs from './components/breadcrumbs.vue';
import LastCommit from './components/last_commit.vue';
import TreeActionLink from './components/tree_action_link.vue';
import DirectoryDownloadLinks from './components/directory_download_links.vue';
import apolloProvider from './graphql';
import { setTitle } from './utils/title';
import { updateFormAction } from './utils/dom';
import { parseBoolean } from '../lib/utils/common_utils';
import { webIDEUrl } from '../lib/utils/url_utility';
import { __ } from '../locale';

export default function setupVueRepositoryList() {
  const el = document.getElementById('js-tree-list');
  const { dataset } = el;
  const { projectPath, projectShortPath, ref, fullName } = dataset;
  const router = createRouter(projectPath, ref);

  apolloProvider.clients.defaultClient.cache.writeData({
    data: {
      projectPath,
      projectShortPath,
      ref,
      commits: [],
    },
  });

  router.afterEach(({ params: { pathMatch } }) => {
    setTitle(pathMatch, ref, fullName);
  });

  const breadcrumbEl = document.getElementById('js-repo-breadcrumb');

  if (breadcrumbEl) {
    const {
      canCollaborate,
      canEditTree,
      newBranchPath,
      newTagPath,
      newBlobPath,
      forkNewBlobPath,
      forkNewDirectoryPath,
      forkUploadBlobPath,
      uploadPath,
      newDirPath,
    } = breadcrumbEl.dataset;

    router.afterEach(({ params: { pathMatch = '/' } }) => {
      updateFormAction('.js-upload-blob-form', uploadPath, pathMatch);
      updateFormAction('.js-create-dir-form', newDirPath, pathMatch);
    });

    // eslint-disable-next-line no-new
    new Vue({
      el: breadcrumbEl,
      router,
      apolloProvider,
      render(h) {
        return h(Breadcrumbs, {
          props: {
            currentPath: this.$route.params.pathMatch,
            canCollaborate: parseBoolean(canCollaborate),
            canEditTree: parseBoolean(canEditTree),
            newBranchPath,
            newTagPath,
            newBlobPath,
            forkNewBlobPath,
            forkNewDirectoryPath,
            forkUploadBlobPath,
          },
        });
      },
    });
  }

  // eslint-disable-next-line no-new
  new Vue({
    el: document.getElementById('js-last-commit'),
    router,
    apolloProvider,
    render(h) {
      return h(LastCommit, {
        props: {
          currentPath: this.$route.params.pathMatch,
        },
      });
    },
  });

  const treeHistoryLinkEl = document.getElementById('js-tree-history-link');
  const { historyLink } = treeHistoryLinkEl.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: treeHistoryLinkEl,
    router,
    render(h) {
      return h(TreeActionLink, {
        props: {
          path: historyLink + (this.$route.params.pathMatch || '/'),
          text: __('History'),
        },
      });
    },
  });

  const webIdeLinkEl = document.getElementById('js-tree-web-ide-link');

  if (webIdeLinkEl) {
    // eslint-disable-next-line no-new
    new Vue({
      el: webIdeLinkEl,
      router,
      render(h) {
        return h(TreeActionLink, {
          props: {
            path: webIDEUrl(`/${projectPath}/edit/${ref}/-${this.$route.params.pathMatch || '/'}`),
            text: __('Web IDE'),
            cssClass: 'qa-web-ide-button',
          },
        });
      },
    });
  }

  const directoryDownloadLinks = document.getElementById('js-directory-downloads');

  if (directoryDownloadLinks) {
    // eslint-disable-next-line no-new
    new Vue({
      el: directoryDownloadLinks,
      router,
      render(h) {
        const currentPath = this.$route.params.pathMatch || '/';

        if (currentPath !== '/') {
          return h(DirectoryDownloadLinks, {
            props: {
              currentPath: currentPath.replace(/^\//, ''),
              links: JSON.parse(directoryDownloadLinks.dataset.links),
            },
          });
        }

        return null;
      },
    });
  }

  // eslint-disable-next-line no-new
  new Vue({
    el,
    router,
    apolloProvider,
    render(h) {
      return h(App);
    },
  });

  return { router, data: dataset };
}

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import ImportByUrl from '~/projects/new_v2/components/import_by_url_form.vue';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';

export function initImportByUrl() {
  const el = document.querySelector('.js-vue-import-by-url-app');

  if (!el) {
    return null;
  }

  const {
    importByUrlValidatePath,
    canCreateProject,
    defaultProjectVisibility,
    hasRepositoryMirrorsFeature,
    newProjectPath,
    newProjectFormPath,
    userNamespaceId,
    userNamespaceFullPath,
  } = el.dataset;

  const provide = {
    importByUrlValidatePath,
    canCreateProject,
    defaultProjectVisibility,
    hasRepositoryMirrorsFeature: parseBoolean(hasRepositoryMirrorsFeature),
    newProjectPath,
    newProjectFormPath,
    userNamespaceId,
    userNamespaceFullPath,
  };

  return new Vue({
    el,
    name: 'ImportByUrlRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide,
    render(createElement) {
      return createElement(ImportByUrl);
    },
  });
}

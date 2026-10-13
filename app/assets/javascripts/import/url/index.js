import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '@gitlab/frontend-utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import ImportByUrlForm from '~/projects/new_v2/components/import_by_url_form.vue';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

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
    namespaceId,
    namespaceFullPath,
    namespaceVisibility,
  } = el.dataset;

  const namespace = {
    id: namespaceId,
    fullPath: namespaceFullPath,
    visibility: namespaceVisibility,
  };

  const provide = {
    importByUrlValidatePath,
    canCreateProject,
    defaultProjectVisibility,
    hasRepositoryMirrorsFeature: parseBoolean(hasRepositoryMirrorsFeature),
    newProjectPath,
    newProjectFormPath,
    userNamespaceId,
  };

  return initVueApp({
    el,
    name: 'ImportByUrlRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide,
    component: ImportByUrlForm,
    props: { namespace },
  });
}

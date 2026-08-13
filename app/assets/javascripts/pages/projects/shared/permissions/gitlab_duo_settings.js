import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import GitlabDuoSettings from './components/gitlab_duo_settings.vue';

Vue.use(VueApollo);

export default function initGitlabDuoSettings() {
  const mountPoint = document.querySelector('.js-gitlab-duo-settings-form');
  const componentPropsEl = document.querySelector('.js-gitlab-duo-settings-form-data');

  if (!mountPoint) {
    return null;
  }

  const componentProps = JSON.parse(componentPropsEl.innerHTML);
  const componentPropsParsed = convertObjectPropsToCamelCase(componentProps, {
    deep: true,
  });
  const { targetFormId } = mountPoint.dataset;

  return initVueApp({
    el: mountPoint,
    name: 'GitlabDuoSettingsRoot',
    apolloProvider: new VueApollo({ defaultClient: createDefaultClient() }),
    component: GitlabDuoSettings,
    props: componentPropsParsed,
    events: {
      confirm: () => {
        if (targetFormId) document.getElementById(targetFormId)?.submit();
      },
    },
  });
}

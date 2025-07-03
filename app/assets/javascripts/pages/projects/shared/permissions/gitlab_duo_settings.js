import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import GitlabDuoSettings from './components/gitlab_duo_settings.vue';

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

  return new Vue({
    el: mountPoint,
    name: 'GitlabDuoSettingsRoot',
    render: (createElement) =>
      createElement(GitlabDuoSettings, {
        props: componentPropsParsed,
        on: {
          confirm: () => {
            if (targetFormId) document.getElementById(targetFormId)?.submit();
          },
        },
      }),
  });
}

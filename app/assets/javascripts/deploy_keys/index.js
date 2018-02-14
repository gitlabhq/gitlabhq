import mountComponent from '~/vue_shared/mount_vue_component';
import DeployKeysApp from './components/app.vue';

document.addEventListener('DOMContentLoaded', () => {
  mountComponent(DeployKeysApp, '#js-deploy-keys');
});

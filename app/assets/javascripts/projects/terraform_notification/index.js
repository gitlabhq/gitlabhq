import Vue from 'vue';
import TerraformNotification from './components/terraform_notification.vue';

export default () => {
  const el = document.querySelector('.js-terraform-notification');

  if (!el) {
    return false;
  }

  const { projectId } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(TerraformNotification, { props: { projectId: Number(projectId) } }),
  });
};

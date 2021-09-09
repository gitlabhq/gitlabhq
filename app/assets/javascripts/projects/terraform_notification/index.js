import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import TerraformNotification from './components/terraform_notification.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('.js-terraform-notification');

  if (!el) {
    return false;
  }

  const { terraformImagePath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      terraformImagePath,
    },
    render: (createElement) => createElement(TerraformNotification),
  });
};

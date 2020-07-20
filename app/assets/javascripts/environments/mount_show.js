import Vue from 'vue';
import DeleteEnvironmentModal from './components/delete_environment_modal.vue';
import environmentsMixin from './mixins/environments_mixin';

export default () => {
  const el = document.getElementById('delete-environment-modal');
  const container = document.getElementById('environments-detail-view');

  return new Vue({
    el,
    components: {
      DeleteEnvironmentModal,
    },
    mixins: [environmentsMixin],
    data() {
      const environment = JSON.parse(JSON.stringify(container.dataset));
      environment.delete_path = environment.deletePath;
      environment.onSingleEnvironmentPage = true;

      return {
        environment,
      };
    },
    render(createElement) {
      return createElement('delete-environment-modal', {
        props: {
          environment: this.environment,
        },
      });
    },
  });
};

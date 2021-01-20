import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import PromoteMilestoneModal from './components/promote_milestone_modal.vue';

Vue.use(Translate);

export default () => {
  const promoteMilestoneModal = document.getElementById('promote-milestone-modal');
  if (!promoteMilestoneModal) {
    return null;
  }

  return new Vue({
    el: promoteMilestoneModal,
    render(createElement) {
      return createElement(PromoteMilestoneModal);
    },
  });
};

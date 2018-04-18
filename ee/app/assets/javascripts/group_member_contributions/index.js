import Vue from 'vue';

import Translate from '~/vue_shared/translate';

import GroupMemberStore from './store/group_member_store';
import GroupMemberService from './service/group_member_service';

import GroupMemberContributionsApp from './components/app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-group-member-contributions');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    components: {
      GroupMemberContributionsApp,
    },
    data() {
      const { memberContributionsPath } = el.dataset;
      const store = new GroupMemberStore();
      const service = new GroupMemberService(memberContributionsPath);

      return {
        store,
        service,
      };
    },
    render(createElement) {
      return createElement('group-member-contributions-app', {
        props: {
          store: this.store,
          service: this.service,
        },
      });
    },
  });
};

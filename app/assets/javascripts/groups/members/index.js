import Vue from 'vue';
import App from './components/app.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default el => {
  if (!el) {
    return () => {};
  }

  return new Vue({
    el,
    components: { App },
    data() {
      const { members, groupId, currentUserId } = this.$options.el.dataset;

      return {
        members: convertObjectPropsToCamelCase(JSON.parse(members), { deep: true }),
        groupId: parseInt(groupId, 10),
        ...(currentUserId ? { currentUserId: parseInt(currentUserId, 10) } : {}),
      };
    },
    render(createElement) {
      return createElement('app', {
        props: {
          members: this.members,
          groupId: this.groupId,
          currentUserId: this.currentUserId,
        },
      });
    },
  });
};

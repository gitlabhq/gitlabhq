export default {
  name: 'ShowMoreAssignees',
  props: {
    hiddenAssignees: { type: Number, required: true },
    toggle: { type: Function, required: true },
  },
  computed: {
    showMore() {
      return this.hiddenAssignees > 0;
    },
  },
  template: `
    <div class="user-list-more">
      <button type="button" class="btn-link" @click="toggle">
        <template v-if="showMore">
          + {{hiddenAssignees}} more
        </template>
        <template v-else>
          - show less
        </template>
      </button>
    </div>
  `,
};

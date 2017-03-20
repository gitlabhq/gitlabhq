export default {
  name: 'ShowMoreAssignees',
  props: {
    hiddenAssignees: { type: Number, required: true },
    toggle: { type: Function, required: true }
  },
  template: `
    <div class="user-list-more">
      <button type="button" class="btn-link" @click="toggle">
        <template v-if="hiddenAssignees > 0">
          + {{hiddenAssignees}} more
        </template>
        <template v-else>
          - show less
        </template>
      </button>
    </div>
  `,
};

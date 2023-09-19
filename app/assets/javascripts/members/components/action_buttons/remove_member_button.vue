<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';

export default {
  name: 'RemoveMemberButton',
  components: { GlButton },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['namespace'],
  props: {
    memberId: {
      type: Number,
      required: true,
    },
    message: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    isAccessRequest: {
      type: Boolean,
      required: false,
      default: false,
    },
    isInvite: {
      type: Boolean,
      required: false,
      default: false,
    },
    userDeletionObstacles: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    ...mapState({
      memberPath(state) {
        return state[this.namespace].memberPath;
      },
    }),
    modalData() {
      return {
        isAccessRequest: this.isAccessRequest,
        isInvite: this.isInvite,
        memberPath: this.memberPath.replace(':id', this.memberId),
        message: this.message,
        userDeletionObstacles: this.userDeletionObstacles,
      };
    },
  },
  methods: {
    ...mapActions({
      showRemoveMemberModal(dispatch, payload) {
        return dispatch(`${this.namespace}/showRemoveMemberModal`, payload);
      },
    }),
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip
    :title="title"
    :aria-label="title"
    icon="remove"
    data-testid="delete-member-button"
    @click="showRemoveMemberModal(modalData)"
  />
</template>

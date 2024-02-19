<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { formType } from '~/boards/constants';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';

export default {
  components: {
    GlButton,
    GitlabExperiment,
  },
  directives: {
    GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['multipleIssueBoardsAvailable', 'canAdminBoard'],
  computed: {
    canShowCreateButton() {
      return this.canAdminBoard && this.multipleIssueBoardsAvailable;
    },
    createButtonText() {
      return s__('Boards|New board');
    },
  },
  methods: {
    showDialog() {
      this.track('click_button', { label: 'create_board' });
      this.$emit('showBoardModal', formType.new);
    },
  },
};
</script>

<template>
  <gitlab-experiment name="prominent_create_board_btn">
    <template #control> </template>
    <template #candidate>
      <div v-if="canShowCreateButton" class="gl-ml-1 gl-mr-3 gl-display-flex gl-align-items-center">
        <gl-button @click.prevent="showDialog">
          {{ createButtonText }}
        </gl-button>
      </div>
    </template>
  </gitlab-experiment>
</template>

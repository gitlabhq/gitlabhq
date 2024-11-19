<script>
import { GlButton, GlButtonGroup, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export const i18n = {
  playTooltip: s__('PipelineSchedules|Run scheduled pipeline'),
  editTooltip: s__('PipelineSchedules|Edit scheduled pipeline'),
  deleteTooltip: s__('PipelineSchedules|Delete scheduled pipeline'),
  takeOwnershipTooltip: s__('PipelineSchedules|Take ownership of pipeline schedule'),
};

export default {
  i18n,
  components: {
    GlButton,
    GlButtonGroup,
  },
  directives: {
    GlTooltip,
  },
  props: {
    schedule: {
      type: Object,
      required: true,
    },
    currentUser: {
      type: Object,
      required: true,
    },
  },
  computed: {
    canPlay() {
      return this.schedule.userPermissions.playPipelineSchedule;
    },
    isCurrentUserOwner() {
      return this.schedule.owner?.username === this.currentUser.username;
    },
    canTakeOwnership() {
      return !this.isCurrentUserOwner && this.schedule.userPermissions.adminPipelineSchedule;
    },
    canUpdate() {
      return this.schedule.userPermissions.updatePipelineSchedule;
    },
    canRemove() {
      return this.schedule.userPermissions.adminPipelineSchedule;
    },
    editPathWithIdParam() {
      const id = getIdFromGraphQLId(this.schedule.id);

      return `${this.schedule.editPath}?id=${id}`;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-justify-end">
    <gl-button-group>
      <gl-button
        v-if="canPlay"
        v-gl-tooltip
        :title="$options.i18n.playTooltip"
        :aria-label="$options.i18n.playTooltip"
        icon="play"
        data-testid="play-pipeline-schedule-btn"
        @click="$emit('playPipelineSchedule', schedule.id)"
      />
      <gl-button
        v-if="canTakeOwnership"
        v-gl-tooltip
        :title="$options.i18n.takeOwnershipTooltip"
        icon="user"
        data-testid="take-ownership-pipeline-schedule-btn"
        @click="$emit('showTakeOwnershipModal', schedule.id)"
      />
      <gl-button
        v-if="canUpdate"
        v-gl-tooltip
        :href="editPathWithIdParam"
        :title="$options.i18n.editTooltip"
        :aria-label="$options.i18n.editTooltip"
        icon="pencil"
        data-testid="edit-pipeline-schedule-btn"
      />
      <gl-button
        v-if="canRemove"
        v-gl-tooltip
        :title="$options.i18n.deleteTooltip"
        :aria-label="$options.i18n.deleteTooltip"
        icon="remove"
        variant="danger"
        data-testid="delete-pipeline-schedule-btn"
        @click="$emit('showDeleteModal', schedule.id)"
      />
    </gl-button-group>
  </div>
</template>

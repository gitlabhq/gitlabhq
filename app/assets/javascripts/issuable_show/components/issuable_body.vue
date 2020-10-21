<script>
import { GlLink } from '@gitlab/ui';

import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import IssuableTitle from './issuable_title.vue';
import IssuableDescription from './issuable_description.vue';
import IssuableEditForm from './issuable_edit_form.vue';

export default {
  components: {
    GlLink,
    TimeAgoTooltip,
    IssuableTitle,
    IssuableDescription,
    IssuableEditForm,
  },
  props: {
    issuable: {
      type: Object,
      required: true,
    },
    statusBadgeClass: {
      type: String,
      required: true,
    },
    statusIcon: {
      type: String,
      required: true,
    },
    enableEdit: {
      type: Boolean,
      required: true,
    },
    enableAutocomplete: {
      type: Boolean,
      required: true,
    },
    editFormVisible: {
      type: Boolean,
      required: true,
    },
    descriptionPreviewPath: {
      type: String,
      required: true,
    },
    descriptionHelpPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    isUpdated() {
      return Boolean(this.issuable.updatedAt);
    },
    updatedBy() {
      return this.issuable.updatedBy;
    },
  },
};
</script>

<template>
  <div class="issue-details issuable-details">
    <div class="detail-page-description content-block">
      <issuable-edit-form
        v-if="editFormVisible"
        :issuable="issuable"
        :enable-autocomplete="enableAutocomplete"
        :description-preview-path="descriptionPreviewPath"
        :description-help-path="descriptionHelpPath"
      >
        <template #edit-form-actions="issuableMeta">
          <slot name="edit-form-actions" v-bind="issuableMeta"></slot>
        </template>
      </issuable-edit-form>
      <template v-else>
        <issuable-title
          :issuable="issuable"
          :status-badge-class="statusBadgeClass"
          :status-icon="statusIcon"
          :enable-edit="enableEdit"
          @edit-issuable="$emit('edit-issuable', $event)"
        >
          <template #status-badge>
            <slot name="status-badge"></slot>
          </template>
        </issuable-title>
        <issuable-description v-if="issuable.descriptionHtml" :issuable="issuable" />
        <small v-if="isUpdated" class="edited-text gl-font-sm!">
          {{ __('Edited') }}
          <time-ago-tooltip :time="issuable.updatedAt" tooltip-placement="bottom" />
          <span v-if="updatedBy">
            {{ __('by') }}
            <gl-link :href="updatedBy.webUrl" class="author-link gl-font-sm!">
              <span>{{ updatedBy.name }}</span>
            </gl-link>
          </span>
        </small>
      </template>
    </div>
  </div>
</template>

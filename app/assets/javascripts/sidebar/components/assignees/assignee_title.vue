<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { n__, __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'AssigneeTitle',
  components: {
    GlLoadingIcon,
    GlIcon,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    numberOfAssignees: {
      type: Number,
      required: true,
    },
    editable: {
      type: Boolean,
      required: true,
    },
    showToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
    changing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    assigneeTitle() {
      const assignees = this.numberOfAssignees;
      return n__('Assignee', `%d Assignees`, assignees);
    },
    titleCopy() {
      return this.changing ? __('Apply') : __('Edit');
    },
  },
};
</script>
<template>
  <div class="hide-collapsed gl-line-height-20 gl-mb-2 gl-text-gray-900 gl-font-weight-bold">
    {{ assigneeTitle }}
    <gl-loading-icon v-if="loading" size="sm" inline class="align-bottom" />
    <a
      v-if="editable"
      class="js-sidebar-dropdown-toggle edit-link btn gl-text-gray-900! gl-ml-auto hide-collapsed btn-default btn-sm gl-button btn-default-tertiary float-right"
      href="#"
      data-test-id="edit-link"
      data-qa-selector="edit_link"
      data-track-action="click_edit_button"
      data-track-label="right_sidebar"
      data-track-property="assignee"
    >
      {{ titleCopy }}
    </a>
    <a
      v-if="showToggle"
      :aria-label="__('Toggle sidebar')"
      class="gutter-toggle float-right js-sidebar-toggle"
      :class="{ 'gl-display-block gl-md-display-none!': glFeatures.movedMrSidebar }"
      href="#"
      role="button"
    >
      <gl-icon data-hidden="true" name="chevron-double-lg-right" :size="12" />
    </a>
  </div>
</template>

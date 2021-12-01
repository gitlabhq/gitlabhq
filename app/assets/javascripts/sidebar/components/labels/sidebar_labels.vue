<script>
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_vue/constants';
import LabelsSelectWidget from '~/vue_shared/components/sidebar/labels_select_widget/labels_select_root.vue';
import { LabelType } from '~/vue_shared/components/sidebar/labels_select_widget/constants';

export default {
  components: {
    LabelsSelectWidget,
  },
  variant: DropdownVariant.Sidebar,
  inject: ['allowLabelEdit', 'iid', 'fullPath', 'issuableType', 'projectIssuesPath'],
  data() {
    return {
      LabelType,
    };
  },
};
</script>

<template>
  <labels-select-widget
    class="block labels js-labels-block"
    :iid="iid"
    :full-path="fullPath"
    :allow-label-remove="allowLabelEdit"
    :allow-multiselect="true"
    :footer-create-label-title="__('Create project label')"
    :footer-manage-label-title="__('Manage project labels')"
    :labels-create-title="__('Create project label')"
    :labels-filter-base-path="projectIssuesPath"
    :variant="$options.variant"
    :issuable-type="issuableType"
    workspace-type="project"
    :attr-workspace-path="fullPath"
    :label-create-type="LabelType.project"
    data-qa-selector="labels_block"
  >
    {{ __('None') }}
  </labels-select-widget>
</template>

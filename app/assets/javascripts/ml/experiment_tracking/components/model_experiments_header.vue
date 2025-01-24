<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlIcon,
  GlModalDirective,
} from '@gitlab/ui';
import { n__, s__ } from '~/locale';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { MLFLOW_USAGE_MODAL_ID } from '../routes/experiments/index/constants';
import MlflowModal from '../routes/experiments/index/components/mlflow_usage_modal.vue';

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    GlIcon,
    MlflowModal,
    TitleArea,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    pageTitle: {
      type: String,
      required: true,
    },
    count: {
      type: Number,
      required: true,
    },
  },
  computed: {
    mlflowUsageModalItem() {
      return {
        text: this.$options.i18n.importMlflow,
      };
    },
    modelsCountLabel() {
      return n__('MlModelRegistry|%d experiment', 'MlModelRegistry|%d experiments', this.count);
    },
  },
  i18n: {
    createTitle: s__('MlModelRegistry|Create'),
    importMlflow: s__('MlModelRegistry|Create experiments using MLflow'),
  },
  mlflowModalId: MLFLOW_USAGE_MODAL_ID,
};
</script>

<template>
  <title-area>
    <template #title>
      <div class="gl-flex gl-grow gl-items-center">
        <span class="gl-inline-flex gl-items-center gl-gap-3" data-testid="page-heading">
          {{ pageTitle }}
          <slot></slot>
        </span>
      </div>
    </template>
    <template #metadata-models-count>
      <div class="detail-page-header-body gl-flex-wrap gl-gap-x-2" data-testid="count">
        <gl-icon name="issue-type-test-case" />
        {{ modelsCountLabel }}
      </div>
    </template>
    <template #right-actions>
      <gl-disclosure-dropdown
        :toggle-text="$options.i18n.createTitle"
        toggle-class="gl-w-full"
        data-testid="create-dropdown"
        variant="confirm"
        category="primary"
        placement="bottom-end"
      >
        <gl-disclosure-dropdown-group>
          <gl-disclosure-dropdown-item
            v-gl-modal="$options.mlflowModalId"
            data-testid="create-menu-item"
            :item="mlflowUsageModalItem"
          />
        </gl-disclosure-dropdown-group>
        <mlflow-modal />
      </gl-disclosure-dropdown>
    </template>
  </title-area>
</template>

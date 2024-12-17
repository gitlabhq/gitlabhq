<script>
import { GlModal, GlAlert, GlFormInput } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';
import { __, s__ } from '~/locale';

export default {
  i18n: {
    title: __('Are you absolutely sure?'),
    confirmText: __('Enter the following to confirm:'),
    warningListItems: [
      s__(
        'ProjectMaintenance|Open merge requests might fail to merge and require manual rebasing.',
      ),
      s__(
        'ProjectMaintenance|Existing local clones are incompatible with the updated repository and must be re-cloned.',
      ),
      s__(
        'ProjectMaintenance|Pipelines referencing old commit SHAs might break and require reconfiguration.',
      ),
      s__(
        'ProjectMaintenance|Historical tags and branches based on the old commit history might not function correctly.',
      ),
      s__('ProjectMaintenance|Commit signatures are dropped during the rewrite process.'),
    ],
  },
  components: { GlModal, GlAlert, GlFormInput },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    confirmPhrase: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    primaryText: {
      type: String,
      required: true,
    },
    confirmLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      userInput: null,
      modalId: uniqueId('rewrite-history-warning-modal'),
    };
  },
  computed: {
    confirmDisabled() {
      return this.userInput !== this.confirmPhrase;
    },
    modalActionProps() {
      return {
        primary: {
          text: this.primaryText,
          attributes: {
            variant: 'danger',
            disabled: this.confirmDisabled,
            loading: this.confirmLoading,
          },
        },
        cancel: { text: __('Cancel') },
      };
    },
  },
};
</script>

<template>
  <gl-modal
    :visible="visible"
    :no-focus-on-show="true"
    :modal-id="modalId"
    :action-primary="modalActionProps.primary"
    :action-cancel="modalActionProps.cancel"
    @primary.prevent="$emit('confirm')"
    @show="userInput = ''"
    v-on="$listeners"
  >
    <template #modal-title>{{ $options.i18n.title }}</template>
    <div>
      <gl-alert class="gl-mb-5" variant="danger" :dismissible="false">
        <h4 class="gl-alert-title">
          {{ title }}
        </h4>

        <ul class="mb-0">
          <li
            v-for="(item, index) in $options.i18n.warningListItems"
            :key="index"
            data-test-id="warning-item"
          >
            {{ item }}
          </li>
        </ul>

        <slot></slot>
      </gl-alert>

      <p>
        {{ $options.i18n.confirmText }} <code>{{ confirmPhrase }}</code>
      </p>

      <gl-form-input v-model="userInput" autofocus />
    </div>
  </gl-modal>
</template>

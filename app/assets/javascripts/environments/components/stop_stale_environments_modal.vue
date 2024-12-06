<script>
import { GlTooltipDirective, GlModal, GlDatepicker, GlFormGroup } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { stopStaleEnvironments } from '~/rest_api';
import { MIN_STALE_ENVIRONMENT_DATE, MAX_STALE_ENVIRONMENT_DATE } from '../constants';

export default {
  id: 'stop-stale-environments-modal',
  name: 'StopStaleEnvironmentsModal',

  components: {
    GlModal,
    GlDatepicker,
    GlFormGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    projectId: {
      default: '',
    },
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  modalProps: {
    primary: {
      text: s__('Environments|Clean up'),
    },
    cancel: {
      text: __('Cancel'),
    },
    dateRange: {
      minDate: MIN_STALE_ENVIRONMENT_DATE, // 10 years ago
      maxDate: MAX_STALE_ENVIRONMENT_DATE,
    },
  },

  data() {
    return {
      stopEnvironmentsBefore: MAX_STALE_ENVIRONMENT_DATE,
    };
  },

  methods: {
    onSubmit() {
      stopStaleEnvironments(this.projectId, this.stopEnvironmentsBefore || this.maxDate);
    },
  },
};
</script>

<template>
  <gl-modal
    :action-primary="$options.modalProps.primary"
    :action-cancel="$options.modalProps.cancel"
    :visible="visible"
    :modal-id="modalId"
    :title="s__('Environments|Clean up environments')"
    static
    @primary="onSubmit"
    @change="$emit('change', $event)"
  >
    <p>
      {{
        s__(
          'Environments|Select which environments to clean up. Protected environments are excluded. Learn more about cleaning up environments.',
        )
      }}
    </p>

    <gl-form-group
      :label="s__('Environments|Stop unused environments')"
      :label-description="
        s__('Environments|Stop environments that have not been updated since the specified date:')
      "
      label-for="stop_environments-before"
    >
      <gl-datepicker
        v-model="stopEnvironmentsBefore"
        input-id="stop-environments-before"
        data-testid="stop-environments-before"
        :min-date="$options.modalProps.dateRange.minDate"
        :max-date="$options.modalProps.dateRange.maxDate"
        :default-date="$options.modalProps.dateRange.maxDate"
      />
    </gl-form-group>
  </gl-modal>
</template>

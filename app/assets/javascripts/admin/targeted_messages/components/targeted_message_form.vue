<script>
import { GlButton, GlFormFields, GlFormSelect, GlFormInput } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { s__, __, sprintf } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import csrf from '~/lib/utils/csrf';
import { formatDate } from '~/lib/utils/datetime_utility';

const DATETIME_FORMAT = "yyyy-mm-dd'T'HH:MM";

export default {
  name: 'TargetedMessageForm',
  components: {
    GlButton,
    GlFormFields,
    GlFormSelect,
    GlFormInput,
  },
  props: {
    targetTypes: {
      type: Array,
      required: true,
    },
    formAction: {
      type: String,
      required: true,
    },
    isAddForm: {
      type: Boolean,
      required: true,
    },
    initialTargetType: {
      type: String,
      required: false,
      default: '',
    },
    initialStartsAt: {
      type: String,
      required: false,
      default: '',
    },
    initialEndsAt: {
      type: String,
      required: false,
      default: '',
    },
    maxNamespaceIds: {
      type: Number,
      required: true,
    },
    messagesPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      formValues: {
        targetType: this.initialTargetType,
        startsAt: this.initialStartsAt ? formatDate(this.initialStartsAt, DATETIME_FORMAT) : null,
        endsAt: this.initialEndsAt ? formatDate(this.initialEndsAt, DATETIME_FORMAT) : null,
        namespaceIdsCsvFile: null,
      },
      serverValidations: {},
      isSubmitting: false,
    };
  },
  computed: {
    submitText() {
      return this.isAddForm ? __('Create') : __('Update');
    },
    targetTypeOptions() {
      return [
        { value: '', text: s__('TargetedMessages|Select a target type') },
        ...this.targetTypes,
      ];
    },
    namespaceIdsLimitText() {
      return sprintf(s__('TargetedMessage|Namespace IDs are limited to a maximum of %{limit}.'), {
        limit: this.maxNamespaceIds.toLocaleString(),
      });
    },
    formMethod() {
      return this.isAddForm ? 'post' : 'patch';
    },
    fields() {
      return {
        targetType: {
          label: s__('TargetedMessages|Target Type'),
        },
        namespaceIdsCsvFile: {
          label: s__('TargetedMessages|Upload a csv file for targeted namespaces'),
          description: this.namespaceIdsLimitText,
        },
        startsAt: {
          label: s__('TargetedMessages|Starts at'),
        },
        endsAt: {
          label: s__('TargetedMessages|Ends at'),
        },
      };
    },
  },
  methods: {
    onFileChange(event) {
      const [file] = event.target.files;
      this.formValues.namespaceIdsCsvFile = file;
    },
    async onSubmit() {
      this.serverValidations = {};
      this.isSubmitting = true;

      await this.submitForm();

      this.isSubmitting = false;
    },
    async submitForm() {
      const formData = new FormData();
      formData.append('targeted_message[target_type]', this.formValues.targetType);
      if (this.formValues.startsAt) {
        formData.append(
          'targeted_message[starts_at]',
          new Date(this.formValues.startsAt).toISOString(),
        );
      }
      if (this.formValues.endsAt) {
        formData.append(
          'targeted_message[ends_at]',
          new Date(this.formValues.endsAt).toISOString(),
        );
      }
      if (this.formValues.namespaceIdsCsvFile) {
        formData.append('targeted_message[namespace_ids_csv]', this.formValues.namespaceIdsCsvFile);
      }
      formData.append('authenticity_token', csrf.token);

      try {
        const response = await axios[this.formMethod](this.formAction, formData);

        if (response.data?.redirect_to) {
          visitUrl(response.data.redirect_to);
        } else {
          visitUrl(this.messagesPath);
        }
      } catch (error) {
        if (error.response?.data?.message) {
          this.serverValidations = this.formatServerValidations(error.response.data.message);
        }
      }
    },
    formatServerValidations(errorMessages) {
      const fieldNameMapping = {
        target_type: 'targetType',
        starts_at: 'startsAt',
        ends_at: 'endsAt',
        targeted_message_namespaces: 'namespaceIdsCsvFile',
      };

      const fieldLabels = {
        target_type: s__('TargetedMessages|Target Type'),
        starts_at: s__('TargetedMessages|Starts at'),
        ends_at: s__('TargetedMessages|Ends at'),
        targeted_message_namespaces: s__('TargetedMessages|Namespace IDs'),
      };

      return Object.entries(errorMessages).reduce((accumulator, [fieldName, messages]) => {
        const camelCaseFieldName = fieldNameMapping[fieldName];
        const fieldLabel = fieldLabels[fieldName];

        if (!camelCaseFieldName || !fieldLabel || !messages.length) {
          return accumulator;
        }

        return {
          ...accumulator,
          [camelCaseFieldName]: `${fieldLabel} ${messages[0]}`,
        };
      }, {});
    },
  },
  formId: 'targeted-message-form',
};
</script>

<template>
  <form :id="$options.formId" @submit.prevent="onSubmit">
    <gl-form-fields
      v-model="formValues"
      :form-id="$options.formId"
      :fields="fields"
      :server-validations="serverValidations"
    >
      <template #input(targetType)="{ id, value, input }">
        <gl-form-select
          :id="id"
          :value="value"
          :options="targetTypeOptions"
          data-testid="target-type-select"
          @input="input"
        />
      </template>
      <template #input(namespaceIdsCsvFile)="{ id }">
        <input
          :id="id"
          type="file"
          accept=".csv"
          class="form-control"
          data-testid="namespace-ids-csv-input"
          @change="onFileChange"
        />
      </template>
      <template #input(startsAt)>
        <div data-testid="starts-at-field">
          <gl-form-input v-model="formValues.startsAt" type="datetime-local" />
        </div>
      </template>
      <template #input(endsAt)>
        <div data-testid="ends-at-field">
          <gl-form-input v-model="formValues.endsAt" type="datetime-local" />
        </div>
      </template>
    </gl-form-fields>

    <gl-button
      type="submit"
      variant="confirm"
      :loading="isSubmitting"
      data-testid="submit-button"
      class="js-no-auto-disable"
    >
      {{ submitText }}
    </gl-button>
  </form>
</template>

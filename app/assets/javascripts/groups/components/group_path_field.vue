<script>
import { GlFormInputGroup, GlFormInput, GlInputGroupText } from '@gitlab/ui';
import { debounce } from 'lodash';

import { getGroupPathAvailability } from '~/rest_api';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';

const DEBOUNCE_DURATION = 1000;

export default {
  i18n: {
    placeholder: __('my-awesome-group'),
    apiErrorMessage: __(
      'An error occurred while checking group path. Please refresh and try again.',
    ),
  },
  inputWidth: { md: 'lg' },
  components: { GlFormInputGroup, GlFormInput, GlInputGroupText },
  props: {
    basePath: {
      type: String,
      required: true,
    },
    id: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: true,
    },
    state: {
      type: Boolean,
      required: false,
      default: null,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      suggestedPath: '',
      initialValue: this.value,
      activeApiRequestAbortController: null,
    };
  },
  watch: {
    value(newValue) {
      // To prevent an infinite loop, skip validation when `value` prop
      // is updated to the path suggested by the API call.
      // We only want to validate the path if the new value is user input.
      if (newValue === this.suggestedPath) {
        return;
      }

      this.debouncedValidatePath();
    },
    selectedGroup() {
      this.debouncedValidatePath();
    },
  },
  created() {
    const validatePath = async () => {
      if (this.isEditing && this.value === this.initialValue) return;

      this.suggestedPath = '';

      try {
        const {
          exists,
          suggests: [suggestedPath],
        } = await this.checkPathAvailability();

        this.suggestedPath = suggestedPath;

        if (exists) {
          this.$emit('input-suggested-path', suggestedPath);
          this.$emit('state-change', false);
        } else {
          this.$emit('state-change', true);
        }
      } catch (error) {
        // Do nothing, error handled in `checkPathAvailability`
      }
    };

    this.debouncedValidatePath = debounce(validatePath, DEBOUNCE_DURATION);
  },
  methods: {
    async checkPathAvailability() {
      if (!this.value) return Promise.reject();

      this.$emit('loading-change', true);

      if (this.activeApiRequestAbortController !== null) {
        this.activeApiRequestAbortController.abort();
      }

      this.activeApiRequestAbortController = new AbortController();

      try {
        const {
          data: { exists, suggests },
        } = await getGroupPathAvailability(
          this.value,
          this.selectedGroup ? this.selectedGroup.id : null,
          {
            signal: this.activeApiRequestAbortController.signal,
          },
        );

        this.$emit('loading-change', false);

        if (exists && !suggests.length) {
          createAlert({
            message: this.$options.i18n.apiErrorMessage,
          });

          return Promise.reject();
        }

        return Promise.resolve({ exists, suggests });
      } catch (error) {
        if (!axios.isCancel(error)) {
          this.$emit('loading-change', false);

          createAlert({
            message: this.$options.i18n.apiErrorMessage,
          });
        }

        return Promise.reject();
      }
    },
    handlePathInput(value) {
      this.$emit('input', value);
    },
  },
};
</script>

<template>
  <gl-form-input-group>
    <template #prepend>
      <gl-input-group-text class="group-root-path">
        {{ basePath }}
      </gl-input-group-text>
    </template>
    <gl-form-input
      :id="id"
      class="gl-field-error-ignore !gl-h-auto"
      :value="value"
      :placeholder="$options.i18n.placeholder"
      :state="state"
      :width="$options.inputWidth"
      @input="handlePathInput"
      @blur="$emit('blur', $event)"
      @invalid="$emit('invalid', $event)"
    />
  </gl-form-input-group>
</template>

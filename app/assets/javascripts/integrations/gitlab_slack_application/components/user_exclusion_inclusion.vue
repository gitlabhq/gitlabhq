<script>
import { GlButton, GlFormCheckbox, GlAlert, GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'UserExclusionInclusion',
  components: {
    GlButton,
    GlFormCheckbox,
    GlAlert,
    GlCollapsibleListbox,
  },
  props: {
    users: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      inclusionList: [],
      exclusionList: [],
      isGlobalFilter: true,
      isSaving: false,
      successMessage: '',
      errorMessage: '',
    };
  },
  computed: {
    userItems() {
      return this.users.map((user) => ({
        value: user.id,
        text: `${user.name} (@${user.username})`,
      }));
    },
  },
  methods: {
    async saveConfiguration() {
      try {
        this.isSaving = true;
        this.errorMessage = '';

        // TODO: Replace with actual API call when backend is implemented

        this.successMessage = __('Configuration saved successfully!');
        setTimeout(() => {
          this.successMessage = '';
        }, 3000);
      } catch (error) {
        this.errorMessage = __('Failed to save configuration');
      } finally {
        this.isSaving = false;
      }
    },
    resetForm() {
      this.inclusionList = [];
      this.exclusionList = [];
      this.isGlobalFilter = true;
      this.successMessage = '';
      this.errorMessage = '';
    },
  },
};
</script>

<template>
  <div class="slack-user-filter gl-mt-5">
    <h3 class="gl-mb-3 gl-font-bold">{{ __('Configure Users for Slack Notifications') }}</h3>

    <p class="gl-mb-4 gl-text-gray-700">
      {{
        __('Select which users should be included or excluded from triggering Slack notifications.')
      }}
    </p>

    <div class="gl-mb-5">
      <label class="gl-form-label gl-font-bold">{{ __('Include Users') }}</label>
      <p class="gl-mb-2 gl-text-sm gl-text-gray-600">
        {{ __('Only these users will trigger Slack notifications') }}
      </p>
      <gl-collapsible-listbox
        v-model="inclusionList"
        :items="userItems"
        multiple
        block
        searchable
        :toggle-text="__('Select users to include...')"
      />
    </div>

    <div class="gl-mb-5">
      <label class="gl-form-label gl-font-bold">{{ __('Exclude Users') }}</label>
      <p class="gl-mb-2 gl-text-sm gl-text-gray-600">
        {{ __('These users will NOT trigger Slack notifications') }}
      </p>
      <gl-collapsible-listbox
        v-model="exclusionList"
        :items="userItems"
        multiple
        block
        searchable
        :toggle-text="__('Select users to exclude...')"
      />
    </div>

    <div class="gl-mb-5">
      <gl-form-checkbox v-model="isGlobalFilter">
        {{ __('Apply filter globally to all notification events') }}
      </gl-form-checkbox>
      <p class="gl-text-sm gl-text-gray-600">
        {{ __('If unchecked, configure different filters for different event types') }}
      </p>
    </div>

    <div class="gl-mt-5">
      <gl-button
        data-testid="save-button"
        variant="confirm"
        :loading="isSaving"
        @click="saveConfiguration"
      >
        {{ __('Save Configuration') }}
      </gl-button>
      <gl-button data-testid="reset-button" variant="default" class="gl-ml-2" @click="resetForm">
        {{ __('Reset') }}
      </gl-button>
    </div>

    <gl-alert
      v-if="successMessage"
      data-testid="success-alert"
      variant="success"
      :dismissible="true"
      class="gl-mt-3"
      @dismiss="successMessage = ''"
    >
      {{ successMessage }}
    </gl-alert>
    <gl-alert
      v-if="errorMessage"
      data-testid="error-alert"
      variant="danger"
      :dismissible="true"
      class="gl-mt-3"
      @dismiss="errorMessage = ''"
    >
      {{ errorMessage }}
    </gl-alert>
  </div>
</template>

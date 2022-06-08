<script>
import { GlFormGroup, GlFormInput, GlFormInputGroup, GlInputGroupText } from '@gitlab/ui';
import { debounce } from 'lodash';

import { s__, __ } from '~/locale';
import { getGroupPathAvailability } from '~/rest_api';
import { createAlert } from '~/flash';
import { slugify } from '~/lib/utils/text_utility';
import axios from '~/lib/utils/axios_utils';
import { helpPagePath } from '~/helpers/help_page_helper';

const DEBOUNCE_DURATION = 1000;

export default {
  i18n: {
    inputs: {
      name: {
        label: s__('Groups|Group name'),
        placeholder: __('My awesome group'),
        description: s__(
          'Groups|Must start with letter, digit, emoji, or underscore. Can also contain periods, dashes, spaces, and parentheses.',
        ),
        invalidFeedback: s__('Groups|Enter a descriptive name for your group.'),
      },
      path: {
        label: s__('Groups|Group URL'),
        placeholder: __('my-awesome-group'),
        invalidFeedbackInvalidPattern: s__(
          'GroupSettings|Choose a group path that does not start with a dash or end with a period. It can also contain alphanumeric characters and underscores.',
        ),
        invalidFeedbackPathUnavailable: s__(
          'Groups|Group path is unavailable. Path has been replaced with a suggested available path.',
        ),
        validFeedback: s__('Groups|Group path is available.'),
      },
    },
    apiLoadingMessage: s__('Groups|Checking group URL availability...'),
    apiErrorMessage: __(
      'An error occurred while checking group path. Please refresh and try again.',
    ),
  },
  nameInputSize: { md: 'lg' },
  changingGroupPathHelpPagePath: helpPagePath('user/group/index', {
    anchor: 'change-a-groups-path',
  }),
  mattermostDataBindName: 'create_chat_team',
  components: { GlFormGroup, GlFormInput, GlFormInputGroup, GlInputGroupText },
  inject: ['fields', 'basePath', 'mattermostEnabled'],
  data() {
    return {
      name: this.fields.name.value,
      path: this.fields.path.value,
      apiSuggestedPath: '',
      apiLoading: false,
      nameFeedbackState: null,
      pathFeedbackState: null,
      pathInvalidFeedback: null,
      activeApiRequestAbortController: null,
    };
  },
  computed: {
    computedPath() {
      return this.apiSuggestedPath || this.path;
    },
    pathDescription() {
      return this.apiLoading ? this.$options.i18n.apiLoadingMessage : '';
    },
  },
  watch: {
    name: [
      function updatePath(newName) {
        this.nameFeedbackState = null;
        this.pathFeedbackState = null;
        this.apiSuggestedPath = '';
        this.path = slugify(newName);
      },
      debounce(async function updatePathWithSuggestions() {
        try {
          const { suggests } = await this.checkPathAvailability();

          const [suggestedPath] = suggests;

          this.apiSuggestedPath = suggestedPath;
        } catch (error) {
          // Do nothing, error handled in `checkPathAvailability`
        }
      }, DEBOUNCE_DURATION),
    ],
  },
  methods: {
    async checkPathAvailability() {
      if (!this.path) return Promise.reject();

      this.apiLoading = true;

      if (this.activeApiRequestAbortController !== null) {
        this.activeApiRequestAbortController.abort();
      }

      this.activeApiRequestAbortController = new AbortController();

      try {
        const {
          data: { exists, suggests },
        } = await getGroupPathAvailability(this.path, this.fields.parentId?.value, {
          signal: this.activeApiRequestAbortController.signal,
        });

        if (exists) {
          if (suggests.length) {
            return Promise.resolve({ exists, suggests });
          }

          createAlert({
            message: this.$options.i18n.apiErrorMessage,
          });

          return Promise.reject();
        }

        return Promise.resolve({ exists, suggests });
      } catch (error) {
        if (!axios.isCancel(error)) {
          createAlert({
            message: this.$options.i18n.apiErrorMessage,
          });
        }

        return Promise.reject();
      } finally {
        this.apiLoading = false;
      }
    },
    handlePathInput(value) {
      this.pathFeedbackState = null;
      this.apiSuggestedPath = '';
      this.path = value;
      this.debouncedValidatePath();
    },
    debouncedValidatePath: debounce(async function validatePath() {
      try {
        const {
          exists,
          suggests: [suggestedPath],
        } = await this.checkPathAvailability();

        if (exists) {
          this.apiSuggestedPath = suggestedPath;
          this.pathInvalidFeedback = this.$options.i18n.inputs.path.invalidFeedbackPathUnavailable;
          this.pathFeedbackState = false;
        } else {
          this.pathFeedbackState = true;
        }
      } catch (error) {
        // Do nothing, error handled in `checkPathAvailability`
      }
    }, DEBOUNCE_DURATION),
    handleInvalidName(event) {
      event.preventDefault();

      this.nameFeedbackState = false;
    },
    handleInvalidPath(event) {
      event.preventDefault();

      this.pathInvalidFeedback = this.$options.i18n.inputs.path.invalidFeedbackInvalidPattern;
      this.pathFeedbackState = false;
    },
  },
};
</script>

<template>
  <div>
    <input
      :id="fields.parentId.id"
      type="hidden"
      :name="fields.parentId.name"
      :value="fields.parentId.value"
    />
    <gl-form-group
      :label="$options.i18n.inputs.name.label"
      :description="$options.i18n.inputs.name.description"
      :label-for="fields.name.id"
      :invalid-feedback="$options.i18n.inputs.name.invalidFeedback"
      :state="nameFeedbackState"
    >
      <gl-form-input
        :id="fields.name.id"
        v-model="name"
        class="gl-field-error-ignore"
        required
        :name="fields.name.name"
        :placeholder="$options.i18n.inputs.name.placeholder"
        data-qa-selector="group_name_field"
        :size="$options.nameInputSize"
        :state="nameFeedbackState"
        @invalid="handleInvalidName"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.inputs.path.label"
      :label-for="fields.path.id"
      :description="pathDescription"
      :state="pathFeedbackState"
      :valid-feedback="$options.i18n.inputs.path.validFeedback"
      :invalid-feedback="pathInvalidFeedback"
    >
      <gl-form-input-group>
        <template #prepend>
          <gl-input-group-text class="group-root-path">{{ basePath }}</gl-input-group-text>
        </template>
        <gl-form-input
          :id="fields.path.id"
          class="gl-field-error-ignore"
          :name="fields.path.name"
          :value="computedPath"
          :placeholder="$options.i18n.inputs.path.placeholder"
          :maxlength="fields.path.maxLength"
          :pattern="fields.path.pattern"
          :state="pathFeedbackState"
          :size="$options.nameInputSize"
          required
          data-qa-selector="group_path_field"
          :data-bind-in="mattermostEnabled ? $options.mattermostDataBindName : null"
          @input="handlePathInput"
          @invalid="handleInvalidPath"
        />
      </gl-form-input-group>
    </gl-form-group>
  </div>
</template>

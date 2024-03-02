<script>
import { GlForm, GlFormFields, GlButton } from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/dist/utils';
import { __, s__, sprintf } from '~/locale';
import { slugify } from '~/lib/utils/text_utility';
import VisibilityLevelRadioButtons from '~/visibility_level/components/visibility_level_radio_buttons.vue';
import {
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  GROUP_VISIBILITY_LEVEL_DESCRIPTIONS,
} from '~/visibility_level/constants';
import { restrictedVisibilityLevelsMessage } from '~/visibility_level/utils';
import { FORM_FIELD_NAME, FORM_FIELD_PATH, FORM_FIELD_VISIBILITY_LEVEL } from '../constants';
import GroupPathField from './group_path_field.vue';

export default {
  name: 'NewGroupForm',
  components: {
    GlForm,
    GlFormFields,
    GlButton,
    GroupPathField,
    VisibilityLevelRadioButtons,
  },
  i18n: {
    cancel: __('Cancel'),
    submitButtonText: __('Create group'),
  },
  GROUP_VISIBILITY_LEVEL_DESCRIPTIONS,
  formId: 'organization-new-group-form',
  props: {
    loading: {
      type: Boolean,
      required: true,
    },
    basePath: {
      type: String,
      required: true,
    },
    cancelPath: {
      type: String,
      required: true,
    },
    pathMaxlength: {
      required: true,
      type: Number,
    },
    pathPattern: {
      required: true,
      type: String,
    },
    availableVisibilityLevels: {
      type: Array,
      required: true,
    },
    restrictedVisibilityLevels: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      hasPathBeenManuallySet: false,
      isPathLoading: false,
      formValues: {
        [FORM_FIELD_NAME]: '',
        [FORM_FIELD_PATH]: '',
        [FORM_FIELD_VISIBILITY_LEVEL]: VISIBILITY_LEVEL_PRIVATE_INTEGER,
      },
    };
  },
  computed: {
    fields() {
      return {
        [FORM_FIELD_NAME]: {
          label: s__('Groups|Group name'),
          validators: [
            formValidators.required(s__('Groups|Enter a descriptive name for your group.')),
          ],
          inputAttrs: {
            width: { md: 'lg' },
            placeholder: __('My awesome group'),
          },
          groupAttrs: {
            description: s__(
              'Groups|Must start with letter, digit, emoji, or underscore. Can also contain periods, dashes, spaces, and parentheses.',
            ),
          },
        },
        [FORM_FIELD_PATH]: {
          label: s__('Groups|Group URL'),
          validators: [
            formValidators.required(s__('Groups|Enter a path for your group.')),
            formValidators.factory(
              sprintf(s__('GroupSettings|Group path cannot be longer than %{length} characters.'), {
                length: this.pathMaxlength,
              }),
              (val) => val.length <= this.pathMaxlength,
            ),
            formValidators.factory(
              s__(
                'GroupSettings|Choose a group path that does not start with a dash or end with a period. It can also contain alphanumeric characters and underscores.',
              ),
              (val) => {
                return new RegExp(`^(${this.pathPattern})$`).test(val);
              },
            ),
          ],
          groupAttrs: {
            description: this.isPathLoading
              ? s__('Groups|Checking group URL availability...')
              : null,
          },
        },
        [FORM_FIELD_VISIBILITY_LEVEL]: {
          label: __('Visibility level'),
          groupAttrs: {
            description: restrictedVisibilityLevelsMessage({
              availableVisibilityLevels: this.availableVisibilityLevels,
              restrictedVisibilityLevels: this.restrictedVisibilityLevels,
            }),
          },
        },
      };
    },
  },
  watch: {
    [`formValues.${FORM_FIELD_NAME}`](newName) {
      if (this.hasPathBeenManuallySet) {
        return;
      }

      this.formValues[FORM_FIELD_PATH] = slugify(newName);
    },
  },
  methods: {
    onPathInput(event, formFieldsInputEvent) {
      formFieldsInputEvent(event);
      this.hasPathBeenManuallySet = true;
    },
    onPathLoading(value) {
      this.isPathLoading = value;
    },
  },
};
</script>

<template>
  <gl-form :id="$options.formId">
    <gl-form-fields
      v-model="formValues"
      :form-id="$options.formId"
      :fields="fields"
      @submit="$emit('submit', formValues)"
    >
      <template #input(path)="{ id, value, validation, input, blur }">
        <group-path-field
          :id="id"
          :value="value"
          :state="validation.state"
          :base-path="basePath"
          @input="onPathInput($event, input)"
          @input-suggested-path="input"
          @blur="blur"
          @loading-change="onPathLoading"
        />
      </template>
      <template #input(visibilityLevel)="{ value, input }">
        <visibility-level-radio-buttons
          :checked="value"
          :visibility-levels="availableVisibilityLevels"
          :visibility-level-descriptions="$options.GROUP_VISIBILITY_LEVEL_DESCRIPTIONS"
          @input="input"
        />
      </template>
    </gl-form-fields>
    <div class="gl-display-flex gl-gap-3">
      <gl-button
        type="submit"
        variant="confirm"
        :loading="loading"
        class="js-no-auto-disable"
        data-testid="submit-button"
        >{{ $options.i18n.submitButtonText }}</gl-button
      >
      <gl-button :href="cancelPath">{{ $options.i18n.cancel }}</gl-button>
    </div>
  </gl-form>
</template>

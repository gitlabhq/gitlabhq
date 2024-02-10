<script>
import { GlForm, GlFormFields, GlButton } from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/dist/utils';
import { __, s__, sprintf } from '~/locale';
import { FORM_FIELD_PATH } from '../constants';
import GroupPathField from './group_path_field.vue';

export default {
  name: 'NewGroupForm',
  components: {
    GlForm,
    GlFormFields,
    GlButton,
    GroupPathField,
  },
  i18n: {
    cancel: __('Cancel'),
    submitButtonText: __('Create group'),
  },
  formId: 'organization-new-group-form',
  props: {
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
  },
  data() {
    return {
      hasPathBeenManuallySet: false,
      isPathLoading: false,
      formValues: {
        [FORM_FIELD_PATH]: '',
      },
    };
  },
  computed: {
    fields() {
      return {
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
      };
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
    </gl-form-fields>
    <div class="gl-display-flex gl-gap-3">
      <gl-button
        type="submit"
        variant="confirm"
        class="js-no-auto-disable"
        data-testid="submit-button"
        >{{ $options.i18n.submitButtonText }}</gl-button
      >
      <gl-button :href="cancelPath">{{ $options.i18n.cancel }}</gl-button>
    </div>
  </gl-form>
</template>

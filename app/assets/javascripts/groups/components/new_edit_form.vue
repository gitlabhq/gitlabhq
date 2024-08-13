<script>
import { GlForm, GlFormFields, GlButton, GlLink, GlAlert, GlSprintf } from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/dist/utils';
import { __, s__, sprintf } from '~/locale';
import { slugify } from '~/lib/utils/text_utility';
import VisibilityLevelRadioButtons from '~/visibility_level/components/visibility_level_radio_buttons.vue';
import { GROUP_VISIBILITY_LEVEL_DESCRIPTIONS } from '~/visibility_level/constants';
import { restrictedVisibilityLevelsMessage } from '~/visibility_level/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import {
  FORM_FIELD_NAME,
  FORM_FIELD_PATH,
  FORM_FIELD_ID,
  FORM_FIELD_VISIBILITY_LEVEL,
} from '../constants';
import GroupPathField from './group_path_field.vue';

export default {
  name: 'NewEditForm',
  components: {
    GlForm,
    GlFormFields,
    GlButton,
    GlLink,
    GlAlert,
    GlSprintf,
    GroupPathField,
    VisibilityLevelRadioButtons,
    HelpPageLink,
  },
  i18n: {
    cancel: __('Cancel'),
    warningForUsingDotInName: s__(
      'Groups|Your group name must not contain a period if you intend to use SCIM integration, as it can lead to errors.',
    ),
    warningForChangingUrl: s__(
      'Groups|Changing group URL can have unintended side effects. %{linkStart}Learn more%{linkEnd}.',
    ),
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
    submitButtonText: {
      type: String,
      required: false,
      default: __('Create group'),
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
    initialFormValues: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      hasPathBeenManuallySet: this.initialFormValues[FORM_FIELD_PATH],
      isPathLoading: false,
      formValues: this.initialFormValues,
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
        ...(this.isEditing
          ? {
              [FORM_FIELD_ID]: {
                label: s__('Groups|Group ID'),
                groupAttrs: {
                  class: 'gl-w-full',
                },
                inputAttrs: {
                  class: 'gl-md-form-input-lg',
                  disabled: true,
                },
              },
            }
          : {}),
        [FORM_FIELD_VISIBILITY_LEVEL]: {
          label: __('Visibility level'),
          labelDescription: {
            text: __('Who will be able to see this group?'),
            linkText: __('Learn more'),
            linkHref: helpPagePath('user/public_access'),
          },
          groupAttrs: {
            // eslint-disable-next-line @gitlab/require-i18n-strings
            'data-testid': `${FORM_FIELD_VISIBILITY_LEVEL}-group`,
            description: restrictedVisibilityLevelsMessage({
              availableVisibilityLevels: this.availableVisibilityLevels,
              restrictedVisibilityLevels: this.restrictedVisibilityLevels,
            }),
          },
        },
      };
    },
    isEditing() {
      return Boolean(this.initialFormValues[FORM_FIELD_ID]);
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
      <template #after(name)>
        <gl-alert
          class="gl-mb-5"
          :dismissible="false"
          variant="warning"
          data-testid="dot-in-path-alert"
        >
          {{ $options.i18n.warningForUsingDotInName }}
        </gl-alert>
      </template>
      <template #input(path)="{ id, value, validation, input, blur }">
        <group-path-field
          :id="id"
          :value="value"
          :state="validation.state"
          :base-path="basePath"
          :is-editing="isEditing"
          @input="onPathInput($event, input)"
          @input-suggested-path="input"
          @blur="blur"
          @loading-change="onPathLoading"
        />
      </template>
      <template v-if="isEditing" #after(path)>
        <gl-alert
          class="gl-mb-5"
          :dismissible="false"
          variant="warning"
          data-testid="changing-url-alert"
        >
          <gl-sprintf :message="$options.i18n.warningForChangingUrl">
            <template #link="{ content }">
              <help-page-link href="user/group/manage" anchor="change-a-groups-path">{{
                content
              }}</help-page-link>
            </template>
          </gl-sprintf>
        </gl-alert>
      </template>
      <template #input(visibilityLevel)="{ value, input }">
        <visibility-level-radio-buttons
          :checked="value"
          :visibility-levels="availableVisibilityLevels"
          :visibility-level-descriptions="$options.GROUP_VISIBILITY_LEVEL_DESCRIPTIONS"
          @input="input"
        />
      </template>
      <template #group(visibilityLevel)-label-description>
        {{ fields.visibilityLevel.labelDescription.text }}
        <gl-link :href="fields.visibilityLevel.labelDescription.linkHref">{{
          fields.visibilityLevel.labelDescription.linkText
        }}</gl-link
        >.
      </template>
    </gl-form-fields>
    <div class="gl-flex gl-gap-3">
      <gl-button
        type="submit"
        variant="confirm"
        :loading="loading"
        class="js-no-auto-disable"
        data-testid="submit-button"
        >{{ submitButtonText }}</gl-button
      >
      <gl-button :href="cancelPath">{{ $options.i18n.cancel }}</gl-button>
    </div>
  </gl-form>
</template>

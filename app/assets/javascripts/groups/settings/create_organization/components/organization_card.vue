<script>
import {
  GlAvatar,
  GlAvatarLabeled,
  GlCard,
  GlIcon,
  GlButton,
  GlForm,
  GlFormFields,
  GlTooltipDirective,
} from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { formValidators } from '@gitlab/ui/src/utils';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { VISIBILITY_TYPE_ICON, ORGANIZATION_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { isDefaultOrganization } from '~/organizations/shared/utils';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import { PASSWORD_MANAGER_IGNORE_ATTRS } from '~/lib/utils/forms';
import { FORM_FIELD_NAME } from '~/organizations/shared/constants';
import { s__ } from '~/locale';

export default {
  name: 'OrganizationCard',
  AVATAR_SHAPE_OPTION_RECT,
  PASSWORD_MANAGER_IGNORE_ATTRS,
  formFields: {
    [FORM_FIELD_NAME]: {
      label: s__('Organization|Organization name'),
      validators: [formValidators.required(s__('Organization|Organization name is required.'))],
      groupAttrs: {
        labelSrOnly: true,
        class: 'gl-m-0',
      },
      inputAttrs: {
        placeholder: s__('Organization|My organization'),
        autofocus: true,
        ...PASSWORD_MANAGER_IGNORE_ATTRS,
      },
    },
  },
  i18n: {
    editOrganizationName: s__('Organization|Edit organization name'),
    saveOrganizationName: s__('Organization|Save organization name'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAvatar,
    GlAvatarLabeled,
    GlCard,
    GlIcon,
    GlButton,
    GlForm,
    GlFormFields,
  },
  mixins: [glSlotsMixin],
  props: {
    organization: {
      type: Object,
      required: true,
    },
    allowEditMode: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['update'],
  data() {
    return {
      isEditMode: false,
      formValues: {
        [FORM_FIELD_NAME]: this.organization.name,
      },
      formId: uniqueId('organization-name-form-'),
    };
  },
  computed: {
    organizationName() {
      return this.organization.name;
    },
    organizationAvatarUrl() {
      return this.organization.avatarUrl;
    },
    bodyClass() {
      const baseClasses = ['gl-bg-transparent'];

      if (this.glSlots().default) {
        return baseClasses;
      }

      return [...baseClasses, 'gl-hidden'];
    },
    headerClass() {
      return {
        'gl-pb-2': !this.glSlots().default,
      };
    },
    visibility() {
      return this.organization.visibility;
    },
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.visibility];
    },
    visibilityTooltip() {
      return ORGANIZATION_VISIBILITY_TYPE[this.visibility];
    },
    isDefaultOrganization() {
      return isDefaultOrganization(this.organization);
    },
  },
  methods: {
    getIdFromGraphQLId,
    onEditClick() {
      this.isEditMode = true;
    },
    onSaveOrganizationName() {
      this.$emit('update', {
        ...this.organization,
        name: this.formValues[FORM_FIELD_NAME],
      });

      this.isEditMode = false;
    },
  },
};
</script>

<template>
  <gl-card
    v-if="isDefaultOrganization"
    class="gl-border gl-h-full gl-bg-transparent"
    :header-class="headerClass"
    :body-class="bodyClass"
  >
    <template #header>
      <div class="gl-pt-3 gl-text-center">
        <p class="gl-m-0 gl-text-sm">{{ s__('Organization|Other top-level groups') }}</p>
      </div>
    </template>
    <div class="gl-relative gl-h-full">
      <slot :is-default-organization="true"></slot>
    </div>
  </gl-card>
  <gl-card v-else class="gl-h-full" :header-class="headerClass" :body-class="bodyClass">
    <template #header>
      <div class="gl-flex gl-justify-between">
        <div v-if="allowEditMode && isEditMode" class="gl-flex gl-gap-3">
          <gl-avatar
            :entity-id="getIdFromGraphQLId(organization.id)"
            :entity-name="organizationName"
            :shape="$options.AVATAR_SHAPE_OPTION_RECT"
            :size="32"
            :src="organizationAvatarUrl"
          />
          <gl-form :id="formId" class="gl-flex gl-items-start gl-gap-2">
            <gl-form-fields
              v-model="formValues"
              :form-id="formId"
              :fields="$options.formFields"
              @submit="onSaveOrganizationName"
            />
            <gl-button
              v-gl-tooltip="$options.i18n.saveOrganizationName"
              :aria-label="$options.i18n.saveOrganizationName"
              class="gl-mt-2"
              type="submit"
              icon="check-sm"
              size="small"
              data-testid="save-organization-name-button"
              category="tertiary"
            />
          </gl-form>
        </div>
        <gl-avatar-labeled
          v-else
          class="gl-flex"
          :label="organizationName"
          :entity-id="getIdFromGraphQLId(organization.id)"
          :entity-name="organizationName"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
          :size="32"
          :src="organizationAvatarUrl"
        >
          <template v-if="allowEditMode" #meta>
            <div class="gl-p-1">
              <gl-button
                v-if="!isEditMode"
                v-gl-tooltip="$options.i18n.editOrganizationName"
                :aria-label="$options.i18n.editOrganizationName"
                icon="pencil"
                size="small"
                category="tertiary"
                data-testid="edit-organization-name-button"
                @click="onEditClick"
              />
            </div>
          </template>
        </gl-avatar-labeled>
        <gl-icon
          v-gl-tooltip="visibilityTooltip"
          class="gl-mt-3 gl-shrink-0"
          :name="visibilityIcon"
          variant="subtle"
          data-testid="organization-visibility"
        />
      </div>
    </template>
    <div class="gl-relative gl-h-full">
      <slot :is-default-organization="false"></slot>
    </div>
  </gl-card>
</template>

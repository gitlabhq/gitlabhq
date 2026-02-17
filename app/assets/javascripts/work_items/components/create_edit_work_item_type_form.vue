<script>
import {
  GlModal,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlButton,
  GlIcon,
  GlAlert,
  GlFormRadio,
  GlFormRadioGroup,
} from '@gitlab/ui';
import {
  WI_TYPE_ICON_SELECTION_SET_SCREEN_READER_TEXT_MAP,
  WORK_ITEM_ICON_OPTIONS as ICON_OPTIONS,
  NAME_TO_ICON_MAP,
  ICON_NAVIGATION_KEYS,
} from '~/work_items/constants';
import { s__ } from '~/locale';

export default {
  name: 'CreateEditWorkItemTypeForm',
  components: {
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlButton,
    GlIcon,
    GlAlert,
    GlFormRadio,
    GlFormRadioGroup,
    GlForm,
  },
  props: {
    isVisible: {
      type: Boolean,
      required: true,
    },
    isEditMode: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemType: {
      type: Object,
      required: false,
      default: null,
    },
  },
  emits: ['save', 'close'],
  data() {
    return {
      form: {
        name: this.workItemType?.name || '',
        iconName: NAME_TO_ICON_MAP[this.workItemType?.name] || ICON_OPTIONS[0],
      },
      errors: {},
      showErrors: false,
      isSubmitting: false,
    };
  },
  computed: {
    modalTitle() {
      return this.isEditMode ? s__('WorkItem|Edit type name and icon') : s__('WorkItem|New type');
    },
    defaultIconName() {
      /** need the icon map because the work item types does not return the correct icon names */
      return NAME_TO_ICON_MAP[this.workItemType?.name] || ICON_OPTIONS[0];
    },
    nameErrorState() {
      return this.showErrors && this.formValidationErrors.name ? false : null;
    },
    formValidationErrors() {
      const errors = {};

      if (!this.form.name?.trim()) {
        errors.name = s__('WorkItem|Name is required');
      }

      return errors;
    },
    isFormValid() {
      return Object.keys(this.formValidationErrors).length === 0;
    },
  },
  watch: {
    workItemType() {
      // Reinitialize form whenever the workItemType prop changes
      this.initializeForm();
    },
    isVisible(newValue) {
      if (newValue) {
        this.initializeForm();
      }
    },
  },
  methods: {
    initializeForm() {
      this.form = {
        name: this.workItemType?.name || '',
        iconName: this.defaultIconName,
      };
      this.showErrors = false;
      this.errors = {};
    },
    async handleSubmit() {
      if (!this.isFormValid) {
        this.showErrors = true;
        this.errors = this.formValidationErrors;
        return;
      }

      this.$emit('close');
    },
    handleCancel() {
      this.initializeForm();
      this.$emit('close');
    },
    handleClose() {
      this.initializeForm();
      this.$emit('close');
    },
    onVisibilityChange(visible) {
      if (visible) {
        this.initializeForm();
      }
    },
    handleIconKeydown(event) {
      const allIconNavigationKeys = [
        ...ICON_NAVIGATION_KEYS.PREVIOUS,
        ...ICON_NAVIGATION_KEYS.NEXT,
        ...ICON_NAVIGATION_KEYS.IGNORE,
      ];

      if (!allIconNavigationKeys.includes(event.key)) {
        return;
      }

      event.preventDefault();

      const currentIndex = ICON_OPTIONS.indexOf(this.form.iconName);
      let newIndex = currentIndex;

      if (ICON_NAVIGATION_KEYS.PREVIOUS.includes(event.key)) {
        newIndex = currentIndex === 0 ? ICON_OPTIONS.length - 1 : currentIndex - 1;
      } else if (ICON_NAVIGATION_KEYS.NEXT.includes(event.key)) {
        newIndex = currentIndex === ICON_OPTIONS.length - 1 ? 0 : currentIndex + 1;
      }

      this.form.iconName = ICON_OPTIONS[newIndex];
      this.focusIcon(newIndex);
    },
    focusIcon(index) {
      this.$nextTick(() => {
        const iconRefs = this.$refs[`icon-${ICON_OPTIONS[index]}`];
        if (iconRefs && iconRefs.length) {
          iconRefs[0].focus();
        }
      });
    },
  },
  WI_TYPE_ICON_SELECTION_SET_SCREEN_READER_TEXT_MAP,
  ICON_OPTIONS,
};
</script>

<template>
  <gl-modal
    :visible="isVisible"
    :title="modalTitle"
    size="sm"
    modal-id="create-edit-work-item-type-modal"
    @hidden="handleClose"
    @change="onVisibilityChange"
  >
    <gl-form @submit.prevent="handleSubmit">
      <gl-alert v-if="errors.form" class="gl-mb-4" variant="danger" @dismiss="errors.form = {}">
        {{ errors.form }}
      </gl-alert>

      <div class="gl-flex gl-gap-3">
        <gl-form-group
          :label="s__('WorkItem|Name')"
          label-for="work-item-type-name"
          :state="nameErrorState"
          :invalid-feedback="errors.name"
          class="gl-mb-4 gl-flex-1"
        >
          <gl-form-input
            id="work-item-type-name"
            v-model="form.name"
            :maxlength="48"
            :placeholder="s__('WorkItem|Bug')"
            :state="nameErrorState"
            data-testid="work-item-type-name-input"
            autocomplete="off"
          />
        </gl-form-group>
      </div>

      <gl-form-group class="gl-mb-4">
        <template #label>
          <span id="icon-selection-legend">
            {{ s__('WorkItem|Icon') }}
          </span>
        </template>

        <gl-form-radio-group
          id="work-item-type-icon"
          class="icon-selection-set gl-flex gl-flex-wrap gl-gap-3"
          :checked="form.iconName"
        >
          <div aria-live="polite" aria-atomic="true" class="gl-sr-only">
            {{ $options.WI_TYPE_ICON_SELECTION_SET_SCREEN_READER_TEXT_MAP[form.iconName] }}
          </div>
          <label
            v-for="iconOption in $options.ICON_OPTIONS"
            :ref="`icon-${iconOption}`"
            :key="iconOption"
            class="gl-flex gl-cursor-pointer gl-items-center gl-rounded-lg gl-p-3 gl-transition-colors"
            :class="form.iconName === iconOption ? 'selected-icon' : ''"
            :style="
              form.iconName === iconOption
                ? { backgroundColor: 'var(--gl-control-background-color-selected-default)' }
                : { backgroundColor: 'var(--gl-control-background-color-default)' }
            "
            :aria-label="$options.WI_TYPE_ICON_SELECTION_SET_SCREEN_READER_TEXT_MAP[iconOption]"
            role="radio"
            :aria-checked="form.iconName === iconOption"
            :tabindex="form.iconName === iconOption ? 0 : -1"
            @click="form.iconName = iconOption"
            @keydown="handleIconKeydown"
          >
            <gl-form-radio
              :value="iconOption"
              data-testid="ci-variable-visible-radio"
              tabindex="-1"
              class="gl-sr-only"
            />
            <gl-icon
              :name="iconOption"
              :size="16"
              :style="form.iconName === iconOption ? { filter: 'invert(1)' } : {}"
            />
          </label>
        </gl-form-radio-group>
      </gl-form-group>
    </gl-form>

    <template #modal-footer>
      <gl-button data-testid="work-item-type-cancel-button" @click="handleCancel">
        {{ s__('WorkItem|Cancel') }}
      </gl-button>
      <gl-button
        variant="confirm"
        :loading="isSubmitting"
        data-testid="work-item-type-submit-button"
        @click="handleSubmit"
      >
        {{ s__('WorkItem|Save') }}
      </gl-button>
    </template>
  </gl-modal>
</template>

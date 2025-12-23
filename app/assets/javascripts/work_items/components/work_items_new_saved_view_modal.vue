<script>
import {
  GlButton,
  GlModal,
  GlFormTextarea,
  GlIcon,
  GlForm,
  GlFormInput,
  GlFormGroup,
  GlFormRadio,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { SAVED_VIEW_VISIBILITY } from '../constants';

export default {
  name: 'WorkItemsNewSavedViewModal',
  components: {
    GlIcon,
    GlForm,
    GlFormInput,
    GlFormGroup,
    GlFormRadio,
    GlFormTextarea,
    GlButton,
    GlModal,
  },
  i18n: {
    newViewTitle: s__('WorkItem|New view'),
    descriptionValidation: s__('WorkItem|140 characters max'),
    validateTitle: s__('WorkItem|Title is required.'),
    privateView: s__('WorkItem|Only you can see and edit this view.'),
    sharedView: s__(
      'WorkItem|Anyone with access to this project can add the view, and those with the Planner and above roles can edit it.',
    ),
  },
  model: {
    prop: 'show',
    event: 'hide',
  },
  props: {
    show: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['hide'],
  MAX_DESCRIPTION_LENGTH: 140,
  SAVED_VIEW_VISIBILITY,
  data() {
    return {
      savedViewDescription: '',
      savedViewTitle: '',
      isTitleValid: true,
      savedViewVisibility: SAVED_VIEW_VISIBILITY.PRIVATE,
    };
  },
  methods: {
    focusTitleInput() {
      this.$refs.savedViewTitle?.$el.focus();
    },
    validateTitle() {
      this.isTitleValid = Boolean(this.savedViewTitle.trim());
    },
    createSavedView() {
      this.validateTitle();

      if (!this.isTitleValid) {
        return;
      }
      // TODO: Add further logic to create saved view

      this.hideAddNewViewModal();
    },
    resetModal() {
      this.isTitleValid = true;
      this.savedViewTitle = '';
      this.savedViewDescription = '';
      this.savedViewDescription = '';
      this.savedViewVisibility = SAVED_VIEW_VISIBILITY.PRIVATE;
    },
    hideAddNewViewModal() {
      this.$emit('hide', false);
      this.resetModal();
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="create-saved-view-modal"
    modal-class="create-saved-view-modal"
    :aria-label="$options.i18n.newViewTitle"
    :title="$options.i18n.newViewTitle"
    :visible="show"
    body-class="!gl-pb-0"
    size="sm"
    hide-footer
    @shown="focusTitleInput"
    @hide="hideAddNewViewModal"
  >
    <gl-form data-testid="add-new-saved-view-form" @submit.prevent="createSavedView">
      <gl-form-group
        :label="__('Title')"
        label-for="saved-view-title"
        data-testid="saved-view-title"
        :state="isTitleValid"
        :invalid-feedback="$options.i18n.validateTitle"
      >
        <gl-form-input
          id="saved-view-title"
          ref="savedViewTitle"
          v-model="savedViewTitle"
          autocomplete="off"
          autofocus
          :state="isTitleValid"
          @input="isTitleValid = true"
        />
      </gl-form-group>

      <gl-form-group
        :label="__('Description (optional)')"
        :description="$options.i18n.descriptionValidation"
        label-for="saved-view-description"
        data-testid="saved-view-description"
      >
        <gl-form-textarea
          id="saved-view-description"
          v-model="savedViewDescription"
          size="sm"
          :maxlength="$options.MAX_DESCRIPTION_LENGTH"
        />
      </gl-form-group>

      <gl-form-group
        :label="__('Visibility')"
        label-for="saved-view-visibility"
        data-testid="saved-view-visibility"
      >
        <gl-form-radio
          id="saved-view-visibility"
          v-model="savedViewVisibility"
          :checked="savedViewVisibility"
          :value="$options.SAVED_VIEW_VISIBILITY.PRIVATE"
        >
          <span>
            <gl-icon name="lock" class="gl-shrink-0" variant="subtle" />
            {{ s__('WorkItem|Private') }}
          </span>
          <template #help>{{ $options.i18n.privateView }}</template>
        </gl-form-radio>
        <gl-form-radio v-model="savedViewVisibility" :value="$options.SAVED_VIEW_VISIBILITY.SHARED">
          <span>
            <gl-icon name="users" class="gl-shrink-0" variant="subtle" />
            {{ s__('WorkItem|Shared') }}
          </span>
          <template #help>{{ $options.i18n.sharedView }}</template>
        </gl-form-radio>
      </gl-form-group>

      <div class="gl-mb-5 gl-flex gl-justify-end gl-gap-3">
        <gl-button type="button" data-testid="cancel-button" @click="hideAddNewViewModal">
          {{ __('Cancel') }}
        </gl-button>
        <gl-button
          type="submit"
          variant="confirm"
          :disabled="!isTitleValid"
          data-testid="create-view-button"
        >
          {{ s__('WorkItem|Create view') }}
        </gl-button>
      </div>
    </gl-form>
  </gl-modal>
</template>

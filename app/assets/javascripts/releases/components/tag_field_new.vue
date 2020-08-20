<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import FormFieldContainer from './form_field_container.vue';

export default {
  name: 'TagFieldNew',
  components: { GlFormGroup, GlFormInput, RefSelector, FormFieldContainer },
  data() {
    return {
      // Keeps track of whether or not the user has interacted with
      // the input field. This is used to avoid showing validation
      // errors immediately when the page loads.
      isInputDirty: false,
    };
  },
  computed: {
    ...mapState('detail', ['projectId', 'release', 'createFrom']),
    ...mapGetters('detail', ['validationErrors']),
    tagName: {
      get() {
        return this.release.tagName;
      },
      set(tagName) {
        this.updateReleaseTagName(tagName);
      },
    },
    createFromModel: {
      get() {
        return this.createFrom;
      },
      set(createFrom) {
        this.updateCreateFrom(createFrom);
      },
    },
    showTagNameValidationError() {
      return this.isInputDirty && this.validationErrors.isTagNameEmpty;
    },
    tagNameInputId() {
      return uniqueId('tag-name-input-');
    },
    createFromSelectorId() {
      return uniqueId('create-from-selector-');
    },
  },
  methods: {
    ...mapActions('detail', ['updateReleaseTagName', 'updateCreateFrom']),
    markInputAsDirty() {
      this.isInputDirty = true;
    },
  },
  translations: {
    noRefSelected: __('No source selected'),
    searchPlaceholder: __('Search branches, tags, and commits'),
    dropdownHeader: __('Select source'),
  },
};
</script>
<template>
  <div>
    <gl-form-group
      :label="__('Tag name')"
      :label-for="tagNameInputId"
      data-testid="tag-name-field"
      :state="!showTagNameValidationError"
      :invalid-feedback="__('Tag name is required')"
    >
      <form-field-container>
        <gl-form-input
          :id="tagNameInputId"
          v-model="tagName"
          :state="!showTagNameValidationError"
          type="text"
          class="form-control"
          @blur.once="markInputAsDirty"
        />
      </form-field-container>
    </gl-form-group>
    <gl-form-group
      :label="__('Create from')"
      :label-for="createFromSelectorId"
      data-testid="create-from-field"
    >
      <form-field-container>
        <ref-selector
          :id="createFromSelectorId"
          v-model="createFromModel"
          :project-id="projectId"
          :translations="$options.translations"
        />
      </form-field-container>
      <template #description>
        {{ __('Existing branch name, tag, or commit SHA') }}
      </template>
    </gl-form-group>
  </div>
</template>

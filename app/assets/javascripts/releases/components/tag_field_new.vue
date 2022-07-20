<script>
import { GlFormGroup, GlDropdownItem, GlSprintf } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { mapState, mapActions, mapGetters } from 'vuex';
import { __ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_TAGS } from '~/ref/constants';
import FormFieldContainer from './form_field_container.vue';

export default {
  name: 'TagFieldNew',
  components: {
    GlFormGroup,
    RefSelector,
    FormFieldContainer,
    GlDropdownItem,
    GlSprintf,
  },
  data() {
    return {
      // Keeps track of whether or not the user has interacted with
      // the input field. This is used to avoid showing validation
      // errors immediately when the page loads.
      isInputDirty: false,
    };
  },
  computed: {
    ...mapState('editNew', ['projectId', 'release', 'createFrom', 'showCreateFrom']),
    ...mapGetters('editNew', ['validationErrors']),
    tagName: {
      get() {
        return this.release.tagName;
      },
      set(tagName) {
        this.updateReleaseTagName(tagName);

        // This setter is used by the `v-model` on the `RefSelector`.
        // When this is called, the selection originated from the
        // dropdown list of existing tag names, so we know the tag
        // already exists and don't need to show the "create from" input
        this.updateShowCreateFrom(false);
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
      return (
        this.isInputDirty &&
        (this.validationErrors.isTagNameEmpty || this.validationErrors.existingRelease)
      );
    },
    tagNameInputId() {
      return uniqueId('tag-name-input-');
    },
    createFromSelectorId() {
      return uniqueId('create-from-selector-');
    },
    tagFeedback() {
      return this.validationErrors.existingRelease
        ? __('Selected tag is already in use. Choose another option.')
        : __('Tag name is required.');
    },
  },
  methods: {
    ...mapActions('editNew', [
      'updateReleaseTagName',
      'updateCreateFrom',
      'fetchTagNotes',
      'updateShowCreateFrom',
    ]),
    markInputAsDirty() {
      this.isInputDirty = true;
    },
    createTagClicked(newTagName) {
      this.updateReleaseTagName(newTagName);

      // This method is called when the user selects the "create tag"
      // option, so the tag does not already exist. Because of this,
      // we need to show the "create from" input.
      this.updateShowCreateFrom(true);
    },
    shouldShowCreateTagOption(isLoading, matches, query) {
      // Show the "create tag" option if:
      return (
        // we're not currently loading any results, and
        !isLoading &&
        // the search query isn't just whitespace, and
        query.trim() &&
        // the `matches` object is non-null, and
        matches &&
        // the tag name doesn't already exist
        !matches.tags.list.some(
          (tagInfo) => tagInfo.name.toUpperCase() === query.toUpperCase().trim(),
        )
      );
    },
  },
  translations: {
    tagName: {
      noRefSelected: __('No tag selected'),
      dropdownHeader: __('Tag name'),
      searchPlaceholder: __('Search or create tag'),
      label: __('Tag name'),
      labelDescription: __('*Required'),
    },
    createFrom: {
      noRefSelected: __('No source selected'),
      searchPlaceholder: __('Search branches, tags, and commits'),
      dropdownHeader: __('Select source'),
    },
  },
  tagNameEnabledRefTypes: [REF_TYPE_TAGS],
};
</script>
<template>
  <div>
    <gl-form-group
      data-testid="tag-name-field"
      :state="!showTagNameValidationError"
      :invalid-feedback="tagFeedback"
      :label="$options.translations.tagName.label"
      :label-for="tagNameInputId"
      :label-description="$options.translations.tagName.labelDescription"
    >
      <form-field-container>
        <ref-selector
          :id="tagNameInputId"
          v-model="tagName"
          :project-id="projectId"
          :translations="$options.translations.tagName"
          :enabled-ref-types="$options.tagNameEnabledRefTypes"
          :state="!showTagNameValidationError"
          @input="fetchTagNotes"
          @hide.once="markInputAsDirty"
        >
          <template #footer="{ isLoading, matches, query }">
            <gl-dropdown-item
              v-if="shouldShowCreateTagOption(isLoading, matches, query)"
              is-check-item
              :is-checked="tagName === query"
              @click="createTagClicked(query)"
            >
              <gl-sprintf :message="__('Create tag %{tagName}')">
                <template #tagName>
                  <b>{{ query }}</b>
                </template>
              </gl-sprintf>
            </gl-dropdown-item>
          </template>
        </ref-selector>
      </form-field-container>
    </gl-form-group>
    <gl-form-group
      v-if="showCreateFrom"
      :label="__('Create from')"
      :label-for="createFromSelectorId"
      data-testid="create-from-field"
    >
      <form-field-container>
        <ref-selector
          :id="createFromSelectorId"
          v-model="createFromModel"
          :project-id="projectId"
          :translations="$options.translations.createFrom"
        />
      </form-field-container>
      <template #description>
        {{ __('Existing branch name, tag, or commit SHA') }}
      </template>
    </gl-form-group>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex';
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import FormFieldContainer from './form_field_container.vue';

export default {
  name: 'TagFieldNew',
  components: { GlFormGroup, GlFormInput, RefSelector, FormFieldContainer },
  computed: {
    ...mapState('detail', ['projectId', 'release', 'createFrom']),
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
    tagNameInputId() {
      return uniqueId('tag-name-input-');
    },
    createFromSelectorId() {
      return uniqueId('create-from-selector-');
    },
  },
  methods: {
    ...mapActions('detail', ['updateReleaseTagName', 'updateCreateFrom']),
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
    <gl-form-group :label="__('Tag name')" :label-for="tagNameInputId" data-testid="tag-name-field">
      <form-field-container>
        <gl-form-input :id="tagNameInputId" v-model="tagName" type="text" class="form-control" />
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

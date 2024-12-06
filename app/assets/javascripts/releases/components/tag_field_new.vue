<script>
import { GlButton, GlTruncate, GlIcon, GlFormGroup, GlPopover } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions, mapGetters } from 'vuex';
import { __, s__ } from '~/locale';
import { ESC_KEY } from '~/lib/utils/keys';

import TagSearch from './tag_search.vue';
import TagCreate from './tag_create.vue';

export default {
  components: {
    GlTruncate,
    GlButton,
    GlIcon,
    GlFormGroup,
    GlPopover,
    TagSearch,
    TagCreate,
  },
  data() {
    return { id: 'release-tag-name', newTagName: '', show: false, isInputDirty: false };
  },
  computed: {
    ...mapState('editNew', ['release', 'showCreateFrom']),
    ...mapGetters('editNew', ['validationErrors', 'isSearching', 'isCreating']),
    title() {
      return this.isCreating ? this.$options.i18n.createTitle : this.$options.i18n.selectTitle;
    },
    showTagNameValidationError() {
      return this.isInputDirty && !this.validationErrors.tagNameValidation.isValid;
    },
    tagFeedback() {
      return this.validationErrors.tagNameValidation.validationErrors[0];
    },
    buttonText() {
      return this.release?.tagName || s__('Release|Search or create tag name');
    },
    buttonVariant() {
      return this.showTagNameValidationError ? 'danger' : 'default';
    },
    createText() {
      return this.newTagName ? this.$options.i18n.createTag : this.$options.i18n.typeNew;
    },
  },
  mounted() {
    this.newTagName = this.release?.tagName || '';
  },
  methods: {
    ...mapActions('editNew', [
      'setSearching',
      'setCreating',
      'setNewTag',
      'setExistingTag',
      'updateReleaseTagName',
      'fetchTagNotes',
    ]),
    startCreate(query) {
      this.newTagName = query;
      this.setCreating();
    },
    selected(tag) {
      this.updateReleaseTagName(tag);

      if (this.isSearching) {
        this.fetchTagNotes(tag);
        this.setExistingTag();
        this.newTagName = '';
      } else {
        this.setNewTag();
      }

      this.hidePopover();
    },
    markInputAsDirty() {
      this.isInputDirty = true;
    },
    showPopover() {
      this.show = true;
    },
    hidePopover() {
      this.show = false;
      // gl-button doesn't expose focus method, but we can find button element by id
      document.getElementById(this.id)?.focus();
    },
    onPopoverKeyUp(e) {
      if (e.code === ESC_KEY) {
        this.hidePopover();
      }
    },
  },
  i18n: {
    selectTitle: __('Tags'),
    createTitle: s__('Release|Create tag'),
    label: __('Tag name'),
    required: __('(required)'),
    create: __('Create'),
    cancel: __('Cancel'),
  },
};
</script>
<template>
  <div class="row">
    <gl-form-group
      class="col-md-4 col-sm-10"
      :label="$options.i18n.label"
      :label-for="id"
      :optional-text="$options.i18n.required"
      :state="!showTagNameValidationError"
      :invalid-feedback="tagFeedback"
      optional
    >
      <gl-button :id="id" class="gl-w-30 !gl-px-0" @click="showPopover">
        <span class="gl-flex gl-w-28 gl-justify-between">
          <gl-truncate :text="buttonText" class="gl-max-w-26" />
          <gl-icon class="gl-button-icon gl-new-dropdown-chevron" name="chevron-down" />
        </span>
      </gl-button>
      <gl-popover
        :show="show"
        :target="id"
        :title="title"
        :css-classes="['gl-z-200', 'release-tag-selector']"
        placement="bottom"
        triggers="manual"
        container="content-body"
        show-close-button
        @close-button-clicked="hidePopover"
        @hide.once="markInputAsDirty"
      >
        <div class="gl-border-t-1 gl-border-strong gl-border-t-solid" @keyup="onPopoverKeyUp">
          <tag-create
            v-if="isCreating"
            v-model="newTagName"
            @create="selected(newTagName)"
            @cancel="setSearching"
          />
          <tag-search v-else v-model="newTagName" @create="startCreate" @select="selected" />
        </div>
      </gl-popover>
    </gl-form-group>
  </div>
</template>

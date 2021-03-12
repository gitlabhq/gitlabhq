<script>
import { GlButton } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import Dropdown from './dropdown.vue';

export default {
  components: {
    Dropdown,
    GlButton,
  },
  computed: {
    ...mapGetters(['activeFile']),
    ...mapGetters('fileTemplates', ['templateTypes']),
    ...mapState('fileTemplates', ['selectedTemplateType', 'updateSuccess']),
    showTemplatesDropdown() {
      return Object.keys(this.selectedTemplateType).length > 0;
    },
  },
  watch: {
    activeFile: 'setInitialType',
  },
  mounted() {
    this.setInitialType();
  },
  methods: {
    ...mapActions('fileTemplates', [
      'setSelectedTemplateType',
      'fetchTemplate',
      'undoFileTemplate',
    ]),
    setInitialType() {
      const initialTemplateType = this.templateTypes.find((t) => t.name === this.activeFile.name);

      if (initialTemplateType) {
        this.setSelectedTemplateType(initialTemplateType);
      }
    },
    selectTemplateType(templateType) {
      this.setSelectedTemplateType(templateType);
    },
    selectTemplate(template) {
      this.fetchTemplate(template);
    },
    undo() {
      this.undoFileTemplate();
    },
  },
};
</script>

<template>
  <div
    class="d-flex align-items-center ide-file-templates qa-file-templates-bar gl-relative gl-z-index-1"
  >
    <strong class="gl-mr-3"> {{ __('File templates') }} </strong>
    <dropdown
      :data="templateTypes"
      :label="selectedTemplateType.name || __('Choose a type...')"
      class="mr-2"
      @click="selectTemplateType"
    />
    <dropdown
      v-if="showTemplatesDropdown"
      :label="__('Choose a template...')"
      :is-async-data="true"
      :searchable="true"
      :title="__('File templates')"
      class="mr-2 qa-file-template-dropdown"
      @click="selectTemplate"
    />
    <transition name="fade">
      <gl-button v-show="updateSuccess" category="secondary" variant="default" @click="undo">
        {{ __('Undo') }}
      </gl-button>
    </transition>
  </div>
</template>

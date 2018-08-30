<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Dropdown from './dropdown.vue';

export default {
  components: {
    Dropdown,
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
      const type = this.templateTypes.find(t => t.name === this.activeFile.name);

      if (type) {
        this.setSelectedTemplateType(type);
      }
    },
    selectTemplateType(type) {
      this.setSelectedTemplateType(type);
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
  <div class="d-flex align-items-center ide-file-templates">
    <strong class="append-right-default">
      {{ __('File templates') }}
    </strong>
    <dropdown
      :data="templateTypes"
      :label="selectedTemplateType.name || __('Choose a type...')"
      class="mr-2"
      @click="selectTemplateType"
    />
    <dropdown
      v-if="showTemplatesDropdown"
      :label="__('Choose a template...')"
      :async="true"
      :searchable="true"
      :title="__('File templates')"
      class="mr-2"
      @click="selectTemplate"
    />
    <transition name="fade">
      <button
        v-show="updateSuccess"
        type="button"
        class="btn btn-default"
        @click="undo"
      >
        {{ __('Undo') }}
      </button>
    </transition>
  </div>
</template>

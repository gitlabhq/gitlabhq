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
    activeFile: {
      handler: 'setInitialType',
    },
  },
  mounted() {
    this.setInitialType();
  },
  methods: {
    ...mapActions('fileTemplates', ['setTemplateType', 'fetchTemplate']),
    setInitialType() {
      const type = this.templateTypes.find(t => t.name === this.activeFile.name);

      if (type) {
        this.setTemplateType(type);
      }
    },
    selectTemplateType(type) {
      this.setTemplateType(type);
    },
    selecteTemplate(template) {
      this.fetchTemplate(template);
    },
  },
};
</script>

<template>
  <div class="d-flex align-items-center ide-file-templates">
    <strong class="mr-2">
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
      :label="__('Choose a type...')"
      :async="true"
      :searchable="true"
      :title="__('File templates')"
      class="mr-2"
      @click="selecteTemplate"
    />
    <transition name="fade">
      <div v-show="updateSuccess">
        <strong class="text-success mr-2">
          {{ __('Template applied') }}
        </strong>
        <button
          type="button"
          class="btn btn-default"
        >
          {{ __('Undo') }}
        </button>
      </div>
    </transition>
  </div>
</template>

<style>
.ide-file-templates {
  padding: 8px 16px;
  background-color: #fafafa;
  border-bottom: 1px solid #eaeaea;
}

.ide-file-templates .dropdown {
  min-width: 180px;
}
</style>

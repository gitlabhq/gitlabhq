<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlDropdown, GlDropdownItem, GlLoadingIcon, GlSearchBoxByType } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { __ } from '~/locale';

const barLabel = __('File templates');
const templateListDropdownLabel = __('Choose a template...');
const templateTypesDropdownLabel = __('Choose a type...');
const undoButtonText = __('Undo');

export default {
  i18n: {
    barLabel,
    templateListDropdownLabel,
    templateTypesDropdownLabel,
    undoButtonText,
  },
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlLoadingIcon,
    GlSearchBoxByType,
  },
  data() {
    return {
      search: '',
    };
  },
  computed: {
    ...mapGetters(['activeFile']),
    ...mapGetters('fileTemplates', ['templateTypes']),
    ...mapState('fileTemplates', [
      'selectedTemplateType',
      'updateSuccess',
      'templates',
      'isLoading',
    ]),
    filteredTemplateTypes() {
      return this.templates.filter((t) => {
        return t.name.toLowerCase().includes(this.search.toLowerCase());
      });
    },
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
      'fetchTemplateTypes',
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
    class="ide-file-templates gl-relative gl-z-1 gl-flex gl-items-center"
    data-testid="file-templates-bar"
  >
    <strong class="gl-mr-3"> {{ $options.i18n.barLabel }} </strong>
    <gl-dropdown
      class="gl-mr-6"
      :text="selectedTemplateType.name || $options.i18n.templateTypesDropdownLabel"
    >
      <gl-dropdown-item
        v-for="template in templateTypes"
        :key="template.key"
        @click.prevent="selectTemplateType(template)"
      >
        {{ template.name }}
      </gl-dropdown-item>
    </gl-dropdown>
    <gl-dropdown
      v-if="showTemplatesDropdown"
      class="gl-mr-6"
      :text="$options.i18n.templateListDropdownLabel"
      @show="fetchTemplateTypes"
    >
      <template #header>
        <gl-search-box-by-type v-model.trim="search" />
      </template>
      <div>
        <gl-loading-icon v-if="isLoading" />
        <template v-else>
          <gl-dropdown-item
            v-for="template in filteredTemplateTypes"
            :key="template.key"
            @click="selectTemplate(template)"
          >
            {{ template.name }}
          </gl-dropdown-item>
        </template>
      </div>
    </gl-dropdown>
    <transition name="fade">
      <gl-button v-show="updateSuccess" category="secondary" variant="default" @click="undo">
        {{ $options.i18n.undoButtonText }}
      </gl-button>
    </transition>
  </div>
</template>

<script>
import { GlFormGroup, GlFormRadio, GlFormText } from '@gitlab/ui';
import ProjectsTokenSelector from './projects_token_selector.vue';

export default {
  name: 'ProjectsField',
  ALL_PROJECTS: 'ALL_PROJECTS',
  SELECTED_PROJECTS: 'SELECTED_PROJECTS',
  components: { GlFormGroup, GlFormRadio, GlFormText, ProjectsTokenSelector },
  props: {
    inputAttrs: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      selectedRadio: !this.inputAttrs.value
        ? this.$options.ALL_PROJECTS
        : this.$options.SELECTED_PROJECTS,
      selectedProjects: [],
    };
  },
  computed: {
    allProjectsRadioSelected() {
      return this.selectedRadio === this.$options.ALL_PROJECTS;
    },
    hiddenInputValue() {
      return this.allProjectsRadioSelected
        ? null
        : this.selectedProjects.map((project) => project.id).join(',');
    },
    initialProjectIds() {
      if (!this.inputAttrs.value) {
        return [];
      }

      return this.inputAttrs.value.split(',');
    },
  },
  methods: {
    handleTokenSelectorFocus() {
      this.selectedRadio = this.$options.SELECTED_PROJECTS;
    },
  },
};
</script>

<template>
  <div>
    <gl-form-group :label="__('Projects')" label-class="gl-pb-0!">
      <gl-form-text class="gl-pb-3">{{
        __('Set access permissions for this token.')
      }}</gl-form-text>
      <gl-form-radio v-model="selectedRadio" :value="$options.ALL_PROJECTS">{{
        __('All projects')
      }}</gl-form-radio>
      <gl-form-radio v-model="selectedRadio" :value="$options.SELECTED_PROJECTS">{{
        __('Selected projects')
      }}</gl-form-radio>
      <input :id="inputAttrs.id" type="hidden" :name="inputAttrs.name" :value="hiddenInputValue" />
      <projects-token-selector
        v-model="selectedProjects"
        :initial-project-ids="initialProjectIds"
        @focus="handleTokenSelectorFocus"
      />
    </gl-form-group>
  </div>
</template>

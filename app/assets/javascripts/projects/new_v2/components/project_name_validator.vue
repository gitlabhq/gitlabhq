<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import searchProjectNameAvailabilityQuery from '../queries/search_project_name_availability.query.graphql';

export default {
  components: {
    GlAlert,
  },
  apollo: {
    namespace: {
      query: searchProjectNameAvailabilityQuery,
      variables() {
        return {
          search: this.projectPath,
          namespacePath: this.namespaceFullPath,
        };
      },
      update(data) {
        return data.namespace.projects.nodes || [];
      },
      skip() {
        return (
          this.namespaceFullPath === null ||
          (this.projectPath === null && this.projectName === null)
        );
      },
      debounce: DEBOUNCE_DELAY,
    },
  },
  props: {
    namespaceFullPath: {
      type: String,
      required: false,
      default: null,
    },
    projectPath: {
      type: String,
      required: false,
      default: null,
    },
    projectName: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      namespace: [],
      projectPathExists: false,
      projectNameExists: false,
    };
  },
  computed: {
    alertMessage() {
      if (this.projectNameExists && this.projectPathExists) {
        return s__(
          'ProjectsNew|Both project name and project path are already taken. Please choose different values for both.',
        );
      }
      if (this.projectNameExists) {
        return s__(
          'ProjectsNew|Project name is already taken. Please choose a different project name.',
        );
      }
      return s__(
        'ProjectsNew|Project path is already taken. Please choose a different project path.',
      );
    },
    fieldsValid() {
      return !this.projectNameExists && !this.projectPathExists;
    },
  },
  watch: {
    namespace(newNamespace) {
      this.projectPathExists = Boolean(
        this.projectPath && newNamespace.find((project) => project.path === this.projectPath),
      );

      this.projectNameExists = Boolean(
        this.projectName && newNamespace.find((project) => project.name === this.projectName),
      );

      this.$emit('onValidation', this.fieldsValid);
    },
  },
};
</script>

<template>
  <gl-alert v-if="!fieldsValid" variant="danger" :dismissible="false" class="gl-mb-5">
    {{ alertMessage }}
  </gl-alert>
</template>

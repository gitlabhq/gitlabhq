<script>
/* eslint-disable vue/no-v-html */
import { GlButton, GlIcon } from '@gitlab/ui';
import { isString } from 'lodash';
import highlight from '~/lib/utils/highlight';
import { truncateNamespace } from '~/lib/utils/text_utility';
import ProjectAvatar from '~/vue_shared/components/deprecated_project_avatar/default.vue';

export default {
  name: 'ProjectListItem',
  components: { GlIcon, ProjectAvatar, GlButton },
  props: {
    project: {
      type: Object,
      required: true,
      validator: (p) =>
        (Number.isFinite(p.id) || isString(p.id)) &&
        isString(p.name) &&
        (isString(p.name_with_namespace) || isString(p.nameWithNamespace)),
    },
    selected: { type: Boolean, required: true },
    matcher: { type: String, required: false, default: '' },
  },
  computed: {
    projectNameWithNamespace() {
      return this.project.nameWithNamespace || this.project.name_with_namespace;
    },
    truncatedNamespace() {
      return truncateNamespace(this.projectNameWithNamespace);
    },
    highlightedProjectName() {
      return highlight(this.project.name, this.matcher);
    },
  },
  methods: {
    onClick() {
      this.$emit('click');
    },
  },
};
</script>
<template>
  <gl-button
    category="tertiary"
    class="gl-display-flex gl-align-items-center gl-justify-content-start! gl-mb-2 gl-w-full"
    @click="onClick"
  >
    <div
      class="gl-display-flex gl-align-items-center gl-flex-wrap project-namespace-name-container"
    >
      <gl-icon v-if="selected" class="js-selected-icon" name="mobile-issue-close" />
      <project-avatar class="gl-flex-shrink-0 js-project-avatar" :project="project" :size="32" />
      <div
        v-if="truncatedNamespace"
        :title="projectNameWithNamespace"
        class="text-secondary text-truncate js-project-namespace"
      >
        {{ truncatedNamespace }}
        <span v-if="truncatedNamespace" class="text-secondary">/&nbsp;</span>
      </div>
      <div
        :title="project.name"
        class="js-project-name text-truncate"
        v-html="highlightedProjectName"
      ></div>
    </div>
  </gl-button>
</template>

<script>
import { GlDeprecatedButton } from '@gitlab/ui';
import { isString } from 'lodash';
import Icon from '~/vue_shared/components/icon.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar/default.vue';
import highlight from '~/lib/utils/highlight';
import { truncateNamespace } from '~/lib/utils/text_utility';

export default {
  name: 'ProjectListItem',
  components: { Icon, ProjectAvatar, GlDeprecatedButton },
  props: {
    project: {
      type: Object,
      required: true,
      validator: p =>
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
  <gl-deprecated-button
    class="d-flex align-items-center btn pt-1 pb-1 border-0 project-list-item"
    @click="onClick"
  >
    <icon
      class="gl-ml-3 gl-mr-3 flex-shrink-0 position-top-0 js-selected-icon"
      :class="{ 'js-selected visible': selected, 'js-unselected invisible': !selected }"
      name="mobile-issue-close"
    />
    <project-avatar class="flex-shrink-0 js-project-avatar" :project="project" :size="32" />
    <div class="d-flex flex-wrap project-namespace-name-container">
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
  </gl-deprecated-button>
</template>

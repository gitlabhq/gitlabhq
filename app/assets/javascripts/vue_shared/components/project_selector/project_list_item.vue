<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { isString } from 'lodash';
import highlight from '~/lib/utils/highlight';
import { truncateNamespace } from '~/lib/utils/text_utility';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'ProjectListItem',
  components: { GlIcon, ProjectAvatar, GlButton },
  directives: { SafeHtml },
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
    projectAvatarUrl() {
      return this.project.avatar_url || this.project.avatarUrl;
    },
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
    class="gl-mb-2 gl-flex gl-w-full gl-items-center !gl-justify-start"
    @click="onClick"
  >
    <div class="project-namespace-name-container gl-flex gl-flex-wrap gl-items-center">
      <gl-icon v-if="selected" data-testid="selected-icon" name="mobile-issue-close" />
      <project-avatar
        :project-id="project.id"
        :project-avatar-url="projectAvatarUrl"
        :project-name="projectNameWithNamespace"
        class="gl-mr-3"
      />
      <div
        v-if="truncatedNamespace"
        data-testid="project-namespace"
        :title="projectNameWithNamespace"
        class="text-truncate gl-text-subtle"
      >
        {{ truncatedNamespace }}
        <span v-if="truncatedNamespace" class="gl-text-subtle">/&nbsp;</span>
      </div>
      <div
        v-safe-html="highlightedProjectName"
        data-testid="project-name"
        :title="project.name"
        class="text-truncate"
      ></div>
    </div>
  </gl-button>
</template>

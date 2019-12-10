<script>
import { GlButton } from '@gitlab/ui';
import _ from 'underscore';
import Icon from '~/vue_shared/components/icon.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar/default.vue';
import highlight from '~/lib/utils/highlight';
import { truncateNamespace } from '~/lib/utils/text_utility';

export default {
  name: 'ProjectListItem',
  components: {
    Icon,
    ProjectAvatar,
    GlButton,
  },
  props: {
    project: {
      type: Object,
      required: true,
      validator: p => _.isFinite(p.id) && _.isString(p.name) && _.isString(p.name_with_namespace),
    },
    selected: {
      type: Boolean,
      required: true,
    },
    matcher: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    truncatedNamespace() {
      return truncateNamespace(this.project.name_with_namespace);
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
    class="d-flex align-items-center btn pt-1 pb-1 border-0 project-list-item"
    @click="onClick"
  >
    <icon
      class="prepend-left-10 append-right-10 flex-shrink-0 position-top-0 js-selected-icon"
      :class="{ 'js-selected visible': selected, 'js-unselected invisible': !selected }"
      name="mobile-issue-close"
    />
    <project-avatar class="flex-shrink-0 js-project-avatar" :project="project" :size="32" />
    <div class="d-flex flex-wrap project-namespace-name-container">
      <div
        v-if="truncatedNamespace"
        :title="project.name_with_namespace"
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

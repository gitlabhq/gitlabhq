<script>
import { GlButton, GlCollapse, GlIcon, GlBadge, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import pollIntervalQuery from '../graphql/queries/poll_interval.query.graphql';
import folderQuery from '../graphql/queries/folder.query.graphql';
import { ENVIRONMENT_COUNT_BY_SCOPE } from '../constants';
import EnvironmentItem from './new_environment_item.vue';

export default {
  components: {
    EnvironmentItem,
    GlButton,
    GlCollapse,
    GlIcon,
    GlBadge,
    GlLink,
  },
  props: {
    nestedEnvironment: {
      type: Object,
      required: true,
    },
    scope: {
      type: String,
      required: true,
    },
    search: {
      type: String,
      required: true,
    },
  },
  data() {
    return { visible: false, interval: undefined };
  },
  apollo: {
    folder: {
      query: folderQuery,
      variables() {
        return {
          environment: this.nestedEnvironment.latest,
          scope: this.scope,
          search: this.search,
        };
      },
    },
    interval: {
      query: pollIntervalQuery,
    },
  },
  i18n: {
    collapse: __('Collapse'),
    expand: __('Expand'),
    link: s__('Environments|Show all'),
  },
  computed: {
    icons() {
      return this.visible
        ? { caret: 'chevron-lg-down', folder: 'folder-open' }
        : { caret: 'chevron-lg-right', folder: 'folder-o' };
    },
    label() {
      return this.visible ? this.$options.i18n.collapse : this.$options.i18n.expand;
    },
    count() {
      const count = ENVIRONMENT_COUNT_BY_SCOPE[this.scope];
      return this.folder?.[count] ?? 0;
    },
    folderClass() {
      return { 'gl-font-weight-bold': this.visible };
    },
    folderPath() {
      return this.nestedEnvironment.latest.folderPath;
    },
    environments() {
      return this.folder?.environments;
    },
  },
  methods: {
    toggleCollapse() {
      this.visible = !this.visible;
      if (this.visible) {
        this.$apollo.queries.folder.startPolling(this.interval);
      } else {
        this.$apollo.queries.folder.stopPolling();
      }
    },
    isFirstEnvironment(index) {
      return index === 0;
    },
  },
};
</script>
<template>
  <div
    :class="{ 'gl-pb-5': !visible }"
    class="gl-border-b-solid gl-border-gray-100 gl-border-1 gl-pt-3"
  >
    <div class="gl-w-full gl-display-flex gl-align-items-center gl-px-3">
      <gl-button
        class="gl-mr-4 gl-fill-current-color gl-text-gray-500"
        :aria-label="label"
        :icon="icons.caret"
        size="small"
        category="tertiary"
        @click="toggleCollapse"
      />
      <gl-icon class="gl-mr-2 gl-fill-current-color gl-text-gray-500" :name="icons.folder" />
      <div class="gl-mr-2 gl-text-gray-500" :class="folderClass">
        {{ nestedEnvironment.name }}
      </div>
      <gl-badge size="sm" class="gl-mr-auto">{{ count }}</gl-badge>
      <gl-link v-if="visible" :href="folderPath">{{ $options.i18n.link }}</gl-link>
    </div>
    <gl-collapse :visible="visible">
      <environment-item
        v-for="(environment, index) in environments"
        :key="environment.name"
        :environment="environment"
        :class="{ 'gl-mt-5': isFirstEnvironment(index) }"
        class="gl-border-gray-100 gl-border-t-solid gl-border-1 gl-pt-3"
        in-folder
      />
    </gl-collapse>
  </div>
</template>

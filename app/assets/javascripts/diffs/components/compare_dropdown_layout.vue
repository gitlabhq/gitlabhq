<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    TimeAgo,
  },
  props: {
    versions: {
      type: Array,
      required: true,
    },
  },
  computed: {
    selectedVersionName() {
      return this.versions.find((x) => x.selected)?.versionName || '';
    },
  },
};
</script>

<template>
  <gl-dropdown
    :text="selectedVersionName"
    data-testid="version-dropdown-content"
    size="small"
    category="tertiary"
  >
    <template v-for="version in versions">
      <gl-dropdown-divider v-if="version.addDivider" :key="version.id" />
      <gl-dropdown-item
        :key="version.id"
        :class="{
          'is-active': version.selected,
        }"
        is-check-item
        :is-checked="version.selected"
        :href="version.href"
      >
        <div>
          <strong>
            {{ version.versionName }}
            <template v-if="version.isHead">{{ s__('DiffsCompareBaseBranch|(HEAD)') }}</template>
            <template v-else-if="version.isBase">{{
              s__('DiffsCompareBaseBranch|(base)')
            }}</template>
          </strong>
        </div>
        <div>
          <small class="commit-sha"> {{ version.short_commit_sha }} </small>
        </div>
        <div>
          <small>
            <template v-if="version.commitsText">
              {{ version.commitsText }}
            </template>
            <time-ago v-if="version.created_at" :time="version.created_at" class="js-timeago" />
          </small>
        </div>
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>

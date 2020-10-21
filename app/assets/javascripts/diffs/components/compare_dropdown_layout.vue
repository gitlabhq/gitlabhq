<script>
import { GlIcon } from '@gitlab/ui';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlIcon,
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
      return this.versions.find(x => x.selected)?.versionName || '';
    },
  },
};
</script>

<template>
  <span class="dropdown inline">
    <a
      class="dropdown-menu-toggle btn btn-default w-100"
      data-toggle="dropdown"
      aria-expanded="false"
    >
      <span> {{ selectedVersionName }} </span>
      <gl-icon :size="12" name="angle-down" class="position-absolute" />
    </a>
    <div class="dropdown-menu dropdown-select dropdown-menu-selectable">
      <div class="dropdown-content" data-qa-selector="dropdown_content">
        <ul>
          <li v-for="version in versions" :key="version.id">
            <a :class="{ 'is-active': version.selected }" :href="version.href">
              <div>
                <strong>
                  {{ version.versionName }}
                  <template v-if="version.isHead">{{
                    s__('DiffsCompareBaseBranch|(HEAD)')
                  }}</template>
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
                  <time-ago
                    v-if="version.created_at"
                    :time="version.created_at"
                    class="js-timeago"
                  />
                </small>
              </div>
            </a>
          </li>
        </ul>
      </div>
    </div>
  </span>
</template>

<style>
.dropdown {
  min-width: 0;
  max-height: 170px;
}
</style>

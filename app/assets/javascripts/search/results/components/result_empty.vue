<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import emptySearchSVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg';
import { s__ } from '~/locale';
import { SCOPE_NAVIGATION_MAP } from '~/search/store/constants';

export default {
  name: 'GlobalSearchResultsEmpty',
  i18n: {
    title: s__('GlobalSearch|No results found'),
    descriptionProject: s__(
      "GlobalSearch|We couldn't find any %{scope} matching %{term} in project %{project}",
    ),
    descriptionGroup: s__(
      "GlobalSearch|We couldn't find any %{scope} matching %{term} in group %{group}",
    ),
    descriptionSimple: s__("GlobalSearch|We couldn't find any %{scope} matching %{term}"),
  },
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
  },
  computed: {
    ...mapState(['query', 'groupInitialJson', 'projectInitialJson']),
    ...mapGetters(['currentScope']),
  },
  emptySearchSVG,
  SCOPE_NAVIGATION_MAP,
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="$options.emptySearchSVG"
    description="No results found"
  >
    <template #description>
      <gl-sprintf
        v-if="query.project_id && projectInitialJson"
        :message="$options.i18n.descriptionProject"
      >
        <template #scope>
          <strong>{{ $options.SCOPE_NAVIGATION_MAP[currentScope] }}</strong>
        </template>
        <template #term>
          <strong>{{ query.search }}</strong>
        </template>
        <template #project>
          <gl-link v-if="projectInitialJson.full_path" :href="projectInitialJson.full_path">
            {{ projectInitialJson.name_with_namespace }}
          </gl-link>
          <span v-else>{{ projectInitialJson.name_with_namespace }}</span>
        </template>
      </gl-sprintf>
      <gl-sprintf
        v-else-if="query.group_id && groupInitialJson"
        :message="$options.i18n.descriptionGroup"
      >
        <template #scope>
          <strong>{{ $options.SCOPE_NAVIGATION_MAP[currentScope] }}</strong>
        </template>
        <template #term>
          <strong>{{ query.search }}</strong>
        </template>
        <template #group>
          <gl-link v-if="groupInitialJson.full_path" :href="groupInitialJson.full_path">
            {{ groupInitialJson.full_name }}
          </gl-link>
          <span v-else>{{ groupInitialJson.full_name }}</span>
        </template>
      </gl-sprintf>
      <gl-sprintf v-else :message="$options.i18n.descriptionSimple">
        <template #scope>
          <strong>{{ $options.SCOPE_NAVIGATION_MAP[currentScope] }}</strong>
        </template>
        <template #term>
          <strong>{{ query.search }}</strong>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>

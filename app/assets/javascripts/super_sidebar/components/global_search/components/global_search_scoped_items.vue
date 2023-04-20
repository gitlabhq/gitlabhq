<script>
import { GlIcon, GlToken, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { s__, sprintf } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';
import { SCOPE_TOKEN_MAX_LENGTH } from '../constants';

export default {
  name: 'GlobalSearchScopedItems',
  components: {
    GlIcon,
    GlToken,
    GlDisclosureDropdownGroup,
  },
  computed: {
    ...mapState(['search']),
    ...mapGetters(['scopedSearchGroup']),
  },
  methods: {
    titleLabel(item) {
      return sprintf(s__('GlobalSearch|in %{scope}'), {
        search: this.search,
        scope: item.scope || item.description,
      });
    },
    getTruncatedScope(scope) {
      return truncate(scope, SCOPE_TOKEN_MAX_LENGTH);
    },
  },
};
</script>

<template>
  <div>
    <ul class="gl-m-0 gl-p-0 gl-pb-2 gl-list-style-none">
      <gl-disclosure-dropdown-group :group="scopedSearchGroup" bordered class="gl-mt-0!">
        <template #list-item="{ item }">
          <span
            class="gl-display-flex gl-align-items-center gl-line-height-24 gl-flex-direction-row gl-w-full"
          >
            <gl-icon name="search" class="gl-flex-shrink-0 gl-mr-2 gl-pt-2 gl-mt-n2" />
            <span class="gl-flex-grow-1">
              <gl-token class="gl-flex-shrink-0 gl-white-space-nowrap gl-float-right" view-only>
                <gl-icon v-if="item.icon" :name="item.icon" class="gl-mr-2" />
                <span>{{ getTruncatedScope(titleLabel(item)) }}</span>
              </gl-token>
              {{ search }}
            </span>
          </span>
        </template>
      </gl-disclosure-dropdown-group>
    </ul>
  </div>
</template>

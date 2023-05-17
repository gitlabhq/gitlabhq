<script>
import { GlAvatar, GlAlert, GlLoadingIcon, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlight from '~/lib/utils/highlight';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { AUTOCOMPLETE_ERROR_MESSAGE } from '~/vue_shared/global_search/constants';

export default {
  name: 'GlobalSearchAutocompleteItems',
  i18n: {
    AUTOCOMPLETE_ERROR_MESSAGE,
  },
  components: {
    GlAvatar,
    GlAlert,
    GlLoadingIcon,
    GlDisclosureDropdownGroup,
  },
  directives: {
    SafeHtml,
  },
  computed: {
    ...mapState(['search', 'loading', 'autocompleteError']),
    ...mapGetters(['autocompleteGroupedSearchOptions', 'scopedSearchOptions']),
    isPrecededByScopedOptions() {
      return this.scopedSearchOptions.length > 1;
    },
  },
  methods: {
    highlightedName(val) {
      return highlight(val, this.search);
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <div>
    <ul v-if="!loading" class="gl-m-0 gl-p-0 gl-list-style-none">
      <gl-disclosure-dropdown-group
        v-for="group in autocompleteGroupedSearchOptions"
        :key="group.name"
        :class="{ 'gl-mt-0!': !isPrecededByScopedOptions }"
        :group="group"
        bordered
      >
        <template #list-item="{ item }">
          <div class="gl-display-flex gl-align-items-center">
            <gl-avatar
              v-if="item.avatar_url !== undefined"
              class="gl-mr-3"
              :src="item.avatar_url"
              :entity-id="item.entity_id"
              :entity-name="item.entity_name"
              :size="item.avatar_size"
              :shape="$options.AVATAR_SHAPE_OPTION_RECT"
              aria-hidden="true"
            />
            <span class="gl-display-flex gl-flex-direction-column">
              <span
                v-safe-html="highlightedName(item.text)"
                class="gl-text-gray-900"
                data-testid="autocomplete-item-name"
              ></span>
              <span
                v-if="item.value"
                v-safe-html="item.namespace"
                class="gl-font-sm gl-text-gray-500"
                data-testid="autocomplete-item-namespace"
              ></span>
            </span>
          </div>
        </template>
      </gl-disclosure-dropdown-group>
    </ul>

    <gl-loading-icon v-else size="lg" class="my-4" />

    <gl-alert
      v-if="autocompleteError"
      class="gl-text-body gl-mt-2"
      :dismissible="false"
      variant="danger"
    >
      {{ $options.i18n.AUTOCOMPLETE_ERROR_MESSAGE }}
    </gl-alert>
  </div>
</template>

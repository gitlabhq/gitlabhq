<script>
import {
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
  GlLoadingIcon,
} from '@gitlab/ui';
import { debounce } from 'lodash';

import createFlash from '~/flash';
import { __ } from '~/locale';

import { DEBOUNCE_DELAY, DEFAULT_NONE_ANY } from '../constants';
import { stripQuotes } from '../filtered_search_utils';

export default {
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
    GlDropdownDivider,
    GlLoadingIcon,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      emojis: this.config.initialEmojis || [],
      defaultEmojis: this.config.defaultEmojis || DEFAULT_NONE_ANY,
      loading: true,
    };
  },
  computed: {
    currentValue() {
      return this.value.data.toLowerCase();
    },
    activeEmoji() {
      return this.emojis.find(
        (emoji) => emoji.name.toLowerCase() === stripQuotes(this.currentValue),
      );
    },
  },
  watch: {
    active: {
      immediate: true,
      handler(newValue) {
        if (!newValue && !this.emojis.length) {
          this.fetchEmojiBySearchTerm(this.value.data);
        }
      },
    },
  },
  methods: {
    fetchEmojiBySearchTerm(searchTerm) {
      this.loading = true;
      this.config
        .fetchEmojis(searchTerm)
        .then((res) => {
          this.emojis = Array.isArray(res) ? res : res.data;
        })
        .catch(() =>
          createFlash({
            message: __('There was a problem fetching emojis.'),
          }),
        )
        .finally(() => {
          this.loading = false;
        });
    },
    searchEmojis: debounce(function debouncedSearch({ data }) {
      this.fetchEmojiBySearchTerm(data);
    }, DEBOUNCE_DELAY),
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="config"
    v-bind="{ ...$props, ...$attrs }"
    v-on="$listeners"
    @input="searchEmojis"
  >
    <template #view="{ inputValue }">
      <gl-emoji v-if="activeEmoji" :data-name="activeEmoji.name" />
      <span v-else>{{ inputValue }}</span>
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="emoji in defaultEmojis"
        :key="emoji.value"
        :value="emoji.value"
      >
        {{ emoji.value }}
      </gl-filtered-search-suggestion>
      <gl-dropdown-divider v-if="defaultEmojis.length" />
      <gl-loading-icon v-if="loading" size="sm" />
      <template v-else>
        <gl-filtered-search-suggestion
          v-for="emoji in emojis"
          :key="emoji.name"
          :value="emoji.name"
        >
          <div class="gl-display-flex">
            <gl-emoji :data-name="emoji.name" />
            <span class="gl-ml-3">{{ emoji.name }}</span>
          </div>
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>

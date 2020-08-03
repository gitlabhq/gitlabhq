<script>
import {
  GlToken,
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
  GlLoadingIcon,
} from '@gitlab/ui';
import { debounce } from 'lodash';

import createFlash from '~/flash';
import { __ } from '~/locale';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

import { NO_LABEL, DEBOUNCE_DELAY } from '../constants';

export default {
  noLabel: NO_LABEL,
  components: {
    GlToken,
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
      labels: this.config.initialLabels || [],
      loading: true,
    };
  },
  computed: {
    currentValue() {
      return this.value.data.toLowerCase();
    },
    activeLabel() {
      // Strip double quotes
      const strippedCurrentValue = this.currentValue.includes(' ')
        ? this.currentValue.substring(1, this.currentValue.length - 1)
        : this.currentValue;

      return this.labels.find(label => label.title.toLowerCase() === strippedCurrentValue);
    },
    containerStyle() {
      if (this.activeLabel) {
        const { color, textColor } = convertObjectPropsToCamelCase(this.activeLabel);

        return { backgroundColor: color, color: textColor };
      }
      return {};
    },
  },
  watch: {
    active: {
      immediate: true,
      handler(newValue) {
        if (!newValue && !this.labels.length) {
          this.fetchLabelBySearchTerm(this.value.data);
        }
      },
    },
  },
  methods: {
    fetchLabelBySearchTerm(searchTerm) {
      this.loading = true;
      this.config
        .fetchLabels(searchTerm)
        .then(res => {
          // We'd want to avoid doing this check but
          // labels.json and /groups/:id/labels & /projects/:id/labels
          // return response differently.
          this.labels = Array.isArray(res) ? res : res.data;
        })
        .catch(() => createFlash(__('There was a problem fetching labels.')))
        .finally(() => {
          this.loading = false;
        });
    },
    searchLabels: debounce(function debouncedSearch({ data }) {
      this.fetchLabelBySearchTerm(data);
    }, DEBOUNCE_DELAY),
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="config"
    v-bind="{ ...$props, ...$attrs }"
    v-on="$listeners"
    @input="searchLabels"
  >
    <template #view-token="{ inputValue, cssClasses, listeners }">
      <gl-token variant="search-value" :class="cssClasses" :style="containerStyle" v-on="listeners">
        ~{{ activeLabel ? activeLabel.title : inputValue }}
      </gl-token>
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion :value="$options.noLabel">
        {{ __('No label') }}
      </gl-filtered-search-suggestion>
      <gl-dropdown-divider />
      <gl-loading-icon v-if="loading" />
      <template v-else>
        <gl-filtered-search-suggestion v-for="label in labels" :key="label.id" :value="label.title">
          <div class="gl-display-flex">
            <span
              :style="{ backgroundColor: label.color }"
              class="gl-display-inline-block mr-2 p-2"
            ></span>
            <div>{{ label.title }}</div>
          </div>
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>

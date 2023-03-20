<script>
import { GlToken, GlFilteredSearchSuggestion } from '@gitlab/ui';

import { createAlert } from '~/alert';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { __ } from '~/locale';

import { OPTIONS_NONE_ANY } from '../constants';
import { stripQuotes } from '../filtered_search_utils';

import BaseToken from './base_token.vue';

export default {
  components: {
    BaseToken,
    GlToken,
    GlFilteredSearchSuggestion,
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
    active: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      labels: this.config.initialLabels || [],
      loading: false,
    };
  },
  computed: {
    defaultLabels() {
      return this.config.defaultLabels || OPTIONS_NONE_ANY;
    },
  },
  methods: {
    getActiveLabel(labels, data) {
      return labels.find((label) => this.getLabelName(label) === stripQuotes(data));
    },
    /**
     * There's an inconsistency between private and public API
     * for labels where label name is included in a different
     * property;
     *
     * Private API => `label.title`
     * Public API => `label.name`
     *
     * This method allows compatibility as there may be instances
     * where `config.fetchLabels` provided externally may still be
     * using either of the two APIs.
     */
    getLabelName(label) {
      return label.name || label.title;
    },
    getContainerStyle(activeLabel) {
      if (activeLabel) {
        const { color: backgroundColor, textColor: color } = convertObjectPropsToCamelCase(
          activeLabel,
        );

        return { backgroundColor, color };
      }
      return {};
    },
    fetchLabels(searchTerm) {
      this.loading = true;
      this.config
        .fetchLabels(searchTerm)
        .then((res) => {
          // We'd want to avoid doing this check but
          // labels.json and /groups/:id/labels & /projects/:id/labels
          // return response differently.
          this.labels = Array.isArray(res) ? res : res.data;
          if (this.config.fetchLatestLabels) {
            this.fetchLatestLabels(searchTerm);
          }
        })
        .catch(() =>
          createAlert({
            message: __('There was a problem fetching labels.'),
          }),
        )
        .finally(() => {
          this.loading = false;
        });
    },
    fetchLatestLabels(searchTerm) {
      this.config
        .fetchLatestLabels(searchTerm)
        .then((res) => {
          // We'd want to avoid doing this check but
          // labels.json and /groups/:id/labels & /projects/:id/labels
          // return response differently.
          this.labels = Array.isArray(res) ? res : res.data;
        })
        .catch(() =>
          createAlert({
            message: __('There was a problem fetching latest labels.'),
          }),
        );
    },
  },
};
</script>

<template>
  <base-token
    :config="config"
    :value="value"
    :active="active"
    :suggestions-loading="loading"
    :suggestions="labels"
    :get-active-token-value="getActiveLabel"
    :default-suggestions="defaultLabels"
    v-bind="$attrs"
    @fetch-suggestions="fetchLabels"
    v-on="$listeners"
  >
    <template
      #view-token="{ viewTokenProps: { inputValue, cssClasses, listeners, activeTokenValue } }"
    >
      <gl-token
        variant="search-value"
        :class="cssClasses"
        :style="getContainerStyle(activeTokenValue)"
        v-on="listeners"
        >~{{ activeTokenValue ? getLabelName(activeTokenValue) : inputValue }}</gl-token
      >
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="label in suggestions"
        :key="label.id"
        :value="getLabelName(label)"
      >
        <div class="gl-display-flex gl-align-items-center">
          <span
            :style="{ backgroundColor: label.color }"
            class="gl-display-inline-block gl-mr-3 gl-p-3"
          ></span>
          <div>{{ getLabelName(label) }}</div>
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>

<script>
import { GlIcon, GlIntersperse, GlFilteredSearchSuggestion, GlLabel } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { stripQuotes } from '~/lib/utils/text_utility';
import { __ } from '~/locale';

import { OPTIONS_NONE_ANY } from '../constants';

import BaseToken from './base_token.vue';

export default {
  components: {
    BaseToken,
    GlIcon,
    GlFilteredSearchSuggestion,
    GlIntersperse,
    GlLabel,
  },
  inject: ['hasScopedLabelsFeature'],
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
      allLabels: this.config.initialLabels || [],
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
    findLabelByName(name) {
      return this.allLabels.find((label) => this.getLabelName(label) === name);
    },
    findLabelById(id) {
      return this.allLabels.find((label) => label.id === id);
    },
    showScopedLabel(labelName) {
      const label = this.findLabelByName(labelName);
      return isScopedLabel(label) && this.hasScopedLabelsFeature;
    },
    getLabelBackgroundColor(labelName) {
      const label = this.findLabelByName(labelName);
      const backgroundColor = label?.color || '#fff0';
      return backgroundColor;
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
    updateListOfAllLabels() {
      this.labels.forEach((label) => {
        if (!this.findLabelById(label.id)) {
          this.allLabels.push(label);
        }
      });
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
          this.updateListOfAllLabels();

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
          this.updateListOfAllLabels();
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
    :value-identifier="getLabelName"
    v-bind="$attrs"
    @fetch-suggestions="fetchLabels"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue, selectedTokens } }">
      <gl-intersperse v-if="selectedTokens.length > 0" separator=", ">
        <gl-label
          v-for="label in selectedTokens"
          :key="label"
          class="js-no-trigger"
          :background-color="getLabelBackgroundColor(label)"
          :scoped="showScopedLabel(label)"
          :title="label"
        />
      </gl-intersperse>
      <template v-else>
        <gl-label
          class="js-no-trigger"
          :background-color="
            getLabelBackgroundColor(activeTokenValue ? getLabelName(activeTokenValue) : inputValue)
          "
          :scoped="showScopedLabel(activeTokenValue ? getLabelName(activeTokenValue) : inputValue)"
          :title="activeTokenValue ? getLabelName(activeTokenValue) : inputValue"
      /></template>
    </template>
    <template #suggestions-list="{ suggestions, selections = [] }">
      <gl-filtered-search-suggestion
        v-for="label in suggestions"
        :key="label.id"
        :value="getLabelName(label)"
      >
        <div
          class="gl-flex gl-items-center"
          :class="{ 'gl-pl-6': !selections.includes(label.title) }"
        >
          <gl-icon
            v-if="selections.includes(label.title)"
            name="check"
            class="gl-mr-3 gl-shrink-0"
            variant="subtle"
          />
          <span
            :style="{ backgroundColor: label.color }"
            class="gl-mr-3 gl-inline-block gl-p-3"
          ></span>
          <div>{{ getLabelName(label) }}</div>
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>

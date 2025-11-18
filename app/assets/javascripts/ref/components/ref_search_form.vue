<script>
import { GlFormInputGroup, GlCollapsibleListbox, GlButton, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';
import { setUrlParams, visitUrl, queryToObject } from '~/lib/utils/url_utility';

export const i18n = {
  textInputLabel: s__('RepositoryGraph|Enter a Git revision...'),
  searchButtonLabel: s__('RepositoryGraph|Search revision and rerender the graph'),
  selectDropdownLabel: s__('RepositoryGraph|Select display option'),
};

export const FILTER_OPTIONS = {
  FULL_HISTORY: {
    value: 0,
    text: s__('RepositoryGraph|Display full history'),
  },
  UP_TO_REVISION: {
    value: 1,
    text: s__('RepositoryGraph|Display up to revision'),
  },
};

export const FILTER_OPTIONS_ARRAY = Object.values(FILTER_OPTIONS);

export default {
  i18n,
  filterOptions: FILTER_OPTIONS_ARRAY,
  components: {
    GlFormInputGroup,
    GlCollapsibleListbox,
    GlFormInput,
    GlButton,
  },
  props: {
    networkPath: {
      type: String,
      required: true,
    },
  },
  data() {
    // Get the initial selected option from URL params
    const urlParams = queryToObject(window.location.search);
    const hasFilterRef = urlParams.filter_ref === '1';

    return {
      searchSha: urlParams.extended_sha1 || '',
      selectedOptionIndex: hasFilterRef
        ? FILTER_OPTIONS.UP_TO_REVISION.value
        : FILTER_OPTIONS.FULL_HISTORY.value,
    };
  },
  methods: {
    submitForm() {
      const params = {
        extended_sha1: this.searchSha || null,
        filter_ref: this.selectedOptionIndex === FILTER_OPTIONS.UP_TO_REVISION.value ? '1' : null,
      };

      const baseUrl = new URL(this.networkPath, window.location.origin);
      const url = setUrlParams(params, { url: baseUrl });
      visitUrl(url);
    },
  },
};
</script>
<template>
  <form class="network-form" @submit.prevent="submitForm">
    <gl-form-input-group ref="formInputGroup" class="gl-max-w-62">
      <gl-form-input
        v-model="searchSha"
        :placeholder="`${$options.i18n.textInputLabel}`"
        :aria-label="$options.i18n.textInputLabel"
      />
      <template #prepend>
        <label id="select-display-option-label" class="gl-sr-only">{{
          $options.i18n.selectDropdownLabel
        }}</label>
        <gl-collapsible-listbox
          v-model="selectedOptionIndex"
          :items="$options.filterOptions"
          toggle-aria-labelled-by="select-display-option-label"
          toggle-class="!gl-rounded-tr-none !gl-rounded-br-none"
        />
      </template>
      <template #append>
        <gl-button type="submit" icon="search" :aria-label="$options.i18n.searchButtonLabel" />
      </template>
    </gl-form-input-group>
  </form>
</template>

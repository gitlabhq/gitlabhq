<script>
import { GlButton, GlSearchBoxByType } from '@gitlab/ui';
import { debounce } from 'lodash';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

/**
 * Creates a searchable input for environments.
 *
 * When given a value, it will render it as selected value
 * Otherwise it will render a placeholder for the search input.
 * It will fetch the available environments on focus.
 *
 * When the user types, it will trigger an event to allow
 * for API queries outside of the component.
 *
 * When results are returned, it renders a selectable
 * list with the suggestions
 *
 * When no results are returned, it will render a
 * button with a `Create` label. When clicked, it will
 * emit an event to allow for the creation of a new
 * record.
 *
 */

export default {
  name: 'EnvironmentsSearchableInput',
  components: {
    GlButton,
    GlSearchBoxByType,
  },
  inject: ['environmentsEndpoint'],
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
    placeholder: {
      type: String,
      required: false,
      default: __('Search an environment spec'),
    },
    createButtonLabel: {
      type: String,
      required: false,
      default: __('Create'),
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      environmentSearch: this.value,
      results: [],
      showSuggestions: false,
      isLoading: false,
    };
  },
  computed: {
    /**
     * Creates a label with the value of the filter
     * @returns {String}
     */
    composedCreateButtonLabel() {
      return `${this.createButtonLabel} ${this.environmentSearch}`;
    },
    shouldRenderCreateButton() {
      return !this.isLoading && !this.results.length;
    },
  },
  methods: {
    fetchEnvironments: debounce(function debouncedFetchEnvironments() {
      this.isLoading = true;
      this.openSuggestions();
      axios
        .get(this.environmentsEndpoint, { params: { query: this.environmentSearch } })
        .then(({ data }) => {
          this.results = data || [];
          this.isLoading = false;
        })
        .catch(() => {
          this.isLoading = false;
          this.closeSuggestions();
          createAlert({
            message: __('Something went wrong on our end. Please try again.'),
          });
        });
    }, 250),
    /**
     * Opens the list of suggestions
     */
    openSuggestions() {
      this.showSuggestions = true;
    },
    /**
     * Closes the list of suggestions and cleans the results
     */
    closeSuggestions() {
      this.showSuggestions = false;
      this.environmentSearch = '';
    },
    /**
     * On click, it will:
     *  1. clear the input value
     *  2. close the list of suggestions
     *  3. emit an event
     */
    clearInput() {
      this.closeSuggestions();
      this.$emit('clearInput');
    },
    /**
     * When the user selects a value from the list of suggestions
     *
     * It emits an event with the selected value
     * Clears the filter
     * and closes the list of suggestions
     *
     * @param {String} selected
     */
    selectEnvironment(selected) {
      this.$emit('selectEnvironment', selected);
      this.results = [];
      this.closeSuggestions();
    },

    /**
     * When the user clicks the create button
     * it emits an event with the filter value
     */
    createClicked() {
      this.$emit('createClicked', this.environmentSearch);
      this.closeSuggestions();
    },
  },
};
</script>
<template>
  <div>
    <div class="dropdown position-relative">
      <gl-search-box-by-type
        v-model.trim="environmentSearch"
        class="js-env-search"
        :aria-label="placeholder"
        :placeholder="placeholder"
        :disabled="disabled"
        :is-loading="isLoading"
        @focus="fetchEnvironments"
        @keyup="fetchEnvironments"
      />
      <div
        v-if="showSuggestions"
        class="dropdown-menu dropdown-menu-selectable dropdown-menu-full-width !gl-block"
      >
        <div class="dropdown-content">
          <ul v-if="results.length">
            <li v-for="(result, i) in results" :key="i">
              <gl-button category="tertiary" @click="selectEnvironment(result)">{{
                result
              }}</gl-button>
            </li>
          </ul>
          <div v-else-if="!results.length" class="gl-p-3 gl-text-subtle">
            {{ __('No matching results') }}
          </div>
          <div v-if="shouldRenderCreateButton" class="dropdown-footer">
            <gl-button
              category="tertiary"
              class="js-create-button dropdown-item"
              @click="createClicked"
              >{{ composedCreateButtonLabel }}</gl-button
            >
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

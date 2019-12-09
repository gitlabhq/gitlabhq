import _ from 'underscore';
import { GlLoadingIcon } from '@gitlab/ui';
import DropdownSearchInput from '~/vue_shared/components/dropdown/dropdown_search_input.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';

import store from '../store';

export default {
  store,
  components: {
    DropdownButton,
    DropdownSearchInput,
    DropdownHiddenInput,
    GlLoadingIcon,
  },
  props: {
    fieldId: {
      type: String,
      required: true,
    },
    fieldName: {
      type: String,
      required: true,
    },
    defaultValue: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isLoading: false,
      hasErrors: false,
      searchQuery: '',
      gapiError: '',
    };
  },
  computed: {
    results() {
      if (!this.items) {
        return [];
      }

      return this.items.filter(item => item.name.toLowerCase().indexOf(this.searchQuery) > -1);
    },
  },
  methods: {
    fetchSuccessHandler() {
      if (this.defaultValue) {
        const itemToSelect = _.find(this.items, item => item.name === this.defaultValue);

        if (itemToSelect) {
          this.setItem(itemToSelect.name);
        }
      }

      this.isLoading = false;
      this.hasErrors = false;
    },
    fetchFailureHandler(resp) {
      this.isLoading = false;
      this.hasErrors = true;

      if (resp.result && resp.result.error) {
        this.gapiError = resp.result.error.message;
      }
    },
  },
};

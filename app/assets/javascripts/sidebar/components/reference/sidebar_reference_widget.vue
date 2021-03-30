<script>
import { __ } from '~/locale';
import { referenceQueries } from '~/sidebar/constants';
import CopyableField from '~/vue_shared/components/sidebar/copyable_field.vue';

export default {
  components: {
    CopyableField,
  },
  inject: ['fullPath', 'iid'],
  props: {
    issuableType: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      reference: '',
    };
  },
  apollo: {
    reference: {
      query() {
        return referenceQueries[this.issuableType].query;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update(data) {
        return data.workspace?.issuable?.reference || '';
      },
      error(error) {
        this.$emit('fetch-error', {
          message: __('An error occurred while fetching reference'),
          error,
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.reference.loading;
    },
  },
};
</script>

<template>
  <copyable-field
    class="sub-block"
    :is-loading="isLoading"
    :name="__('Reference')"
    :value="reference"
  />
</template>

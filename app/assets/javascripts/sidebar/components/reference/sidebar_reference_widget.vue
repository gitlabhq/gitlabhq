<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { referenceQueries } from '~/sidebar/constants';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  i18n: {
    copyReference: __('Copy reference'),
    text: __('Reference'),
  },
  components: {
    ClipboardButton,
    GlLoadingIcon,
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
  <div class="sub-block">
    <clipboard-button
      v-if="!isLoading"
      :title="$options.i18n.copyReference"
      :text="reference"
      category="tertiary"
      css-class="sidebar-collapsed-icon dont-change-state"
      tooltip-placement="left"
    />
    <div class="gl-display-flex gl-align-items-center gl-justify-between gl-mb-2 hide-collapsed">
      <span class="gl-overflow-hidden gl-text-overflow-ellipsis gl-white-space-nowrap">
        {{ $options.i18n.text }}: {{ reference }}
        <gl-loading-icon v-if="isLoading" inline :label="$options.i18n.text" />
      </span>
      <clipboard-button
        v-if="!isLoading"
        :title="$options.i18n.copyReference"
        :text="reference"
        size="small"
        category="tertiary"
        css-class="gl-mr-1"
        tooltip-placement="left"
      />
    </div>
  </div>
</template>

<script>
import { GlKeysetPagination } from '@gitlab/ui';
import { setUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

export default {
  name: 'KeysetPagination',
  components: {
    GlKeysetPagination,
  },
  props: {
    startCursor: {
      type: String,
      required: false,
      default: '',
    },
    endCursor: {
      type: String,
      required: false,
      default: '',
    },
    hasNextPage: {
      type: Boolean,
      required: true,
    },
    hasPreviousPage: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    previousPageLink() {
      return setUrlParams({ cursor: this.startCursor });
    },
    nextPageLink() {
      return setUrlParams({ cursor: this.endCursor });
    },
    isPaginationVisible() {
      return this.hasPreviousPage || this.hasNextPage;
    },
  },
  i18n: {
    previousPageButtonLabel: __('Prev'),
    nextPageButtonLabel: __('Next'),
  },
};
</script>

<template>
  <div v-if="isPaginationVisible" class="gl--flex-center">
    <gl-keyset-pagination
      :start-cursor="startCursor"
      :end-cursor="endCursor"
      :has-previous-page="hasPreviousPage"
      :has-next-page="hasNextPage"
      :prev-text="$options.i18n.previousPageButtonLabel"
      :next-text="$options.i18n.nextPageButtonLabel"
      :prev-button-link="previousPageLink"
      :next-button-link="nextPageLink"
      class="gl-mt-4"
    />
  </div>
</template>

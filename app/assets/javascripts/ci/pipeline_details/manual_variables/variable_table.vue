<script>
import { GlButton, GlPagination, GlTableLite, GlTruncate } from '@gitlab/ui';
import { __ } from '~/locale';

// The number of items per page is based on the design mockup.
// Please refer to https://gitlab.com/gitlab-org/gitlab/-/issues/323097/designs/TabVariables.png
const VARIABLES_PER_PAGE = 15;

export default {
  components: {
    GlButton,
    GlPagination,
    GlTableLite,
    GlTruncate,
  },
  inject: ['manualVariablesCount', 'canReadVariables'],
  props: {
    variables: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      revealed: false,
      currentPage: 1,
      hasPermission: true,
    };
  },
  computed: {
    buttonText() {
      return this.revealed ? __('Hide values') : __('Reveal values');
    },
    showPager() {
      return this.manualVariablesCount > VARIABLES_PER_PAGE;
    },
    items() {
      const start = (this.currentPage - 1) * VARIABLES_PER_PAGE;
      const end = start + VARIABLES_PER_PAGE;
      return this.variables.slice(start, end);
    },
  },
  methods: {
    toggleRevealed() {
      this.revealed = !this.revealed;
    },
  },
  TABLE_FIELDS: [
    {
      key: 'key',
      label: __('Key'),
      thClass: 'gl-w-1/4 gl-whitespace-nowrap',
      tdClass: 'gl-max-w-15',
    },
    {
      key: 'value',
      label: __('Value'),
    },
  ],
  VARIABLES_PER_PAGE,
};
</script>

<template>
  <!-- This negative margin top is a hack for the purpose to eliminate default padding of tab container -->
  <!-- For context refer to: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159206#note_1999122459 -->
  <div class="-gl-mt-3">
    <div v-if="canReadVariables" class="gl-bg-subtle gl-p-3">
      <gl-button :aria-label="buttonText" @click="toggleRevealed">{{ buttonText }}</gl-button>
    </div>
    <gl-table-lite :fields="$options.TABLE_FIELDS" :items="items">
      <template #cell(key)="{ value }">
        <gl-truncate :text="value" class="gl-text-subtle" />
      </template>
      <template #cell(value)="{ value }">
        <div class="gl-text-subtle" data-testid="manual-variable-value">
          <span v-if="revealed">{{ value }}</span>
          <span v-else>****</span>
        </div>
      </template>
    </gl-table-lite>
    <gl-pagination
      v-if="showPager"
      v-model="currentPage"
      class="gl-mt-6"
      :per-page="$options.VARIABLES_PER_PAGE"
      :total-items="manualVariablesCount"
      align="center"
    />
  </div>
</template>

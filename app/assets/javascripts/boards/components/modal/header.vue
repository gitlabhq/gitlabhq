<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import ModalFilters from './filters';
import ModalTabs from './tabs.vue';
import ModalStore from '../../stores/modal_store';
import modalMixin from '../../mixins/modal_mixins';

export default {
  components: {
    ModalTabs,
    ModalFilters,
    GlButton,
  },
  mixins: [modalMixin],
  props: {
    projectId: {
      type: Number,
      required: true,
    },
    labelPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return ModalStore.store;
  },
  computed: {
    selectAllText() {
      if (ModalStore.selectedCount() !== this.issues.length || this.issues.length === 0) {
        return __('Select all');
      }

      return __('Deselect all');
    },
    showSearch() {
      return this.activeTab === 'all' && !this.loading && this.issuesCount > 0;
    },
  },
  methods: {
    toggleAll() {
      this.$refs.selectAllBtn.$el.blur();

      ModalStore.toggleAll();
    },
  },
};
</script>
<template>
  <div>
    <header class="add-issues-header border-top-0 form-actions">
      <h2 class="m-0">
        Add issues
        <gl-button
          category="tertiary"
          icon="close"
          class="close"
          data-dismiss="modal"
          :aria-label="__('Close')"
          @click="toggleModal(false)"
        />
      </h2>
    </header>
    <modal-tabs v-if="!loading && issuesCount > 0" />
    <div v-if="showSearch" class="d-flex gl-mb-3">
      <modal-filters :store="filter" />
      <gl-button
        ref="selectAllBtn"
        category="secondary"
        variant="success"
        class="gl-ml-3"
        @click="toggleAll"
      >
        {{ selectAllText }}
      </gl-button>
    </div>
  </div>
</template>

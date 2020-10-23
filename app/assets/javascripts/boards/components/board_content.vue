<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { sortBy } from 'lodash';
import BoardColumn from 'ee_else_ce/boards/components/board_column.vue';
import { GlAlert } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    BoardColumn,
    BoardContentSidebar: () => import('ee_component/boards/components/board_content_sidebar.vue'),
    EpicsSwimlanes: () => import('ee_component/boards/components/epics_swimlanes.vue'),
    GlAlert,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    lists: {
      type: Array,
      required: true,
    },
    canAdminList: {
      type: Boolean,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState(['boardLists', 'error']),
    ...mapGetters(['isSwimlanesOn']),
    boardListsToUse() {
      const lists =
        this.glFeatures.graphqlBoardLists || this.isSwimlanesOn ? this.boardLists : this.lists;
      return sortBy([...Object.values(lists)], 'position');
    },
  },
  mounted() {
    if (this.glFeatures.graphqlBoardLists) {
      this.showPromotionList();
    }
  },
  methods: {
    ...mapActions(['showPromotionList']),
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" :dismissible="false">
      {{ error }}
    </gl-alert>
    <div
      v-if="!isSwimlanesOn"
      class="boards-list gl-w-full gl-py-5 gl-px-3 gl-white-space-nowrap"
      data-qa-selector="boards_list"
    >
      <board-column
        v-for="list in boardListsToUse"
        :key="list.id"
        ref="board"
        :can-admin-list="canAdminList"
        :list="list"
        :disabled="disabled"
      />
    </div>

    <template v-else>
      <epics-swimlanes
        ref="swimlanes"
        :lists="boardListsToUse"
        :can-admin-list="canAdminList"
        :disabled="disabled"
      />
      <board-content-sidebar />
    </template>
  </div>
</template>

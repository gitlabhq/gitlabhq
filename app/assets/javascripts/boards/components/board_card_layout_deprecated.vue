<script>
import { mapActions, mapGetters } from 'vuex';
import { ISSUABLE } from '~/boards/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import boardsStore from '../stores/boards_store';
import IssueCardInnerDeprecated from './issue_card_inner_deprecated.vue';

export default {
  name: 'BoardCardLayout',
  components: {
    IssueCardInner: IssueCardInnerDeprecated,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    list: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    issue: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    },
    index: {
      type: Number,
      default: 0,
      required: false,
    },
    isActive: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      showDetail: false,
      multiSelect: boardsStore.multiSelect,
    };
  },
  computed: {
    ...mapGetters(['isSwimlanesOn']),
    multiSelectVisible() {
      return this.multiSelect.list.findIndex((issue) => issue.id === this.issue.id) > -1;
    },
  },
  methods: {
    ...mapActions(['setActiveId']),
    mouseDown() {
      this.showDetail = true;
    },
    mouseMove() {
      this.showDetail = false;
    },
    showIssue(e) {
      // Don't do anything if this happened on a no trigger element
      if (e.target.classList.contains('js-no-trigger')) return;

      if (this.glFeatures.graphqlBoardLists || this.isSwimlanesOn) {
        this.setActiveId({ id: this.issue.id, sidebarType: ISSUABLE });
        return;
      }

      const isMultiSelect = e.ctrlKey || e.metaKey;

      if (this.showDetail || isMultiSelect) {
        this.showDetail = false;
        this.$emit('show', { event: e, isMultiSelect });
      }
    },
  },
};
</script>

<template>
  <li
    :class="{
      'multi-select': multiSelectVisible,
      'user-can-drag': !disabled && issue.id,
      'is-disabled': disabled || !issue.id,
      'is-active': isActive,
    }"
    :index="index"
    :data-issue-id="issue.id"
    :data-issue-iid="issue.iid"
    :data-issue-path="issue.referencePath"
    data-testid="board_card"
    class="board-card gl-p-5 gl-rounded-base"
    @mousedown="mouseDown"
    @mousemove="mouseMove"
    @mouseup="showIssue($event)"
  >
    <issue-card-inner :list="list" :issue="issue" :update-filters="true" />
  </li>
</template>

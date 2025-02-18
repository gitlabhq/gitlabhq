<script>
import { GlCollapse, GlBadge, GlButton, GlIcon, GlSkeletonLoader, GlLoadingIcon } from '@gitlab/ui';
import {
  CONTAINING_COMMIT,
  FETCH_CONTAINING_REFS_EVENT,
  BRANCHES_REF_TYPE,
  EMPTY_BRANCHES_MESSAGE,
  EMPTY_TAGS_MESSAGE,
} from '../constants';

export default {
  name: 'RefsList',
  components: {
    GlCollapse,
    GlSkeletonLoader,
    GlBadge,
    GlButton,
    GlIcon,
    GlLoadingIcon,
  },
  props: {
    urlPart: {
      type: String,
      required: true,
    },
    refType: {
      type: String,
      required: true,
    },
    containingRefs: {
      type: Array,
      required: false,
      default: () => [],
    },
    tippingRefs: {
      type: Array,
      required: false,
      default: () => [],
    },
    namespace: {
      type: String,
      required: true,
    },
    hasContainingRefs: {
      type: Boolean,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isContainingRefsVisible: false,
    };
  },
  computed: {
    collapseIcon() {
      return this.isContainingRefsVisible ? 'chevron-down' : 'chevron-right';
    },
    isLoadingRefs() {
      return this.isLoading && !this.containingRefs.length;
    },
    refIcon() {
      return this.refType === BRANCHES_REF_TYPE ? 'branch' : 'tag';
    },
    showEmptyMessage() {
      return this.tippingRefs.length === 0 && this.containingRefs.length === 0 && !this.isLoading;
    },
    showNameSpace() {
      return (this.tippingRefs.length !== 0 || this.containingRefs.length !== 0) && !this.isLoading;
    },
    emptyMessage() {
      return this.refType === BRANCHES_REF_TYPE ? EMPTY_BRANCHES_MESSAGE : EMPTY_TAGS_MESSAGE;
    },
  },
  methods: {
    toggleCollapse() {
      this.isContainingRefsVisible = !this.isContainingRefsVisible;
    },
    showRefs() {
      this.toggleCollapse();
      this.$emit(FETCH_CONTAINING_REFS_EVENT);
    },
    getRefUrl(ref) {
      return `${this.urlPart}${ref}?ref_type=${this.refType}`;
    },
  },
  i18n: {
    containingCommit: CONTAINING_COMMIT,
  },
};
</script>

<template>
  <div>
    <gl-icon :name="refIcon" variant="default" :size="16" class="gl-ml-2 gl-mr-3" />
    <gl-loading-icon v-if="isLoading" size="sm" inline />
    <span v-if="showEmptyMessage">{{ emptyMessage }}</span>
    <span v-else-if="showNameSpace" data-testid="title" class="gl-mr-2">{{ namespace }}</span>
    <gl-badge
      v-for="ref in tippingRefs"
      :key="ref"
      :href="getRefUrl(ref)"
      class="gl-mr-2 gl-mt-2"
      >{{ ref }}</gl-badge
    >
    <gl-button
      v-if="hasContainingRefs"
      class="gl-mr-2 !gl-text-sm"
      variant="link"
      size="small"
      @click="showRefs"
    >
      <gl-icon :name="collapseIcon" :size="14" />
      {{ namespace }} {{ $options.i18n.containingCommit }}
    </gl-button>
    <gl-collapse :visible="isContainingRefsVisible">
      <gl-skeleton-loader v-if="isLoadingRefs" :lines="1" />
      <template v-else>
        <gl-badge
          v-for="ref in containingRefs"
          :key="ref"
          :href="getRefUrl(ref)"
          class="gl-mr-2 gl-mt-3"
          >{{ ref }}</gl-badge
        >
      </template>
    </gl-collapse>
  </div>
</template>

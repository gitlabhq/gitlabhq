<script>
import { GlCollapse, GlBadge, GlButton, GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import { CONTAINING_COMMIT, FETCH_CONTAINING_REFS_EVENT, BRANCHES_REF_TYPE } from '../constants';

export default {
  name: 'RefsList',
  components: {
    GlCollapse,
    GlSkeletonLoader,
    GlBadge,
    GlButton,
    GlIcon,
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
  <div class="ref-list gl-p-5 gl-border-b-solid gl-border-b-1">
    <gl-icon :name="refIcon" :size="14" class="gl-ml-2 gl-mr-3" />
    <span data-testid="title" class="gl-mr-2">{{ namespace }}</span>
    <gl-badge
      v-for="ref in tippingRefs"
      :key="ref"
      :href="getRefUrl(ref)"
      class="gl-mt-2 gl-mr-2"
      size="sm"
      >{{ ref }}</gl-badge
    >
    <gl-button
      v-if="hasContainingRefs"
      class="gl-mr-2 gl-font-sm!"
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
          class="gl-mt-3 gl-mr-2"
          size="sm"
          >{{ ref }}</gl-badge
        >
      </template>
    </gl-collapse>
  </div>
</template>

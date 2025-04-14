<script>
import { GlIcon, GlLabel } from '@gitlab/ui';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';
import { isScopedLabel } from '~/lib/utils/common_utils';

export default {
  components: {
    GlIcon,
    GlLabel,
    WorkItemTypeIcon,
    IssueMilestone,
    IssueWeight: () => import('ee_component/issues/components/issue_weight.vue'),
    IssueHealthStatus: () =>
      import('ee_component/related_items_tree/components/issue_health_status.vue'),
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    itemReferencePath() {
      const { reference } = this.item;
      return reference.split('#')[0];
    },
    directNamespaceReference() {
      return this.itemReferencePath.split('/').slice(-1)[0];
    },
  },
  methods: {
    scopedLabel(label) {
      return isScopedLabel(label);
    },
  },
};
</script>
<template>
  <li
    class="board-card gl-border gl-relative gl-mb-3 gl-rounded-base gl-border-section gl-bg-section gl-leading-normal hover:gl-bg-subtle dark:hover:gl-bg-gray-200"
  >
    <button
      class="board-card-button gl-block gl-h-full gl-w-full gl-rounded-base gl-border-0 gl-bg-transparent gl-p-4 gl-text-left gl-outline-none focus:gl-focus"
    >
      <div class="gl-flex" dir="auto">
        <h4
          class="board-card-title gl-mb-0 gl-mt-0 gl-min-w-0 gl-hyphens-auto gl-break-words gl-text-base"
        >
          <gl-icon
            v-if="item.confidential"
            name="eye-slash"
            data-testid="confidential-icon"
            :title="__('Confidential')"
            class="gl-mr-2 gl-cursor-help"
            :aria-label="__('Confidential')"
            variant="warning"
          />
          <a
            :href="item.path || item.webUrl || ''"
            :title="item.title"
            class="gl-text-default hover:gl-text-default"
            data-testid="board-card-title-link"
            @mousemove.stop
            >{{ item.title }}</a
          >
        </h4>
      </div>
      <div v-if="item.labels.length > 0" class="board-card-labels gl-mt-2 gl-flex gl-flex-wrap">
        <gl-label
          v-for="label in item.labels"
          :key="label.id"
          class="js-no-trigger gl-mr-2 gl-mt-2"
          :background-color="label.color"
          :title="label.title"
          :description="label.description"
          target="#"
          :scoped="scopedLabel(label)"
        />
      </div>
      <div class="board-card-footer gl-mt-3 gl-flex gl-items-end gl-justify-between">
        <div
          class="align-items-start board-card-number-container gl-flex gl-flex-wrap-reverse gl-overflow-hidden"
        >
          <span class="board-info-items gl-inline-block gl-leading-20">
            <span
              class="board-card-number gl-mr-3 gl-mt-3 gl-gap-2 gl-overflow-hidden gl-text-sm gl-text-subtle"
            >
              <work-item-type-icon :work-item-type="item.type.name" show-tooltip-on-hover />
              <span
                :title="itemReferencePath"
                data-placement="bottom"
                class="board-item-path gl-cursor-help gl-truncate gl-font-bold"
              >
                {{ directNamespaceReference }}
              </span>
              #{{ item.iid }}
            </span>
            <issue-weight v-if="item.weight !== undefined" :weight="item.weight.value" />
            <issue-milestone
              v-if="item.milestone"
              data-testid="issue-milestone"
              :milestone="item.milestone"
              class="gl-mr-3 gl-inline-flex gl-max-w-15 gl-cursor-help gl-items-center gl-align-bottom gl-text-sm gl-text-subtle"
            />
            <issue-health-status v-if="item.healthStatus" :health-status="item.healthStatus" />
          </span>
        </div>
      </div>
    </button>
  </li>
</template>

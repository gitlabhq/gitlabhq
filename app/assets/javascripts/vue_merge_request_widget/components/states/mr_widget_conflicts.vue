<script>
import $ from 'jquery';
import { escape } from 'lodash';
import { s__, sprintf } from '~/locale';
import { mouseenter, debouncedMouseleave, togglePopover } from '~/shared/popover';
import StatusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetConflicts',
  components: {
    StatusIcon,
  },
  props: {
    /* TODO: This is providing all store and service down when it
      only needs a few props */
    mr: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },
  computed: {
    popoverTitle() {
      return s__(
        'mrWidget|This feature merges changes from the target branch to the source branch. You cannot use this feature since the source branch is protected.',
      );
    },
    showResolveButton() {
      return this.mr.conflictResolutionPath && this.mr.canPushToSourceBranch;
    },
    showPopover() {
      return this.showResolveButton && this.mr.sourceBranchProtected;
    },
  },
  mounted() {
    if (this.showPopover) {
      const $el = $(this.$refs.popover);

      $el
        .popover({
          html: true,
          trigger: 'focus',
          container: 'body',
          placement: 'top',
          template:
            '<div class="popover" role="tooltip"><div class="arrow"></div><p class="popover-header"></p><div class="popover-body"></div></div>',
          title: s__(
            'mrWidget|This feature merges changes from the target branch to the source branch. You cannot use this feature since the source branch is protected.',
          ),
          content: sprintf(
            s__('mrWidget|%{link_start}Learn more about resolving conflicts%{link_end}'),
            {
              link_start: `<a href="${escape(
                this.mr.conflictsDocsPath,
              )}" target="_blank" rel="noopener noreferrer">`,
              link_end: '</a>',
            },
            false,
          ),
        })
        .on('mouseenter', mouseenter)
        .on('mouseleave', debouncedMouseleave(300))
        .on('show.bs.popover', () => {
          window.addEventListener('scroll', togglePopover.bind($el, false), { once: true });
        });
    }
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="true" status="warning" />

    <div class="media-body space-children">
      <span v-if="mr.shouldBeRebased" class="bold">
        {{
          s__(`mrWidget|Fast-forward merge is not possible.
To merge this request, first rebase locally.`)
        }}
      </span>
      <template v-else>
        <span class="bold">
          {{ s__('mrWidget|There are merge conflicts') }}<span v-if="!mr.canMerge">.</span>
          <span v-if="!mr.canMerge">
            {{
              s__(`mrWidget|Resolve these conflicts or ask someone
            with write access to this repository to merge it locally`)
            }}
          </span>
        </span>
        <span v-if="showResolveButton" ref="popover">
          <a
            :href="mr.conflictResolutionPath"
            :disabled="mr.sourceBranchProtected"
            class="js-resolve-conflicts-button btn btn-default btn-sm"
          >
            {{ s__('mrWidget|Resolve conflicts') }}
          </a>
        </span>
        <button
          v-if="mr.canMerge"
          class="js-merge-locally-button btn btn-default btn-sm"
          data-toggle="modal"
          data-target="#modal_merge_info"
        >
          {{ s__('mrWidget|Merge locally') }}
        </button>
      </template>
    </div>
  </div>
</template>

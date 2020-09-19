<script>
import { GlLink, GlLabel, GlTooltipDirective } from '@gitlab/ui';

import { __, sprintf } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { isScopedLabel } from '~/lib/utils/common_utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    GlLink,
    GlLabel,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    issuableSymbol: {
      type: String,
      required: true,
    },
    issuable: {
      type: Object,
      required: true,
    },
  },
  computed: {
    author() {
      return this.issuable.author;
    },
    authorId() {
      const id = parseInt(this.author.id, 10);

      if (Number.isNaN(id)) {
        return this.author.id.includes('gid')
          ? this.author.id.split('gid://gitlab/User/').pop()
          : '';
      }

      return id;
    },
    labels() {
      return this.issuable.labels?.nodes || this.issuable.labels || [];
    },
    createdAt() {
      return sprintf(__('created %{timeAgo}'), {
        timeAgo: getTimeago().format(this.issuable.createdAt),
      });
    },
    updatedAt() {
      return sprintf(__('updated %{timeAgo}'), {
        timeAgo: getTimeago().format(this.issuable.updatedAt),
      });
    },
  },
  methods: {
    scopedLabel(label) {
      return isScopedLabel(label);
    },
    /**
     * This is needed as an independent method since
     * when user changes current page, `$refs.authorLink`
     * will be null until next page results are loaded & rendered.
     */
    getAuthorPopoverTarget() {
      if (this.$refs.authorLink) {
        return this.$refs.authorLink.$el;
      }
      return '';
    },
  },
};
</script>

<template>
  <li class="issue">
    <div class="issue-box">
      <div class="issuable-info-container">
        <div class="issuable-main-info">
          <div data-testid="issuable-title" class="issue-title title">
            <span class="issue-title-text" dir="auto">
              <gl-link :href="issuable.webUrl">{{ issuable.title }}</gl-link>
            </span>
          </div>
          <div class="issuable-info">
            <span data-testid="issuable-reference" class="issuable-reference"
              >{{ issuableSymbol }}{{ issuable.iid }}</span
            >
            <span class="issuable-authored d-none d-sm-inline-block">
              &middot;
              <span
                v-gl-tooltip:tooltipcontainer.bottom
                data-testid="issuable-created-at"
                :title="tooltipTitle(issuable.createdAt)"
                >{{ createdAt }}</span
              >
              {{ __('by') }}
              <gl-link
                :data-user-id="authorId"
                :data-username="author.username"
                :data-name="author.name"
                :data-avatar-url="author.avatarUrl"
                :href="author.webUrl"
                data-testid="issuable-author"
                class="author-link js-user-link"
              >
                <span class="author">{{ author.name }}</span>
              </gl-link>
            </span>
            &nbsp;
            <gl-label
              v-for="(label, index) in labels"
              :key="index"
              :background-color="label.color"
              :title="label.title"
              :description="label.description"
              :scoped="scopedLabel(label)"
              :class="{ 'gl-ml-2': index }"
              size="sm"
            />
          </div>
        </div>
        <div class="issuable-meta">
          <div
            data-testid="issuable-updated-at"
            class="float-right issuable-updated-at d-none d-sm-inline-block"
          >
            <span
              v-gl-tooltip:tooltipcontainer.bottom
              :title="tooltipTitle(issuable.updatedAt)"
              class="issuable-updated-at"
              >{{ updatedAt }}</span
            >
          </div>
        </div>
      </div>
    </div>
  </li>
</template>

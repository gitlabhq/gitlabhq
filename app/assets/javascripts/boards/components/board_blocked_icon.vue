<script>
import { GlIcon, GlLink, GlPopover, GlLoadingIcon } from '@gitlab/ui';
import { blockingIssuablesQueries, issuableTypes } from '~/boards/constants';
import { TYPE_ISSUE } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { truncate } from '~/lib/utils/text_utility';
import { __, n__, s__, sprintf } from '~/locale';

export default {
  i18n: {
    issuableType: {
      [issuableTypes.issue]: __('issue'),
    },
  },
  graphQLIdType: {
    [issuableTypes.issue]: TYPE_ISSUE,
  },
  referenceFormatter: {
    [issuableTypes.issue]: (r) => r.split('/')[1],
  },
  defaultDisplayLimit: 3,
  textTruncateWidth: 80,
  components: {
    GlIcon,
    GlPopover,
    GlLink,
    GlLoadingIcon,
  },
  blockingIssuablesQueries,
  props: {
    item: {
      type: Object,
      required: true,
    },
    uniqueId: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: true,
      validator(value) {
        return [issuableTypes.issue].includes(value);
      },
    },
  },
  apollo: {
    blockingIssuables: {
      skip() {
        return this.skip;
      },
      query() {
        return blockingIssuablesQueries[this.issuableType].query;
      },
      variables() {
        return {
          id: convertToGraphQLId(this.$options.graphQLIdType[this.issuableType], this.item.id),
        };
      },
      update(data) {
        this.skip = true;

        return data?.issuable?.blockingIssuables?.nodes || [];
      },
      error(error) {
        const message = sprintf(s__('Boards|Failed to fetch blocking %{issuableType}s'), {
          issuableType: this.issuableTypeText,
        });
        this.$emit('blocking-issuables-error', { error, message });
      },
    },
  },
  data() {
    return {
      skip: true,
      blockingIssuables: [],
    };
  },
  computed: {
    displayedIssuables() {
      const { defaultDisplayLimit, referenceFormatter } = this.$options;
      return this.blockingIssuables.slice(0, defaultDisplayLimit).map((i) => {
        return {
          ...i,
          title: truncate(i.title, this.$options.textTruncateWidth),
          reference: referenceFormatter[this.issuableType](i.reference),
        };
      });
    },
    loading() {
      return this.$apollo.queries.blockingIssuables.loading;
    },
    issuableTypeText() {
      return this.$options.i18n.issuableType[this.issuableType];
    },
    blockedLabel() {
      return sprintf(
        n__(
          'Boards|Blocked by %{blockedByCount} %{issuableType}',
          'Boards|Blocked by %{blockedByCount} %{issuableType}s',
          this.item.blockedByCount,
        ),
        {
          blockedByCount: this.item.blockedByCount,
          issuableType: this.issuableTypeText,
        },
      );
    },
    glIconId() {
      return `blocked-icon-${this.uniqueId}`;
    },
    hasMoreIssuables() {
      return this.item.blockedByCount > this.$options.defaultDisplayLimit;
    },
    displayedIssuablesCount() {
      return this.hasMoreIssuables
        ? this.item.blockedByCount - this.$options.defaultDisplayLimit
        : this.item.blockedByCount;
    },
    moreIssuablesText() {
      return sprintf(
        n__(
          'Boards|+ %{displayedIssuablesCount} more %{issuableType}',
          'Boards|+ %{displayedIssuablesCount} more %{issuableType}s',
          this.displayedIssuablesCount,
        ),
        {
          displayedIssuablesCount: this.displayedIssuablesCount,
          issuableType: this.issuableTypeText,
        },
      );
    },
    viewAllIssuablesText() {
      return sprintf(s__('Boards|View all blocking %{issuableType}s'), {
        issuableType: this.issuableTypeText,
      });
    },
    loadingMessage() {
      return sprintf(s__('Boards|Retrieving blocking %{issuableType}s'), {
        issuableType: this.issuableTypeText,
      });
    },
  },
  methods: {
    handleMouseEnter() {
      this.skip = false;
    },
  },
};
</script>
<template>
  <div class="gl-display-inline">
    <gl-icon
      :id="glIconId"
      ref="icon"
      name="issue-block"
      class="issue-blocked-icon gl-mr-2 gl-cursor-pointer"
      data-testid="issue-blocked-icon"
      @mouseenter="handleMouseEnter"
    />
    <gl-popover :target="glIconId" placement="top">
      <template #title
        ><span data-testid="popover-title">{{ blockedLabel }}</span></template
      >
      <template v-if="loading">
        <gl-loading-icon size="sm" />
        <p class="gl-mt-4 gl-mb-0 gl-font-small">{{ loadingMessage }}</p>
      </template>
      <template v-else>
        <ul class="gl-list-style-none gl-p-0">
          <li v-for="issuable in displayedIssuables" :key="issuable.id">
            <gl-link :href="issuable.webUrl" class="gl-text-blue-500! gl-font-sm">{{
              issuable.reference
            }}</gl-link>
            <p class="gl-mb-3 gl-display-block!" data-testid="issuable-title">
              {{ issuable.title }}
            </p>
          </li>
        </ul>
        <div v-if="hasMoreIssuables" class="gl-mt-4">
          <p class="gl-mb-3" data-testid="hidden-blocking-count">{{ moreIssuablesText }}</p>
          <gl-link
            data-testid="view-all-issues"
            :href="`${item.webUrl}#related-issues`"
            class="gl-text-blue-500! gl-font-sm"
            >{{ viewAllIssuablesText }}</gl-link
          >
        </div>
      </template>
    </gl-popover>
  </div>
</template>

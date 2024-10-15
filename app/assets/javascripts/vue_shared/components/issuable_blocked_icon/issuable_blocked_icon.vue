<script>
import { GlIcon, GlLink, GlPopover, GlLoadingIcon } from '@gitlab/ui';
import { TYPENAME_ISSUE, TYPENAME_EPIC } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import { truncate } from '~/lib/utils/text_utility';
import { __, n__, s__, sprintf } from '~/locale';
import { blockingIssuablesQueries } from './constants';

export default {
  i18n: {
    issuableType: {
      [TYPE_ISSUE]: __('issue'),
      [TYPE_EPIC]: __('epic'),
    },
  },
  graphQLIdType: {
    [TYPE_ISSUE]: TYPENAME_ISSUE,
    [TYPE_EPIC]: TYPENAME_EPIC,
  },
  referenceFormatter: {
    [TYPE_ISSUE]: (r) => r.split('/')[1],
  },
  defaultDisplayLimit: 3,
  textTruncateWidth: 80,
  components: {
    GlIcon,
    GlPopover,
    GlLink,
    GlLoadingIcon,
  },
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
        return [TYPE_ISSUE, TYPE_EPIC].includes(value);
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
        if (this.isEpic) {
          return {
            fullPath: this.item.group.fullPath,
            iid: Number(this.item.iid),
          };
        }
        return {
          id: convertToGraphQLId(this.$options.graphQLIdType[this.issuableType], this.item.id),
        };
      },
      update(data) {
        this.skip = true;
        const issuable = this.isEpic ? data?.group?.issuable : data?.issuable;

        return issuable?.blockingIssuables?.nodes || [];
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
    isEpic() {
      return this.issuableType === TYPE_EPIC;
    },
    displayedIssuables() {
      const { defaultDisplayLimit, referenceFormatter } = this.$options;
      return this.blockingIssuables.slice(0, defaultDisplayLimit).map((i) => {
        return {
          ...i,
          title: truncate(i.title, this.$options.textTruncateWidth),
          reference: this.isEpic ? i.reference : referenceFormatter[this.issuableType](i.reference),
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
    blockIcon() {
      return this.issuableType === TYPE_ISSUE ? 'entity-blocked' : 'entity-blocked';
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
  <div class="gl-inline">
    <gl-icon
      :id="glIconId"
      ref="icon"
      :name="blockIcon"
      class="issuable-blocked-icon gl-mr-2 gl-cursor-pointer gl-text-red-500"
      data-testid="issuable-blocked-icon"
      @mouseenter="handleMouseEnter"
    />
    <gl-popover :target="glIconId" placement="top">
      <template #title
        ><span data-testid="popover-title">{{ blockedLabel }}</span></template
      >
      <template v-if="loading">
        <gl-loading-icon size="sm" />
        <p class="gl-mb-0 gl-mt-4">{{ loadingMessage }}</p>
      </template>
      <template v-else>
        <ul class="gl-mb-0 gl-list-none gl-p-0">
          <li v-for="(issuable, index) in displayedIssuables" :key="issuable.id">
            <gl-link :href="issuable.webUrl" class="gl-text-sm !gl-text-link">{{
              issuable.reference
            }}</gl-link>
            <p
              class="!gl-block"
              :class="{
                'gl-mb-3': index < displayedIssuables.length - 1,
                'gl-mb-0': index === displayedIssuables.length - 1,
              }"
              data-testid="issuable-title"
            >
              {{ issuable.title }}
            </p>
          </li>
        </ul>
        <div v-if="hasMoreIssuables" class="gl-mt-4">
          <p class="gl-mb-3" data-testid="hidden-blocking-count">{{ moreIssuablesText }}</p>
          <gl-link
            data-testid="view-all-issues"
            :href="`${item.webUrl}#related-issues`"
            class="gl-text-sm !gl-text-link"
            >{{ viewAllIssuablesText }}</gl-link
          >
        </div>
      </template>
    </gl-popover>
  </div>
</template>

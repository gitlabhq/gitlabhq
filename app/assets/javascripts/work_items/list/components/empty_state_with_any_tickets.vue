<script>
import emptyStateSvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-service-desk-md.svg';
import { GlEmptyState } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  name: 'EmptyStateWithAnyTickets',
  emptyStateSvg,
  components: {
    GlEmptyState,
  },
  props: {
    hasSearch: {
      type: Boolean,
      required: true,
    },
    isOpenTab: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    content() {
      if (this.hasSearch) {
        return {
          title: __('Sorry, your filter produced no results'),
          description: __('To widen your search, change or remove filters above'),
        };
      }

      if (this.isOpenTab) {
        return {
          title: __('There are no open issues'),
          description: s__(
            'ServiceDesk|Tickets created from Service Desk emails will appear here. Each comment becomes part of the email conversation.',
          ),
        };
      }

      return { title: __('There are no closed issues') };
    },
  },
};
</script>

<template>
  <gl-empty-state
    :description="content.description"
    :title="content.title"
    :svg-path="$options.emptyStateSvg"
    data-testid="issuable-empty-state"
  />
</template>

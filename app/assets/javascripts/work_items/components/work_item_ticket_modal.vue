<script>
import { GlEmptyState, GlModal, GlSprintf } from '@gitlab/ui';

export default {
  name: 'WorkItemTicketModal',
  components: {
    GlEmptyState,
    GlModal,
    GlSprintf,
  },
  emits: ['hide'],
};
</script>

<template>
  <gl-modal
    modal-id="work-item-ticket-modal"
    hide-footer
    size="sm"
    visible
    :aria-label="s__('WorkItem|A new experience for Tickets')"
    @hide="$emit('hide')"
  >
    <gl-empty-state
      class="gl-mt-0"
      illustration-name="empty-issues-md"
      :title="s__('WorkItem|A new experience for Tickets')"
    >
      <template #description>
        <gl-sprintf
          :message="
            s__(
              'WorkItem|Your Service Desk items are now Tickets, complete with %{boldStart}status%{boldEnd}, %{boldStart}custom fields%{boldEnd}, and an %{boldStart}enhanced UI%{boldEnd}. As a separate type, you can filter to just Ticket items, or define statuses and custom fields just for tickets.',
            )
          "
        >
          <template #bold="{ content }">
            <span class="gl-font-bold">{{ content }}</span>
          </template>
        </gl-sprintf>
      </template>
    </gl-empty-state>
  </gl-modal>
</template>

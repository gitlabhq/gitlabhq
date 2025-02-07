<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';

export default {
  name: 'GroupListItemPreventDeleteModal',
  i18n: {
    title: __("Group can't be be deleted"),
    message: __(
      "This group can't be deleted because it is linked to a subscription. To delete this group, %{linkStart}link the subscription%{linkEnd} with a different group.",
    ),
  },
  components: {
    GlModal,
    GlSprintf,
    HelpPageLink,
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
    group: {
      type: Object,
      required: true,
    },
  },
  CANCEL_PROPS: {
    text: __('Cancel'),
  },
};
</script>
<template>
  <gl-modal
    :visible="visible"
    :modal-id="modalId"
    :data-testid="modalId"
    :title="$options.i18n.title"
    size="sm"
    :action-cancel="$options.CANCEL_PROPS"
    @change="$emit('change', $event)"
  >
    <gl-sprintf :message="$options.i18n.message">
      <template #link="{ content }">
        <help-page-link
          href="subscriptions/gitlab_com/_index"
          anchor="link-subscription-to-a-group"
          >{{ content }}</help-page-link
        >
      </template>
    </gl-sprintf>
  </gl-modal>
</template>

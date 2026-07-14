<script>
import { s__ } from '~/locale';
import { VARIANT_DEFAULT } from '../../constants';
import { isValidVariant } from '../../utils';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventApproved',
  i18n: {
    message: s__(
      'ContributionEvent|Approved merge request %{targetLink} in %{resourceParentLink}.',
    ),
  },
  components: { ContributionEventBase },
  props: {
    /**
     * Expected format
     * {
     *   created_at: string;
     *   action: "approved"
     *   author: {
     *     id: number;
     *     username: string;
     *     name: string;
     *     state: string;
     *     avatar_url: string;
     *     web_url: string;
     *   };
     *   target: {
     *     id: number;
     *     type: "MergeRequest"
     *     title: string;
     *     reference_link_text: string;
     *     web_url: string;
     *   };
     *   resource_parent: {
     *     type: "project";
     *     full_name: string;
     *     full_path: string;
     *     web_url: string;
     *     avatar_url: string;
     *   };
     * };
     */
    event: {
      type: Object,
      required: true,
    },
    variant: {
      type: String,
      required: false,
      default: VARIANT_DEFAULT,
      validator: isValidVariant,
    },
  },
};
</script>

<template>
  <contribution-event-base
    :event="event"
    :variant="variant"
    :message="$options.i18n.message"
    icon-name="approval-solid"
  />
</template>

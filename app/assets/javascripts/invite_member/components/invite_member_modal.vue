<script>
import { GlModal, GlLink } from '@gitlab/ui';
import eventHub from '../event_hub';
import { s__, __ } from '~/locale';
import { OPEN_MODAL, MODAL_ID } from '../constants';

export default {
  cancelProps: {
    text: __('Got it'),
    attributes: [
      {
        variant: 'info',
      },
    ],
  },
  modalId: MODAL_ID,
  components: {
    GlLink,
    GlModal,
  },
  inject: {
    membersPath: {
      default: '',
    },
  },
  i18n: {
    modalTitle: s__("InviteMember|Oops, this feature isn't ready yet"),
    bodyTopMessage: s__(
      "InviteMember|We're working to allow everyone to invite new members, making it easier for teams to get started with GitLab",
    ),
    bodyMiddleMessage: s__(
      'InviteMember|Until then, ask an owner to invite new project members for you',
    ),
    linkText: s__('InviteMember|See who can invite members for you'),
  },
  mounted() {
    eventHub.$on(OPEN_MODAL, this.openModal);
  },
  methods: {
    openModal() {
      this.$root.$emit('bv::show::modal', MODAL_ID);
    },
  },
};
</script>
<template>
  <gl-modal :modal-id="$options.modalId" size="sm" :action-cancel="$options.cancelProps">
    <template #modal-title>
      {{ $options.i18n.modalTitle }}
      <gl-emoji
        class="gl-vertical-align-baseline font-size-inherit gl-mr-1"
        data-name="sweat_smile"
      />
    </template>
    <p>{{ $options.i18n.bodyTopMessage }}</p>
    <p>{{ $options.i18n.bodyMiddleMessage }}</p>
    <gl-link
      :href="membersPath"
      data-track-event="click_who_can_invite_link"
      data-track-label="invite_members_message"
      >{{ $options.i18n.linkText }}</gl-link
    >
  </gl-modal>
</template>

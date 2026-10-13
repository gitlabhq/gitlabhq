<script>
import { GlAvatarsInline, GlAvatar } from '@gitlab/ui';
import { n__, sprintf } from '~/locale';
import { assignUserColor } from '../user_colors';

const MAX_VISIBLE_AVATARS = 5;

export default {
  name: 'CollaboratorsIndicator',
  components: {
    GlAvatarsInline,
    GlAvatar,
  },
  props: {
    provider: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      collaborators: [],
    };
  },
  computed: {
    groupLabel() {
      return sprintf(
        n__(
          'CollaborativeEditing|%{count} other person editing',
          'CollaborativeEditing|%{count} other people editing',
          this.collaborators.length,
        ),
        { count: this.collaborators.length },
      );
    },
    hiddenCount() {
      return Math.max(this.collaborators.length - MAX_VISIBLE_AVATARS, 0);
    },
    hiddenLabel() {
      return sprintf(
        n__(
          'CollaborativeEditing|%{count} more person editing',
          'CollaborativeEditing|%{count} more people editing',
          this.hiddenCount,
        ),
        { count: this.hiddenCount },
      );
    },
  },
  mounted() {
    this.provider.awareness.on('change', this.updateCollaborators);
    this.updateCollaborators();
  },
  beforeDestroy() {
    this.provider.awareness.off('change', this.updateCollaborators);
  },
  methods: {
    updateCollaborators() {
      const localClientId = this.provider.doc.clientID;

      const identities = new Map(
        [...this.provider.awareness.getStates().keys()]
          .filter((clientId) => clientId !== localClientId)
          .map((clientId) => this.provider.identityFor(clientId))
          .filter(Boolean)
          // One person editing in two tabs is two Yjs clients but one collaborator.
          .map((identity) => [identity.id, identity]),
      );

      this.collaborators = [...identities.values()].map((identity) => ({
        ...identity,
        color: assignUserColor(identity.id),
      }));
    },
  },
  MAX_VISIBLE_AVATARS,
};
</script>

<template>
  <gl-avatars-inline
    v-if="collaborators.length"
    :avatars="collaborators"
    :collapsed="true"
    :max-visible="$options.MAX_VISIBLE_AVATARS"
    :avatar-size="24"
    badge-tooltip-prop="name"
    :badge-sr-only-text="hiddenLabel"
    role="group"
    :aria-label="groupLabel"
    data-testid="collaborators-indicator"
  >
    <template #avatar="{ avatar }">
      <gl-avatar
        :src="avatar.avatarUrl"
        :entity-name="avatar.name"
        :alt="avatar.name"
        :size="24"
        :style="{ boxShadow: `0 0 0 2px ${avatar.color}` }"
      />
    </template>
  </gl-avatars-inline>
</template>

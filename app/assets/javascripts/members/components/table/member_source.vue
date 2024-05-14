<script>
import { GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import PrivateIcon from '../icons/private_icon.vue';

export default {
  name: 'MemberSource',
  i18n: {
    private: __('Private'),
    inherited: __('Inherited'),
    indirect: __('Indirect'),
    directMember: __('Direct member'),
    directMemberWithCreatedBy: s__('Members|Direct member by %{createdBy}'),
    indirectMemberWithCreatedBy: s__('Members|%{group} by %{createdBy}'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: { GlSprintf, PrivateIcon },
  props: {
    memberSource: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
    isDirectMember: {
      type: Boolean,
      required: true,
    },
    isSharedWithGroupPrivate: {
      type: Boolean,
      required: false,
      default: false,
    },
    createdBy: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    showCreatedBy() {
      return this.createdBy?.name && this.createdBy?.webUrl;
    },
    tooltipHover() {
      return gon.features?.webuiMembersInheritedUsers
        ? this.$options.i18n.indirect
        : this.$options.i18n.inherited;
    },
    messageWithCreatedBy() {
      return this.isDirectMember
        ? this.$options.i18n.directMemberWithCreatedBy
        : this.$options.i18n.indirectMemberWithCreatedBy;
    },
  },
};
</script>

<template>
  <div v-if="isSharedWithGroupPrivate" class="gl-display-flex gl-gap-x-2">
    <span>{{ $options.i18n.private }}</span>
    <private-icon />
  </div>
  <span v-else-if="showCreatedBy">
    <gl-sprintf :message="messageWithCreatedBy">
      <template #group>
        <a v-gl-tooltip.hover="tooltipHover" :href="memberSource.webUrl">{{
          memberSource.fullName
        }}</a>
      </template>
      <template #createdBy>
        <a :href="createdBy.webUrl">{{ createdBy.name }}</a>
      </template>
    </gl-sprintf>
  </span>
  <span v-else-if="isDirectMember">{{ $options.i18n.directMember }}</span>
  <a v-else v-gl-tooltip.hover="tooltipHover" :href="memberSource.webUrl">{{
    memberSource.fullName
  }}</a>
</template>

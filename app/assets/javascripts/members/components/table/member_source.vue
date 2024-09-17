<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import PrivateIcon from '../icons/private_icon.vue';

export default {
  name: 'MemberSource',
  i18n: {
    private: __('Private'),
    inheritedMember: s__('Members|Inherited from %{group}'),
    sharedMember: s__('Members|Invited group %{group}'),
    directMember: s__('Members|Direct member'),
    directMemberWithCreatedBy: s__('Members|Direct member by %{createdBy}'),
  },
  components: { GlSprintf, GlLink, PrivateIcon },
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  computed: {
    memberSource() {
      return this.member.source;
    },
    isDirectMember() {
      return this.member.isDirectMember;
    },
    isInheritedMember() {
      return this.member.isInheritedMember;
    },
    isSharedWithGroupPrivate() {
      return this.member.isSharedWithGroupPrivate;
    },
    createdBy() {
      return this.member.createdBy;
    },
    showCreatedBy() {
      return this.createdBy?.name && this.createdBy?.webUrl;
    },
    message() {
      if (this.isDirectMember) {
        if (this.showCreatedBy) {
          return this.$options.i18n.directMemberWithCreatedBy;
        }

        return this.$options.i18n.directMember;
      }

      if (this.isInheritedMember) {
        return this.$options.i18n.inheritedMember;
      }

      return this.$options.i18n.sharedMember;
    },
  },
};
</script>

<template>
  <div v-if="isSharedWithGroupPrivate" class="gl-flex gl-gap-x-2">
    <span>{{ $options.i18n.private }}</span>
    <private-icon />
  </div>
  <div v-else>
    <gl-sprintf :message="message">
      <template #group>
        <gl-link :href="memberSource.webUrl">{{ memberSource.fullName }}</gl-link>
      </template>
      <template #createdBy>
        <gl-link :href="createdBy.webUrl">{{ createdBy.name }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>

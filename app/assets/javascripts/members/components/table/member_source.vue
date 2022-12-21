<script>
import { GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export default {
  name: 'MemberSource',
  i18n: {
    inherited: __('Inherited'),
    directMember: __('Direct member'),
    directMemberWithCreatedBy: s__('Members|Direct member by %{createdBy}'),
    inheritedMemberWithCreatedBy: s__('Members|%{group} by %{createdBy}'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: { GlSprintf },
  props: {
    memberSource: {
      type: Object,
      required: true,
    },
    isDirectMember: {
      type: Boolean,
      required: true,
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
    messageWithCreatedBy() {
      return this.isDirectMember
        ? this.$options.i18n.directMemberWithCreatedBy
        : this.$options.i18n.inheritedMemberWithCreatedBy;
    },
  },
};
</script>

<template>
  <span v-if="showCreatedBy">
    <gl-sprintf :message="messageWithCreatedBy">
      <template #group>
        <a v-gl-tooltip.hover="$options.i18n.inherited" :href="memberSource.webUrl">{{
          memberSource.fullName
        }}</a>
      </template>
      <template #createdBy>
        <a :href="createdBy.webUrl">{{ createdBy.name }}</a>
      </template>
    </gl-sprintf>
  </span>
  <span v-else-if="isDirectMember">{{ $options.i18n.directMember }}</span>
  <a v-else v-gl-tooltip.hover="$options.i18n.inherited" :href="memberSource.webUrl">{{
    memberSource.fullName
  }}</a>
</template>

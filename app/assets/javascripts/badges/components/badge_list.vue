<script>
import { GlLoadingIcon, GlBadge } from '@gitlab/ui';
import { mapState } from 'vuex';
import { GROUP_BADGE } from '../constants';
import BadgeListRow from './badge_list_row.vue';

export default {
  name: 'BadgeList',
  components: {
    BadgeListRow,
    GlLoadingIcon,
    GlBadge,
  },
  computed: {
    ...mapState(['badges', 'isLoading', 'kind']),
    hasNoBadges() {
      return !this.isLoading && (!this.badges || !this.badges.length);
    },
    isGroupBadge() {
      return this.kind === GROUP_BADGE;
    },
  },
};
</script>

<template>
  <div class="card">
    <div class="card-header">
      {{ s__('Badges|Your badges') }}
      <gl-badge v-show="!isLoading" size="sm">{{ badges.length }}</gl-badge>
    </div>
    <gl-loading-icon v-show="isLoading" size="lg" class="card-body" />
    <div v-if="hasNoBadges" class="card-body">
      <span v-if="isGroupBadge">{{ s__('Badges|This group has no badges') }}</span>
      <span v-else>{{ s__('Badges|This project has no badges') }}</span>
    </div>
    <div v-else class="card-body">
      <badge-list-row v-for="badge in badges" :key="badge.id" :badge="badge" />
    </div>
  </div>
</template>

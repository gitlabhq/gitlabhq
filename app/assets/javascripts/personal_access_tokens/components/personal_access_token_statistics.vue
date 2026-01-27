<script>
import { GlButton, GlCard, GlLoadingIcon } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { s__, sprintf } from '~/locale';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { fifteenDaysFromNow } from '~/vue_shared/access_tokens/utils';
import getUserPersonalAccessTokenStatistics from '../graphql/get_user_personal_access_token_statistics.query.graphql';
import { STATISTICS_FILTERS } from '../constants';

export default {
  name: 'PersonalAccessTokenStatistics',
  components: {
    GlLoadingIcon,
    GlButton,
    GlCard,
    GlSingleStat,
  },
  emits: ['filter'],
  data() {
    return {
      statistics: {
        active: 0,
        expiringSoon: 0,
        revoked: 0,
        expired: 0,
      },
    };
  },
  apollo: {
    statistics: {
      query: getUserPersonalAccessTokenStatistics,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          expiresBefore: fifteenDaysFromNow(),
        };
      },
      update(data) {
        const user = data?.user;
        if (!user) return this.statistics;

        return {
          active: user.active?.count || 0,
          expiringSoon: user.expiringSoon?.count || 0,
          revoked: user.revoked?.count || 0,
          expired: user.expired?.count || 0,
        };
      },
      error() {
        createAlert({
          message: this.$options.i18n.fetchError,
          variant: VARIANT_DANGER,
        });
      },
    },
  },
  computed: {
    isLoading() {
      return Boolean(this.$apollo.queries.statistics.loading);
    },
    statisticsCards() {
      return [
        {
          title: this.$options.i18n.activeTokens,
          value: this.statistics.active,
          filter: STATISTICS_FILTERS.active,
        },
        {
          title: this.$options.i18n.expiringSoon,
          value: this.statistics.expiringSoon,
          filter: STATISTICS_FILTERS.expiringSoon,
        },
        {
          title: this.$options.i18n.revokedTokens,
          value: this.statistics.revoked,
          filter: STATISTICS_FILTERS.revoked,
        },
        {
          title: this.$options.i18n.expiredTokens,
          value: this.statistics.expired,
          filter: STATISTICS_FILTERS.expired,
        },
      ];
    },
  },
  methods: {
    handleFilter(statistic) {
      this.$emit('filter', statistic.filter);
    },
    tooltipTitle(statistic) {
      return sprintf(this.$options.i18n.filterFor, { status: statistic.title.toLowerCase() });
    },
  },
  i18n: {
    activeTokens: s__('AccessTokens|Active tokens'),
    expiringSoon: s__('AccessTokens|Tokens expiring in 2 weeks'),
    revokedTokens: s__('AccessTokens|Revoked tokens'),
    expiredTokens: s__('AccessTokens|Expired tokens'),
    filter: s__('AccessTokens|Filter list'),
    filterFor: s__('AccessTokens|Filter for %{status}'),
    fetchError: s__('AccessTokens|An error occurred while fetching token statistics.'),
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <gl-loading-icon v-if="isLoading" size="md" class="gl-my-5" />

    <div v-else class="gl-my-5 gl-grid gl-gap-4 @sm/panel:gl-grid-cols-2 @lg/panel:gl-grid-cols-4">
      <gl-card v-for="statistic in statisticsCards" :key="statistic.title">
        <gl-single-stat class="!gl-p-0" :title="statistic.title" :value="statistic.value" />
        <gl-button
          class="gl-mt-3"
          :title="tooltipTitle(statistic)"
          variant="link"
          @click="handleFilter(statistic)"
        >
          {{ $options.i18n.filter }}
        </gl-button>
      </gl-card>
    </div>
  </div>
</template>

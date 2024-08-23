<script>
import { GlButton, GlTableLite } from '@gitlab/ui';
import { isEmpty } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapMutations, mapState } from 'vuex';
import { removeSubscription } from '~/jira_connect/subscriptions/api';
import { reloadPage } from '~/jira_connect/subscriptions/utils';
import { __, s__ } from '~/locale';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { SET_ALERT } from '../store/mutation_types';
import GroupItemName from './group_item_name.vue';

export default {
  components: {
    GlButton,
    GlTableLite,
    GroupItemName,
    TimeagoTooltip,
  },
  data() {
    return {
      loadingItem: null,
    };
  },
  fields: [
    {
      key: 'name',
      label: s__('JiraConnect|Linked groups'),
    },
    {
      key: 'created_at',
      label: __('Created on'),
      tdClass: '!gl-align-middle gl-w-2/10',
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-text-right !gl-align-middle !gl-pl-0',
    },
  ],
  i18n: {
    unlinkError: s__('JiraConnect|Failed to unlink group. Please try again.'),
  },
  computed: {
    ...mapState(['subscriptions']),
  },
  methods: {
    ...mapMutations({
      setAlert: SET_ALERT,
    }),
    isUnlinkButtonDisabled(item) {
      return !isEmpty(item);
    },
    isLoadingItem(item) {
      return this.loadingItem === item;
    },
    unlinkBtnClass(item) {
      return this.isLoadingItem(item) ? '' : 'gl-ml-6';
    },
    onClick(item) {
      this.loadingItem = item;

      removeSubscription(item.unlink_path)
        .then(() => {
          reloadPage();
        })
        .catch((error) => {
          this.setAlert({
            message: error?.response?.data?.error || this.$options.i18n.unlinkError,
            variant: 'danger',
          });
          this.loadingItem = null;
        });
    },
  },
};
</script>

<template>
  <gl-table-lite :items="subscriptions" :fields="$options.fields">
    <template #cell(name)="{ item }">
      <group-item-name :group="item.group" />
    </template>
    <template #cell(created_at)="{ item }">
      <timeago-tooltip :time="item.created_at" />
    </template>
    <template #cell(actions)="{ item }">
      <gl-button
        :class="unlinkBtnClass(item)"
        category="secondary"
        :loading="isLoadingItem(item)"
        :disabled="isUnlinkButtonDisabled(loadingItem)"
        @click.prevent="onClick(item)"
        >{{ __('Unlink') }}</gl-button
      >
    </template>
  </gl-table-lite>
</template>

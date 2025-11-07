<script>
import {
  GlTable,
  GlLoadingIcon,
  GlDisclosureDropdown,
  GlTooltipDirective,
  GlSprintf,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import DateWithTooltip from './date_with_tooltip.vue';

const TABLE_FIELDS = [
  {
    key: 'name',
    label: __('Name'),
    tdClass: 'sm:gl-w-1/2',
  },
  {
    key: 'description',
    label: __('Description'),
    tdClass: 'sm:gl-w-1/2',
  },
  {
    key: 'status',
    label: __('Status'),
    tdClass: 'sm:gl-w-0',
  },
  {
    key: 'actions',
    label: __('Actions'),
    tdClass: 'gl-text-right',
  },
];

export default {
  name: 'TokensTable',
  components: {
    GlTable,
    GlLoadingIcon,
    GlDisclosureDropdown,
    GlSprintf,
    DateWithTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    tokens: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    getTokenActionItems(token) {
      return [
        {
          text: __('View details'),
          action: () => this.$emit('select', token),
        },
        {
          text: s__('AccessTokens|Rotate'),
          action: () => this.$emit('rotate', token),
        },
        {
          text: __('Revoke'),
          variant: 'danger',
          action: () => this.$emit('revoke', token),
        },
      ];
    },
  },
  TABLE_FIELDS,
};
</script>

<template>
  <gl-table
    :items="tokens"
    :fields="$options.TABLE_FIELDS"
    :busy="loading"
    stacked="sm"
    show-empty
    :empty-text="s__('AccessTokens|No access tokens')"
  >
    <template #table-busy>
      <gl-loading-icon size="md" />
    </template>

    <template #cell(name)="{ value }">
      <span class="gl-line-clamp-2 gl-wrap-anywhere">{{ value }}</span>
    </template>

    <template #cell(description)="{ value }">
      <span class="gl-line-clamp-2 gl-wrap-anywhere">{{ value }}</span>
    </template>

    <template #cell(status)="{ item }">
      <date-with-tooltip
        #default="{ date }"
        :timestamp="item.expiresAt"
        :token="item"
        icon="expire"
        class="gl-flex-wrap gl-justify-end sm:gl-flex-nowrap sm:gl-justify-start"
      >
        <gl-sprintf :message="s__('AccessTokens|Expires: %{date}')">
          <template #date>{{ date }}</template>
        </gl-sprintf>
      </date-with-tooltip>

      <date-with-tooltip
        #default="{ date }"
        :timestamp="item.lastUsedAt"
        icon="hourglass"
        class="gl-mt-3 gl-justify-end sm:gl-justify-start"
      >
        <gl-sprintf :message="s__('AccessTokens|Last used: %{date}')">
          <template #date>{{ date }}</template>
        </gl-sprintf>
      </date-with-tooltip>
    </template>

    <template #cell(actions)="{ item }">
      <gl-disclosure-dropdown
        v-if="item.active"
        :items="getTokenActionItems(item)"
        category="tertiary"
        icon="ellipsis_v"
        no-caret
        placement="bottom-end"
      />
    </template>
  </gl-table>
</template>

<script>
import { GlFormRadio } from '@gitlab/ui';
import { dateInWords, parsePikadayDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { dateFields } from '../../constants';
import SidebarFormattedDate from './sidebar_formatted_date.vue';

export default {
  components: {
    GlFormRadio,
    SidebarFormattedDate,
  },
  inject: ['canUpdate'],
  props: {
    issuable: {
      required: true,
      type: Object,
    },
    isLoading: {
      required: true,
      type: Boolean,
    },
    dateType: {
      type: String,
      required: true,
    },
  },
  computed: {
    dateIsFixed: {
      get() {
        return this.issuable?.[dateFields[this.dateType].isDateFixed] || false;
      },
      set(fixed) {
        this.$emit('set-date', fixed);
      },
    },
    hasFixedDate() {
      return this.issuable[dateFields[this.dateType].dateFixed] !== null;
    },
    formattedFixedDate() {
      const dateFixed = this.issuable[dateFields[this.dateType].dateFixed];
      if (!dateFixed) {
        return this.$options.i18n.noDate;
      }

      return dateInWords(parsePikadayDate(dateFixed), true);
    },
    formattedInheritedDate() {
      const dateFromMilestones = this.issuable[dateFields[this.dateType].dateFromMilestones];
      if (!dateFromMilestones) {
        return this.$options.i18n.noDate;
      }

      return dateInWords(parsePikadayDate(dateFromMilestones), true);
    },
  },
  i18n: {
    fixed: __('Fixed:'),
    inherited: __('Inherited:'),
    remove: __('remove'),
    noDate: __('None'),
  },
};
</script>

<template>
  <div class="hide-collapsed gl-mt-3">
    <div class="gl-display-flex gl-align-items-baseline" data-testid="sidebar-fixed-date">
      <gl-form-radio
        v-model="dateIsFixed"
        :value="true"
        :disabled="!canUpdate || isLoading"
        class="gl-pr-2"
      >
        <span :class="dateIsFixed ? 'gl-text-gray-900 gl-font-weight-bold' : 'gl-text-gray-500'">
          {{ $options.i18n.fixed }}
        </span>
      </gl-form-radio>
      <sidebar-formatted-date
        :has-date="dateIsFixed"
        :formatted-date="formattedFixedDate"
        :reset-text="$options.i18n.remove"
        :is-loading="isLoading"
        :can-delete="dateIsFixed && hasFixedDate"
        class="gl-line-height-normal"
        @reset-date="$emit('reset-date', $event)"
      />
    </div>
    <div class="gl-display-flex gl-align-items-baseline" data-testid="sidebar-inherited-date">
      <gl-form-radio
        v-model="dateIsFixed"
        :value="false"
        :disabled="!canUpdate || isLoading"
        class="gl-pr-2"
      >
        <span :class="!dateIsFixed ? 'gl-text-gray-900 gl-font-weight-bold' : 'gl-text-gray-500'">
          {{ $options.i18n.inherited }}
        </span>
      </gl-form-radio>
      <sidebar-formatted-date
        :has-date="!dateIsFixed"
        :formatted-date="formattedInheritedDate"
        :reset-text="$options.i18n.remove"
        :is-loading="isLoading"
        :can-delete="false"
        class="gl-line-height-normal"
      />
    </div>
  </div>
</template>

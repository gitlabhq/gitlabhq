<script>
import { GlFormRadio } from '@gitlab/ui';
import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
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
      required: false,
      type: Boolean,
      default: false,
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
        if (fixed === this.issuable[dateFields[this.dateType].isDateFixed]) return;
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

      return localeDateFormat.asDate.format(newDate(dateFixed));
    },
    formattedInheritedDate() {
      const dateFromMilestones = this.issuable[dateFields[this.dateType].dateFromMilestones];
      if (!dateFromMilestones) {
        return this.$options.i18n.noDate;
      }

      return localeDateFormat.asDate.format(newDate(dateFromMilestones));
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
    <div class="gl-flex gl-items-baseline" data-testid="sidebar-fixed-date">
      <gl-form-radio
        v-model="dateIsFixed"
        :value="true"
        :disabled="!canUpdate || isLoading"
        class="gl-pr-2"
      >
        <span :class="dateIsFixed ? 'gl-font-bold gl-text-default' : 'gl-text-subtle'">
          {{ $options.i18n.fixed }}
        </span>
      </gl-form-radio>
      <sidebar-formatted-date
        :has-date="dateIsFixed"
        :formatted-date="formattedFixedDate"
        :reset-text="$options.i18n.remove"
        :is-loading="isLoading"
        :can-delete="dateIsFixed && hasFixedDate"
        class="gl-leading-normal"
        @reset-date="$emit('reset-date', $event)"
      />
    </div>
    <div class="gl-flex gl-items-baseline" data-testid="sidebar-inherited-date">
      <gl-form-radio
        v-model="dateIsFixed"
        :value="false"
        :disabled="!canUpdate || isLoading"
        class="gl-pr-2"
      >
        <span :class="!dateIsFixed ? 'gl-font-bold gl-text-default' : 'gl-text-disalbed'">
          {{ $options.i18n.inherited }}
        </span>
      </gl-form-radio>
      <sidebar-formatted-date
        :has-date="!dateIsFixed"
        :formatted-date="formattedInheritedDate"
        :reset-text="$options.i18n.remove"
        :is-loading="isLoading"
        :can-delete="false"
        class="gl-leading-normal"
      />
    </div>
  </div>
</template>

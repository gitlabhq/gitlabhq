<script>
import { GlDatepicker } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { getDateInFuture } from '~/lib/utils/datetime_utility';
import { s__ } from '~/locale';

export default {
  name: 'ExpirationDatepicker',
  components: { GlDatepicker },
  inject: ['namespace'],
  props: {
    member: {
      type: Object,
      required: true,
    },
    permissions: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      selectedDate: null,
      busy: false,
    };
  },
  computed: {
    minDate() {
      // Members expire at the beginning of the day.
      // The first selectable day should be tomorrow.
      const today = new Date();
      const beginningOfToday = new Date(today.setHours(0, 0, 0, 0));

      return getDateInFuture(beginningOfToday, 1);
    },
    disabled() {
      return (
        this.busy ||
        !this.permissions.canUpdate ||
        (this.permissions.canOverride && !this.member.isOverridden)
      );
    },
  },
  mounted() {
    if (this.member.expiresAt) {
      this.selectedDate = new Date(this.member.expiresAt);
    }
  },
  methods: {
    ...mapActions({
      updateMemberExpiration(dispatch, payload) {
        return dispatch(`${this.namespace}/updateMemberExpiration`, payload);
      },
    }),
    handleInput(date) {
      this.busy = true;
      this.updateMemberExpiration({
        memberId: this.member.id,
        expiresAt: date,
      })
        .then(() => {
          this.$toast.show(s__('Members|Expiration date updated successfully.'));
          this.busy = false;
        })
        .catch(() => {
          this.busy = false;
        });
    },
    handleClear() {
      this.busy = true;

      this.updateMemberExpiration({
        memberId: this.member.id,
        expiresAt: null,
      })
        .then(() => {
          this.$toast.show(s__('Members|Expiration date removed successfully.'));
          this.selectedDate = null;
          this.busy = false;
        })
        .catch(() => {
          this.busy = false;
        });
    },
  },
};
</script>

<template>
  <!-- `:target="null"` allows the datepicker to be opened on focus -->
  <!-- `:container="null"` renders the datepicker in the body to prevent conflicting CSS table styles -->
  <gl-datepicker
    v-model="selectedDate"
    class="gl-max-w-full"
    show-clear-button
    :target="null"
    :container="null"
    :min-date="minDate"
    :placeholder="__('Expiration date')"
    :disabled="disabled"
    @input="handleInput"
    @clear="handleClear"
  />
</template>

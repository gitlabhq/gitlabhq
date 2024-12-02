<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { GlButton } from '@gitlab/ui';
import GroupItemName from '../group_item_name.vue';
import { I18N_ADD_SUBSCRIPTIONS_ERROR_MESSAGE } from '../../constants';

export default {
  components: {
    GlButton,
    GroupItemName,
  },
  inject: {
    subscriptionsPath: {
      default: '',
    },
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  methods: {
    ...mapActions(['addSubscription']),
    async onClick() {
      this.isLoading = true;
      try {
        await this.addSubscription({
          namespacePath: this.group.full_path,
          subscriptionsPath: this.subscriptionsPath,
        });
      } catch (error) {
        this.$emit('error', error?.response?.data?.error || I18N_ADD_SUBSCRIPTIONS_ERROR_MESSAGE);
      }
      this.isLoading = false;
    },
  },
};
</script>

<template>
  <li class="gl-border-b-1 gl-border-b-default gl-border-b-solid">
    <div class="gl-flex gl-items-center gl-py-3">
      <div class="gl-flex-shrink-1 gl-flex gl-min-w-0 gl-grow gl-items-center">
        <div class="gl-flex-shrink-1 gl-min-w-0 gl-grow">
          <group-item-name :group="group" />
        </div>

        <gl-button
          category="secondary"
          variant="confirm"
          :loading="isLoading"
          :disabled="disabled"
          @click.prevent="onClick"
        >
          {{ __('Link') }}
        </gl-button>
      </div>
    </div>
  </li>
</template>

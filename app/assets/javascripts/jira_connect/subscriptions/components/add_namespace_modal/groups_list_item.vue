<script>
import { mapActions } from 'vuex';
import { GlButton } from '@gitlab/ui';
import { addSubscription } from '~/jira_connect/subscriptions/api';
import { persistAlert, reloadPage } from '~/jira_connect/subscriptions/utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import GroupItemName from '../group_item_name.vue';
import {
  INTEGRATIONS_DOC_LINK,
  I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE,
  I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE,
  I18N_ADD_SUBSCRIPTIONS_ERROR_MESSAGE,
} from '../../constants';

export default {
  components: {
    GlButton,
    GroupItemName,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    addSubscriptionsPath: {
      default: '',
    },
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
      await this.addSubscription({
        namespacePath: this.group.full_path,
        subscriptionsPath: this.subscriptionsPath,
      });
      this.isLoading = false;
    },
    deprecatedAddSubscription() {
      this.isLoading = true;

      addSubscription(this.addSubscriptionsPath, this.group.full_path)
        .then(() => {
          persistAlert({
            title: I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE,
            message: I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE,
            linkUrl: INTEGRATIONS_DOC_LINK,
            variant: 'success',
          });

          reloadPage();
        })
        .catch((error) => {
          this.$emit('error', error?.response?.data?.error || I18N_ADD_SUBSCRIPTIONS_ERROR_MESSAGE);
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <li class="gl-border-b-1 gl-border-b-solid gl-border-b-gray-100">
    <div class="gl-display-flex gl-align-items-center gl-py-3">
      <div class="gl-min-w-0 gl-display-flex gl-flex-grow-1 gl-flex-shrink-1 gl-align-items-center">
        <div class="gl-min-w-0 gl-flex-grow-1 flex-shrink-1">
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

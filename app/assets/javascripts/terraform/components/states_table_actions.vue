<script>
import { GlDropdown, GlDropdownItem, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import lockState from '../graphql/mutations/lock_state.mutation.graphql';
import unlockState from '../graphql/mutations/unlock_state.mutation.graphql';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
  },
  props: {
    state: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      loading: false,
    };
  },
  i18n: {
    downloadJSON: s__('Terraform|Download JSON'),
    lock: s__('Terraform|Lock'),
    unlock: s__('Terraform|Unlock'),
  },
  methods: {
    lock() {
      this.stateMutation(lockState);
    },
    unlock() {
      this.stateMutation(unlockState);
    },
    stateMutation(mutation) {
      this.loading = true;
      this.$apollo
        .mutate({
          mutation,
          variables: {
            stateID: this.state.id,
          },
          refetchQueries: () => ['getStates'],
          awaitRefetchQueries: true,
          notifyOnNetworkStatusChange: true,
        })
        .catch(() => {})
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown
      icon="ellipsis_v"
      right
      :data-testid="`terraform-state-actions-${state.name}`"
      :disabled="loading"
      toggle-class="gl-px-3! gl-shadow-none!"
    >
      <template #button-content>
        <gl-icon class="gl-mr-0" name="ellipsis_v" />
      </template>

      <gl-dropdown-item
        v-if="state.latestVersion"
        data-testid="terraform-state-download"
        :download="`${state.name}.json`"
        :href="state.latestVersion.downloadPath"
      >
        {{ $options.i18n.downloadJSON }}
      </gl-dropdown-item>

      <gl-dropdown-item v-if="state.lockedAt" data-testid="terraform-state-unlock" @click="unlock">
        {{ $options.i18n.unlock }}
      </gl-dropdown-item>

      <gl-dropdown-item v-else data-testid="terraform-state-lock" @click="lock">
        {{ $options.i18n.lock }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>

<script>
import { GlButton } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { addSubscription } from '~/jira_connect/api';
import { persistAlert, reloadPage } from '~/jira_connect/utils';
import { s__ } from '~/locale';
import GroupItemName from './group_item_name.vue';

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
    onClick() {
      this.isLoading = true;

      addSubscription(this.subscriptionsPath, this.group.full_path)
        .then(() => {
          persistAlert({
            title: s__('Integrations|Namespace successfully linked'),
            message: s__(
              'Integrations|You should now see GitLab.com activity inside your Jira Cloud issues. %{linkStart}Learn more%{linkEnd}',
            ),
            linkUrl: helpPagePath('integration/jira_development_panel.html', { anchor: 'usage' }),
            variant: 'success',
          });

          reloadPage();
        })
        .catch((error) => {
          this.$emit(
            'error',
            error?.response?.data?.error ||
              s__('Integrations|Failed to link namespace. Please try again.'),
          );
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

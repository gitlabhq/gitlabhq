<script>
import { GlAvatar, GlButton, GlIcon } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { addSubscription } from '~/jira_connect/api';
import { s__ } from '~/locale';
import { persistAlert } from '../utils';

export default {
  components: {
    GlAvatar,
    GlButton,
    GlIcon,
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

          AP.navigator.reload();
        })
        .catch((error) => {
          this.$emit(
            'error',
            error?.response?.data?.error ||
              s__('Integrations|Failed to link namespace. Please try again.'),
          );
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <li class="gl-border-b-1 gl-border-b-solid gl-border-b-gray-100">
    <div class="gl-display-flex gl-align-items-center gl-py-3">
      <gl-icon name="folder-o" class="gl-mr-3" />
      <div class="gl-display-none gl-flex-shrink-0 gl-sm-display-flex gl-mr-3">
        <gl-avatar :size="32" shape="rect" :entity-name="group.name" :src="group.avatar_url" />
      </div>
      <div class="gl-min-w-0 gl-display-flex gl-flex-grow-1 gl-flex-shrink-1 gl-align-items-center">
        <div class="gl-min-w-0 gl-flex-grow-1 flex-shrink-1">
          <div class="gl-display-flex gl-align-items-center gl-flex-wrap">
            <span
              class="gl-mr-3 gl-text-gray-900! gl-font-weight-bold"
              data-testid="group-list-item-name"
            >
              {{ group.full_name }}
            </span>
          </div>
          <div v-if="group.description" data-testid="group-list-item-description">
            <p class="gl-mt-2! gl-mb-0 gl-text-gray-600" v-text="group.description"></p>
          </div>
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

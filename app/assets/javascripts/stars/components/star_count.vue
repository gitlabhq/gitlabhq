<script>
import { GlButton, GlButtonGroup, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import setStarStatusMutation from './graphql/mutations/star.mutation.graphql';

export default {
  name: 'StarCount',
  components: {
    GlButton,
    GlButtonGroup,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    projectId: {
      default: null,
    },
    signInPath: {
      default: '',
    },
    starCount: {
      default: 0,
    },
    starred: {
      default: false,
    },
    starrersPath: {
      default: '',
    },
  },
  data() {
    return {
      isLoading: false,
      count: this.starCount,
      isStarred: this.starred,
    };
  },
  computed: {
    starIcon() {
      return this.isStarred ? 'star' : 'star-o';
    },
    starText() {
      return this.isStarred ? s__('ProjectOverview|Unstar') : s__('ProjectOverview|Star');
    },
    starHref() {
      return isLoggedIn() ? null : this.signInPath;
    },
    tooltip() {
      if (isLoggedIn()) {
        return this.starText;
      }

      return s__('ProjectOverview|You must sign in to star a project');
    },
  },
  methods: {
    showToastMessage() {
      const toastProps = {
        text: s__('ProjectOverview|Star toggle failed. Try again later.'),
        variant: 'danger',
      };

      this.$toast.show(toastProps.text, {
        variant: toastProps.variant,
      });
    },
    async setStarStatus() {
      if (!isLoggedIn()) {
        return;
      }

      try {
        const { data } = await this.$apollo.mutate({
          mutation: setStarStatusMutation,
          variables: {
            projectId: convertToGraphQLId(TYPENAME_PROJECT, this.projectId),
            starred: !this.isStarred,
          },
        });

        if (data.errors?.length > 0) {
          reportToSentry(this.$options.name, new Error(data.errors.join(', ')));
          this.showToastMessage();
        } else {
          this.count = data.starProject.count;
          this.isStarred = !this.isStarred;
        }
      } catch (failure) {
        reportToSentry(this.$options.name, failure);
        this.showToastMessage();
      }
    },
  },
  modalId: 'custom-notifications-modal',
};
</script>

<template>
  <gl-button-group>
    <gl-button
      v-gl-tooltip
      class="star-btn"
      size="medium"
      data-testid="star-button"
      :title="tooltip"
      :href="starHref"
      @click="setStarStatus()"
    >
      <gl-icon :name="starIcon" :size="16" />
      {{ starText }}
    </gl-button>
    <gl-button
      v-gl-tooltip
      class="star-count"
      data-testid="star-count"
      size="medium"
      :href="starrersPath"
      :title="s__('ProjectOverview|Starrers')"
    >
      {{ count }}
    </gl-button>
  </gl-button-group>
</template>

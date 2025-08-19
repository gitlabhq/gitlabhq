<script>
import { GlButton, GlModal, GlSprintf } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import GlobalUserSelect from '~/vue_shared/components/user_select/global_user_select.vue';

import { logError } from '~/lib/logger';

import awardAchievementMutation from './graphql/award_achievement.mutation.graphql';

export default {
  components: {
    GlButton,
    GlModal,
    GlSprintf,
    GlobalUserSelect,
  },
  props: {
    achievementId: {
      type: String,
      required: true,
    },
    achievementName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      usersToAward: [],
    };
  },
  methods: {
    async awardAll() {
      this.loading = true;
      await Promise.all(this.usersToAward.map((user) => this.award(user)));
      this.loading = false;
    },
    async award(user) {
      const userId = convertToGraphQLId(TYPENAME_USER, user.id);

      await this.$apollo
        .mutate({
          mutation: awardAchievementMutation,
          variables: {
            input: {
              achievementId: this.achievementId,
              userId,
            },
          },
        })
        .catch((e) => {
          logError(e);
        });
    },
    openModal() {
      this.$refs.modal.show();
    },
  },
};
</script>

<template>
  <span>
    <gl-button :loading="loading" @click="openModal"> {{ s__('Achievements|Award') }}</gl-button>
    <gl-modal
      ref="modal"
      modal-id="award-achievement-modal"
      :title="s__('Achievements|Award achievements')"
      @primary="awardAll"
      @canceled="usersToAward = []"
    >
      <div class="gl-mb-4">
        <gl-sprintf
          :message="s__('Achievements|You\'re awarding users the %{achievementName} achievement')"
        >
          <template #achievementName>
            <b>{{ achievementName }}</b>
          </template>
        </gl-sprintf>
      </div>
      <div class="gl-mb-2">
        <b>{{ __('Users') }}</b>
      </div>
      <global-user-select v-model="usersToAward" class="gl-mb-2" />
    </gl-modal>
  </span>
</template>

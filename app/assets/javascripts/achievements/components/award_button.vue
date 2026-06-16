<script>
import { GlButton, GlFormGroup, GlFormInput, GlModal, GlSprintf } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import GlobalUserSelect from '~/vue_shared/components/user_select/global_user_select.vue';

import { logError } from '~/lib/logger';

import awardAchievementMutation from './graphql/award_achievement.mutation.graphql';
import getGroupAchievements from './graphql/get_group_achievements.query.graphql';

export default {
  name: 'AwardButton',
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
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
      awardMessage: '',
    };
  },
  methods: {
    async awardAll() {
      this.loading = true;
      await Promise.all(this.usersToAward.map((user) => this.award(user)));
      await this.$apollo.getClient().refetchQueries({ include: [getGroupAchievements] });
      this.loading = false;
      this.resetModal();
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
              ...(this.awardMessage ? { awardMessage: this.awardMessage } : {}),
            },
          },
        })
        .catch((e) => {
          logError(e);
        });
    },
    resetModal() {
      this.usersToAward = [];
      this.awardMessage = '';
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
      @canceled="resetModal"
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
      <gl-form-group :label="__('Users')" class="gl-mb-2" label-for="global_users_input">
        <global-user-select v-model="usersToAward" input-id="global_users_input" class="gl-mb-2" />
      </gl-form-group>
      <gl-form-group
        :label="s__('Achievements|Award message')"
        label-for="award_message_input"
        :description="
          s__(
            'Achievements|Optional message shown on the recipient\'s profile (maximum 200 characters).',
          )
        "
      >
        <gl-form-input
          id="award_message_input"
          v-model="awardMessage"
          :maxlength="200"
          :placeholder="s__('Achievements|For example, Awarded for outstanding contribution')"
        />
      </gl-form-group>
    </gl-modal>
  </span>
</template>

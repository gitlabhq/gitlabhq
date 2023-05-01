<script>
import { GlLink, GlLoadingIcon, GlSprintf, GlToggle } from '@gitlab/ui';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import updateOptInJwtMutation from '../graphql/mutations/update_opt_in_jwt.mutation.graphql';
import getOptInJwtSettingQuery from '../graphql/queries/get_opt_in_jwt_setting.query.graphql';
import { LIMIT_JWT_ACCESS_SNIPPET, OPT_IN_JWT_HELP_LINK } from '../constants';

export default {
  i18n: {
    labelText: s__('CICD|Limit JSON Web Token (JWT) access'),
    helpText: s__(
      `CICD|The JWT must be manually declared in each job that needs it. When disabled, the token is always available in all jobs in the pipeline. %{linkStart}Learn more.%{linkEnd}`,
    ),
    expandedText: s__(
      'CICD|Use the %{codeStart}secrets%{codeEnd} keyword to configure a job with a JWT.',
    ),
    copyToClipboard: __('Copy to clipboard'),
    fetchError: s__('CICD|There was a problem fetching the token access settings.'),
    updateError: s__('CICD|An error occurred while update the setting. Please try again.'),
  },
  components: {
    CodeInstruction,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    GlToggle,
  },
  inject: ['fullPath'],
  apollo: {
    optInJwt: {
      query: getOptInJwtSettingQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({
        project: {
          ciCdSettings: { optInJwt },
        },
      }) {
        return optInJwt;
      },
      error() {
        createAlert({ message: this.$options.i18n.fetchError });
      },
    },
  },
  data() {
    return {
      optInJwt: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.optInJwt.loading;
    },
  },
  methods: {
    async updateOptInJwt() {
      try {
        const {
          data: {
            projectCiCdSettingsUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateOptInJwtMutation,
          variables: {
            input: {
              fullPath: this.fullPath,
              optInJwt: this.optInJwt,
            },
          },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        createAlert({ message: this.$options.i18n.updateError });
      }
    },
  },
  OPT_IN_JWT_HELP_LINK,
  LIMIT_JWT_ACCESS_SNIPPET,
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-5" />
    <template v-else>
      <gl-toggle
        v-model="optInJwt"
        class="gl-mt-5"
        :label="$options.i18n.labelText"
        @change="updateOptInJwt"
      >
        <template #help>
          <gl-sprintf :message="$options.i18n.helpText">
            <template #link="{ content }">
              <gl-link :href="$options.OPT_IN_JWT_HELP_LINK" class="inline-link" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </template>
      </gl-toggle>
      <div v-if="optInJwt" class="gl-mt-5" data-testid="opt-in-jwt-expanded-section">
        <gl-sprintf :message="$options.i18n.expandedText">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
        <code-instruction
          class="gl-mt-3"
          :instruction="$options.LIMIT_JWT_ACCESS_SNIPPET"
          :copy-text="$options.i18n.copyToClipboard"
          multiline
        />
      </div>
    </template>
  </div>
</template>

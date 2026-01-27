<script>
import { mapActions, mapState } from 'pinia';
import { s__ } from '~/locale';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import AccessTokenForm from '~/vue_shared/access_tokens/components/access_token_form.vue';
import { useAccessTokens } from '~/vue_shared/access_tokens/stores/access_tokens';
import CreatedPersonalAccessToken from '../created_personal_access_token.vue';

export default {
  name: 'CreateLegacyPersonalAccessTokenForm',
  components: {
    PageHeading,
    AccessTokenForm,
    CreatedPersonalAccessToken,
  },
  inject: ['accessTokenCreate', 'accessTokenTableUrl'],
  computed: {
    ...mapState(useAccessTokens, ['token']),
  },
  mounted() {
    this.setup({
      urlCreate: this.accessTokenCreate,
      showCreateFormInline: false,
    });
  },
  methods: {
    ...mapActions(useAccessTokens, ['setup']),
  },
  i18n: {
    heading: s__('AccessTokens|Generate legacy token'),
    description: s__(
      'AccessTokens|Legacy personal access tokens are scoped to all groups and projects with broad permissions to resources.',
    ),
  },
};
</script>

<template>
  <created-personal-access-token v-if="token" v-model="token" />

  <div v-else>
    <page-heading :heading="$options.i18n.heading">
      <template #description>
        {{ $options.i18n.description }}
      </template>
    </page-heading>

    <access-token-form />
  </div>
</template>

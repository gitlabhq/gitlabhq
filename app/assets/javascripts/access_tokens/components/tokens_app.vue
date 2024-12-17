<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { pickBy } from 'lodash';
import { s__ } from '~/locale';
import { FEED_TOKEN, INCOMING_EMAIL_TOKEN, STATIC_OBJECT_TOKEN } from '../constants';
import Token from './token.vue';

export default {
  i18n: {
    canNotAccessOtherData: s__('AccessTokens|It cannot be used to access any other data.'),
    [FEED_TOKEN]: {
      label: s__('AccessTokens|Feed token'),
      copyButtonTitle: s__('AccessTokens|Copy feed token'),
      description: s__(
        'AccessTokens|Your feed token authenticates you when your RSS reader loads a personalized RSS feed or when your calendar application loads a personalized calendar. It is visible in those feed URLs.',
      ),
      inputDescription: s__(
        'AccessTokens|Keep this token secret. Anyone who has it can read activity and issue RSS feeds or your calendar feed as if they were you. If that happens, %{linkStart}reset this token%{linkEnd}.',
      ),
      resetConfirmMessage: s__(
        'AccessTokens|Are you sure? Any RSS or calendar URLs currently in use will stop working.',
      ),
    },
    [INCOMING_EMAIL_TOKEN]: {
      label: s__('AccessTokens|Incoming email token'),
      copyButtonTitle: s__('AccessTokens|Copy incoming email token'),
      description: s__(
        'AccessTokens|Your incoming email token authenticates you when you create a new issue by email, and is included in your personal project-specific email addresses.',
      ),
      inputDescription: s__(
        'AccessTokens|Keep this token secret. Anyone who has it can create issues as if they were you. If that happens, %{linkStart}reset this token%{linkEnd}.',
      ),
      resetConfirmMessage: s__(
        'AccessTokens|Are you sure? Any issue email addresses currently in use will stop working.',
      ),
    },
    [STATIC_OBJECT_TOKEN]: {
      label: s__('AccessTokens|Static object token'),
      copyButtonTitle: s__('AccessTokens|Copy static object token'),
      description: s__(
        'AccessTokens|Your static object token authenticates you when repository static objects (such as archives or blobs) are served from an external storage.',
      ),
      inputDescription: s__(
        'AccessTokens|Keep this token secret. Anyone who has it can access repository static objects as if they were you. If that ever happens, %{linkStart}reset this token%{linkEnd}.',
      ),
      resetConfirmMessage: s__('AccessTokens|Are you sure?'),
    },
  },
  htmlAttributes: {
    [FEED_TOKEN]: {
      inputId: 'feed_token',
      containerTestId: 'feed-token-container',
    },
    [INCOMING_EMAIL_TOKEN]: {
      inputId: 'incoming_email_token',
      containerTestId: 'incoming-email-token-container',
    },
    [STATIC_OBJECT_TOKEN]: {
      inputId: 'static_object_token',
      containerTestId: 'static-object-token-container',
    },
  },
  components: { Token, GlSprintf, GlLink },
  inject: ['tokenTypes'],
  computed: {
    enabledTokenTypes() {
      return pickBy(this.tokenTypes, (tokenData, tokenType) => {
        return (
          tokenData?.enabled &&
          this.$options.i18n[tokenType] &&
          this.$options.htmlAttributes[tokenType]
        );
      });
    },
  },
};
</script>

<template>
  <div>
    <token
      v-for="(tokenData, tokenType) in enabledTokenTypes"
      :key="tokenType"
      :token="tokenData.token"
      :input-id="$options.htmlAttributes[tokenType].inputId"
      :input-label="$options.i18n[tokenType].label"
      :copy-button-title="$options.i18n[tokenType].copyButtonTitle"
      :data-testid="$options.htmlAttributes[tokenType].containerTestId"
      size="md"
    >
      <template #title>
        {{ $options.i18n[tokenType].label }}
      </template>
      <template #description>
        {{ $options.i18n[tokenType].description }}
        {{ $options.i18n.canNotAccessOtherData }}
      </template>
      <template #input-description>
        <gl-sprintf :message="$options.i18n[tokenType].inputDescription">
          <template #link="{ content }">
            <gl-link
              :href="tokenData.resetPath"
              :data-confirm="$options.i18n[tokenType].resetConfirmMessage"
              data-confirm-btn-variant="danger"
              data-method="put"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </template>
    </token>
  </div>
</template>

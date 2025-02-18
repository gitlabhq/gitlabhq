<script>
import { GlBadge, GlPopover, GlLink, GlToggle } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { DOCS_URL_IN_EE_DIR } from '~/lib/utils/url_utility';
import getUserPreferences from '../graphql/user_preferences.query.graphql';
import setUseWorkItemsView from '../graphql/set_use_work_items_view.mutation.graphql';

export default {
  name: 'WorkItemToggle',
  components: {
    GlBadge,
    GlPopover,
    GlLink,
    GlToggle,
  },
  data() {
    return {
      currentUser: {
        userPreferences: {},
      },
      feedbackIssue: `${DOCS_URL_IN_EE_DIR}/user/project/issues/issue_work_items.html`,
    };
  },
  apollo: {
    currentUser: {
      query: getUserPreferences,
    },
  },
  computed: {
    onOff() {
      return this.currentUser.userPreferences.useWorkItemsView ? __('On') : __('Off');
    },
  },
  methods: {
    setWorkItemsView(val) {
      this.$apollo
        .mutate({
          mutation: setUseWorkItemsView,
          variables: {
            useWorkItemsView: val,
          },
          update: (cache, { data: { userPreferencesUpdate } }) => {
            cache.modify({
              id: cache.identify(this.currentUser),
              fields: {
                userPreferences(existingPreferences = {}) {
                  return {
                    ...existingPreferences,
                    ...userPreferencesUpdate.userPreferences,
                  };
                },
              },
            });

            window.location.reload();
          },
        })
        .catch((error) => {
          createAlert({
            message: __('Something went wrong. Please try again.'),
          });
          Sentry.captureException(error);
        });
    },
  },
  badgeId: uniqueId(),
  i18n: {
    previewWorkItems: __(
      'Preview the new issues experience, with real time updates and refreshed design.',
    ),
    leaveFeedback: __('Learn more'),
    newIssueLook: __('New issue look'),
  },
};
</script>

<template>
  <div class="gl-flex gl-content-center">
    <gl-badge :id="$options.badgeId" variant="info" icon="information-o" href="#"
      >{{ $options.i18n.newIssueLook }}: {{ onOff }}</gl-badge
    >
    <gl-popover
      :target="$options.badgeId"
      data-testid="work-item-feedback-popover"
      triggers="focus click manual blur"
      placement="bottom"
      show-close-button
      :title="$options.i18n.newIssueLook"
    >
      <gl-toggle
        :value="currentUser.userPreferences.useWorkItemsView"
        :label="onOff"
        label-position="left"
        @change="setWorkItemsView"
      />
      <div class="gl-pt-2">
        {{ $options.i18n.previewWorkItems }}
      </div>
      <gl-link target="_blank" :href="feedbackIssue">{{ $options.i18n.leaveFeedback }}</gl-link>
    </gl-popover>
  </div>
</template>

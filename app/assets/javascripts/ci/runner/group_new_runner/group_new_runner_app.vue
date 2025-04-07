<script>
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import { GROUP_TYPE } from '../constants';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'GroupNewRunnerApp',
  components: {
    RunnerCreateForm,
    PageHeading,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    groupId: {
      type: String,
      required: true,
    },
  },
  methods: {
    onSaved(runner) {
      this.trackEvent('click_create_group_runner_button');

      saveAlertToLocalStorage({
        message: s__('Runners|Runner created.'),
        variant: VARIANT_SUCCESS,
      });
      visitUrl(runner.ephemeralRegisterUrl);
    },
    onError(error) {
      createAlert({ message: error.message });
    },
  },
  GROUP_TYPE,
};
</script>

<template>
  <div>
    <page-heading :heading="s__('Runners|New group runner')">
      <template #description>
        {{
          s__(
            'Runners|Create a group runner to generate a command that registers the runner with all its configurations.',
          )
        }}
      </template>
    </page-heading>

    <runner-create-form
      :runner-type="$options.GROUP_TYPE"
      :group-id="groupId"
      @saved="onSaved"
      @error="onError"
    />
  </div>
</template>

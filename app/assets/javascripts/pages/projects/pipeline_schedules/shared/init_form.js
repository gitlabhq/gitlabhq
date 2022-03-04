import $ from 'jquery';
import Vue from 'vue';
import { __ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import setupNativeFormVariableList from '../../../../ci_variable_list/native_form_variable_list';
import GlFieldErrors from '../../../../gl_field_errors';
import Translate from '../../../../vue_shared/translate';
import intervalPatternInput from './components/interval_pattern_input.vue';
import TimezoneDropdown from './components/timezone_dropdown';

Vue.use(Translate);

function initIntervalPatternInput() {
  const intervalPatternMount = document.getElementById('interval-pattern-input');
  const initialCronInterval = intervalPatternMount?.dataset?.initialInterval;
  const dailyLimit = intervalPatternMount.dataset?.dailyLimit;

  return new Vue({
    el: intervalPatternMount,
    components: {
      intervalPatternInput,
    },
    render(createElement) {
      return createElement('interval-pattern-input', {
        props: {
          initialCronInterval,
          dailyLimit,
        },
      });
    },
  });
}

function getEnabledRefTypes() {
  const refTypes = [REF_TYPE_BRANCHES];

  if (gon.features.pipelineSchedulesWithTags) {
    refTypes.push(REF_TYPE_TAGS);
  }

  return refTypes;
}

function initTargetRefDropdown() {
  const $refField = document.getElementById('schedule_ref');
  const el = document.querySelector('.js-target-ref-dropdown');
  const { projectId, defaultBranch } = el.dataset;

  if (!$refField.value) {
    $refField.value = defaultBranch;
  }

  const refDropdown = new Vue({
    el,
    render(h) {
      return h(RefSelector, {
        props: {
          enabledRefTypes: getEnabledRefTypes(),
          projectId,
          value: $refField.value,
          useSymbolicRefNames: true,
          translations: {
            dropdownHeader: gon.features.pipelineSchedulesWithTags
              ? __('Select target branch or tag')
              : __('Select target branch'),
          },
        },
        class: 'gl-w-full',
      });
    },
  });

  refDropdown.$children[0].$on('input', (newRef) => {
    $refField.value = newRef;
  });

  return refDropdown;
}

export default () => {
  /* Most of the form is written in haml, but for fields with more complex behaviors,
   * you should mount individual Vue components here. If at some point components need
   * to share state, it may make sense to refactor the whole form to Vue */

  initIntervalPatternInput();

  // Initialize non-Vue JS components in the form

  const formElement = document.getElementById('new-pipeline-schedule-form');

  gl.timezoneDropdown = new TimezoneDropdown({
    $dropdownEl: $('.js-timezone-dropdown'),
    $inputEl: $('#schedule_cron_timezone'),
    onSelectTimezone: () => {
      gl.pipelineScheduleFieldErrors.updateFormValidityState();
    },
  });
  gl.pipelineScheduleFieldErrors = new GlFieldErrors(formElement);

  initTargetRefDropdown();

  setupNativeFormVariableList({
    container: $('.js-ci-variable-list-section'),
    formField: 'schedule',
  });
};

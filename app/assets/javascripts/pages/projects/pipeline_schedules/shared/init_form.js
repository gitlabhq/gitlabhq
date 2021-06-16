import $ from 'jquery';
import Vue from 'vue';
import setupNativeFormVariableList from '../../../../ci_variable_list/native_form_variable_list';
import GlFieldErrors from '../../../../gl_field_errors';
import Translate from '../../../../vue_shared/translate';
import intervalPatternInput from './components/interval_pattern_input.vue';
import TargetBranchDropdown from './components/target_branch_dropdown';
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
  gl.targetBranchDropdown = new TargetBranchDropdown();
  gl.pipelineScheduleFieldErrors = new GlFieldErrors(formElement);

  setupNativeFormVariableList({
    container: $('.js-ci-variable-list-section'),
    formField: 'schedule',
  });
};

import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import IntegrationForm from './components/integration_form.vue';

export default el => {
  if (!el) {
    return null;
  }

  function parseBooleanInData(data) {
    const result = {};
    Object.entries(data).forEach(([key, value]) => {
      result[key] = parseBoolean(value);
    });
    return result;
  }

  const { type, commentDetail, ...booleanAttributes } = el.dataset;
  const {
    showActive,
    activated,
    commitEvents,
    mergeRequestEvents,
    enableComments,
  } = parseBooleanInData(booleanAttributes);

  return new Vue({
    el,
    render(createElement) {
      return createElement(IntegrationForm, {
        props: {
          activeToggleProps: {
            initialActivated: activated,
          },
          showActive,
          type,
          triggerFieldsProps: {
            initialTriggerCommit: commitEvents,
            initialTriggerMergeRequest: mergeRequestEvents,
            initialEnableComments: enableComments,
            initialCommentDetail: commentDetail,
          },
        },
      });
    },
  });
};

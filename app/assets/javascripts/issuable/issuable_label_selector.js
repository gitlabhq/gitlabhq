import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import {
  DropdownVariant,
  LabelType,
} from '~/sidebar/components/labels/labels_select_widget/constants';
import { WorkspaceType } from '~/issues/constants';
import IssuableLabelSelector from '~/vue_shared/issuable/create/components/issuable_label_selector.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('.js-issuable-form-label-selector');

  if (!el) {
    return false;
  }

  const {
    fieldName,
    fullPath,
    initialLabels,
    issuableType,
    labelsFilterBasePath,
    labelsManagePath,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      allowLabelCreate: true,
      allowLabelEdit: true,
      allowLabelRemove: true,
      allowScopedLabels: true,
      attrWorkspacePath: fullPath,
      fieldName,
      fullPath,
      initialLabels: JSON.parse(initialLabels),
      issuableType,
      labelType: LabelType.project,
      labelsFilterBasePath,
      labelsManagePath,
      variant: DropdownVariant.Embedded,
      workspaceType: WorkspaceType.project,
    },
    render(createElement) {
      return createElement(IssuableLabelSelector);
    },
  });
};

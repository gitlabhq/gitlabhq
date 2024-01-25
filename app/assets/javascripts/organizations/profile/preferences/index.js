import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { s__ } from '~/locale';
import OrganizationSelect from '~/vue_shared/components/entity_select/organization_select.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const initHomeOrganizationSetting = () => {
  const el = document.getElementById('js-home-organization-setting');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const { initialSelection } = convertObjectPropsToCamelCase(JSON.parse(appData));

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    name: 'HomeOrganizationSetting',
    apolloProvider,
    render(createElement) {
      return createElement(OrganizationSelect, {
        props: {
          block: true,
          label: s__('Organization|Home organization'),
          description: s__('Organization|Choose what organization you want to see by default.'),
          inputName: 'user[home_organization_id]',
          inputId: 'user_home_organization_id',
          initialSelection,
          toggleClass: 'gl-form-input-xl',
        },
      });
    },
  });
};

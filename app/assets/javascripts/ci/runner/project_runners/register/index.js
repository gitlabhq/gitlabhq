import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import RegistrationDropdown from '~/ci/runner/components/registration/registration_dropdown.vue';
import { PROJECT_TYPE } from '~/ci/runner/constants';
import { parseBoolean } from '~/lib/utils/common_utils';

Vue.use(VueApollo);

export const initProjectRunnersRegistrationDropdown = (
  selector = '#js-project-runner-registration-dropdown',
) => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { allowRegistrationToken, registrationToken, projectId } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectId,
    },
    render(h) {
      return h(RegistrationDropdown, {
        props: {
          allowRegistrationToken: parseBoolean(allowRegistrationToken),
          registrationToken,
          type: PROJECT_TYPE,
        },
      });
    },
  });
};

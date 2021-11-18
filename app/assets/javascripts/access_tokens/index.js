import Vue from 'vue';
import createFlash from '~/flash';
import { parseRailsFormFields } from '~/lib/utils/forms';
import { __ } from '~/locale';

import ExpiresAtField from './components/expires_at_field.vue';

export const initExpiresAtField = () => {
  const el = document.querySelector('.js-access-tokens-expires-at');

  if (!el) {
    return null;
  }

  const { expiresAt: inputAttrs } = parseRailsFormFields(el);

  return new Vue({
    el,
    render(h) {
      return h(ExpiresAtField, {
        props: {
          inputAttrs,
        },
      });
    },
  });
};

export const initProjectsField = () => {
  const el = document.querySelector('.js-access-tokens-projects');

  if (!el) {
    return null;
  }

  const { projects: inputAttrs } = parseRailsFormFields(el);

  if (window.gon.features.personalAccessTokensScopedToProjects) {
    return new Promise((resolve) => {
      Promise.all([
        import('./components/projects_field.vue'),
        import('vue-apollo'),
        import('~/lib/graphql'),
      ])
        .then(
          ([
            { default: ProjectsField },
            { default: VueApollo },
            { default: createDefaultClient },
          ]) => {
            const apolloProvider = new VueApollo({
              defaultClient: createDefaultClient(),
            });

            Vue.use(VueApollo);

            resolve(
              new Vue({
                el,
                apolloProvider,
                render(h) {
                  return h(ProjectsField, {
                    props: {
                      inputAttrs,
                    },
                  });
                },
              }),
            );
          },
        )
        .catch(() => {
          createFlash({
            message: __(
              'An error occurred while loading the access tokens form, please try again.',
            ),
          });
        });
    });
  }

  return null;
};

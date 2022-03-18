import Vue from 'vue';

import createFlash from '~/flash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { parseRailsFormFields } from '~/lib/utils/forms';
import { __ } from '~/locale';

import ExpiresAtField from './components/expires_at_field.vue';
import TokensApp from './components/tokens_app.vue';
import { FEED_TOKEN, INCOMING_EMAIL_TOKEN, STATIC_OBJECT_TOKEN } from './constants';

export const initExpiresAtField = () => {
  const el = document.querySelector('.js-access-tokens-expires-at');

  if (!el) {
    return null;
  }

  const { expiresAt: inputAttrs } = parseRailsFormFields(el);
  const { maxDate } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(ExpiresAtField, {
        props: {
          inputAttrs,
          maxDate: maxDate ? new Date(maxDate) : undefined,
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

export const initTokensApp = () => {
  const el = document.getElementById('js-tokens-app');

  if (!el) return false;

  const tokensData = convertObjectPropsToCamelCase(JSON.parse(el.dataset.tokensData), {
    deep: true,
  });

  const tokenTypes = {
    [FEED_TOKEN]: tokensData[FEED_TOKEN],
    [INCOMING_EMAIL_TOKEN]: tokensData[INCOMING_EMAIL_TOKEN],
    [STATIC_OBJECT_TOKEN]: tokensData[STATIC_OBJECT_TOKEN],
  };

  return new Vue({
    el,
    provide: {
      tokenTypes,
    },
    render(createElement) {
      return createElement(TokensApp);
    },
  });
};

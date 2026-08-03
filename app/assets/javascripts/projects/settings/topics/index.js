import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import TopicsTokenSelector from './components/topics_token_selector.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('.js-topics-selector');

  if (!el) return null;

  const { hiddenInputId, organizationId } = el.dataset;
  const hiddenInput = document.getElementById(hiddenInputId);

  const selected = hiddenInput.value
    ? hiddenInput.value.split(/,\s*/).map((token, index) => ({
        id: index,
        name: token,
      }))
    : [];

  return initVueApp({
    el,
    name: 'TopicsTokenSelectorRoot',
    apolloProvider,
    component: TopicsTokenSelector,
    props: {
      selected,
      organizationId,
    },
    events: {
      update(tokens) {
        const value = tokens.map(({ name }) => name).join(', ');
        hiddenInput.value = value;
        // Dispatch `input` event so form submit button becomes active
        hiddenInput.dispatchEvent(
          new Event('input', {
            bubbles: true,
            cancelable: true,
          }),
        );
      },
    },
  });
};

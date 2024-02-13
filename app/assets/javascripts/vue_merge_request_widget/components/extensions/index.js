import Vue from 'vue';
import { markRaw } from '~/lib/utils/vue3compat/mark_raw';
import ExtensionBase from './base.vue';

// Holds all the currently registered extensions
export const registeredExtensions = Vue.observable({ extensions: [] });

const createCustomOptionsWithFallback = (extension) => (options) => {
  return options.reduce((acc, option) => {
    acc[option] = extension[option] ?? ExtensionBase[option];
    return acc;
  }, {});
};

export const registerExtension = (extension) => {
  const customOptions = createCustomOptionsWithFallback(extension);
  registeredExtensions.extensions.push(
    markRaw({
      extends: ExtensionBase,
      name: extension.name,
      props: {
        mr: {
          type: Object,
          required: true,
        },
      },
      // Vue 3 doesn't copy custom component options with Vue.extend
      // We have to explicitly fallback to the base component if an option is missing
      ...customOptions([
        'telemetry',
        'i18n',
        'expandEvent',
        'enablePolling',
        'enableExpandedPolling',
        'modalComponent',
      ]),
      computed: {
        ...extension.props.reduce(
          (acc, propKey) => ({
            ...acc,
            [propKey]() {
              return this.mr[propKey];
            },
          }),
          {},
        ),
        ...Object.keys(extension.computed).reduce(
          (acc, computedKey) => ({
            ...acc,
            // Making the computed property a method allows us to pass in arguments
            // this allows for each computed property to receive some data
            [computedKey]() {
              return extension.computed[computedKey];
            },
          }),
          {},
        ),
      },
      methods: {
        ...extension.methods,
      },
    }),
  );
};

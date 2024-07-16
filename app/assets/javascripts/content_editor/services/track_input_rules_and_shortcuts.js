import { mapValues } from 'lodash';
import { InputRule } from '@tiptap/core';
import { ENTER_KEY, BACKSPACE_KEY } from '~/lib/utils/keys';
import Tracking from '~/tracking';
import {
  CONTENT_EDITOR_TRACKING_LABEL,
  KEYBOARD_SHORTCUT_TRACKING_ACTION,
  INPUT_RULE_TRACKING_ACTION,
} from '../constants';

const trackKeyboardShortcut =
  (contentType, commandFn, shortcut) =>
  (...args) => {
    Tracking.event(undefined, KEYBOARD_SHORTCUT_TRACKING_ACTION, {
      label: CONTENT_EDITOR_TRACKING_LABEL,
      property: `${contentType}.${shortcut}`,
    });
    return commandFn(...args);
  };

const trackInputRule = (contentType, inputRule) => {
  return new InputRule({
    find: inputRule.find,
    handler: (...args) => {
      const result = inputRule.handler(...args);

      if (result !== null) {
        Tracking.event(undefined, INPUT_RULE_TRACKING_ACTION, {
          label: CONTENT_EDITOR_TRACKING_LABEL,
          property: contentType,
        });
      }

      return result;
    },
  });
};

const trackInputRulesAndShortcuts = (tiptapExtension) => {
  return tiptapExtension
    .extend({
      addKeyboardShortcuts() {
        const shortcuts = this.parent?.() || {};
        const { name } = this;
        /**
         * We don’t want to track keyboard shortcuts
         * that are not deliberately executed to create
         * new types of content
         */
        const dotNotTrackKeys = [ENTER_KEY, BACKSPACE_KEY];
        const decorated = mapValues(shortcuts, (commandFn, shortcut) =>
          dotNotTrackKeys.includes(shortcut)
            ? commandFn
            : trackKeyboardShortcut(name, commandFn, shortcut),
        );

        return decorated;
      },
      addInputRules() {
        const inputRules = this.parent?.() || [];
        const { name } = this;

        return inputRules.map((inputRule) => trackInputRule(name, inputRule));
      },
    })
    .configure(tiptapExtension.options);
};

export default trackInputRulesAndShortcuts;

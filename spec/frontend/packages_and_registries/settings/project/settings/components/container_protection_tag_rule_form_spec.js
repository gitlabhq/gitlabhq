import { mountExtended } from 'helpers/vue_test_utils_helper';
import ContainerProtectionTagRuleForm from '~/packages_and_registries/settings/project/components/container_protection_tag_rule_form.vue';

describe('container Protection Rule Form', () => {
  let wrapper;

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const findTagNamePatternInput = () =>
    wrapper.findByRole('textbox', { name: /protect container tags matching/i });
  const findMinimumAccessLevelForPushSelect = () =>
    wrapper.findByRole('combobox', { name: /minimum role allowed to push/i });
  const findMinimumAccessLevelForDeleteSelect = () =>
    wrapper.findByRole('combobox', { name: /minimum role allowed to delete/i });

  const mountComponent = ({ config, provide = defaultProvidedValues } = {}) => {
    wrapper = mountExtended(ContainerProtectionTagRuleForm, {
      provide,
      ...config,
    });
  };

  describe('form fields', () => {
    describe('form field "tagNamePattern"', () => {
      it('exists', () => {
        mountComponent();

        expect(findTagNamePatternInput().exists()).toBe(true);
      });
    });

    describe('form field "minimumAccessLevelForPush"', () => {
      const minimumAccessLevelForPushOptions = () =>
        findMinimumAccessLevelForPushSelect()
          .findAll('option')
          .wrappers.map((option) => option.element.value);

      it.each(['MAINTAINER', 'OWNER', 'ADMIN'])(
        'includes the access level "%s" as an option',
        (accessLevel) => {
          mountComponent();

          expect(findMinimumAccessLevelForPushSelect().exists()).toBe(true);
          expect(minimumAccessLevelForPushOptions()).toContain(accessLevel);
        },
      );
    });

    describe('form field "minimumAccessLevelForDelete"', () => {
      const minimumAccessLevelForDeleteOptions = () =>
        findMinimumAccessLevelForDeleteSelect()
          .findAll('option')
          .wrappers.map((option) => option.element.value);

      it.each(['MAINTAINER', 'OWNER', 'ADMIN'])(
        'includes the access level "%s" as an option',
        (accessLevel) => {
          mountComponent();

          expect(findMinimumAccessLevelForDeleteSelect().exists()).toBe(true);
          expect(minimumAccessLevelForDeleteOptions()).toContain(accessLevel);
        },
      );
    });
  });
});

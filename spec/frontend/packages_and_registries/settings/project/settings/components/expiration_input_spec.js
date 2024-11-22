import { GlSprintf, GlFormInputGroup, GlInputGroupText, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { GlFormGroup } from 'jest/packages_and_registries/shared/stubs';
import ExpirationInput from '~/packages_and_registries/settings/project/components/expiration_input.vue';
import { NAME_REGEX_LENGTH } from '~/packages_and_registries/settings/project/constants';

describe('ExpirationInput', () => {
  let wrapper;

  const defaultProps = {
    name: 'foo',
    label: 'label-bar',
    placeholder: 'placeholder-baz',
    description: '%{linkStart}description-foo%{linkEnd}',
  };

  const tagsRegexHelpPagePath = 'fooPath';

  const findInputGroup = () => wrapper.findComponent(GlFormInputGroup);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findLabel = () => wrapper.findByTestId('label');
  const findDescription = () => wrapper.findByTestId('description');
  const findScreenReaderOnlyDescription = () => wrapper.findByTestId('regex-anchors-help-text');
  const findDescriptionLink = () => wrapper.findComponent(GlLink);
  const findPrependGroupText = () => wrapper.findAllComponents(GlInputGroupText).at(0);
  const findAppendGroupText = () => wrapper.findAllComponents(GlInputGroupText).at(1);

  const mountComponent = (props) => {
    wrapper = shallowMountExtended(ExpirationInput, {
      stubs: {
        GlSprintf,
        GlFormGroup,
      },
      provide: {
        tagsRegexHelpPagePath,
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('structure', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('has a label', () => {
      expect(findLabel().text()).toBe(defaultProps.label);
    });

    it('renders input group component', () => {
      expect(findInputGroup().exists()).toBe(true);
      expect(findInputGroup().attributes('aria-describedby')).toBe('regex-anchors-help-text');
    });

    it('renders aria-hidden prepend component', () => {
      expect(findPrependGroupText().text()).toBe('\\A');
      expect(findPrependGroupText().attributes('aria-hidden')).toBe('true');
    });

    it('renders aria-hidden append component', () => {
      expect(findAppendGroupText().text()).toBe('\\z');
      expect(findAppendGroupText().attributes('aria-hidden')).toBe('true');
    });

    it('has a description', () => {
      expect(findDescription().text()).toMatchInterpolatedText(defaultProps.description);
    });

    it('has description for screenreader', () => {
      expect(findScreenReaderOnlyDescription().attributes('id')).toBe('regex-anchors-help-text');
      expect(findScreenReaderOnlyDescription().attributes('class')).toBe('gl-sr-only');
      expect(findScreenReaderOnlyDescription().text()).toBe(
        'Regular expression without the \\A and \\z anchors.',
      );
    });

    it('has a description link', () => {
      const link = findDescriptionLink();
      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(tagsRegexHelpPagePath);
    });
  });

  describe('model', () => {
    it('assigns the right props to the input group component', () => {
      const value = 'foobar';
      const disabled = true;

      mountComponent({ value, disabled });

      expect(findInputGroup().attributes()).toMatchObject({
        id: defaultProps.name,
        value,
        placeholder: defaultProps.placeholder,
        disabled: `${disabled}`,
        trim: '',
      });
    });

    it('emits input event when input emits input', () => {
      const emittedValue = 'barfoo';

      mountComponent();

      findInputGroup().vm.$emit('input', emittedValue);
      expect(wrapper.emitted('input')).toEqual([[emittedValue]]);
    });
  });

  describe('regex input validation', () => {
    const invalidString = new Array(NAME_REGEX_LENGTH + 2).join(',');

    describe('when error contains an error message', () => {
      const errorMessage = 'something went wrong';

      it('shows the error message on the relevant field', () => {
        mountComponent({ error: errorMessage });

        expect(findFormGroup().attributes('invalid-feedback')).toBe(errorMessage);
      });

      it('gives precedence to API errors compared to local ones', () => {
        mountComponent({
          error: errorMessage,
          value: invalidString,
        });

        expect(findFormGroup().attributes('invalid-feedback')).toBe(errorMessage);
      });
    });

    describe('when error is empty', () => {
      describe('if the user did not type', () => {
        it('validation is not emitted', () => {
          mountComponent();

          expect(wrapper.emitted('validation')).toBeUndefined();
        });

        it('no error message is shown', () => {
          mountComponent();

          expect(findFormGroup().props('state')).toBe(true);
          expect(findFormGroup().attributes('invalid-feedback')).toBe('');
        });
      });

      describe('when the user typed something', () => {
        describe(`when name regex is longer than ${NAME_REGEX_LENGTH}`, () => {
          beforeEach(() => {
            // since the component has no state we both emit the event and set the prop
            mountComponent({ value: invalidString });

            findInputGroup().vm.$emit('input', invalidString);
          });

          it('input group validation state is false', () => {
            expect(findFormGroup().props('state')).toBe(false);
            expect(findInputGroup().attributes('state')).toBeUndefined();
          });

          it('emits the @validation event with false payload', () => {
            expect(wrapper.emitted('validation')).toEqual([[false]]);
          });
        });

        it(`when user input is less than ${NAME_REGEX_LENGTH} state is "true"`, () => {
          mountComponent();

          findInputGroup().vm.$emit('input', 'foo');

          expect(findFormGroup().props('state')).toBe(true);
          expect(findInputGroup().attributes('state')).toBe('true');
          expect(wrapper.emitted('validation')).toEqual([[true]]);
        });
      });
    });
  });
});

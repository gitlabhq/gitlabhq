import { GlFormFields } from '@gitlab/ui';

import NewEditForm from '~/projects/components/new_edit_form.vue';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  FORM_FIELD_NAME,
  FORM_FIELD_ID,
  FORM_FIELD_DESCRIPTION,
} from '~/projects/components/constants';
import { RESTRICTED_TOOLBAR_ITEMS_BASIC_EDITING_ONLY } from '~/vue_shared/components/markdown/constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('NewEditForm', () => {
  let wrapper;

  const defaultPropsData = {
    cancelButtonHref: '/-/organizations/default/groups_and_projects?display=projects',
    loading: false,
    previewMarkdownPath: '/-/organizations/preview_markdown',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(NewEditForm, {
      attachTo: document.body,
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findGlFormFields = () => wrapper.findComponent(GlFormFields);
  const findNameField = () => wrapper.findByLabelText('Project name');
  const findIdField = () => wrapper.findByLabelText('Project ID');
  const findDescriptionField = () => wrapper.findByLabelText('Project description (optional)');
  const findDescriptionCharacterCounter = () =>
    wrapper.findByTestId('description-character-counter');
  const findDescriptionMarkdownField = () => wrapper.findComponent(MarkdownField);

  it('renders `Project name` field', () => {
    createComponent();

    expect(findNameField().exists()).toBe(true);
  });

  it('renders `Project description` field as markdown editor', () => {
    createComponent();

    expect(findDescriptionField().exists()).toBe(true);
    expect(wrapper.findComponent(MarkdownField).props()).toMatchObject({
      markdownPreviewPath: defaultPropsData.previewMarkdownPath,
      markdownDocsPath: helpPagePath('user/markdown'),
      textareaValue: '',
      restrictedToolBarItems: RESTRICTED_TOOLBAR_ITEMS_BASIC_EDITING_ONLY,
    });
  });

  describe('Project description character counter', () => {
    describe('when character count is within 2000 characters', () => {
      beforeEach(() => {
        createComponent();

        findDescriptionField().setValue('a'.repeat(5));
      });

      it('renders the character counter correctly', () => {
        expect(findDescriptionCharacterCounter().classes()).toStrictEqual(['gl-text-subtle']);
        expect(findDescriptionCharacterCounter().text()).toBe('1995 characters remaining');
      });
    });

    describe('when character count is over 2000 characters', () => {
      beforeEach(() => {
        createComponent();

        findDescriptionField().setValue('a'.repeat(2005));
      });

      it('renders the character counter correctly', () => {
        expect(findDescriptionCharacterCounter().classes()).toStrictEqual(['gl-text-red-500']);
        expect(findDescriptionCharacterCounter().text()).toBe('5 characters over limit');
      });
    });
  });

  describe('when `initialFormValues` prop is set', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          initialFormValues: {
            [FORM_FIELD_NAME]: 'Foo bar',
            [FORM_FIELD_ID]: 1,
            [FORM_FIELD_DESCRIPTION]: 'foo bar baz description',
          },
        },
      });
    });

    it('sets initial values for fields', () => {
      expect(findNameField().element.value).toBe('Foo bar');
      expect(findIdField().element.value).toBe('1');
      expect(findDescriptionField().element.value).toBe('foo bar baz description');
      expect(findDescriptionMarkdownField().props('textareaValue')).toBe('foo bar baz description');
    });
  });

  describe('when `serverValidations` prop is set', () => {
    const serverValidations = {
      [FORM_FIELD_DESCRIPTION]: 'Project description is too long (maximum is 2000 characters)',
    };

    beforeEach(() => {
      createComponent({
        propsData: {
          serverValidations,
        },
      });
    });

    it('passes prop to `GlFormFields`', () => {
      expect(findGlFormFields().props('serverValidations')).toEqual(serverValidations);
    });
  });

  it('renders `Project ID` field as disabled', () => {
    createComponent();

    expect(findIdField().attributes('disabled')).toBe('disabled');
  });

  describe('when `loading` prop is `true`', () => {
    beforeEach(() => {
      createComponent({ propsData: { loading: true } });
    });

    it('shows button with loading icon', () => {
      expect(wrapper.findByTestId('submit-button').props('loading')).toBe(true);
    });
  });

  it('renders cancel button', () => {
    expect(wrapper.findByRole('link', { name: 'Cancel' }).attributes('href')).toBe(
      defaultPropsData.cancelButtonHref,
    );
  });

  describe('when `submitButtonText` prop is not set', () => {
    beforeEach(() => {
      createComponent();
    });

    it('defaults to `Save changes`', () => {
      expect(wrapper.findByRole('button', { name: 'Save changes' }).exists()).toBe(true);
    });
  });

  describe('when `submitButtonText` prop is set', () => {
    beforeEach(() => {
      createComponent({ propsData: { submitButtonText: 'Create project' } });
    });

    it('uses it for submit button', () => {
      expect(wrapper.findByRole('button', { name: 'Create project' }).exists()).toBe(true);
    });
  });

  describe('when `GlFormFields` emits `submit` event', () => {
    const formValues = {
      [FORM_FIELD_NAME]: 'Foo bar',
      [FORM_FIELD_ID]: 1,
      [FORM_FIELD_DESCRIPTION]: 'foo bar baz description',
    };

    beforeEach(() => {
      createComponent({
        propsData: {
          initialFormValues: formValues,
        },
      });

      findGlFormFields().vm.$emit('submit');
    });

    it('emits `submit` event with form values', () => {
      expect(wrapper.emitted('submit')).toEqual([[formValues]]);
    });
  });

  describe('when `GlFormFields` emits `input-field` event', () => {
    const event = { name: FORM_FIELD_NAME, value: 'Foo bar' };

    beforeEach(() => {
      createComponent();

      findGlFormFields().vm.$emit('input-field', event);
    });

    it('emits `input-field` event', () => {
      expect(wrapper.emitted('input-field')).toEqual([[event]]);
    });
  });
});

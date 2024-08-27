import { GlLink, GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';

import NewEditForm from '~/groups/components/new_edit_form.vue';
import GroupPathField from '~/groups/components/group_path_field.vue';
import VisibilityLevelRadioButtons from '~/visibility_level/components/visibility_level_radio_buttons.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  VISIBILITY_LEVELS_STRING_TO_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
  GROUP_VISIBILITY_LEVEL_DESCRIPTIONS,
} from '~/visibility_level/constants';
import {
  FORM_FIELD_NAME,
  FORM_FIELD_PATH,
  FORM_FIELD_ID,
  FORM_FIELD_VISIBILITY_LEVEL,
} from '~/groups/constants';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('NewEditForm', () => {
  let wrapper;

  const defaultPropsData = {
    loading: false,
    basePath: 'http://127.0.0.1:3000/',
    cancelPath: '/-/organizations/default/groups_and_projects?display=groups',
    pathMaxlength: 10,
    pathPattern: '[a-zA-Z0-9_\\.][a-zA-Z0-9_\\-\\.]{0,254}[a-zA-Z0-9_\\-]|[a-zA-Z0-9_]',
    availableVisibilityLevels: Object.values(VISIBILITY_LEVELS_STRING_TO_INTEGER),
    restrictedVisibilityLevels: [],
    initialFormValues: {
      [FORM_FIELD_NAME]: '',
      [FORM_FIELD_PATH]: '',
      [FORM_FIELD_VISIBILITY_LEVEL]: VISIBILITY_LEVEL_PUBLIC_INTEGER,
    },
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(NewEditForm, {
      attachTo: document.body,
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      stubs: {
        GroupPathField: true,
      },
    });
  };

  const findNameField = () => wrapper.findByLabelText('Group name');
  const findPathField = () => wrapper.findComponent(GroupPathField);
  const findVisibilityLevelField = () => wrapper.findComponent(VisibilityLevelRadioButtons);
  const findSubmitButton = () => wrapper.findByTestId('submit-button');

  const setPathFieldValue = async (value) => {
    findPathField().vm.$emit('input', value);
    await nextTick();
  };
  const setVisibilityLevelFieldValue = async (value) => {
    findVisibilityLevelField().vm.$emit('input', value);
    await nextTick();
  };
  const submitForm = async () => {
    await findSubmitButton().trigger('click');
  };

  it('renders `Group name` field with label description', () => {
    createComponent();

    expect(findNameField().exists()).toBe(true);

    const formGroup = wrapper.findByTestId(`${FORM_FIELD_VISIBILITY_LEVEL}-group`);
    expect(formGroup.text()).toContain('Who will be able to see this group?');
    expect(formGroup.findComponent(GlLink).attributes('href')).toBe(
      helpPagePath('user/public_access'),
    );
  });

  it('renders SCIM warning', () => {
    createComponent();

    expect(wrapper.findComponent(GlAlert).text()).toBe(
      'Your group name must not contain a period if you intend to use SCIM integration, as it can lead to errors.',
    );
  });

  it('renders `Group URL` field', () => {
    createComponent();

    expect(findPathField().exists()).toBe(true);
  });

  it('renders `Visibility level` field with correct props', () => {
    createComponent();

    expect(findVisibilityLevelField().props()).toMatchObject({
      checked: VISIBILITY_LEVEL_PUBLIC_INTEGER,
      visibilityLevels: defaultPropsData.availableVisibilityLevels,
      visibilityLevelDescriptions: GROUP_VISIBILITY_LEVEL_DESCRIPTIONS,
    });
  });

  describe('when editing a group', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          initialFormValues: {
            [FORM_FIELD_ID]: 5,
            [FORM_FIELD_NAME]: 'Foo bar',
            [FORM_FIELD_PATH]: 'foo-bar',
            [FORM_FIELD_VISIBILITY_LEVEL]: VISIBILITY_LEVEL_PUBLIC_INTEGER,
          },
        },
      });
    });

    it('renders `Group ID` field', () => {
      expect(wrapper.findByLabelText('Group ID').element.value).toBe('5');
    });

    it('renders alert about changing URL', () => {
      const alert = wrapper.findByTestId('changing-url-alert');

      expect(alert.text()).toBe('Changing group URL can have unintended side effects. Learn more.');
      expect(alert.findComponent(HelpPageLink).props()).toEqual({
        href: 'user/group/manage',
        anchor: 'change-a-groups-path',
      });
    });

    it('does not modify `Group URL` when typing in `Group name`', async () => {
      await findNameField().setValue('Foo bar baz');

      expect(findPathField().props('value')).toBe('foo-bar');
    });

    it('sets `isEditing` prop to `true`', () => {
      expect(findPathField().props('isEditing')).toBe(true);
    });
  });

  describe('when form is submitted without filling in required fields', () => {
    beforeEach(async () => {
      createComponent();
      await submitForm();
    });

    it('shows error message', () => {
      expect(wrapper.findByText('Enter a descriptive name for your group.').exists()).toBe(true);
      expect(wrapper.findByText('Enter a path for your group.').exists()).toBe(true);
      expect(wrapper.emitted('submit')).toBeUndefined();
    });
  });

  describe('when `Group URL` field is over max length characters', () => {
    beforeEach(async () => {
      createComponent();
      await setPathFieldValue('foo-bar-baz');
      await submitForm();
    });

    it('shows error message', () => {
      expect(wrapper.findByText('Group path cannot be longer than 10 characters.').exists()).toBe(
        true,
      );
      expect(wrapper.emitted('submit')).toBeUndefined();
    });
  });

  describe('when `Group URL` does not match pattern', () => {
    beforeEach(async () => {
      createComponent();
      await setPathFieldValue('-foo');
      await submitForm();
    });

    it('shows error message', () => {
      expect(
        wrapper
          .findByText(
            'Choose a group path that does not start with a dash or end with a period. It can also contain alphanumeric characters and underscores.',
          )
          .exists(),
      ).toBe(true);
      expect(wrapper.emitted('submit')).toBeUndefined();
    });
  });

  describe('when `Group URL` has not been manually set', () => {
    beforeEach(async () => {
      createComponent();

      await findNameField().setValue('Foo bar');
    });

    it('sets `Group URL` when typing in `Group name`', () => {
      expect(findPathField().props('value')).toBe('foo-bar');
    });
  });

  describe('when `Group URL` has been manually set', () => {
    beforeEach(async () => {
      createComponent();

      await setPathFieldValue('foo-bar-baz');
      await findNameField().setValue('Foo bar');
    });

    it('does not modify `Group URL` when typing in `Group name`', () => {
      expect(findPathField().props('value')).toBe('foo-bar-baz');
    });
  });

  describe('when form is submitted successfully', () => {
    beforeEach(async () => {
      createComponent();

      await findNameField().setValue('Foo bar');
      await setVisibilityLevelFieldValue(VISIBILITY_LEVEL_PUBLIC_INTEGER);
      await submitForm();
    });

    it('emits `submit` event with form values', () => {
      expect(wrapper.emitted('submit')).toEqual([
        [{ name: 'Foo bar', path: 'foo-bar', visibilityLevel: VISIBILITY_LEVEL_PUBLIC_INTEGER }],
      ]);
    });
  });

  it('shows cancel button', () => {
    expect(wrapper.findByRole('link', { name: 'Cancel' }).attributes('href')).toBe(
      defaultPropsData.cancelPath,
    );
  });

  it('passes `loading` prop to submit button', () => {
    createComponent();

    expect(findSubmitButton().props('loading')).toBe(false);
  });

  describe('when `submitButtonText` prop is set', () => {
    beforeEach(() => {
      createComponent({ propsData: { submitButtonText: 'Save changes' } });
    });

    it('uses it for submit button', () => {
      expect(wrapper.findByRole('button', { name: 'Save changes' }).exists()).toBe(true);
    });
  });
});

import { nextTick } from 'vue';

import NewGroupForm from '~/groups/components/new_group_form.vue';
import GroupPathField from '~/groups/components/group_path_field.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('NewGroupForm', () => {
  let wrapper;

  const defaultPropsData = {
    basePath: 'http://127.0.0.1:3000/',
    cancelPath: '/-/organizations/default/groups_and_projects?display=groups',
    pathMaxlength: 10,
    pathPattern: '[a-zA-Z0-9_\\.][a-zA-Z0-9_\\-\\.]{0,254}[a-zA-Z0-9_\\-]|[a-zA-Z0-9_]',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(NewGroupForm, {
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

  const findPathField = () => wrapper.findComponent(GroupPathField);

  const setPathFieldValue = async (value) => {
    findPathField().vm.$emit('input', value);
    await nextTick();
  };
  const submitForm = async () => {
    await wrapper.findByRole('button', { name: 'Create group' }).trigger('click');
  };

  it('renders `Group URL` field', () => {
    createComponent();

    expect(findPathField().exists()).toBe(true);
  });

  describe('when form is submitted without filling in required fields', () => {
    beforeEach(async () => {
      createComponent();
      await submitForm();
    });

    it('shows error message', () => {
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

  describe('when form is submitted successfully', () => {
    beforeEach(async () => {
      createComponent();

      await setPathFieldValue('foo-bar');
      await submitForm();
    });

    it('emits `submit` event with form values', () => {
      expect(wrapper.emitted('submit')).toEqual([[{ path: 'foo-bar' }]]);
    });
  });

  it('shows cancel button', () => {
    expect(wrapper.findByRole('link', { name: 'Cancel' }).attributes('href')).toBe(
      defaultPropsData.cancelPath,
    );
  });
});

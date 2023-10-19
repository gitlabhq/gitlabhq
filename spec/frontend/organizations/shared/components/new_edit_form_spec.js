import { GlButton, GlInputGroupText, GlTruncate } from '@gitlab/ui';

import NewEditForm from '~/organizations/shared/components/new_edit_form.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('NewEditForm', () => {
  let wrapper;

  const defaultProvide = {
    organizationsPath: '/-/organizations',
    rootUrl: 'http://127.0.0.1:3000/',
  };

  const defaultPropsData = {
    loading: false,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(NewEditForm, {
      attachTo: document.body,
      provide: defaultProvide,
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findNameField = () => wrapper.findByLabelText('Organization name');
  const findUrlField = () => wrapper.findByLabelText('Organization URL');
  const submitForm = async () => {
    await wrapper.findByRole('button', { name: 'Create organization' }).trigger('click');
  };

  it('renders `Organization name` field', () => {
    createComponent();

    expect(findNameField().exists()).toBe(true);
  });

  it('renders `Organization URL` field', () => {
    createComponent();

    expect(wrapper.findComponent(GlInputGroupText).findComponent(GlTruncate).props('text')).toBe(
      'http://127.0.0.1:3000/-/organizations/',
    );
    expect(findUrlField().exists()).toBe(true);
  });

  describe('when form is submitted without filling in required fields', () => {
    beforeEach(async () => {
      createComponent();
      await submitForm();
    });

    it('shows error messages', () => {
      expect(wrapper.findByText('Organization name is required.').exists()).toBe(true);
      expect(wrapper.findByText('Organization URL is required.').exists()).toBe(true);
    });
  });

  describe('when form is submitted successfully', () => {
    beforeEach(async () => {
      createComponent();

      await findNameField().setValue('Foo bar');
      await findUrlField().setValue('foo-bar');
      await submitForm();
    });

    it('emits `submit` event with form values', () => {
      expect(wrapper.emitted('submit')).toEqual([[{ name: 'Foo bar', path: 'foo-bar' }]]);
    });
  });

  describe('when `Organization URL` has not been manually set', () => {
    beforeEach(async () => {
      createComponent();

      await findNameField().setValue('Foo bar');
      await submitForm();
    });

    it('sets `Organization URL` when typing in `Organization name`', () => {
      expect(findUrlField().element.value).toBe('foo-bar');
    });
  });

  describe('when `Organization URL` has been manually set', () => {
    beforeEach(async () => {
      createComponent();

      await findUrlField().setValue('foo-bar-baz');
      await findNameField().setValue('Foo bar');
      await submitForm();
    });

    it('does not modify `Organization URL` when typing in `Organization name`', () => {
      expect(findUrlField().element.value).toBe('foo-bar-baz');
    });
  });

  describe('when `loading` prop is `true`', () => {
    beforeEach(() => {
      createComponent({ propsData: { loading: true } });
    });

    it('shows button with loading icon', () => {
      expect(wrapper.findComponent(GlButton).props('loading')).toBe(true);
    });
  });
});

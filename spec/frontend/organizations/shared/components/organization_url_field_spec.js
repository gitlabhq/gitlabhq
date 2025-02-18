import { GlFormInputGroup, GlInputGroupText, GlTruncate, GlFormInput } from '@gitlab/ui';

import OrganizedUrlField from '~/organizations/shared/components/organization_url_field.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('OrganizationUrlField', () => {
  let wrapper;

  const defaultProvide = {
    organizationsPath: '/-/organizations',
    rootUrl: 'http://127.0.0.1:3000/',
  };

  const defaultPropsData = {
    id: 'organization-url',
    value: 'foo-bar',
    validation: {
      invalidFeedback: 'Invalid',
      state: false,
    },
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(OrganizedUrlField, {
      attachTo: document.body,
      provide: defaultProvide,
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findInputGroup = () => wrapper.findComponent(GlFormInputGroup);
  const findInput = () => findInputGroup().findComponent(GlFormInput);

  it('renders organization url field with correct props', () => {
    createComponent();

    expect(
      findInputGroup().findComponent(GlInputGroupText).findComponent(GlTruncate).props('text'),
    ).toBe('http://127.0.0.1:3000/-/organizations/');
    expect(findInput().attributes('id')).toBe(defaultPropsData.id);
    expect(findInput().vm.$attrs).toMatchObject({
      invalidFeedback: defaultPropsData.validation.invalidFeedback,
    });
    expect(findInput().props()).toMatchObject({
      value: defaultPropsData.value,
      state: defaultPropsData.validation.state,
    });
  });

  it('emits `input` event', () => {
    createComponent();

    findInput().vm.$emit('input', 'foo');

    expect(wrapper.emitted('input')).toEqual([['foo']]);
  });

  it('emits `blur` event', () => {
    createComponent();

    findInput().vm.$emit('blur', true);

    expect(wrapper.emitted('blur')).toEqual([[true]]);
  });
});

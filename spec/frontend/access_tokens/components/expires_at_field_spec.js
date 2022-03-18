import { shallowMount } from '@vue/test-utils';
import ExpiresAtField from '~/access_tokens/components/expires_at_field.vue';

describe('~/access_tokens/components/expires_at_field', () => {
  let wrapper;

  const defaultPropsData = {
    inputAttrs: {
      id: 'personal_access_token_expires_at',
      name: 'personal_access_token[expires_at]',
      placeholder: 'YYYY-MM-DD',
    },
  };

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMount(ExpiresAtField, {
      propsData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render datepicker with input info', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});

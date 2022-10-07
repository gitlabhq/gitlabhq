import { GlButton, GlFormInput } from '@gitlab/ui';

import FormUrlMaskItem from '~/webhooks/components/form_url_mask_item.vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('FormUrlMaskItem', () => {
  let wrapper;

  const defaultProps = {
    index: 0,
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(FormUrlMaskItem, {
      propsData: { ...defaultProps },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findMaskItemKey = () => wrapper.findByTestId('mask-item-key');
  const findMaskItemValue = () => wrapper.findByTestId('mask-item-value');
  const findRemoveButton = () => wrapper.findComponent(GlButton);

  describe('template', () => {
    it('renders input for key and value', () => {
      createComponent();

      const keyInput = findMaskItemKey();
      expect(keyInput.attributes('label')).toBe(FormUrlMaskItem.i18n.keyLabel);
      expect(keyInput.findComponent(GlFormInput).attributes('name')).toBe(
        'hook[url_variables][][key]',
      );

      const valueInput = findMaskItemValue();
      expect(valueInput.attributes('label')).toBe(FormUrlMaskItem.i18n.valueLabel);
      expect(valueInput.findComponent(GlFormInput).attributes('name')).toBe(
        'hook[url_variables][][value]',
      );
    });

    it('renders remove button', () => {
      createComponent();

      expect(findRemoveButton().props('icon')).toBe('remove');
    });
  });
});

import { nextTick } from 'vue';
import { GlFormRadio, GlFormRadioGroup, GlLink } from '@gitlab/ui';

import FormUrlApp from '~/webhooks/components/form_url_app.vue';
import FormUrlMaskItem from '~/webhooks/components/form_url_mask_item.vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('FormUrlApp', () => {
  let wrapper;

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMountExtended(FormUrlApp, {
      propsData: { ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findAllRadioButtons = () => wrapper.findAllComponents(GlFormRadio);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findUrlMaskDisable = () => findAllRadioButtons().at(0);
  const findUrlMaskEnable = () => findAllRadioButtons().at(1);
  const findAllUrlMaskItems = () => wrapper.findAllComponents(FormUrlMaskItem);
  const findAddItem = () => wrapper.findComponent(GlLink);
  const findFormUrl = () => wrapper.findByTestId('form-url');
  const findFormUrlPreview = () => wrapper.findByTestId('form-url-preview');
  const findUrlMaskSection = () => wrapper.findByTestId('url-mask-section');

  describe('template', () => {
    it('renders radio buttons for URL masking', () => {
      createComponent();

      expect(findAllRadioButtons()).toHaveLength(2);
      expect(findUrlMaskDisable().text()).toBe(FormUrlApp.i18n.radioFullUrlText);
      expect(findUrlMaskEnable().text()).toBe(FormUrlApp.i18n.radioMaskUrlText);
    });

    it('does not render mask section', () => {
      createComponent();

      expect(findUrlMaskSection().exists()).toBe(false);
    });

    describe('on radio select', () => {
      beforeEach(async () => {
        createComponent();

        findRadioGroup().vm.$emit('input', true);
        await nextTick();
      });

      it('renders mask section', () => {
        expect(findUrlMaskSection().exists()).toBe(true);
      });

      it('renders an empty mask item by default', () => {
        expect(findAllUrlMaskItems()).toHaveLength(1);

        const firstItem = findAllUrlMaskItems().at(0);
        expect(firstItem.props('itemKey')).toBeNull();
        expect(firstItem.props('itemValue')).toBeNull();
      });
    });

    describe('with mask items', () => {
      const mockItem1 = { key: 'key1', value: 'value1' };
      const mockItem2 = { key: 'key2', value: 'value2' };

      beforeEach(() => {
        createComponent({
          props: { initialUrlVariables: [mockItem1, mockItem2] },
        });
      });

      it('renders masked URL preview', async () => {
        const mockUrl = 'https://test.host/value1?secret=value2';

        findFormUrl().vm.$emit('input', mockUrl);
        await nextTick();

        expect(findFormUrlPreview().attributes('value')).toBe(
          'https://test.host/{key1}?secret={key2}',
        );
      });

      it('renders mask items correctly', () => {
        expect(findAllUrlMaskItems()).toHaveLength(2);

        const firstItem = findAllUrlMaskItems().at(0);
        expect(firstItem.props('itemKey')).toBe(mockItem1.key);
        expect(firstItem.props('itemValue')).toBe(mockItem1.value);

        const secondItem = findAllUrlMaskItems().at(1);
        expect(secondItem.props('itemKey')).toBe(mockItem2.key);
        expect(secondItem.props('itemValue')).toBe(mockItem2.value);
      });

      describe('on mask item input', () => {
        const mockInput = { index: 0, key: 'display', value: 'secret' };

        it('updates mask item', async () => {
          const firstItem = findAllUrlMaskItems().at(0);
          firstItem.vm.$emit('input', mockInput);
          await nextTick();

          expect(firstItem.props('itemKey')).toBe(mockInput.key);
          expect(firstItem.props('itemValue')).toBe(mockInput.value);
        });
      });

      describe('when add item is clicked', () => {
        it('adds mask item', async () => {
          findAddItem().vm.$emit('click');
          await nextTick();

          expect(findAllUrlMaskItems()).toHaveLength(3);

          const lastItem = findAllUrlMaskItems().at(-1);
          expect(lastItem.props('itemKey')).toBeNull();
          expect(lastItem.props('itemValue')).toBeNull();
        });
      });

      describe('when remove item is clicked', () => {
        it('removes the correct mask item', async () => {
          const firstItem = findAllUrlMaskItems().at(0);
          firstItem.vm.$emit('remove');
          await nextTick();

          expect(findAllUrlMaskItems()).toHaveLength(1);

          const newFirstItem = findAllUrlMaskItems().at(0);
          expect(newFirstItem.props('itemKey')).toBe(mockItem2.key);
          expect(newFirstItem.props('itemValue')).toBe(mockItem2.value);
        });
      });
    });
  });
});

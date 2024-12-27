import { nextTick } from 'vue';
import { GlFormGroup, GlFormRadio, GlFormRadioGroup, GlLink, GlAlert } from '@gitlab/ui';
import { scrollToElement } from '~/lib/utils/common_utils';

import FormUrlApp from '~/webhooks/components/form_url_app.vue';
import FormUrlMaskItem from '~/webhooks/components/form_url_mask_item.vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

jest.mock('~/lib/utils/common_utils');

describe('FormUrlApp', () => {
  let wrapper;

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMountExtended(FormUrlApp, {
      propsData: { ...props },
    });
  };

  const findAllRadioButtons = () => wrapper.findAllComponents(GlFormRadio);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findUrlMaskDisable = () => findAllRadioButtons().at(0);
  const findUrlMaskEnable = () => findAllRadioButtons().at(1);
  const findAllUrlMaskItems = () => wrapper.findAllComponents(FormUrlMaskItem);
  const findAddItem = () => wrapper.findComponent(GlLink);
  const findFormUrl = () => wrapper.findByTestId('form-url');
  const findFormUrlGroup = () => wrapper.findAllComponents(GlFormGroup).at(0);
  const findFormUrlPreview = () => wrapper.findByTestId('form-url-preview');
  const findUrlMaskSection = () => wrapper.findByTestId('url-mask-section');
  const findFormEl = () => document.querySelector('.js-webhook-form');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const submitForm = () => findFormEl().dispatchEvent(new Event('submit'));

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
        expect(firstItem.props()).toMatchObject({
          itemKey: null,
          itemValue: null,
        });
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
        expect(firstItem.props()).toMatchObject({
          itemKey: mockItem1.key,
          itemValue: mockItem1.value,
          isEditing: true,
        });

        const secondItem = findAllUrlMaskItems().at(1);
        expect(secondItem.props()).toMatchObject({
          itemKey: mockItem2.key,
          itemValue: mockItem2.value,
          isEditing: true,
        });
      });

      describe('on mask item input', () => {
        const mockInput = { index: 0, key: 'display', value: 'secret' };

        it('updates mask item', async () => {
          const firstItem = findAllUrlMaskItems().at(0);
          firstItem.vm.$emit('input', mockInput);
          await nextTick();

          expect(firstItem.props()).toMatchObject({
            itemKey: mockInput.key,
            itemValue: mockInput.value,
          });
        });
      });

      describe('when add item is clicked', () => {
        it('adds mask item', async () => {
          findAddItem().vm.$emit('click');
          await nextTick();

          expect(findAllUrlMaskItems()).toHaveLength(3);

          const lastItem = findAllUrlMaskItems().at(2);
          expect(lastItem.props()).toMatchObject({
            itemKey: null,
            itemValue: null,
          });
        });
      });

      describe('when remove item is clicked', () => {
        it('removes the correct mask item', async () => {
          const firstItem = findAllUrlMaskItems().at(0);
          firstItem.vm.$emit('remove');
          await nextTick();

          expect(findAllUrlMaskItems()).toHaveLength(1);

          const newFirstItem = findAllUrlMaskItems().at(0);
          expect(newFirstItem.props()).toMatchObject({
            itemKey: mockItem2.key,
            itemValue: mockItem2.value,
          });
        });
      });
    });

    describe('token will be cleared warning', () => {
      beforeEach(() => {
        createComponent({ initialUrl: 'url' });
      });

      it('is hidden when URL has not changed', () => {
        expect(findAlert().exists()).toBe(false);
      });

      it('is displayed when URL has changed', async () => {
        findFormUrl().vm.$emit('input', 'another_url');
        await nextTick();

        expect(findAlert().exists()).toBe(true);
      });
    });

    describe('validations', () => {
      const inputRequiredText = FormUrlApp.i18n.inputRequired;

      beforeEach(() => {
        setHTMLFixture('<form class="js-webhook-form"></form>');
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it.each`
        url                       | state        | scrollToElementCalls
        ${null}                   | ${undefined} | ${1}
        ${''}                     | ${undefined} | ${1}
        ${'https://example.com/'} | ${'true'}    | ${0}
      `('when URL is `$url`, state is `$state`', async ({ url, state, scrollToElementCalls }) => {
        createComponent({
          props: { initialUrl: url },
        });

        submitForm();
        await nextTick();

        expect(findFormUrlGroup().attributes('state')).toBe(state);
        expect(scrollToElement).toHaveBeenCalledTimes(scrollToElementCalls);
        expect(findFormUrlGroup().attributes('invalid-feedback')).toBe(inputRequiredText);
      });

      it.each`
        key      | value       | keyInvalidFeedback   | valueInvalidFeedback              | scrollToElementCalls
        ${null}  | ${null}     | ${inputRequiredText} | ${inputRequiredText}              | ${1}
        ${null}  | ${'random'} | ${inputRequiredText} | ${FormUrlApp.i18n.valuePartOfUrl} | ${1}
        ${null}  | ${'secret'} | ${inputRequiredText} | ${null}                           | ${1}
        ${'key'} | ${null}     | ${null}              | ${inputRequiredText}              | ${1}
        ${'key'} | ${'secret'} | ${null}              | ${null}                           | ${0}
      `(
        'when key is `$key` and value is `$value`',
        async ({ key, value, keyInvalidFeedback, valueInvalidFeedback, scrollToElementCalls }) => {
          createComponent({
            props: { initialUrl: 'http://example.com?password=secret' },
          });
          findRadioGroup().vm.$emit('input', true);
          await nextTick();

          const maskItem = findAllUrlMaskItems().at(0);
          const mockInput = { index: 0, key, value };
          maskItem.vm.$emit('input', mockInput);

          submitForm();
          await nextTick();

          expect(maskItem.props('keyInvalidFeedback')).toBe(keyInvalidFeedback);
          expect(maskItem.props('valueInvalidFeedback')).toBe(valueInvalidFeedback);
          expect(scrollToElement).toHaveBeenCalledTimes(scrollToElementCalls);
        },
      );

      describe('when initialUrlVariables is passed', () => {
        it('does not validate empty values', async () => {
          const initialUrlVariables = [{ key: 'key' }];

          createComponent({
            props: { initialUrl: 'url', initialUrlVariables },
          });

          submitForm();
          await nextTick();

          const maskItem = findAllUrlMaskItems().at(0);

          expect(maskItem.props('keyInvalidFeedback')).toBeNull();
          expect(maskItem.props('valueInvalidFeedback')).toBeNull();
          expect(scrollToElement).not.toHaveBeenCalled();
        });
      });
    });
  });
});

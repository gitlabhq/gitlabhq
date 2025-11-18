import { nextTick } from 'vue';
import { GlAlert, GlFormGroup } from '@gitlab/ui';
import { scrollToElement } from '~/lib/utils/scroll_utils';

import FormUrlApp from '~/webhooks/components/form_url_app.vue';
import FormUrlMaskItem from '~/webhooks/components/form_url_mask_item.vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

jest.mock('~/lib/utils/scroll_utils');

describe('FormUrlApp', () => {
  let wrapper;

  const mockUrl = 'https://test.host/value1?secret=value2';

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMountExtended(FormUrlApp, {
      propsData: { ...props },
    });
  };

  const findUrlInput = () => wrapper.findByTestId('webhook-url');
  const findUrlInputGroup = () => wrapper.findAllComponents(GlFormGroup).at(0);
  const findUrlPreview = () => wrapper.findByTestId('webhook-url-preview');
  const findAddItemButton = () => wrapper.findByTestId('add-item-button');
  const findAllUrlMaskItems = () => wrapper.findAllComponents(FormUrlMaskItem);
  const findFormEl = () => document.querySelector('.js-webhook-form');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const submitForm = async () => {
    findFormEl().dispatchEvent(new Event('submit'));
    await nextTick();
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders URL input', () => {
    expect(findUrlInput().props('name')).toBe('hook[url]');
    expect(findUrlInput().props('value')).toBeNull();
  });

  describe('without URL masking', () => {
    it('renders add button as "Add URL masking"', () => {
      expect(findAddItemButton().text()).toBe('+ Add URL masking');
    });

    it('does not render URL mask items', () => {
      expect(findAllUrlMaskItems()).toHaveLength(0);
    });

    it('does not render "URL preview"', () => {
      expect(findUrlPreview().exists()).toBe(false);
    });
  });

  describe('when "Add URL masking" is clicked', () => {
    beforeEach(() => {
      createComponent();

      findUrlInput().vm.$emit('input', mockUrl);
      findAddItemButton().vm.$emit('click');
    });

    it('renders add button as "Mask another portion of URL"', () => {
      expect(findAddItemButton().text()).toBe('+ Mask another portion of URL');
    });

    it('renders empty URL mask item', () => {
      expect(findAllUrlMaskItems()).toHaveLength(1);

      const firstItem = findAllUrlMaskItems().at(0);
      expect(firstItem.props()).toMatchObject({
        itemKey: null,
        itemValue: null,
      });
    });

    it('renders "URL preview"', () => {
      expect(findUrlPreview().attributes('value')).toBe('https://test.host/value1?secret=value2');
    });

    describe('on mask item input', () => {
      const mockInput = { index: 0, key: 'secret', value: 'value2' };
      let firstItem;

      beforeEach(() => {
        firstItem = findAllUrlMaskItems().at(0);
        firstItem.vm.$emit('input', mockInput);
      });

      it('updates mask item', () => {
        expect(firstItem.props()).toMatchObject({
          itemKey: mockInput.key,
          itemValue: mockInput.value,
        });
      });

      it('renders masked "URL preview"', () => {
        expect(findUrlPreview().attributes('value')).toBe(
          'https://test.host/value1?secret={secret}',
        );
      });
    });
  });

  describe('when editing webhook with URL masking', () => {
    const mockItem1 = { key: 'key1' };
    const mockItem2 = { key: 'key2' };

    beforeEach(() => {
      createComponent({
        props: {
          initialUrl: 'https://test.host/{key1}?secret={key2}',
          initialUrlVariables: [mockItem1, mockItem2],
        },
      });
    });

    it('renders URL input', () => {
      expect(findUrlInput().props('value')).toBe('https://test.host/{key1}?secret={key2}');
    });

    it('renders URL mask items correctly', () => {
      expect(findAllUrlMaskItems()).toHaveLength(2);

      const firstItem = findAllUrlMaskItems().at(0);
      expect(firstItem.props()).toMatchObject({
        itemKey: mockItem1.key,
        itemValue: null,
        isExisting: true,
      });

      const secondItem = findAllUrlMaskItems().at(1);
      expect(secondItem.props()).toMatchObject({
        itemKey: mockItem2.key,
        itemValue: null,
        isExisting: true,
      });
    });

    it('renders masked URL preview', () => {
      expect(findUrlPreview().attributes('value')).toBe('https://test.host/{key1}?secret={key2}');
    });

    describe('when add button is clicked', () => {
      beforeEach(() => {
        findAddItemButton().vm.$emit('click');
      });

      it('adds empty mask item', () => {
        expect(findAllUrlMaskItems()).toHaveLength(3);

        const lastItem = findAllUrlMaskItems().at(2);
        expect(lastItem.props()).toMatchObject({
          itemKey: null,
          itemValue: null,
        });
      });

      describe('on mask item input', () => {
        const mockInput = { index: 2, key: 'domain', value: 'test.host' };
        let lastItem;

        beforeEach(() => {
          lastItem = findAllUrlMaskItems().at(2);
          lastItem.vm.$emit('input', mockInput);
        });

        it('updates mask item', () => {
          expect(lastItem.props()).toMatchObject({
            itemKey: mockInput.key,
            itemValue: mockInput.value,
          });
        });

        it('renders masked "URL preview"', () => {
          expect(findUrlPreview().attributes('value')).toBe(
            'https://{domain}/{key1}?secret={key2}',
          );
        });
      });

      describe('when remove event is emitted', () => {
        it('removes the correct mask item', async () => {
          await findAllUrlMaskItems().at(2).vm.$emit('remove', 2);

          expect(findAllUrlMaskItems()).toHaveLength(2);

          const newLastItem = findAllUrlMaskItems().at(1);
          expect(newLastItem.props()).toMatchObject({
            itemKey: mockItem2.key,
            itemValue: null,
          });
        });
      });
    });

    describe('token will be cleared warning', () => {
      it('is hidden when URL has not changed', () => {
        expect(findAlert().exists()).toBe(false);
      });

      it('is displayed when URL has changed', async () => {
        await findUrlInput().vm.$emit('input', 'another_url');

        expect(findAlert().exists()).toBe(true);
      });
    });
  });

  describe('validations', () => {
    const inputRequiredText = 'This field is required.';

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
      createComponent();

      findUrlInput().vm.$emit('input', url);

      await submitForm();

      expect(findUrlInputGroup().attributes('state')).toBe(state);
      expect(findUrlInputGroup().attributes('invalid-feedback')).toBe('A URL is required.');
      expect(scrollToElement).toHaveBeenCalledTimes(scrollToElementCalls);
    });

    it.each`
      key      | value       | keyInvalidFeedback   | valueInvalidFeedback        | scrollToElementCalls
      ${null}  | ${null}     | ${inputRequiredText} | ${inputRequiredText}        | ${1}
      ${null}  | ${'random'} | ${inputRequiredText} | ${'Must match part of URL'} | ${1}
      ${null}  | ${'secret'} | ${inputRequiredText} | ${null}                     | ${1}
      ${'key'} | ${null}     | ${null}              | ${inputRequiredText}        | ${1}
      ${'key'} | ${'secret'} | ${null}              | ${null}                     | ${0}
    `(
      'when key is `$key` and value is `$value`',
      async ({ key, value, keyInvalidFeedback, valueInvalidFeedback, scrollToElementCalls }) => {
        createComponent();

        findUrlInput().vm.$emit('input', 'http://example.com?password=secret');

        await findAddItemButton().vm.$emit('click');

        const maskItem = findAllUrlMaskItems().at(0);
        const mockInput = { index: 0, key, value };
        maskItem.vm.$emit('input', mockInput);

        await submitForm();

        expect(maskItem.props('keyInvalidFeedback')).toBe(keyInvalidFeedback);
        expect(maskItem.props('valueInvalidFeedback')).toBe(valueInvalidFeedback);
        expect(scrollToElement).toHaveBeenCalledTimes(scrollToElementCalls);
      },
    );

    describe('when initialUrlVariables is passed', () => {
      it('does not validate empty values', async () => {
        const initialUrlVariables = [{ key: 'key' }];

        createComponent({
          props: { initialUrl: mockUrl, initialUrlVariables },
        });

        await submitForm();

        const maskItem = findAllUrlMaskItems().at(0);

        expect(maskItem.props('keyInvalidFeedback')).toBeNull();
        expect(maskItem.props('valueInvalidFeedback')).toBeNull();
        expect(scrollToElement).not.toHaveBeenCalled();
      });
    });
  });
});

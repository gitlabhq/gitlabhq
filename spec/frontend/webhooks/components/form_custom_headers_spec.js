import { nextTick } from 'vue';

import { scrollToElement } from '~/lib/utils/common_utils';
import FormCustomHeaders from '~/webhooks/components/form_custom_headers.vue';
import FormCustomHeaderItem from '~/webhooks/components/form_custom_header_item.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

jest.mock('~/lib/utils/common_utils');

describe('FormCustomHeaders', () => {
  let wrapper;

  const createEmptyCustomHeaders = () => ({
    initialCustomHeaders: [],
  });

  const createFilledCustomHeaders = () => ({
    initialCustomHeaders: [
      { key: 'key1', value: 'value1' },
      { key: 'key2', value: 'value2' },
    ],
  });

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMountExtended(FormCustomHeaders, {
      propsData: props,
      stubs: {
        CrudComponent,
      },
    });
  };

  const findCustomHeadersCard = () => wrapper.findByTestId('custom-headers-card');
  const findAllCustomHeaderItems = () => wrapper.findAllComponents(FormCustomHeaderItem);
  const findAddItem = () => wrapper.findByTestId('add-custom-header');

  describe('template', () => {
    it('renders custom headers card', () => {
      createComponent({ props: createEmptyCustomHeaders() });

      expect(findCustomHeadersCard().exists()).toBe(true);
    });

    describe('when add item is clicked', () => {
      it('adds custom header item', async () => {
        createComponent({ props: createFilledCustomHeaders() });

        findAddItem().vm.$emit('click');
        await nextTick();

        expect(findAllCustomHeaderItems()).toHaveLength(3);

        const lastItem = findAllCustomHeaderItems().at(2);
        expect(lastItem.props()).toMatchObject({
          headerKey: '',
          headerValue: '',
        });
      });
    });

    describe('when remove item is clicked', () => {
      it('removes the correct custom header item', async () => {
        createComponent({ props: createFilledCustomHeaders() });

        const firstItem = findAllCustomHeaderItems().at(0);
        firstItem.vm.$emit('remove');
        await nextTick();

        expect(findAllCustomHeaderItems()).toHaveLength(1);

        const newFirstItem = findAllCustomHeaderItems().at(0);
        expect(newFirstItem.props()).toMatchObject({
          headerKey: 'key2',
          headerValue: 'value2',
        });
      });
    });

    describe('when maximum headers are reached', () => {
      it('does not render add item button', () => {
        createComponent({
          props: {
            initialCustomHeaders: Array.from({ length: 20 }, (i) => ({
              key: `key${i}`,
              value: `value${i}`,
            })),
          },
        });

        expect(findAddItem().exists()).toBe(false);
      });
    });
  });

  describe('validation', () => {
    beforeEach(() => {
      setHTMLFixture('<form class="js-webhook-form"></form>');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    const findFormEl = () => document.querySelector('.js-webhook-form');
    const submitForm = (event) => findFormEl().dispatchEvent(event);

    const createFakeSubmitEvent = () => {
      const event = new Event('submit');
      event.preventDefault = jest.fn();
      event.stopPropagation = jest.fn();
      return event;
    };

    it('prevents submit event when form is invalid', async () => {
      createComponent({ props: { initialCustomHeaders: [{ key: 'key', value: '' }] } });

      const fakeEvent = createFakeSubmitEvent();
      submitForm(fakeEvent);
      await nextTick();

      expect(fakeEvent.preventDefault).toHaveBeenCalled();
      expect(fakeEvent.stopPropagation).toHaveBeenCalled();
      expect(scrollToElement).toHaveBeenCalledTimes(1);
    });

    it('does not prevent submit event when form is valid', async () => {
      createComponent({ props: { initialCustomHeaders: [{ key: 'key', value: 'value' }] } });

      const fakeEvent = createFakeSubmitEvent();
      submitForm(fakeEvent);
      await nextTick();

      expect(fakeEvent.preventDefault).not.toHaveBeenCalled();
      expect(fakeEvent.stopPropagation).not.toHaveBeenCalled();
      expect(scrollToElement).not.toHaveBeenCalled();
    });
  });
});

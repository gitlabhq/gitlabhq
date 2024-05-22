import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlFormGroup, GlFormInput, GlModal } from '@gitlab/ui';
import createStore from '~/vue_shared/components/metric_images/store';
import MetricImageDetailsModal from '~/vue_shared/components/metric_images/metric_image_details_modal.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import { fileList } from './mock_data';

Vue.use(Vuex);

const mockEvent = { preventDefault: jest.fn() };

describe('Metric image details modal', () => {
  let wrapper;
  let store;
  const testText = 'test text';
  const testUrl = 'https://valid-url.com';

  const mountComponent = (options = {}) => {
    store = createStore({}, {});

    wrapper = shallowMountExtended(MetricImageDetailsModal, {
      store,
      stubs: {
        GlFormGroup: stubComponent(GlFormGroup, {
          props: ['state', 'invalidFeedback'],
        }),
        GlFormInput: stubComponent(GlFormInput, {
          props: ['state', 'value'],
          template: '<input />',
        }),
      },
      ...options,
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findTextInput = () =>
    wrapper.findComponent('[data-testid="metric-image-details-modal-text-input"]');
  const findUrlInput = () =>
    wrapper.findComponent('[data-testid="metric-image-details-modal-url-input"]');
  const findUrlFormGroup = () =>
    wrapper.findComponent('[data-testid="metric-image-details-url-form-group"]');
  const findForm = () => wrapper.findComponent('[data-testid="metric-image-details-modal-form"]');
  const cancelModal = () => findModal().vm.$emit('hidden');
  const submitForm = () => findForm().vm.$emit('submit', mockEvent);
  const setTextInputValue = (value) => findTextInput().vm.$emit('input', value);
  const setUrlInputValue = (value) => findUrlInput().vm.$emit('input', value);

  describe('should display', () => {
    beforeEach(() => {
      mountComponent({
        propsData: { visible: true },
      });
    });

    it('a description of the url field', () => {
      const urlGroup = findUrlFormGroup();
      expect(urlGroup.attributes('description')).toBe('Must start with http:// or https://');
    });
  });

  describe('when URL is invalid', () => {
    it('should have an error state', async () => {
      mountComponent({ propsData: { visible: true } });

      setUrlInputValue('invalid-url');
      submitForm();

      await nextTick();

      const urlGroup = findUrlFormGroup();
      const urlInput = findUrlInput();

      expect(urlGroup.props('state')).toBe(false);
      expect(urlGroup.props('invalidFeedback')).toBe('Invalid URL');
      expect(urlInput.props('state')).toBe(false);
    });

    it('should focus on the URL input on submit', async () => {
      mountComponent({
        attachTo: document.body,
        propsData: { visible: true },
        stubs: {
          GlFormInput: {
            template: '<input />',
          },
        },
      });

      setUrlInputValue('invalid-url');
      submitForm();

      await waitForPromises();

      const urlInput = findUrlInput();
      expect(urlInput.element).toBe(document.activeElement);
    });

    describe('and modal is in the add state', () => {
      it('should not dispatch uploadImage action', async () => {
        mountComponent({ propsData: { visible: true } });
        const dispatchSpy = jest.spyOn(store, 'dispatch');

        setUrlInputValue('invalid-url');
        submitForm();

        await waitForPromises();

        expect(dispatchSpy).not.toHaveBeenCalled();
      });
    });

    describe('and modal is in the edit state', () => {
      it('should not dispatch updateImage action', async () => {
        mountComponent({
          propsData: {
            edit: true,
            imageId: 1,
            filename: 'test.jpg',
            url: '',
            urlText: '',
            visible: true,
          },
        });
        const dispatchSpy = jest.spyOn(store, 'dispatch');

        setUrlInputValue('invalid-url');
        submitForm();

        await waitForPromises();

        expect(dispatchSpy).not.toHaveBeenCalled();
      });
    });
  });

  describe('when is in the add state', () => {
    beforeEach(() => {
      mountComponent({
        propsData: {
          imageFiles: fileList,
          visible: true,
        },
      });
    });

    it('should display a modal title', () => {
      expect(findModal().attributes('title')).toBe('Add image details');
    });

    it('should display a modal description', () => {
      const description = wrapper.findComponent(
        '[data-testid="metric-image-details-modal-description"]',
      );

      expect(description.text()).toBe(
        "Add text or a link to display with your image. If you don't add either, the file name displays instead.",
      );
    });

    it('should display an empty text field', () => {
      const textInput = findTextInput();

      expect(textInput.props('value')).toBe('');
    });

    it('should display an empty url field', () => {
      const urlInput = findUrlInput();

      expect(urlInput.props('value')).toBe('');
    });

    it('should send files, text and url when submitted', async () => {
      const dispatchSpy = jest.spyOn(store, 'dispatch');

      setTextInputValue(testText);
      setUrlInputValue(testUrl);

      submitForm();

      await waitForPromises();

      expect(dispatchSpy).toHaveBeenCalledWith('uploadImage', {
        files: fileList,
        url: testUrl,
        urlText: testText,
      });
    });

    describe('after submit', () => {
      it('should clear url, text fields and emit `hidden` event', async () => {
        setTextInputValue(testText);
        setUrlInputValue(testUrl);

        await nextTick();

        expect(findTextInput().props('value')).toBe(testText);
        expect(findUrlInput().props('value')).toBe(testUrl);

        submitForm();

        await waitForPromises();

        expect(findTextInput().props('value')).toBe('');
        expect(findUrlInput().props('value')).toBe('');
        expect(wrapper.emitted().hidden).toHaveLength(1);
      });
    });

    describe('when cancelled', () => {
      it('should clear url, text fields and emit `hidden` event', async () => {
        setTextInputValue(testText);
        setUrlInputValue(testUrl);

        await nextTick();

        expect(findTextInput().props('value')).toBe(testText);
        expect(findUrlInput().props('value')).toBe(testUrl);

        cancelModal();

        await waitForPromises();

        expect(findTextInput().props('value')).toBe('');
        expect(findUrlInput().props('value')).toBe('');
        expect(wrapper.emitted().hidden).toHaveLength(1);
      });
    });
  });

  describe('when is in the edit state', () => {
    const updatedText = 'updated text';
    const updatedUrl = 'https://updated-url.com';

    beforeEach(() => {
      mountComponent({
        propsData: {
          edit: true,
          imageId: 1,
          filename: 'test.jpg',
          url: testUrl,
          urlText: testText,
          visible: true,
        },
      });
    });

    it('should display a modal title', () => {
      expect(findModal().props('title')).toBe('Editing test.jpg');
    });

    it('should display the text field with prefilled value', () => {
      expect(findTextInput().props('value')).toBe(testText);
    });

    it('should display the url field with prefilled value', () => {
      expect(findUrlInput().props('value')).toBe(testUrl);
    });

    it('should update text and url when changed', async () => {
      const dispatchSpy = jest.spyOn(store, 'dispatch');

      setTextInputValue(updatedText);
      setUrlInputValue(updatedUrl);

      submitForm();

      await waitForPromises();

      expect(dispatchSpy).toHaveBeenCalledWith('updateImage', {
        imageId: 1,
        url: updatedUrl,
        urlText: updatedText,
      });
    });

    describe('after submit', () => {
      it('should restore url, text fields and emit `hidden` event', async () => {
        setTextInputValue(updatedText);
        setUrlInputValue(updatedUrl);

        await nextTick();

        expect(findTextInput().props('value')).toBe(updatedText);
        expect(findUrlInput().props('value')).toBe(updatedUrl);

        submitForm();

        await waitForPromises();

        expect(findTextInput().props('value')).toBe(testText);
        expect(findUrlInput().props('value')).toBe(testUrl);
        expect(wrapper.emitted().hidden).toHaveLength(1);
      });
    });

    describe('when cancelled', () => {
      it('should restore url, text fields and emit `hidden` event', async () => {
        setTextInputValue(updatedText);
        setUrlInputValue(updatedUrl);

        await nextTick();

        expect(findTextInput().props('value')).toBe(updatedText);
        expect(findUrlInput().props('value')).toBe(updatedUrl);

        cancelModal();

        await waitForPromises();

        expect(findTextInput().props('value')).toBe(testText);
        expect(findUrlInput().props('value')).toBe(testUrl);
        expect(wrapper.emitted().hidden).toHaveLength(1);
      });
    });
  });
});

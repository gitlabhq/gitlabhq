import { shallowMount } from '@vue/test-utils';
import App from '~/issue_show/components/app.vue';
import { TEST_HOST } from 'helpers/constants';
import { getJSONFixture } from 'helpers/fixtures';

import Poll from '~/lib/utils/poll';
import eventHub from '~/issue_show/event_hub';
import Service from '~/issue_show/services/index';
import Store from '~/issue_show/stores';
import Form from '~/issue_show/components/form.vue';

jest.mock('~/lib/utils/poll');
jest.mock('~/issue_show/services/index');
jest.mock('~/issue_show/stores');

const mockState = {};
const mockFormState = {};

Store.mockImplementation(function mockStoreConstructor() {
  this.state = mockState;
  this.formState = mockFormState;
});

describe('issue_show app component', () => {
  const endpointUrl = `${TEST_HOST}/issue/realtime_changes`;
  const defaultProps = {
    canUpdate: true,
    canDestroy: true,
    endpoint: endpointUrl,
    updateEndpoint: `${TEST_HOST}/issue/update`,
    issuableRef: '#1',
    initialTitleHtml: '',
    initialTitleText: '',
    initialDescriptionHtml: 'test',
    initialDescriptionText: 'test',
    markdownPreviewPath: '/',
    markdownDocsPath: '/',
    projectNamespace: '/',
    projectPath: '/',
  };

  let wrapper;

  beforeEach(() => {
    Poll.mockClear();
    // eventHub.mockClear();
    Service.mockClear();
    Store.mockClear();

    Object.assign(mockState, {
      titleText: 'some title',
      titleHtml: '<p>some title</p>',
    });

    wrapper = shallowMount(App, {
      propsData: defaultProps,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('store', () => {
    it('is created when mounting', () => {
      expect(Store).toHaveBeenCalledTimes(1);
      const props = wrapper.props();
      expect(Store).toHaveBeenCalledWith({
        titleHtml: props.initialTitleHtml,
        titleText: props.initialTitleText,
        descriptionHtml: props.initialDescriptionHtml,
        descriptionText: props.initialDescriptionText,
        updatedAt: props.updatedAt,
        updatedByName: props.updatedByName,
        updatedByPath: props.updatedByPath,
        taskStatus: props.initialTaskStatus,
      });
      expect(wrapper.vm.store).toBe(Store.mock.instances[0]);
    });
  });

  describe('polling', () => {
    it('is set up when mounting', () => {
      expect(Service).toHaveBeenCalledTimes(1);
      expect(Service).toHaveBeenCalledWith(endpointUrl);
      expect(Poll).toHaveBeenCalledTimes(1);
      const pollingOptions = Poll.mock.calls[0];
      expect(pollingOptions.length).toBe(1);
      expect(pollingOptions[0]).toEqual({
        resource: Service.mock.instances[0],
        method: 'getData',
        successCallback: expect.any(Function),
        errorCallback: expect.any(Function),
      });
    });

    it('updates the store for successful request', () => {
      const realtimeChangesData = getJSONFixture('issues/realtime_changes.json');
      const pollingOptions = Poll.mock.calls[0];
      const { successCallback } = pollingOptions[0];

      successCallback({ data: realtimeChangesData });

      const { store } = wrapper.vm;
      expect(store.updateState).toHaveBeenCalledTimes(1);
      expect(store.updateState).toHaveBeenCalledWith(realtimeChangesData);
    });
  });

  describe('form', () => {
    const findForm = () => wrapper.find(Form);

    test.each`
      canUpdate | showForm | isVisible
      ${false}  | ${false} | ${false}
      ${false}  | ${true}  | ${false}
      ${true}   | ${false} | ${false}
      ${true}   | ${true}  | ${true}
    `(
      'toggles for canUpdate = $canUpdate and showForm = $showForm',
      ({ canUpdate, showForm, isVisible }) => {
        wrapper.setProps({
          ...defaultProps,
          canUpdate,
        });
        wrapper.vm.showForm = showForm;

        expect(findForm().exists()).toBe(isVisible);
      },
    );

    describe('if shown', () => {
      beforeEach(() => {
        wrapper.setProps({
          ...defaultProps,
          canUpdate: true,
        });
        wrapper.vm.showForm = true;
      });

      it('updates formState from store', () => {
        Object.assign(mockFormState, {
          newState: true,
        });

        expect(findForm().props().formState).toEqual(mockFormState);
      });

      it('does not update formState when emitting open.form event', () => {
        eventHub.$emit('open.form');

        const { store } = wrapper.vm;
        expect(store.setFormState).not.toHaveBeenCalled();
      });
    });

    describe('if not shown', () => {
      beforeEach(() => {
        wrapper.setProps({
          ...defaultProps,
          canUpdate: true,
        });
      });

      it('is shown when emitting open.form event', () => {
        expect(findForm().exists()).toBe(false);

        eventHub.$emit('open.form');

        expect(findForm().exists()).toBe(true);
      });

      it('updates formState when emitting open.form event', () => {
        eventHub.$emit('open.form');

        const { store } = wrapper.vm;
        expect(store.setFormState).toHaveBeenCalledTimes(1);
        expect(store.setFormState).toHaveBeenCalledWith({
          title: store.state.titleText,
          description: store.state.descriptionText,
          lockedWarningVisible: false,
          updateLoading: false,
        });
      });
    });
  });
});

import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Tracking from '~/tracking';
import component from '~/registry/settings/components/settings_form.vue';
import expirationPolicyFields from '~/registry/shared/components/expiration_policy_fields.vue';
import updateContainerExpirationPolicyMutation from '~/registry/settings/graphql/mutations/update_container_expiration_policy.graphql';
import expirationPolicyQuery from '~/registry/settings/graphql/queries/get_expiration_policy.graphql';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '~/registry/shared/constants';
import { GlCard, GlLoadingIcon } from '../../shared/stubs';
import { expirationPolicyPayload, expirationPolicyMutationPayload } from '../mock_data';

const localVue = createLocalVue();

describe('Settings Form', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const {
    data: {
      project: { containerExpirationPolicy },
    },
  } = expirationPolicyPayload();

  const defaultProps = {
    value: { ...containerExpirationPolicy },
  };

  const trackingPayload = {
    label: 'docker_container_retention_and_expiration_policies',
  };

  const findForm = () => wrapper.find({ ref: 'form-element' });
  const findFields = () => wrapper.find(expirationPolicyFields);
  const findCancelButton = () => wrapper.find({ ref: 'cancel-button' });
  const findSaveButton = () => wrapper.find({ ref: 'save-button' });

  const mountComponent = ({
    props = defaultProps,
    data,
    config,
    provide = defaultProvidedValues,
    mocks,
  } = {}) => {
    wrapper = shallowMount(component, {
      stubs: {
        GlCard,
        GlLoadingIcon,
      },
      propsData: { ...props },
      provide,
      data() {
        return {
          ...data,
        };
      },
      mocks: {
        $toast: {
          show: jest.fn(),
        },
        ...mocks,
      },
      ...config,
    });
  };

  const mountComponentWithApollo = ({ provide = defaultProvidedValues, resolver } = {}) => {
    localVue.use(VueApollo);

    const requestHandlers = [
      [updateContainerExpirationPolicyMutation, resolver],
      [expirationPolicyQuery, jest.fn().mockResolvedValue(expirationPolicyPayload())],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    fakeApollo.defaultClient.cache.writeQuery({
      query: expirationPolicyQuery,
      variables: {
        projectPath: provide.projectPath,
      },
      ...expirationPolicyPayload(),
    });

    mountComponent({
      provide,
      config: {
        localVue,
        apolloProvider: fakeApollo,
      },
    });

    return requestHandlers.map(resolvers => resolvers[1]);
  };

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data binding', () => {
    it('v-model change update the settings property', () => {
      mountComponent();
      findFields().vm.$emit('input', { newValue: 'foo' });
      expect(wrapper.emitted('input')).toEqual([['foo']]);
    });

    it('v-model change update the api error property', () => {
      const apiErrors = { baz: 'bar' };
      mountComponent({ data: { apiErrors } });
      expect(findFields().props('apiErrors')).toEqual(apiErrors);
      findFields().vm.$emit('input', { newValue: 'foo', modified: 'baz' });
      expect(findFields().props('apiErrors')).toEqual({});
    });

    it('shows the default option when none are selected', () => {
      mountComponent({ props: { value: {} } });
      expect(findFields().props('value')).toEqual({
        cadence: 'EVERY_DAY',
        keepN: 'TEN_TAGS',
        olderThan: 'NINETY_DAYS',
      });
    });
  });

  describe('form', () => {
    describe('form reset event', () => {
      beforeEach(() => {
        mountComponent();

        findForm().trigger('reset');
      });
      it('calls the appropriate function', () => {
        expect(wrapper.emitted('reset')).toEqual([[]]);
      });

      it('tracks the reset event', () => {
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'reset_form', trackingPayload);
      });
    });

    describe('form submit event ', () => {
      it('save has type submit', () => {
        mountComponent();

        expect(findSaveButton().attributes('type')).toBe('submit');
      });

      it('dispatches the correct apollo mutation', async () => {
        const [expirationPolicyMutationResolver] = mountComponentWithApollo({
          resolver: jest.fn().mockResolvedValue(expirationPolicyMutationPayload()),
        });

        findForm().trigger('submit');
        await expirationPolicyMutationResolver();
        expect(expirationPolicyMutationResolver).toHaveBeenCalled();
      });

      it('tracks the submit event', () => {
        mountComponentWithApollo({
          resolver: jest.fn().mockResolvedValue(expirationPolicyMutationPayload()),
        });

        findForm().trigger('submit');

        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'submit_form', trackingPayload);
      });

      it('show a success toast when submit succeed', async () => {
        const handlers = mountComponentWithApollo({
          resolver: jest.fn().mockResolvedValue(expirationPolicyMutationPayload()),
        });

        findForm().trigger('submit');
        await Promise.all(handlers);
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_SUCCESS_MESSAGE, {
          type: 'success',
        });
      });

      describe('when submit fails', () => {
        describe('user recoverable errors', () => {
          it('when there is an error is shown in a toast', async () => {
            const handlers = mountComponentWithApollo({
              resolver: jest
                .fn()
                .mockResolvedValue(expirationPolicyMutationPayload({ errors: ['foo'] })),
            });

            findForm().trigger('submit');
            await Promise.all(handlers);
            await wrapper.vm.$nextTick();

            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('foo', {
              type: 'error',
            });
          });
        });
        describe('global errors', () => {
          it('shows an error', async () => {
            const handlers = mountComponentWithApollo({
              resolver: jest.fn().mockRejectedValue(expirationPolicyMutationPayload()),
            });

            findForm().trigger('submit');
            await Promise.all(handlers);
            await wrapper.vm.$nextTick();
            await wrapper.vm.$nextTick();

            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_ERROR_MESSAGE, {
              type: 'error',
            });
          });

          it('parses the error messages', async () => {
            const mutate = jest.fn().mockRejectedValue({
              graphQLErrors: [
                {
                  extensions: {
                    problems: [{ path: ['name'], message: 'baz' }],
                  },
                },
              ],
            });
            mountComponent({ mocks: { $apollo: { mutate } } });

            findForm().trigger('submit');
            await waitForPromises();
            await wrapper.vm.$nextTick();

            expect(findFields().props('apiErrors')).toEqual({ name: 'baz' });
          });
        });
      });
    });
  });

  describe('form actions', () => {
    describe('cancel button', () => {
      it('has type reset', () => {
        mountComponent();

        expect(findCancelButton().attributes('type')).toBe('reset');
      });

      it.each`
        isLoading | isEdited | mutationLoading | isDisabled
        ${true}   | ${true}  | ${true}         | ${true}
        ${false}  | ${true}  | ${true}         | ${true}
        ${false}  | ${false} | ${true}         | ${true}
        ${true}   | ${false} | ${false}        | ${true}
        ${false}  | ${false} | ${false}        | ${true}
        ${false}  | ${true}  | ${false}        | ${false}
      `(
        'when isLoading is $isLoading and isEdited is $isEdited and mutationLoading is $mutationLoading is $isDisabled that the is disabled',
        ({ isEdited, isLoading, mutationLoading, isDisabled }) => {
          mountComponent({
            props: { ...defaultProps, isEdited, isLoading },
            data: { mutationLoading },
          });

          const expectation = isDisabled ? 'true' : undefined;
          expect(findCancelButton().attributes('disabled')).toBe(expectation);
        },
      );
    });

    describe('submit button', () => {
      it('has type submit', () => {
        mountComponent();

        expect(findSaveButton().attributes('type')).toBe('submit');
      });
      it.each`
        isLoading | fieldsAreValid | mutationLoading | isDisabled
        ${true}   | ${true}        | ${true}         | ${true}
        ${false}  | ${true}        | ${true}         | ${true}
        ${false}  | ${false}       | ${true}         | ${true}
        ${true}   | ${false}       | ${false}        | ${true}
        ${false}  | ${false}       | ${false}        | ${true}
        ${false}  | ${true}        | ${false}        | ${false}
      `(
        'when isLoading is $isLoading and fieldsAreValid is $fieldsAreValid and mutationLoading is $mutationLoading is $isDisabled that the is disabled',
        ({ fieldsAreValid, isLoading, mutationLoading, isDisabled }) => {
          mountComponent({
            props: { ...defaultProps, isLoading },
            data: { mutationLoading, fieldsAreValid },
          });

          const expectation = isDisabled ? 'true' : undefined;
          expect(findSaveButton().attributes('disabled')).toBe(expectation);
        },
      );

      it.each`
        isLoading | mutationLoading | showLoading
        ${true}   | ${true}         | ${true}
        ${true}   | ${false}        | ${true}
        ${false}  | ${true}         | ${true}
        ${false}  | ${false}        | ${false}
      `(
        'when isLoading is $isLoading and mutationLoading is $mutationLoading is $showLoading that the loading icon is shown',
        ({ isLoading, mutationLoading, showLoading }) => {
          mountComponent({
            props: { ...defaultProps, isLoading },
            data: { mutationLoading },
          });

          expect(findSaveButton().props('loading')).toBe(showLoading);
        },
      );
    });
  });
});

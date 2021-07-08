import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { GlCard, GlLoadingIcon } from 'jest/registry/shared/stubs';
import component from '~/packages_and_registries/settings/project/components/settings_form.vue';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '~/packages_and_registries/settings/project/constants';
import updateContainerExpirationPolicyMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_container_expiration_policy.mutation.graphql';
import expirationPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_expiration_policy.query.graphql';
import Tracking from '~/tracking';
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

  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"');
  const findSaveButton = () => wrapper.find('[data-testid="save-button"');
  const findEnableToggle = () => wrapper.find('[data-testid="enable-toggle"]');
  const findCadenceDropdown = () => wrapper.find('[data-testid="cadence-dropdown"]');
  const findKeepNDropdown = () => wrapper.find('[data-testid="keep-n-dropdown"]');
  const findKeepRegexInput = () => wrapper.find('[data-testid="keep-regex-input"]');
  const findOlderThanDropdown = () => wrapper.find('[data-testid="older-than-dropdown"]');
  const findRemoveRegexInput = () => wrapper.find('[data-testid="remove-regex-input"]');

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

  const mountComponentWithApollo = ({
    provide = defaultProvidedValues,
    mutationResolver,
    queryPayload = expirationPolicyPayload(),
  } = {}) => {
    localVue.use(VueApollo);

    const requestHandlers = [
      [updateContainerExpirationPolicyMutation, mutationResolver],
      [expirationPolicyQuery, jest.fn().mockResolvedValue(queryPayload)],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    // This component does not do the query directly, but we need a proper cache to update
    fakeApollo.defaultClient.cache.writeQuery({
      query: expirationPolicyQuery,
      variables: {
        projectPath: provide.projectPath,
      },
      ...queryPayload,
    });

    // we keep in sync what prop we pass to the component with the cache
    const {
      data: {
        project: { containerExpirationPolicy: value },
      },
    } = queryPayload;

    mountComponent({
      provide,
      props: {
        ...defaultProps,
        value,
      },
      config: {
        localVue,
        apolloProvider: fakeApollo,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    model              | finder                   | fieldName         | type          | defaultValue
    ${'enabled'}       | ${findEnableToggle}      | ${'Enable'}       | ${'toggle'}   | ${false}
    ${'cadence'}       | ${findCadenceDropdown}   | ${'Cadence'}      | ${'dropdown'} | ${'EVERY_DAY'}
    ${'keepN'}         | ${findKeepNDropdown}     | ${'Keep N'}       | ${'dropdown'} | ${''}
    ${'nameRegexKeep'} | ${findKeepRegexInput}    | ${'Keep Regex'}   | ${'textarea'} | ${''}
    ${'olderThan'}     | ${findOlderThanDropdown} | ${'OlderThan'}    | ${'dropdown'} | ${''}
    ${'nameRegex'}     | ${findRemoveRegexInput}  | ${'Remove regex'} | ${'textarea'} | ${''}
  `('$fieldName', ({ model, finder, type, defaultValue }) => {
    it('matches snapshot', () => {
      mountComponent();

      expect(finder().element).toMatchSnapshot();
    });

    it('input event triggers a model update', () => {
      mountComponent();

      finder().vm.$emit('input', 'foo');
      expect(wrapper.emitted('input')[0][0]).toMatchObject({
        [model]: 'foo',
      });
    });

    it('shows the default option when none are selected', () => {
      mountComponent({ props: { value: {} } });
      expect(finder().props('value')).toEqual(defaultValue);
    });

    if (type !== 'toggle') {
      it.each`
        isLoading | mutationLoading | enabledValue
        ${false}  | ${false}        | ${false}
        ${true}   | ${false}        | ${false}
        ${true}   | ${true}         | ${true}
        ${false}  | ${true}         | ${true}
        ${false}  | ${false}        | ${false}
      `(
        'is disabled when is loading is $isLoading, mutationLoading is $mutationLoading and enabled is $enabledValue',
        ({ isLoading, mutationLoading, enabledValue }) => {
          mountComponent({
            props: { isLoading, value: { enabled: enabledValue } },
            data: { mutationLoading },
          });
          expect(finder().props('disabled')).toEqual(true);
        },
      );
    } else {
      it.each`
        isLoading | mutationLoading
        ${true}   | ${false}
        ${true}   | ${true}
        ${false}  | ${true}
      `(
        'is disabled when is loading is $isLoading and mutationLoading is $mutationLoading',
        ({ isLoading, mutationLoading }) => {
          mountComponent({
            props: { isLoading, value: {} },
            data: { mutationLoading },
          });
          expect(finder().props('disabled')).toEqual(true);
        },
      );
    }

    if (type === 'textarea') {
      it('input event updates the api error property', async () => {
        const apiErrors = { [model]: 'bar' };
        mountComponent({ data: { apiErrors } });

        finder().vm.$emit('input', 'foo');
        expect(finder().props('error')).toEqual('bar');

        await wrapper.vm.$nextTick();

        expect(finder().props('error')).toEqual('');
      });

      it('validation event updates buttons disabled state', async () => {
        mountComponent();

        expect(findSaveButton().props('disabled')).toBe(false);

        finder().vm.$emit('validation', false);

        await wrapper.vm.$nextTick();

        expect(findSaveButton().props('disabled')).toBe(true);
      });
    }

    if (type === 'dropdown') {
      it('has the correct formOptions', () => {
        mountComponent();
        expect(finder().props('formOptions')).toEqual(wrapper.vm.$options.formOptions[model]);
      });
    }
  });

  describe('form', () => {
    describe('form reset event', () => {
      it('calls the appropriate function', () => {
        mountComponent();

        findForm().trigger('reset');

        expect(wrapper.emitted('reset')).toEqual([[]]);
      });

      it('tracks the reset event', () => {
        mountComponent();

        findForm().trigger('reset');

        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'reset_form', trackingPayload);
      });

      it('resets the errors objects', async () => {
        mountComponent({
          data: { apiErrors: { nameRegex: 'bar' }, localErrors: { nameRegexKeep: false } },
        });

        findForm().trigger('reset');

        await wrapper.vm.$nextTick();

        expect(findKeepRegexInput().props('error')).toBe('');
        expect(findRemoveRegexInput().props('error')).toBe('');
        expect(findSaveButton().props('disabled')).toBe(false);
      });
    });

    describe('form submit event ', () => {
      it('save has type submit', () => {
        mountComponent();

        expect(findSaveButton().attributes('type')).toBe('submit');
      });

      it('dispatches the correct apollo mutation', () => {
        const mutationResolver = jest.fn().mockResolvedValue(expirationPolicyMutationPayload());
        mountComponentWithApollo({
          mutationResolver,
        });

        findForm().trigger('submit');

        expect(mutationResolver).toHaveBeenCalled();
      });

      it('saves the default values when a value is missing did not change the default options', async () => {
        const mutationResolver = jest.fn().mockResolvedValue(expirationPolicyMutationPayload());
        mountComponentWithApollo({
          mutationResolver,
          queryPayload: expirationPolicyPayload({ keepN: null, cadence: null, olderThan: null }),
        });

        await waitForPromises();

        findForm().trigger('submit');

        expect(mutationResolver).toHaveBeenCalledWith({
          input: {
            cadence: 'EVERY_DAY',
            enabled: true,
            keepN: null,
            nameRegex: 'asdasdssssdfdf',
            nameRegexKeep: 'sss',
            olderThan: null,
            projectPath: 'path',
          },
        });
      });

      it('tracks the submit event', () => {
        mountComponentWithApollo({
          mutationResolver: jest.fn().mockResolvedValue(expirationPolicyMutationPayload()),
        });

        findForm().trigger('submit');

        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'submit_form', trackingPayload);
      });

      it('show a success toast when submit succeed', async () => {
        mountComponentWithApollo({
          mutationResolver: jest.fn().mockResolvedValue(expirationPolicyMutationPayload()),
        });

        findForm().trigger('submit');
        await waitForPromises();
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_SUCCESS_MESSAGE);
      });

      describe('when submit fails', () => {
        describe('user recoverable errors', () => {
          it('when there is an error is shown in a toast', async () => {
            mountComponentWithApollo({
              mutationResolver: jest
                .fn()
                .mockResolvedValue(expirationPolicyMutationPayload({ errors: ['foo'] })),
            });

            findForm().trigger('submit');
            await waitForPromises();
            await wrapper.vm.$nextTick();

            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('foo');
          });
        });

        describe('global errors', () => {
          it('shows an error', async () => {
            mountComponentWithApollo({
              mutationResolver: jest.fn().mockRejectedValue(expirationPolicyMutationPayload()),
            });

            findForm().trigger('submit');
            await waitForPromises();
            await wrapper.vm.$nextTick();

            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_ERROR_MESSAGE);
          });

          it('parses the error messages', async () => {
            const mutate = jest.fn().mockRejectedValue({
              graphQLErrors: [
                {
                  extensions: {
                    problems: [{ path: ['nameRegexKeep'], message: 'baz' }],
                  },
                },
              ],
            });
            mountComponent({ mocks: { $apollo: { mutate } } });

            findForm().trigger('submit');
            await waitForPromises();
            await wrapper.vm.$nextTick();

            expect(findKeepRegexInput().props('error')).toEqual('baz');
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
        isLoading | isEdited | mutationLoading
        ${true}   | ${true}  | ${true}
        ${false}  | ${true}  | ${true}
        ${false}  | ${false} | ${true}
        ${true}   | ${false} | ${false}
        ${false}  | ${false} | ${false}
      `(
        'when isLoading is $isLoading, isEdited is $isEdited and mutationLoading is $mutationLoading is disabled',
        ({ isEdited, isLoading, mutationLoading }) => {
          mountComponent({
            props: { ...defaultProps, isEdited, isLoading },
            data: { mutationLoading },
          });

          expect(findCancelButton().props('disabled')).toBe(true);
        },
      );
    });

    describe('submit button', () => {
      it('has type submit', () => {
        mountComponent();

        expect(findSaveButton().attributes('type')).toBe('submit');
      });

      it.each`
        isLoading | localErrors       | mutationLoading
        ${true}   | ${{}}             | ${true}
        ${true}   | ${{}}             | ${false}
        ${false}  | ${{}}             | ${true}
        ${false}  | ${{ foo: false }} | ${true}
        ${true}   | ${{ foo: false }} | ${false}
        ${false}  | ${{ foo: false }} | ${false}
      `(
        'when isLoading is $isLoading, localErrors is $localErrors and mutationLoading is $mutationLoading is disabled',
        ({ localErrors, isLoading, mutationLoading }) => {
          mountComponent({
            props: { ...defaultProps, isLoading },
            data: { mutationLoading, localErrors },
          });

          expect(findSaveButton().props('disabled')).toBe(true);
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

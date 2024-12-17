import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { GlLoadingIcon } from 'jest/packages_and_registries/shared/stubs';
import component from '~/packages_and_registries/settings/project/components/container_expiration_policy_form.vue';
import { UPDATE_SETTINGS_ERROR_MESSAGE } from '~/packages_and_registries/settings/project/constants';
import updateContainerExpirationPolicyMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_container_expiration_policy.mutation.graphql';
import expirationPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_expiration_policy.query.graphql';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { expirationPolicyPayload, expirationPolicyMutationPayload } from '../mock_data';

describe('Container Expiration Policy Settings Form', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
    projectSettingsPath: '/settings-path',
  };

  const {
    data: {
      project: { containerTagsExpirationPolicy },
    },
  } = expirationPolicyPayload();

  const defaultProps = {
    value: { ...containerTagsExpirationPolicy },
  };

  const trackingPayload = {
    label: 'docker_container_retention_and_expiration_policies',
  };

  const findForm = () => wrapper.find('form');

  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"');
  const findSaveButton = () => wrapper.find('[data-testid="save-button"');
  const findEnableToggle = () => wrapper.find('[data-testid="enable-toggle"]');
  const findCadenceDropdown = () => wrapper.find('[data-testid="cadence-dropdown"]');
  const findKeepNDropdown = () => wrapper.find('[data-testid="keep-n-dropdown"]');
  const findKeepRegexInput = () => wrapper.find('[data-testid="keep-regex-input"]');
  const findOlderThanDropdown = () => wrapper.find('[data-testid="older-than-dropdown"]');
  const findRemoveRegexInput = () => wrapper.find('[data-testid="remove-regex-input"]');

  const submitForm = () => {
    findForm().trigger('submit');
    return waitForPromises();
  };

  const mountComponent = ({
    props = defaultProps,
    data,
    config,
    provide = defaultProvidedValues,
  } = {}) => {
    wrapper = shallowMount(component, {
      stubs: {
        GlLoadingIcon,
        GlSprintf,
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
      },
      ...config,
    });
  };

  const mountComponentWithApollo = ({
    provide = defaultProvidedValues,
    mutationResolver,
    queryPayload = expirationPolicyPayload(),
  } = {}) => {
    Vue.use(VueApollo);

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
        project: { containerTagsExpirationPolicy: value },
      },
    } = queryPayload;

    mountComponent({
      provide,
      props: {
        ...defaultProps,
        value,
      },
      config: {
        apolloProvider: fakeApollo,
      },
    });
  };

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

        await nextTick();

        expect(finder().props('error')).toEqual('');
      });

      it('validation event updates buttons disabled state', async () => {
        mountComponent({
          props: { ...defaultProps, isEdited: true },
        });

        expect(findSaveButton().props('disabled')).toBe(false);

        finder().vm.$emit('validation', false);

        await nextTick();

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
    describe('form submit event', () => {
      useMockLocationHelper();
      const originalHref = window.location.href;

      it('save has type submit', () => {
        mountComponent();

        expect(findSaveButton().attributes('type')).toBe('submit');
      });

      it('dispatches the correct apollo mutation', async () => {
        const mutationResolver = jest.fn().mockResolvedValue(expirationPolicyMutationPayload());
        mountComponentWithApollo({
          mutationResolver,
        });

        await submitForm();

        expect(mutationResolver).toHaveBeenCalled();
      });

      it('saves the default values when a value is missing did not change the default options', async () => {
        const mutationResolver = jest.fn().mockResolvedValue(expirationPolicyMutationPayload());
        mountComponentWithApollo({
          mutationResolver,
          queryPayload: expirationPolicyPayload({ keepN: null, cadence: null, olderThan: null }),
        });

        await submitForm();

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

      describe('tracking', () => {
        let trackingSpy;

        beforeEach(() => {
          trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
        });

        afterEach(() => {
          unmockTracking();
        });

        it('tracks the submit event', async () => {
          mountComponentWithApollo({
            mutationResolver: jest.fn().mockResolvedValue(expirationPolicyMutationPayload()),
          });

          await submitForm();

          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'submit_form', trackingPayload);
        });
      });

      it('redirects to package and registry project settings page when submitted successfully', async () => {
        mountComponentWithApollo({
          mutationResolver: jest.fn().mockResolvedValue(expirationPolicyMutationPayload()),
        });

        await submitForm();

        expect(window.location.assign).toHaveBeenCalledWith(
          '/settings-path?showSetupSuccessAlert=true',
        );
      });

      describe('when submit fails', () => {
        describe('user recoverable errors', () => {
          it('when there is an error is shown in the nameRegex field t', async () => {
            mountComponentWithApollo({
              mutationResolver: jest
                .fn()
                .mockResolvedValue(expirationPolicyMutationPayload({ errors: ['foo'] })),
            });

            await submitForm();

            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_ERROR_MESSAGE);
            expect(findRemoveRegexInput().props('error')).toBe('foo');
          });
        });

        describe('global errors', () => {
          it('shows an error', async () => {
            mountComponentWithApollo({
              mutationResolver: jest.fn().mockRejectedValue(expirationPolicyMutationPayload()),
            });

            await submitForm();

            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_ERROR_MESSAGE);
            expect(window.location.href).toBe(originalHref);
          });

          it('parses the error messages', async () => {
            const mutate = jest.fn().mockResolvedValue({
              errors: [
                {
                  extensions: {
                    problems: [{ path: ['nameRegexKeep'], message: 'baz' }],
                  },
                },
              ],
            });
            mountComponentWithApollo({
              mutationResolver: mutate,
            });

            await submitForm();

            expect(findKeepRegexInput().props('error')).toEqual('baz');
          });
        });
      });
    });
  });

  describe('form actions', () => {
    describe('cancel button', () => {
      it('links to project package and registry settings path', () => {
        mountComponent();

        expect(findCancelButton().attributes('href')).toBe(
          defaultProvidedValues.projectSettingsPath,
        );
      });

      it.each`
        isLoading | mutationLoading
        ${true}   | ${true}
        ${false}  | ${true}
        ${true}   | ${false}
      `(
        'is disabled when isLoading is $isLoading and mutationLoading is $mutationLoading',
        ({ isLoading, mutationLoading }) => {
          mountComponent({
            props: { ...defaultProps, isLoading },
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
        isLoading | isEdited | localErrors       | mutationLoading
        ${true}   | ${false} | ${{}}             | ${true}
        ${true}   | ${false} | ${{}}             | ${false}
        ${false}  | ${false} | ${{}}             | ${true}
        ${false}  | ${false} | ${{}}             | ${false}
        ${false}  | ${false} | ${{ foo: false }} | ${true}
        ${true}   | ${false} | ${{ foo: false }} | ${false}
        ${false}  | ${false} | ${{ foo: false }} | ${false}
      `(
        'is disabled when isLoading is $isLoading, isEdited is $isEdited, localErrors is $localErrors and mutationLoading is $mutationLoading',
        ({ localErrors, isEdited, isLoading, mutationLoading }) => {
          mountComponent({
            props: { ...defaultProps, isEdited, isLoading },
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

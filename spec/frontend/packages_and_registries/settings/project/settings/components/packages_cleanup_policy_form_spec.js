import VueApollo from 'vue-apollo';
import Vue from 'vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { GlLoadingIcon } from 'jest/packages_and_registries/shared/stubs';
import component from '~/packages_and_registries/settings/project/components/packages_cleanup_policy_form.vue';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
  KEEP_N_DUPLICATED_PACKAGE_FILES_LABEL,
  KEEP_N_DUPLICATED_PACKAGE_FILES_DESCRIPTION,
} from '~/packages_and_registries/settings/project/constants';
import packagesCleanupPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_cleanup_policy.query.graphql';
import updatePackagesCleanupPolicyMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_packages_cleanup_policy.mutation.graphql';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { packagesCleanupPolicyPayload, packagesCleanupPolicyMutationPayload } from '../mock_data';

Vue.use(VueApollo);

describe('Packages Cleanup Policy Settings Form', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const {
    data: {
      project: { packagesCleanupPolicy },
    },
  } = packagesCleanupPolicyPayload();

  const defaultProps = {
    value: { ...packagesCleanupPolicy },
  };

  const trackingPayload = {
    label: 'packages_cleanup_policies',
  };

  const defaultQueryResolver = jest.fn().mockResolvedValue(packagesCleanupPolicyPayload());

  const findForm = () => wrapper.findComponent({ ref: 'form-element' });
  const findSaveButton = () => wrapper.findByTestId('save-button');
  const findKeepNDuplicatedPackageFilesDropdown = () =>
    wrapper.findByTestId('keep-n-duplicated-package-files-dropdown');
  const findNextRunAt = () => wrapper.findByTestId('next-run-at');

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
    wrapper = shallowMountExtended(component, {
      stubs: {
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
      },
      ...config,
    });
  };

  const mountComponentWithApollo = ({
    provide = defaultProvidedValues,
    queryResolver = defaultQueryResolver,
    mutationResolver,
    queryPayload = packagesCleanupPolicyPayload(),
  } = {}) => {
    const requestHandlers = [
      [updatePackagesCleanupPolicyMutation, mutationResolver],
      [packagesCleanupPolicyQuery, queryResolver],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    const {
      data: {
        project: { packagesCleanupPolicy: value },
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

  afterEach(() => {
    fakeApollo = null;
  });

  describe('keepNDuplicatedPackageFiles', () => {
    it('renders dropdown', () => {
      mountComponent();

      const element = findKeepNDuplicatedPackageFilesDropdown();

      expect(element.exists()).toBe(true);
      expect(element.props('label')).toMatchInterpolatedText(KEEP_N_DUPLICATED_PACKAGE_FILES_LABEL);
      expect(element.props('description')).toEqual(KEEP_N_DUPLICATED_PACKAGE_FILES_DESCRIPTION);
    });

    it('input event triggers a model update', () => {
      mountComponent();

      findKeepNDuplicatedPackageFilesDropdown().vm.$emit('input', 'foo');
      expect(wrapper.emitted('input')[0][0]).toMatchObject({
        keepNDuplicatedPackageFiles: 'foo',
      });
    });

    it('shows the default option when none are selected', () => {
      mountComponent({ props: { value: {} } });
      expect(findKeepNDuplicatedPackageFilesDropdown().props('value')).toEqual('ALL_PACKAGE_FILES');
    });

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
        expect(findKeepNDuplicatedPackageFilesDropdown().props('disabled')).toEqual(true);
      },
    );

    it('has the correct formOptions', () => {
      mountComponent();
      expect(findKeepNDuplicatedPackageFilesDropdown().props('formOptions')).toEqual(
        wrapper.vm.$options.formOptions.keepNDuplicatedPackageFiles,
      );
    });
  });

  describe('nextRunAt', () => {
    it('when present renders time until next package cleanup', () => {
      jest.spyOn(Date, 'now').mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());

      mountComponent({
        props: { value: { ...defaultProps.value, nextRunAt: '2063-04-04T02:42:00Z' } },
      });

      expect(findNextRunAt().text()).toMatchInterpolatedText(
        'Packages and assets will not be deleted until cleanup runs in about 2 hours.',
      );
    });

    it('renders message for cleanup when its before current date', () => {
      jest.spyOn(Date, 'now').mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());

      mountComponent({
        props: { value: { ...defaultProps.value, nextRunAt: '2063-03-04T00:42:00Z' } },
      });

      expect(findNextRunAt().text()).toMatchInterpolatedText(
        'Packages and assets cleanup is ready to be executed when the next cleanup job runs.',
      );
    });

    it('when null hides time until next package cleanup', () => {
      mountComponent({
        props: { value: { ...defaultProps.value, nextRunAt: null } },
      });

      expect(findNextRunAt().exists()).toBe(false);
    });
  });

  describe('form', () => {
    describe('actions', () => {
      describe('submit button', () => {
        it('has type submit', () => {
          mountComponent();

          expect(findSaveButton().attributes('type')).toBe('submit');
        });

        it.each`
          isLoading | mutationLoading | disabled
          ${true}   | ${true}         | ${true}
          ${true}   | ${false}        | ${true}
          ${false}  | ${true}         | ${true}
          ${false}  | ${false}        | ${false}
        `(
          'when isLoading is $isLoading and mutationLoading is $mutationLoading is disabled',
          ({ isLoading, mutationLoading, disabled }) => {
            mountComponent({
              props: { ...defaultProps, isLoading },
              data: { mutationLoading },
            });

            expect(findSaveButton().props('disabled')).toBe(disabled);
            expect(findKeepNDuplicatedPackageFilesDropdown().props('disabled')).toBe(disabled);
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

    describe('form submit event', () => {
      it('dispatches the correct apollo mutation and refetches query', async () => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(packagesCleanupPolicyMutationPayload());
        mountComponentWithApollo({
          mutationResolver,
        });

        findForm().trigger('submit');

        expect(mutationResolver).toHaveBeenCalledWith({
          input: {
            keepNDuplicatedPackageFiles: 'ALL_PACKAGE_FILES',
            projectPath: 'path',
          },
        });

        await waitForPromises();

        expect(defaultQueryResolver).toHaveBeenCalledWith({
          projectPath: 'path',
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

        it('tracks the submit event', () => {
          mountComponentWithApollo({
            mutationResolver: jest.fn().mockResolvedValue(packagesCleanupPolicyMutationPayload()),
          });

          findForm().trigger('submit');

          expect(trackingSpy).toHaveBeenCalledWith(
            undefined,
            'submit_packages_cleanup_form',
            trackingPayload,
          );
        });
      });

      it('show a success toast when submit succeed', async () => {
        mountComponentWithApollo({
          mutationResolver: jest.fn().mockResolvedValue(packagesCleanupPolicyMutationPayload()),
        });

        await submitForm();

        expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_SUCCESS_MESSAGE);
      });

      it('shows error toast when mutation responds with errors', async () => {
        mountComponentWithApollo({
          mutationResolver: jest
            .fn()
            .mockResolvedValue(packagesCleanupPolicyMutationPayload({ errors: [new Error()] })),
        });

        await submitForm();

        expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_ERROR_MESSAGE);
      });

      describe('when submit fails', () => {
        it('shows an error', async () => {
          mountComponentWithApollo({
            mutationResolver: jest.fn().mockRejectedValue(packagesCleanupPolicyMutationPayload()),
          });

          await submitForm();

          expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_ERROR_MESSAGE);
        });
      });
    });
  });
});

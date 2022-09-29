import Vue from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert, VARIANT_SUCCESS, VARIANT_WARNING } from '~/flash';
import DeletePackage from '~/packages_and_registries/package_registry/components/functional/delete_package.vue';

import destroyPackageMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_package.mutation.graphql';
import getPackagesQuery from '~/packages_and_registries/package_registry/graphql/queries/get_packages.query.graphql';
import {
  packageDestroyMutation,
  packageDestroyMutationError,
  packagesListQuery,
} from '../../mock_data';

jest.mock('~/flash');

describe('DeletePackage', () => {
  let wrapper;
  let apolloProvider;
  let resolver;
  let mutationResolver;

  const eventPayload = { id: '1' };

  function createComponent(propsData = {}) {
    Vue.use(VueApollo);

    const requestHandlers = [
      [getPackagesQuery, resolver],
      [destroyPackageMutation, mutationResolver],
    ];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(DeletePackage, {
      propsData,
      apolloProvider,
      scopedSlots: {
        default(props) {
          return this.$createElement('button', {
            attrs: {
              'data-testid': 'trigger-button',
            },
            on: {
              click: props.deletePackage,
            },
          });
        },
      },
    });
  }

  const findButton = () => wrapper.findByTestId('trigger-button');

  const clickOnButtonAndWait = (payload) => {
    findButton().trigger('click', payload);
    return waitForPromises();
  };

  beforeEach(() => {
    resolver = jest.fn().mockResolvedValue(packagesListQuery());
    mutationResolver = jest.fn().mockResolvedValue(packageDestroyMutation());
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('binds deletePackage method to the default slot', () => {
    createComponent();

    findButton().trigger('click');

    expect(wrapper.emitted('start')).toEqual([[]]);
  });

  it('calls apollo mutation', async () => {
    createComponent();

    await clickOnButtonAndWait(eventPayload);

    expect(mutationResolver).toHaveBeenCalledWith(eventPayload);
  });

  it('passes refetchQueries to apollo mutate', async () => {
    const variables = { isGroupPage: true };
    createComponent({
      refetchQueries: [{ query: getPackagesQuery, variables }],
    });

    await clickOnButtonAndWait(eventPayload);

    expect(mutationResolver).toHaveBeenCalledWith(eventPayload);
    expect(resolver).toHaveBeenCalledWith(variables);
  });

  describe('on mutation success', () => {
    it('emits end event', async () => {
      createComponent();

      await clickOnButtonAndWait(eventPayload);

      expect(wrapper.emitted('end')).toEqual([[]]);
    });

    it('does not call createAlert', async () => {
      createComponent();

      await clickOnButtonAndWait(eventPayload);

      expect(createAlert).not.toHaveBeenCalled();
    });

    it('calls createAlert with the success message when showSuccessAlert is true', async () => {
      createComponent({ showSuccessAlert: true });

      await clickOnButtonAndWait(eventPayload);

      expect(createAlert).toHaveBeenCalledWith({
        message: DeletePackage.i18n.successMessage,
        variant: VARIANT_SUCCESS,
      });
    });
  });

  describe.each`
    errorType            | mutationResolverResponse
    ${'connectionError'} | ${jest.fn().mockRejectedValue()}
    ${'localError'}      | ${jest.fn().mockResolvedValue(packageDestroyMutationError())}
  `('on mutation $errorType', ({ mutationResolverResponse }) => {
    beforeEach(() => {
      mutationResolver = mutationResolverResponse;
    });

    it('emits end event', async () => {
      createComponent();

      await clickOnButtonAndWait(eventPayload);

      expect(wrapper.emitted('end')).toEqual([[]]);
    });

    it('calls createAlert with the error message', async () => {
      createComponent({ showSuccessAlert: true });

      await clickOnButtonAndWait(eventPayload);

      expect(createAlert).toHaveBeenCalledWith({
        message: DeletePackage.i18n.errorMessage,
        variant: VARIANT_WARNING,
        captureError: true,
        error: expect.any(Error),
      });
    });
  });
});

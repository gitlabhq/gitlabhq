import Vue from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert, VARIANT_SUCCESS, VARIANT_WARNING } from '~/alert';
import DeletePackages from '~/packages_and_registries/package_registry/components/functional/delete_packages.vue';

import destroyPackagesMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_packages.mutation.graphql';
import getPackagesQuery from '~/packages_and_registries/package_registry/graphql/queries/get_packages.query.graphql';
import {
  packagesDestroyMutation,
  packagesDestroyMutationError,
  packagesListQuery,
} from '../../mock_data';

jest.mock('~/alert');

describe('DeletePackages', () => {
  let wrapper;
  let apolloProvider;
  let resolver;
  let mutationResolver;

  const eventPayload = [{ id: '1' }];
  const eventPayloadMultiple = [{ id: '1' }, { id: '2' }];
  const mutationPayload = { ids: ['1'] };

  function createComponent(propsData = {}) {
    Vue.use(VueApollo);

    const requestHandlers = [
      [getPackagesQuery, resolver],
      [destroyPackagesMutation, mutationResolver],
    ];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(DeletePackages, {
      propsData,
      apolloProvider,
      scopedSlots: {
        default(props) {
          return this.$createElement('button', {
            attrs: {
              'data-testid': 'trigger-button',
            },
            on: {
              click: (payload) => {
                return props.deletePackages(payload[0]);
              },
            },
          });
        },
      },
    });
  }

  const findButton = () => wrapper.findByTestId('trigger-button');

  const clickOnButtonAndWait = (payload) => {
    findButton().trigger('click', [payload]);
    return waitForPromises();
  };

  beforeEach(() => {
    resolver = jest.fn().mockResolvedValue(packagesListQuery());
    mutationResolver = jest.fn().mockResolvedValue(packagesDestroyMutation());
  });

  it('binds deletePackages method to the default slot', () => {
    createComponent();

    findButton().trigger('click', eventPayload);

    expect(wrapper.emitted('start')).toEqual([[]]);
  });

  it('calls apollo mutation', async () => {
    createComponent();

    await clickOnButtonAndWait(eventPayload);

    expect(mutationResolver).toHaveBeenCalledWith(mutationPayload);
  });

  it('passes refetchQueries to apollo mutate', async () => {
    const variables = { isGroupPage: true };
    createComponent({
      refetchQueries: [{ query: getPackagesQuery, variables }],
    });

    await clickOnButtonAndWait(eventPayload);

    expect(mutationResolver).toHaveBeenCalledWith(mutationPayload);
    expect(resolver).toHaveBeenCalledWith(variables);
  });

  describe('when payload contains multiple packages', () => {
    it('calls apollo mutation with different payload', async () => {
      createComponent();

      await clickOnButtonAndWait(eventPayloadMultiple);

      expect(mutationResolver).toHaveBeenCalledWith({ ids: ['1', '2'] });
    });
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
        message: DeletePackages.i18n.successMessage,
        variant: VARIANT_SUCCESS,
      });
    });

    describe('when payload contains multiple packages', () => {
      it('calls createAlert with success message when showSuccessAlert is true', async () => {
        createComponent({ showSuccessAlert: true });

        await clickOnButtonAndWait(eventPayloadMultiple);

        expect(createAlert).toHaveBeenCalledWith({
          message: DeletePackages.i18n.successMessageMultiple,
          variant: VARIANT_SUCCESS,
        });
      });
    });
  });

  describe.each`
    errorType            | mutationResolverResponse
    ${'connectionError'} | ${jest.fn().mockRejectedValue()}
    ${'localError'}      | ${jest.fn().mockResolvedValue(packagesDestroyMutationError())}
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
        message: DeletePackages.i18n.errorMessage,
        variant: VARIANT_WARNING,
        captureError: true,
        error: expect.any(Error),
      });
    });

    describe('when payload contains multiple packages', () => {
      it('calls createAlert with error message', async () => {
        createComponent({ showSuccessAlert: true });

        await clickOnButtonAndWait(eventPayloadMultiple);

        expect(createAlert).toHaveBeenCalledWith({
          message: DeletePackages.i18n.errorMessageMultiple,
          variant: VARIANT_WARNING,
          captureError: true,
          error: expect.any(Error),
        });
      });
    });
  });
});
